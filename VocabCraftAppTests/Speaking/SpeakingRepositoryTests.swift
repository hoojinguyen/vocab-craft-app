import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp

struct SpeakingRepositoryTests {
    @Test func updateAnalysisFlattensScoresAndIsIdempotent() async throws {
        let repo = try SpeakingModelActor.inMemory()
        let snapshot = SpeakingSessionSnapshot.fixture()
        let fixture = try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-valid.json"))
        let analysis = SpeakingAnalysis(
            learnerTranscript: fixture.learnerTranscript,
            scores: .init(fluency: .init(value: 3, reason: "Fluency"), grammar: .init(value: 2, reason: "Grammar"),
                          vocabulary: .init(value: 4, reason: "Vocabulary"), pronunciation: .init(value: 5, reason: "Pronunciation")),
            corrections: fixture.corrections, naturalPhrasings: fixture.naturalPhrasings,
            pronunciation: fixture.pronunciation, targetWords: fixture.targetWords,
            objective: fixture.objective, summary: fixture.summary
        )
        try await repo.save(snapshot)
        try await repo.updateAnalysis(sessionId: snapshot.id, status: .analyzed, analysis: analysis)
        try await repo.updateAnalysis(sessionId: snapshot.id, status: .analyzed, analysis: analysis)
        let all = try await repo.sessions(limit: nil)
        #expect(all.count == 1)
        #expect(all.first?.analysis == analysis)
        #expect(all.first?.status == .analyzed)
        let container = repo.modelContainer
        defer { withExtendedLifetime(container) {} }
        let context = ModelContext(container)
        let record = try #require(context.fetch(FetchDescriptor<SpeakingSessionRecord>()).first)
        #expect(record.fluency == 3)
        #expect(record.grammar == 2)
        #expect(record.vocabulary == 4)
        #expect(record.pronunciation == 5)
        #expect(record.status == "analyzed")
        try await repo.updateAnalysis(sessionId: snapshot.id, status: .analysisFailed, analysis: nil)
        let cleared = try await repo.session(id: snapshot.id)
        #expect(cleared?.analysis == nil)
        let fresh = ModelContext(container)
        let clearedRecord = try #require(fresh.fetch(FetchDescriptor<SpeakingSessionRecord>()).first)
        #expect(clearedRecord.fluency == nil && clearedRecord.grammar == nil)
        #expect(clearedRecord.vocabulary == nil && clearedRecord.pronunciation == nil)
    }

    @Test func saveUpsertsAndListsNewestFirstWithLimits() async throws {
        let repo = try SpeakingModelActor.inMemory()
        let old = SpeakingSessionSnapshot.fixture(startedAt: Date(timeIntervalSince1970: 1))
        var newest = SpeakingSessionSnapshot.fixture(startedAt: Date(timeIntervalSince1970: 2))
        try await repo.save(newest)
        try await repo.save(old)
        newest.status = .tooShort
        try await repo.save(newest)
        #expect(try await repo.sessions(limit: nil) == [newest, old])
        #expect(try await repo.sessions(limit: 1) == [newest])
        #expect(try await repo.sessions(limit: 0).isEmpty)
        #expect(try await repo.sessions(limit: -1).isEmpty)
        #expect(try await repo.session(id: UUID()) == nil)
        try await repo.updateAnalysis(sessionId: UUID(), status: .analyzed, analysis: nil)
        #expect(try await repo.sessions(limit: nil).count == 2)
    }

    @Test func savePhraseRejectsDuplicateSuggestionAndDeletes() async throws {
        let repo = try SpeakingModelActor.inMemory()
        let first = SavedPhrase.fixture(suggestion: "I'd like a latte")
        #expect(try await repo.savePhrase(first))
        #expect(try await repo.savePhrase(.fixture(suggestion: "  I'D LIKE A LATTE \n")) == false)
        #expect(try await repo.savePhrase(.fixture(suggestion: "I’D like a latte!")) == false)
        #expect(try await repo.phrases() == [first])
        try await repo.deletePhrase(id: UUID())
        try await repo.deletePhrase(id: first.id)
        #expect(try await repo.phrases().isEmpty)
        #expect(try await repo.savePhrase(.fixture(suggestion: "I'd like a latte")))
    }

    @Test func detachAudioKeepsLatestTwentyAndPreservesAnalysis() async throws {
        let repo = try SpeakingModelActor.inMemory()
        let analysis = try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-valid.json"))
        for index in 0..<22 {
            var snapshot = SpeakingSessionSnapshot.fixture(
                startedAt: Date(timeIntervalSince1970: Double(index)), audioFileName: "s\(index).m4a"
            )
            snapshot.analysis = analysis
            try await repo.save(snapshot)
        }
        let removed = try await repo.detachAudio(keepingLatest: 20)
        #expect(Set(removed) == ["s0.m4a", "s1.m4a"])
        let all = try await repo.sessions(limit: nil)
        #expect(all.filter { $0.audioFileName != nil }.count == 20)
        #expect(all.allSatisfy { $0.analysis == analysis })
        #expect(try await repo.detachAudio(keepingLatest: 20).isEmpty)
        #expect(try await repo.detachAudio(keepingLatest: 0).count == 20)
        #expect(try await repo.sessions(limit: nil).allSatisfy { $0.audioFileName == nil })
    }

    @Test func concurrentPhraseSavesInsertOnlyOnce() async throws {
        let repo = try SpeakingModelActor.inMemory()
        let inserted = try await withThrowingTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask { try await repo.savePhrase(.fixture(suggestion: "A latte please")) }
            }
            var count = 0
            for try await saved in group where saved { count += 1 }
            return count
        }
        #expect(inserted == 1)
        #expect(try await repo.phrases().count == 1)
    }

    @Test func sessionsAndPhrasesSurviveReopeningAfterAudioDetachment() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("speaking.sqlite")
        let (snapshot, phrase) = try await seedSpeakingStore(url: url)
        let container = try SharedAppGroupContainer.createContainer(storeURL: url)
        defer { withExtendedLifetime(container) {} }
        let repo = SpeakingModelActor(modelContainer: container)
        var detached = snapshot
        detached.audioFileName = nil
        #expect(try await repo.session(id: snapshot.id) == detached)
        #expect(try await repo.phrases() == [phrase])
        #expect(try await repo.savePhrase(.fixture(suggestion: "  A LATTE PLEASE ")) == false)
    }

    private func seedSpeakingStore(url: URL) async throws -> (SpeakingSessionSnapshot, SavedPhrase) {
        let container = try SharedAppGroupContainer.createContainer(storeURL: url)
        defer { withExtendedLifetime(container) {} }
        let repo = SpeakingModelActor(modelContainer: container)
        var snapshot = SpeakingSessionSnapshot.fixture(audioFileName: "saved.m4a")
        snapshot.analysis = try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("analysis-valid.json"))
        snapshot.status = .analyzed
        let phrase = SavedPhrase.fixture(suggestion: "A latte please")
        try await repo.save(snapshot)
        #expect(try await repo.savePhrase(phrase))
        #expect(try await repo.detachAudio(keepingLatest: 0) == ["saved.m4a"])
        return (snapshot, phrase)
    }

    @Test func retentionCountsSessionsWithoutAudioAndClampsNegativeCount() async throws {
        let repo = try SpeakingModelActor.inMemory()
        try await repo.save(.fixture(startedAt: Date(timeIntervalSince1970: 1), audioFileName: "old.m4a"))
        try await repo.save(.fixture(startedAt: Date(timeIntervalSince1970: 2)))
        #expect(try await repo.detachAudio(keepingLatest: 1) == ["old.m4a"])
        try await repo.save(.fixture(audioFileName: "new.m4a"))
        #expect(try await repo.detachAudio(keepingLatest: -1) == ["new.m4a"])
    }
}

extension SpeakingSessionSnapshot {
    static func fixture(
        id: UUID = UUID(), startedAt: Date = Date(), audioFileName: String? = nil
    ) -> Self {
        Self(id: id, plan: .fixture(), startedAt: startedAt, duration: 42, status: .pendingAnalysis,
             endReason: .learnerEnded, hintCount: 0, audioFileName: audioFileName, turns: [], analysis: nil)
    }
}

extension SavedPhrase {
    static func fixture(suggestion: String) -> Self {
        Self(id: UUID(), original: "A latte", suggestion: suggestion, note: "Polite request",
             sessionId: UUID(), source: .correction, createdAt: Date())
    }
}

extension SpeakingModelActor {
    static func inMemory() throws -> SpeakingModelActor {
        SpeakingModelActor(modelContainer: try SharedAppGroupContainer.createContainer(inMemory: true))
    }
}
