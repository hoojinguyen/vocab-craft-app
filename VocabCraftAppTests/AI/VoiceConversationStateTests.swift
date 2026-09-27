import Foundation
import SwiftUI
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

    @Test("Verify CraftVoiceOrbView renders for all VoiceCallStates")
    @MainActor
    func orbViewRendering() {
        let testStates: [VoiceCallState] = [
            .idle,
            .speaking(characterText: "Hello there!"),
            .listening(liveTranscript: "I would like a latte"),
            .thinking,
            .ended
        ]

        for state in testStates {
            let orb = CraftVoiceOrbView(state: state)
            #expect(orb.state == state)
            _ = orb.body
        }
    }

    @Test("Verify OrbVisualState discrete mapping and stability during transcript mutation")
    func orbVisualStateMappingAndStability() {
        // Discrete mapping
        #expect(VoiceCallState.idle.visualState == .idle)
        #expect(VoiceCallState.speaking(characterText: "Hello").visualState == .speaking)
        #expect(VoiceCallState.listening(liveTranscript: "").visualState == .listening)
        #expect(VoiceCallState.thinking.visualState == .thinking)
        #expect(VoiceCallState.ended.visualState == .ended)

        // Stability during live transcript updates (decoupling from animation jitter)
        let listeningEmpty = VoiceCallState.listening(liveTranscript: "")
        let listeningWord1 = VoiceCallState.listening(liveTranscript: "I")
        let listeningWord2 = VoiceCallState.listening(liveTranscript: "I would")
        let listeningSentence = VoiceCallState.listening(liveTranscript: "I would like a cappuccino please")

        #expect(listeningEmpty != listeningWord1)
        #expect(listeningWord1 != listeningWord2)
        #expect(listeningEmpty.visualState == listeningWord1.visualState)
        #expect(listeningWord1.visualState == listeningWord2.visualState)
        #expect(listeningWord2.visualState == listeningSentence.visualState)
        #expect(listeningSentence.visualState == .listening)

        // Stability during speaking text updates
        let speakingShort = VoiceCallState.speaking(characterText: "Hi")
        let speakingLong = VoiceCallState.speaking(characterText: "Hi, what kind of coffee would you like today?")
        #expect(speakingShort != speakingLong)
        #expect(speakingShort.visualState == speakingLong.visualState)
        #expect(speakingLong.visualState == .speaking)
    }
}
