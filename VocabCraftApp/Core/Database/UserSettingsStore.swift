import CraftUIKit
import Foundation
import SwiftUI

@MainActor
@Observable
public final class UserSettingsStore {
    public var themePreset: CraftThemePreset {
        get { CraftThemeManager.shared.currentPreset }
        set { CraftThemeManager.shared.setPreset(newValue) }
    }

    public var dailyGoalCount: Int {
        didSet {
            UserDefaults.standard.set(dailyGoalCount, forKey: "daily_goal_count")
        }
    }

    public var isNotificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isNotificationEnabled, forKey: "is_notification_enabled")
        }
    }

    public var notificationTimeInterval: Double {
        didSet {
            UserDefaults.standard.set(notificationTimeInterval, forKey: "notification_time_interval")
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
            UserDefaults.standard.set(ttsVoiceGender, forKey: "tts_voice_gender")
        }
    }

    public var ttsSpeed: Double {
        didSet {
            UserDefaults.standard.set(ttsSpeed, forKey: "tts_speed")
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
            UserDefaults.standard.set(isHapticsEnabled, forKey: "is_haptics_enabled")
        }
    }

    public var isSoundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEffectsEnabled, forKey: "is_sound_effects_enabled")
        }
    }

    public var appLanguage: String {
        didSet {
            UserDefaults.standard.set(appLanguage, forKey: "app_language")
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

    public init() {
        let defaults = UserDefaults.standard
        self.dailyGoalCount = defaults.object(forKey: "daily_goal_count") != nil ? defaults.integer(forKey: "daily_goal_count") : 15
        self.isNotificationEnabled = defaults.object(forKey: "is_notification_enabled") != nil ? defaults.bool(forKey: "is_notification_enabled") : true
        self.notificationTimeInterval = defaults.object(forKey: "notification_time_interval") != nil ? defaults.double(forKey: "notification_time_interval") : 72000
        self.ttsVoiceGender = defaults.string(forKey: "tts_voice_gender") ?? "US"
        self.ttsSpeed = defaults.object(forKey: "tts_speed") != nil ? defaults.double(forKey: "tts_speed") : 1.0
        self.appLanguage = defaults.string(forKey: "app_language") ?? "system"
        self.isHapticsEnabled = defaults.object(forKey: "is_haptics_enabled") != nil ? defaults.bool(forKey: "is_haptics_enabled") : true
        self.isSoundEffectsEnabled = defaults.object(forKey: "is_sound_effects_enabled") != nil ? defaults.bool(forKey: "is_sound_effects_enabled") : true
    }
}
