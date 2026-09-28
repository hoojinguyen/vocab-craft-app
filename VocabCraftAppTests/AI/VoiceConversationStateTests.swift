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

    @Test("Verify CraftVoiceOrbView dynamic scaling and symbol selection with audioLevel")
    @MainActor
    func orbDynamicAudioMeteringPulse() {
        // AudioLevel 0.0 (Silence / Standby in listening)
        let silentOrb = CraftVoiceOrbView(state: .listening(liveTranscript: ""), audioLevel: 0.0)
        #expect(silentOrb.audioLevel == 0.0)
        #expect(silentOrb.stateSymbol == .mic)
        #expect(abs(silentOrb.outerGlowScale(isExpanded: true) - 1.0) < 0.001)
        #expect(abs(silentOrb.soundwaveRingScale(isExpanded: true) - 1.0) < 0.001)

        // AudioLevel 0.5 (Moderate speech)
        let moderateOrb = CraftVoiceOrbView(state: .listening(liveTranscript: "Hello"), audioLevel: 0.5)
        #expect(moderateOrb.audioLevel == 0.5)
        #expect(moderateOrb.stateSymbol == .waveform)
        #expect(abs(moderateOrb.outerGlowScale(isExpanded: true) - 1.175) < 0.001)
        #expect(abs(moderateOrb.soundwaveRingScale(isExpanded: true) - 1.175) < 0.001)

        // AudioLevel 1.0 (Maximum speech peak)
        let peakOrb = CraftVoiceOrbView(state: .listening(liveTranscript: "I want coffee!"), audioLevel: 1.0)
        #expect(peakOrb.audioLevel == 1.0)
        #expect(peakOrb.stateSymbol == .waveform)
        #expect(abs(peakOrb.outerGlowScale(isExpanded: true) - 1.35) < 0.001)
        #expect(abs(peakOrb.soundwaveRingScale(isExpanded: true) - 1.35) < 0.001)

        // Threshold boundary tests for audioLevel 0.08
        let atThresholdOrb = CraftVoiceOrbView(state: .listening(liveTranscript: ""), audioLevel: 0.08)
        #expect(atThresholdOrb.stateSymbol == .mic)
        let aboveThresholdOrb = CraftVoiceOrbView(state: .listening(liveTranscript: ""), audioLevel: 0.081)
        #expect(aboveThresholdOrb.stateSymbol == .waveform)

        // Reduce motion respect
        #expect(peakOrb.outerGlowScale(isExpanded: true, reduceMotion: true) == 1.0)
        #expect(peakOrb.soundwaveRingScale(isExpanded: true, reduceMotion: true) == 1.0)

        // Non-listening states ignore audioLevel for symbol and custom scale
        let speakingOrb = CraftVoiceOrbView(state: .speaking(characterText: "Hi"), audioLevel: 0.9)
        #expect(speakingOrb.stateSymbol == .waveform)
        #expect(speakingOrb.outerGlowScale(isExpanded: true) == 1.15)
        #expect(speakingOrb.outerGlowScale(isExpanded: false) == 0.98)
    }
}
