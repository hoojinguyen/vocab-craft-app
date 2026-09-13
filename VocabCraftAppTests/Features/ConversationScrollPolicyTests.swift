import Testing
@testable import VocabCraftApp

@Suite("Conversation scroll policy")
struct ConversationScrollPolicyTests {
    @Test("active turns auto-scroll until the learner manually scrolls")
    func automaticScrollGate() {
        var policy = ConversationScrollPolicy()
        #expect(policy.target(for: "turn-2") == "turn-2")
        policy.markManualScroll()
        #expect(policy.target(for: "turn-3") == nil)
        policy.returnToCurrent()
        #expect(policy.target(for: "turn-3") == "turn-3")
    }
}
