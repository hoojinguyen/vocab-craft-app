import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Guided Practice Localization Tests")
struct GuidedPracticeLocalizationTests {
    private func locateCatalogURL() -> URL? {
        if let bundlePath = Bundle.main.path(forResource: "Localizable", ofType: "xcstrings") {
            return URL(fileURLWithPath: bundlePath)
        }

        var currentDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<6 {
            let candidate = currentDir.appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            let directCandidate = currentDir.appendingPathComponent("Resources/Localizable.xcstrings")
            if FileManager.default.fileExists(atPath: directCandidate.path) {
                return directCandidate
            }
            currentDir = currentDir.deletingLastPathComponent()
        }
        return nil
    }

    private func extractFormatSpecifierTypes(from text: String) -> [String] {
        let pattern = "%(?:\\d+\\$)?[#0-9 .+-]*(?:hl|ll|[hljztL])?([diouxXeEfgGaAcpsS@%])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let conversionRange = match.range(at: 1)
            return nsText.substring(with: conversionRange)
        }
    }

    @Test("Verify all app.ai_assistant.guided keys have complete EN and VI parity")
    func verifyGuidedPracticeKeysIntegrity() throws {
        let catalogURL = try #require(locateCatalogURL(), "Localizable.xcstrings must be found")
        let fileData = try Data(contentsOf: catalogURL)
        let json = try #require(
            JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog must parse as JSON dictionary"
        )
        let strings = try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog must contain strings dictionary"
        )

        let guidedKeys = strings.filter { $0.key.hasPrefix("app.ai_assistant.guided.") }
        #expect(!guidedKeys.isEmpty, "There must be guided practice localization keys in the catalog")

        for (key, entry) in guidedKeys {
            // 1. extractionState must be manual
            let extractionState = entry["extractionState"] as? String
            #expect(extractionState == "manual", "Key \(key) extractionState must be manual, found: \(String(describing: extractionState))")

            // 2. localizations dictionary must exist
            let localizations = try #require(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations dictionary"
            )

            // 3. Must have EN localization with state: translated and non-empty value
            let enLoc = try #require(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try #require(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be translated")
            let enValue = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(!enValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Key \(key) EN value cannot be empty")

            // 4. Must have VI localization with state: translated and non-empty value
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be translated")
            let viValue = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(!viValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Key \(key) VI value cannot be empty")

            // 5. Format specifier count and types must match exactly between EN and VI
            let enSpecifiers = extractFormatSpecifierTypes(from: enValue)
            let viSpecifiers = extractFormatSpecifierTypes(from: viValue)
            #expect(
                enSpecifiers == viSpecifiers,
                "Key \(key) format specifier mismatch: EN \(enSpecifiers) vs VI \(viSpecifiers)"
            )
        }
    }

    @Test("Verify required strongly-typed keys exist in catalog")
    func verifyRequiredStronglyTypedKeys() throws {
        let catalogURL = try #require(locateCatalogURL(), "Localizable.xcstrings must be found")
        let fileData = try Data(contentsOf: catalogURL)
        let json = try #require(
            JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog must parse as JSON dictionary"
        )
        let strings = try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog must contain strings dictionary"
        )

        let requiredKeys = [
            "app.ai_assistant.guided.hub.title",
            "app.ai_assistant.guided.hub.subtitle",
            "app.ai_assistant.guided.hub.resume_title",
            "app.ai_assistant.guided.hub.resume_subtitle",
            "app.ai_assistant.guided.hub.resume_badge",
            "app.ai_assistant.guided.hub.recommended_badge",
            "app.ai_assistant.guided.hub.other_scenarios",
            "app.ai_assistant.guided.empty.needs_vocab_title",
            "app.ai_assistant.guided.empty.needs_vocab_desc",
            "app.ai_assistant.guided.empty.needs_vocab_cta",
            "app.ai_assistant.guided.empty.no_template_title",
            "app.ai_assistant.guided.empty.no_template_desc",
            "app.ai_assistant.guided.empty.no_template_cta",
            "app.ai_assistant.guided.error.title",
            "app.ai_assistant.guided.error.desc",
            "app.ai_assistant.guided.error.retry",
            "app.ai_assistant.guided.preparation.title",
            "app.ai_assistant.guided.preparation.your_role",
            "app.ai_assistant.guided.preparation.partner_role",
            "app.ai_assistant.guided.preparation.objectives_title",
            "app.ai_assistant.guided.preparation.mode_voice_title",
            "app.ai_assistant.guided.preparation.mode_voice_desc",
            "app.ai_assistant.guided.preparation.mode_text_title",
            "app.ai_assistant.guided.preparation.mode_text_desc",
            "app.ai_assistant.guided.preparation.review_words_first",
            "app.ai_assistant.guided.preparation.review_words_title",
            "app.ai_assistant.guided.preparation.review_words_done",
            "app.ai_assistant.guided.preparation.start_practice",
            "app.ai_assistant.guided.preparation.voice_permission_required",
            "app.ai_assistant.guided.preparation.llm_unavailable",
            "app.ai_assistant.guided.preparation.switch_to_text"
        ]

        for key in requiredKeys {
            #expect(strings[key] != nil, "Missing required key in catalog: \(key)")
        }
    }
}
