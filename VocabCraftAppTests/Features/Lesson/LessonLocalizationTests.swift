import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Lesson Localization Tests")
struct LessonLocalizationTests {
    private let requiredLessonKeys: [String: (vi: String, en: String)] = [
        "app.lesson.discovery.title": ("Khám phá từ mới", "Discover New Words"),
        "app.lesson.discovery.continue_action": ("Tiếp tục", "Continue"),
        "app.lesson.exercise.check_action": ("Kiểm tra", "Check"),
        "app.lesson.feedback.correct": ("Chính xác!", "Correct!"),
        "app.lesson.feedback.incorrect": ("Chưa chính xác", "Incorrect"),
        "app.lesson.feedback.correct_answer_format": ("Đáp án đúng: %@", "Correct answer: %@"),
        "app.lesson.summary.title": ("Hoàn thành bài học!", "Lesson Completed!"),
        "app.lesson.summary.xp_earned_format": ("+%lld XP", "+%lld XP"),
        "app.lesson.summary.xp_title": ("XP", "XP"),
        "app.lesson.summary.mastered_words": ("Từ vựng đã làm chủ", "Mastered Words"),
        "app.lesson.summary.learned_words": ("Từ vựng đã học", "Words Learned"),
        "app.lesson.summary.review_words": ("Cần ôn tập", "Needs Review"),
        "app.lesson.summary.accuracy": ("Độ chính xác", "Accuracy"),
        "app.lesson.summary.finish_action": ("Hoàn tất bài học", "Finish Lesson"),
        "app.lesson.exit_alert.title": ("Dừng bài học?", "Quit Lesson?"),
        "app.lesson.exit_alert.message": ("Tiến độ bài học hiện tại sẽ không được lưu nếu bạn rời khỏi bây giờ.", "Your progress for this lesson will not be saved if you leave now."),
        "app.lesson.exit_alert.confirm": ("Rời khỏi", "Quit"),
        "app.lesson.exit_alert.cancel": ("Tiếp tục học", "Keep Learning"),
        "app.lesson.exercise.skip_speaking": ("Không tiện nói lúc này", "Can't speak now"),
        "app.lesson.exercise.hint_action": ("Gợi ý", "Hint"),
        "app.lesson.exercise.skip_action": ("Bỏ qua", "Skip"),
        "app.lesson.countdown.subtitle": ("Chuẩn bị khám phá từ vựng và làm chủ bài học", "Get ready to discover words and master skills")
    ]

    @Test("All app.lesson keys exist with non-empty en and vi strings")
    func testLessonLocalizationKeysDictionary() {
        let keys = Array(requiredLessonKeys.keys)
        #expect(keys.count >= 19)

        let expectedPrefix = "app.lesson."
        for key in keys {
            #expect(!key.isEmpty, "Key cannot be empty")
            #expect(key.hasPrefix(expectedPrefix), "Key \(key) must have prefix \(expectedPrefix)")
            #expect(requiredLessonKeys[key]?.vi.isEmpty == false, "Key \(key) missing Vietnamese translation")
            #expect(requiredLessonKeys[key]?.en.isEmpty == false, "Key \(key) missing English translation")
        }
    }

    @Test("Catalog integrity check for app.lesson.* keys in Localizable.xcstrings")
    func testLessonCatalogIntegrity() throws {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            Bundle(for: LessonLocalizationTestsMarker.self).path(forResource: "Localizable", ofType: "xcstrings"),
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

        for (key, expected) in requiredLessonKeys {
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
}

private final class LessonLocalizationTestsMarker {}
#endif
