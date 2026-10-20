import Foundation
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("FetchVocabGrowthMetricsUseCase Tests")
struct FetchVocabGrowthMetricsUseCaseTests {
    @Test("Calculates CEFR distribution and retention rate correctly")
    func testCalculatesCEFRDistributionAndRetentionRate() async throws {
        let mockProgressRepo = MockUserProgressRepository()
        mockProgressRepo.stubbedProgress = [
            UserWordProgressData(wordId: 1, cefrLevel: "A1", masteryLevel: 4, intervalDays: 10, lastReviewDate: Date()),
            UserWordProgressData(wordId: 2, cefrLevel: "A1", masteryLevel: 1, intervalDays: 1, lastReviewDate: Date()),
            UserWordProgressData(wordId: 3, cefrLevel: "B1", masteryLevel: 2, intervalDays: 3, lastReviewDate: Date())
        ]
        let useCase = FetchVocabGrowthMetricsUseCase(progressRepo: mockProgressRepo)

        let snapshot = try await useCase.execute()

        #expect(snapshot.totalWordsAcquired == 3)
        #expect(snapshot.masteredWordsCount == 1)
        #expect(snapshot.consolidatingWordsCount == 1)
        #expect(snapshot.newWordsCount == 1)
        #expect(snapshot.estimatedRetentionRate >= 0.90)

        let a1Stat = snapshot.cefrDistribution.first(where: { $0.cefrLevel == "A1" })
        #expect(a1Stat?.acquiredCount == 2)
        #expect(a1Stat?.targetStandardCount == 500)

        let b1Stat = snapshot.cefrDistribution.first(where: { $0.cefrLevel == "B1" })
        #expect(b1Stat?.acquiredCount == 1)
        #expect(b1Stat?.targetStandardCount == 800)
    }

    @Test("Handles empty user progress safely with default 1.0 retention")
    func testEmptyProgressReturnsSafeDefaults() async throws {
        let mockProgressRepo = MockUserProgressRepository()
        mockProgressRepo.stubbedProgress = []
        let useCase = FetchVocabGrowthMetricsUseCase(progressRepo: mockProgressRepo)

        let snapshot = try await useCase.execute()

        #expect(snapshot.totalWordsAcquired == 0)
        #expect(snapshot.masteredWordsCount == 0)
        #expect(snapshot.consolidatingWordsCount == 0)
        #expect(snapshot.newWordsCount == 0)
        #expect(snapshot.estimatedRetentionRate == 1.0)
        #expect(snapshot.cefrDistribution.count == 6)

        let expectedTargets = ["A1": 500, "A2": 600, "B1": 800, "B2": 1000, "C1": 1200, "C2": 1500]
        for stat in snapshot.cefrDistribution {
            #expect(stat.acquiredCount == 0)
            #expect(stat.targetStandardCount == expectedTargets[stat.cefrLevel])
            #expect(stat.masteryPercentage == 0.0)
        }
    }

    @Test("Simulates retention decay for overdue reviews")
    func testRetentionDecayWithOverdueReviews() async throws {
        let fixedNow = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: fixedNow) ?? fixedNow.addingTimeInterval(-30 * 86400)
        let mockProgressRepo = MockUserProgressRepository()
        mockProgressRepo.stubbedProgress = [
            // Word 1: Reviewed 30 days ago, interval was 1 day, easeFactor 2.5 -> S = 1.0. Decays to ~0.
            UserWordProgressData(
                wordId: 101,
                cefrLevel: "A2",
                masteryLevel: 1,
                easeFactor: 2.5,
                intervalDays: 1,
                lastReviewDate: thirtyDaysAgo
            ),
            // Word 2: Reviewed right now -> retention = 1.0
            UserWordProgressData(
                wordId: 102,
                cefrLevel: "A2",
                masteryLevel: 3,
                easeFactor: 2.5,
                intervalDays: 10,
                lastReviewDate: fixedNow
            )
        ]
        let useCase = FetchVocabGrowthMetricsUseCase(progressRepo: mockProgressRepo)

        let snapshot = try await useCase.execute(at: fixedNow)

        #expect(snapshot.totalWordsAcquired == 2)
        // Word 1 retention ≈ 0.0, Word 2 retention = 1.0 -> Average ≈ 0.50
        #expect(snapshot.estimatedRetentionRate > 0.45 && snapshot.estimatedRetentionRate < 0.55)
    }

    @Test("Classifies depth tiers accurately")
    func testDepthTiersClassification() async throws {
        let mockProgressRepo = MockUserProgressRepository()
        mockProgressRepo.stubbedProgress = [
            UserWordProgressData(wordId: 1, cefrLevel: "A1", masteryLevel: 1, intervalDays: 1, lastReviewDate: Date()),
            UserWordProgressData(wordId: 2, cefrLevel: "A1", masteryLevel: 2, intervalDays: 2, lastReviewDate: Date()),
            UserWordProgressData(wordId: 3, cefrLevel: "A2", masteryLevel: 3, intervalDays: 5, lastReviewDate: Date()),
            UserWordProgressData(wordId: 4, cefrLevel: "B1", masteryLevel: 4, intervalDays: 10, lastReviewDate: Date()),
            UserWordProgressData(wordId: 5, cefrLevel: "B2", masteryLevel: 5, intervalDays: 25, lastReviewDate: Date())
        ]
        let useCase = FetchVocabGrowthMetricsUseCase(progressRepo: mockProgressRepo)

        let snapshot = try await useCase.execute()

        #expect(snapshot.totalWordsAcquired == 5)
        #expect(snapshot.newWordsCount == 1)           // Level 1
        #expect(snapshot.consolidatingWordsCount == 2) // Level 2 & Level 3
        #expect(snapshot.masteredWordsCount == 2)      // Level 4 & Level 5
    }

    @Test("Calculates CEFR mastery percentage correctly and clamps at 100%")
    func testCEFRMasteryPercentageCalculation() {
        let statBelow = CEFRLevelStat(cefrLevel: "A1", acquiredCount: 250, targetStandardCount: 500)
        #expect(statBelow.masteryPercentage == 0.5)

        let statExact = CEFRLevelStat(cefrLevel: "A1", acquiredCount: 500, targetStandardCount: 500)
        #expect(statExact.masteryPercentage == 1.0)

        let statExceed = CEFRLevelStat(cefrLevel: "A1", acquiredCount: 650, targetStandardCount: 500)
        #expect(statExceed.masteryPercentage == 1.0)

        let statZero = CEFRLevelStat(cefrLevel: "C2", acquiredCount: 0, targetStandardCount: 1500)
        #expect(statZero.masteryPercentage == 0.0)
    }

    @Test("AppContainer wires and resolves FetchVocabGrowthMetricsUseCase")
    func testAppContainerDependencyInjection() async throws {
        let container = AppContainer.mock
        let useCase = container.makeFetchVocabGrowthMetricsUseCase()
        let snapshot = try await useCase.execute()
        #expect(snapshot.cefrDistribution.count == 6)
    }
}
