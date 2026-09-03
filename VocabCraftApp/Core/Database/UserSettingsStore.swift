import CraftUIKit
import Foundation
import SwiftUI

@MainActor
@Observable
public final class UserSettingsStore {
    private let defaults: UserDefaults

    public var themePreset: CraftThemePreset {
        get { CraftThemeManager.shared.currentPreset }
        set { CraftThemeManager.shared.setPreset(newValue) }
    }

    public var dailyGoalCount: Int {
        didSet {
            defaults.set(dailyGoalCount, forKey: "daily_goal_count")
        }
    }

    public var isNotificationEnabled: Bool {
        didSet {
            defaults.set(isNotificationEnabled, forKey: "is_notification_enabled")
        }
    }

    public var notificationTimeInterval: Double {
        didSet {
            defaults.set(notificationTimeInterval, forKey: "notification_time_interval")
        }
    }

    public var notificationTime: Date {
        get {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            return startOfDay.addingTimeInterval(notificationTimeInterval)
        }
        set {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: newValue)
            notificationTimeInterval = newValue.timeIntervalSince(startOfDay)
        }
    }

    public var ttsVoiceGender: String {
        didSet {
            defaults.set(ttsVoiceGender, forKey: "tts_voice_gender")
        }
    }

    public var ttsSpeed: Double {
        didSet {
            defaults.set(ttsSpeed, forKey: "tts_speed")
        }
    }

    public var appearanceMode: CraftAppearanceMode {
        get { CraftThemeManager.shared.appearanceMode }
        set { CraftThemeManager.shared.setAppearanceMode(newValue) }
    }

    public var appTheme: String {
        get { CraftThemeManager.shared.appearanceMode.rawValue }
        set {
            if let mode = CraftAppearanceMode(rawValue: newValue) {
                CraftThemeManager.shared.setAppearanceMode(mode)
            }
        }
    }

    public var isHapticsEnabled: Bool {
        didSet {
            defaults.set(isHapticsEnabled, forKey: "is_haptics_enabled")
        }
    }

    public var isSoundEffectsEnabled: Bool {
        didSet {
            defaults.set(isSoundEffectsEnabled, forKey: "is_sound_effects_enabled")
        }
    }

    public var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: "has_completed_onboarding")
        }
    }

    public var selectedGoalDeckId: String {
        didSet {
            defaults.set(selectedGoalDeckId, forKey: "selected_goal_deck_id")
        }
    }

    public var assessedCefrLevel: String {
        didSet {
            defaults.set(assessedCefrLevel, forKey: "assessed_cefr_level")
        }
    }

    public var currentStreak: Int {
        didSet {
            defaults.set(currentStreak, forKey: "current_streak")
        }
    }

    public var todayWordsLearnedDate: Date? {
        didSet {
            if let todayWordsLearnedDate {
                defaults.set(todayWordsLearnedDate.timeIntervalSince1970, forKey: "today_words_learned_date")
            } else {
                defaults.removeObject(forKey: "today_words_learned_date")
            }
        }
    }

    public var todayWordsLearned: Int {
        get {
            guard let date = todayWordsLearnedDate, Calendar.current.isDateInToday(date) else {
                return 0
            }
            return defaults.integer(forKey: "today_words_learned")
        }
        set {
            todayWordsLearnedDate = Date()
            defaults.set(newValue, forKey: "today_words_learned")
        }
    }

    public var appLanguage: String {
        didSet {
            defaults.set(appLanguage, forKey: "app_language")
        }
    }

    public var appLocale: Locale? {
        switch appLanguage {
        case "vi": return Locale(identifier: "vi")
        case "en": return Locale(identifier: "en")
        default: return nil
        }
    }

    public var colorScheme: ColorScheme? {
        CraftThemeManager.shared.preferredColorScheme
    }

    public init(defaults: UserDefaults = .standard, hasPersistedAppData: Bool = false) {
        self.defaults = defaults
        self.dailyGoalCount = defaults.object(forKey: "daily_goal_count") != nil ? defaults.integer(forKey: "daily_goal_count") : 15
        self.isNotificationEnabled = defaults.object(forKey: "is_notification_enabled") != nil ? defaults.bool(forKey: "is_notification_enabled") : true
        self.notificationTimeInterval = defaults.object(forKey: "notification_time_interval") != nil ? defaults.double(forKey: "notification_time_interval") : 72000
        self.ttsVoiceGender = defaults.string(forKey: "tts_voice_gender") ?? "US"
        self.ttsSpeed = defaults.object(forKey: "tts_speed") != nil ? defaults.double(forKey: "tts_speed") : 1.0
        self.appLanguage = defaults.string(forKey: "app_language") ?? "system"
        self.isHapticsEnabled = defaults.object(forKey: "is_haptics_enabled") != nil ? defaults.bool(forKey: "is_haptics_enabled") : true
        self.isSoundEffectsEnabled = defaults.object(forKey: "is_sound_effects_enabled") != nil ? defaults.bool(forKey: "is_sound_effects_enabled") : true

        if let timestamp = defaults.object(forKey: "today_words_learned_date") as? Double {
            self.todayWordsLearnedDate = Date(timeIntervalSince1970: timestamp)
        } else {
            self.todayWordsLearnedDate = nil
        }

        let completedOnboarding: Bool
        if defaults.object(forKey: "has_completed_onboarding") == nil {
            if defaults.object(forKey: "did_perform_legacy_onboarding_migration") == nil {
                let hasLegacyUserData = defaults.object(forKey: "daily_goal_count") != nil
                    || defaults.object(forKey: "is_notification_enabled") != nil
                    || defaults.object(forKey: "notification_time_interval") != nil
                    || defaults.object(forKey: "tts_voice_gender") != nil
                    || defaults.object(forKey: "tts_speed") != nil
                    || defaults.object(forKey: "is_haptics_enabled") != nil
                    || defaults.object(forKey: "is_sound_effects_enabled") != nil
                    || defaults.object(forKey: "app_language") != nil
                    || defaults.object(forKey: "selected_goal_deck_id") != nil
                    || hasPersistedAppData
                defaults.set(true, forKey: "did_perform_legacy_onboarding_migration")
                defaults.set(hasLegacyUserData, forKey: "has_completed_onboarding")
                completedOnboarding = hasLegacyUserData
                let streak = defaults.object(forKey: "current_streak") != nil
                    ? defaults.integer(forKey: "current_streak")
                    : (hasLegacyUserData ? 14 : 0)
                defaults.set(streak, forKey: "current_streak")
                self.currentStreak = streak
                if hasLegacyUserData {
                    self.todayWordsLearnedDate = Date()
                    defaults.set(Date().timeIntervalSince1970, forKey: "today_words_learned_date")
                    let existingLearned = defaults.object(forKey: "today_words_learned") != nil
                        ? defaults.integer(forKey: "today_words_learned")
                        : 8
                    defaults.set(existingLearned, forKey: "today_words_learned")
                } else {
                    self.todayWordsLearnedDate = nil
                    defaults.set(0, forKey: "today_words_learned")
                }
            } else {
                completedOnboarding = false
                self.currentStreak = defaults.object(forKey: "current_streak") != nil
                    ? defaults.integer(forKey: "current_streak")
                    : 0
            }
        } else {
            completedOnboarding = defaults.bool(forKey: "has_completed_onboarding")
            self.currentStreak = defaults.object(forKey: "current_streak") != nil
                ? defaults.integer(forKey: "current_streak")
                : 0
            if defaults.object(forKey: "today_words_learned_date") == nil,
               defaults.object(forKey: "today_words_learned") != nil {
                self.todayWordsLearnedDate = Date()
                defaults.set(Date().timeIntervalSince1970, forKey: "today_words_learned_date")
            }
        }
        self.hasCompletedOnboarding = completedOnboarding
        self.selectedGoalDeckId = defaults.string(forKey: "selected_goal_deck_id") ?? "deck_daily"
        self.assessedCefrLevel = defaults.string(forKey: "assessed_cefr_level") ?? "A1"
    }
}
