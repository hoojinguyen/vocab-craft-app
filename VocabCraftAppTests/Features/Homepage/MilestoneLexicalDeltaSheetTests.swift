import CraftUIKit
import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("MilestoneLexicalDeltaSheet Tests")
struct MilestoneLexicalDeltaSheetTests {
    @Test("MilestoneLexicalDeltaSheet initializes with metrics")
    func testMilestoneDeltaSheetInitializesWithMetrics() {
        let delta = MilestoneLexicalDelta(
            unitId: "deck_daily",
            unitTitle: "Everyday Travel",
            cefrLevel: "A1",
            newWordsAdded: 15,
            wordsMastered: 8,
            avgResponseTimeMs: 1200,
            accuracyRate: 0.94
        )
        let view = MilestoneLexicalDeltaSheet(delta: delta, onContinue: {}, onOpenVault: {})
        #expect(view.delta.newWordsAdded == 15)
        #expect(view.delta.cefrLevel == "A1")
    }

    @Test("MilestoneLexicalDeltaSheet callbacks fire on invocation")
    func testMilestoneDeltaSheetCallbacksFire() {
        var didContinue = false
        var didOpenVault = false

        let delta = MilestoneLexicalDelta(
            unitId: "deck_tech",
            unitTitle: "Tech & Workplace",
            cefrLevel: "B1",
            newWordsAdded: 20,
            wordsMastered: 12,
            avgResponseTimeMs: 950,
            accuracyRate: 0.98,
            acquiredWords: ["Algorithm", "Bandwidth", "Scalability"]
        )
        let view = MilestoneLexicalDeltaSheet(
            delta: delta,
            onContinue: { didContinue = true },
            onOpenVault: { didOpenVault = true }
        )

        view.onContinue()
        #expect(didContinue == true)

        view.onOpenVault()
        #expect(didOpenVault == true)
    }

    @Test("MilestoneLexicalDeltaSheet body renders properly")
    func testMilestoneDeltaSheetBodyRenders() {
        let delta = MilestoneLexicalDelta(
            unitId: "deck_daily",
            unitTitle: "Everyday Travel",
            cefrLevel: "A2",
            newWordsAdded: 18,
            wordsMastered: 10,
            avgResponseTimeMs: 1100,
            accuracyRate: 0.96,
            acquiredWords: ["Passport", "Luggage", "Boarding"],
            cefrProgressCurrent: 240,
            cefrProgressTarget: 800
        )
        let view = MilestoneLexicalDeltaSheet(delta: delta, onContinue: {}, onOpenVault: {})
        _ = view.body
        #expect(view.delta.unitId == "deck_daily")
    }

    @Test("HomepageViewModel triggerMilestoneDelta populates activeMilestoneDelta")
    func testHomepageViewModelTriggerMilestoneDelta() {
        let section = LessonSection(id: "deck_1", title: "Unit 1: Basics", level: "A1", nodes: [])
        let vm = HomepageViewModel(sections: [section])

        #expect(vm.activeMilestoneDelta == nil)

        vm.triggerMilestoneDelta(for: "deck_1")
        #expect(vm.activeMilestoneDelta != nil)
        #expect(vm.activeMilestoneDelta?.unitId == "deck_1")
        #expect(vm.activeMilestoneDelta?.unitTitle == "Unit 1: Basics")
        #expect(vm.activeMilestoneDelta?.cefrLevel == "A1")
        #expect(vm.activeMilestoneDelta?.cefrProgressTarget == 500)

        vm.dismissMilestoneDelta()
        #expect(vm.activeMilestoneDelta == nil)
    }

    @Test("HomepageViewModel triggerMilestoneDelta uses dynamic CEFR progress from snapshot")
    func testHomepageViewModelTriggerMilestoneDeltaUsesSnapshot() {
        let section = LessonSection(id: "deck_b1", title: "Business English", level: "B1", nodes: [])
        let stat = CEFRLevelStat(cefrLevel: "B1", acquiredCount: 320, targetStandardCount: 800)
        let snapshot = VocabGrowthSnapshot(
            totalWordsAcquired: 320,
            masteredWordsCount: 100,
            consolidatingWordsCount: 120,
            newWordsCount: 100,
            estimatedRetentionRate: 0.92,
            cefrDistribution: [stat]
        )
        let vm = HomepageViewModel(vocabGrowthSnapshot: snapshot, sections: [section])

        vm.triggerMilestoneDelta(for: "deck_b1")
        #expect(vm.activeMilestoneDelta?.cefrProgressCurrent == 320)
        #expect(vm.activeMilestoneDelta?.cefrProgressTarget == 800)
    }

    @Test("HomepageViewModel handleLessonFinished triggers milestone on checkpoint completion")
    func testHomepageViewModelHandleLessonFinishedWithCheckpoint() {
        let cpNode = LessonNodeModel(id: "checkpoint_deck_1", title: "Checkpoint", state: .active, kind: .checkpoint)
        let section = LessonSection(id: "deck_1", title: "Travel Essentials", level: "A2", nodes: [cpNode])
        let vm = HomepageViewModel(sections: [section])

        let summary = LessonSummaryModel(
            stageId: "checkpoint_deck_1",
            deckId: "deck_1",
            stars: 3,
            xpEarned: 100,
            accuracyFraction: 0.95,
            learnedWords: [
                TopicWordDTO(
                    id: 1,
                    stageId: "checkpoint_deck_1",
                    lemma: "Hotel",
                    phonetic: "/hoʊˈtɛl/",
                    pos: "noun",
                    cefrLevel: "A2",
                    definitionVi: "Khách sạn",
                    definitionEn: "A place providing lodging",
                    exampleEn: "I booked a hotel.",
                    exampleVi: "Tôi đã đặt khách sạn."
                )
            ],
            weakWordIds: []
        )

        vm.handleLessonFinished(summary: summary)
        #expect(vm.activeMilestoneDelta != nil)
        #expect(vm.activeMilestoneDelta?.unitId == "deck_1")
        #expect(vm.activeMilestoneDelta?.unitTitle == "Travel Essentials")
        #expect(vm.activeMilestoneDelta?.cefrLevel == "A2")
        #expect(vm.activeMilestoneDelta?.acquiredWords.contains("Hotel") == true)
    }

    @Test("HomepageViewModel handleLessonFinished does not trigger milestone on standard node completion")
    func testHomepageViewModelHandleLessonFinishedStandardNode() {
        let stdNode = LessonNodeModel(id: "stage_1", title: "Lesson 1", state: .active, kind: .standard)
        let section = LessonSection(id: "deck_1", title: "Travel Essentials", level: "A2", nodes: [stdNode])
        let vm = HomepageViewModel(sections: [section])

        let summary = LessonSummaryModel(
            stageId: "stage_1",
            deckId: "deck_1",
            stars: 3,
            xpEarned: 50,
            accuracyFraction: 0.90,
            learnedWords: [],
            weakWordIds: []
        )

        vm.handleLessonFinished(summary: summary)
        #expect(vm.activeMilestoneDelta == nil)
    }

    @Test("HomepageViewModel claimTreasure triggers milestone delta when autoTriggerMilestone is true")
    func testHomepageViewModelClaimTreasureTriggersMilestoneDelta() async throws {
        let treasureNode = LessonNodeModel(id: "treasure_deck_1", title: "Treasure Chest", state: .bonus, kind: .treasureChest)
        let section = LessonSection(id: "deck_1", title: "Unit 1", level: "A1", nodes: [treasureNode])
        let vm = HomepageViewModel(claimTreasureRewardUseCase: nil, sections: [section])

        let result = try await vm.claimTreasure(node: treasureNode, autoTriggerMilestone: true)
        #expect(result.xpEarned == 150)
        #expect(vm.activeMilestoneDelta != nil)
        #expect(vm.activeMilestoneDelta?.unitId == "deck_1")
    }

    @Test("HomepageViewModel claimTreasure avoids modal race condition by defaulting autoTriggerMilestone to false")
    func testHomepageViewModelClaimTreasureAvoidsModalRaceCondition() async throws {
        let treasureNode = LessonNodeModel(id: "treasure_deck_1", title: "Treasure Chest", state: .bonus, kind: .treasureChest)
        let section = LessonSection(id: "deck_1", title: "Unit 1", level: "A1", nodes: [treasureNode])
        let vm = HomepageViewModel(claimTreasureRewardUseCase: nil, sections: [section])

        let result = try await vm.claimTreasure(node: treasureNode)
        #expect(result.xpEarned == 150)
        #expect(vm.activeMilestoneDelta == nil)
    }

    @Test("AppStrings.MilestoneReport accessors return expected formatted strings")
    func testAppStringsMilestoneReportAccessors() {
        #expect(AppStrings.MilestoneReport.celebrationTitleText == "Unit Milestone Achieved!")
        #expect(AppStrings.MilestoneReport.wordsAdded(count: 15) == "+15 Words Added")
        #expect(AppStrings.MilestoneReport.latencyValue(seconds: 1.2) == "1.2s / word")
        #expect(AppStrings.MilestoneReport.retentionValue(percent: 94) == "94%")
        #expect(AppStrings.MilestoneReport.wordsMasteredValue(count: 8) == "8 words")
        #expect(AppStrings.MilestoneReport.cefrProgressTitle(level: "A1") == "A1 Competence Progress")
        #expect(AppStrings.MilestoneReport.cefrProgressDetail(current: 240, target: 800, percent: 30) == "240/800 Words (30%)")
        #expect(AppStrings.MilestoneReport.continueCtaText == "Continue Journey")
        #expect(AppStrings.MilestoneReport.viewVaultCtaText == "View in Personal Vault")

        let _: LocalizedStringKey = AppStrings.MilestoneReport.celebrationTitle
        let _: LocalizedStringKey = AppStrings.MilestoneReport.wordsAddedKey(count: 15)
        let _: LocalizedStringKey = AppStrings.MilestoneReport.wordsAddedSubtitle
        let _: LocalizedStringKey = AppStrings.MilestoneReport.acquiredWordsTitle
        let _: LocalizedStringKey = AppStrings.MilestoneReport.telemetryTitle
        let _: LocalizedStringKey = AppStrings.MilestoneReport.latencyLabel
        let _: LocalizedStringKey = AppStrings.MilestoneReport.retentionLabel
        let _: LocalizedStringKey = AppStrings.MilestoneReport.wordsMasteredLabel
        let _: LocalizedStringKey = AppStrings.MilestoneReport.continueCta
        let _: LocalizedStringKey = AppStrings.MilestoneReport.viewVaultCta
        let _: LocalizedStringKey = AppStrings.MilestoneReport.closeA11y
        let _: LocalizedStringKey = AppStrings.MilestoneReport.listenPronunciationA11y
    }

    @Test("Verify milestone report localization catalog integrity in Localizable.xcstrings")
    func testMilestoneReportLocalizationCatalogIntegrity() throws {
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
            "app.milestone_report.celebration_title",
            "app.milestone_report.words_added_format",
            "app.milestone_report.words_added_subtitle",
            "app.milestone_report.acquired_words_title",
            "app.milestone_report.telemetry_title",
            "app.milestone_report.latency_label",
            "app.milestone_report.latency_value_format",
            "app.milestone_report.retention_label",
            "app.milestone_report.retention_value_format",
            "app.milestone_report.words_mastered_label",
            "app.milestone_report.words_mastered_format",
            "app.milestone_report.cefr_progress_title_format",
            "app.milestone_report.cefr_progress_detail_format",
            "app.milestone_report.continue_cta",
            "app.milestone_report.view_vault_cta",
            "app.milestone_report.close_a11y",
            "app.milestone_report.listen_pronunciation_a11y"
        ]

        for key in requiredKeys {
            let entry = try #require(strings[key], "Missing milestone report key: \(key)")
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
