import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("ReflexMode Listening Tests")
struct ReflexModeListeningTests {
    @Test("Verifies Listening mode hint stage thresholds")
    func testListeningHintStages() {
        let mode = ReflexMode.listening
        #expect(mode.timeLimitSeconds == 5.5)
        #expect(mode.hintStage(forElapsedTimeMs: 0) == 0)
        #expect(mode.hintStage(forElapsedTimeMs: 1799) == 0)
        #expect(mode.hintStage(forElapsedTimeMs: 1800) == 1)
        #expect(mode.hintStage(forElapsedTimeMs: 2999) == 1)
        #expect(mode.hintStage(forElapsedTimeMs: 3000) == 2)
        #expect(mode.hintStage(forElapsedTimeMs: 5499) == 2)
        #expect(mode.hintStage(forElapsedTimeMs: 5500) == 3)
    }
}

@Suite("ReflexMode Speaking Tests")
struct ReflexModeSpeakingTests {
    @Test("Verifies Speaking mode hint stage thresholds")
    func testSpeakingHintStages() {
        let mode = ReflexMode.speaking
        #expect(mode.timeLimitSeconds == 6.0)
        #expect(mode.hintStage(forElapsedTimeMs: 0) == 0)
        #expect(mode.hintStage(forElapsedTimeMs: 2499) == 0)
        #expect(mode.hintStage(forElapsedTimeMs: 2500) == 1)
        #expect(mode.hintStage(forElapsedTimeMs: 3999) == 1)
        #expect(mode.hintStage(forElapsedTimeMs: 4000) == 2)
        #expect(mode.hintStage(forElapsedTimeMs: 4999) == 2)
        #expect(mode.hintStage(forElapsedTimeMs: 5000) == 3)
        #expect(mode.hintStage(forElapsedTimeMs: 6000) == 3)
    }
}
#endif
