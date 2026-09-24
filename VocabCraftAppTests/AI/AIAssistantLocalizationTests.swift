import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("AI Assistant Localization Tests")
struct AIAssistantLocalizationTests {
    private let expectedCatalogKeys: [String: (vi: String, en: String)] = [
        "app.ai_assistant.hub.title": (
            vi: "Trợ lý AI",
            en: "AI Assistant"
        ),
        "app.ai_assistant.hub.subtitle": (
            vi: "Làm chủ từ vựng chủ động qua đàm thoại nhập vai",
            en: "Master active speaking through interactive roleplay"
        ),
        "app.ai_assistant.hub.daily_mission_badge": (
            vi: "Tình huống đề xuất hôm nay",
            en: "Daily Recommended Scenario"
        ),
        "app.ai_assistant.hub.action_start_roleplay": (
            vi: "Bắt đầu nhập vai",
            en: "Start Roleplay"
        ),
        "app.ai_assistant.room.target_words_title": (
            vi: "Từ vựng mục tiêu",
            en: "Target Words"
        ),
        "app.ai_assistant.room.refine_button": (
            vi: "💡 Xem gợi ý diễn đạt tự nhiên",
            en: "💡 See natural phrasing"
        ),
        "app.ai_assistant.room.action_finish": (
            vi: "Kết thúc",
            en: "Finish"
        ),
        "app.ai_assistant.room.discard_title": (
            vi: "Rời khỏi buổi đàm thoại?",
            en: "Leave Roleplay?"
        ),
        "app.ai_assistant.room.discard_message": (
            vi: "Tiến trình trò chuyện hiện tại sẽ không được lưu.",
            en: "Your current conversation progress will not be saved."
        ),
        "app.ai_assistant.room.fallback_reply": (
            vi: "Tôi hiểu rồi! Hãy tiếp tục nhé.",
            en: "I see! Please go on."
        ),
        "app.ai_assistant.room.input_placeholder": (
            vi: "Nhập tin nhắn...",
            en: "Type a message..."
        ),
        "app.ai_assistant.summary.congratulations": (
            vi: "Hoàn thành buổi đàm thoại!",
            en: "Roleplay Completed!"
        ),
        "app.ai_assistant.summary.fluency_score": (
            vi: "Điểm trôi chảy",
            en: "Fluency Score"
        ),
        "app.ai_assistant.summary.mastered_words": (
            vi: "Từ mục tiêu đã làm chủ",
            en: "Target Words Mastered"
        ),
        "app.ai_assistant.summary.takeaways_title": (
            vi: "Gợi ý diễn đạt nâng cao",
            en: "Refined Phrasing Takeaways"
        ),
        "app.ai_assistant.summary.action_done": (
            vi: "Quay về trang chính",
            en: "Back to Hub"
        ),
        "app.ai_assistant.scenario.cafe.title": (
            vi: "Gọi món tại quán cà phê",
            en: "Cafe Ordering"
        ),
        "app.ai_assistant.scenario.cafe.desc": (
            vi: "Luyện tập gọi đồ uống và đồ ăn nhẹ với nhân viên pha chế",
            en: "Practice ordering drinks and snacks with a barista"
        ),
        "app.ai_assistant.scenario.hotel.title": (
            vi: "Nhận phòng khách sạn",
            en: "Hotel Check-in"
        ),
        "app.ai_assistant.scenario.hotel.desc": (
            vi: "Hỏi về tiện nghi và làm thủ tục nhận phòng",
            en: "Inquire about amenities and check into your room"
        ),
        "app.ai_assistant.scenario.interview.title": (
            vi: "Phỏng vấn xin việc",
            en: "Job Interview"
        ),
        "app.ai_assistant.scenario.interview.desc": (
            vi: "Tự tin trả lời các câu hỏi tình huống hành vi thử thách",
            en: "Answer challenging behavioral questions with confidence"
        ),
        "app.ai_assistant.scenario.daily.title": (
            vi: "Luyện từ vựng hàng ngày",
            en: "Daily Vocabulary Practice"
        ),
        "app.ai_assistant.scenario.daily.desc": (
            vi: "Luyện tập các từ còn yếu trong cuộc trò chuyện tự nhiên",
            en: "Practice your weak words in a natural conversation"
        ),
        "app.ai_assistant.room.play_audio": (
            vi: "Phát âm thanh hội thoại",
            en: "Play dialogue audio"
        ),
        "app.ai_assistant.hub.configure_api_key": (
            vi: "Cấu hình khóa API",
            en: "Configure API Key"
        ),
        "app.ai_assistant.hub.api_key_sheet_title": (
            vi: "Thiết lập khóa API Gemini",
            en: "Gemini API Setup"
        ),
        "app.ai_assistant.hub.api_key_banner_desc": (
            vi: "Thêm khóa API Gemini để mở khóa các cuộc trò chuyện và nhận xét AI tự nhiên.",
            en: "Add your Gemini API key to unlock natural AI roleplay conversations and feedback."
        ),
        "app.ai_assistant.call.active_badge": (
            vi: "Cuộc gọi trực tiếp",
            en: "Live Call"
        ),
        "app.ai_assistant.call.state_idle": (
            vi: "Đang kết nối...",
            en: "Connecting..."
        ),
        "app.ai_assistant.call.state_speaking": (
            vi: "Đang nói...",
            en: "Speaking..."
        ),
        "app.ai_assistant.call.state_listening": (
            vi: "Đang nghe...",
            en: "Listening..."
        ),
        "app.ai_assistant.call.state_thinking": (
            vi: "Đang suy nghĩ...",
            en: "Thinking..."
        ),
        "app.ai_assistant.call.state_ended": (
            vi: "Cuộc gọi đã kết thúc",
            en: "Call Ended"
        ),
        "app.ai_assistant.call.toggle_captions": (
            vi: "Bật/tắt phụ đề",
            en: "Toggle captions"
        ),
        "app.ai_assistant.call.mute_microphone": (
            vi: "Tắt mic",
            en: "Mute microphone"
        ),
        "app.ai_assistant.call.unmute_microphone": (
            vi: "Bật mic",
            en: "Unmute microphone"
        ),
        "app.ai_assistant.call.end_call": (
            vi: "Kết thúc cuộc gọi",
            en: "End call"
        )
    ]

    @Test("AppStrings contains AI Assistant keys")
    func testAppStringsAIAssistantKeys() {
        let title: LocalizedStringKey? = AppStrings.AIAssistant.hubTitle
        let start: LocalizedStringKey? = AppStrings.AIAssistant.actionStartRoleplay
        let finish: LocalizedStringKey? = AppStrings.AIAssistant.actionFinishSession
        #expect(title != nil)
        #expect(start != nil)
        #expect(finish != nil)
        // Verify remaining LocalizedStringKey accessors are accessible
        let keys: [LocalizedStringKey?] = [
            AppStrings.AIAssistant.hubSubtitle,
            AppStrings.AIAssistant.dailyMissionBadge,
            AppStrings.AIAssistant.targetWordsTitle,
            AppStrings.AIAssistant.refineSuggestionButton,
            AppStrings.AIAssistant.discardConfirmTitle,
            AppStrings.AIAssistant.discardConfirmMessage,
            AppStrings.AIAssistant.summaryCongratulations,
            AppStrings.AIAssistant.summaryFluencyScore,
            AppStrings.AIAssistant.summaryMasteredWords,
            AppStrings.AIAssistant.summaryTakeawaysTitle,
            AppStrings.AIAssistant.actionDone,
            AppStrings.AIAssistant.fallbackReply,
            AppStrings.AIAssistant.inputPlaceholder,
            AppStrings.AIAssistant.audioPlayButton,
            AppStrings.AIAssistant.configureApiKey,
            AppStrings.AIAssistant.apiKeySheetTitle,
            AppStrings.AIAssistant.apiKeyBannerDesc,
            AppStrings.AIAssistant.callActiveBadge,
            AppStrings.AIAssistant.stateIdle,
            AppStrings.AIAssistant.stateSpeaking,
            AppStrings.AIAssistant.stateListening,
            AppStrings.AIAssistant.stateThinking,
            AppStrings.AIAssistant.stateEnded,
            AppStrings.AIAssistant.toggleCaptions,
            AppStrings.AIAssistant.muteMicrophone,
            AppStrings.AIAssistant.unmuteMicrophone,
            AppStrings.AIAssistant.endCall
        ]
        for key in keys {
            #expect(key != nil)
        }
    }

    @Test("AppStrings AI Assistant text accessors return English defaults")
    func testAppStringsAIAssistantTextAccessors() {
        #expect(AppStrings.AIAssistant.hubTitleText == "AI Assistant")
        #expect(AppStrings.AIAssistant.hubSubtitleText == "Master active speaking through interactive roleplay")
        #expect(AppStrings.AIAssistant.dailyMissionBadgeText == "Daily Recommended Scenario")
        #expect(AppStrings.AIAssistant.actionStartRoleplayText == "Start Roleplay")
        #expect(AppStrings.AIAssistant.targetWordsTitleText == "Target Words")
        #expect(AppStrings.AIAssistant.refineSuggestionButtonText == "💡 See natural phrasing")
        #expect(AppStrings.AIAssistant.actionFinishSessionText == "Finish")
        #expect(AppStrings.AIAssistant.discardConfirmTitleText == "Leave Roleplay?")
        #expect(AppStrings.AIAssistant.discardConfirmMessageText == "Your current conversation progress will not be saved.")
        #expect(AppStrings.AIAssistant.fallbackReplyText == "I see! Please go on.")
        #expect(AppStrings.AIAssistant.inputPlaceholderText == "Type a message...")
        #expect(AppStrings.AIAssistant.callActiveBadgeText == "Live Call")
        #expect(AppStrings.AIAssistant.stateIdleText == "Connecting...")
        #expect(AppStrings.AIAssistant.stateSpeakingText == "Speaking...")
        #expect(AppStrings.AIAssistant.stateListeningText == "Listening...")
        #expect(AppStrings.AIAssistant.stateThinkingText == "Thinking...")
        #expect(AppStrings.AIAssistant.stateEndedText == "Call Ended")
        #expect(AppStrings.AIAssistant.toggleCaptionsText == "Toggle captions")
        #expect(AppStrings.AIAssistant.muteMicrophoneText == "Mute microphone")
        #expect(AppStrings.AIAssistant.unmuteMicrophoneText == "Unmute microphone")
        #expect(AppStrings.AIAssistant.endCallText == "End call")
        #expect(AppStrings.AIAssistant.summaryCongratulationsText == "Roleplay Completed!")
        #expect(AppStrings.AIAssistant.summaryFluencyScoreText == "Fluency Score")
        #expect(AppStrings.AIAssistant.summaryMasteredWordsText == "Target Words Mastered")
        #expect(AppStrings.AIAssistant.summaryTakeawaysTitleText == "Refined Phrasing Takeaways")
        #expect(AppStrings.AIAssistant.actionDoneText == "Back to Hub")
        #expect(AppStrings.AIAssistant.audioPlayButtonText == "Play dialogue audio")
        #expect(AppStrings.AIAssistant.configureApiKeyText == "Configure API Key")
        #expect(AppStrings.AIAssistant.apiKeySheetTitleText == "Gemini API Setup")
        #expect(AppStrings.AIAssistant.apiKeyBannerDescText == "Add your Gemini API key to unlock natural AI roleplay conversations and feedback.")
    }

    @Test("AppStrings Settings AI configuration keys exist")
    func testAppStringsSettingsAIKeys() {
        let keys: [LocalizedStringKey?] = [
            AppStrings.Settings.sectionAI,
            AppStrings.Settings.aiGeminiKeyTitle,
            AppStrings.Settings.aiGeminiKeyPlaceholder,
            AppStrings.Settings.aiGeminiStatusConnected,
            AppStrings.Settings.aiGeminiStatusMock,
            AppStrings.Settings.aiGeminiActive,
            AppStrings.Settings.aiGeminiMock,
            AppStrings.Settings.aiGeminiHelpText,
            AppStrings.Settings.aiShowKey,
            AppStrings.Settings.aiHideKey,
            AppStrings.Settings.aiClearKey
        ]
        for key in keys {
            #expect(key != nil)
        }
    }

    @Test("AppStrings Settings AI text accessors return English defaults")
    func testAppStringsSettingsAITextAccessors() {
        #expect(AppStrings.Settings.sectionAIText == "AI CONFIGURATION")
        #expect(AppStrings.Settings.aiGeminiKeyTitleText == "Gemini API Key")
        #expect(AppStrings.Settings.aiGeminiKeyPlaceholderText == "Enter Gemini API Key...")
        #expect(AppStrings.Settings.aiGeminiStatusConnectedText == "Active (Gemini 1.5 Flash)")
        #expect(AppStrings.Settings.aiGeminiStatusMockText == "Mock Mode (Demo)")
        #expect(AppStrings.Settings.aiGeminiActiveText == "Active")
        #expect(AppStrings.Settings.aiGeminiMockText == "Mock Mode")
        #expect(AppStrings.Settings.aiGeminiHelpTextString == "Get a free Gemini API key at Google AI Studio to unlock natural roleplay dialogues.")
        #expect(AppStrings.Settings.aiShowKeyText == "Show API Key")
        #expect(AppStrings.Settings.aiHideKeyText == "Hide API Key")
        #expect(AppStrings.Settings.aiClearKeyText == "Clear API Key")
    }

    @Test("Localizable.xcstrings catalog integrity for AI Assistant keys")
    func testLocalizableCatalogIntegrity() throws {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #file)
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

        let fileData = try #require(data, "Localizable.xcstrings must be found")
        let json = try #require(
            try JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog should parse as JSON dictionary"
        )
        let strings = try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' dictionary"
        )

        for (key, expected) in expectedCatalogKeys {
            let entry = try #require(strings[key], "Missing key in catalog: \(key)")
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
            #expect(enVal == expected.en, "Key \(key) EN value mismatch: expected '\(expected.en)' but got '\(enVal)'")

            // Verify VI
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(viVal == expected.vi, "Key \(key) VI value mismatch: expected '\(expected.vi)' but got '\(viVal)'")
        }
    }

    @Test("Verify new AI configuration and audio strings exist in catalog")
    func testNewAIConfigurationAndAudioStringsExistInCatalog() throws {
        let potentialUrls: [URL?] = [
            Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings"),
            Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings"),
            URL(fileURLWithPath: "VocabCraftApp/Resources/Localizable.xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
        ]
        guard let catalogUrl = potentialUrls.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            Issue.record("Localizable.xcstrings not found in module bundle")
            return
        }
        let data = try Data(contentsOf: catalogUrl)
        let json = try JSONDecoder().decode(StringCatalogDTO.self, from: data)

        let requiredKeys = [
            "app.settings.section.ai",
            "app.settings.ai.gemini_key_title",
            "app.settings.ai.gemini_key_placeholder",
            "app.settings.ai.gemini_status_connected",
            "app.settings.ai.gemini_status_mock",
            "app.settings.ai.gemini_active",
            "app.settings.ai.gemini_mock",
            "app.settings.ai.gemini_help_text",
            "app.settings.ai.show_key",
            "app.settings.ai.hide_key",
            "app.settings.ai.clear_key",
            "app.ai_assistant.room.play_audio",
            "app.ai_assistant.hub.configure_api_key",
            "app.ai_assistant.hub.api_key_sheet_title",
            "app.ai_assistant.hub.api_key_banner_desc"
        ]

        for key in requiredKeys {
            #expect(json.strings[key] != nil, "Missing key: \(key)")
            #expect(json.strings[key]?.localizations["en"] != nil, "Missing 'en' for \(key)")
            #expect(json.strings[key]?.localizations["vi"] != nil, "Missing 'vi' for \(key)")
        }
    }
}

struct StringCatalogDTO: Decodable {
    let strings: [String: StringEntryDTO]

    struct StringEntryDTO: Decodable {
        let extractionState: String?
        let localizations: [String: LocalizationDTO]
    }

    struct LocalizationDTO: Decodable {
        let stringUnit: StringUnitDTO?
    }

    struct StringUnitDTO: Decodable {
        let state: String
        let value: String
    }
}
