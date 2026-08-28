import CraftUIKit
import SwiftUI
@testable import VocabCraftApp
import XCTest

@MainActor
final class SettingsViewTests: XCTestCase {
    func testSettingsViewInitialization() {
        let store = UserSettingsStore()
        let tts = MockTextToSpeechService()
        let vm = SettingsViewModel(store: store, ttsService: tts)
        let view = SettingsView(viewModel: vm)
        XCTAssertNotNil(view.viewModel)
    }

    func testHeroProfileCardInitialization() {
        var actionTapped = false
        let card = HeroProfileCard(
            userName: "Hooji N.",
            userLevel: "B2 Intermediate",
            onTapAction: { actionTapped = true }
        )
        XCTAssertEqual(card.userName, "Hooji N.")
        XCTAssertEqual(card.userLevel, "B2 Intermediate")
        card.onTapAction?()
        XCTAssertTrue(actionTapped)
    }

    func testHeroProfileCardBodyRendering() {
        let card = HeroProfileCard(
            userName: "Hooji N.",
            userLevel: "B2 Intermediate",
            onTapAction: {}
        )
        let body = card.body
        XCTAssertNotNil(body)
    }

    func testSettingsViewBodyRendering() {
        let store = UserSettingsStore()
        let tts = MockTextToSpeechService()
        let vm = SettingsViewModel(store: store, ttsService: tts)
        let view = SettingsView(viewModel: vm)
        let body = view.body
        XCTAssertNotNil(body)
    }

    func testSettingsViewNotificationEnabledBodyRendering() {
        let store = UserSettingsStore()
        store.isNotificationEnabled = true
        let tts = MockTextToSpeechService()
        let vm = SettingsViewModel(store: store, ttsService: tts)
        let view = SettingsView(viewModel: vm)
        let body = view.body
        XCTAssertNotNil(body)
    }

    func testSettingsViewAudioPlayingBodyRendering() {
        let store = UserSettingsStore()
        let tts = MockTextToSpeechService()
        let vm = SettingsViewModel(store: store, ttsService: tts)
        vm.isPlayingAudio = true
        let view = SettingsView(viewModel: vm)
        let body = view.body
        XCTAssertNotNil(body)
    }

    func testThemePresetBindingInteraction() {
        let store = UserSettingsStore()
        store.themePreset = .editorial
        XCTAssertEqual(store.themePreset, .editorial)

        store.themePreset = .neoArcade
        XCTAssertEqual(store.themePreset, .neoArcade)

        store.themePreset = .kyotoMatcha
        XCTAssertEqual(store.themePreset, .kyotoMatcha)
    }

    func testAppThemeSegmentBindingInteraction() {
        let store = UserSettingsStore()
        store.appTheme = "dark"
        XCTAssertEqual(store.appTheme, "dark")
        XCTAssertEqual(store.colorScheme, .dark)

        store.appTheme = "light"
        XCTAssertEqual(store.appTheme, "light")
        XCTAssertEqual(store.colorScheme, .light)

        store.appTheme = "system"
        XCTAssertEqual(store.appTheme, "system")
        XCTAssertNil(store.colorScheme)
    }

    func testTTSVoiceGenderSegmentBindingInteraction() {
        let store = UserSettingsStore()
        store.ttsVoiceGender = "US"
        XCTAssertEqual(store.ttsVoiceGender, "US")

        store.ttsVoiceGender = "UK"
        XCTAssertEqual(store.ttsVoiceGender, "UK")
    }

    func testDailyGoalStepperAdjustment() {
        let store = UserSettingsStore()
        store.dailyGoalCount = 15

        store.dailyGoalCount = min(100, store.dailyGoalCount + 5)
        XCTAssertEqual(store.dailyGoalCount, 20)

        store.dailyGoalCount = max(5, store.dailyGoalCount - 5)
        XCTAssertEqual(store.dailyGoalCount, 15)
    }

    func testAppLanguageBindingInteraction() {
        let store = UserSettingsStore()
        store.appLanguage = "vi"
        XCTAssertEqual(store.appLanguage, "vi")
        XCTAssertEqual(store.appLocale?.identifier, "vi")

        store.appLanguage = "en"
        XCTAssertEqual(store.appLanguage, "en")
        XCTAssertEqual(store.appLocale?.identifier, "en")

        store.appLanguage = "system"
        XCTAssertEqual(store.appLanguage, "system")
        XCTAssertNil(store.appLocale)
    }

    func testHapticsAndSoundEffectsToggles() {
        let store = UserSettingsStore()
        store.isHapticsEnabled = true
        store.isSoundEffectsEnabled = true

        store.isHapticsEnabled.toggle()
        XCTAssertFalse(store.isHapticsEnabled)

        store.isSoundEffectsEnabled.toggle()
        XCTAssertFalse(store.isSoundEffectsEnabled)
    }
}
