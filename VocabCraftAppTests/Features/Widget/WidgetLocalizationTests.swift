import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Widget Localization Tests")
struct WidgetLocalizationTests {
    private func loadCatalogStrings() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(root["strings"] as? [String: Any])
    }

    @Test("Widget keys exist in catalog with translated EN and VI values")
    func widgetKeysHaveFullParity() throws {
        let strings = try loadCatalogStrings()
        let keys = [
            "app.widget.description",
            "app.widget.badge.new",
            "app.widget.badge.review",
            "app.widget.action.reveal",
            "app.widget.action.remembered",
            "app.widget.action.forgot",
            "app.widget.hidden_meaning",
            "app.widget.due_count_format",
            "app.widget.empty.title",
            "app.widget.intent.reveal.title",
            "app.widget.intent.reveal.description",
            "app.widget.intent.grade.title",
            "app.widget.intent.grade.description",
            "app.widget.intent.param.word",
            "app.widget.intent.param.remembered",
            "app.widget.intent.error.store_unavailable",
            "app.widget.pos.noun",
            "app.widget.pos.verb",
            "app.widget.pos.adjective",
            "app.widget.pos.adverb",
            "app.widget.pos.pronoun",
            "app.widget.pos.preposition",
            "app.widget.pos.conjunction",
            "app.widget.pos.determiner",
            "app.widget.practiced_today_format",
            "app.widget.progress_format",
            "app.widget.empty.subtitle",
            "app.widget.accessibility.blank"
        ]
        for key in keys {
            let entry = try #require(strings[key] as? [String: Any], "Missing key \(key)")
            let localizations = try #require(entry["localizations"] as? [String: [String: Any]], "No localizations for \(key)")
            for language in ["en", "vi"] {
                let unit = localizations[language]?["stringUnit"] as? [String: Any]
                let value = unit?["value"] as? String ?? ""
                #expect(!value.isEmpty, "\(key) has no \(language) value")
                #expect(unit?["state"] as? String == "translated", "\(key) \(language) is not translated")
            }
        }
    }

    @Test("Removed widget keys are gone from the catalog")
    func removedKeysAreGone() throws {
        let strings = try loadCatalogStrings()
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

    @Test("Vietnamese part-of-speech labels are not the English abbreviations")
    func vietnamesePartOfSpeechLabelsAreLocalized() throws {
        let strings = try loadCatalogStrings()
        for pos in ["noun", "verb", "adjective", "adverb", "pronoun", "preposition", "conjunction", "determiner"] {
            let entry = try #require(strings["app.widget.pos.\(pos)"] as? [String: Any])
            let localizations = try #require(entry["localizations"] as? [String: Any])
            func value(_ language: String) throws -> String {
                let unit = try #require((localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any])
                return try #require(unit["value"] as? String)
            }
            #expect(try value("vi") != value("en"), "vi label for \(pos) is still English")
        }
    }
}
