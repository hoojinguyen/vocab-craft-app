import SwiftUI

// MARK: - Vocabulary Vault Extension
extension AppStrings {
    public enum Vault {
        public static var title: LocalizedStringKey { "app.vault.title" }
        public static var titleText: String {
            String(localized: "app.vault.title", defaultValue: "Kho Từ", bundle: .module)
        }
        public static var searchPlaceholder: LocalizedStringKey { "app.vault.search_placeholder" }
        public static var searchPlaceholderText: String {
            String(localized: "app.vault.search_placeholder", defaultValue: "Tìm kiếm từ vựng...", bundle: .module)
        }
        public static var filterNotMasteredTitle: String {
            String(localized: "app.vault.filter.not_mastered_title", defaultValue: "Chưa thuộc", bundle: .module)
        }
        public static var filterMasteredTitle: String {
            String(localized: "app.vault.filter.mastered_title", defaultValue: "Đã thuộc", bundle: .module)
        }
        public static var filterBookmarkedTitle: String {
            String(localized: "app.vault.filter.bookmarked_title", defaultValue: "Đã lưu", bundle: .module)
        }
        public static func filterNotMastered(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.not_mastered", defaultValue: "Chưa thuộc (%lld)", bundle: .module), count)
        }
        public static func filterMastered(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.mastered", defaultValue: "Đã thuộc (%lld)", bundle: .module), count)
        }
        public static func filterBookmarked(_ count: Int) -> String {
            String(format: String(localized: "app.vault.filter.bookmarked", defaultValue: "Đã lưu (%lld)", bundle: .module), count)
        }
        public static var actionPractice: LocalizedStringKey { "app.vault.action.review_words" }
        public static var actionPracticeText: String {
            String(localized: "app.vault.action.review_words", defaultValue: "LUYỆN TẬP", bundle: .module)
        }
        public static func actionReviewWords(_ count: Int = 0) -> String {
            actionPracticeText
        }
        public static func actionPracticeWords(_ count: Int = 0) -> String {
            actionPracticeText
        }
        public static var emptyNotMastered: LocalizedStringKey { "app.vault.empty.not_mastered" }
        public static var emptyNotMasteredText: String {
            String(localized: "app.vault.empty.not_mastered", defaultValue: "Bạn không có từ nào chưa thuộc", bundle: .module)
        }
        public static var emptyMastered: LocalizedStringKey { "app.vault.empty.mastered" }
        public static var emptyMasteredText: String {
            String(localized: "app.vault.empty.mastered", defaultValue: "Chưa có từ nào đạt mức thành thạo", bundle: .module)
        }
        public static var emptyBookmarked: LocalizedStringKey { "app.vault.empty.bookmarked" }
        public static var emptyBookmarkedText: String {
            String(localized: "app.vault.empty.bookmarked", defaultValue: "Chưa có từ nào được lưu", bundle: .module)
        }
        public static var emptySearchNoResults: LocalizedStringKey { "app.vault.empty.search_no_results" }
        public static var emptySearchNoResultsText: String {
            String(localized: "app.vault.empty.search_no_results", defaultValue: "Không tìm thấy từ nào phù hợp", bundle: .module)
        }
        public static var detailDefinitionsTitle: LocalizedStringKey { "app.vault.detail.definitions_title" }
        public static var detailDefinitionsTitleText: String {
            String(localized: "app.vault.detail.definitions_title", defaultValue: "Định nghĩa", bundle: .module)
        }
        public static var detailExamplesTitle: LocalizedStringKey { "app.vault.detail.examples_title" }
        public static var detailExamplesTitleText: String {
            String(localized: "app.vault.detail.examples_title", defaultValue: "Ví dụ thực tế", bundle: .module)
        }
        public static var detailProgressTitle: LocalizedStringKey { "app.vault.detail.progress_title" }
        public static var detailProgressTitleText: String {
            String(localized: "app.vault.detail.progress_title", defaultValue: "Tiến độ phản xạ", bundle: .module)
        }
        public static func detailStreakCount(_ count: Int) -> String {
            String(format: String(localized: "app.vault.detail.streak_count", defaultValue: "Chuỗi đúng %lld", bundle: .module), count)
        }
        public static var detailPracticedModes: LocalizedStringKey { "app.vault.detail.practiced_modes" }
        public static var detailPracticedModesText: String {
            String(localized: "app.vault.detail.practiced_modes", defaultValue: "Chế độ đã luyện", bundle: .module)
        }
    }
}
