@preconcurrency import AVFoundation
import Foundation
import SpeechKit

public typealias AudioSessionIntent = SpeechKit.AudioSessionIntent
public typealias AudioSessionLease = SpeechKit.AudioSessionLease
public typealias AudioSessionCoordinating = SpeechKit.AudioSessionCoordinating
public typealias AudioSessionEvent = SpeechKit.AudioSessionEvent

#if !os(iOS)
public enum AVAudioSession {
    public struct Category: Hashable, Sendable {
        let rawValue: String
        public static let playback = Category(rawValue: "playback")
        public static let playAndRecord = Category(rawValue: "playAndRecord")
    }

    public struct Mode: Hashable, Sendable {
        let rawValue: String
        public static let `default` = Mode(rawValue: "default")
        public static let spokenAudio = Mode(rawValue: "spokenAudio")
    }

    public struct CategoryOptions: OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt = 0) {
            self.rawValue = rawValue
        }

        public static let defaultToSpeaker = CategoryOptions(rawValue: 1 << 0)
        public static let allowBluetoothHFP = CategoryOptions(rawValue: 1 << 1)
        public static let duckOthers = CategoryOptions(rawValue: 1 << 2)
    }

    public struct SetActiveOptions: OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt = 0) {
            self.rawValue = rawValue
        }

        public static let notifyOthersOnDeactivation = SetActiveOptions(rawValue: 1 << 0)
    }

    public enum PortOverride: Sendable {
        case speaker
    }
}
#endif

public protocol AudioSessionHardware: Sendable {
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws
}

private final class EventBroadcaster: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<AudioSessionEvent>.Continuation] = [:]

    func register(_ continuation: AsyncStream<AudioSessionEvent>.Continuation, for id: UUID) {
        lock.withLock {
            continuations[id] = continuation
        }
    }

    func unregister(for id: UUID) {
        lock.withLock {
            _ = continuations.removeValue(forKey: id)
        }
    }

    func broadcast(_ event: AudioSessionEvent) {
        let list = lock.withLock {
            Array(continuations.values)
        }
        for continuation in list {
            continuation.yield(event)
        }
    }
}

#if os(iOS)
private final class NotificationObserverBox: @unchecked Sendable {
    private var tokens: [NSObjectProtocol] = []

    func add(_ token: NSObjectProtocol) {
        tokens.append(token)
    }

    deinit {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
private final class NotificationTransferBox: @unchecked Sendable {
    let notification: Notification
    init(_ notification: Notification) {
        self.notification = notification
    }
}
#endif

public actor AudioSessionCoordinator: AudioSessionCoordinating {
    private let hardware: any AudioSessionHardware
    private let broadcaster = EventBroadcaster()
    #if os(iOS)
    private let observerBox = NotificationObserverBox()
    #endif
    private var activeLeases: [UUID: AudioSessionLease] = [:]
    private(set) public var generation: UInt = 0
    private(set) public var effectiveIntent: AudioSessionIntent?

    public init(hardware: any AudioSessionHardware) {
        self.hardware = hardware
        #if os(iOS)
        let notificationCenter = NotificationCenter.default
        let interruption = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }
            let box = NotificationTransferBox(notification)
            Task {
                await self.handleInterruption(box.notification)
            }
        }
        let routeChange = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }
            let box = NotificationTransferBox(notification)
            Task {
                await self.handleRouteChange(box.notification)
            }
        }
        let mediaReset = notificationCenter.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.handleMediaServicesReset()
            }
        }
        self.observerBox.add(interruption)
        self.observerBox.add(routeChange)
        self.observerBox.add(mediaReset)
        #endif
    }

    public init() {
        self.init(hardware: LiveAudioSessionHardware())
    }

    public var activeLeaseCount: Int {
        activeLeases.count
    }

    public var currentGeneration: UInt {
        generation
    }

    // MARK: - Event Stream

    nonisolated public var events: AsyncStream<AudioSessionEvent> {
        AsyncStream { continuation in
            let id = UUID()
            self.registerContinuation(continuation, for: id)
            continuation.onTermination = { [weak self] _ in
                self?.unregisterContinuation(for: id)
            }
        }
    }

    nonisolated func registerContinuation(
        _ continuation: AsyncStream<AudioSessionEvent>.Continuation,
        for id: UUID
    ) {
        broadcaster.register(continuation, for: id)
    }

    nonisolated func unregisterContinuation(for id: UUID) {
        broadcaster.unregister(for: id)
    }

    private func broadcast(_ event: AudioSessionEvent) {
        broadcaster.broadcast(event)
    }

    public func broadcastEventForTesting(_ event: AudioSessionEvent) {
        broadcast(event)
    }

    // MARK: - Lease Management

    public func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        let nextGeneration = generation &+ 1
        let candidateLease = AudioSessionLease(
            id: UUID(),
            generation: nextGeneration,
            intent: intent
        )

        var tentativeLeases = activeLeases
        tentativeLeases[candidateLease.id] = candidateLease

        let tentativeIntent = deriveEffectiveIntent(from: tentativeLeases)

        try applyEffectiveIntent(to: tentativeIntent)

        generation = nextGeneration
        activeLeases = tentativeLeases
        effectiveIntent = tentativeIntent

        return candidateLease
    }

    public func release(_ lease: AudioSessionLease) async {
        guard let existing = activeLeases[lease.id] else {
            return
        }
        guard existing.generation == lease.generation else {
            return
        }

        var tentativeLeases = activeLeases
        tentativeLeases.removeValue(forKey: lease.id)

        let tentativeIntent = deriveEffectiveIntent(from: tentativeLeases)

        do {
            try applyEffectiveIntent(to: tentativeIntent)
        } catch {
            // Non-fatal deactivation/transition failure on release
        }

        activeLeases = tentativeLeases
        effectiveIntent = tentativeIntent
    }

    private func deriveEffectiveIntent(from leases: [UUID: AudioSessionLease]) -> AudioSessionIntent? {
        if leases.isEmpty {
            return nil
        }

        let hasDuplex = leases.values.contains { $0.intent == .duplexSpeech }
        let hasCapture = leases.values.contains { $0.intent == .speechCapture }
        let hasPlayback = leases.values.contains { $0.intent == .playback }

        if hasDuplex || (hasCapture && hasPlayback) {
            return .duplexSpeech
        } else if hasCapture {
            return .speechCapture
        } else {
            return .playback
        }
    }

    private func isCaptureOrDuplex(_ intent: AudioSessionIntent?) -> Bool {
        guard let intent else { return false }
        return intent == .speechCapture || intent == .duplexSpeech
    }

    private func applyEffectiveIntent(to newIntent: AudioSessionIntent?) throws {
        if newIntent == effectiveIntent {
            return
        }
        if isCaptureOrDuplex(newIntent) && isCaptureOrDuplex(effectiveIntent) {
            return
        }

        switch newIntent {
        case .speechCapture, .duplexSpeech:
            try hardware.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try hardware.setAllowHapticsAndSystemSoundsDuringRecording(true)
            if effectiveIntent == nil {
                try hardware.setActive(true, options: [])
            }
            try? hardware.overrideOutputAudioPort(.speaker)

        case .playback:
            try hardware.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            if effectiveIntent == nil {
                try hardware.setActive(true, options: [])
            }

        case nil:
            if effectiveIntent != nil {
                try hardware.setActive(false, options: [.notifyOthersOnDeactivation])
            }
        }
    }

    // MARK: - System Notifications

    #if os(iOS)
    func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let rawType = (userInfo[AVAudioSessionInterruptionTypeKey] as? UInt)
            ?? ((userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue)
        guard let rawType, let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began:
            broadcast(.interruptionBegan)
        case .ended:
            let rawOptions = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
                ?? ((userInfo[AVAudioSessionInterruptionOptionKey] as? NSNumber)?.uintValue)
            var shouldResume = false
            if let rawOptions {
                shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
            }
            broadcast(.interruptionEnded(shouldResume: shouldResume))
        @unknown default:
            break
        }
    }

    func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let rawReason = (userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt)
            ?? ((userInfo[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue)
        guard let rawReason, let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else {
            return
        }

        let eventReason: AudioSessionEvent.RouteChangeReason
        switch reason {
        case .newDeviceAvailable:
            eventReason = .newDeviceAvailable
        case .oldDeviceUnavailable:
            eventReason = .oldDeviceUnavailable
        case .categoryChange:
            eventReason = .categoryChange
        default:
            eventReason = .other
        }
        broadcast(.routeChanged(reason: eventReason))
    }
    #endif

    public func handleMediaServicesReset() {
        // Note: When media services are reset by the OS, active audio session hardware is
        // implicitly invalidated and torn down. We clear all tracked leases, advance the
        // generation counter to invalidate in-flight leases, and broadcast the reset event.
        activeLeases.removeAll()
        generation &+= 1
        effectiveIntent = nil
        broadcast(.mediaServicesReset)
    }
}

#if os(iOS)
final class LiveAudioSessionHardware: AudioSessionHardware, @unchecked Sendable {
    private let session = AVAudioSession.sharedInstance()

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        try session.setCategory(category, mode: mode, options: options)
    }

    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws {
        try session.setAllowHapticsAndSystemSoundsDuringRecording(inValue)
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        try session.setActive(active, options: options)
    }

    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws {
        try session.overrideOutputAudioPort(portOverride)
    }
}
#else
final class LiveAudioSessionHardware: AudioSessionHardware, @unchecked Sendable {
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {}

    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws {}

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {}

    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws {}
}
#endif
