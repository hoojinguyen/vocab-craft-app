import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Reflex Blitz Localization Tests")
struct ReflexBlitzLocalizationTests {
    private let requiredReflexKeys: [String: (vi: String, en: String)] = [
        "app.reflex.hub.badge": ("REFLEX BLITZ", "REFLEX BLITZ"),
        "app.reflex.hub.title": ("Luyện phản xạ tốc độ", "Speed Reflex Practice"),
        "app.reflex.hub.subtitle": ("Chọn phương pháp phản xạ hôm nay", "Choose your reflex modality today"),
        "app.reflex.hub.stats_title": ("Thống kê phản xạ", "Reflex Stats"),
        "app.reflex.stats.weekly_words": ("%lld từ đã luyện", "%lld practiced"),
        "app.reflex.stats.weak_words": ("%lld từ cần củng cố", "%lld need review"),
        "app.reflex.stats.avg_speed": ("Tốc độ TB", "Avg Speed"),
        "app.reflex.hub.footer_hint": ("Mỗi từ có giới hạn đếm ngược riêng biệt để tạo phản xạ vô điều kiện.", "Each word has a dedicated countdown to build unconditional reflexes."),
        "app.reflex.mode.speaking.title": ("Luyện nói", "Speaking Drill"),
        "app.reflex.mode.speaking.subtitle": ("Phản xạ phát âm & nhận diện giọng nói", "Pronunciation reflex & voice recognition"),
        "app.reflex.mode.typing.title": ("Gõ từ", "Typing Drill"),
        "app.reflex.mode.typing.subtitle": ("Phản xạ gõ phím & nhớ mặt chữ", "Keyboard reflex & spelling memory"),
        "app.reflex.mode.mc.title": ("Trắc nghiệm", "Multiple Choice"),
        "app.reflex.mode.mc.subtitle": ("Nhận diện từ vựng 1 trong 4", "1-in-4 rapid vocabulary identification"),
        "app.reflex.mode.listening.title": ("Phản xạ nghe", "Listening Reflex"),
        "app.reflex.mode.listening.subtitle": ("Bắt âm thanh & dịch nghĩa tức thì", "Audio capture & instant translation"),
        "app.reflex.drill.skip": ("Bỏ qua", "Skip"),
        "app.reflex.drill.typing_placeholder": ("Gõ từ tiếng Anh...", "Type English word..."),
        "app.reflex.drill.listening_instruction": ("Chọn nghĩa tiếng Việt của từ vừa nghe", "Select the Vietnamese meaning of the word you heard"),
        "app.reflex.drill.listening_replay": ("Nghe lại phát âm", "Replay pronunciation"),
        "app.reflex.drill.speaking_listening": ("Đang lắng nghe phát âm...", "Listening for pronunciation..."),
        "app.reflex.drill.continue_cta": ("Tiếp tục", "Continue"),
        "app.reflex.summary.title": ("Hoàn thành phiên phản xạ Blitz", "Reflex Blitz Completed"),
        "app.reflex.summary.redrill_weak": ("Luyện lại %lld từ chưa thuộc", "Re-drill %lld weak words"),
        "app.reflex.summary.finish_save": ("Hoàn thành & Lưu tiến độ", "Finish & Save Progress"),
        "app.reflex.summary.perfect_title": ("Phản xạ hoàn hảo!", "Perfect Reflex!"),
        "app.reflex.summary.perfect_desc": ("Bạn đã trả lời chính xác và nhanh chóng toàn bộ từ vựng.", "You answered all words quickly and accurately."),
        "app.reflex.summary.avg_speed": ("Tốc độ TB", "Avg Speed"),
        "app.reflex.summary.accuracy": ("Độ chính xác", "Accuracy"),
        "app.reflex.summary.max_combo": ("Combo cao nhất", "Max Combo")
    ]

    @Test("All app.reflex keys exist with non-empty en and vi strings")
    func testReflexLocalizationKeysDictionary() {
        let keys = Array(requiredReflexKeys.keys)
        #expect(keys.count >= 27, "Must have at least 27 required keys for Reflex Blitz")

        let expectedPrefix = "app.reflex."
        for key in keys {
            #expect(!key.isEmpty, "Key cannot be empty")
            #expect(key.hasPrefix(expectedPrefix), "Key \(key) must have prefix \(expectedPrefix)")
            #expect(requiredReflexKeys[key]?.vi.isEmpty == false, "Key \(key) missing Vietnamese translation")
            #expect(requiredReflexKeys[key]?.en.isEmpty == false, "Key \(key) missing English translation")
        }
    }

    @Test("Catalog integrity check for app.reflex.* keys in Localizable.xcstrings")
    func testReflexCatalogIntegrity() throws {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            Bundle(for: ReflexBlitzLocalizationTestsMarker.self).path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path,
            "VocabCraftApp/Resources/Localizable.xcstrings"
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

        for (key, expected) in requiredReflexKeys {
            let entry = try #require(strings[key], "Missing required localization key in catalog: \(key)")
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
            #expect(!enVal.isEmpty, "Key \(key) EN value cannot be empty")
            #expect(enVal == expected.en, "Key \(key) EN value expected '\(expected.en)' but found '\(enVal)'")

            // Verify VI
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(!viVal.isEmpty, "Key \(key) VI value cannot be empty")
            #expect(viVal == expected.vi, "Key \(key) VI value expected '\(expected.vi)' but found '\(viVal)'")
        }
    }

    @Test("AppStrings.ReflexBlitz accessors produce correct non-empty values")
    func testAppStringsReflexBlitzAccessors() {
        #expect(AppStrings.ReflexBlitz.hubBadgeText == "REFLEX BLITZ")
        #expect(!AppStrings.ReflexBlitz.hubTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.hubSubtitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.hubStatsTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.avgSpeedLabelText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.hubFooterHintText.isEmpty)

        #expect(!AppStrings.ReflexBlitz.speakingTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.speakingSubtitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.typingTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.typingSubtitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.mcTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.mcSubtitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.listeningTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.listeningSubtitleText.isEmpty)

        #expect(!AppStrings.ReflexBlitz.skipText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.typingPlaceholderText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.listeningInstructionText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.listeningReplayText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.speakingListeningText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.continueCTAText.isEmpty)

        #expect(!AppStrings.ReflexBlitz.summaryTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.finishSaveText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.perfectTitleText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.perfectDescText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.summaryAvgSpeedText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.summaryAccuracyText.isEmpty)
        #expect(!AppStrings.ReflexBlitz.summaryMaxComboText.isEmpty)

        #expect(AppStrings.ReflexBlitz.weeklyWords(10).contains("10"))
        #expect(AppStrings.ReflexBlitz.weakWords(3).contains("3"))
        #expect(AppStrings.ReflexBlitz.redrillWeak(5).contains("5"))
    }
}

private final class ReflexBlitzLocalizationTestsMarker {}
