import Foundation
import SwiftData

public enum SchemaV4: VersionedSchema {
    public static let versionIdentifier = Schema.Version(4, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [UserWordProgress.self, UserStageProgress.self, ReflexSessionLog.self,
         WidgetCurrentState.self, QuickReflexAttemptRecord.self,
         SpeakingSessionRecord.self, SavedPhraseRecord.self]
    }

    public typealias UserWordProgress = SchemaV2.UserWordProgress
    public typealias UserStageProgress = SchemaV2.UserStageProgress
    public typealias ReflexSessionLog = SchemaV2.ReflexSessionLog
    public typealias WidgetCurrentState = SchemaV2.WidgetCurrentState
    public typealias QuickReflexAttemptRecord = SchemaV2.QuickReflexAttemptRecord

    @Model
    public final class SpeakingSessionRecord {
        @Attribute(.unique) public var id: UUID
        public var startedAt: Date
        public var status: String
        public var audioFileName: String?
        public var payload: Data
        public var fluency: Int?
        public var grammar: Int?
        public var vocabulary: Int?
        public var pronunciation: Int?

        public init(
            id: UUID, startedAt: Date, status: String, audioFileName: String?, payload: Data,
            fluency: Int?, grammar: Int?, vocabulary: Int?, pronunciation: Int?
        ) {
            self.id = id
            self.startedAt = startedAt
            self.status = status
            self.audioFileName = audioFileName
            self.payload = payload
            self.fluency = fluency
            self.grammar = grammar
            self.vocabulary = vocabulary
            self.pronunciation = pronunciation
        }
    }

    @Model
    public final class SavedPhraseRecord {
        @Attribute(.unique) public var id: UUID
        public var dedupeKey: String
        public var payload: Data
        public var createdAt: Date

        public init(id: UUID, dedupeKey: String, payload: Data, createdAt: Date) {
            self.id = id
            self.dedupeKey = dedupeKey
            self.payload = payload
            self.createdAt = createdAt
        }
    }
}
