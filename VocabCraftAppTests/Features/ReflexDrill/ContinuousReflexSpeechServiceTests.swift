@testable import VocabCraftApp
import XCTest

final class ContinuousReflexSpeechServiceTests: XCTestCase {
    func testTargetSwitchingAndMatching() {
        let mockService = MockContinuousReflexSpeechService()
        var matchedTarget: String?

        mockService.onMatchDetected = { matched in
            matchedTarget = matched
        }

        mockService.startSession()
        XCTAssertTrue(mockService.isSessionActive)

        // Set target 1
        mockService.setTargetWord(lemma: "ephemeral", contextualPhrases: ["Her fame proved to be ephemeral"])
        mockService.simulateTranscript("I think it is ephemeral indeed")
        XCTAssertEqual(matchedTarget, "ephemeral")

        // Reset and switch to target 2 without stopping session
        matchedTarget = nil
        mockService.setTargetWord(lemma: "serendipity", contextualPhrases: ["Pure serendipity"])
        mockService.simulateTranscript("serendipity")
        XCTAssertEqual(matchedTarget, "serendipity")

        mockService.stopSession()
        XCTAssertFalse(mockService.isSessionActive)
    }

    func testMockServiceResetBufferAndNoMatch() {
        let mockService = MockContinuousReflexSpeechService()
        var matchCount = 0
        mockService.onMatchDetected = { _ in matchCount += 1 }

        mockService.startSession()
        mockService.setTargetWord(lemma: "ephemeral", contextualPhrases: ["Her fame proved to be ephemeral"])

        mockService.simulateTranscript("completely unrelated text")
        XCTAssertEqual(matchCount, 0)
        XCTAssertEqual(mockService.currentTranscript, "completely unrelated text")

        mockService.resetBuffer()
        XCTAssertEqual(mockService.currentTranscript, "")

        mockService.stopSession()
        XCTAssertFalse(mockService.isSessionActive)
        XCTAssertEqual(mockService.currentTargetLemma, "")
    }

    func testMockServiceCaseInsensitiveAndPunctuationMatching() {
        let mockService = MockContinuousReflexSpeechService()
        var matchedWords: [String] = []
        mockService.onMatchDetected = { word in
            matchedWords.append(word)
        }

        mockService.startSession()
        mockService.setTargetWord(lemma: "  Serendipity\n", contextualPhrases: ["A stroke of serendipity!"])
        XCTAssertEqual(mockService.currentTargetLemma, "serendipity")
        XCTAssertEqual(mockService.contextualPhrases, ["A stroke of serendipity!"])

        mockService.simulateTranscript("It was SERENDIPITY!")
        XCTAssertEqual(matchedWords, ["serendipity"])
    }

    func testContinuousReflexSpeechServiceInitialState() {
        let service = ContinuousReflexSpeechService()
        XCTAssertFalse(service.isSessionActive)
        XCTAssertEqual(service.currentTranscript, "")

        var updateReceived: String?
        var matchReceived: String?
        var errorReceived: Error?

        service.onTranscriptUpdate = { updateReceived = $0 }
        service.onMatchDetected = { matchReceived = $0 }
        service.onError = { errorReceived = $0 }

        XCTAssertNil(updateReceived)
        XCTAssertNil(matchReceived)
        XCTAssertNil(errorReceived)

        service.setTargetWord(lemma: " ubiquitous ", contextualPhrases: ["Smartphones are ubiquitous"])
        service.resetBuffer()
        XCTAssertEqual(service.currentTranscript, "")

        service.stopSession()
        XCTAssertFalse(service.isSessionActive)
        XCTAssertEqual(service.currentTranscript, "")
    }
}
