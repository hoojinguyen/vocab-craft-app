import SwiftUI
@testable import VocabCraftApp
import XCTest

final class HomeLocalizationTests: XCTestCase {
    func testAppStringsHomeHeaderAccessors() {
        XCTAssertEqual(AppStrings.Home.greeting("Hooji"), "Hello, Hooji")
        XCTAssertNotNil(AppStrings.Home.greetingKey("Hooji"))
        XCTAssertEqual(AppStrings.Home.dailyGoal(percent: 80), "Daily Goal: 80%")
        XCTAssertEqual(AppStrings.Home.streak(days: 5), "5 days")
    }

    func testAppStringsHomeSectionAccessors() {
        XCTAssertEqual(AppStrings.Home.unitTitle(number: 1, title: "Foundations"), "Unit 1: Foundations")
        XCTAssertEqual(AppStrings.Home.checkpointTitleText, "Unit Review Exam")
        XCTAssertEqual(AppStrings.Home.checkpointSubtitleText, "Comprehensive exam covering all unit words")
        XCTAssertNotNil(AppStrings.Home.checkpointTitle)
        XCTAssertNotNil(AppStrings.Home.checkpointSubtitle)
    }

    func testAppStringsHomeNodeMetadataAndObjectives() {
        XCTAssertEqual(AppStrings.Home.wordsDuration(words: 10, minutes: 5), "10 words • 5 min")
        XCTAssertEqual(AppStrings.Home.objective1(words: 15), "Master 15 core vocabulary words")
        XCTAssertEqual(AppStrings.Home.objective2Text, "Practice 2-way Receptive & Productive recall")
        XCTAssertEqual(AppStrings.Home.objective3Text, "Achieve ≥ 80% accuracy to pass")
        XCTAssertEqual(AppStrings.Home.checkpointObjective1(words: 50), "Review all 50 words in this unit")
        XCTAssertEqual(AppStrings.Home.checkpointObjective2Text, "Score ≥ 80% accuracy to unlock the next Unit")
        XCTAssertNotNil(AppStrings.Home.objective2)
        XCTAssertNotNil(AppStrings.Home.objective3)
        XCTAssertNotNil(AppStrings.Home.checkpointObjective2)
    }

    func testAppStringsHomeCallToActionsAndHints() {
        XCTAssertEqual(AppStrings.Home.ctaStartText, "Start Lesson")
        XCTAssertEqual(AppStrings.Home.ctaContinue(percent: 60), "Continue (60%)")
        XCTAssertEqual(AppStrings.Home.ctaReview(xp: 25), "Review Lesson (+25 XP)")
        XCTAssertEqual(AppStrings.Home.ctaCheckpointText, "Start Boss Exam")
        XCTAssertEqual(AppStrings.Home.lockedHintText, "Complete previous lessons to unlock")
        XCTAssertNotNil(AppStrings.Home.ctaStart)
        XCTAssertNotNil(AppStrings.Home.ctaCheckpoint)
        XCTAssertNotNil(AppStrings.Home.lockedHint)
    }

    func testHomeCatalogKeysIntegrity() throws {
        // Find Localizable.xcstrings file
        let potentialPaths: [String?] = [
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #file)
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

        let fileData = try XCTUnwrap(data, "Localizable.xcstrings should be found")
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: fileData) as? [String: Any],
            "Catalog should parse as JSON dictionary"
        )
        let strings = try XCTUnwrap(
            json["strings"] as? [String: [String: Any]],
            "Catalog should contain 'strings' key"
        )

        let requiredHomeKeys = [
            "app.home.header.greeting_format",
            "app.home.header.daily_goal_format",
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

        XCTAssertEqual(requiredHomeKeys.count, 17)

        for key in requiredHomeKeys {
            let entry = try XCTUnwrap(strings[key], "Missing required key: \(key)")
            XCTAssertEqual(
                entry["extractionState"] as? String,
                "manual",
                "Key \(key) must have extractionState: manual"
            )

            let localizations = try XCTUnwrap(
                entry["localizations"] as? [String: [String: Any]],
                "Key \(key) must have localizations"
            )

            // Verify EN
            let enLoc = try XCTUnwrap(localizations["en"], "Key \(key) missing EN localization")
            let enUnit = try XCTUnwrap(enLoc["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            XCTAssertEqual(enUnit["state"] as? String, "translated", "Key \(key) EN state must be 'translated'")
            let enVal = try XCTUnwrap(enUnit["value"] as? String, "Key \(key) missing EN value")
            XCTAssertFalse(enVal.isEmpty, "Key \(key) EN value cannot be empty")

            // Verify VI
            let viLoc = try XCTUnwrap(localizations["vi"], "Key \(key) missing VI localization")
            let viUnit = try XCTUnwrap(viLoc["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            XCTAssertEqual(viUnit["state"] as? String, "translated", "Key \(key) VI state must be 'translated'")
            let viVal = try XCTUnwrap(viUnit["value"] as? String, "Key \(key) VI value cannot be empty")
            XCTAssertFalse(viVal.isEmpty, "Key \(key) VI value cannot be empty")
        }
    }
}
