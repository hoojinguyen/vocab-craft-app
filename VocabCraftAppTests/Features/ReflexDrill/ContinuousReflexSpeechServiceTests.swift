import Foundation
import AVFoundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class ContinuousReflexSpeechServiceTests: XCTestCase {
    func testTargetSwitchingAndMatching() {
        let mockService: ContinuousReflexSpeechProtocol = MockContinuousReflexSpeechService()
        var matchedTarget: String?

        mockService.onMatchDetected = { matched in
            matchedTarget = matched
        }

        mockService.startSession(contextualPhrases: ["ephemeral", "serendipity"])
        XCTAssertTrue(mockService.isSessionActive)

        // Set target 1
        mockService.setTargetWord(lemma: "ephemeral", contextualPhrases: ["Her fame proved to be ephemeral"])
        (mockService as? MockContinuousReflexSpeechService)?.simulateTranscript("I think it is ephemeral indeed")
        XCTAssertEqual(matchedTarget, "ephemeral")

        // Reset and switch to target 2 without stopping session
        matchedTarget = nil
        mockService.setTargetWord(lemma: "serendipity", contextualPhrases: ["Pure serendipity"])
        (mockService as? MockContinuousReflexSpeechService)?.simulateTranscript("I think it is ephemeral indeed serendipity")
        XCTAssertEqual(matchedTarget, "serendipity")

        mockService.stopSession()
        XCTAssertFalse(mockService.isSessionActive)
    }

    func testFuzzyMatchingAndAccentTolerance() {
        let mockService = MockContinuousReflexSpeechService()
        var matchedTarget: String?
        mockService.onMatchDetected = { matchedTarget = $0 }

        mockService.startSession()

        // 1. STT slight misspelling / accent: "reluctence" instead of "reluctant"
        mockService.setTargetWord(lemma: "reluctant", contextualPhrases: [])
        mockService.simulateTranscript("I felt very reluctence about it")
        XCTAssertEqual(matchedTarget, "reluctant", "Fuzzy matcher should tolerate slight acoustic variation in reluctant")

        // 2. STT missing ending phoneme: "ephemera" instead of "ephemeral"
        matchedTarget = nil
        mockService.setTargetWord(lemma: "ephemeral", contextualPhrases: [])
        mockService.simulateTranscript("I felt very reluctence about it ephemera")
        XCTAssertEqual(matchedTarget, "ephemeral", "Fuzzy matcher should match ephemera for ephemeral")

        // 3. STT typo: "abundent" instead of "abundant"
        matchedTarget = nil
        mockService.setTargetWord(lemma: "abundant", contextualPhrases: [])
        mockService.simulateTranscript("I felt very reluctence about it ephemera abundent")
        XCTAssertEqual(matchedTarget, "abundant", "Fuzzy matcher should match abundent for abundant")

        mockService.stopSession()
    }

    func testStemmingAndPrefixToleranceForReflex() {
        let mockService = MockContinuousReflexSpeechService()
        var matchedTarget: String?
        mockService.onMatchDetected = { matchedTarget = $0 }

        mockService.startSession()

        // Target: "hesitate", Learner utters "hesitating"
        mockService.setTargetWord(lemma: "hesitate", contextualPhrases: [])
        mockService.simulateTranscript("She was hesitating")
        XCTAssertEqual(matchedTarget, "hesitate", "Stem prefix match should recognize hesitating for hesitate")

        mockService.stopSession()
    }

    func testWordBoundaryMatchingPreventsSubstringFalsePositives() {
        let mockService = MockContinuousReflexSpeechService()
        var matchedTarget: String?
        mockService.onMatchDetected = { matchedTarget = $0 }

        mockService.startSession()
        // Target is "in"
        mockService.setTargetWord(lemma: "in", contextualPhrases: [])

        // "morning" contains "in" as a substring, but NOT as a separate word token
        mockService.simulateTranscript("Good morning everyone")
        XCTAssertNil(matchedTarget, "Substring match on 'morning' should not trigger match for 'in'")

        // Now speak "in" as a distinct word
        mockService.simulateTranscript("Good morning everyone in the room")
        XCTAssertEqual(matchedTarget, "in")
    }

    func testCumulativeTranscriptOffsetPreventsHistoricalMatching() {
        let mockService = MockContinuousReflexSpeechService()
        var matchedTarget: String?
        mockService.onMatchDetected = { matchedTarget = $0 }

        mockService.startSession()

        // Speak some sentences first
        mockService.simulateTranscript("The weather is ephemeral today")

        // Now set new target word that happened to be in previous transcript
        mockService.setTargetWord(lemma: "ephemeral", contextualPhrases: [])

        // Simulating the same transcript without new words should NOT match because of transcriptOffset
        matchedTarget = nil
        mockService.simulateTranscript("The weather is ephemeral today")
        XCTAssertNil(matchedTarget, "Historical transcript before setTargetWord should not match")

        // Now speak new phrase containing ephemeral after the offset
        mockService.simulateTranscript("The weather is ephemeral today and also ephemeral tonight")
        XCTAssertEqual(matchedTarget, "ephemeral")
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

    func testContinuousReflexSpeechServiceInitialStateAndProtocolConformance() {
        let service: ContinuousReflexSpeechProtocol = ContinuousReflexSpeechService()
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

    func testTranscriptUpdateEmitsOnlyNewlySpokenTranscriptForCurrentTarget() {
        let mockService = MockContinuousReflexSpeechService()
        var receivedTranscript: String = ""
        mockService.onTranscriptUpdate = { receivedTranscript = $0 }

        mockService.startSession()

        // Word 1: Speak phrase
        mockService.setTargetWord(lemma: "ephemeral", contextualPhrases: [])
        mockService.simulateTranscript("Hello Spain expand")
        XCTAssertEqual(receivedTranscript, "Hello Spain expand")

        // Switch to Word 2: setTargetWord updates offset
        mockService.setTargetWord(lemma: "fluent", contextualPhrases: [])

        // Now speak for word 2 (speech recognizer accumulates full session text)
        mockService.simulateTranscript("Hello Spain expand fluent")
        // The transcript emitted to UI MUST only be "fluent", NOT the historical "Hello Spain expand fluent"
        XCTAssertEqual(receivedTranscript, "fluent")

        // Switch to Word 3:
        mockService.setTargetWord(lemma: "confident", contextualPhrases: [])
        mockService.simulateTranscript("Hello Spain expand fluent confident")
        XCTAssertEqual(receivedTranscript, "confident")
    }

    func testPauseAndResumeListening() {
        let mock = MockContinuousReflexSpeechService()
        mock.startSession()
        mock.setTargetWord(lemma: "habit", contextualPhrases: [])

        mock.pauseListening()
        XCTAssertTrue(mock.isRecognitionMuted)

        var matchDetected = false
        var transcriptEmitted: String?
        mock.onMatchDetected = { _ in matchDetected = true }
        mock.onTranscriptUpdate = { transcriptEmitted = $0 }
        mock.simulateTranscript("habit")
        XCTAssertFalse(matchDetected, "Should not detect match while listening is muted/paused")
        XCTAssertNil(transcriptEmitted, "Should not emit transcript while listening is muted/paused")

        mock.resumeListening()
        XCTAssertFalse(mock.isRecognitionMuted)
        mock.simulateTranscript("habit")
        XCTAssertTrue(matchDetected, "Should detect match after resuming listening")
        XCTAssertEqual(transcriptEmitted, "habit")
    }

    func testContinuousReflexSpeechServicePauseResumeLifecycle() {
        let service: ContinuousReflexSpeechProtocol = ContinuousReflexSpeechService()
        XCTAssertFalse(service.isRecognitionMuted)

        service.pauseListening()
        XCTAssertTrue(service.isRecognitionMuted)

        service.resumeListening()
        XCTAssertFalse(service.isRecognitionMuted)

        service.pauseListening()
        XCTAssertTrue(service.isRecognitionMuted)
        service.stopSession()
        XCTAssertFalse(service.isRecognitionMuted, "Stopping session should reset recognition mute state")
    }

    func testContinuousReflexSpeechServiceSimulatorStartAndStopLifecycle() {
        let service = ContinuousReflexSpeechService()
        XCTAssertFalse(service.isSessionActive)

        service.startSession(contextualPhrases: ["test", "reflex"])
        XCTAssertTrue(service.isSessionActive)

        service.stopSession()
        XCTAssertFalse(service.isSessionActive)
        XCTAssertFalse(service.isRecognitionMuted)
        XCTAssertEqual(service.currentTranscript, "")
    }

    func testContinuousReflexSpeechServiceSimulateTranscriptAndMainActorCallbacks() {
        let service = ContinuousReflexSpeechService()
        service.startSession(contextualPhrases: ["resilient"])

        let transcriptExpectation = expectation(description: "Transcript update on main thread")
        let matchExpectation = expectation(description: "Match detected on main thread")

        service.onTranscriptUpdate = { transcript in
            XCTAssertTrue(Thread.isMainThread, "onTranscriptUpdate must be called on main thread")
            if transcript == "She is very resilient" {
                transcriptExpectation.fulfill()
            }
        }

        service.onMatchDetected = { matched in
            XCTAssertTrue(Thread.isMainThread, "onMatchDetected must be called on main thread")
            if matched == "resilient" {
                matchExpectation.fulfill()
            }
        }

        service.setTargetWord(lemma: "resilient", contextualPhrases: [])
        service.simulateTranscript("She is very resilient")

        wait(for: [transcriptExpectation, matchExpectation], timeout: 2.0)
        service.stopSession()
    }

    func testContinuousReflexSpeechServiceConcurrentAccessThreadSafety() {
        let service = ContinuousReflexSpeechService()
        service.startSession(contextualPhrases: ["thread", "safety"])

        let iterationCount = 200
        DispatchQueue.concurrentPerform(iterations: iterationCount) { i in
            if i % 4 == 0 {
                service.pauseListening()
            } else if i % 4 == 1 {
                service.resumeListening()
            } else if i % 4 == 2 {
                service.setTargetWord(lemma: "word\(i)", contextualPhrases: ["phrase \(i)"])
            } else {
                _ = service.isSessionActive
                _ = service.isRecognitionMuted
                _ = service.currentTranscript
                service.resetBuffer()
            }
        }

        service.stopSession()
        XCTAssertFalse(service.isSessionActive)
    }

#if os(iOS)
    func testServiceSurvivesRouteChangeNotification() {
        let service = ContinuousReflexSpeechService()
        service.startSession(contextualPhrases: ["hello"])
        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue]
        )
        XCTAssertTrue(service.isSessionActive)
        service.stopSession()
    }

    func testServiceRouteChangeWhenInactiveDoesNothing() {
        let service = ContinuousReflexSpeechService()
        XCTAssertFalse(service.isSessionActive)
        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue]
        )
        XCTAssertFalse(service.isSessionActive)
    }

    func testServiceSurvivesMultipleRouteChangeReasons() {
        let service = ContinuousReflexSpeechService()
        service.startSession(contextualPhrases: ["test"])

        let reasons: [AVAudioSession.RouteChangeReason] = [
            .newDeviceAvailable,
            .oldDeviceUnavailable,
            .categoryChange,
            .override,
            .wakeFromSleep,
            .noSuitableRouteForCategory,
            .routeConfigurationChange
        ]
        for reason in reasons {
            NotificationCenter.default.post(
                name: AVAudioSession.routeChangeNotification,
                object: nil,
                userInfo: [AVAudioSessionRouteChangeReasonKey: reason.rawValue]
            )
            XCTAssertTrue(service.isSessionActive)
        }
        service.stopSession()
    }
#endif
}
