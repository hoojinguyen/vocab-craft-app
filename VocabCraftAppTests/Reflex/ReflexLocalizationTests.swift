import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("Reflex Typing Localization Tests")
struct ReflexTypingLocalizationTests {
    @Test("Typing localized string helpers return formatted values")
    func testTypingLocalizationHelpers() {
        let enteredStr = AppStrings.ReflexBlitz.typingEnteredPrefix("apple")
        #expect(enteredStr.contains("apple"))

        let youTypedStr = AppStrings.ReflexBlitz.typingYouTypedPrefix("aple")
        #expect(youTypedStr.contains("aple"))

        let placeholder = AppStrings.ReflexBlitz.typingPlaceholderText
        #expect(!placeholder.isEmpty)
    }
}
