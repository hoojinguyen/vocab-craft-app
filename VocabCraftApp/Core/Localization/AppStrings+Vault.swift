import SwiftUI

// MARK: - Vocabulary Vault Extension
extension AppStrings {
    public enum Vault {
        public static var title: LocalizedStringKey { "app.vault.title" }
        public static var titleText: String {
            String(localized: "app.vault.title", defaultValue: "Vocabulary Vault", bundle: .module)
        }
        public static var searchPlaceholder: LocalizedStringKey { "app.vault.search_placeholder" }
        public static var searchPlaceholderText: String {
            String(localized: "app.vault.search_placeholder", defaultValue: "Search vocabulary...", bundle: .module)
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
    }
}
