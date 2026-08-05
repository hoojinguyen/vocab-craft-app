import SwiftUI
import Foundation

@Observable
public final class UserSettingsStore: @unchecked Sendable {
    @ObservationIgnored
    @AppStorage("daily_goal_count") public var dailyGoalCount: Int = 15
    
    @ObservationIgnored
    @AppStorage("is_notification_enabled") public var isNotificationEnabled: Bool = true
    
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
