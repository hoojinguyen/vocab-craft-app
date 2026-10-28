import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ShadowingProgressRepository Tests")
struct ShadowingProgressRepositoryTests {
    private func makeRepository(suiteName: String = "test_shadowing_\(UUID().uuidString)") throws -> (ShadowingProgressRepositoryImpl, String) {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            struct UserDefaultsInitError: Error {}
            throw UserDefaultsInitError()
        }
        // Transfer this defaults instance to the actor; callers retain only the suite name.
        let repository = ShadowingProgressRepositoryImpl(userDefaults: userDefaults)
        return (repository, suiteName)
    }

    @Test("Verifies getProgress returns nil for unrecorded video")
    func testGetProgressForUnrecordedVideo() async throws {
        let (repo, suiteName) = try makeRepository()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

        let progress = await repo.getProgress(videoId: "unknown_video")
        #expect(progress == nil)
    }

    @Test("Verifies recording completion creates progress record")
    func testRecordCompletionCreatesRecord() async throws {
        let (repo, suiteName) = try makeRepository()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

        let beforeTime = Date().addingTimeInterval(-1)
        try await repo.recordCompletion(
            videoId: "vid_01",
            score: 85.5,
            sentenceScores: ["s_1": 90.0, "s_2": 81.0]
        )
        let afterTime = Date().addingTimeInterval(1)

        let record = await repo.getProgress(videoId: "vid_01")
        #expect(record != nil)
        #expect(record?.videoId == "vid_01")
        #expect(record?.id == "vid_01")
        #expect(record?.bestScore == 85.5)
        #expect(record?.timesCompleted == 1)
        #expect(record?.sentenceScores == ["s_1": 90.0, "s_2": 81.0])
        if let lastCompletedAt = record?.lastCompletedAt {
            #expect(lastCompletedAt >= beforeTime && lastCompletedAt <= afterTime)
        }
    }

    @Test("Verifies higher score updates bestScore and increments timesCompleted")
    func testHigherScoreUpdatesBestScore() async throws {
        let (repo, suiteName) = try makeRepository()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

        try await repo.recordCompletion(videoId: "vid_01", score: 75.0, sentenceScores: ["s_1": 75.0])
        try await repo.recordCompletion(videoId: "vid_01", score: 92.5, sentenceScores: ["s_1": 92.5])

        let record = await repo.getProgress(videoId: "vid_01")
        #expect(record?.bestScore == 92.5)
        #expect(record?.timesCompleted == 2)
        #expect(record?.sentenceScores["s_1"] == 92.5)
    }

    @Test("Verifies lower score keeps previous bestScore while incrementing timesCompleted")
    func testLowerScoreRetainsBestScore() async throws {
        let (repo, suiteName) = try makeRepository()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

        try await repo.recordCompletion(videoId: "vid_01", score: 95.0, sentenceScores: ["s_1": 95.0])
        try await repo.recordCompletion(videoId: "vid_01", score: 80.0, sentenceScores: ["s_2": 80.0])

        let record = await repo.getProgress(videoId: "vid_01")
        #expect(record?.bestScore == 95.0)
        #expect(record?.timesCompleted == 2)
        #expect(record?.sentenceScores["s_1"] == 95.0)
        #expect(record?.sentenceScores["s_2"] == 80.0)
    }

    @Test("Verifies sentenceScores merging across attempts")
    func testSentenceScoresMerging() async throws {
        let (repo, suiteName) = try makeRepository()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

        try await repo.recordCompletion(videoId: "vid_01", score: 70.0, sentenceScores: ["s_1": 80.0, "s_2": 60.0])
        try await repo.recordCompletion(videoId: "vid_01", score: 85.0, sentenceScores: ["s_2": 90.0, "s_3": 85.0])

        let record = await repo.getProgress(videoId: "vid_01")
        #expect(record?.sentenceScores == ["s_1": 80.0, "s_2": 90.0, "s_3": 85.0])
    }

    @Test("Verifies getAllProgress returns all recorded videos")
    func testGetAllProgress() async throws {
        let (repo, suiteName) = try makeRepository()
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

        let initialProgress = await repo.getAllProgress()
        #expect(initialProgress.isEmpty)

        try await repo.recordCompletion(videoId: "vid_01", score: 88.0, sentenceScores: ["s_1": 88.0])
        try await repo.recordCompletion(videoId: "vid_02", score: 94.0, sentenceScores: ["s_2": 94.0])

        let allProgress = await repo.getAllProgress()
        #expect(allProgress.count == 2)
        #expect(allProgress["vid_01"]?.bestScore == 88.0)
        #expect(allProgress["vid_02"]?.bestScore == 94.0)
    }

    @Test("Verifies progress persists across repository instances")
    func testProgressPersistsAcrossInstances() async throws {
        let suiteName = "test_shadowing_\(UUID().uuidString)"
        defer { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

        let (repo1, _) = try makeRepository(suiteName: suiteName)
        try await repo1.recordCompletion(videoId: "vid_persist", score: 91.0, sentenceScores: ["s_1": 91.0])

        let (repo2, _) = try makeRepository(suiteName: suiteName)
        let record = await repo2.getProgress(videoId: "vid_persist")
        #expect(record?.bestScore == 91.0)
        #expect(record?.timesCompleted == 1)
        #expect(record?.sentenceScores["s_1"] == 91.0)
    }
}
