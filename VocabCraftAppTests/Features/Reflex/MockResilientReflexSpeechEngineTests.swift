@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class MockResilientReflexSpeechEngineTests: XCTestCase {
    private var engine: MockResilientReflexSpeechEngine!

    override func setUp() {
        super.setUp()
        engine = MockResilientReflexSpeechEngine()
    }

    func testStartSession_setsActive() {
        engine.startSession(contextualPhrases: ["hello"])
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertEqual(engine.startSessionCallCount, 1)
    }

    func testStopSession_resetsState() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    func testBeginWord_setsTargetAndActivates() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "Ephemeral", contextualPhrases: ["test"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.lastTargetLemma, "ephemeral")
        XCTAssertEqual(engine.beginWordCallCount, 1)
    }

    func testEndWord_deactivatesWord() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.endWord()
        XCTAssertFalse(engine.isWordActive)
        XCTAssertEqual(engine.endWordCallCount, 1)
    }

    func testSimulateTranscript_firesCallback() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertEqual(received, "hello")
        XCTAssertEqual(engine.liveTranscript, "hello")
    }

    func testSimulateTranscript_ignoredWhenNotActive() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.simulateTranscript("hello")
        XCTAssertNil(received)
    }

    func testSimulateMatch_firesCallback() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateMatch("test")
        XCTAssertEqual(matched, "test")
    }

    func testSimulateMatch_ignoredWhenNotActive() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.simulateMatch("test")
        XCTAssertNil(matched)
    }

    func testSimulateError_firesCallback() {
        var receivedError: Error?
        engine.onError = { receivedError = $0 }
        struct TestError: Error {}
        engine.simulateError(TestError())
        XCTAssertNotNil(receivedError)
    }
}
