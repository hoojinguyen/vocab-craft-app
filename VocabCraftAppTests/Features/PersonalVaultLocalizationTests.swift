import Foundation
import Testing
@testable import VocabCraftApp

@Suite("PersonalVault Localization Tests")
struct PersonalVaultLocalizationTests {
    private let requiredVaultKeys: [String: (vi: String, en: String)] = [
        "app.vault.title": ("Kho Từ", "Vocabulary Vault"),
        "app.vault.search_placeholder": ("Tìm kiếm từ vựng...", "Search vocabulary..."),
        "app.vault.filter.not_mastered": ("Chưa thuộc (%lld)", "Learning (%lld)"),
        "app.vault.filter.mastered": ("Đã thuộc (%lld)", "Mastered (%lld)"),
        "app.vault.filter.bookmarked": ("Đã lưu (%lld)", "Saved (%lld)"),
        "app.vault.action.review_words": ("LUYỆN TẬP", "PRACTICE"),
        "app.vault.empty.not_mastered": ("Bạn không có từ nào chưa thuộc", "No unmastered words"),
        "app.vault.empty.mastered": ("Chưa có từ nào đạt mức thành thạo", "No mastered words yet"),
        "app.vault.empty.bookmarked": ("Chưa có từ nào được lưu", "No saved words yet"),
        "app.vault.empty.search_no_results": ("Không tìm thấy từ nào phù hợp", "No matching words found"),
        "app.vault.detail.definitions_title": ("Định nghĩa", "Definitions"),
        "app.vault.detail.examples_title": ("Ví dụ thực tế", "Examples"),
        "app.vault.detail.progress_title": ("Tiến độ phản xạ", "Reflex Progress"),
        "app.vault.detail.streak_count": ("Chuỗi đúng %lld", "%lld streak"),
        "app.vault.detail.practiced_modes": ("Chế độ đã luyện", "Practiced modes")
    ]

    @Test("Kiểm tra sự tồn tại của các localization keys trong kho từ")
    func testVaultLocalizationKeysExist() {
        let keys = Array(requiredVaultKeys.keys)
        #expect(keys.count == 15, "Phải có đủ 15 key cho Vocabulary Vault")

        let expectedPrefix = "app.vault."
        for key in keys {
            #expect(!key.isEmpty, "Key cannot be empty")
            #expect(key.hasPrefix(expectedPrefix), "Key \(key) must have prefix \(expectedPrefix)")
            #expect(requiredVaultKeys[key]?.vi.isEmpty == false, "Key \(key) missing Vietnamese translation")
            #expect(requiredVaultKeys[key]?.en.isEmpty == false, "Key \(key) missing English translation")
        }
    }

    @Test("Kiểm tra tính toàn vẹn và song ngữ EN/VI trong catalog xcstrings")
    func testVaultCatalogIntegrity() throws {
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
        let strings = try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )

        for (key, expected) in requiredVaultKeys {
            let entry = try #require(strings[key], "Missing required key in catalog: \(key)")
            #expect(
                entry["extractionState"] as? String == "manual",
                "Key \(key) must have extractionState: manual"
            )

            let localizations = try #require(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations dictionary"
            )

            // Verify EN
            let enLoc = try #require(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try #require(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(enVal == expected.en, "Key \(key) EN value mismatch: expected '\(expected.en)' but got '\(enVal)'")

            // Verify VI
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(viVal == expected.vi, "Key \(key) VI value mismatch: expected '\(expected.vi)' but got '\(viVal)'")
        }
    }

    @Test("Kiểm tra typed accessors trong AppStrings.Vault")
    func testAppStringsVaultAccessors() {
        #expect(AppStrings.Vault.titleText == "Vocabulary Vault")
        #expect(AppStrings.Vault.searchPlaceholderText == "Search vocabulary...")
        #expect(AppStrings.Vault.filterNotMastered(10) == "Learning (10)")
        #expect(AppStrings.Vault.filterMastered(5) == "Mastered (5)")
        #expect(AppStrings.Vault.filterBookmarked(3) == "Saved (3)")
        #expect(AppStrings.Vault.actionPracticeText == "PRACTICE")
        #expect(AppStrings.Vault.emptyNotMasteredText == "No unmastered words")
        #expect(AppStrings.Vault.emptyMasteredText == "No mastered words yet")
        #expect(AppStrings.Vault.emptyBookmarkedText == "No saved words yet")
        #expect(AppStrings.Vault.emptySearchNoResultsText == "No matching words found")
        #expect(AppStrings.Vault.detailDefinitionsTitleText == "Definitions")
        #expect(AppStrings.Vault.detailExamplesTitleText == "Examples")
        #expect(AppStrings.Vault.detailProgressTitleText == "Reflex Progress")
        #expect(AppStrings.Vault.detailStreakCount(7) == "7 streak")
        #expect(AppStrings.Vault.detailPracticedModesText == "Practiced modes")
    }
}
