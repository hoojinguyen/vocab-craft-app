import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("PracticeSelection Localization Tests")
struct PracticeSelectionLocalizationTests {
    private let requiredPracticeKeys: [String: (vi: String, en: String)] = [
        "app.practice.selection.title": ("Luyện tập", "Practice Selection"),
        "app.practice.selection.back": ("Quay lại", "Back"),
        "app.practice.selection.close": ("Đóng", "Close"),
        "app.practice.selection.selected_count": ("%lld đã chọn", "%lld selected"),
        "app.practice.selection.total_count": ("%lld từ trong danh sách", "%lld words in list"),
        "app.practice.selection.select_all": ("Chọn tất cả", "Select All"),
        "app.practice.selection.deselect_all": ("Bỏ chọn tất cả", "Deselect All"),
        "app.practice.selection.smart_pick": ("⚡️ Luyện tập nhanh", "⚡️ Smart Practice"),
        "app.practice.selection.start_button": ("BẮT ĐẦU LUYỆN TẬP (%lld TỪ)", "START PRACTICE (%lld WORDS)"),
        "app.practice.selection.empty_prompt": ("VUI LÒNG CHỌN TỪ ĐỂ BẮT ĐẦU", "SELECT WORDS TO START"),
        "app.practice.selection.empty_title": ("Chưa có từ vựng", "No vocabulary"),
        "app.practice.selection.empty_message": ("Không tìm thấy từ vựng nào trong mục này.", "No vocabulary found in this section."),
        "app.practice.drill.cant_speak_now": ("Không thể nói lúc này", "Can't speak now"),
        "app.practice.selection.mode.speaking": ("Luyện nói", "Speaking"),
        "app.practice.selection.mode.typing": ("Gõ từ", "Typing"),
        "app.practice.selection.mode.multiple_choice": ("Trắc nghiệm", "Multiple Choice"),
        "app.practice.selection.mode.listening": ("Luyện nghe", "Listening"),
        "app.practice.selection.mode_mastered": ("Đã đạt: %@", "Mastered: %@"),
        "app.practice.selection.mode_unmastered": ("Chưa đạt: %@", "Not mastered: %@"),
        "app.practice.selection.toggle_a11y": ("Chọn từ %@", "Select word %@"),
        "app.practice.selection.audio_a11y": ("Nghe phát âm từ %@", "Play pronunciation for %@")
    ]

    @Test("Kiểm tra sự tồn tại và định dạng của các localization keys trong Practice")
    func testPracticeLocalizationKeys() {
        for (key, values) in requiredPracticeKeys {
            #expect(!key.isEmpty)
            #expect(key.hasPrefix("app.practice."))
            #expect(!values.vi.isEmpty)
            #expect(!values.en.isEmpty)
        }
    }

    @Test("Kiểm tra tính toàn vẹn và song ngữ EN/VI trong catalog xcstrings cho Practice")
    func testPracticeCatalogIntegrity() throws {
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

        for (key, expected) in requiredPracticeKeys {
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

    @Test("Kiểm tra typed accessors trong AppStrings.Practice")
    func testAppStringsPracticeAccessors() {
        #expect(AppStrings.Practice.titleText == "Practice Selection")
        #expect(AppStrings.Practice.backText == "Back")
        #expect(AppStrings.Practice.closeText == "Close")
        #expect(AppStrings.Practice.selectedCount(3) == "3 selected")
        #expect(AppStrings.Practice.totalCount(10) == "10 words in list")
        #expect(AppStrings.Practice.selectAllText == "Select All")
        #expect(AppStrings.Practice.deselectAllText == "Deselect All")
        #expect(AppStrings.Practice.smartPickText == "⚡️ Smart Practice")
        #expect(AppStrings.Practice.startButton(5) == "START PRACTICE (5 WORDS)")
        #expect(AppStrings.Practice.emptyPromptText == "SELECT WORDS TO START")
        #expect(AppStrings.Practice.emptyTitleText == "No vocabulary")
        #expect(AppStrings.Practice.emptyMessageText == "No vocabulary found in this section.")
        #expect(AppStrings.Practice.cantSpeakNowText == "Can't speak now")
        #expect(AppStrings.Practice.modeTitle(.speaking) == "Speaking")
        #expect(AppStrings.Practice.modeTitle(.typing) == "Typing")
        #expect(AppStrings.Practice.modeTitle(.multipleChoice) == "Multiple Choice")
        #expect(AppStrings.Practice.modeTitle(.listening) == "Listening")
        #expect(AppStrings.Practice.modeAccessibilityLabel(mode: .speaking, isMastered: true) == "Mastered: Speaking")
        #expect(AppStrings.Practice.modeAccessibilityLabel(mode: .typing, isMastered: false) == "Not mastered: Typing")
        #expect(AppStrings.Practice.toggleA11yLabel(lemma: "apple") == "Select word apple")
        #expect(AppStrings.Practice.audioA11yLabel(lemma: "apple") == "Play pronunciation for apple")
    }
}
#endif
