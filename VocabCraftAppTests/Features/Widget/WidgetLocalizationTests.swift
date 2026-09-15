import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Widget Localization Tests")
struct WidgetLocalizationTests {
    @Test("Widget placeholder keys exist in catalog with EN and VI translations")
    func widgetPlaceholderKeysHaveFullParity() throws {
        let keys = [
            "app.widget.placeholder.lemma",
            "app.widget.placeholder.ipa",
            "app.widget.placeholder.definition",
            "app.widget.placeholder.example"
        ]
        for key in keys {
            let englishValue = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "en"))
            let vietnameseValue = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "vi"))
            #expect(!englishValue.isEmpty && englishValue != key)
            #expect(!vietnameseValue.isEmpty && vietnameseValue != key)
        }
    }
}
