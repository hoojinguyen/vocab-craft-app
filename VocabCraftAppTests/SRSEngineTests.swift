import XCTest
@testable import VocabCraftApp

final class SRSEngineTests: XCTestCase {
    func testFastCorrectResponseIncreasesEaseFactorAndMastery() {
        let result = SRSEngine.calculateNextInterval(
            currentMastery: 0,
            easeFactor: 2.5,
            isCorrect: true,
            responseTimeMs: 1500
        )
        
        XCTAssertEqual(result.nextMastery, 1)
        XCTAssertEqual(result.easeFactor, 2.6, accuracy: 0.001)
        XCTAssertEqual(result.intervalDays, 1)
    }

    func testFastCorrectResponseAtHigherMastery() {
        let result = SRSEngine.calculateNextInterval(
            currentMastery: 2,
            easeFactor: 2.5,
            isCorrect: true,
            responseTimeMs: 2000
        )
        
        XCTAssertEqual(result.nextMastery, 3)
        XCTAssertEqual(result.easeFactor, 2.6, accuracy: 0.001)
        XCTAssertGreaterThan(result.intervalDays, 6)
    }

    func testSlowCorrectResponseKeepsEaseFactorConstant() {
        let result = SRSEngine.calculateNextInterval(
            currentMastery: 1,
            easeFactor: 2.5,
            isCorrect: true,
            responseTimeMs: 3000
        )
        
        XCTAssertEqual(result.nextMastery, 2)
        XCTAssertEqual(result.easeFactor, 2.5, accuracy: 0.001)
        XCTAssertEqual(result.intervalDays, 6)
    }

    func testIncorrectResponseResetsMasteryAndPenalizesEaseFactor() {
        let result = SRSEngine.calculateNextInterval(
            currentMastery: 3,
            easeFactor: 2.5,
            isCorrect: false,
            responseTimeMs: 1200
        )
        
        XCTAssertEqual(result.nextMastery, 0)
        XCTAssertEqual(result.easeFactor, 2.3, accuracy: 0.001)
        XCTAssertEqual(result.intervalDays, 1)
    }

    func testEaseFactorMinimumFloorAt1_3() {
        let result = SRSEngine.calculateNextInterval(
            currentMastery: 1,
            easeFactor: 1.4,
            isCorrect: false,
            responseTimeMs: 5000
        )
        
        XCTAssertEqual(result.nextMastery, 0)
        XCTAssertEqual(result.easeFactor, 1.3, accuracy: 0.001)
        XCTAssertEqual(result.intervalDays, 1)
    }

    func testMasteryCapAt5() {
        let result = SRSEngine.calculateNextInterval(
            currentMastery: 5,
            easeFactor: 2.5,
            isCorrect: true,
            responseTimeMs: 1000
        )
        
        XCTAssertEqual(result.nextMastery, 5)
        XCTAssertGreaterThan(result.intervalDays, 10)
    }
}
