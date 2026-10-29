import Testing
@testable import VocabCraftApp

@Suite("Speaking call view content")
struct SpeakingCallViewTests {
    @Test func liveShowsHintAndTimeLeft() {
        let content = SpeakingCallViewContent.make(phase: .live, elapsed: 300, duration: 360)

        #expect(content.timeLeft == 60)
        #expect(content.showsHint)
        #expect(!content.showsReconnecting)
        #expect(content.failure == nil)
        #expect(content.statusKey.isEmpty)
    }

    @Test func reconnectingHidesHintAndKeepsCountdown() {
        let content = SpeakingCallViewContent.make(phase: .reconnecting, elapsed: 310, duration: 360)

        #expect(!content.showsHint)
        #expect(content.showsReconnecting)
        #expect(content.timeLeft == 50)
        #expect(content.statusKey == "app.speaking.call.reconnecting")
    }

    @Test func failedQuotaExposesFailure() {
        let content = SpeakingCallViewContent.make(phase: .failed(.quotaExceeded), elapsed: 12, duration: 360)

        #expect(content.failure == .quotaExceeded)
        #expect(content.statusKey == "app.speaking.error.quota")
        #expect(content.timeLeft == nil)
        #expect(!content.showsHint)
    }

    @Test func liveCountdownNeverGoesBelowZero() {
        let content = SpeakingCallViewContent.make(phase: .live, elapsed: 400, duration: 360)

        #expect(content.timeLeft == 0)
    }
}
