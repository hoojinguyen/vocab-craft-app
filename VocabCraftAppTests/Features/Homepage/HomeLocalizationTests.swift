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

    @Test("Verifies catalog keys integrity for Home domain")
    func testHomeCatalogKeysIntegrity() throws {
        // Find Localizable.xcstrings file
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
        let strings = try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )

        let requiredHomeKeys = [
            "app.home.title",
            "app.home.header.greeting_format",
            "app.home.header.daily_goal_format",
            "app.home.header.daily_goal_count_format",
            "app.home.header.daily_goal_a11y_format",
            "app.home.header.streak_format",
            "app.home.section.unit_title_format",
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

        #expect(requiredHomeKeys.count == 20)

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

    @Test("Verifies search accessors in AppStrings.Search")
    func testAppStringsSearchAccessors() {
        #expect(AppStrings.Search.titleText == "Search")
        #expect(AppStrings.Search.upcomingFeatureBadgeText == "COMING SOON")
        #expect(AppStrings.Search.smartLookupTitleText == "Smart Dictionary & AI Lookup")
        #expect(AppStrings.Search.smartLookupDescriptionText == "Offline morphological parser, bilingual context sentences...")
        #expect(AppStrings.Search.recentSearchesTitleText == "Recent Searches")
        #expect(AppStrings.Search.suggestedTopicsTitleText == "Suggested Topics")
        #expect(AppStrings.Search.topicIeltsText == "IELTS Band 7.0+")
        #expect(AppStrings.Search.topicBusinessText == "Business & Tech")
        #expect(AppStrings.Search.topicAcademicText == "Academic Research")
        #expect(AppStrings.Search.topicDailyText == "Daily Expressions")
        let _: LocalizedStringKey = AppStrings.Search.title
        let _: LocalizedStringKey = AppStrings.Search.upcomingFeatureBadge
        let _: LocalizedStringKey = AppStrings.Search.smartLookupTitle
        let _: LocalizedStringKey = AppStrings.Search.smartLookupDescription
        let _: LocalizedStringKey = AppStrings.Search.recentSearchesTitle
        let _: LocalizedStringKey = AppStrings.Search.suggestedTopicsTitle
        let _: LocalizedStringKey = AppStrings.Search.topicIelts
        let _: LocalizedStringKey = AppStrings.Search.topicBusiness
        let _: LocalizedStringKey = AppStrings.Search.topicAcademic
        let _: LocalizedStringKey = AppStrings.Search.topicDaily
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

    @Test("Verifies search and widget catalog keys integrity")
    func testSearchAndWidgetCatalogKeysIntegrity() throws {
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
        let strings = try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )

        let expectedSearchAndWidgetKeys: [String: (vi: String, en: String)] = [
            "app.search.title": ("Tra từ", "Search"),
            "app.search.upcoming_feature_badge": ("SẮP RA MẮT", "COMING SOON"),
            "app.search.smart_lookup_title": ("Từ điển Thông minh & Tra cứu AI", "Smart Dictionary & AI Lookup"),
            "app.search.smart_lookup_desc": ("Bộ phân tích hình thái học offline, câu ví dụ song ngữ...", "Offline morphological parser, bilingual context sentences..."),
            "app.search.recent_searches": ("Tìm kiếm gần đây", "Recent Searches"),
            "app.search.suggested_topics": ("Chủ đề gợi ý", "Suggested Topics"),
            "app.search.topic_ielts": ("IELTS Band 7.0+", "IELTS Band 7.0+"),
            "app.search.topic_business": ("Kinh doanh & Công nghệ", "Business & Tech"),
            "app.search.topic_academic": ("Nghiên cứu Học thuật", "Academic Research"),
            "app.search.topic_daily": ("Giao tiếp Hàng ngày", "Daily Expressions"),
            "app.widget.next": ("Tiếp", "Next"),
            "app.widget.mastered": ("Thuộc", "Mastered"),
            "app.widget.level_format": ("Cấp độ %lld", "Level %lld")
        ]

        for (key, expected) in expectedSearchAndWidgetKeys {
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
