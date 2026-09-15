#if canImport(SwiftDataMacros) || canImport(SwiftData)
import Foundation
import SwiftData
@testable import VocabCraftApp
import XCTest

@MainActor
final class StageProgressRepositoryConcurrencyTests: XCTestCase {
    private func assertSendable<T: Sendable>(_ item: T) -> Bool {
        true
    }

    func test_concurrent_reads_and_writes_return_sendable_snapshots() async throws {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo: StageProgressRepositoryProtocol = StageProgressRepositoryImpl(modelContext: container.mainContext)

        // Seed initial stage
        try await repo.saveStageProgress(stageId: "stage_0", deckId: "deck_0", isCompleted: false, score: 0, progressFraction: 0.0)

        // Execute concurrent operations across multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 1...10 {
                group.addTask {
                    try? await repo.saveStageProgress(
                        stageId: "stage_\(i)",
                        deckId: "deck_0",
                        isCompleted: true,
                        score: i * 10,
                        progressFraction: 1.0
                    )
                }
            }
        }

        let allProgress: [UserStageProgressData] = try await repo.fetchAllStageProgress()
        XCTAssertGreaterThanOrEqual(allProgress.count, 10)
        XCTAssertTrue(allProgress.allSatisfy { assertSendable($0) })
    }

    func test_stageProgressRepositoryImpl_isMainActorIsolated() async throws {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo = StageProgressRepositoryImpl(modelContext: container.mainContext)

        MainActor.assertIsolated()

        try await repo.saveStageProgress(
            stageId: "main_actor_stage",
            deckId: "deck_main",
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )

        let result = try await repo.fetchStageProgress(stageId: "main_actor_stage")
        XCTAssertEqual(result?.stageId, "main_actor_stage")
        XCTAssertEqual(result?.isCompleted, true)
    }

    func test_concurrent_detached_tasks_safely_hop_to_main_actor() async throws {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repo: StageProgressRepositoryProtocol = StageProgressRepositoryImpl(modelContext: container.mainContext)

        let detachedTasks = (1...5).map { index in
            Task.detached {
                try await repo.saveStageProgress(
                    stageId: "detached_stage_\(index)",
                    deckId: "detached_deck",
                    isCompleted: true,
                    score: index * 20,
                    progressFraction: 1.0
                )
                return try await repo.fetchStageProgress(stageId: "detached_stage_\(index)")
            }
        }

        for task in detachedTasks {
            let result = try await task.value
            XCTAssertNotNil(result)
            XCTAssertTrue(result?.isCompleted == true)
        }

        let completedIds = try await repo.fetchCompletedStageIds(deckId: "detached_deck")
        XCTAssertEqual(completedIds.count, 5)
    }

    func test_mockStageProgressRepository_isMainActorIsolated() async throws {
        let mockRepo = MockStageProgressRepository()

        MainActor.assertIsolated()

        try await mockRepo.saveStageProgress(
            stageId: "mock_iso_stage",
            deckId: "mock_deck",
            isCompleted: true,
            score: 80,
            progressFraction: 1.0
        )

        let progress = try await mockRepo.fetchStageProgress(stageId: "mock_iso_stage")
        XCTAssertEqual(progress?.stageId, "mock_iso_stage")
        XCTAssertEqual(mockRepo.saveCallCount, 1)
    }
}
#endif
