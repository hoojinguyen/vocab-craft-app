import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("Audio Localization Tests")
struct AudioLocalizationTests {
    private let expectedCatalogKeys: [String: (en: String, vi: String)] = [
        "app.audio.voice_quality_premium": (
            en: "Studio Quality Voice",
            vi: "Chất lượng giọng nói chuẩn Studio"
        ),
        "app.audio.voice_quality_enhanced": (
            en: "Enhanced Natural Voice",
            vi: "Giọng nói tự nhiên nâng cao"
        ),
        "app.audio.voice_quality_standard": (
            en: "Standard Voice",
            vi: "Giọng nói tiêu chuẩn"
        ),
        "app.audio.fallback_notice": (
            en: "Switched to offline voice",
            vi: "Đang chuyển sang giọng đọc ngoại tuyến"
        )
    ]

    private func extractKey(from localizedKey: LocalizedStringKey) -> String {
        let mirror = Mirror(reflecting: localizedKey)
        return mirror.children.first(where: { $0.label == "key" })?.value as? String ?? ""
    }

    @Test("Verify audio voice quality and fallback string keys exist in English and Vietnamese")
    func test_audioLocalizationKeys_existInEnglishAndVietnamese() throws {
        guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings") ??
                Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings") ??
                [
                    URL(fileURLWithPath: "VocabCraftApp/Resources/Localizable.xcstrings"),
                    URL(fileURLWithPath: #filePath)
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .deletingLastPathComponent()
                        .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
                ].first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            Issue.record("Localizable.xcstrings not found")
            return
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = json?["strings"] as? [String: Any]

        let requiredKeys = [
            "app.audio.voice_quality_premium",
            "app.audio.voice_quality_enhanced",
            "app.audio.voice_quality_standard",
            "app.audio.fallback_notice"
        ]

        for key in requiredKeys {
            let entry = strings?[key] as? [String: Any]
            #expect(entry != nil, "Missing key: \(key)")
            let localizations = entry?["localizations"] as? [String: Any]
            let enTranslation = localizations?["en"] as? [String: Any]
            let viTranslation = localizations?["vi"] as? [String: Any]
            #expect(enTranslation != nil, "Missing EN translation for \(key)")
            #expect(viTranslation != nil, "Missing VI translation for \(key)")

            if let expected = expectedCatalogKeys[key] {
                let enUnit = enTranslation?["stringUnit"] as? [String: Any]
                let viUnit = viTranslation?["stringUnit"] as? [String: Any]
                #expect(enUnit?["value"] as? String == expected.en, "EN translation mismatch for \(key)")
                #expect(viUnit?["value"] as? String == expected.vi, "VI translation mismatch for \(key)")
                #expect(enUnit?["state"] as? String == "translated", "EN state must be translated for \(key)")
                #expect(viUnit?["state"] as? String == "translated", "VI state must be translated for \(key)")
            }
        }
    }

    @Test("Verify AppStrings.Audio LocalizedStringKey accessors")
    func test_appStringsAudio_localizedStringKeyAccessors() {
        #expect(extractKey(from: AppStrings.Audio.voiceQualityPremium) == "app.audio.voice_quality_premium")
        #expect(extractKey(from: AppStrings.Audio.voiceQualityEnhanced) == "app.audio.voice_quality_enhanced")
        #expect(extractKey(from: AppStrings.Audio.voiceQualityStandard) == "app.audio.voice_quality_standard")
        #expect(extractKey(from: AppStrings.Audio.fallbackNotice) == "app.audio.fallback_notice")
    }

    @Test("Verify AppStrings.Audio text accessors return default English values")
    func test_appStringsAudio_textAccessors() {
        #expect(AppStrings.Audio.voiceQualityPremiumText == "Studio Quality Voice")
        #expect(AppStrings.Audio.voiceQualityEnhancedText == "Enhanced Natural Voice")
        #expect(AppStrings.Audio.voiceQualityStandardText == "Standard Voice")
        #expect(AppStrings.Audio.fallbackNoticeText == "Switched to offline voice")
    }
}
