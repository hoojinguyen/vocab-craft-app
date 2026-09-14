import Foundation

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
    func teardown() async
}

public extension ConversationSpeechPlaying {
    func teardown() async {}
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
        operationGeneration += 1
        let generation = operationGeneration
        if let existingCaptureID = activeCapture?.id {
            finishCapture(.cancelled, captureID: existingCaptureID)
        }
        guard !Task.isCancelled else { return .cancelled }
        let result = await player.play(text: text, locale: locale)
        guard !Task.isCancelled, generation == operationGeneration else { return .cancelled }
        return result
    }

    public func capture(
        targetSentence: String,
        contextualPhrases: [String],
        onListening: @escaping @MainActor @Sendable () -> Void,
        onPartial: @escaping @MainActor @Sendable (String) -> Void
    ) async -> ConversationCaptureResult {
        operationGeneration += 1
        let generation = operationGeneration
        if let existingCaptureID = activeCapture?.id {
            finishCapture(.cancelled, captureID: existingCaptureID)
        }
        guard !Task.isCancelled else { return .cancelled }

        let isAuthorized = await recognizer.requestAuthorization()
        guard !Task.isCancelled, generation == operationGeneration else { return .cancelled }
        guard isAuthorized else { return .permissionDenied }

        player.stop()
        await player.teardown()
        guard !Task.isCancelled, generation == operationGeneration else { return .cancelled }

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
                guard !Task.isCancelled, generation == self.operationGeneration else {
                    Task { [audioSessionCoordinator] in
                        await audioSessionCoordinator.release(lease)
                        continuation.resume(returning: .cancelled)
                    }
                    return
                }

                self.activeCapture = ActiveCapture(id: captureID, continuation: continuation, lease: lease)
                var phrases = contextualPhrases
                let trimmedTarget = targetSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedTarget.isEmpty {
                    if let index = phrases.firstIndex(of: trimmedTarget) {
                        phrases.remove(at: index)
                    }
                    phrases.insert(trimmedTarget, at: 0)
                }
                do {
                    try self.recognizer.start(
                        contextualPhrases: phrases,
                        onPartial: { [weak self] transcript in
                            self?.receivePartial(transcript, captureID: captureID, onPartial: onPartial)
                        },
                        onFinal: { [weak self] transcript in
                            guard let self, self.activeCapture?.id == captureID else { return }
                            let currentLatest = self.activeCapture?.latestTranscript ?? ""
                            let candidate = transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? currentLatest
                                : transcript
                            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
                            self.finishCapture(
                                trimmed.isEmpty ? .silence : .transcript(trimmed),
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
                    self.finishCapture(error == .unavailable ? .unavailable : .failed, captureID: captureID)
                    return
                } catch {
                    self.finishCapture(.failed, captureID: captureID)
                    return
                }

                onListening()
                self.scheduleTimer(.initialSilence, after: self.capturePolicy.initialSilence, captureID: captureID)
                self.scheduleTimer(.maximumDuration, after: self.capturePolicy.maximumDuration, captureID: captureID)
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
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Empty partial does not cancel initial silence or reset trailing timer.
            return
        }

        // Non-empty speech detected: cancel initial silence
        capture.initialSilenceTask?.cancel()
        capture.initialSilenceTask = nil

        // Only reset trailing timer if transcript actually changed
        guard transcript != capture.latestTranscript else { return }

        capture.latestTranscript = transcript
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
            guard capture.latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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
