import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData

/// Pure mapping and serialization layer translating between SwiftData SchemaV3 records and domain value types.
public enum PracticeRecordMapper {
    private static var encoder: JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }

    private static var decoder: JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }

    // MARK: - Logical Key Generation

    public static func logicalKey(wordId: Int64, mode: PracticeInputMode) -> String {
        "\(wordId)_\(mode.rawValue)"
    }

    public static func evidenceLogicalKey(sessionId: UUID, turnId: UUID, wordId: Int64, assessmentVersion: Int) -> String {
        "\(sessionId.uuidString)_\(turnId.uuidString)_\(wordId)_\(assessmentVersion)"
    }

    // MARK: - Payloads

    struct SessionPayload: Codable {
        let missionSnapshot: PracticeMission
        let checkpoint: PracticeCheckpoint
    }

    struct TurnPayload: Codable {
        let originalText: String
        let acceptedText: String
        let transcriptStatus: PracticeTranscriptStatus
        let generationStatus: PracticeGenerationStatus
        let requestId: String
    }

    struct ExposurePayload: Codable {
        let wordIds: [Int64]
        let contentSnapshot: String
    }

    struct PresentationPayload: Codable {
        let content: String
        let possibleWordIds: [Int64]
    }

    struct EvidencePayload: Codable {
        let supportExposureIds: [UUID]
        let contextFamily: PracticeContextFamily
        let quotedSpan: String?
        let assessmentVersion: Int
        let providerIdentity: String
        let turnRevision: Int
        let opportunityId: String?
    }

    struct ProgressPayload: Codable {
        let independentEvidenceIds: [UUID]
        let recentOutcome: PracticeOpportunityOutcome?
    }

    // MARK: - PracticeSession Mapping

    public static func toRecord(_ session: PracticeSession) throws -> SchemaV3.PracticeSessionRecord {
        let payload = SessionPayload(missionSnapshot: session.missionSnapshot, checkpoint: session.checkpoint)
        let data = try encoder.encode(payload)
        return SchemaV3.PracticeSessionRecord(
            id: session.id,
            revision: session.revision,
            statusRaw: session.status.rawValue,
            initialInputModeRaw: session.initialInputMode.rawValue,
            policyVersion: session.policyVersion,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            payloadJSON: data,
            formatVersion: SchemaV3.PracticeSessionRecord.currentFormatVersion
        )
    }

    public static func updateRecord(_ record: SchemaV3.PracticeSessionRecord, from session: PracticeSession) throws {
        let payload = SessionPayload(missionSnapshot: session.missionSnapshot, checkpoint: session.checkpoint)
        record.revision = session.revision
        record.statusRaw = session.status.rawValue
        record.initialInputModeRaw = session.initialInputMode.rawValue
        record.policyVersion = session.policyVersion
        record.completedAt = session.completedAt
        record.payloadJSON = try encoder.encode(payload)
    }

    public static func toDomain(_ record: SchemaV3.PracticeSessionRecord) throws -> PracticeSession {
        try record.validatePayloadFormatVersion()
        let payload: SessionPayload
        do {
            payload = try decoder.decode(SessionPayload.self, from: record.payloadJSON)
        } catch {
            throw PracticeFailure(code: .schema, message: "Invalid session payload for id \(record.id): \(error)")
        }
        let status = PracticeSessionStatus(rawValue: record.statusRaw) ?? .inProgress
        let inputMode = PracticeInputMode(rawValue: record.initialInputModeRaw) ?? .voice
        return PracticeSession(
            id: record.id,
            missionSnapshot: payload.missionSnapshot,
            status: status,
            startedAt: record.startedAt,
            completedAt: record.completedAt,
            checkpoint: payload.checkpoint,
            revision: record.revision,
            initialInputMode: inputMode,
            policyVersion: record.policyVersion
        )
    }

    // MARK: - PracticeTurn Mapping

    public static func toRecord(_ turn: PracticeTurn) throws -> SchemaV3.PracticeTurnRecord {
        let payload = TurnPayload(
            originalText: turn.originalText,
            acceptedText: turn.acceptedText,
            transcriptStatus: turn.transcriptStatus,
            generationStatus: turn.generationStatus,
            requestId: turn.requestId
        )
        let data = try encoder.encode(payload)
        return SchemaV3.PracticeTurnRecord(
            id: turn.id,
            sessionId: turn.sessionId,
            sequence: turn.sequence,
            speakerRaw: turn.speaker.rawValue,
            inputModeRaw: turn.inputMode.rawValue,
            sessionRevision: turn.sessionRevision,
            timestamp: turn.timestamp,
            payloadJSON: data,
            formatVersion: SchemaV3.PracticeTurnRecord.currentFormatVersion
        )
    }

    public static func updateRecord(_ record: SchemaV3.PracticeTurnRecord, from turn: PracticeTurn) throws {
        let payload = TurnPayload(
            originalText: turn.originalText,
            acceptedText: turn.acceptedText,
            transcriptStatus: turn.transcriptStatus,
            generationStatus: turn.generationStatus,
            requestId: turn.requestId
        )
        record.sequence = turn.sequence
        record.speakerRaw = turn.speaker.rawValue
        record.inputModeRaw = turn.inputMode.rawValue
        record.sessionRevision = turn.sessionRevision
        record.timestamp = turn.timestamp
        record.payloadJSON = try encoder.encode(payload)
    }

    public static func toDomain(_ record: SchemaV3.PracticeTurnRecord) throws -> PracticeTurn {
        try record.validatePayloadFormatVersion()
        let payload: TurnPayload
        do {
            payload = try decoder.decode(TurnPayload.self, from: record.payloadJSON)
        } catch {
            throw PracticeFailure(code: .schema, message: "Invalid turn payload for id \(record.id): \(error)")
        }
        let speaker = PracticeSpeaker(rawValue: record.speakerRaw) ?? .learner
        let inputMode = PracticeInputMode(rawValue: record.inputModeRaw) ?? .voice
        return PracticeTurn(
            id: record.id,
            sessionId: record.sessionId,
            sequence: record.sequence,
            speaker: speaker,
            inputMode: inputMode,
            originalText: payload.originalText,
            acceptedText: payload.acceptedText,
            transcriptStatus: payload.transcriptStatus,
            generationStatus: payload.generationStatus,
            requestId: payload.requestId,
            sessionRevision: record.sessionRevision,
            timestamp: record.timestamp
        )
    }

    // MARK: - SupportExposure Mapping

    public static func toRecord(_ exposure: SupportExposure) throws -> SchemaV3.SupportExposureRecord {
        let payload = ExposurePayload(wordIds: exposure.wordIds, contentSnapshot: exposure.contentSnapshot)
        let data = try encoder.encode(payload)
        let targetWordIdsRaw = exposure.wordIds.map(String.init).joined(separator: ",")
        return SchemaV3.SupportExposureRecord(
            id: exposure.id,
            sessionId: exposure.sessionId,
            turnId: exposure.turnId,
            targetWordIdsRaw: targetWordIdsRaw,
            levelRaw: exposure.level.rawValue,
            originRaw: exposure.origin.rawValue,
            channelRaw: exposure.channel.rawValue,
            presentedAt: exposure.presentedAt,
            payloadJSON: data,
            formatVersion: SchemaV3.SupportExposureRecord.currentFormatVersion
        )
    }

    public static func toDomain(_ record: SchemaV3.SupportExposureRecord) throws -> SupportExposure {
        try record.validatePayloadFormatVersion()
        let payload: ExposurePayload
        do {
            payload = try decoder.decode(ExposurePayload.self, from: record.payloadJSON)
        } catch {
            throw PracticeFailure(code: .schema, message: "Invalid exposure payload for id \(record.id): \(error)")
        }
        let level = PracticeSupportLevel(rawValue: record.levelRaw) ?? .none
        let origin = SupportOrigin(rawValue: record.originRaw) ?? .coachSuggested
        let channel = PracticePresentationChannel(rawValue: record.channelRaw) ?? .visual
        return SupportExposure(
            id: record.id,
            sessionId: record.sessionId,
            turnId: record.turnId,
            wordIds: payload.wordIds,
            level: level,
            origin: origin,
            contentSnapshot: payload.contentSnapshot,
            presentedAt: record.presentedAt,
            channel: channel
        )
    }

    // MARK: - PracticePresentation Mapping

    public static func toRecord(_ intent: PracticePresentationIntent) throws -> SchemaV3.PracticePresentationRecord {
        let payload = PresentationPayload(content: intent.content, possibleWordIds: intent.possibleWordIds)
        let data = try encoder.encode(payload)
        let possibleWordIdsRaw = intent.possibleWordIds.map(String.init).joined(separator: ",")
        return SchemaV3.PracticePresentationRecord(
            id: intent.id,
            sessionId: intent.sessionId,
            turnId: intent.turnId,
            statusRaw: intent.status.rawValue,
            channelRaw: intent.channel.rawValue,
            proposedLevelRaw: intent.proposedLevel.rawValue,
            possibleWordIdsRaw: possibleWordIdsRaw,
            payloadJSON: data,
            formatVersion: SchemaV3.PracticePresentationRecord.currentFormatVersion
        )
    }

    public static func updateRecord(_ record: SchemaV3.PracticePresentationRecord, from intent: PracticePresentationIntent) throws {
        let payload = PresentationPayload(content: intent.content, possibleWordIds: intent.possibleWordIds)
        record.turnId = intent.turnId
        record.statusRaw = intent.status.rawValue
        record.channelRaw = intent.channel.rawValue
        record.proposedLevelRaw = intent.proposedLevel.rawValue
        record.possibleWordIdsRaw = intent.possibleWordIds.map(String.init).joined(separator: ",")
        record.payloadJSON = try encoder.encode(payload)
    }

    public static func toDomain(_ record: SchemaV3.PracticePresentationRecord) throws -> PracticePresentationIntent {
        try record.validatePayloadFormatVersion()
        let payload: PresentationPayload
        do {
            payload = try decoder.decode(PresentationPayload.self, from: record.payloadJSON)
        } catch {
            throw PracticeFailure(code: .schema, message: "Invalid presentation payload for id \(record.id): \(error)")
        }
        let status = PracticePresentationStatus(rawValue: record.statusRaw) ?? .pending
        let channel = PracticePresentationChannel(rawValue: record.channelRaw) ?? .visual
        let proposedLevel = PracticeSupportLevel(rawValue: record.proposedLevelRaw) ?? .none
        return PracticePresentationIntent(
            id: record.id,
            sessionId: record.sessionId,
            turnId: record.turnId,
            content: payload.content,
            channel: channel,
            possibleWordIds: payload.possibleWordIds,
            proposedLevel: proposedLevel,
            status: status
        )
    }

    // MARK: - WordUseEvidence Mapping

    public static func toRecord(_ evidence: WordUseEvidence) throws -> SchemaV3.WordUseEvidenceRecord {
        let payload = EvidencePayload(
            supportExposureIds: evidence.supportExposureIds,
            contextFamily: evidence.contextFamily,
            quotedSpan: evidence.quotedSpan,
            assessmentVersion: evidence.assessmentVersion,
            providerIdentity: evidence.providerIdentity,
            turnRevision: evidence.turnRevision,
            opportunityId: evidence.opportunityId
        )
        let data = try encoder.encode(payload)
        return SchemaV3.WordUseEvidenceRecord(
            id: evidence.id,
            sessionId: evidence.sessionId,
            turnId: evidence.turnId,
            wordId: evidence.wordId,
            objectiveId: evidence.objectiveId,
            usageVerdictRaw: evidence.usageVerdict.rawValue,
            intentVerdictRaw: evidence.intentVerdict.rawValue,
            transcriptReliabilityRaw: evidence.transcriptReliability.rawValue,
            inputModeRaw: evidence.inputMode.rawValue,
            statusRaw: evidence.status.rawValue,
            primed: evidence.primed,
            timestamp: evidence.timestamp,
            payloadJSON: data,
            formatVersion: SchemaV3.WordUseEvidenceRecord.currentFormatVersion
        )
    }

    public static func updateRecord(_ record: SchemaV3.WordUseEvidenceRecord, from evidence: WordUseEvidence) throws {
        let payload = EvidencePayload(
            supportExposureIds: evidence.supportExposureIds,
            contextFamily: evidence.contextFamily,
            quotedSpan: evidence.quotedSpan,
            assessmentVersion: evidence.assessmentVersion,
            providerIdentity: evidence.providerIdentity,
            turnRevision: evidence.turnRevision,
            opportunityId: evidence.opportunityId
        )
        record.usageVerdictRaw = evidence.usageVerdict.rawValue
        record.intentVerdictRaw = evidence.intentVerdict.rawValue
        record.transcriptReliabilityRaw = evidence.transcriptReliability.rawValue
        record.inputModeRaw = evidence.inputMode.rawValue
        record.statusRaw = evidence.status.rawValue
        record.primed = evidence.primed
        record.timestamp = evidence.timestamp
        record.payloadJSON = try encoder.encode(payload)
    }

    public static func toDomain(_ record: SchemaV3.WordUseEvidenceRecord) throws -> WordUseEvidence {
        try record.validatePayloadFormatVersion()
        let payload: EvidencePayload
        do {
            payload = try decoder.decode(EvidencePayload.self, from: record.payloadJSON)
        } catch {
            throw PracticeFailure(code: .schema, message: "Invalid evidence payload for id \(record.id): \(error)")
        }
        let usage = PracticeUsageVerdict(rawValue: record.usageVerdictRaw) ?? .uncertain
        let intent = PracticeIntentVerdict(rawValue: record.intentVerdictRaw) ?? .uncertain
        let transcript = PracticeTranscriptReliability(rawValue: record.transcriptReliabilityRaw) ?? .usable
        let inputMode = PracticeInputMode(rawValue: record.inputModeRaw) ?? .voice
        let status = PracticeEvidenceStatus(rawValue: record.statusRaw) ?? .valid
        return WordUseEvidence(
            id: record.id,
            sessionId: record.sessionId,
            turnId: record.turnId,
            wordId: record.wordId,
            objectiveId: record.objectiveId,
            usageVerdict: usage,
            intentVerdict: intent,
            transcriptReliability: transcript,
            supportExposureIds: payload.supportExposureIds,
            primed: record.primed,
            contextFamily: payload.contextFamily,
            inputMode: inputMode,
            quotedSpan: payload.quotedSpan,
            assessmentVersion: payload.assessmentVersion,
            providerIdentity: payload.providerIdentity,
            status: status,
            timestamp: record.timestamp,
            turnRevision: payload.turnRevision,
            opportunityId: payload.opportunityId
        )
    }

    // MARK: - CommunicationProgress Mapping

    public static func toRecord(_ progress: CommunicationProgress) throws -> SchemaV3.CommunicationProgressRecord {
        let payload = ProgressPayload(
            independentEvidenceIds: progress.independentEvidenceIds,
            recentOutcome: progress.recentOutcome
        )
        let data = try encoder.encode(payload)
        let key = logicalKey(wordId: progress.wordId, mode: progress.inputMode)
        return SchemaV3.CommunicationProgressRecord(
            logicalKey: key,
            wordId: progress.wordId,
            inputModeRaw: progress.inputMode.rawValue,
            stageRaw: progress.stage.rawValue,
            lastIndependentUseAt: progress.lastIndependentUseAt,
            nextPracticeAt: progress.nextPracticeAt,
            policyVersion: progress.policyVersion,
            payloadJSON: data,
            formatVersion: SchemaV3.CommunicationProgressRecord.currentFormatVersion
        )
    }

    public static func updateRecord(_ record: SchemaV3.CommunicationProgressRecord, from progress: CommunicationProgress) throws {
        let payload = ProgressPayload(
            independentEvidenceIds: progress.independentEvidenceIds,
            recentOutcome: progress.recentOutcome
        )
        record.stageRaw = progress.stage.rawValue
        record.lastIndependentUseAt = progress.lastIndependentUseAt
        record.nextPracticeAt = progress.nextPracticeAt
        record.policyVersion = progress.policyVersion
        record.payloadJSON = try encoder.encode(payload)
    }

    public static func toDomain(_ record: SchemaV3.CommunicationProgressRecord) throws -> CommunicationProgress {
        try record.validatePayloadFormatVersion()
        let payload: ProgressPayload
        do {
            payload = try decoder.decode(ProgressPayload.self, from: record.payloadJSON)
        } catch {
            throw PracticeFailure(code: .schema, message: "Invalid progress payload for key \(record.logicalKey): \(error)")
        }
        let inputMode = PracticeInputMode(rawValue: record.inputModeRaw) ?? .voice
        let stage = CommunicationStage(rawValue: record.stageRaw) ?? .noEvidence
        return CommunicationProgress(
            wordId: record.wordId,
            inputMode: inputMode,
            stage: stage,
            independentEvidenceIds: payload.independentEvidenceIds,
            lastIndependentUseAt: record.lastIndependentUseAt,
            nextPracticeAt: record.nextPracticeAt,
            recentOutcome: payload.recentOutcome,
            policyVersion: record.policyVersion
        )
    }
}
#endif
