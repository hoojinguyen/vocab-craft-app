import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking blueprint catalog")
struct SpeakingBlueprintCatalogTests {
    @Test func catalogContainsTheTwelveApprovedBlueprints() {
        let scenarioIDs: Set<String> = [
            "cafe_order", "hotel_checkin", "ask_directions", "doctor_visit", "job_interview_intro", "return_item_shop"
        ]
        let topicIDs: Set<String> = [
            "topic_daily_routine", "topic_travel", "topic_work_study", "topic_movies_music", "topic_food",
            "topic_weekend_plans"
        ]
        let blueprints = SpeakingBlueprintCatalog.all

        #expect(blueprints.count == 12)
        #expect(Set(blueprints.map(\.id)).count == 12)
        #expect(Set(blueprints.filter { $0.kind == .scenario }.map(\.id)) == scenarioIDs)
        #expect(Set(blueprints.filter { $0.kind == .topic }.map(\.id)) == topicIDs)
        #expect(blueprints.allSatisfy { $0.durationSeconds == 360 })
        #expect(blueprints.filter { $0.kind == .scenario }.allSatisfy { $0.objective?.isEmpty == false })
        #expect(blueprints.filter { $0.kind == .topic }.allSatisfy { $0.objective == nil })
    }

    @Test func blueprintLookupReturnsMatchingEntryOrNil() {
        #expect(SpeakingBlueprintCatalog.blueprint(id: "cafe_order")?.id == "cafe_order")
        #expect(SpeakingBlueprintCatalog.blueprint(id: "unknown") == nil)
    }

    @Test func everyBlueprintHasLocalizedTitleAndBriefInBothLanguages() throws {
        let catalogData = try #require(localizationCatalogData(), "Localizable.xcstrings should be available")
        let json = try #require(
            JSONSerialization.jsonObject(with: catalogData) as? [String: Any],
            "Localization catalog should parse as a JSON object"
        )
        let strings = try #require(json["strings"] as? [String: [String: Any]])

        for blueprint in SpeakingBlueprintCatalog.all {
            for key in [blueprint.titleKey, blueprint.briefKey] {
                let entry = try #require(strings[key], "Missing blueprint localization key: \(key)")
                #expect(entry["extractionState"] as? String == "manual")
                let localizations = try #require(entry["localizations"] as? [String: [String: Any]])

                let englishLocalization = try #require(localizations["en"], "Missing en value for \(key)")
                let englishUnit = try #require(englishLocalization["stringUnit"] as? [String: Any])
                #expect(englishUnit["state"] as? String == "translated")
                let englishValue = try #require(englishUnit["value"] as? String)
                #expect(!englishValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                let vietnameseLocalization = try #require(localizations["vi"], "Missing vi value for \(key)")
                let vietnameseUnit = try #require(vietnameseLocalization["stringUnit"] as? [String: Any])
                #expect(vietnameseUnit["state"] as? String == "translated")
                let vietnameseValue = try #require(vietnameseUnit["value"] as? String)
                #expect(!vietnameseValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                #expect(englishValue != vietnameseValue)
            }
        }
    }

    private func localizationCatalogData() -> Data? {
        let candidates = [
            Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings")
        ]

        return candidates.compactMap { $0 }.first { FileManager.default.fileExists(atPath: $0.path) }
            .flatMap { try? Data(contentsOf: $0) }
    }
}
