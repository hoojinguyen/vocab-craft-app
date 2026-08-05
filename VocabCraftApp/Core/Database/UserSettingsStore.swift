import SwiftUI
import Foundation

@Observable
public final class UserSettingsStore: @unchecked Sendable {
    @ObservationIgnored
    @AppStorage("daily_goal_count") public var dailyGoalCount: Int = 15
    
    @ObservationIgnored
    @AppStorage("is_notification_enabled") public var isNotificationEnabled: Bool = true
    
    @ObservationIgnored
    @AppStorage("notification_time_interval") public var notificationTimeInterval: Double = 72000 // Default 20:00
    
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
    
    @ObservationIgnored
    @AppStorage("tts_voice_gender") public var ttsVoiceGender: String = "US"
    
    @ObservationIgnored
    @AppStorage("tts_speed") public var ttsSpeed: Double = 0.85
    
    @ObservationIgnored
    @AppStorage("app_theme") public var appTheme: String = "system"
    
    @ObservationIgnored
    @AppStorage("is_haptics_enabled") public var isHapticsEnabled: Bool = true
    
    @ObservationIgnored
    @AppStorage("is_sound_effects_enabled") public var isSoundEffectsEnabled: Bool = true

    public init() {}
}
