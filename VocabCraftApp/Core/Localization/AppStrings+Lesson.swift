import SwiftUI

// MARK: - Lesson Learning Flow Localization Extension
extension AppStrings {
    public enum Lesson {
        public static var discoveryTitle: LocalizedStringKey { "app.lesson.discovery.title" }
        public static var discoveryTitleText: String {
            String(localized: "app.lesson.discovery.title", defaultValue: "Khám phá từ mới", bundle: .module)
        }

        public static var continueAction: LocalizedStringKey { "app.lesson.discovery.continue_action" }
        public static var continueActionText: String {
            String(localized: "app.lesson.discovery.continue_action", defaultValue: "Tiếp tục", bundle: .module)
        }

        public static var checkAction: LocalizedStringKey { "app.lesson.exercise.check_action" }
        public static var checkActionText: String {
            String(localized: "app.lesson.exercise.check_action", defaultValue: "Kiểm tra", bundle: .module)
        }

        public static var correctFeedback: LocalizedStringKey { "app.lesson.feedback.correct" }
        public static var correctFeedbackText: String {
            String(localized: "app.lesson.feedback.correct", defaultValue: "Chính xác!", bundle: .module)
        }

        public static var incorrectFeedback: LocalizedStringKey { "app.lesson.feedback.incorrect" }
        public static var incorrectFeedbackText: String {
            String(localized: "app.lesson.feedback.incorrect", defaultValue: "Chưa chính xác", bundle: .module)
        }

        public static func correctAnswerFormat(_ answer: String) -> String {
            String(format: String(localized: "app.lesson.feedback.correct_answer_format", defaultValue: "Đáp án đúng: %@", bundle: .module), answer)
        }

        public static var summaryTitle: LocalizedStringKey { "app.lesson.summary.title" }
        public static var summaryTitleText: String {
            String(localized: "app.lesson.summary.title", defaultValue: "Hoàn thành bài học!", bundle: .module)
        }

        public static func xpEarnedFormat(_ xp: Int) -> String {
            String(format: String(localized: "app.lesson.summary.xp_earned_format", defaultValue: "+%lld XP", bundle: .module), xp)
        }

        public static var masteredWords: LocalizedStringKey { "app.lesson.summary.mastered_words" }
        public static var masteredWordsText: String {
            String(localized: "app.lesson.summary.mastered_words", defaultValue: "Từ vựng đã làm chủ", bundle: .module)
        }

        public static var accuracy: LocalizedStringKey { "app.lesson.summary.accuracy" }
        public static var accuracyText: String {
            String(localized: "app.lesson.summary.accuracy", defaultValue: "Độ chính xác", bundle: .module)
        }

        public static var finishAction: LocalizedStringKey { "app.lesson.summary.finish_action" }
        public static var finishActionText: String {
            String(localized: "app.lesson.summary.finish_action", defaultValue: "Hoàn tất bài học", bundle: .module)
        }

        public static var exitAlertTitle: LocalizedStringKey { "app.lesson.exit_alert.title" }
        public static var exitAlertTitleText: String {
            String(localized: "app.lesson.exit_alert.title", defaultValue: "Dừng bài học?", bundle: .module)
        }

        public static var exitAlertMessage: LocalizedStringKey { "app.lesson.exit_alert.message" }
        public static var exitAlertMessageText: String {
            String(localized: "app.lesson.exit_alert.message", defaultValue: "Tiến độ bài học hiện tại sẽ không được lưu nếu bạn rời khỏi bây giờ.", bundle: .module)
        }

        public static var exitAlertConfirm: LocalizedStringKey { "app.lesson.exit_alert.confirm" }
        public static var exitAlertConfirmText: String {
            String(localized: "app.lesson.exit_alert.confirm", defaultValue: "Rời khỏi", bundle: .module)
        }

        public static var exitAlertCancel: LocalizedStringKey { "app.lesson.exit_alert.cancel" }
        public static var exitAlertCancelText: String {
            String(localized: "app.lesson.exit_alert.cancel", defaultValue: "Tiếp tục học", bundle: .module)
        }

        public static var skipSpeaking: LocalizedStringKey { "app.lesson.exercise.skip_speaking" }
        public static var skipSpeakingText: String {
            String(localized: "app.lesson.exercise.skip_speaking", defaultValue: "Không tiện nói lúc này", bundle: .module)
        }

        public static var hintAction: LocalizedStringKey { "app.lesson.exercise.hint_action" }
        public static var hintActionText: String {
            String(localized: "app.lesson.exercise.hint_action", defaultValue: "Gợi ý", bundle: .module)
        }

        public static var skipAction: LocalizedStringKey { "app.lesson.exercise.skip_action" }
        public static var skipActionText: String {
            String(localized: "app.lesson.exercise.skip_action", defaultValue: "Bỏ qua", bundle: .module)
        }

        public static var countdownSubtitle: LocalizedStringKey { "app.lesson.countdown.subtitle" }
        public static var countdownSubtitleText: String {
            String(localized: "app.lesson.countdown.subtitle", defaultValue: "Chuẩn bị khám phá từ vựng và làm chủ bài học", bundle: .module)
        }
    }
}
