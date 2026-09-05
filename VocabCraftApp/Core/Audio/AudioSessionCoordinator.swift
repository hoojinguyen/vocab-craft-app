@preconcurrency import AVFoundation
import Foundation

public enum AudioSessionIntent: Hashable, Sendable {
    case playback
    case speechCapture
    case duplexSpeech
}

public struct AudioSessionLease: Hashable, Sendable {
    public let id: UUID
    public let generation: UInt
    public let intent: AudioSessionIntent

    public init(id: UUID = UUID(), generation: UInt, intent: AudioSessionIntent) {
        self.id = id
        self.generation = generation
        self.intent = intent
    }
}

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

public protocol AudioSessionCoordinating: Sendable {
    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease
    func release(_ lease: AudioSessionLease) async
}

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

public actor AudioSessionCoordinator: AudioSessionCoordinating {
    private let hardware: any AudioSessionHardware
    private var activeLeases: [UUID: AudioSessionLease] = [:]
    private(set) public var generation: UInt = 0
    private(set) public var effectiveIntent: AudioSessionIntent?

    public init(hardware: any AudioSessionHardware) {
        self.hardware = hardware
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

    public func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        let nextGeneration = generation + 1
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
        if leases.values.contains(where: { $0.intent == .duplexSpeech }) {
            return .duplexSpeech
        }
        if leases.values.contains(where: { $0.intent == .speechCapture }) {
            return .speechCapture
        }
        return .playback
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
