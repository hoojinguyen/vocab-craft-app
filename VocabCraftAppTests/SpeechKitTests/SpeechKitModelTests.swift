import XCTest
@testable import VocabCraftApp

final class SpeechKitModelTests: XCTestCase {

    // MARK: - WordMatchStatus Tests

    func testWordMatchStatus_rawValuesAndCodable() throws {
        XCTAssertEqual(WordMatchStatus.exactMatch.rawValue, "exactMatch")
        XCTAssertEqual(WordMatchStatus.fuzzyMatch.rawValue, "fuzzyMatch")
        XCTAssertEqual(WordMatchStatus.missing.rawValue, "missing")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let status = WordMatchStatus.fuzzyMatch
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(WordMatchStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    // MARK: - WordTokenResult Tests

    func testWordTokenResult_initializationAndCodable() throws {
        let token = WordTokenResult(
            id: 1,
            targetWord: "apple",
            spokenWord: "aple",
            status: .fuzzyMatch,
            similarityScore: 0.8
        )

        XCTAssertEqual(token.id, 1)
        XCTAssertEqual(token.targetWord, "apple")
        XCTAssertEqual(token.spokenWord, "aple")
        XCTAssertEqual(token.status, .fuzzyMatch)
        XCTAssertEqual(token.similarityScore, 0.8)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(token)
        let decoded = try decoder.decode(WordTokenResult.self, from: data)
        XCTAssertEqual(decoded, token)
    }

    func testWordTokenResult_defaultValues() {
        let token = WordTokenResult(id: 0, targetWord: "banana")
        XCTAssertEqual(token.id, 0)
        XCTAssertEqual(token.targetWord, "banana")
        XCTAssertNil(token.spokenWord)
        XCTAssertEqual(token.status, .missing)
        XCTAssertEqual(token.similarityScore, 0.0)
    }

    // MARK: - SpeechEvaluationResult Tests

    func testSpeechEvaluationResult_initializationAndCodable() throws {
        let tokens = [
            WordTokenResult(id: 0, targetWord: "hello", spokenWord: "hello", status: .exactMatch, similarityScore: 1.0),
            WordTokenResult(id: 1, targetWord: "world", spokenWord: "world", status: .exactMatch, similarityScore: 1.0)
        ]

        let result = SpeechEvaluationResult(
            targetSentence: "hello world",
            spokenText: "hello world",
            tokens: tokens,
            overallScore: 100.0,
            isPassed: true,
            durationMs: 1200
        )

        XCTAssertEqual(result.targetSentence, "hello world")
        XCTAssertEqual(result.spokenText, "hello world")
        XCTAssertEqual(result.tokens.count, 2)
        XCTAssertEqual(result.overallScore, 100.0)
        XCTAssertTrue(result.isPassed)
        XCTAssertEqual(result.durationMs, 1200)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(result)
        let decoded = try decoder.decode(SpeechEvaluationResult.self, from: data)
        XCTAssertEqual(decoded, result)
    }

    func testSpeechEvaluationResult_emptyHelper() {
        let emptyResult = SpeechEvaluationResult.empty(targetSentence: "The quick brown fox")
        XCTAssertEqual(emptyResult.targetSentence, "The quick brown fox")
        XCTAssertEqual(emptyResult.spokenText, "")
        XCTAssertTrue(emptyResult.tokens.isEmpty)
        XCTAssertEqual(emptyResult.overallScore, 0.0)
        XCTAssertFalse(emptyResult.isPassed)
        XCTAssertEqual(emptyResult.durationMs, 0)
    }

    // MARK: - SpeechKitError Tests

    func testSpeechKitError_localizedDescriptionsAndEquality() {
        let errors: [SpeechKitError] = [
            .speechRecognitionNotAuthorized,
            .microphoneNotAuthorized,
            .recognizerUnavailable,
            .audioSessionConfigurationFailed,
            .audioBufferCreationFailed,
            .emptyTargetSentence
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }

        XCTAssertEqual(SpeechKitError.speechRecognitionNotAuthorized, SpeechKitError.speechRecognitionNotAuthorized)
        XCTAssertNotEqual(SpeechKitError.speechRecognitionNotAuthorized, SpeechKitError.microphoneNotAuthorized)
    }

    // MARK: - SpeechAssessmentProtocol Mock Test

    @MainActor
    func testSpeechAssessmentProtocol_mockImplementation() {
        final class MockSpeechAssessmentService: SpeechAssessmentProtocol {
            var isListening: Bool = false
            var currentEvaluation: SpeechEvaluationResult?

            var didStartAssessing = false
            var didStopAssessing = false
            var receivedTargetSentence: String?
            var receivedToleranceThreshold: Double?
            var receivedContextualPhrases: [String]?

            func startAssessing(
                targetSentence: String,
                toleranceThreshold: Double,
                contextualPhrases: [String],
                onProgress: @escaping (SpeechEvaluationResult) -> Void,
                onCompletion: @escaping (SpeechEvaluationResult) -> Void,
                onError: @escaping (Error) -> Void
            ) {
                didStartAssessing = true
                receivedTargetSentence = targetSentence
                receivedToleranceThreshold = toleranceThreshold
                receivedContextualPhrases = contextualPhrases
                isListening = true
            }

            func stopAssessing() {
                didStopAssessing = true
                isListening = false
            }
        }

        let mock = MockSpeechAssessmentService()
        XCTAssertFalse(mock.isListening)
        XCTAssertNil(mock.currentEvaluation)

        mock.startAssessing(
            targetSentence: "Sample sentence",
            toleranceThreshold: 0.75,
            contextualPhrases: ["Sample", "sentence"],
            onProgress: { _ in },
            onCompletion: { _ in },
            onError: { _ in }
        )

        XCTAssertTrue(mock.didStartAssessing)
        XCTAssertTrue(mock.isListening)
        XCTAssertEqual(mock.receivedTargetSentence, "Sample sentence")
        XCTAssertEqual(mock.receivedToleranceThreshold, 0.75)
        XCTAssertEqual(mock.receivedContextualPhrases, ["Sample", "sentence"])

        mock.stopAssessing()
        XCTAssertTrue(mock.didStopAssessing)
        XCTAssertFalse(mock.isListening)
    }
}
