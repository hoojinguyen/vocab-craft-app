import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Localization Parity Tests")
struct ShadowingLocalizationTests {
    private let requiredKeys = [
        "app.shadowing.title",
        "app.shadowing.progress_format",
        "app.shadowing.speed",
        "app.shadowing.action.hear_native",
        "app.shadowing.action.hear_me",
        "app.shadowing.action.retry",
        "app.shadowing.action.next_sentence",
        "app.shadowing.srs.add_to_vault",
        "app.shadowing.srs.saved_success",
        "app.shadowing.celebration.title",
        "app.shadowing.celebration.message"
    ]

    private func loadCatalogStrings() throws -> [String: [String: Any]] {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path,
            "VocabCraftApp/Resources/Localizable.xcstrings"
        ]

        var data: Data?
        for case let path? in potentialPaths {
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                data = fileData
                break
            }
        }

        let fileData = try #require(data, "Localizable.xcstrings should be found")
        let json = try #require(
            try JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog should parse as JSON dictionary"
        )
        return try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )
    }

    private func lookupCatalog(in catalog: [String: [String: Any]], key: String, language: String) -> String? {
        guard let entry = catalog[key],
              let localizations = entry["localizations"] as? [String: [String: Any]],
              let langUnit = localizations[language],
              let stringUnit = langUnit["stringUnit"] as? [String: Any],
              let value = stringUnit["value"] as? String else {
            return nil
        }
        return value
    }

    @Test("Verifies all required Shadowing keys exist in Localizable.xcstrings with EN and VI values")
    func testLocalizationKeys() throws {
        let catalog = try loadCatalogStrings()
        _ = Bundle(for: BundleToken.self)

        for key in requiredKeys {
            let enString = lookupCatalog(in: catalog, key: key, language: "en") ?? key
            let viString = lookupCatalog(in: catalog, key: key, language: "vi") ?? key

            #expect(!enString.isEmpty, "Missing EN translation for \(key)")
            #expect(!viString.isEmpty, "Missing VI translation for \(key)")
            #expect(enString != key, "Key \(key) was not localized in EN")
            #expect(viString != key, "Key \(key) was not localized in VI")
        }
    }
}

private final class BundleToken {}
