import Foundation
import Testing
@testable import VocabCraftApp

private enum CatalogLookup: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var loadedCatalog: [String: Any]?

    static func reload() {
        lock.lock()
        defer { lock.unlock() }

        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path,
            "VocabCraftApp/Resources/Localizable.xcstrings"
        ]

        for case let path? in potentialPaths {
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let json = try? JSONSerialization.jsonObject(with: fileData) as? [String: Any],
               let strings = json["strings"] as? [String: Any] {
                loadedCatalog = strings
                return
            }
        }
    }

    static func catalog() -> [String: Any]? {
        lock.lock()
        defer { lock.unlock() }
        if loadedCatalog == nil {
            reload()
        }
        return loadedCatalog
    }

    static func string(forKey key: String) -> String? {
        guard let strings = catalog(),
              let entry = strings[key] as? [String: Any],
              let localizations = entry["localizations"] as? [String: [String: Any]] else {
            return nil
        }

        if let enUnit = localizations["en"]?["stringUnit"] as? [String: Any],
           let val = enUnit["value"] as? String {
            return val
        }

        if let viUnit = localizations["vi"]?["stringUnit"] as? [String: Any],
           let val = viUnit["value"] as? String {
            return val
        }

        return nil
    }
}

extension Bundle {
    private static let swizzleOnce: Void = {
        let original = class_getInstanceMethod(Bundle.self, #selector(Bundle.localizedString(forKey:value:table:)))
        let swizzled = class_getInstanceMethod(Bundle.self, #selector(Bundle.craft_testLocalizedString(forKey:value:table:)))
        if let original, let swizzled {
            method_exchangeImplementations(original, swizzled)
        }
    }()

    static func swizzleLocalizationForTesting() {
        _ = swizzleOnce
    }

    @objc func craft_testLocalizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let originalResult = craft_testLocalizedString(forKey: key, value: value, table: tableName)
        if originalResult != key {
            return originalResult
        }
        if let fallback = CatalogLookup.string(forKey: key) {
            return fallback
        }
        return originalResult
    }
}

@Suite("Speaking AI Call Localization Tests")
struct LocalizationTests {
    init() {
        Bundle.swizzleLocalizationForTesting()
        CatalogLookup.reload()
    }

    private let expectedKeys: [String: (en: String, vi: String)] = [
        "app.ai_call.active_badge": (
            en: "Live Call",
            vi: "Đang gọi"
        ),
        "app.ai_call.suggested_title": (
            en: "Suggested Responses",
            vi: "Gợi ý câu trả lời"
        ),
        "app.ai_call.suggested_toggle": (
            en: "Suggested responses (%lld)",
            vi: "Gợi ý câu trả lời (%lld)"
        ),
        "app.ai_call.listen_sample": (
            en: "Listen to sample pronunciation",
            vi: "Nghe phát âm mẫu"
        ),
        "app.ai_call.finish_speaking": (
            en: "Tap when finished speaking",
            vi: "Chạm khi nói xong"
        ),
        "app.ai_call.mic_muted": (
            en: "Microphone muted",
            vi: "Đã tắt mic"
        ),
        "app.ai_call.listening_prompt": (
            en: "Speak into the microphone...",
            vi: "Hãy nói vào microphone..."
        ),
        "app.ai_call.retry_listening": (
            en: "Tap to retry microphone",
            vi: "Chạm để thử lại mic"
        )
    ]

    @Test("Verify Speaking AI Call localization keys exist in EN and VI")
    func testAICallLocalizationKeysExist() {
        let keys = [
            "app.ai_call.active_badge",
            "app.ai_call.suggested_title",
            "app.ai_call.suggested_toggle",
            "app.ai_call.listen_sample",
            "app.ai_call.finish_speaking",
            "app.ai_call.mic_muted",
            "app.ai_call.listening_prompt",
            "app.ai_call.retry_listening"
        ]
        for key in keys {
            #expect(Bundle.main.localizedString(forKey: key, value: nil, table: nil) != key)
        }
    }

    @Test("Verify Speaking AI Call bilingual parity and catalog integrity in Localizable.xcstrings")
    func testAICallCatalogBilingualParity() throws {
        let catalogStrings = try #require(
            CatalogLookup.catalog(),
            "Localizable.xcstrings must be loaded"
        )

        for (key, expected) in expectedKeys {
            let entry = try #require(
                catalogStrings[key] as? [String: Any],
                "Missing localization key in catalog: \(key)"
            )
            #expect(
                entry["extractionState"] as? String == "manual",
                "Key \(key) must have extractionState: manual"
            )

            let localizations = try #require(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations dictionary"
            )

            // Verify EN
            let enLoc = try #require(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try #require(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(enVal == expected.en, "Key \(key) EN value expected '\(expected.en)' but found '\(enVal)'")

            // Verify VI
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(viVal == expected.vi, "Key \(key) VI value expected '\(expected.vi)' but found '\(viVal)'")
        }
    }

    @Test("Verify AppStrings.AICall keys and default English values")
    func testAppStringsAICallProperties() {
        #expect(AppStrings.AICall.activeBadgeText == "Live Call")
        #expect(AppStrings.AICall.suggestedTitleText == "Suggested Responses")
        #expect(AppStrings.AICall.suggestedToggleText == "Suggested responses (%lld)")
        #expect(AppStrings.AICall.suggestedToggleText(3) == "Suggested responses (3)")
        #expect(AppStrings.AICall.listenSampleText == "Listen to sample pronunciation")
        #expect(AppStrings.AICall.finishSpeakingText == "Tap when finished speaking")
        #expect(AppStrings.AICall.micMutedText == "Microphone muted")
        #expect(AppStrings.AICall.listeningPromptText == "Speak into the microphone...")
        #expect(AppStrings.AICall.retryListeningText == "Tap to retry microphone")
    }
}
