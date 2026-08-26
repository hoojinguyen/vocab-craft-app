import Foundation
import Observation

/// Orchestrates real-time speech assessment, combining acoustic recognition,
/// accent-tolerant fuzzy evaluation, instant reflex pass triggering, and silence auto-stop.
@MainActor
@Observable
public final class SpeechAssessmentService: SpeechAssessmentProtocol, @unchecked Sendable {
    // MARK: - State

    public private(set) var isListening: Bool = false
    public private(set) var currentEvaluation: SpeechEvaluationResult?

    // MARK: - Dependencies

    private let engine: SpeechRecognitionEngineProtocol
    private let initialSilenceDuration: Duration
    private let silenceDuration: Duration
    private var silenceDetector: SilenceDetector?
    private var currentSessionToken = UUID()

    // MARK: - Initialization

    /// Initializes a speech assessment service with optional engine and silence durations.
    ///
    /// - Parameters:
    ///   - recognitionEngine: Audio recognition engine conforming to `SpeechRecognitionEngineProtocol`.
    ///   - initialSilenceDuration: Duration to wait before first speech before auto-stopping (default: 5.0s).
    ///   - silenceDuration: Duration of silence after speech activity before auto-stopping (default: 1.3s).
    public init(
        recognitionEngine: SpeechRecognitionEngineProtocol = SpeechRecognitionEngine(),
        initialSilenceDuration: Duration = .seconds(5),
        silenceDuration: Duration = .milliseconds(1300)
    ) {
        self.engine = recognitionEngine
        self.initialSilenceDuration = initialSilenceDuration
        self.silenceDuration = silenceDuration
    }

    /// Convenience initializer using default 5s initial silence and custom trailing silence duration.
    public convenience init(
        recognitionEngine: SpeechRecognitionEngineProtocol = SpeechRecognitionEngine(),
        silenceDuration: Duration = .milliseconds(1300)
    ) {
        self.init(
            recognitionEngine: recognitionEngine,
            initialSilenceDuration: .seconds(5),
            silenceDuration: silenceDuration
        )
    }

    deinit {
        engine.stop()
    }

    // MARK: - SpeechAssessmentProtocol

    /// Starts assessing speech against a target sentence.
    ///
    /// - Parameters:
    ///   - targetSentence: The expected target phrase or sentence.
    ///   - toleranceThreshold: Pass ratio threshold (default: 0.75 / 75%).
    ///   - contextualPhrases: Additional keywords or target phrases used to bias acoustic STT.
    ///   - onProgress: Real-time callback emitting intermediate evaluations.
    ///   - onCompletion: Final evaluation callback upon instant pass, final result, or silence auto-stop.
    ///   - onError: Error callback if recognition or audio engine fails.
    public func startAssessing(
        targetSentence: String,
        toleranceThreshold: Double = 0.75,
        contextualPhrases: [String] = [],
        onProgress: @escaping (SpeechEvaluationResult) -> Void = { _ in },
        onCompletion: @escaping (SpeechEvaluationResult) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        let trimmedTarget = targetSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTarget.isEmpty else {
            onError(SpeechKitError.emptyTargetSentence)
            return
        }

        if isListening {
            stopAssessing()
        }

        let sessionToken = UUID()
        currentSessionToken = sessionToken
        isListening = true
        currentEvaluation = nil

        let startTime = Date()

        // Contextual biasing: bias towards target sentence and provided keywords
        var biasedPhrases = contextualPhrases
        if !biasedPhrases.contains(targetSentence) {
            biasedPhrases.append(targetSentence)
        }

        // Setup silence auto-stop detector with dual-phase timers and arm it immediately
        let detector = makeSilenceDetector(
            sessionToken: sessionToken,
            targetSentence: targetSentence,
            toleranceThreshold: toleranceThreshold,
            startTime: startTime,
            onCompletion: onCompletion
        )
        self.silenceDetector = detector
        detector.arm()

        engine.requestAuthorization { [weak self] authorized in
            let handleAuth: @MainActor () -> Void = { [weak self] in
                guard let self, self.isListening, self.currentSessionToken == sessionToken else { return }
                guard authorized else {
                    self.stopAssessing()
                    onError(SpeechKitError.speechRecognitionNotAuthorized)
                    return
                }

                self.beginEngineCapture(
                    sessionToken: sessionToken,
                    targetSentence: targetSentence,
                    toleranceThreshold: toleranceThreshold,
                    biasedPhrases: biasedPhrases,
                    startTime: startTime,
                    onProgress: onProgress,
                    onCompletion: onCompletion,
                    onError: onError
                )
            }

            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    handleAuth()
                }
            } else {
                Task { @MainActor in
                    handleAuth()
                }
            }
        }
    }

    private func makeSilenceDetector(
        sessionToken: UUID,
        targetSentence: String,
        toleranceThreshold: Double,
        startTime: Date,
        onCompletion: @escaping (SpeechEvaluationResult) -> Void
    ) -> SilenceDetector {
        SilenceDetector(
            initialSilenceDuration: initialSilenceDuration,
            trailingSilenceDuration: silenceDuration
        ) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.isListening, self.currentSessionToken == sessionToken else { return }
                let finalEval = self.currentEvaluation ?? FuzzySpeechMatcher.evaluate(
                    spokenText: "",
                    targetSentence: targetSentence,
                    passThreshold: toleranceThreshold,
                    durationMs: Int(Date().timeIntervalSince(startTime) * 1000)
                )
                self.stopAssessing()
                onCompletion(finalEval)
            }
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func beginEngineCapture(
        sessionToken: UUID,
        targetSentence: String,
        toleranceThreshold: Double,
        biasedPhrases: [String],
        startTime: Date,
        onProgress: @escaping (SpeechEvaluationResult) -> Void,
        onCompletion: @escaping (SpeechEvaluationResult) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        do {
            try self.engine.start(
                contextualPhrases: biasedPhrases,
                onPartialResult: { [weak self] partialText in
                    Task { @MainActor [weak self] in
                        guard let self, self.isListening, self.currentSessionToken == sessionToken else { return }
                        self.silenceDetector?.registerActivity()

                        let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
                        let eval = FuzzySpeechMatcher.evaluate(
                            spokenText: partialText,
                            targetSentence: targetSentence,
                            passThreshold: toleranceThreshold,
                            durationMs: durationMs
                        )
                        self.currentEvaluation = eval
                        onProgress(eval)

                        // Instant Reflex Trigger: pass threshold reached with sufficient token coverage
                        let matchedTokensCount = eval.tokens.filter { $0.status != .missing }.count
                        let requiredCoverage = max(1, Int(Double(eval.tokens.count) * 0.85))
                        let hasSufficientCoverage = matchedTokensCount >= requiredCoverage || eval.overallScore >= 95.0

                        if eval.isPassed && hasSufficientCoverage {
                            self.stopAssessing()
                            onCompletion(eval)
                        }
                    }
                },
                onFinalResult: { [weak self] finalText in
                    Task { @MainActor [weak self] in
                        guard let self, self.isListening, self.currentSessionToken == sessionToken else { return }
                        let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
                        let eval = FuzzySpeechMatcher.evaluate(
                            spokenText: finalText,
                            targetSentence: targetSentence,
                            passThreshold: toleranceThreshold,
                            durationMs: durationMs
                        )
                        self.currentEvaluation = eval
                        self.stopAssessing()
                        onCompletion(eval)
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        guard let self, self.isListening, self.currentSessionToken == sessionToken else { return }
                        self.stopAssessing()
                        onError(error)
                    }
                }
            )
        } catch {
            self.stopAssessing()
            onError(error)
        }
    }

    /// Stops the active speech assessment session and releases recognition resources.
    public func stopAssessing() {
        currentSessionToken = UUID()
        silenceDetector?.cancel()
        silenceDetector = nil
        engine.stop()
        isListening = false
    }
}
