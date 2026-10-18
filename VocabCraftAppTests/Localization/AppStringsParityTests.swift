import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("AppStrings & Localizable Parity Tests")
struct AppStringsParityTests {
    private func loadCatalogStrings() throws -> [String: [String: Any]] {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path
        ]

        var data: Data?
        for case let path? in potentialPaths {
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                data = fileData
                break
            }
        }

        let fileData = try #require(data, "Localizable.xcstrings should be found")
        let json = try #require(
            JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog should parse as JSON dictionary"
        )
        return try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )
    }

    // MARK: - Typed Accessor Tests

    @Test("Verifies Treasure typed accessors and defaults in AppStrings.Treasure")
    func testTreasureAccessors() {
        #expect(AppStrings.Treasure.congratsTitleText == "Unit Mastered!")
        #expect(
            AppStrings.Treasure.congratsSubtitleText ==
            "You have completed all lessons and the checkpoint quiz. Open the chest to claim your milestone reward!"
        )
        #expect(AppStrings.Treasure.claimButtonText == "Claim +150 XP")
        #expect(AppStrings.Treasure.alreadyClaimedText == "Reward Claimed")
        #expect(
            AppStrings.Treasure.checkpointIncompleteErrorText ==
            "Checkpoint must be completed before claiming treasure reward."
        )

        let _: LocalizedStringKey = AppStrings.Treasure.congratsTitle
        let _: LocalizedStringKey = AppStrings.Treasure.congratsSubtitle
        let _: LocalizedStringKey = AppStrings.Treasure.claimButton
        let _: LocalizedStringKey = AppStrings.Treasure.alreadyClaimed
        let _: LocalizedStringKey = AppStrings.Treasure.checkpointIncompleteError
    }

    @Test("Verifies LearningPath typed accessors and formatting in AppStrings.LearningPath")
    func testLearningPathAccessors() {
        #expect(AppStrings.LearningPath.switcherTitleText == "Learning Paths")
        #expect(
            AppStrings.LearningPath.switcherSubtitleText ==
            "Switch paths anytime. All progress is safely preserved."
        )
        #expect(AppStrings.LearningPath.activeBadgeText == "Active")
        #expect(
            AppStrings.LearningPath.progressFormat(completed: 5, total: 26, percent: 19) ==
            "5 of 26 Units completed (19%)"
        )
        #expect(
            AppStrings.LearningPath.progress(completed: 5, total: 26, percent: 19) ==
            "5 of 26 Units completed (19%)"
        )
        #expect(AppStrings.LearningPath.switchActionText == "Switch to this Path")

        let _: LocalizedStringKey = AppStrings.LearningPath.switcherTitle
        let _: LocalizedStringKey = AppStrings.LearningPath.switcherSubtitle
        let _: LocalizedStringKey = AppStrings.LearningPath.activeBadge
        let _: LocalizedStringKey = AppStrings.LearningPath.progressFormatKey(
            completed: 5,
            total: 26,
            percent: 19
        )
        let _: LocalizedStringKey = AppStrings.LearningPath.switchAction
    }

    // MARK: - Catalog Bilingual Parity Tests

    @Test("Verifies catalog bilingual completeness and format parity for Treasure and LearningPath keys")
    func testCatalogBilingualParity() throws {
        let strings = try loadCatalogStrings()

        let expectedKeys: [String: (en: String, vi: String)] = [
            "app.treasure.congrats_title": (
                en: "Unit Mastered!",
                vi: "Chúc mừng bạn đã chinh phục Unit!"
            ),
            "app.treasure.congrats_subtitle": (
                en: "You have completed all lessons and the checkpoint quiz. Open the chest to claim your milestone reward!",
                vi: "Bạn đã hoàn thành toàn bộ bài học và bài kiểm tra Checkpoint. Mở rương để nhận phần thưởng!"
            ),
            "app.treasure.claim_button": (
                en: "Claim +150 XP",
                vi: "Nhận Thưởng +150 XP"
            ),
            "app.treasure.already_claimed": (
                en: "Reward Claimed",
                vi: "Đã Nhận Thưởng"
            ),
            "app.treasure.error.checkpoint_incomplete": (
                en: "Checkpoint must be completed before claiming treasure reward.",
                vi: "Cần hoàn thành bài kiểm tra checkpoint trước khi mở rương phần thưởng."
            ),
            "app.learning_path.switcher_title": (
                en: "Learning Paths",
                vi: "Lộ Trình Học Tập"
            ),
            "app.learning_path.switcher_subtitle": (
                en: "Switch paths anytime. All progress is safely preserved.",
                vi: "Chuyển đổi linh hoạt bất cứ lúc nào. Toàn bộ tiến độ được lưu giữ nguyên vẹn."
            ),
            "app.learning_path.active_badge": (
                en: "Active",
                vi: "Đang học"
            ),
            "app.learning_path.progress_format": (
                en: "%lld of %lld Units completed (%lld%%)",
                vi: "Đã hoàn thành %lld/%lld Unit (%lld%%)"
            ),
            "app.learning_path.switch_action": (
                en: "Switch to this Path",
                vi: "Chọn lộ trình này"
            )
        ]

        #expect(expectedKeys.count == 10)

        for (key, expected) in expectedKeys {
            let entry = try #require(strings[key], "Missing required key: \(key)")
            #expect(
                entry["extractionState"] as? String == "manual",
                "Key \(key) must have extractionState: manual"
            )

            let localizations = try #require(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations"
            )

            // Verify EN
            let enLoc = try #require(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try #require(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(enVal == expected.en, "Key \(key) EN mismatch: expected '\(expected.en)' but got '\(enVal)'")

            // Verify VI
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(viVal == expected.vi, "Key \(key) VI mismatch: expected '\(expected.vi)' but got '\(viVal)'")
        }
    }

    @Test("Verifies learning path progress formatting specifier evaluation in EN and VI")
    func testProgressFormatEvaluation() throws {
        let strings = try loadCatalogStrings()
        let progressKey = "app.learning_path.progress_format"
        let entry = try #require(strings[progressKey], "Missing key \(progressKey)")
        let localizations = try #require(entry["localizations"] as? [String: [String: Any]])

        let enUnit = try #require(localizations["en"]?["stringUnit"] as? [String: Any])
        let enFormat = try #require(enUnit["value"] as? String)
        let formattedEn = String(format: enFormat, 5, 26, 19)
        #expect(formattedEn == "5 of 26 Units completed (19%)")

        let viUnit = try #require(localizations["vi"]?["stringUnit"] as? [String: Any])
        let viFormat = try #require(viUnit["value"] as? String)
        let formattedVi = String(format: viFormat, 5, 26, 19)
        #expect(formattedVi == "Đã hoàn thành 5/26 Unit (19%)")
    }
}
