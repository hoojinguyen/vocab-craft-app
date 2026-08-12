import XCTest
@testable import VocabCraftApp

@MainActor
final class UserSettingsStoreTests: XCTestCase {
    func testDefaultUserSettingsValues() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "daily_goal_count")
        defaults.removeObject(forKey: "tts_voice_gender")
        defaults.removeObject(forKey: "tts_speed")
        defaults.removeObject(forKey: "is_haptics_enabled")
        defaults.removeObject(forKey: "is_sound_effects_enabled")

        let store = UserSettingsStore()
        XCTAssertEqual(store.dailyGoalCount, 15)
        XCTAssertEqual(store.ttsVoiceGender, "US")
        XCTAssertEqual(store.ttsSpeed, 1.0)
        XCTAssertTrue(store.isHapticsEnabled)
        XCTAssertTrue(store.isSoundEffectsEnabled)
    }

}

