import SwiftUI

// MARK: - Profile & Achievements Extension
extension AppStrings {
    public enum Profile {
        public static var title: LocalizedStringKey { "app.profile.title" }
        public static var titleText: String { String(localized: "app.profile.title", defaultValue: "Profile & Achievements", bundle: .module) }
        public static var wordsLearned: LocalizedStringKey { "app.profile.words_learned" }
        public static var wordsLearnedText: String { String(localized: "app.profile.words_learned", defaultValue: "Words Learned", bundle: .module) }
        public static var reflexAccuracy: LocalizedStringKey { "app.profile.reflex_accuracy" }
        public static var reflexAccuracyText: String { String(localized: "app.profile.reflex_accuracy", defaultValue: "Reflex Accuracy", bundle: .module) }
        public static var avgSpeed: LocalizedStringKey { "app.profile.avg_speed" }
        public static var avgSpeedText: String { String(localized: "app.profile.avg_speed", defaultValue: "Avg Speed", bundle: .module) }
        public static var streakDays: LocalizedStringKey { "app.profile.streak_days" }
        public static var streakDaysText: String { String(localized: "app.profile.streak_days", defaultValue: "Streak Days", bundle: .module) }
        public static var cefrMastery: LocalizedStringKey { "app.profile.cefr_mastery" }
        public static var cefrMasteryText: String { String(localized: "app.profile.cefr_mastery", defaultValue: "Oxford CEFR Mastery", bundle: .module) }
        public static var achievements: LocalizedStringKey { "app.profile.achievements" }
        public static var achievementsText: String { String(localized: "app.profile.achievements", defaultValue: "Badges & Achievements", bundle: .module) }
        public static var badgeReflexMaster: LocalizedStringKey { "app.profile.badge_reflex_master" }
        public static var badgeReflexMasterText: String { String(localized: "app.profile.badge_reflex_master", defaultValue: "Reflex Master", bundle: .module) }
        public static var badgeStreakBlaze: LocalizedStringKey { "app.profile.badge_streak_blaze" }
        public static var badgeStreakBlazeText: String { String(localized: "app.profile.badge_streak_blaze", defaultValue: "14-Day Blaze", bundle: .module) }
        public static var badgeOxfordPioneer: LocalizedStringKey { "app.profile.badge_oxford_pioneer" }
        public static var badgeOxfordPioneerText: String { String(localized: "app.profile.badge_oxford_pioneer", defaultValue: "Oxford Pioneer", bundle: .module) }
    }
}
