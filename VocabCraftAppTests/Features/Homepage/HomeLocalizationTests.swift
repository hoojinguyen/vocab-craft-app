import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Home Localization Tests")
struct HomeLocalizationTests {
    @Test("Verifies zen header accessors in AppStrings.Home")
    func testAppStringsHomeZenHeaderAccessors() {
        #expect(AppStrings.Home.titleText == "Home")
        #expect(AppStrings.Home.dailyGoalCount(completed: 8, goal: 10) == "8/10")
        #expect(AppStrings.Home.dailyGoalA11y(completed: 8, goal: 10) == "Daily Goal: 8 of 10 words completed")
        let _: LocalizedStringKey = AppStrings.Home.title
    }

    @Test("Verifies header greeting and streak accessors in AppStrings.Home")
    func testAppStringsHomeHeaderAccessors() {
        #expect(AppStrings.Home.greeting("Hooji") == "Hello, Hooji")
        let _: LocalizedStringKey = AppStrings.Home.greetingKey("Hooji")
        #expect(AppStrings.Home.dailyGoal(percent: 80) == "Daily Goal: 80%")
        #expect(AppStrings.Home.streak(days: 5) == "5 days")
    }

    @Test("Verifies section and checkpoint accessors in AppStrings.Home")
    func testAppStringsHomeSectionAccessors() {
        #expect(AppStrings.Home.unitTitle(number: 1, title: "Foundations") == "Unit 1: Foundations")
        #expect(AppStrings.Home.deckSummary(lessons: 4, words: 24) == "4 lessons • 24 words")
        #expect(AppStrings.Home.checkpointTitleText == "Unit Review Exam")
        #expect(AppStrings.Home.checkpointSubtitleText == "Comprehensive exam covering all unit words")
        let _: LocalizedStringKey = AppStrings.Home.checkpointTitle
        let _: LocalizedStringKey = AppStrings.Home.checkpointSubtitle
    }

    @Test("Verifies node metadata and objectives accessors in AppStrings.Home")
    func testAppStringsHomeNodeMetadataAndObjectives() {
        #expect(AppStrings.Home.wordsDuration(words: 10, minutes: 5) == "10 words • 5 min")
        #expect(AppStrings.Home.objective1(words: 15) == "Master 15 core vocabulary words")
        #expect(AppStrings.Home.objective2Text == "Practice 2-way Receptive & Productive recall")
        #expect(AppStrings.Home.objective3Text == "Achieve ≥ 80% accuracy to pass")
        #expect(AppStrings.Home.checkpointObjective1(words: 50) == "Review all 50 words in this unit")
        #expect(AppStrings.Home.checkpointObjective2Text == "Score ≥ 80% accuracy to unlock the next Unit")
        let _: LocalizedStringKey = AppStrings.Home.objective2
        let _: LocalizedStringKey = AppStrings.Home.objective3
        let _: LocalizedStringKey = AppStrings.Home.checkpointObjective2
    }

    @Test("Verifies CTA and hint accessors in AppStrings.Home")
    func testAppStringsHomeCallToActionsAndHints() {
        #expect(AppStrings.Home.ctaStartText == "Start Lesson")
        #expect(AppStrings.Home.ctaContinue(percent: 60) == "Continue (60%)")
        #expect(AppStrings.Home.ctaReview(xp: 25) == "Review Lesson (+25 XP)")
        #expect(AppStrings.Home.ctaCheckpointText == "Start Boss Exam")
        #expect(AppStrings.Home.lockedHintText == "Complete previous lessons to unlock")
        let _: LocalizedStringKey = AppStrings.Home.ctaStart
        let _: LocalizedStringKey = AppStrings.Home.ctaCheckpoint
        let _: LocalizedStringKey = AppStrings.Home.lockedHint
    }

    private func loadCatalogStrings() throws -> [String: [String: Any]] {
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path
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
            JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog should parse as JSON dictionary"
        )
        return try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )
    }

    @Test("Verifies catalog keys integrity for Home domain")
    func testHomeCatalogKeysIntegrity() throws {
        let strings = try loadCatalogStrings()

        let requiredHomeKeys = [
            "app.home.title",
            "app.home.header.greeting_format",
            "app.home.header.daily_goal_format",
            "app.home.header.daily_goal_count_format",
            "app.home.header.daily_goal_a11y_format",
            "app.home.header.streak_format",
            "app.home.section.unit_title_format",
            "app.home.section.deck_summary_format",
            "app.home.section.checkpoint_title",
            "app.home.section.checkpoint_subtitle",
            "app.home.node.words_duration_format",
            "app.home.node.objective_1_format",
            "app.home.node.objective_2",
            "app.home.node.objective_3",
            "app.home.node.checkpoint_objective_1_format",
            "app.home.node.checkpoint_objective_2",
            "app.home.node.cta_start",
            "app.home.node.cta_continue_format",
            "app.home.node.cta_review_format",
            "app.home.node.cta_checkpoint",
            "app.home.node.locked_hint"
        ]

        #expect(requiredHomeKeys.count == 21)

        for key in requiredHomeKeys {
            let entry = try #require(strings[key], "Missing required key: \(key)")
            #expect(
                entry["extractionState"] as? String == "manual",
                "Key \(key) must have extractionState: manual"
            )

            let localizations = try #require(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations"
            )

            // Verify EN
            let enLoc = try #require(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try #require(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(!enVal.isEmpty, "Key \(key) EN value cannot be empty")

            // Verify VI
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(!viVal.isEmpty, "Key \(key) VI value cannot be empty")
        }
    }

    @Test("Verifies AI Assistant accessors in AppStrings.AIAssistant")
    func testAppStringsAIAssistantAccessors() {
        #expect(AppStrings.AIAssistant.titleText == "AI Assistant")
        #expect(AppStrings.AIAssistant.badgeComingSoonText == "COMING SOON")
        #expect(AppStrings.AIAssistant.heroTitleText == "VocabCraft AI Copilot")
        #expect(AppStrings.AIAssistant.upcomingFeaturesTitleText == "Upcoming Capabilities")
        let _: LocalizedStringKey = AppStrings.AIAssistant.title
        let _: LocalizedStringKey = AppStrings.AIAssistant.badgeComingSoon
        let _: LocalizedStringKey = AppStrings.AIAssistant.heroTitle
        let _: LocalizedStringKey = AppStrings.AIAssistant.heroDescription
        let _: LocalizedStringKey = AppStrings.AIAssistant.upcomingFeaturesTitle
        let _: LocalizedStringKey = AppStrings.AIAssistant.featureConversationTitle
        let _: LocalizedStringKey = AppStrings.AIAssistant.featureConversationDescription
        let _: LocalizedStringKey = AppStrings.AIAssistant.featureContextTitle
        let _: LocalizedStringKey = AppStrings.AIAssistant.featureContextDescription
        let _: LocalizedStringKey = AppStrings.AIAssistant.featurePronunciationTitle
        let _: LocalizedStringKey = AppStrings.AIAssistant.featurePronunciationDescription
    }

    @Test("Verifies widget accessors in AppStrings.Widget")
    func testAppStringsWidgetAccessors() {
        #expect(AppStrings.Widget.nextText == "Next")
        #expect(AppStrings.Widget.masteredText == "Mastered")
        #expect(AppStrings.Widget.levelText(3) == "Level 3")
        let _: LocalizedStringKey = AppStrings.Widget.next
        let _: LocalizedStringKey = AppStrings.Widget.mastered
        let _: LocalizedStringKey = AppStrings.Widget.level(3)
    }

    @Test("Verifies AI Assistant and widget catalog keys integrity")
    func testAIAssistantAndWidgetCatalogKeysIntegrity() throws {
        let strings = try loadCatalogStrings()

        let expectedAIAssistantAndKeys: [String: (vi: String, en: String)] = [
            "app.ai_assistant.title": ("Trợ lý AI", "AI Assistant"),
            "app.ai_assistant.badge_coming_soon": ("SẮP RA MẮT", "COMING SOON"),
            "app.ai_assistant.hero_title": ("VocabCraft AI Copilot", "VocabCraft AI Copilot"),
            "app.ai_assistant.upcoming_features_title": ("Tính năng sắp ra mắt", "Upcoming Capabilities"),
            "app.ai_assistant.feature_conversation_title": ("Đối tác Luyện hội thoại AI", "AI Conversation Partner"),
            "app.ai_assistant.feature_context_title": ("Tạo Ngữ cảnh Thông minh", "Smart Context Generator"),
            "app.ai_assistant.feature_pronunciation_title": ("Huấn luyện viên Ngữ điệu & Phát âm", "Phonetic & Tone Coach"),
            "app.widget.next": ("Tiếp", "Next"),
            "app.widget.mastered": ("Thuộc", "Mastered"),
            "app.widget.level_format": ("Cấp độ %lld", "Level %lld")
        ]

        for (key, expected) in expectedAIAssistantAndKeys {
            let entry = try #require(strings[key], "Missing required key: \(key)")
            #expect(
                entry["extractionState"] as? String == "manual",
                "Key \(key) must have extractionState: manual"
            )

            let localizations = try #require(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations"
            )

            // Verify EN
            let enLoc = try #require(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try #require(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(enVal == expected.en, "Key \(key) EN mismatch: expected '\(expected.en)' but got '\(enVal)'")

            // Verify VI
            let viLoc = try #require(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try #require(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(viVal == expected.vi, "Key \(key) VI mismatch: expected '\(expected.vi)' but got '\(viVal)'")
        }
    }
}
#endif
