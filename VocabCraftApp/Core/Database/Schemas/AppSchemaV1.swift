import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftDataMacros)
public enum SchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            SchemaV1.UserWordProgress.self,
            SchemaV1.ReflexSessionLog.self,
            SchemaV1.WidgetCurrentState.self
        ]
    }

    @Model
    public final class UserWordProgress {
        @Attribute(.unique) public var wordId: Int64
        public var repetitionLevel: Int
        public var interval: Double
        public var easeFactor: Double
        public var nextReviewDate: Date
        public var isBookmarked: Bool
        public var isMastered: Bool
        public var correctStreak: Int
        public var mistakeCount: Int
        public var lastReviewedAt: Date?
        public var modeSuccessCountsRaw: String = "{}"

        public init(
            wordId: Int64,
            repetitionLevel: Int = 0,
            interval: Double = 0,
            easeFactor: Double = 2.5,
            nextReviewDate: Date = Date(),
            isBookmarked: Bool = false,
            isMastered: Bool = false,
            correctStreak: Int = 0,
            mistakeCount: Int = 0,
            lastReviewedAt: Date? = nil,
            modeSuccessCountsRaw: String = "{}"
        ) {
            self.wordId = wordId
            self.repetitionLevel = repetitionLevel
            self.interval = interval
            self.easeFactor = easeFactor
            self.nextReviewDate = nextReviewDate
            self.isBookmarked = isBookmarked
            self.isMastered = isMastered
            self.correctStreak = correctStreak
            self.mistakeCount = mistakeCount
            self.lastReviewedAt = lastReviewedAt
            self.modeSuccessCountsRaw = modeSuccessCountsRaw
        }
    }

    @Model
    public final class ReflexSessionLog {
        @Attribute(.unique) public var id: UUID
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

    @Model
    public final class WidgetCurrentState {
        @Attribute(.unique) public var id: String
        public var activeWord: String
        public var phonetic: String
        public var meaningVi: String
        public var exampleSentence: String
        public var updatedAt: Date

        public init(
            id: String = "current",
            activeWord: String,
            phonetic: String,
            meaningVi: String,
            exampleSentence: String,
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.activeWord = activeWord
            self.phonetic = phonetic
            self.meaningVi = meaningVi
            self.exampleSentence = exampleSentence
            self.updatedAt = updatedAt
        }
    }
}
#endif
