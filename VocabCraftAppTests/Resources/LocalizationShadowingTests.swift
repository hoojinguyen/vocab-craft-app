import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Studio Localization & Parity Tests")
struct LocalizationShadowingTests {
    private struct ExpectedString {
        let english: String
        let vietnamese: String
    }

    private let expectedStrings: [String: ExpectedString] = [
        "app.shadowing.hub.title": ExpectedString(
            english: "Shadowing Studio",
            vietnamese: "Shadowing Studio"
        ),
        "app.shadowing.hub.subtitle": ExpectedString(
            english: "Master spoken reflexes with real videos",
            vietnamese: "Luyện phản xạ nói qua video ngắn"
        ),
        "app.shadowing.hub.daily_challenge": ExpectedString(
            english: "TODAY'S 15-MIN CHALLENGE",
            vietnamese: "BÀI HỌC HÔM NAY (15 PHÚT)"
        ),
        "app.shadowing.hub.filter_all": ExpectedString(
            english: "All Levels",
            vietnamese: "Tất cả"
        ),
        "app.shadowing.hub.streak_format": ExpectedString(
            english: "%lld-day streak",
            vietnamese: "%lld ngày streak"
        ),
        "app.shadowing.hub.start_practice": ExpectedString(
            english: "Start Practice ▶",
            vietnamese: "Bắt đầu luyện ▶"
        ),
        "app.shadowing.hub.see_all": ExpectedString(
            english: "See All (%lld)",
            vietnamese: "Xem tất cả (%lld)"
        ),
        "app.shadowing.hub.not_practiced": ExpectedString(
            english: "Not practiced",
            vietnamese: "Chưa luyện"
        ),
        "app.shadowing.hub.practiced_format": ExpectedString(
            english: "Practiced (%lld%%)",
            vietnamese: "Đã học (%lld%%)"
        ),
        "app.shadowing.hub.meta_format": ExpectedString(
            english: "%lld sentences • %@",
            vietnamese: "%lld câu • %@"
        ),
        "app.shadowing.round1.title": ExpectedString(
            english: "Round 1: Watch & Absorb",
            vietnamese: "Vòng 1: Nghe & Cảm nhận"
        ),
        "app.shadowing.round1.instruction": ExpectedString(
            english: "Listen to authentic rhythm and flow",
            vietnamese: "Lắng nghe ngữ điệu và dòng chảy tự nhiên"
        ),
        "app.shadowing.round1.skip_to_round2": ExpectedString(
            english: "Skip to Speed Shadowing",
            vietnamese: "Chuyển sang Shadow đuổi"
        ),
        "app.shadowing.round2.title": ExpectedString(
            english: "Round 2: Speed Shadowing",
            vietnamese: "Vòng 2: Shadow đuổi tốc độ"
        ),
        "app.shadowing.round2.pacer_hint": ExpectedString(
            english: "Shadow 1-2 words behind speaker",
            vietnamese: "Nói đuổi chậm hơn video 1-2 từ"
        ),
        "app.shadowing.round2.headphone_advisory": ExpectedString(
            english: "Connect headphones for best recording",
            vietnamese: "Đeo tai nghe để trải nghiệm tốt nhất"
        ),
        "app.shadowing.round2.headphone_connected": ExpectedString(
            english: "Headphones Connected",
            vietnamese: "Đã cắm tai nghe"
        ),
        "app.shadowing.round2.listening_hint": ExpectedString(
            english: "Listening to your voice...",
            vietnamese: "Đang bắt giọng nói..."
        ),
        "app.shadowing.round2.upcoming_sentence": ExpectedString(
            english: "Next sentence:",
            vietnamese: "Câu tiếp theo:"
        ),
        "app.shadowing.round2.rewind_5s": ExpectedString(
            english: "Rewind 5s",
            vietnamese: "Lùi 5s"
        ),
        "app.shadowing.round2.speed": ExpectedString(
            english: "Speed: %@",
            vietnamese: "Tốc độ: %@"
        ),
        "app.shadowing.round2.pause": ExpectedString(
            english: "Pause",
            vietnamese: "Tạm dừng"
        ),
        "app.shadowing.round2.resume": ExpectedString(
            english: "Resume",
            vietnamese: "Tiếp tục"
        ),
        "app.shadowing.round3.title": ExpectedString(
            english: "Round 3: Deep Drill & Score",
            vietnamese: "Vòng 3: Khoan sâu từng câu"
        ),
        "app.shadowing.summary.title": ExpectedString(
            english: "Session Completed!",
            vietnamese: "Hoàn thành buổi luyện!"
        ),
        "app.shadowing.summary.score_format": ExpectedString(
            english: "Mastery Score: %lld%%",
            vietnamese: "Điểm phản xạ: %lld%%"
        ),
        "app.shadowing.summary.round2_audio": ExpectedString(
            english: "Listen to Speed Shadowing",
            vietnamese: "Nghe lại bản thu Shadow đuổi"
        ),
        "app.shadowing.summary.saved_words": ExpectedString(
            english: "Saved Vocabulary (%lld)",
            vietnamese: "Từ vựng đã lưu (%lld)"
        ),
        "app.shadowing.summary.finish": ExpectedString(
            english: "Finish Session",
            vietnamese: "Hoàn thành"
        ),
        "app.shadowing.summary.retry_weak": ExpectedString(
            english: "Review Weak Sentences",
            vietnamese: "Luyện lại câu chưa đạt"
        ),
        "app.shadowing.error.playback_failed": ExpectedString(
            english: "Unable to load video. Please try again.",
            vietnamese: "Không thể tải video. Vui lòng thử lại."
        )
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

    private func extractFormatSpecifiers(from string: String) -> [String] {
        let pattern = "%(?:\\d+\\$)?[#0\\- +']?(?:\\d+)?(?:\\.\\d+)?[hlLjztL]*[diouxXeEfgGaAcsp@%]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsString = string as NSString
        let matches = regex.matches(in: string, range: NSRange(location: 0, length: nsString.length))
        return matches.map { nsString.substring(with: $0.range) }
    }

    @Test("Verify all 31 Shadowing Studio keys exist in catalog with manual extraction")
    func testAllRequiredKeysExist() throws {
        let catalog = try loadCatalogStrings()
        #expect(expectedStrings.count == 31, "Must test exactly 31 shadowing keys")

        for key in expectedStrings.keys {
            let entry = try #require(catalog[key], "Missing required key in catalog: \(key)")
            let extractionState = entry["extractionState"] as? String
            #expect(extractionState == "manual", "Key \(key) must have extractionState: manual")
        }
    }

    @Test("Verify 100% bilingual parity (EN & VI) for all 31 Shadowing Studio keys")
    func testBilingualCompletenessAndValues() throws {
        let catalog = try loadCatalogStrings()

        for (key, expected) in expectedStrings {
            let entry = try #require(catalog[key], "Missing key: \(key)")
            let localizations = try #require(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) missing localizations dictionary"
            )

            // EN verification
            let enLoc = try #require(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try #require(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(!enVal.isEmpty, "Key \(key) EN translation must not be empty")
            #expect(enVal == expected.english, "Key \(key) EN mismatch: expected '\(expected.english)', got '\(enVal)'")

            // VI verification
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(!viVal.isEmpty, "Key \(key) VI translation must not be empty")
            #expect(viVal == expected.vietnamese, "Key \(key) VI mismatch: expected '\(expected.vietnamese)', got '\(viVal)'")
        }
    }

    @Test("Verify format specifiers parity between EN and VI")
    func testFormatSpecifiersParity() throws {
        let catalog = try loadCatalogStrings()

        for (key, _) in expectedStrings {
            guard let entry = catalog[key],
                  let localizations = entry["localizations"] as? [String: [String: Any]],
                  let enVal = (localizations["en"]?["stringUnit"] as? [String: Any])?["value"] as? String,
                  let viVal = (localizations["vi"]?["stringUnit"] as? [String: Any])?["value"] as? String else {
                continue
            }

            let enSpecifiers = extractFormatSpecifiers(from: enVal)
            let viSpecifiers = extractFormatSpecifiers(from: viVal)

            #expect(
                enSpecifiers == viSpecifiers,
                "Format specifier mismatch for \(key): EN \(enSpecifiers) vs VI \(viSpecifiers)"
            )
        }
    }

    @Test("Verify evaluation of formatted strings")
    func testFormatSpecifierEvaluation() throws {
        let catalog = try loadCatalogStrings()

        func resolve(_ key: String, lang: String) throws -> String {
            let entry = try #require(catalog[key], "Missing key \(key)")
            let localizations = try #require(entry["localizations"] as? [String: [String: Any]])
            let unit = try #require(localizations[lang]?["stringUnit"] as? [String: Any])
            return try #require(unit["value"] as? String)
        }

        // Streak format
        let streakKey = "app.shadowing.hub.streak_format"
        #expect(String(format: try resolve(streakKey, lang: "en"), 7) == "7-day streak")
        #expect(String(format: try resolve(streakKey, lang: "vi"), 7) == "7 ngày streak")

        // See all format
        let seeAllKey = "app.shadowing.hub.see_all"
        #expect(String(format: try resolve(seeAllKey, lang: "en"), 12) == "See All (12)")
        #expect(String(format: try resolve(seeAllKey, lang: "vi"), 12) == "Xem tất cả (12)")

        // Practiced format
        let practicedKey = "app.shadowing.hub.practiced_format"
        #expect(String(format: try resolve(practicedKey, lang: "en"), 85) == "Practiced (85%)")
        #expect(String(format: try resolve(practicedKey, lang: "vi"), 85) == "Đã học (85%)")

        // Meta format
        let metaKey = "app.shadowing.hub.meta_format"
        #expect(String(format: try resolve(metaKey, lang: "en"), 10, "B1") == "10 sentences • B1")
        #expect(String(format: try resolve(metaKey, lang: "vi"), 10, "B1") == "10 câu • B1")

        // Speed format
        let speedKey = "app.shadowing.round2.speed"
        #expect(String(format: try resolve(speedKey, lang: "en"), "1.0x") == "Speed: 1.0x")
        #expect(String(format: try resolve(speedKey, lang: "vi"), "1.0x") == "Tốc độ: 1.0x")

        // Summary score format
        let scoreKey = "app.shadowing.summary.score_format"
        #expect(String(format: try resolve(scoreKey, lang: "en"), 92) == "Mastery Score: 92%")
        #expect(String(format: try resolve(scoreKey, lang: "vi"), 92) == "Điểm phản xạ: 92%")

        // Summary saved words format
        let savedKey = "app.shadowing.summary.saved_words"
        #expect(String(format: try resolve(savedKey, lang: "en"), 4) == "Saved Vocabulary (4)")
        #expect(String(format: try resolve(savedKey, lang: "vi"), 4) == "Từ vựng đã lưu (4)")
    }
}
