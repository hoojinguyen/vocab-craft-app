@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class ResilientReflexSpeechEngineTests: XCTestCase {
    private var engine: ResilientReflexSpeechEngine!

    override func setUp() {
        super.setUp()
        engine = ResilientReflexSpeechEngine()
    }

    override func tearDown() {
        engine.stopSession()
        engine = nil
        super.tearDown()
    }

    func testStartSession_activatesSession() {
        engine.startSession(contextualPhrases: ["hello", "world"])
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testStopSession_deactivatesEverything() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testBeginWord_activatesWord() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: ["test"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    func testEndWord_deactivatesWordKeepsSession() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.endWord()
        XCTAssertFalse(engine.isWordActive)
        XCTAssertTrue(engine.isSessionActive)
    }

    func testMultipleWordCycles_nocrash() {
        engine.startSession(contextualPhrases: [])
        for i in 0..<10 {
            engine.beginWord(targetLemma: "word\(i)", contextualPhrases: [])
            engine.endWord()
        }
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testSimulateTranscript_updatesLiveTranscript() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateTranscript("hello world")
        XCTAssertEqual(engine.liveTranscript, "hello world")
        XCTAssertEqual(received, "hello world")
    }

    func testSimulateTranscript_matchDetected() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: [])
        engine.simulateTranscript("ephemeral")
        XCTAssertEqual(matched, "ephemeral")
    }

    func testSimulateTranscript_noMatchForWrongWord() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertNil(matched)
    }

    func testSimulateTranscript_ignoredWhenWordNotActive() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertNil(received)
    }

    func testBeginWord_endsPreviousWordAutomatically() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "word1", contextualPhrases: [])
        XCTAssertTrue(engine.isWordActive)
        engine.beginWord(targetLemma: "word2", contextualPhrases: [])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    func testAudioBufferRelay_threadSafetyAndNilHandling() {
        let relay = AudioBufferRelay()
        relay.setRequest(nil)
        XCTAssertNotNil(relay)
    }
}
