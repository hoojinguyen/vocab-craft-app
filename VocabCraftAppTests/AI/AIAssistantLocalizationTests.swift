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
            AppStrings.AIAssistant.fallbackReply
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
        #expect(AppStrings.AIAssistant.summaryCongratulationsText == "Roleplay Completed!")
        #expect(AppStrings.AIAssistant.summaryFluencyScoreText == "Fluency Score")
        #expect(AppStrings.AIAssistant.summaryMasteredWordsText == "Target Words Mastered")
        #expect(AppStrings.AIAssistant.summaryTakeawaysTitleText == "Refined Phrasing Takeaways")
        #expect(AppStrings.AIAssistant.actionDoneText == "Back to Hub")
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
}
