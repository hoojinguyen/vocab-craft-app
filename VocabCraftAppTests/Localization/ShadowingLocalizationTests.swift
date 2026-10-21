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

    private static let catalogStrings: [String: [String: Any]]? = {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path,
            "VocabCraftApp/Resources/Localizable.xcstrings"
        ]

        for case let path? in potentialPaths {
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let json = try? JSONSerialization.jsonObject(with: fileData) as? [String: Any],
               let strings = json["strings"] as? [String: [String: Any]] {
                return strings
            }
        }
        return nil
    }()

    static func lookupCatalog(key: String, language: String) -> String? {
        guard let entry = catalogStrings?[key],
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
        let bundle = Bundle(for: BundleToken.self)
        for key in requiredKeys {
            let enString = String(localized: String.LocalizationValue(key), bundle: bundle, locale: Locale(identifier: "en"))
            let viString = String(localized: String.LocalizationValue(key), bundle: bundle, locale: Locale(identifier: "vi"))

            #expect(!enString.isEmpty, "Missing EN translation for \(key)")
            #expect(!viString.isEmpty, "Missing VI translation for \(key)")
            #expect(enString != key, "Key \(key) was not localized in EN")
            #expect(viString != key, "Key \(key) was not localized in VI")
        }
    }
}

private final class BundleToken {}

private extension String {
    init(localized value: String.LocalizationValue, bundle: Bundle, locale: Locale) {
        let mirror = Mirror(reflecting: value)
        let key = mirror.children.first(where: { $0.label == "key" })?.value as? String ?? ""
        let lang = locale.language.languageCode?.identifier ?? "en"
        if let translated = ShadowingLocalizationTests.lookupCatalog(key: key, language: lang) {
            self = translated
        } else {
            self = key
        }
    }
}
