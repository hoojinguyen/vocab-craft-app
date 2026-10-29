import CraftUIKit
import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("VocabGrowthDashboardSheet Tests")
struct VocabGrowthDashboardSheetTests {
    @Test("VocabGrowthDashboard renders CEFR distribution")
    func testVocabGrowthDashboardRendersCEFRDistribution() {
        let snapshot = VocabGrowthSnapshot(
            totalWordsAcquired: 450,
            masteredWordsCount: 200,
            consolidatingWordsCount: 150,
            newWordsCount: 100,
            estimatedRetentionRate: 0.95,
            cefrDistribution: [
                CEFRLevelStat(cefrLevel: "A1", acquiredCount: 300, targetStandardCount: 500),
                CEFRLevelStat(cefrLevel: "A2", acquiredCount: 150, targetStandardCount: 600)
            ]
        )
        let view = VocabGrowthDashboardSheet(snapshot: snapshot, onDismiss: {})
        #expect(view.snapshot.totalWordsAcquired == 450)
        #expect(view.snapshot.cefrDistribution.count == 2)
    }

    @Test("VocabGrowthDashboard dismiss callback fires")
    func testVocabGrowthDashboardDismissCallback() {
        var dismissed = false
        let snapshot = VocabGrowthSnapshot(
            totalWordsAcquired: 120,
            masteredWordsCount: 50,
            consolidatingWordsCount: 40,
            newWordsCount: 30,
            estimatedRetentionRate: 0.90,
            cefrDistribution: [
                CEFRLevelStat(cefrLevel: "A1", acquiredCount: 120, targetStandardCount: 500)
            ]
        )
        let view = VocabGrowthDashboardSheet(snapshot: snapshot, onDismiss: {
            dismissed = true
        })

        view.onDismiss()
        #expect(dismissed == true)
    }

    @Test("VocabGrowthDashboard body renders correctly")
    func testVocabGrowthDashboardBodyRenders() {
        let snapshot = VocabGrowthSnapshot(
            totalWordsAcquired: 1250,
            masteredWordsCount: 700,
            consolidatingWordsCount: 350,
            newWordsCount: 200,
            estimatedRetentionRate: 0.94,
            cefrDistribution: [
                CEFRLevelStat(cefrLevel: "A1", acquiredCount: 500, targetStandardCount: 500),
                CEFRLevelStat(cefrLevel: "A2", acquiredCount: 600, targetStandardCount: 600),
                CEFRLevelStat(cefrLevel: "B1", acquiredCount: 150, targetStandardCount: 800),
                CEFRLevelStat(cefrLevel: "B2", acquiredCount: 0, targetStandardCount: 1000),
                CEFRLevelStat(cefrLevel: "C1", acquiredCount: 0, targetStandardCount: 1200),
                CEFRLevelStat(cefrLevel: "C2", acquiredCount: 0, targetStandardCount: 1500)
            ]
        )
        let view = VocabGrowthDashboardSheet(snapshot: snapshot, dailyPace: 15, onDismiss: {})
        assertHosted(view)
        #expect(view.snapshot.totalWordsAcquired == 1250)
        #expect(view.snapshot.masteredWordsCount == 700)
        #expect(view.snapshot.consolidatingWordsCount == 350)
        #expect(view.snapshot.newWordsCount == 200)
    }

    @Test("VocabGrowthDashboard handles empty snapshot")
    func testVocabGrowthDashboardEmptySnapshot() {
        let snapshot = VocabGrowthSnapshot(
            totalWordsAcquired: 0,
            masteredWordsCount: 0,
            consolidatingWordsCount: 0,
            newWordsCount: 0,
            estimatedRetentionRate: 1.0,
            cefrDistribution: []
        )
        let view = VocabGrowthDashboardSheet(snapshot: snapshot, onDismiss: {})
        assertHosted(view)
        #expect(view.snapshot.totalWordsAcquired == 0)
    }

    @Test("VocabGrowthDashboard computes competence level and pacing")
    func testVocabGrowthDashboardCompetenceAndPacing() {
        let snapshot = VocabGrowthSnapshot(
            totalWordsAcquired: 650,
            masteredWordsCount: 400,
            consolidatingWordsCount: 150,
            newWordsCount: 100,
            estimatedRetentionRate: 0.92,
            cefrDistribution: [
                CEFRLevelStat(cefrLevel: "A1", acquiredCount: 500, targetStandardCount: 500),
                CEFRLevelStat(cefrLevel: "A2", acquiredCount: 150, targetStandardCount: 600),
                CEFRLevelStat(cefrLevel: "B1", acquiredCount: 0, targetStandardCount: 800)
            ]
        )
        let view = VocabGrowthDashboardSheet(snapshot: snapshot, dailyPace: 10, onDismiss: {})
        #expect(view.estimatedCompetenceLevel == "A1+")
        #expect(view.pacingRemainingWords == 450)
        #expect(view.pacingTargetLevel == "A2")
    }

    @Test("AppStrings.VocabGrowth accessors return expected formatted strings")
    func testAppStringsVocabGrowthAccessors() {
        #expect(!AppStrings.VocabGrowth.dashboardTitleText.isEmpty)
        #expect(!AppStrings.VocabGrowth.dashboardSubtitleText.isEmpty)
        #expect(!AppStrings.VocabGrowth.pacingAllCompletedText.isEmpty)
        #expect(AppStrings.VocabGrowth.retentionHealthValue(percent: 94).contains("94%"))
        #expect(AppStrings.VocabGrowth.cefrStatRatio(acquired: 240, target: 800, percent: 30).contains("240/800"))
        #expect(AppStrings.VocabGrowth.wordsCount(count: 150).contains("150"))
        #expect(AppStrings.VocabGrowth.headerPill(words: 450, level: "B1").contains("450"))
        #expect(AppStrings.VocabGrowth.headerPill(words: 450, level: "B1").contains("B1"))
        #expect(AppStrings.VocabGrowth.headerPillA11y(words: 450, level: "B1").contains("450"))
    }

    @Test("HomepageViewModel vocab growth integration")
    func testHomepageViewModelVocabGrowthIntegration() async {
        let snapshot = VocabGrowthSnapshot(
            totalWordsAcquired: 300,
            masteredWordsCount: 150,
            consolidatingWordsCount: 100,
            newWordsCount: 50,
            estimatedRetentionRate: 0.96,
            cefrDistribution: [
                CEFRLevelStat(cefrLevel: "A1", acquiredCount: 300, targetStandardCount: 500)
            ]
        )
        let vm = HomepageViewModel(vocabGrowthSnapshot: snapshot)
        #expect(vm.isVocabGrowthDashboardPresented == false)
        #expect(vm.totalWordsAcquired == 300)
        #expect(vm.currentVocabGrowthSnapshot.totalWordsAcquired == 300)

        vm.presentVocabGrowthDashboard()
        #expect(vm.isVocabGrowthDashboardPresented == true)

        vm.dismissVocabGrowthDashboard()
        #expect(vm.isVocabGrowthDashboardPresented == false)
    }

    @Test("Verify vocab growth localization catalog integrity in Localizable.xcstrings")
    func testVocabGrowthLocalizationCatalogIntegrity() throws {
        let potentialPaths: [String?] = [
            Bundle.module.path(forResource: "Localizable", ofType: "xcstrings"),
            ProcessInfo.processInfo.environment["VOCABCRAFT_XSTRINGS_PATH"],
            FileManager.default.currentDirectoryPath + "/VocabCraftApp/Resources/Localizable.xcstrings",
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

        let resolvedData = try #require(data, "Localizable.xcstrings should be found")
        let json = try #require(
            try JSONSerialization.jsonObject(with: resolvedData) as? [String: Any],
            "Catalog must parse as JSON"
        )
        let strings = try #require(
            json["strings"] as? [String: [String: Any]],
            "Catalog must contain strings"
        )

        let requiredKeys = [
            "app.vocab_growth.dashboard_title",
            "app.vocab_growth.dashboard_subtitle",
            "app.vocab_growth.total_words_label",
            "app.vocab_growth.estimated_competence_label",
            "app.vocab_growth.retention_health_label",
            "app.vocab_growth.retention_health_format",
            "app.vocab_growth.cefr_ladder_title",
            "app.vocab_growth.cefr_ladder_subtitle",
            "app.vocab_growth.cefr_stat_ratio_format",
            "app.vocab_growth.depth_funnel_title",
            "app.vocab_growth.depth_funnel_subtitle",
            "app.vocab_growth.tier_encountered_title",
            "app.vocab_growth.tier_encountered_desc",
            "app.vocab_growth.tier_consolidating_title",
            "app.vocab_growth.tier_consolidating_desc",
            "app.vocab_growth.tier_mastered_title",
            "app.vocab_growth.tier_mastered_desc",
            "app.vocab_growth.pacing_title",
            "app.vocab_growth.pacing_subtitle",
            "app.vocab_growth.pacing_prediction_format",
            "app.vocab_growth.pacing_all_completed",
            "app.vocab_growth.words_count_format",
            "app.vocab_growth.header_pill_format",
            "app.vocab_growth.header_pill_a11y_format",
            "app.vocab_growth.header_pill_hint"
        ]

        for key in requiredKeys {
            let entry = try #require(strings[key], "Missing vocab growth key: \(key)")
            #expect(entry["extractionState"] as? String == "manual", "Key \(key) extractionState must be manual")
            let localizations = try #require(entry["localizations"] as? [String: [String: Any]], "Key \(key) missing localizations")

            let enUnit = try #require(localizations["en"]?["stringUnit"] as? [String: Any], "Key \(key) missing EN stringUnit")
            #expect(enUnit["state"] as? String == "translated", "Key \(key) EN state must be translated")
            let enVal = try #require(enUnit["value"] as? String, "Key \(key) missing EN value")
            #expect(!enVal.isEmpty, "Key \(key) EN value cannot be empty")

            let viUnit = try #require(localizations["vi"]?["stringUnit"] as? [String: Any], "Key \(key) missing VI stringUnit")
            #expect(viUnit["state"] as? String == "translated", "Key \(key) VI state must be translated")
            let viVal = try #require(viUnit["value"] as? String, "Key \(key) missing VI value")
            #expect(!viVal.isEmpty, "Key \(key) VI value cannot be empty")
        }
    }
}
