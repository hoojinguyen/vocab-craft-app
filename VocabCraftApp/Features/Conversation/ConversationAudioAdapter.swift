import Foundation
import SpeechKit

public enum ConversationPlaybackResult: Equatable, Sendable {
    case finished
    case cancelled
    case failed
}

public enum ConversationCaptureResult: Equatable, Sendable {
    case transcript(String)
    case silence
    case permissionDenied
    case unavailable
    case failed
    case cancelled
}

public enum ConversationRecognitionError: Error, Equatable, Sendable {
    case unavailable
    case failed
}

@MainActor
public protocol ConversationSpeechPlaying: AnyObject {
    func play(text: String, locale: String) async -> ConversationPlaybackResult
    func stop()
}

@MainActor
public protocol ConversationSpeechRecognizing: AnyObject {
    func requestAuthorization() async -> Bool
    func start(
        contextualPhrases: [String],
        onPartial: @escaping @MainActor @Sendable (String) -> Void,
        onFinal: @escaping @MainActor @Sendable (String) -> Void,
        onError: @escaping @MainActor @Sendable (ConversationRecognitionError) -> Void
    ) throws
    func stop()
}

public protocol ConversationSleeping: Sendable {
    func sleep(for duration: Duration) async throws
}

public struct ContinuousConversationSleeper: ConversationSleeping {
    public init() {}

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}

public struct ConversationCapturePolicy: Sendable {
    public let initialSilence: Duration
    public let trailingInactivity: Duration
    public let maximumDuration: Duration

    public init(
        initialSilence: Duration = .seconds(4),
        trailingInactivity: Duration = .milliseconds(1_500),
        maximumDuration: Duration = .seconds(20)
    ) {
        self.initialSilence = initialSilence
        self.trailingInactivity = trailingInactivity
        self.maximumDuration = maximumDuration
    }
}

@MainActor
public protocol ConversationAudioClient: AnyObject {
    func play(text: String, locale: String) async -> ConversationPlaybackResult
    func capture(
        targetSentence: String,
        contextualPhrases: [String],
        onListening: @escaping @MainActor @Sendable () -> Void,
        onPartial: @escaping @MainActor @Sendable (String) -> Void
    ) async -> ConversationCaptureResult
    func stop()
}

@MainActor
public final class ConversationAudioAdapter: ConversationAudioClient {
    private struct ActiveCapture {
        let id: UUID
        let continuation: CheckedContinuation<ConversationCaptureResult, Never>
        let lease: AudioSessionLease
        var latestTranscript = ""
        var initialSilenceTask: Task<Void, Never>?
        var trailingInactivityTask: Task<Void, Never>?
        var maximumDurationTask: Task<Void, Never>?
    }

    private enum TimerKind {
        case initialSilence
        case trailingInactivity
        case maximumDuration
    }

    private let player: any ConversationSpeechPlaying
    private let recognizer: any ConversationSpeechRecognizing
    private let audioSessionCoordinator: any AudioSessionCoordinating
    private let sleeper: any ConversationSleeping
    private let capturePolicy: ConversationCapturePolicy
    private var activeCapture: ActiveCapture?
    private var operationGeneration: UInt = 0

    public init(
        player: any ConversationSpeechPlaying,
        recognizer: any ConversationSpeechRecognizing,
        audioSessionCoordinator: any AudioSessionCoordinating,
        sleeper: any ConversationSleeping = ContinuousConversationSleeper(),
        capturePolicy: ConversationCapturePolicy = .init()
    ) {
        self.player = player
        self.recognizer = recognizer
        self.audioSessionCoordinator = audioSessionCoordinator
        self.sleeper = sleeper
        self.capturePolicy = capturePolicy
    }

    public func play(text: String, locale: String = "en-US") async -> ConversationPlaybackResult {
        guard !Task.isCancelled else { return .cancelled }
        let result = await player.play(text: text, locale: locale)
        return Task.isCancelled ? .cancelled : result
    }

    public func capture(
        targetSentence: String,
        contextualPhrases: [String],
        onListening: @escaping @MainActor @Sendable () -> Void,
        onPartial: @escaping @MainActor @Sendable (String) -> Void
    ) async -> ConversationCaptureResult {
        operationGeneration += 1
        let generation = operationGeneration
        guard !Task.isCancelled else { return .cancelled }
        let isAuthorized = await recognizer.requestAuthorization()
        guard !Task.isCancelled, generation == operationGeneration else { return .cancelled }
        guard isAuthorized else { return .permissionDenied }

        let lease: AudioSessionLease
        do {
            lease = try await audioSessionCoordinator.acquire(.speechCapture)
        } catch {
            return .failed
        }
        guard !Task.isCancelled, generation == operationGeneration else {
            await audioSessionCoordinator.release(lease)
            return .cancelled
        }

        let captureID = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard !Task.isCancelled else {
                    Task { await self.audioSessionCoordinator.release(lease) }
                    continuation.resume(returning: .cancelled)
                    return
                }

                activeCapture = ActiveCapture(id: captureID, continuation: continuation, lease: lease)
                do {
                    try recognizer.start(
                        contextualPhrases: contextualPhrases,
                        onPartial: { [weak self] transcript in
                            self?.receivePartial(transcript, captureID: captureID, onPartial: onPartial)
                        },
                        onFinal: { [weak self] transcript in
                            self?.finishCapture(
                                transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? .silence : .transcript(transcript),
                                captureID: captureID
                            )
                        },
                        onError: { [weak self] error in
                            self?.finishCapture(
                                error == .unavailable ? .unavailable : .failed,
                                captureID: captureID
                            )
                        }
                    )
                } catch let error as ConversationRecognitionError {
                    finishCapture(error == .unavailable ? .unavailable : .failed, captureID: captureID)
                    return
                } catch {
                    finishCapture(.failed, captureID: captureID)
                    return
                }

                onListening()
                scheduleTimer(.initialSilence, after: capturePolicy.initialSilence, captureID: captureID)
                scheduleTimer(.maximumDuration, after: capturePolicy.maximumDuration, captureID: captureID)
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.finishCapture(.cancelled, captureID: captureID)
            }
        }
    }

    public func stop() {
        operationGeneration += 1
        player.stop()
        guard let captureID = activeCapture?.id else { return }
        finishCapture(.cancelled, captureID: captureID)
    }

    private func receivePartial(
        _ transcript: String,
        captureID: UUID,
        onPartial: @MainActor @Sendable (String) -> Void
    ) {
        guard var capture = activeCapture, capture.id == captureID else { return }
        capture.latestTranscript = transcript
        capture.initialSilenceTask?.cancel()
        capture.trailingInactivityTask?.cancel()
        activeCapture = capture
        onPartial(transcript)
        scheduleTimer(.trailingInactivity, after: capturePolicy.trailingInactivity, captureID: captureID)
    }

    private func scheduleTimer(_ kind: TimerKind, after duration: Duration, captureID: UUID) {
        let task = Task { [weak self, sleeper] in
            do {
                try await sleeper.sleep(for: duration)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.timerFired(kind, captureID: captureID)
        }
        guard var capture = activeCapture, capture.id == captureID else {
            task.cancel()
            return
        }
        switch kind {
        case .initialSilence: capture.initialSilenceTask = task
        case .trailingInactivity: capture.trailingInactivityTask = task
        case .maximumDuration: capture.maximumDurationTask = task
        }
        activeCapture = capture
    }

    private func timerFired(_ kind: TimerKind, captureID: UUID) {
        guard let capture = activeCapture, capture.id == captureID else { return }
        switch kind {
        case .initialSilence:
            guard capture.latestTranscript.isEmpty else { return }
            finishCapture(.silence, captureID: captureID)
        case .trailingInactivity, .maximumDuration:
            let transcript = capture.latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            finishCapture(transcript.isEmpty ? .silence : .transcript(transcript), captureID: captureID)
        }
    }

    private func finishCapture(_ result: ConversationCaptureResult, captureID: UUID) {
        guard let capture = activeCapture, capture.id == captureID else { return }
        activeCapture = nil
        capture.initialSilenceTask?.cancel()
        capture.trailingInactivityTask?.cancel()
        capture.maximumDurationTask?.cancel()
        recognizer.stop()
        Task { [audioSessionCoordinator] in
            await audioSessionCoordinator.release(capture.lease)
            capture.continuation.resume(returning: result)
        }
    }
}

@MainActor
public final class TextToSpeechConversationPlayer: ConversationSpeechPlaying {
    private let service: TextToSpeechService

    public init(service: TextToSpeechService) {
        self.service = service
    }

    public func play(text: String, locale: String) async -> ConversationPlaybackResult {
        switch await service.speakWithCompletion(text: text, rate: 1, locale: locale) {
        case .finished: .finished
        case .cancelled: .cancelled
        case .failed: .failed
        }
    }

    public func stop() {
        service.stop()
    }
}

@MainActor
public final class SpeechKitConversationRecognizer: ConversationSpeechRecognizing {
    private let engine: any SpeechRecognitionEngineProtocol

    public init(
        engine: any SpeechRecognitionEngineProtocol = SpeechRecognitionEngine(managesAudioSession: false)
    ) {
        self.engine = engine
    }

    public func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            engine.requestAuthorization { isAuthorized in
                continuation.resume(returning: isAuthorized)
            }
        }
    }

    public func start(
        contextualPhrases: [String],
        onPartial: @escaping @MainActor @Sendable (String) -> Void,
        onFinal: @escaping @MainActor @Sendable (String) -> Void,
        onError: @escaping @MainActor @Sendable (ConversationRecognitionError) -> Void
    ) throws {
        do {
            try engine.start(
                contextualPhrases: contextualPhrases,
                onPartialResult: { transcript in
                    Task { @MainActor in onPartial(transcript) }
                },
                onFinalResult: { transcript in
                    Task { @MainActor in onFinal(transcript) }
                },
                onError: { error in
                    let result: ConversationRecognitionError
                    if let speechError = error as? SpeechKitError,
                       speechError == .recognizerUnavailable {
                        result = .unavailable
                    } else {
                        result = .failed
                    }
                    Task { @MainActor in onError(result) }
                }
            )
        } catch let speechError as SpeechKitError where speechError == .recognizerUnavailable {
            throw ConversationRecognitionError.unavailable
        } catch {
            throw ConversationRecognitionError.failed
        }
    }

    public func stop() {
        engine.stop()
    }
}
