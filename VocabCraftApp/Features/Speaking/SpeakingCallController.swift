import AVFoundation
import Foundation
import Observation
import SpeechKit
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
public final class SpeakingCallController {
    public private(set) var phase: SpeakingCallPhase = .idle
    public private(set) var turns: [SpeakingTurn] = []
    public private(set) var elapsed: TimeInterval = 0
    public private(set) var hintCount = 0
    public private(set) var isAISpeaking = false
    public private(set) var result: SpeakingSessionSnapshot?

    private let plan: SpeakingSessionPlan
    private let apiKey: String
    private let transport: any LiveTransport
    private let audio: any SpeakingAudioIO
    private let recorder: LearnerRecorder
    private let audioSession: any AudioSessionCoordinating
    private let clock: AnySpeakingClock
    private let notificationCenter: NotificationCenter
    private let now: () -> Date
    private let sessionID = UUID()
    private var reducer = SpeakingCallState()
    private var transcriptAssembler = TranscriptAssembler()
    private var lease: AudioSessionLease?
    private var audioSessionTask: Task<Void, Never>?
    private var incomingTask: Task<Void, Never>?
    private var captureSendTask: Task<Void, Never>?
    private var setupTimeoutTask: Task<Void, Never>?
    private var reconnectTimeoutTask: Task<Void, Never>?
    private var sessionClockTask: Task<Void, Never>?
    private var goodbyeDrainTask: Task<Void, Never>?
    private var captureContinuation: AsyncStream<Data>.Continuation?
    private var socketGeneration: UInt64 = 0
    private var reconnectTimerGeneration: UInt64 = 0
    private var setupAcknowledged = false
    private var recorderStarted = false
    private var audioStarted = false
    private var audioStopped = false
    private var didFinalize = false
    private var didSendWrapUp = false
    private var initialCaptureOverflowCount = 0
    private var initialRecorderOverflowCount = 0
    private var hasCaptureBaseline = false
    private let captureQueueOverflow = CaptureQueueOverflowSignal()
    private let captureGenerationGate = CaptureGenerationGate()
    private var startedAt: Date?
    private var monotonicStart: AnySpeakingInstant?
    private var audioFileName: String?
    #if canImport(UIKit)
    private var backgroundObserver: NSObjectProtocol?
    #endif

    public init(
        plan: SpeakingSessionPlan,
        apiKey: String,
        transport: any LiveTransport,
        audio: any SpeakingAudioIO,
        recorder: LearnerRecorder,
        audioSession: any AudioSessionCoordinating,
        clock: any Clock<Duration> = ContinuousClock(),
        notificationCenter: NotificationCenter = .default,
        now: @escaping () -> Date = Date.init
    ) {
        self.plan = plan
        self.apiKey = apiKey
        self.transport = transport
        self.audio = audio
        self.recorder = recorder
        self.audioSession = audioSession
        self.clock = AnySpeakingClock(clock)
        self.notificationCenter = notificationCenter
        self.now = now
    }

    public func start() async {
        guard phase == .idle else { return }
        observeBackgroundEntry()
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            _ = reducer.reduce(.start)
            phase = reducer.phase
            await dispatch(.connectFailed(.missingKey))
            return
        }
        do {
            lease = try await audioSession.acquire(.duplexSpeech)
            listenForAudioSessionEvents()
        } catch {
            _ = reducer.reduce(.start)
            phase = reducer.phase
            await dispatch(.connectFailed(.microphoneDenied))
            return
        }
        await dispatch(.start)
    }

    public func requestHint() async {
        guard phase == .live else { return }
        do {
            try await transport.send(.hiddenText(SpeakingPromptBuilder.hintRequest))
            hintCount += 1
        } catch {
            await handleTransportError(error, generation: socketGeneration)
        }
    }

    public func end() async {
        await dispatch(hasCaptureFailure ? .audioFailure : .learnerEnded)
    }

    private func dispatch(_ input: SpeakingCallInput) async {
        let isFatalServerFailure: Bool
        if case let .connectFailed(failure) = input {
            isFatalServerFailure = failure == .unauthorized || failure == .quotaExceeded
        } else {
            isFatalServerFailure = false
        }
        let effectiveInput = hasCaptureFailure && input != .audioFailure && !isFatalServerFailure
            ? .audioFailure
            : input
        let effects = reducer.reduce(effectiveInput)
        phase = reducer.phase
        if phase.isTerminal {
            goodbyeDrainTask?.cancel()
            goodbyeDrainTask = nil
        }
        for effect in effects {
            if phase.isTerminal {
                switch effect {
                case .sendOpeningTrigger, .startAudio, .sendWrapUp:
                    continue
                case .openSocket, .stopAudio, .closeSocket, .startReconnectTimer, .cancelReconnectTimer, .finalize:
                    break
                }
            }
            await perform(effect)
        }
    }

    private func perform(_ effect: SpeakingCallEffect) async {
        switch effect {
        case let .openSocket(resumptionHandle):
            await openSocket(resumptionHandle: resumptionHandle)
        case .sendOpeningTrigger:
            do {
                try await transport.send(.hiddenText(SpeakingPromptBuilder.openingTrigger))
            } catch {
                await handleTransportError(error, generation: socketGeneration)
            }
        case .startAudio:
            await startAudio()
        case .stopAudio:
            await stopAudio()
        case .closeSocket:
            await closeSocket()
        case let .startReconnectTimer(seconds):
            startReconnectTimer(seconds: seconds)
        case .cancelReconnectTimer:
            reconnectTimerGeneration &+= 1
            reconnectTimeoutTask?.cancel()
            reconnectTimeoutTask = nil
        case .sendWrapUp:
            do {
                try await transport.send(.hiddenText(SpeakingPromptBuilder.wrapUpRequest))
            } catch {
                await handleTransportError(error, generation: socketGeneration)
            }
        case let .finalize(reason):
            await finalize(reason: reason)
        }
    }

    private func openSocket(resumptionHandle: String?) async {
        socketGeneration &+= 1
        let generation = socketGeneration
        setupTimeoutTask?.cancel()
        setupAcknowledged = false

        do {
            let stream = try await transport.connect(apiKey: apiKey)
            guard generation == socketGeneration, !phase.isTerminal else {
                await transport.close()
                return
            }
            incomingTask = Task { @MainActor [weak self] in
                await self?.consume(stream, generation: generation)
            }
            let setup = LiveSetup(
                model: "models/gemini-3.8-live",
                voiceName: "Kore",
                systemInstruction: SpeakingPromptBuilder.systemInstruction(for: plan),
                resumptionHandle: resumptionHandle
            )
            try await transport.send(.setup(setup))
            if !reducer.hasBeenLive, !setupAcknowledged {
                startSetupTimeout(generation: generation)
            }
        } catch {
            guard generation == socketGeneration else { return }
            await dispatch(.connectFailed(Self.failure(for: error)))
        }
    }

    private func consume(_ stream: AsyncThrowingStream<Data, Error>, generation: UInt64) async {
        do {
            for try await data in stream {
                guard generation == socketGeneration, !phase.isTerminal else { return }
                let events: [LiveServerEvent]
                do {
                    events = try LiveServerEvent.decode(data)
                } catch {
                    await handleTransportError(error, generation: generation)
                    return
                }
                for event in events {
                    guard generation == socketGeneration, !phase.isTerminal else { return }
                    await receive(event)
                }
            }
            guard generation == socketGeneration, !phase.isTerminal else { return }
            await handleStreamEnd()
        } catch {
            guard generation == socketGeneration, !phase.isTerminal else { return }
            await handleTransportError(error, generation: generation)
        }
    }

    private func receive(_ event: LiveServerEvent) async {
        switch event {
        case .setupComplete:
            setupAcknowledged = true
            setupTimeoutTask?.cancel()
            setupTimeoutTask = nil
            let wasLive = reducer.hasBeenLive
            await dispatch(.setupComplete)
            if !wasLive, reducer.hasBeenLive {
                startedAt = now()
                monotonicStart = clock.now
                startSessionClock()
            }
        case let .audio(data):
            audio.enqueuePlayback(data)
            isAISpeaking = true
        case .inputTranscript, .outputTranscript:
            transcriptAssembler.ingest(event, at: recorder.elapsed)
            turns = transcriptAssembler.turns
        case .interrupted:
            audio.flushPlayback()
            isAISpeaking = false
            transcriptAssembler.ingest(event, at: recorder.elapsed)
            turns = transcriptAssembler.turns
        case .turnComplete:
            isAISpeaking = false
            transcriptAssembler.ingest(event, at: recorder.elapsed)
            turns = transcriptAssembler.turns
        case let .toolCall(id, name):
            guard name == "end_session" else { return }
            do {
                try await transport.send(.toolResponse(id: id, name: name))
                startGoodbyeDrain()
            } catch {
                await handleTransportError(error, generation: socketGeneration)
            }
        case .goAway:
            await dispatch(.goAway)
        case let .resumptionUpdate(handle, resumable):
            if resumable, let handle {
                await dispatch(.resumptionHandle(handle))
            } else {
                await dispatch(.resumptionUnavailable)
            }
        }
    }

    private func handleStreamEnd() async {
        switch phase {
        case .live:
            await dispatch(.transportDropped)
        case .connecting, .reconnecting:
            await dispatch(.connectFailed(.network))
        case .idle, .ended, .failed:
            break
        }
    }

    private func handleTransportError(_ error: Error, generation: UInt64) async {
        guard generation == socketGeneration else { return }
        let failure = Self.failure(for: error)
        switch phase {
        case .live where failure == .unauthorized || failure == .quotaExceeded:
            await dispatch(.connectFailed(failure))
        case .live:
            await dispatch(.transportDropped)
        case .connecting, .reconnecting:
            await dispatch(.connectFailed(failure))
        case .idle, .ended, .failed:
            break
        }
    }

    private func startAudio() async {
        do {
            if !recorderStarted {
                guard let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1) else {
                    throw SpeakingAudioIOError.invalidInputFormat
                }
                audioFileName = try recorder.begin(sessionId: sessionID, format: format)
                recorderStarted = true
            }
            let overflow = captureQueueOverflow
            let captureGeneration = captureGenerationGate.activate()
            if !hasCaptureBaseline {
                initialCaptureOverflowCount = audio.captureOverflowCount
                initialRecorderOverflowCount = recorder.overflowCount
                hasCaptureBaseline = true
            }
            let (stream, continuation) = AsyncStream<Data>.makeStream(
                bufferingPolicy: .bufferingOldest(32)
            )
            captureContinuation = continuation
            captureSendTask = Task { @MainActor [weak self] in
                guard let self else { return }
                for await packet in stream {
                    guard !Task.isCancelled else { return }
                    if overflow.didOverflow {
                        await self.dispatch(.audioFailure)
                        return
                    }
                    do {
                        try await self.transport.send(.audio(packet))
                    } catch {
                        await self.handleTransportError(error, generation: self.socketGeneration)
                        return
                    }
                }
            }
            let generationGate = captureGenerationGate
            try await audio.start { [recorder, continuation, overflow, generationGate, captureGeneration] packet in
                guard generationGate.isActive(captureGeneration) else { return }
                recorder.append(packet)
                if case .dropped = continuation.yield(packet) {
                    overflow.markOverflow()
                }
            }
            audioStarted = true
            audioStopped = false
        } catch {
            captureGenerationGate.invalidate()
            captureContinuation?.finish()
            captureContinuation = nil
            captureSendTask?.cancel()
            captureSendTask = nil
            await dispatch(.audioFailure)
        }
    }

    private func stopAudio() async {
        captureGenerationGate.invalidate()
        captureContinuation?.finish()
        captureContinuation = nil
        captureSendTask?.cancel()
        captureSendTask = nil
        await audio.stop()
        audioStarted = false
        audioStopped = true
        isAISpeaking = false
    }

    private func closeSocket() async {
        socketGeneration &+= 1
        incomingTask?.cancel()
        incomingTask = nil
        setupTimeoutTask?.cancel()
        setupTimeoutTask = nil
        reconnectTimeoutTask?.cancel()
        reconnectTimeoutTask = nil
        sessionClockTask?.cancel()
        sessionClockTask = nil
        audioSessionTask?.cancel()
        audioSessionTask = nil
        goodbyeDrainTask?.cancel()
        goodbyeDrainTask = nil
        if !audioStopped {
            captureGenerationGate.invalidate()
            audio.flushPlayback()
            await audio.stop()
            audioStarted = false
            audioStopped = true
        }
        await transport.close()
        removeBackgroundObserver()
        await releaseLeaseOnce()
    }

    private func finalize(reason: SpeakingEndReason) async {
        guard !didFinalize else { return }
        didFinalize = true
        if let monotonicStart {
            elapsed = Self.timeInterval(from: monotonicStart.duration(to: clock.now))
        }
        var finalTurns = transcriptAssembler.turns
        if let last = finalTurns.indices.last, finalTurns[last].endOffset == nil {
            finalTurns[last].endOffset = recorder.elapsed
        }
        turns = finalTurns
        let sessionRecorder = recorder
        let recordingURL = await Task.detached(priority: .utility) { sessionRecorder.finish() }.value
        result = SpeakingSessionSnapshot(
            id: sessionID,
            plan: plan,
            startedAt: startedAt ?? now(),
            duration: elapsed,
            status: .pendingAnalysis,
            endReason: reason,
            hintCount: hintCount,
            audioFileName: recordingURL?.lastPathComponent,
            turns: finalTurns,
            analysis: nil
        )
        await releaseLeaseOnce()
    }

}

private extension SpeakingCallController {
    func startSetupTimeout(generation: UInt64) {
        setupTimeoutTask?.cancel()
        setupTimeoutTask = Task { @MainActor [weak self, clock] in
            do {
                try await clock.sleep(for: .seconds(10))
            } catch {
                return
            }
            guard let self,
                  generation == self.socketGeneration,
                  !self.setupAcknowledged,
                  !self.phase.isTerminal else { return }
            await self.dispatch(.connectFailed(.network))
        }
    }

    func startReconnectTimer(seconds: Int) {
        reconnectTimerGeneration &+= 1
        let generation = reconnectTimerGeneration
        reconnectTimeoutTask?.cancel()
        reconnectTimeoutTask = Task { @MainActor [weak self, clock] in
            do {
                try await clock.sleep(for: .seconds(seconds))
            } catch {
                return
            }
            guard let self,
                  generation == self.reconnectTimerGeneration,
                  self.phase == .reconnecting else { return }
            await self.dispatch(.reconnectTimedOut)
        }
    }

    func startSessionClock() {
        sessionClockTask?.cancel()
        guard let monotonicStart else { return }
        sessionClockTask = Task { @MainActor [weak self, clock] in
            while !Task.isCancelled {
                guard let self, !self.phase.isTerminal else { return }
                self.elapsed = Self.timeInterval(from: monotonicStart.duration(to: clock.now))
                if self.hasCaptureFailure {
                    await self.dispatch(.audioFailure)
                    return
                }
                if self.elapsed >= TimeInterval(max(0, self.plan.blueprint.durationSeconds - 30)), !self.didSendWrapUp {
                    self.didSendWrapUp = true
                    await self.dispatch(.wrapUpDue)
                }
                if self.elapsed >= TimeInterval(self.plan.blueprint.durationSeconds + 30) {
                    await self.dispatch(.hardLimitReached)
                    return
                }
                let nextSecond = Int64(floor(self.elapsed) + 1)
                let nextDeadline = monotonicStart.advanced(by: .seconds(nextSecond))
                do {
                    try await clock.sleep(until: nextDeadline)
                } catch {
                    return
                }
            }
        }
    }

    func startGoodbyeDrain() {
        goodbyeDrainTask?.cancel()
        goodbyeDrainTask = Task { @MainActor [weak self, clock] in
            guard let self else { return }
            let drainStart = clock.now
            while self.audio.isPlaying,
                  drainStart.duration(to: clock.now) < .seconds(2),
                  !Task.isCancelled,
                  !self.phase.isTerminal {
                do {
                    try await clock.sleep(for: .milliseconds(50))
                } catch {
                    return
                }
            }
            guard !Task.isCancelled, !self.phase.isTerminal else { return }
            await self.dispatch(.aiRequestedEnd)
        }
    }

    func listenForAudioSessionEvents() {
        audioSessionTask?.cancel()
        audioSessionTask = Task { @MainActor [weak self, audioSession] in
            for await event in audioSession.events {
                guard let self, !Task.isCancelled, !self.phase.isTerminal else { return }
                switch event {
                case .interruptionBegan:
                    await self.dispatch(self.hasCaptureFailure ? .audioFailure : .audioInterrupted)
                case .routeChanged:
                    guard self.phase == .live else { continue }
                    do {
                        try await self.audio.restartAfterRouteChange()
                    } catch {
                        await self.dispatch(.audioFailure)
                    }
                case .interruptionEnded, .mediaServicesReset:
                    break
                }
            }
        }
    }

    func observeBackgroundEntry() {
        #if canImport(UIKit)
        guard backgroundObserver == nil else { return }
        backgroundObserver = notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                await self.dispatch(self.hasCaptureFailure ? .audioFailure : .audioInterrupted)
            }
        }
        #endif
    }

    func removeBackgroundObserver() {
        #if canImport(UIKit)
        if let backgroundObserver {
            notificationCenter.removeObserver(backgroundObserver)
            self.backgroundObserver = nil
        }
        #endif
    }

    func releaseLeaseOnce() async {
        guard let lease else { return }
        self.lease = nil
        await audioSession.release(lease)
    }

    var hasCaptureFailure: Bool {
        hasCaptureBaseline && (
            audio.captureOverflowCount > initialCaptureOverflowCount ||
            recorder.overflowCount > initialRecorderOverflowCount ||
            captureQueueOverflow.didOverflow
        )
    }

    static func failure(for error: Error) -> SpeakingCallFailure {
        switch error as? LiveTransportError {
        case .unauthorized:
            .unauthorized
        case .quotaExceeded:
            .quotaExceeded
        case .network, .closed:
            .network
        case nil:
            .network
        }
    }

    static func timeInterval(from duration: Duration) -> TimeInterval {
        let parts = duration.components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1_000_000_000_000_000_000
    }
}

private struct AnySpeakingClock: Sendable {
    private let readNow: @Sendable () -> AnySpeakingInstant
    private let sleepFor: @Sendable (Duration) async throws -> Void

    init<C: Clock>(_ clock: C) where C.Duration == Duration {
        readNow = {
            AnySpeakingInstant(clock.now) { deadline in
                try await clock.sleep(until: deadline, tolerance: nil)
            }
        }
        sleepFor = { duration in
            try await clock.sleep(until: clock.now.advanced(by: duration), tolerance: nil)
        }
    }

    var now: AnySpeakingInstant { readNow() }

    func sleep(for duration: Duration) async throws {
        try await sleepFor(duration)
    }

    func sleep(until instant: AnySpeakingInstant) async throws {
        try await instant.sleepUntil()
    }
}

private struct AnySpeakingInstant: @unchecked Sendable {
    private let value: Any
    private let durationTo: @Sendable (Any) -> Duration
    private let advance: @Sendable (Duration) -> AnySpeakingInstant
    private let sleep: @Sendable () async throws -> Void

    init<I: InstantProtocol>(
        _ instant: I,
        sleepUntil: @escaping @Sendable (I) async throws -> Void
    ) where I.Duration == Duration {
        value = instant
        durationTo = { other in
            guard let otherInstant = other as? I else {
                preconditionFailure("Clock instant types must match")
            }
            return instant.duration(to: otherInstant)
        }
        advance = { duration in
            AnySpeakingInstant(instant.advanced(by: duration), sleepUntil: sleepUntil)
        }
        sleep = { try await sleepUntil(instant) }
    }

    func duration(to other: AnySpeakingInstant) -> Duration { durationTo(other.value) }

    func advanced(by duration: Duration) -> AnySpeakingInstant { advance(duration) }

    func sleepUntil() async throws {
        try await sleep()
    }

}

private final class CaptureQueueOverflowSignal: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var didOverflow: Bool { lock.withLock { value } }
    func markOverflow() { lock.withLock { value = true } }
}

private final class CaptureGenerationGate: @unchecked Sendable {
    private let lock = NSLock()
    private var generation: UInt64 = 0
    private var isOpen = false

    func activate() -> UInt64 {
        lock.withLock {
            generation &+= 1
            isOpen = true
            return generation
        }
    }

    func invalidate() {
        lock.withLock {
            generation &+= 1
            isOpen = false
        }
    }

    func isActive(_ expectedGeneration: UInt64) -> Bool {
        lock.withLock { isOpen && generation == expectedGeneration }
    }
}

private extension SpeakingCallPhase {
    var isTerminal: Bool {
        switch self {
        case .ended, .failed:
            true
        case .idle, .connecting, .live, .reconnecting:
            false
        }
    }
}
