import Foundation

/// Domain errors occurring during guided practice validation and execution.
public enum PracticeDomainError: Error, LocalizedError, Sendable, Equatable {
    case invalidDifficulty(Int)
    case duplicateTargetWordId(Int64)
    case unsupportedPolicyVersion(Int)
    case unsupportedSchemaVersion(Int)
    case emptyObjectives
    case emptyTargetWords

    public var errorDescription: String? {
        switch self {
        case .invalidDifficulty(let value):
            return "Difficulty axis value \(value) is outside the permitted 0...2 range."
        case .duplicateTargetWordId(let id):
            return "Target word ID \(id) is duplicated in the practice mission."
        case .unsupportedPolicyVersion(let version):
            return "Policy version \(version) is not supported."
        case .unsupportedSchemaVersion(let version):
            return "Schema version \(version) is not supported."
        case .emptyObjectives:
            return "Practice mission must define at least one communicative objective."
        case .emptyTargetWords:
            return "Practice mission must define at least one target word."
        }
    }
}

/// Frozen snapshot of target word metadata captured when a mission is created.
public struct PracticeWordSnapshot: Codable, Sendable, Equatable, Hashable {
    public let wordId: Int64
    public let lemma: String
    public let definitionEn: String
    public let definitionVi: String
    public let sourceDeckId: String?
    public let sourceNodeId: String?

    public init(
        wordId: Int64,
        lemma: String,
        definitionEn: String,
        definitionVi: String,
        sourceDeckId: String? = nil,
        sourceNodeId: String? = nil
    ) {
        self.wordId = wordId
        self.lemma = lemma
        self.definitionEn = definitionEn
        self.definitionVi = definitionVi
        self.sourceDeckId = sourceDeckId
        self.sourceNodeId = sourceNodeId
    }
}

/// Specific vocabulary sense attached to a target word in template definitions.
public struct PracticeWordSense: Codable, Sendable, Equatable, Hashable {
    public let wordId: Int64
    public let sense: String

    public init(wordId: Int64, sense: String) {
        self.wordId = wordId
        self.sense = sense
    }
}

/// Broad communicative context categories prescribed by templates.
public enum PracticeContextFamily: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case dining
    case shopping
    case planning
    case social
    case travel
    case work
}

/// Three-axis difficulty model bounded to 0...2 per dimension.
public struct PracticeDifficulty: Codable, Sendable, Equatable, Hashable {
    public let taskConstraints: Int
    public let characterDirectness: Int
    public let contextNovelty: Int

    public init(
        taskConstraints: Int,
        characterDirectness: Int,
        contextNovelty: Int
    ) throws {
        guard (0...2).contains(taskConstraints) else {
            throw PracticeDomainError.invalidDifficulty(taskConstraints)
        }
        guard (0...2).contains(characterDirectness) else {
            throw PracticeDomainError.invalidDifficulty(characterDirectness)
        }
        guard (0...2).contains(contextNovelty) else {
            throw PracticeDomainError.invalidDifficulty(contextNovelty)
        }
        self.taskConstraints = taskConstraints
        self.characterDirectness = characterDirectness
        self.contextNovelty = contextNovelty
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let constraints = try container.decode(Int.self, forKey: .taskConstraints)
        let directness = try container.decode(Int.self, forKey: .characterDirectness)
        let novelty = try container.decode(Int.self, forKey: .contextNovelty)
        try self.init(
            taskConstraints: constraints,
            characterDirectness: directness,
            contextNovelty: novelty
        )
    }
}

/// Machine-readable selection rationale codes.
public enum PracticeSelectionReason: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case retryAssisted
    case communicationDue
    case noCommunicationEvidence
}

/// Immutable snapshot defining a practice assignment session.
public struct PracticeMission: Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let templateId: String
    public let templateVersion: Int
    public let targetWordIds: [Int64]
    public let wordSnapshots: [PracticeWordSnapshot]
    public let objectiveIds: [String]
    public let contextFamily: PracticeContextFamily
    public let difficulty: PracticeDifficulty
    public let selectionReasons: [PracticeSelectionReason]
    public let policyVersion: Int
    public let createdAt: Date

    public init(
        id: UUID,
        templateId: String,
        templateVersion: Int,
        targetWordIds: [Int64],
        wordSnapshots: [PracticeWordSnapshot],
        objectiveIds: [String],
        contextFamily: PracticeContextFamily,
        difficulty: PracticeDifficulty,
        selectionReasons: [PracticeSelectionReason],
        policyVersion: Int = 1,
        createdAt: Date
    ) throws {
        guard policyVersion == 1 else {
            throw PracticeDomainError.unsupportedPolicyVersion(policyVersion)
        }
        guard !targetWordIds.isEmpty else {
            throw PracticeDomainError.emptyTargetWords
        }
        guard !objectiveIds.isEmpty else {
            throw PracticeDomainError.emptyObjectives
        }

        var seenTargetIds = Set<Int64>()
        for wordId in targetWordIds {
            guard seenTargetIds.insert(wordId).inserted else {
                throw PracticeDomainError.duplicateTargetWordId(wordId)
            }
        }

        var seenSnapshotIds = Set<Int64>()
        for snapshot in wordSnapshots {
            guard seenSnapshotIds.insert(snapshot.wordId).inserted else {
                throw PracticeDomainError.duplicateTargetWordId(snapshot.wordId)
            }
        }

        self.id = id
        self.templateId = templateId
        self.templateVersion = templateVersion
        self.targetWordIds = targetWordIds
        self.wordSnapshots = wordSnapshots
        self.objectiveIds = objectiveIds
        self.contextFamily = contextFamily
        self.difficulty = difficulty
        self.selectionReasons = selectionReasons
        self.policyVersion = policyVersion
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let templateId = try container.decode(String.self, forKey: .templateId)
        let templateVersion = try container.decode(Int.self, forKey: .templateVersion)
        let targetWordIds = try container.decode([Int64].self, forKey: .targetWordIds)
        let wordSnapshots = try container.decode([PracticeWordSnapshot].self, forKey: .wordSnapshots)
        let objectiveIds = try container.decode([String].self, forKey: .objectiveIds)
        let contextFamily = try container.decode(PracticeContextFamily.self, forKey: .contextFamily)
        let difficulty = try container.decode(PracticeDifficulty.self, forKey: .difficulty)
        let selectionReasons = try container.decode([PracticeSelectionReason].self, forKey: .selectionReasons)
        let policyVersion = try container.decode(Int.self, forKey: .policyVersion)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)

        try self.init(
            id: id,
            templateId: templateId,
            templateVersion: templateVersion,
            targetWordIds: targetWordIds,
            wordSnapshots: wordSnapshots,
            objectiveIds: objectiveIds,
            contextFamily: contextFamily,
            difficulty: difficulty,
            selectionReasons: selectionReasons,
            policyVersion: policyVersion,
            createdAt: createdAt
        )
    }
}
