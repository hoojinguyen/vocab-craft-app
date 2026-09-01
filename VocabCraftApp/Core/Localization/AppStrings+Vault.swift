import SwiftUI

// MARK: - Vocabulary Vault Extension
extension AppStrings {
    public enum Vault {
        public static var title: LocalizedStringKey { "app.vault.title" }
        public static var titleText: String {
            String(localized: "app.vault.title", defaultValue: "Vocabulary", bundle: .module)
        }
        public static var searchPlaceholder: LocalizedStringKey { "app.vault.search_placeholder" }
        public static var searchPlaceholderText: String {
            String(localized: "app.vault.search_placeholder", defaultValue: "Search vocabulary...", bundle: .module)
        }
        public static var searchToggleA11y: String {
            String(localized: "app.vault.header.search_toggle", defaultValue: "Toggle Search", bundle: .module)
        }
        public static var filterNotMasteredTitle: String {
            String(localized: "app.vault.filter.not_mastered_title", defaultValue: "Learning", bundle: .module)
        }
        public static var filterMasteredTitle: String {
            String(localized: "app.vault.filter.mastered_title", defaultValue: "Mastered", bundle: .module)
        }
        public static var filterBookmarkedTitle: String {
            String(localized: "app.vault.filter.bookmarked_title", defaultValue: "Saved", bundle: .module)
        }
        public static func filterNotMastered(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.not_mastered", defaultValue: "Learning (%lld)", bundle: .module), count)
        }
        public static func filterMastered(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.mastered", defaultValue: "Mastered (%lld)", bundle: .module), count)
        }
        public static func filterBookmarked(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.bookmarked", defaultValue: "Saved (%lld)", bundle: .module), count)
        }
        public static var actionPractice: LocalizedStringKey { "app.vault.action.review_words" }
        public static var actionPracticeText: String {
            String(localized: "app.vault.action.review_words", defaultValue: "PRACTICE", bundle: .module)
        }
        public static func actionReviewWords(_ count: Int = 0) -> String {
            actionPracticeText
        }
        public static func actionPracticeWords(_ count: Int = 0) -> String {
            actionPracticeText
        }
        public static var emptyNotMastered: LocalizedStringKey { "app.vault.empty.not_mastered" }
        public static var emptyNotMasteredText: String {
            String(localized: "app.vault.empty.not_mastered", defaultValue: "No unmastered words", bundle: .module)
        }
        public static var emptyMastered: LocalizedStringKey { "app.vault.empty.mastered" }
        public static var emptyMasteredText: String {
            String(localized: "app.vault.empty.mastered", defaultValue: "No mastered words yet", bundle: .module)
        }
        public static var emptyBookmarked: LocalizedStringKey { "app.vault.empty.bookmarked" }
        public static var emptyBookmarkedText: String {
            String(localized: "app.vault.empty.bookmarked", defaultValue: "No saved words yet", bundle: .module)
        }
        public static var emptySearchNoResults: LocalizedStringKey { "app.vault.empty.search_no_results" }
        public static var emptySearchNoResultsText: String {
            String(localized: "app.vault.empty.search_no_results", defaultValue: "No matching words found", bundle: .module)
        }
        public static var detailDefinitionsTitle: LocalizedStringKey { "app.vault.detail.definitions_title" }
        public static var detailDefinitionsTitleText: String {
            String(localized: "app.vault.detail.definitions_title", defaultValue: "Definitions", bundle: .module)
        }
        public static var detailExamplesTitle: LocalizedStringKey { "app.vault.detail.examples_title" }
        public static var detailExamplesTitleText: String {
            String(localized: "app.vault.detail.examples_title", defaultValue: "Examples", bundle: .module)
        }
        public static var detailProgressTitle: LocalizedStringKey { "app.vault.detail.progress_title" }
        public static var detailProgressTitleText: String {
            String(localized: "app.vault.detail.progress_title", defaultValue: "Reflex Progress", bundle: .module)
        }
        public static func detailStreakCount(_ count: Int) -> String {
            String(format: String(localized: "app.vault.detail.streak_count", defaultValue: "%lld streak", bundle: .module), count)
        }
        public static var detailPracticedModes: LocalizedStringKey { "app.vault.detail.practiced_modes" }
        public static var detailPracticedModesText: String {
            String(localized: "app.vault.detail.practiced_modes", defaultValue: "Practiced modes", bundle: .module)
        }
        public static var statusMastered: LocalizedStringKey { "app.vault.status.mastered" }
        public static var statusMasteredText: String {
            String(localized: "app.vault.status.mastered", defaultValue: "Mastered", bundle: .module)
        }

        // MARK: - Smart Review
        public enum SmartReview {
            public static var title: LocalizedStringKey { "app.vault.smart_review.title" }
            public static var titleText: String {
                String(localized: "app.vault.smart_review.title", defaultValue: "Focused Review", bundle: .module)
            }
            public static var pronounce: LocalizedStringKey { "app.vault.smart_review.pronounce" }
            public static var pronounceText: String {
                String(localized: "app.vault.smart_review.pronounce", defaultValue: "Pronounce", bundle: .module)
            }
            public static var definitionVi: LocalizedStringKey { "app.vault.smart_review.definition_vi" }
            public static var definitionViText: String {
                String(localized: "app.vault.smart_review.definition_vi", defaultValue: "Vietnamese Meaning", bundle: .module)
            }
            public static var definitionEn: LocalizedStringKey { "app.vault.smart_review.definition_en" }
            public static var definitionEnText: String {
                String(localized: "app.vault.smart_review.definition_en", defaultValue: "English Definition", bundle: .module)
            }
            public static var contextExample: LocalizedStringKey { "app.vault.smart_review.context_example" }
            public static var contextExampleText: String {
                String(localized: "app.vault.smart_review.context_example", defaultValue: "Context Example", bundle: .module)
            }
            public static var showAnswer: LocalizedStringKey { "app.vault.smart_review.show_answer" }
            public static var showAnswerText: String {
                String(localized: "app.vault.smart_review.show_answer", defaultValue: "Show Meaning & Example", bundle: .module)
            }
            public static var notRemembered: LocalizedStringKey { "app.vault.smart_review.not_remembered" }
            public static var notRememberedText: String {
                String(localized: "app.vault.smart_review.not_remembered", defaultValue: "Forgot", bundle: .module)
            }
            public static var remembered: LocalizedStringKey { "app.vault.smart_review.remembered" }
            public static var rememberedText: String {
                String(localized: "app.vault.smart_review.remembered", defaultValue: "Remembered", bundle: .module)
            }
            public static var completedTitle: LocalizedStringKey { "app.vault.smart_review.completed_title" }
            public static var completedTitleText: String {
                String(localized: "app.vault.smart_review.completed_title", defaultValue: "Review Completed!", bundle: .module)
            }
            public static func completedDesc(_ count: Int) -> String {
                String(format: String(localized: "app.vault.smart_review.completed_desc_format", defaultValue: "You reviewed all %lld weak words in this session.", bundle: .module), count)
            }
            public static var finishAndReturn: LocalizedStringKey { "app.vault.smart_review.finish_and_return" }
            public static var finishAndReturnText: String {
                String(localized: "app.vault.smart_review.finish_and_return", defaultValue: "Finish & Return", bundle: .module)
            }
            public static var emptyTitle: LocalizedStringKey { "app.vault.smart_review.empty_title" }
            public static var emptyTitleText: String {
                String(localized: "app.vault.smart_review.empty_title", defaultValue: "No weak words!", bundle: .module)
            }
            public static var emptyDesc: LocalizedStringKey { "app.vault.smart_review.empty_desc" }
            public static var emptyDescText: String {
                String(localized: "app.vault.smart_review.empty_desc", defaultValue: "All vocabulary in your vault is currently well remembered.", bundle: .module)
            }
            public static var close: LocalizedStringKey { "app.vault.smart_review.close" }
            public static var closeText: String {
                String(localized: "app.vault.smart_review.close", defaultValue: "Close", bundle: .module)
            }
        }
    }
}
