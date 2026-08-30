import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Reflex Localization Tests")
struct ReflexLocalizationTests {
    @Test("Typing localized string helpers return formatted values")
    func testTypingLocalizationHelpers() {
        let enteredStr = AppStrings.ReflexBlitz.typingEnteredPrefix("apple")
        #expect(enteredStr.contains("apple"))

        let youTypedStr = AppStrings.ReflexBlitz.typingYouTypedPrefix("aple")
        #expect(youTypedStr.contains("aple"))

        let placeholder = AppStrings.ReflexBlitz.typingPlaceholderText
        #expect(!placeholder.isEmpty)
    }

    @Test("Verifies Listening mode localization keys in AppStrings and Localizable catalog")
    func testListeningLocalizationKeys() {
        #expect(!AppStrings.ReflexBlitz.listeningInstructionText.isEmpty)
        #expect(AppStrings.ReflexBlitz.listeningInstructionText != "app.reflex.listening.instruction")
        #expect(!AppStrings.ReflexBlitz.listeningReplayA11y.isEmpty)
        #expect(AppStrings.ReflexBlitz.listeningReplayA11y != "app.reflex.listening.replay_a11y")
        #expect(!AppStrings.ReflexBlitz.listeningWaveformA11y.isEmpty)
        #expect(AppStrings.ReflexBlitz.listeningWaveformA11y != "app.reflex.listening.waveform_a11y")
    }
}
#endif
