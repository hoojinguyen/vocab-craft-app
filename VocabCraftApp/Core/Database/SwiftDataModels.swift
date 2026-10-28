import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

// KeyPaths are immutable property accessors. Conforming KeyPath to Sendable satisfies
// Swift 6 strict concurrency checks during Foundation #Predicate macro expansions on SwiftData @Model types.
extension KeyPath: @unchecked @retroactive Sendable {}

#if canImport(SwiftDataMacros) || canImport(SwiftData)
public typealias UserWordProgress = SchemaV4.UserWordProgress
public typealias UserStageProgress = SchemaV4.UserStageProgress
public typealias ReflexSessionLog = SchemaV4.ReflexSessionLog
public typealias QuickReflexAttemptRecord = SchemaV4.QuickReflexAttemptRecord
public typealias WidgetCurrentState = SchemaV4.WidgetCurrentState
public typealias SpeakingSessionRecord = SchemaV4.SpeakingSessionRecord
public typealias SavedPhraseRecord = SchemaV4.SavedPhraseRecord
#else
public final class UserWordProgress: @unchecked Sendable {
    public var wordId: Int64
    public var cefrLevel: String
    public var masteryLevel: Int
    public var isBookmarked: Bool
    public var easeFactor: Double
    public var intervalDays: Int
    public var nextReviewDate: Date
    public var lastReviewDate: Date
    public var totalReviews: Int
    public var needsReview: Bool
    public var mistakeCount: Int
    public var sourceDeckId: String?
    public var sourceNodeId: String?
    public var consecutiveCorrectStreak: Int
    public var practicedModesRaw: String
    public var isMastered: Bool
    public var modeSuccessCountsRaw: String = "{}"

    public init(
        wordId: Int64,
        cefrLevel: String = "A1",
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        easeFactor: Double = 2.5,
        intervalDays: Int = 1,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date = Date(),
        totalReviews: Int = 0,
        needsReview: Bool = false,
        mistakeCount: Int = 0,
        sourceDeckId: String? = nil,
        sourceNodeId: String? = nil,
        consecutiveCorrectStreak: Int = 0,
        practicedModesRaw: String = "",
        isMastered: Bool = false,
        modeSuccessCountsRaw: String = "{}"
    ) {
        self.wordId = wordId
        self.cefrLevel = cefrLevel
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.totalReviews = totalReviews
        self.needsReview = needsReview
        self.mistakeCount = mistakeCount
        self.sourceDeckId = sourceDeckId
        self.sourceNodeId = sourceNodeId
        self.consecutiveCorrectStreak = consecutiveCorrectStreak
        self.practicedModesRaw = practicedModesRaw
        self.isMastered = isMastered
        self.modeSuccessCountsRaw = modeSuccessCountsRaw
    }

    public var correctStreak: Int {
        get { consecutiveCorrectStreak }
        set { consecutiveCorrectStreak = newValue }
    }
}

public final class UserStageProgress: @unchecked Sendable {
    public var stageId: String
    public var deckId: String
    public var isCompleted: Bool
    public var score: Int
    public var progressFraction: Double
    public var completedAt: Date

    public init(
        stageId: String,
        deckId: String,
        isCompleted: Bool = false,
        score: Int = 0,
        progressFraction: Double = 0.0,
        completedAt: Date = Date()
    ) {
        self.stageId = stageId
        self.deckId = deckId
        self.isCompleted = isCompleted
        self.score = score
        self.progressFraction = progressFraction
        self.completedAt = completedAt
    }
}

public final class ReflexSessionLog: @unchecked Sendable {
    public var id: UUID
    public var drillId: Int64
    public var responseTimeMs: Int
    public var accuracyScore: Double
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        drillId: Int64,
        responseTimeMs: Int,
        accuracyScore: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.drillId = drillId
        self.responseTimeMs = responseTimeMs
        self.accuracyScore = accuracyScore
        self.timestamp = timestamp
    }
}

public final class QuickReflexAttemptRecord: @unchecked Sendable {
    public var id: UUID
    public var wordId: Int64
    public var recallWordTimeMs: Int
    public var collocationTimeMs: Int
    public var produceSentenceTimeMs: Int
    public var recallWordSucceeded: Bool
    public var collocationSucceeded: Bool
    public var produceSentenceSucceeded: Bool
    public var shadowPronunciationScore: Double?
    public var maxHintLevel: Int
    public var inputModeRawValue: String
    public var retryCount: Int
    public var confidenceRawValue: String
    public var timestamp: Date

    // Backward-compatible computed properties
    public var retrieveTimeMs: Int {
        get { recallWordTimeMs }
        set { recallWordTimeMs = newValue }
    }
    public var useTimeMs: Int {
        get { produceSentenceTimeMs }
        set { produceSentenceTimeMs = newValue }
    }
    public var retrieveSucceeded: Bool {
        get { recallWordSucceeded }
        set { recallWordSucceeded = newValue }
    }
    public var useSucceeded: Bool {
        get { produceSentenceSucceeded }
        set { produceSentenceSucceeded = newValue }
    }

    public init(
        id: UUID = UUID(),
        wordId: Int64,
        recallWordTimeMs: Int,
        collocationTimeMs: Int = 0,
        produceSentenceTimeMs: Int,
        recallWordSucceeded: Bool,
        collocationSucceeded: Bool,
        produceSentenceSucceeded: Bool,
        shadowPronunciationScore: Double? = nil,
        maxHintLevel: Int,
        inputModeRawValue: String,
        retryCount: Int,
        confidenceRawValue: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.recallWordTimeMs = recallWordTimeMs
        self.collocationTimeMs = collocationTimeMs
        self.produceSentenceTimeMs = produceSentenceTimeMs
        self.recallWordSucceeded = recallWordSucceeded
        self.collocationSucceeded = collocationSucceeded
        self.produceSentenceSucceeded = produceSentenceSucceeded
        self.shadowPronunciationScore = shadowPronunciationScore
        self.maxHintLevel = maxHintLevel
        self.inputModeRawValue = inputModeRawValue
        self.retryCount = retryCount
        self.confidenceRawValue = confidenceRawValue
        self.timestamp = timestamp
    }

    /// Legacy initializer overload for backward compatibility
    public init(
        id: UUID = UUID(),
        wordId: Int64,
        retrieveTimeMs: Int,
        useTimeMs: Int,
        retrieveSucceeded: Bool,
        useSucceeded: Bool,
        maxHintLevel: Int,
        inputModeRawValue: String,
        retryCount: Int,
        confidenceRawValue: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.recallWordTimeMs = retrieveTimeMs
        self.collocationTimeMs = 0
        self.produceSentenceTimeMs = useTimeMs
        self.recallWordSucceeded = retrieveSucceeded
        self.collocationSucceeded = retrieveSucceeded
        self.produceSentenceSucceeded = useSucceeded
        self.shadowPronunciationScore = nil
        self.maxHintLevel = maxHintLevel
        self.inputModeRawValue = inputModeRawValue
        self.retryCount = retryCount
        self.confidenceRawValue = confidenceRawValue
        self.timestamp = timestamp
    }
}

public final class WidgetCurrentState: @unchecked Sendable {
    public var id: String
    public var currentWordId: Int64
    public var lemma: String
    public var ipaUs: String
    public var definitionVi: String
    public var exampleEn: String
    public var lastUpdated: Date

    public init(
        id: String = "default_widget",
        currentWordId: Int64,
        lemma: String,
        ipaUs: String,
        definitionVi: String,
        exampleEn: String,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.currentWordId = currentWordId
        self.lemma = lemma
        self.ipaUs = ipaUs
        self.definitionVi = definitionVi
        self.exampleEn = exampleEn
        self.lastUpdated = lastUpdated
    }
}

public final class PracticeSessionRecord: @unchecked Sendable {
    public static let currentFormatVersion: Int = 1

    public var id: UUID
    public var revision: Int
    public var statusRaw: String
    public var initialInputModeRaw: String
    public var policyVersion: Int
    public var startedAt: Date
    public var completedAt: Date?
    public var payloadJSON: Data
    public var formatVersion: Int

    public init(
        id: UUID = UUID(),
        revision: Int = 1,
        statusRaw: String,
        initialInputModeRaw: String,
        policyVersion: Int = 1,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        payloadJSON: Data = Data(),
        formatVersion: Int = PracticeSessionRecord.currentFormatVersion
    ) {
        self.id = id
        self.revision = revision
        self.statusRaw = statusRaw
        self.initialInputModeRaw = initialInputModeRaw
        self.policyVersion = policyVersion
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.payloadJSON = payloadJSON
        self.formatVersion = formatVersion
    }

    public func validatePayloadFormatVersion() throws {
        guard formatVersion == Self.currentFormatVersion else {
            throw PracticePayloadError.unsupportedFormatVersion(
                recordType: "PracticeSessionRecord",
                found: formatVersion,
                supported: Self.currentFormatVersion
            )
        }
    }
}

public final class PracticeTurnRecord: @unchecked Sendable {
    public static let currentFormatVersion: Int = 1

    public var id: UUID
    public var sessionId: UUID
    public var sequence: Int
    public var speakerRaw: String
    public var inputModeRaw: String
    public var sessionRevision: Int
    public var timestamp: Date
    public var payloadJSON: Data
    public var formatVersion: Int

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        sequence: Int,
        speakerRaw: String,
        inputModeRaw: String,
        sessionRevision: Int,
        timestamp: Date = Date(),
        payloadJSON: Data = Data(),
        formatVersion: Int = PracticeTurnRecord.currentFormatVersion
    ) {
        self.id = id
        self.sessionId = sessionId
        self.sequence = sequence
        self.speakerRaw = speakerRaw
        self.inputModeRaw = inputModeRaw
        self.sessionRevision = sessionRevision
        self.timestamp = timestamp
        self.payloadJSON = payloadJSON
        self.formatVersion = formatVersion
    }

    public func validatePayloadFormatVersion() throws {
        guard formatVersion == Self.currentFormatVersion else {
            throw PracticePayloadError.unsupportedFormatVersion(
                recordType: "PracticeTurnRecord",
                found: formatVersion,
                supported: Self.currentFormatVersion
            )
        }
    }
}

public final class SupportExposureRecord: @unchecked Sendable {
    public static let currentFormatVersion: Int = 1

    public var id: UUID
    public var sessionId: UUID
    public var turnId: UUID?
    public var targetWordIdsRaw: String
    public var levelRaw: String
    public var originRaw: String
    public var channelRaw: String
    public var presentedAt: Date
    public var payloadJSON: Data
    public var formatVersion: Int

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        turnId: UUID? = nil,
        targetWordIdsRaw: String = "",
        levelRaw: String,
        originRaw: String,
        channelRaw: String,
        presentedAt: Date = Date(),
        payloadJSON: Data = Data(),
        formatVersion: Int = SupportExposureRecord.currentFormatVersion
    ) {
        self.id = id
        self.sessionId = sessionId
        self.turnId = turnId
        self.targetWordIdsRaw = targetWordIdsRaw
        self.levelRaw = levelRaw
        self.originRaw = originRaw
        self.channelRaw = channelRaw
        self.presentedAt = presentedAt
        self.payloadJSON = payloadJSON
        self.formatVersion = formatVersion
    }

    public func validatePayloadFormatVersion() throws {
        guard formatVersion == Self.currentFormatVersion else {
            throw PracticePayloadError.unsupportedFormatVersion(
                recordType: "SupportExposureRecord",
                found: formatVersion,
                supported: Self.currentFormatVersion
            )
        }
    }
}

public final class PracticePresentationRecord: @unchecked Sendable {
    public static let currentFormatVersion: Int = 1

    public var id: UUID
    public var sessionId: UUID
    public var turnId: UUID?
    public var statusRaw: String
    public var channelRaw: String
    public var proposedLevelRaw: String
    public var possibleWordIdsRaw: String
    public var payloadJSON: Data
    public var formatVersion: Int

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        turnId: UUID? = nil,
        statusRaw: String,
        channelRaw: String,
        proposedLevelRaw: String,
        possibleWordIdsRaw: String = "",
        payloadJSON: Data = Data(),
        formatVersion: Int = PracticePresentationRecord.currentFormatVersion
    ) {
        self.id = id
        self.sessionId = sessionId
        self.turnId = turnId
        self.statusRaw = statusRaw
        self.channelRaw = channelRaw
        self.proposedLevelRaw = proposedLevelRaw
        self.possibleWordIdsRaw = possibleWordIdsRaw
        self.payloadJSON = payloadJSON
        self.formatVersion = formatVersion
    }

    public func validatePayloadFormatVersion() throws {
        guard formatVersion == Self.currentFormatVersion else {
            throw PracticePayloadError.unsupportedFormatVersion(
                recordType: "PracticePresentationRecord",
                found: formatVersion,
                supported: Self.currentFormatVersion
            )
        }
    }
}

public final class WordUseEvidenceRecord: @unchecked Sendable {
    public static let currentFormatVersion: Int = 1

    public var id: UUID
    public var sessionId: UUID
    public var turnId: UUID
    public var wordId: Int64
    public var objectiveId: String
    public var usageVerdictRaw: String
    public var intentVerdictRaw: String
    public var transcriptReliabilityRaw: String
    public var inputModeRaw: String
    public var statusRaw: String
    public var primed: Bool
    public var timestamp: Date
    public var payloadJSON: Data
    public var formatVersion: Int

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        turnId: UUID,
        wordId: Int64,
        objectiveId: String,
        usageVerdictRaw: String,
        intentVerdictRaw: String,
        transcriptReliabilityRaw: String,
        inputModeRaw: String,
        statusRaw: String,
        primed: Bool = false,
        timestamp: Date = Date(),
        payloadJSON: Data = Data(),
        formatVersion: Int = WordUseEvidenceRecord.currentFormatVersion
    ) {
        self.id = id
        self.sessionId = sessionId
        self.turnId = turnId
        self.wordId = wordId
        self.objectiveId = objectiveId
        self.usageVerdictRaw = usageVerdictRaw
        self.intentVerdictRaw = intentVerdictRaw
        self.transcriptReliabilityRaw = transcriptReliabilityRaw
        self.inputModeRaw = inputModeRaw
        self.statusRaw = statusRaw
        self.primed = primed
        self.timestamp = timestamp
        self.payloadJSON = payloadJSON
        self.formatVersion = formatVersion
    }

    public func validatePayloadFormatVersion() throws {
        guard formatVersion == Self.currentFormatVersion else {
            throw PracticePayloadError.unsupportedFormatVersion(
                recordType: "WordUseEvidenceRecord",
                found: formatVersion,
                supported: Self.currentFormatVersion
            )
        }
    }
}

public final class CommunicationProgressRecord: @unchecked Sendable {
    public static let currentFormatVersion: Int = 1

    public var logicalKey: String
    public var wordId: Int64
    public var inputModeRaw: String
    public var stageRaw: String
    public var lastIndependentUseAt: Date?
    public var nextPracticeAt: Date?
    public var policyVersion: Int
    public var payloadJSON: Data
    public var formatVersion: Int

    public init(
        logicalKey: String? = nil,
        wordId: Int64,
        inputModeRaw: String,
        stageRaw: String,
        lastIndependentUseAt: Date? = nil,
        nextPracticeAt: Date? = nil,
        policyVersion: Int = 1,
        payloadJSON: Data = Data(),
        formatVersion: Int = CommunicationProgressRecord.currentFormatVersion
    ) {
        self.logicalKey = logicalKey ?? "\(wordId)_\(inputModeRaw)"
        self.wordId = wordId
        self.inputModeRaw = inputModeRaw
        self.stageRaw = stageRaw
        self.lastIndependentUseAt = lastIndependentUseAt
        self.nextPracticeAt = nextPracticeAt
        self.policyVersion = policyVersion
        self.payloadJSON = payloadJSON
        self.formatVersion = formatVersion
    }

    public func validatePayloadFormatVersion() throws {
        guard formatVersion == Self.currentFormatVersion else {
            throw PracticePayloadError.unsupportedFormatVersion(
                recordType: "CommunicationProgressRecord",
                found: formatVersion,
                supported: Self.currentFormatVersion
            )
        }
    }
}
#endif

#if !(canImport(SwiftDataMacros) || canImport(SwiftData))
extension UserStageProgress {
    public func toData() -> UserStageProgressData {
        UserStageProgressData(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: score,
            progressFraction: progressFraction,
            completedAt: completedAt
        )
    }
}
#endif
