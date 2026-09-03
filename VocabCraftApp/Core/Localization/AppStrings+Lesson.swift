import SwiftUI

// MARK: - Lesson Learning Flow Localization Extension
extension AppStrings {
    public enum Lesson {
        public static var discoveryTitle: LocalizedStringKey { "app.lesson.discovery.title" }
        public static var discoveryTitleText: String {
            String(localized: "app.lesson.discovery.title", defaultValue: "Discover New Words", bundle: .module)
        }

        public static var continueAction: LocalizedStringKey { "app.lesson.discovery.continue_action" }
        public static var continueActionText: String {
            String(localized: "app.lesson.discovery.continue_action", defaultValue: "Continue", bundle: .module)
        }

        public static var checkAction: LocalizedStringKey { "app.lesson.exercise.check_action" }
        public static var checkActionText: String {
            String(localized: "app.lesson.exercise.check_action", defaultValue: "Check", bundle: .module)
        }

        public static var correctFeedback: LocalizedStringKey { "app.lesson.feedback.correct" }
        public static var correctFeedbackText: String {
            String(localized: "app.lesson.feedback.correct", defaultValue: "Correct!", bundle: .module)
        }

        public static var incorrectFeedback: LocalizedStringKey { "app.lesson.feedback.incorrect" }
        public static var incorrectFeedbackText: String {
            String(localized: "app.lesson.feedback.incorrect", defaultValue: "Incorrect", bundle: .module)
        }

        public static func correctAnswerFormat(_ answer: String) -> String {
            String(format: String(localized: "app.lesson.feedback.correct_answer_format", defaultValue: "Correct answer: %@", bundle: .module), answer)
        }

        public static var summaryTitle: LocalizedStringKey { "app.lesson.summary.title" }
        public static var summaryTitleText: String {
            String(localized: "app.lesson.summary.title", defaultValue: "Lesson Completed!", bundle: .module)
        }

        public static func xpEarnedFormat(_ xp: Int) -> String {
            String(format: String(localized: "app.lesson.summary.xp_earned_format", defaultValue: "+%lld XP", bundle: .module), xp)
        }

        public static var xpTitle: LocalizedStringKey { "app.lesson.summary.xp_title" }
        public static var xpTitleText: String {
            String(localized: "app.lesson.summary.xp_title", defaultValue: "XP", bundle: .module)
        }

        public static var masteredWords: LocalizedStringKey { "app.lesson.summary.mastered_words" }
        public static var masteredWordsText: String {
            String(localized: "app.lesson.summary.mastered_words", defaultValue: "Mastered Words", bundle: .module)
        }

        public static var learnedWords: LocalizedStringKey { "app.lesson.summary.learned_words" }
        public static var learnedWordsText: String {
            String(localized: "app.lesson.summary.learned_words", defaultValue: "Words Learned", bundle: .module)
        }

        public static var reviewWords: LocalizedStringKey { "app.lesson.summary.review_words" }
        public static var reviewWordsText: String {
            String(localized: "app.lesson.summary.review_words", defaultValue: "Needs Review", bundle: .module)
        }

        public static var accuracy: LocalizedStringKey { "app.lesson.summary.accuracy" }
        public static var accuracyText: String {
            String(localized: "app.lesson.summary.accuracy", defaultValue: "Accuracy", bundle: .module)
        }

        public static var finishAction: LocalizedStringKey { "app.lesson.summary.finish_action" }
        public static var finishActionText: String {
            String(localized: "app.lesson.summary.finish_action", defaultValue: "Finish Lesson", bundle: .module)
        }

        public static var exitAlertTitle: LocalizedStringKey { "app.lesson.exit_alert.title" }
        public static var exitAlertTitleText: String {
            String(localized: "app.lesson.exit_alert.title", defaultValue: "Quit Lesson?", bundle: .module)
        }

        public static var exitAlertMessage: LocalizedStringKey { "app.lesson.exit_alert.message" }
        public static var exitAlertMessageText: String {
            String(localized: "app.lesson.exit_alert.message", defaultValue: "Your progress for this lesson will not be saved if you leave now.", bundle: .module)
        }

        public static var exitAlertConfirm: LocalizedStringKey { "app.lesson.exit_alert.confirm" }
        public static var exitAlertConfirmText: String {
            String(localized: "app.lesson.exit_alert.confirm", defaultValue: "Quit", bundle: .module)
        }

        public static var exitAlertCancel: LocalizedStringKey { "app.lesson.exit_alert.cancel" }
        public static var exitAlertCancelText: String {
            String(localized: "app.lesson.exit_alert.cancel", defaultValue: "Keep Learning", bundle: .module)
        }

        public static var skipSpeaking: LocalizedStringKey { "app.lesson.exercise.skip_speaking" }
        public static var skipSpeakingText: String {
            String(localized: "app.lesson.exercise.skip_speaking", defaultValue: "Can't speak now", bundle: .module)
        }

        public static var hintAction: LocalizedStringKey { "app.lesson.exercise.hint_action" }
        public static var hintActionText: String {
            String(localized: "app.lesson.exercise.hint_action", defaultValue: "Hint", bundle: .module)
        }

        public static var skipAction: LocalizedStringKey { "app.lesson.exercise.skip_action" }
        public static var skipActionText: String {
            String(localized: "app.lesson.exercise.skip_action", defaultValue: "Skip", bundle: .module)
        }

        public static var countdownSubtitle: LocalizedStringKey { "app.lesson.countdown.subtitle" }
        public static var countdownSubtitleText: String {
            String(localized: "app.lesson.countdown.subtitle", defaultValue: "Get ready to discover words and master skills", bundle: .module)
        }

        public static var loadError: LocalizedStringKey { "app.lesson.load_error" }
        public static var loadErrorText: String {
            String(localized: "app.lesson.load_error", defaultValue: "Unable to load words for this lesson.", bundle: .module)
        }
    }
}
