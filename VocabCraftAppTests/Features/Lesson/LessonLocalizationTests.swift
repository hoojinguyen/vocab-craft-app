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
        "app.lesson.summary.accuracy_format": ("%lld%%", "%lld%%"),
        "app.lesson.summary.finish_action": ("Hoàn tất bài học", "Finish Lesson"),
        "app.lesson.exit_alert.title": ("Dừng bài học?", "Quit Lesson?"),
        "app.lesson.exit_alert.message": ("Tiến độ bài học hiện tại sẽ không được lưu nếu bạn rời khỏi bây giờ.", "Your progress for this lesson will not be saved if you leave now."),
        "app.lesson.exit_alert.confirm": ("Rời khỏi", "Quit"),
        "app.lesson.exit_alert.cancel": ("Tiếp tục học", "Keep Learning"),
        "app.lesson.exercise.skip_speaking": ("Không tiện nói lúc này", "Can't speak now"),
        "app.lesson.exercise.hint_action": ("Gợi ý", "Hint"),
        "app.lesson.exercise.skip_action": ("Bỏ qua", "Skip"),
        "app.lesson.countdown.subtitle": ("Chuẩn bị khám phá từ vựng và làm chủ bài học", "Get ready to discover words and master skills"),
        "app.lesson.load_error": ("Không thể tải từ vựng cho bài học này.", "Unable to load words for this lesson."),
        "app.lesson.permission.title": ("Cần quyền truy cập micro", "Microphone Access Required"),
        "app.lesson.permission.message": ("Vui lòng cho phép quyền truy cập micro trong Cài đặt để luyện tập các bài tập nói.", "Please allow microphone access in Settings to practice speaking exercises."),
        "app.lesson.permission.open_settings": ("Mở Cài đặt", "Open Settings"),
        "app.lesson.permission.dismiss": ("Tiếp tục bằng gõ phím", "Continue with Typing"),
        "app.lesson.attempt_error.title": ("Không thể lưu tiến độ", "Unable to Save Progress"),
        "app.lesson.attempt_error.message": ("Đã xảy ra lỗi khi lưu kết quả bài tập. Vui lòng thử lại.", "An error occurred while saving your exercise result. Please try again."),
        "app.lesson.attempt_error.retry": ("Thử lại", "Retry"),
        "app.lesson.attempt_error.dismiss": ("Hủy", "Cancel")
    ]

    @Test("AppStrings.Lesson accessors return valid non-empty values")
    func testAppStringsLessonAccessors() {
        #expect(!AppStrings.Lesson.attemptErrorTitleText.isEmpty)
        #expect(!AppStrings.Lesson.attemptErrorMessageText.isEmpty)
        #expect(!AppStrings.Lesson.attemptErrorRetryActionText.isEmpty)
        #expect(!AppStrings.Lesson.attemptErrorDismissActionText.isEmpty)
        #expect(!AppStrings.Lesson.discoveryTitleText.isEmpty)
        #expect(!AppStrings.Lesson.continueActionText.isEmpty)
        #expect(!AppStrings.Lesson.checkActionText.isEmpty)
        #expect(!AppStrings.Lesson.correctFeedbackText.isEmpty)
        #expect(!AppStrings.Lesson.incorrectFeedbackText.isEmpty)
        #expect(!AppStrings.Lesson.summaryTitleText.isEmpty)
        #expect(!AppStrings.Lesson.xpTitleText.isEmpty)
        #expect(!AppStrings.Lesson.masteredWordsText.isEmpty)
        #expect(!AppStrings.Lesson.learnedWordsText.isEmpty)
        #expect(!AppStrings.Lesson.reviewWordsText.isEmpty)
        #expect(!AppStrings.Lesson.accuracyText.isEmpty)
        #expect(!AppStrings.Lesson.finishActionText.isEmpty)
        #expect(!AppStrings.Lesson.exitAlertTitleText.isEmpty)
        #expect(!AppStrings.Lesson.exitAlertMessageText.isEmpty)
        #expect(!AppStrings.Lesson.exitAlertConfirmText.isEmpty)
        #expect(!AppStrings.Lesson.exitAlertCancelText.isEmpty)
        #expect(!AppStrings.Lesson.skipSpeakingText.isEmpty)
        #expect(!AppStrings.Lesson.hintActionText.isEmpty)
        #expect(!AppStrings.Lesson.skipActionText.isEmpty)
        #expect(!AppStrings.Lesson.countdownSubtitleText.isEmpty)
        #expect(!AppStrings.Lesson.loadErrorText.isEmpty)
        #expect(!AppStrings.Lesson.permissionTitleText.isEmpty)
        #expect(!AppStrings.Lesson.permissionMessageText.isEmpty)
        #expect(!AppStrings.Lesson.permissionSettingsActionText.isEmpty)
        #expect(!AppStrings.Lesson.permissionDismissActionText.isEmpty)
        #expect(AppStrings.Lesson.correctAnswerFormat("apple") == "Correct answer: apple")
        #expect(AppStrings.Lesson.xpEarnedFormat(25) == "+25 XP")
        #expect(AppStrings.Lesson.accuracyFormat(85) == "85%")
    }

    @Test("Catalog integrity check for app.lesson.* keys in Localizable.xcstrings")
    func testLessonCatalogIntegrity() throws {
        let data: Data? = {
            if let url = Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings"),
               let bundleData = try? Data(contentsOf: url) {
                return bundleData
            }
            if let url = Bundle(for: LessonLocalizationTestsMarker.self).url(forResource: "Localizable", withExtension: "xcstrings"),
               let bundleData = try? Data(contentsOf: url) {
                return bundleData
            }
            if let path = Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
               let bundleData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                return bundleData
            }
            let repoPath = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path
            return try? Data(contentsOf: URL(fileURLWithPath: repoPath))
        }()

        let fileData = try #require(data, "Localizable.xcstrings must be found for catalog verification")
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
