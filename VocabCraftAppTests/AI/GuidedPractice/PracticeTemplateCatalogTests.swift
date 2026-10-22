import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Practice Template Catalog Tests")
struct PracticeTemplateCatalogTests {
    private let templates = PracticeTemplateCatalog.templates

    @Test("Catalog defines exactly 6 curated templates across 3 families")
    func catalogInvariants() {
        #expect(templates.count == 6)

        let uniqueIds = Set(templates.map(\.id))
        #expect(uniqueIds.count == 6)

        let diningTemplates = templates.filter { $0.contextFamily == .dining }
        let shoppingTemplates = templates.filter { $0.contextFamily == .shopping }
        let planningTemplates = templates.filter { $0.contextFamily == .planning }

        #expect(diningTemplates.count == 2)
        #expect(shoppingTemplates.count == 2)
        #expect(planningTemplates.count == 2)

        for familyTemplates in [diningTemplates, shoppingTemplates, planningTemplates] {
            let basicCount = familyTemplates.filter { $0.difficultyBounds.min.contextNovelty == 0 }.count
            let transferCount = familyTemplates.filter { $0.difficultyBounds.min.contextNovelty >= 1 }.count
            #expect(basicCount == 1)
            #expect(transferCount == 1)
        }
    }

    @Test("Every template has non-empty objectives, roles, and supported word senses")
    func templateStructureValidity() {
        for template in templates {
            #expect(!template.id.isEmpty)
            #expect(template.version == 1)
            #expect(!template.titleKey.isEmpty)
            #expect(!template.briefKey.isEmpty)
            #expect(template.roleKeys.count >= 2)
            #expect(!template.objectiveIds.isEmpty)
            #expect(!template.supportedWordSenses.isEmpty)

            // Difficulty bounds validity
            #expect(template.difficultyBounds.min.taskConstraints <= template.difficultyBounds.max.taskConstraints)
            #expect(template.difficultyBounds.min.characterDirectness <= template.difficultyBounds.max.characterDirectness)
            #expect(template.difficultyBounds.min.contextNovelty <= template.difficultyBounds.max.contextNovelty)
        }
    }

    @Test("All supported word senses resolve from real vocabulary catalog")
    func supportedWordSensesResolveFromRealVocabulary() async throws {
        let dataSource = BundledVocabularyDataSource()
        let wordsMap = try await dataSource.fetchAllWordsMap()
        #expect(!wordsMap.isEmpty)

        for template in templates {
            for sense in template.supportedWordSenses {
                let resolvedWord = wordsMap[sense.wordId]
                #expect(
                    resolvedWord != nil,
                    "Template \(template.id) references wordId \(sense.wordId) which was not found in vocabulary catalog."
                )
                #expect(!sense.sense.isEmpty)
            }
        }
    }

    @Test("All template localization keys exist with EN and VI translations in Localizable.xcstrings")
    func templateLocalizationKeysExistInCatalog() throws {
        let potentialPaths: [String?] = [
            "VocabCraftApp/Resources/Localizable.xcstrings",
            Bundle.main.path(forResource: "Localizable", ofType: "xcstrings"),
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent() // GuidedPractice
                .deletingLastPathComponent() // AI
                .deletingLastPathComponent() // VocabCraftAppTests
                .deletingLastPathComponent() // repo root
                .appendingPathComponent("VocabCraftApp/Resources/Localizable.xcstrings").path
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
            "Catalog should contain strings dictionary"
        )

        #expect(!strings.isEmpty)

        for template in templates {
            let requiredKeys = [template.titleKey, template.briefKey] + template.roleKeys
            for key in requiredKeys {
                let entry = strings[key]
                #expect(entry != nil, "Missing key in Localizable.xcstrings: \(key)")

                let localizations = entry?["localizations"] as? [String: [String: Any]]
                let enEntry = localizations?["en"]?["stringUnit"] as? [String: Any]
                let viEntry = localizations?["vi"]?["stringUnit"] as? [String: Any]

                #expect(enEntry != nil, "Missing English localization for \(key)")
                #expect(viEntry != nil, "Missing Vietnamese localization for \(key)")

                let enVal = enEntry?["value"] as? String ?? ""
                let viVal = viEntry?["value"] as? String ?? ""

                #expect(!enVal.isEmpty, "Empty English value for \(key)")
                #expect(!viVal.isEmpty, "Empty Vietnamese value for \(key)")

                #expect(enEntry?["state"] as? String == "translated")
                #expect(viEntry?["state"] as? String == "translated")
            }
        }
    }
}
