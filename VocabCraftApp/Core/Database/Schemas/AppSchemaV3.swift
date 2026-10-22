import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

/// Typed errors occurring when reading, validating, or deserializing Guided Practice payloads.
public enum PracticePayloadError: Error, LocalizedError, Sendable, Equatable {
    case unsupportedFormatVersion(recordType: String, found: Int, supported: Int)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormatVersion(let recordType, let found, let supported):
            return "Record '\(recordType)' has unsupported format version \(found). Supported version is \(supported)."
        }
    }
}

#if canImport(SwiftDataMacros) || canImport(SwiftData)
public enum SchemaV3: VersionedSchema {
    public static let versionIdentifier = Schema.Version(3, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            SchemaV2.UserWordProgress.self,
            SchemaV2.UserStageProgress.self,
            SchemaV2.ReflexSessionLog.self,
            SchemaV2.WidgetCurrentState.self,
            SchemaV2.QuickReflexAttemptRecord.self,
            SchemaV3.PracticeSessionRecord.self,
            SchemaV3.PracticeTurnRecord.self,
            SchemaV3.SupportExposureRecord.self,
            SchemaV3.PracticePresentationRecord.self,
            SchemaV3.WordUseEvidenceRecord.self,
            SchemaV3.CommunicationProgressRecord.self
        ]
    }

    // Reuse existing persistent models from SchemaV2
    public typealias UserWordProgress = SchemaV2.UserWordProgress
    public typealias UserStageProgress = SchemaV2.UserStageProgress
    public typealias ReflexSessionLog = SchemaV2.ReflexSessionLog
    public typealias WidgetCurrentState = SchemaV2.WidgetCurrentState
    public typealias QuickReflexAttemptRecord = SchemaV2.QuickReflexAttemptRecord

    // MARK: - Guided Practice Storage Models

    @Model
    public final class PracticeSessionRecord {
        public static let currentFormatVersion: Int = 1

        @Attribute(.unique) public var id: UUID
        public var revision: Int = 1
        public var statusRaw: String = ""
        public var initialInputModeRaw: String = ""
        public var policyVersion: Int = 1
        public var startedAt: Date = Date()
        public var completedAt: Date?
        public var payloadJSON: Data = Data()
        public var formatVersion: Int = 1

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

    @Model
    public final class PracticeTurnRecord {
        public static let currentFormatVersion: Int = 1

        @Attribute(.unique) public var id: UUID
        public var sessionId: UUID = UUID()
        public var sequence: Int = 0
        public var speakerRaw: String = ""
        public var inputModeRaw: String = ""
        public var sessionRevision: Int = 1
        public var timestamp: Date = Date()
        public var payloadJSON: Data = Data()
        public var formatVersion: Int = 1

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

    @Model
    public final class SupportExposureRecord {
        public static let currentFormatVersion: Int = 1

        @Attribute(.unique) public var id: UUID
        public var sessionId: UUID = UUID()
        public var turnId: UUID?
        public var targetWordIdsRaw: String = ""
        public var levelRaw: String = ""
        public var originRaw: String = ""
        public var channelRaw: String = ""
        public var presentedAt: Date = Date()
        public var payloadJSON: Data = Data()
        public var formatVersion: Int = 1

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

    @Model
    public final class PracticePresentationRecord {
        public static let currentFormatVersion: Int = 1

        @Attribute(.unique) public var id: UUID
        public var sessionId: UUID = UUID()
        public var turnId: UUID?
        public var statusRaw: String = ""
        public var channelRaw: String = ""
        public var proposedLevelRaw: String = ""
        public var possibleWordIdsRaw: String = ""
        public var payloadJSON: Data = Data()
        public var formatVersion: Int = 1

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

    @Model
    public final class WordUseEvidenceRecord {
        public static let currentFormatVersion: Int = 1

        @Attribute(.unique) public var id: UUID
        public var sessionId: UUID = UUID()
        public var turnId: UUID = UUID()
        public var wordId: Int64 = 0
        public var objectiveId: String = ""
        public var usageVerdictRaw: String = ""
        public var intentVerdictRaw: String = ""
        public var transcriptReliabilityRaw: String = ""
        public var inputModeRaw: String = ""
        public var statusRaw: String = ""
        public var primed: Bool = false
        public var timestamp: Date = Date()
        public var payloadJSON: Data = Data()
        public var formatVersion: Int = 1

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

    @Model
    public final class CommunicationProgressRecord {
        public static let currentFormatVersion: Int = 1

        @Attribute(.unique) public var logicalKey: String
        public var wordId: Int64 = 0
        public var inputModeRaw: String = ""
        public var stageRaw: String = ""
        public var lastIndependentUseAt: Date?
        public var nextPracticeAt: Date?
        public var policyVersion: Int = 1
        public var payloadJSON: Data = Data()
        public var formatVersion: Int = 1

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
}
#endif
