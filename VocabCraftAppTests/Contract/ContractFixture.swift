import Foundation
import SQLite3
@testable import VocabCraftApp

final class ContractFixtureMarker: Sendable {}

public enum ContractFixtureError: Error, LocalizedError {
    case resourceNotFound(String)
    case invalidData(String)

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name):
            return "Contract resource not found: \(name)"
        case .invalidData(let message):
            return "Invalid contract data: \(message)"
        }
    }
}

public struct ExpectedContractCounts: Decodable, Sendable {
    public let entries: Int
    public let senses: Int
    public let pronunciations: Int
    public let examples: Int
    public let collocations: Int
    public let decks: Int
    public let lessons: Int
    public let lessonSenses: Int
    public let attributions: Int
    public let senseAttributions: Int
    public let retiredSenses: Int
    public let reviews: Int
    public let sources: Int
    public let sourceLinks: Int

    enum CodingKeys: String, CodingKey {
        case entries
        case senses
        case pronunciations
        case examples
        case collocations
        case decks
        case lessons
        case lessonSenses = "lesson_senses"
        case attributions
        case senseAttributions = "sense_attributions"
        case retiredSenses = "retired_senses"
        case reviews
        case sources
        case sourceLinks = "source_links"
    }
}

public struct ExpectedContractData: Decodable, Sendable {
    public typealias Counts = ExpectedContractCounts

    public let bookVerbID: SenseID
    public let bookVerbExampleVi: String
    public var bookVerbExampleVI: String { bookVerbExampleVi }
    public let counts: Counts
    public let orderedEntryIDs: [EntryID]
    public let orderedSenseIDs: [SenseID]
    public let orderedLessonIDs: [LessonID]

    enum CodingKeys: String, CodingKey {
        case bookVerbID = "book_verb_id"
        case bookVerbExampleVi = "book_verb_example_vi"
        case counts
        case orderedEntryIDs = "ordered_entry_ids"
        case orderedSenseIDs = "ordered_sense_ids"
        case orderedLessonIDs = "ordered_lesson_ids"
    }
}

public struct CatalogData: Decodable, Sendable {
    public let iconKeys: [String: String]
    public let themeKeys: [String: String]

    enum CodingKeys: String, CodingKey {
        case iconKeys = "icon_keys"
        case themeKeys = "theme_keys"
    }
}

public struct EventFixtureInvalidCase: Sendable {
    public let reason: String
    public let payloadData: Data

    public init(reason: String, payloadData: Data) {
        self.reason = reason
        self.payloadData = payloadData
    }
}

public struct EventFixtureData: Sendable {
    public typealias InvalidCase = EventFixtureInvalidCase

    public let attribution: String
    public let practiceAttempts: [PracticeAttempt]
    public let lessonCompletions: [LessonCompletion]
    public let invalidCases: [InvalidCase]

    public init(
        attribution: String,
        practiceAttempts: [PracticeAttempt],
        lessonCompletions: [LessonCompletion],
        invalidCases: [InvalidCase]
    ) {
        self.attribution = attribution
        self.practiceAttempts = practiceAttempts
        self.lessonCompletions = lessonCompletions
        self.invalidCases = invalidCases
    }
}

public enum ContractFixture {
    public static func bundleResourceURL(for file: String) -> URL? {
        let nsString = file as NSString
        let ext = nsString.pathExtension.isEmpty ? nil : nsString.pathExtension
        let name = nsString.deletingPathExtension

        let bundle = Bundle(for: ContractFixtureMarker.self)
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Contracts/v1") {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources/Contracts/v1") {
            return url
        }
        return nil
    }

    public static func bundleURL() throws -> URL {
        try bundleURL(for: "vocab_content.sqlite")
    }

    public static func bundleURL(for file: String) throws -> URL {
        if let url = bundleResourceURL(for: file) {
            return url
        }

        let testDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fallbackURL = testDir
            .appendingPathComponent("Resources/Contracts/v1")
            .appendingPathComponent(file)

        if FileManager.default.fileExists(atPath: fallbackURL.path) {
            return fallbackURL
        }

        throw ContractFixtureError.resourceNotFound(file)
    }

    public static func loadData(for file: String) throws -> Data {
        let url = try bundleURL(for: file)
        return try Data(contentsOf: url)
    }

    public static func manifest() throws -> ContentManifest {
        let data = try loadData(for: "fixture-manifest.json")
        let decoder = JSONDecoder()
        return try decoder.decode(ContentManifest.self, from: data)
    }

    public static func publishedManifest() throws -> PublishedManifest {
        let contentManifest = try manifest()
        return PublishedManifest(contentManifest: contentManifest)
    }

    public static func loadSnapshot() throws -> DatasetSnapshot {
        let data = try loadData(for: "fixture.json")
        let decoder = JSONDecoder()
        return try decoder.decode(DatasetSnapshot.self, from: data)
    }

    public static func expected() throws -> ExpectedContractData {
        let data = try loadData(for: "expected.json")
        let decoder = JSONDecoder()
        return try decoder.decode(ExpectedContractData.self, from: data)
    }

    public static func loadCatalog() throws -> CatalogData {
        let data = try loadData(for: "catalog.json")
        let decoder = JSONDecoder()
        return try decoder.decode(CatalogData.self, from: data)
    }

    public static func loadEventFixture() throws -> EventFixtureData {
        let data = try loadData(for: "event-fixture.json")
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ContractFixtureError.invalidData("event-fixture.json is not an object")
        }

        let attribution = jsonObject["attribution"] as? String ?? ""

        let attemptsData: Data
        if let rawAttempts = jsonObject["practice_attempts"] {
            attemptsData = try JSONSerialization.data(withJSONObject: rawAttempts)
        } else {
            attemptsData = Data("[]".utf8)
        }
        let decoder = JSONDecoder()
        let practiceAttempts = try decoder.decode([PracticeAttempt].self, from: attemptsData)

        let completionsData: Data
        if let rawCompletions = jsonObject["lesson_completions"] {
            completionsData = try JSONSerialization.data(withJSONObject: rawCompletions)
        } else {
            completionsData = Data("[]".utf8)
        }
        let lessonCompletions = try decoder.decode([LessonCompletion].self, from: completionsData)

        var invalidCases: [EventFixtureData.InvalidCase] = []
        if let rawInvalidCases = jsonObject["invalid_cases"] as? [[String: Any]] {
            for rawCase in rawInvalidCases {
                let reason = rawCase["reason"] as? String ?? ""
                if let payloadObj = rawCase["payload"] {
                    let payloadData = try JSONSerialization.data(withJSONObject: payloadObj)
                    invalidCases.append(EventFixtureData.InvalidCase(reason: reason, payloadData: payloadData))
                }
            }
        }

        return EventFixtureData(
            attribution: attribution,
            practiceAttempts: practiceAttempts,
            lessonCompletions: lessonCompletions,
            invalidCases: invalidCases
        )
    }

    public static func temporaryJournalURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LearningJournalTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("learning_journal.sqlite")
    }
}

public func temporaryJournalURL() -> URL {
    ContractFixture.temporaryJournalURL()
}
