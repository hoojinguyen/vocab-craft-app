import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Widget Localization Tests")
struct WidgetLocalizationTests {
    @Test("Widget keys exist in catalog with EN and VI translations")
    func widgetKeysHaveFullParity() throws {
        let keys = [
            "app.widget.description",
            "app.widget.badge.new",
            "app.widget.badge.review",
            "app.widget.action.reveal",
            "app.widget.action.remembered",
            "app.widget.action.forgot",
            "app.widget.hidden_meaning",
            "app.widget.due_count_format",
            "app.widget.lock.open_to_review",
            "app.widget.empty.title",
            "app.widget.intent.reveal.title",
            "app.widget.intent.reveal.description",
            "app.widget.intent.grade.title",
            "app.widget.intent.grade.description",
            "app.widget.intent.param.word",
            "app.widget.intent.param.remembered"
        ]
        for key in keys {
            let englishValue = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "en"))
            let vietnameseValue = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "vi"))
            #expect(!englishValue.isEmpty && englishValue != key)
            #expect(!vietnameseValue.isEmpty && vietnameseValue != key)
        }
    }

    @Test("Removed widget keys are gone from the catalog")
    func removedKeysAreGone() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(root["strings"] as? [String: Any])
        let removed = [
            "app.widget.next",
            "app.widget.mastered",
            "app.widget.level_format",
            "app.widget.placeholder.lemma",
            "app.widget.placeholder.ipa",
            "app.widget.placeholder.definition",
            "app.widget.placeholder.example",
            "app.widget.intent.next_word.title",
            "app.widget.intent.next_word.description",
            "app.widget.intent.mark_learned.title",
            "app.widget.intent.mark_learned.description"
        ]
        for key in removed {
            #expect(strings[key] == nil, "Key \(key) should be removed")
        }
    }
}
