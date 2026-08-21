@testable import VocabCraftApp
import XCTest

// MARK: - Mock SRS Repository

@MainActor
final class MockSRSRepository: SRSRepositoryProtocol {
    var savedProgress: SRSProgressItem?
    var resetAllProgressCalled = false

    func getProgress(wordId: Int64) async throws -> SRSProgressItem? {
        return nil
    }

    func saveProgress(_ item: SRSProgressItem) async throws {
        savedProgress = item
    }

    func logReflexSession(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) async throws {
        // no-op for test
    }

    func resetAllProgress() async throws {
        resetAllProgressCalled = true
    }
}

// MARK: - Tests

@MainActor
final class EvaluateSRSUseCaseTests: XCTestCase {
    func testEvaluateResponseCalculatesSRSIntervals() {
        let mockRepo = MockSRSRepository()
        let useCase = EvaluateSRSUseCase(srsRepository: mockRepo)
        let result = useCase.evaluateResponse(
            currentMastery: 0,
            easeFactor: 2.5,
            isCorrect: true,
            responseTimeMs: 1500
        )

        XCTAssertEqual(result.nextMastery, 1)
        XCTAssertEqual(result.easeFactor, 2.6, accuracy: 0.001)
        XCTAssertEqual(result.intervalDays, 1)
    }

    func testRecordReviewWithRepositoryPersistsProgress() async throws {
        let mockRepo = MockSRSRepository()
        let useCase = EvaluateSRSUseCase(srsRepository: mockRepo)
        let result = try await useCase.recordReview(
            wordId: 101,
            isCorrect: true,
            responseTimeMs: 2000
        )

        XCTAssertEqual(result.nextMastery, 1)
        XCTAssertEqual(result.easeFactor, 2.6, accuracy: 0.001)
        XCTAssertNotNil(mockRepo.savedProgress)
        XCTAssertEqual(mockRepo.savedProgress?.wordId, 101)
    }
}
