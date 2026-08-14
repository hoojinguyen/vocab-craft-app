import Foundation

@MainActor
public protocol SpeechAssessmentProtocol: AnyObject {
    var isListening: Bool { get }
    var currentEvaluation: SpeechEvaluationResult? { get }

    func startAssessing(
        targetSentence: String,
        toleranceThreshold: Double,
        contextualPhrases: [String],
        onProgress: @escaping (SpeechEvaluationResult) -> Void,
        onCompletion: @escaping (SpeechEvaluationResult) -> Void,
        onError: @escaping (Error) -> Void
    )

    func stopAssessing()
}

public extension SpeechAssessmentProtocol {
    func startAssessing(
        targetSentence: String,
        toleranceThreshold: Double = 0.75,
        contextualPhrases: [String] = [],
        onProgress: @escaping (SpeechEvaluationResult) -> Void = { _ in },
        onCompletion: @escaping (SpeechEvaluationResult) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        startAssessing(
            targetSentence: targetSentence,
            toleranceThreshold: toleranceThreshold,
            contextualPhrases: contextualPhrases,
            onProgress: onProgress,
            onCompletion: onCompletion,
            onError: onError
        )
    }
}
