import CraftUIKit
import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("LearningPathSwitchSheet Tests")
struct LearningPathSwitchSheetTestingTests {
    @Test("PathProgressInfo calculates completion percentage accurately")
    func testPathProgressInfoCalculations() {
        let progressZero = PathProgressInfo(completedUnits: 0, totalUnits: 26)
        #expect(progressZero.completedUnits == 0)
        #expect(progressZero.totalUnits == 26)
        #expect(progressZero.percent == 0)

        let progressHalf = PathProgressInfo(completedUnits: 13, totalUnits: 26)
        #expect(progressHalf.completedUnits == 13)
        #expect(progressHalf.totalUnits == 26)
        #expect(progressHalf.percent == 50)

        let progressFull = PathProgressInfo(completedUnits: 48, totalUnits: 48)
        #expect(progressFull.completedUnits == 48)
        #expect(progressFull.totalUnits == 48)
        #expect(progressFull.percent == 100)

        let progressEmptyTotal = PathProgressInfo(completedUnits: 0, totalUnits: 0)
        #expect(progressEmptyTotal.percent == 0)
    }

    @Test("LearningPathSwitchSheet initializes with custom parameters and renders view")
    @MainActor
    func testLearningPathSwitchSheetInitialization() {
        let samplePath = LearningPathSwitchSheet.fallbackPaths.first!
        var selectedPath: LearningPathDTO?

        let sheet = LearningPathSwitchSheet(
            activePathId: samplePath.id,
            initialPaths: LearningPathSwitchSheet.fallbackPaths,
            onSelectPath: { path in
                selectedPath = path
            }
        )

        #expect(sheet.activePathId == samplePath.id)
        #expect(sheet.initialPaths?.count == 4)
        assertHosted(sheet)

        sheet.onSelectPath?(samplePath)
        #expect(selectedPath?.id == samplePath.id)
    }

    @Test("Verify fallbackPaths contains all 4 curated learning paths with correct codes")
    @MainActor
    func testFallbackPathsIntegrity() {
        let paths = LearningPathSwitchSheet.fallbackPaths
        #expect(paths.count == 4)

        let codes = Set(paths.map(\.code))
        #expect(codes.contains("essential-english-mastery"))
        #expect(codes.contains("daily-life-travel"))
        #expect(codes.contains("business-career"))
        #expect(codes.contains("academic-research"))

        #expect(paths[0].sortOrder == 0)
        #expect(paths[1].sortOrder == 1)
        #expect(paths[2].sortOrder == 2)
        #expect(paths[3].sortOrder == 3)
    }

    @Test("Bilingual progress format output matches expected template")
    func testBilingualProgressFormatting() {
        let formatted = AppStrings.LearningPath.progress(completed: 5, total: 26, percent: 19)
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("5"))
        #expect(formatted.contains("26"))
        #expect(formatted.contains("19%"))
    }
}
#endif

@MainActor
final class LearningPathSwitchSheetXCTests: XCTestCase {
    func testSheetRenderWithActiveSelection() {
        let paths = LearningPathSwitchSheet.fallbackPaths
        let activePath = paths[1]
        let sheet = LearningPathSwitchSheet(
            activePathId: activePath.id,
            initialPaths: paths
        )
        XCTAssertEqual(sheet.activePathId, activePath.id)
        assertHosted(sheet)
    }

    func testSheetWithNilActivePathDefaultsToFirst() {
        let sheet = LearningPathSwitchSheet(
            activePathId: nil,
            initialPaths: LearningPathSwitchSheet.fallbackPaths
        )
        XCTAssertNil(sheet.activePathId)
        assertHosted(sheet)
    }
}
