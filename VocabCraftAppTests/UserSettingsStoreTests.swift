import CraftUIKit
import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class UserSettingsStoreTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "has_completed_onboarding")
        defaults.removeObject(forKey: "selected_goal_deck_id")
        defaults.removeObject(forKey: "assessed_cefr_level")
        defaults.removeObject(forKey: "daily_goal_count")
        defaults.removeObject(forKey: "tts_voice_gender")
        defaults.removeObject(forKey: "tts_speed")
        defaults.removeObject(forKey: "is_haptics_enabled")
        defaults.removeObject(forKey: "is_sound_effects_enabled")
    }

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

    func testAppearanceModeDelegatesToCraftThemeManager() {
        let store = UserSettingsStore()

        store.appTheme = "dark"
        XCTAssertEqual(CraftThemeManager.shared.appearanceMode, .dark)
        XCTAssertEqual(store.colorScheme, .dark)

        store.appTheme = "light"
        XCTAssertEqual(CraftThemeManager.shared.appearanceMode, .light)
        XCTAssertEqual(store.colorScheme, .light)

        store.appTheme = "system"
        XCTAssertEqual(CraftThemeManager.shared.appearanceMode, .system)
        XCTAssertNil(store.colorScheme)

        store.themePreset = .kyotoMatcha
        XCTAssertEqual(CraftThemeManager.shared.currentPreset, .kyotoMatcha)
    }

    func testOnboardingSettingsDefaultAndPersistence() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "has_completed_onboarding")
        defaults.removeObject(forKey: "selected_goal_deck_id")
        defaults.removeObject(forKey: "assessed_cefr_level")
        defaults.removeObject(forKey: "daily_goal_count")

        let store = UserSettingsStore()
        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertEqual(store.selectedGoalDeckId, "deck_daily")
        XCTAssertEqual(store.assessedCefrLevel, "A1")

        store.hasCompletedOnboarding = true
        store.selectedGoalDeckId = "deck_business"
        store.assessedCefrLevel = "B2"

        XCTAssertTrue(defaults.bool(forKey: "has_completed_onboarding"))
        XCTAssertEqual(defaults.string(forKey: "selected_goal_deck_id"), "deck_business")
        XCTAssertEqual(defaults.string(forKey: "assessed_cefr_level"), "B2")
    }

    func testExistingUserMigrationMarksOnboardingCompleted() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "has_completed_onboarding")
        defaults.set(20, forKey: "daily_goal_count")

        let store = UserSettingsStore()
        XCTAssertTrue(store.hasCompletedOnboarding)
    }
}

