import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking prompt builder")
struct SpeakingPromptBuilderTests {
    @Test func a2PromptContainsLevelRoleAndNoCorrectionRule() {
        let prompt = SpeakingPromptBuilder.systemInstruction(for: .fixture())
        #expect(prompt.contains("short simple sentences, common everyday words, speak slowly"))
        #expect(prompt.contains("a friendly barista"))
        #expect(prompt.contains("a quiet cafe"))
        #expect(prompt.contains("Order a coffee"))
        #expect(prompt.contains("Speak only English. Never correct the learner during the conversation. Ask one question at a time. Keep each reply under 3 sentences."))
        #expect(prompt.contains("When the objective is complete or the learner says goodbye, say a short goodbye and call end_session."))
        #expect(!prompt.contains("Target words"))
    }

    @Test func targetWordsAppearOnlyWhenSelected() {
        let prompt = SpeakingPromptBuilder.systemInstruction(for: .fixture(level: .b1, words: ["recommend", "decaf"]))
        #expect(prompt.contains("natural everyday English, moderate pace, some idioms explained by context"))
        #expect(prompt.contains("Target words: recommend, decaf"))
        #expect(prompt.contains("create natural chances for the learner to use these words; never say them first"))
    }

    @Test func topicWithoutObjectiveOmitsObjectiveSection() {
        let blueprint = SpeakingBlueprint(
            id: "travel", kind: .topic, titleKey: "app.speaking.blueprint.travel.title",
            briefKey: "app.speaking.blueprint.travel.brief", aiRole: "a fellow traveler", setting: "a train", objective: nil
        )
        let prompt = SpeakingPromptBuilder.systemInstruction(for: .init(blueprint: blueprint, level: .b1, targetWords: []))
        #expect(!prompt.contains("Objective:"))
        #expect(prompt.contains("a fellow traveler"))
    }

    @Test func promptSnapshotIsStable() throws {
        let data = try SpeakingFixtures.data("prompt-cafe-a2.txt")
        let expected = try #require(String(data: data, encoding: .utf8))
        #expect(SpeakingPromptBuilder.systemInstruction(for: .fixture()) + "\n" == expected)
    }

    @Test func controlRequestsKeepConversationContract() {
        #expect(!SpeakingPromptBuilder.openingTrigger.isEmpty)
        #expect(SpeakingPromptBuilder.hintRequest.contains("short hint"))
        #expect(SpeakingPromptBuilder.hintRequest.contains("Vietnamese"))
        #expect(SpeakingPromptBuilder.hintRequest.contains("wait for the learner"))
        #expect(SpeakingPromptBuilder.wrapUpRequest.contains("one sentence"))
        #expect(SpeakingPromptBuilder.wrapUpRequest.contains("end_session"))
    }
}
