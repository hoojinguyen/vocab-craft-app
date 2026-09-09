#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
@testable import VocabCraftApp
import XCTest

final class StageProgressRepositoryConcurrencyTests: XCTestCase {
    private func assertSendable<T: Sendable>(_ item: T) -> Bool {
        true
    }

    @MainActor
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
}
#endif
