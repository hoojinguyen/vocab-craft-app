import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("PracticeSelection Localization Tests")
struct PracticeSelectionLocalizationTests {
    private let requiredPracticeKeys: [String: (vi: String, en: String)] = [
        "app.practice.selection.title": ("Chọn từ luyện tập", "Select Words"),
        "app.practice.selection.back": ("Quay lại", "Back"),
        "app.practice.selection.close": ("Đóng", "Close"),
        "app.practice.selection.selected_count": ("%lld đã chọn", "%lld selected"),
        "app.practice.selection.select_all": ("Chọn tất cả", "Select All"),
        "app.practice.selection.deselect_all": ("Bỏ chọn tất cả", "Deselect All"),
        "app.practice.selection.smart_pick": ("Luyện tập thông minh", "Smart Practice"),
        "app.practice.selection.start_button": ("BẮT ĐẦU (%lld TỪ)", "START PRACTICE (%lld WORDS)"),
        "app.practice.selection.empty_prompt": ("CHỌN TỪ ĐỂ BẮT ĐẦU", "SELECT WORDS TO START"),
        "app.practice.selection.empty_title": ("Chưa có từ vựng", "No vocabulary"),
        "app.practice.selection.empty_message": ("Không tìm thấy từ vựng nào trong mục này.", "No vocabulary found in this section."),
        "app.practice.drill.cant_speak_now": ("Không thể nói lúc này", "Can't speak now"),
        "app.practice.countdown.mixed_title": ("Luyện tập tổng hợp", "Mixed Reflex Drill"),
        "app.practice.countdown.mixed_subtitle": ("Phản xạ 4 kỹ năng: Trắc nghiệm, Gõ, Nghe & Nói", "Multi-sensory reflex: Quiz, Typing, Listening & Speaking"),
        "app.practice.selection.toggle_a11y": ("Chọn từ %@", "Select word %@")
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
        var catalogURL: URL?

        // Check Bundle first
        if let bundlePath = Bundle.main.path(forResource: "Localizable", ofType: "xcstrings") {
            catalogURL = URL(fileURLWithPath: bundlePath)
        }

        // Check relative file paths up the hierarchy
        if catalogURL == nil {
            var currentDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            for _ in 0..<5 {
                let candidate = currentDir.appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
                if FileManager.default.fileExists(atPath: candidate.path) {
                    catalogURL = candidate
                    break
                }
                let directCandidate = currentDir.appendingPathComponent("Resources/Localizable.xcstrings")
                if FileManager.default.fileExists(atPath: directCandidate.path) {
                    catalogURL = directCandidate
                    break
                }
                currentDir = currentDir.deletingLastPathComponent()
            }
        }

        let fileData = try #require(catalogURL.flatMap { try? Data(contentsOf: $0) }, "Localizable.xcstrings should be found")
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
        #expect(!AppStrings.Practice.titleText.isEmpty)
        #expect(!AppStrings.Practice.backText.isEmpty)
        #expect(!AppStrings.Practice.closeText.isEmpty)
        #expect(AppStrings.Practice.selectedCount(3).contains("3"))
        #expect(!AppStrings.Practice.selectAllText.isEmpty)
        #expect(!AppStrings.Practice.deselectAllText.isEmpty)
        #expect(!AppStrings.Practice.smartPickText.isEmpty)
        #expect(AppStrings.Practice.startButton(5).contains("5"))
        #expect(!AppStrings.Practice.emptyPromptText.isEmpty)
        #expect(!AppStrings.Practice.emptyTitleText.isEmpty)
        #expect(!AppStrings.Practice.emptyMessageText.isEmpty)
        #expect(!AppStrings.Practice.cantSpeakNowText.isEmpty)
        #expect(!AppStrings.Practice.mixedDrillTitleText.isEmpty)
        #expect(!AppStrings.Practice.mixedDrillSubtitleText.isEmpty)
        #expect(AppStrings.Practice.toggleA11yLabel(lemma: "apple").contains("apple"))
    }
}
#endif
