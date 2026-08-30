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
#endif
