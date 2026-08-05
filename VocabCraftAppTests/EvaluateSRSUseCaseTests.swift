import XCTest
@testable import VocabCraftApp

final class EvaluateSRSUseCaseTests: XCTestCase {
    func testEvaluateResponseCalculatesSRSIntervals() {
        let useCase = EvaluateSRSUseCase()
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

    func testRecordReviewWithNilRepositoryReturnsCalculatedResult() async throws {
        let useCase = EvaluateSRSUseCase(srsRepository: nil)
        let result = try await useCase.recordReview(
            wordId: 101,
            isCorrect: true,
            responseTimeMs: 2000
        )
        
        XCTAssertEqual(result.nextMastery, 1)
        XCTAssertEqual(result.easeFactor, 2.6, accuracy: 0.001)
    }
}
