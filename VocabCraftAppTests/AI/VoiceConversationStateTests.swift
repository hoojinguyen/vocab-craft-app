import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Voice Conversation State Tests")
struct VoiceConversationStateTests {
    @Test("Verify VoiceCallState equality and transitions")
    func stateEquality() {
        let idle = VoiceCallState.idle
        let speaking = VoiceCallState.speaking(characterText: "Hello there!")
        let listening = VoiceCallState.listening(liveTranscript: "I want coffee")
        let thinking = VoiceCallState.thinking
        let ended = VoiceCallState.ended

        #expect(idle != speaking)
        #expect(speaking != listening)
        #expect(listening != thinking)
        #expect(thinking != ended)
        #expect(VoiceCallState.speaking(characterText: "A") == VoiceCallState.speaking(characterText: "A"))
        #expect(VoiceCallState.speaking(characterText: "A") != VoiceCallState.speaking(characterText: "B"))
    }

    @Test("Verify RoleplayMessage initialization and equality")
    func messageProperties() {
        let id = UUID()
        let now = Date()
        let userMsg = RoleplayMessage(
            id: id,
            sender: .user,
            text: "Hello",
            timestamp: now,
            refinementSuggestion: "Hi there",
            pedagogicalNote: "Good greeting"
        )
        let aiMsg = RoleplayMessage(
            id: id,
            sender: .character(name: "Alex"),
            text: "Welcome",
            timestamp: now
        )

        #expect(userMsg.sender == .user)
        #expect(aiMsg.sender == .character(name: "Alex"))
        #expect(userMsg != aiMsg)
        #expect(userMsg.refinementSuggestion == "Hi there")
        #expect(userMsg.pedagogicalNote == "Good greeting")
        #expect(aiMsg.refinementSuggestion == nil)
        #expect(aiMsg.pedagogicalNote == nil)
    }
}
