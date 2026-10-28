import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking models Codable")
struct SpeakingModelsCodableTests {
    @Test func analysisDecodesCamelCaseFixture() throws {
        let analysis = try validAnalysis()
        #expect(analysis.learnerTranscript.first?.turnIndex == 1)
        #expect(analysis.scores.fluency.value == 3)
        #expect(analysis.corrections.first?.category == .wordChoice)
        #expect(analysis.targetWords.first?.usedCorrectly == true)
        #expect(analysis.targetWords.first?.quote == "I want coffee.")
        #expect(analysis.objective?.met == true)
        #expect(try JSONDecoder().decode(SpeakingAnalysis.self, from: JSONEncoder().encode(analysis)) == analysis)
    }

    @Test func missingOptionalAnalysisFieldsDefaultOnlyTargetWords() throws {
        let analysis = try JSONDecoder().decode(
            SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-missing-optional.json")
        )
        #expect(analysis.targetWords.isEmpty)
        #expect(analysis.objective == nil)
    }

    @Test(arguments: ["learnerTranscript", "scores", "corrections", "naturalPhrasings", "pronunciation", "summary"])
    func missingRequiredFieldFails(key: String) throws {
        var object = try analysisObject()
        object.removeValue(forKey: key)
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(SpeakingAnalysis.self, from: data) }
    }

    @Test func malformedTargetWordsFailsRatherThanLosingData() throws {
        var object = try analysisObject()
        object["targetWords"] = "invalid"
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(SpeakingAnalysis.self, from: data) }
    }

    @Test func snapshotRoundTripPreservesAnalysisAndLearnerCount() throws {
        let snapshot = SpeakingSessionSnapshot(
            id: UUID(), plan: .fixture(words: ["coffee"]), startedAt: Date(timeIntervalSince1970: 123), duration: 42,
            status: .analyzed, endReason: .learnerEnded, hintCount: 1, audioFileName: "session.m4a",
            turns: [
                SpeakingTurn(index: 0, speaker: .ai, text: "Hello!", startOffset: 0, endOffset: 1),
                SpeakingTurn(index: 1, speaker: .learner, text: "I want coffee.", startOffset: 2, endOffset: nil)
            ], analysis: try validAnalysis()
        )
        let decoded = try JSONDecoder().decode(SpeakingSessionSnapshot.self, from: JSONEncoder().encode(snapshot))
        #expect(decoded == snapshot)
        #expect(decoded.learnerTurnCount == 1)
        #expect(decoded.plan.blueprint.durationSeconds == 360)
    }

    @Test func savedPhraseRoundTripPreservesSource() throws {
        let phrase = SavedPhrase(
            id: UUID(), original: "I want coffee.", suggestion: "Could I have a coffee?", note: "Lịch sự hơn.",
            sessionId: UUID(), source: .naturalPhrasing, createdAt: Date(timeIntervalSince1970: 123)
        )
        #expect(try JSONDecoder().decode(SavedPhrase.self, from: JSONEncoder().encode(phrase)) == phrase)
    }

    private func validAnalysis() throws -> SpeakingAnalysis {
        try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-valid.json"))
    }

    private func analysisObject() throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: SpeakingFixtures.data("analysis-valid.json")) as? [String: Any])
    }
}
