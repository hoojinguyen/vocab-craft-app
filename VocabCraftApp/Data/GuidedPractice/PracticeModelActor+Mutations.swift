import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData

// MARK: - Mutations Extension

extension PracticeModelActor {
    // MARK: - Save Pending Turn

    public func savePendingTurn(_ turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int) throws {
        try performTransaction {
            guard let sessionRecord = try findSessionRecord(id: turn.sessionId) else {
                throw PracticeFailure(code: .storage, message: "Session \(turn.sessionId) not found")
            }
            guard sessionRecord.revision == expectedRevision else {
                throw PracticeFailure(
                    code: .staleRevision,
                    message: "Revision mismatch. Expected \(expectedRevision), current is \(sessionRecord.revision)"
                )
            }

            var turnDesc = FetchDescriptor<SchemaV3.PracticeTurnRecord>(
                predicate: #Predicate { $0.id == turn.id }
            )
            turnDesc.fetchLimit = 1
            if let existing = try modelContext.fetch(turnDesc).first {
                try PracticeRecordMapper.updateRecord(existing, from: turn)
            } else {
                let record = try PracticeRecordMapper.toRecord(turn)
                modelContext.insert(record)
            }

            var session = try PracticeRecordMapper.toDomain(sessionRecord)
            session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: checkpoint,
                revision: session.revision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
            try PracticeRecordMapper.updateRecord(sessionRecord, from: session)
        }
    }

    // MARK: - Commit Transaction

    public func commit(_ value: PracticeCommit) throws -> PracticeSessionSnapshot {
        try performTransaction {
            guard let sessionRecord = try findSessionRecord(id: value.sessionId) else {
                throw PracticeFailure(code: .storage, message: "Session \(value.sessionId) not found")
            }
            guard sessionRecord.revision == value.expectedRevision else {
                throw PracticeFailure(
                    code: .staleRevision,
                    message: "Revision mismatch. Expected \(value.expectedRevision), current is \(sessionRecord.revision)"
                )
            }

            try saveTurnIfPresent(value.turn)
            var affectedWordIds = try processEvidenceDeduplication(value.assessment?.evidence ?? [])

            let sessionDomain = try PracticeRecordMapper.toDomain(sessionRecord)
            for wordId in sessionDomain.missionSnapshot.targetWordIds {
                affectedWordIds.insert(wordId)
            }

            let updatedSession = PracticeSession(
                id: sessionDomain.id,
                missionSnapshot: sessionDomain.missionSnapshot,
                status: sessionDomain.status,
                startedAt: sessionDomain.startedAt,
                completedAt: sessionDomain.completedAt,
                checkpoint: value.checkpoint,
                revision: sessionDomain.revision,
                initialInputMode: sessionDomain.initialInputMode,
                policyVersion: sessionDomain.policyVersion
            )
            try PracticeRecordMapper.updateRecord(sessionRecord, from: updatedSession)

            try rebuildProgress(for: affectedWordIds)
        }

        guard let snapshot = try loadSession(id: value.sessionId) else {
            throw PracticeFailure(code: .storage, message: "Failed to reload session after commit")
        }
        return snapshot
    }

    private func saveTurnIfPresent(_ turn: PracticeTurn?) throws {
        guard let turn else { return }
        var turnDesc = FetchDescriptor<SchemaV3.PracticeTurnRecord>(
            predicate: #Predicate { $0.id == turn.id }
        )
        turnDesc.fetchLimit = 1
        if let existing = try modelContext.fetch(turnDesc).first {
            try PracticeRecordMapper.updateRecord(existing, from: turn)
        } else {
            let record = try PracticeRecordMapper.toRecord(turn)
            modelContext.insert(record)
        }
    }

    private func processEvidenceDeduplication(_ evidenceList: [WordUseEvidence]) throws -> Set<Int64> {
        var affectedWordIds = Set<Int64>()
        for item in evidenceList {
            affectedWordIds.insert(item.wordId)
            let sessionId = item.sessionId
            let wordId = item.wordId

            let evDesc = FetchDescriptor<SchemaV3.WordUseEvidenceRecord>(
                predicate: #Predicate { $0.sessionId == sessionId && $0.wordId == wordId }
            )
            let existingRecords = try modelContext.fetch(evDesc)

            var isDuplicate = false
            for rec in existingRecords {
                if rec.id == item.id {
                    isDuplicate = true
                    break
                }
                if let domain = try? PracticeRecordMapper.toDomain(rec) {
                    if domain.turnId == item.turnId &&
                        domain.assessmentVersion == item.assessmentVersion &&
                        domain.turnRevision == item.turnRevision {
                        isDuplicate = true
                        break
                    }
                }
            }
            if isDuplicate {
                continue
            }

            for rec in existingRecords where rec.statusRaw == PracticeEvidenceStatus.valid.rawValue {
                guard let domain = try? PracticeRecordMapper.toDomain(rec) else { continue }
                guard domain.turnId == item.turnId else { continue }

                if domain.turnRevision < item.turnRevision {
                    rec.statusRaw = PracticeEvidenceStatus.superseded.rawValue
                } else if domain.turnRevision == item.turnRevision && domain.assessmentVersion < item.assessmentVersion {
                    rec.statusRaw = PracticeEvidenceStatus.superseded.rawValue
                }
            }

            let newRecord = try PracticeRecordMapper.toRecord(item)
            modelContext.insert(newRecord)
        }
        return affectedWordIds
    }

    // MARK: - Presentation Workflow

    public func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) throws {
        try performTransaction {
            guard let sessionRecord = try findSessionRecord(id: intent.sessionId) else {
                throw PracticeFailure(code: .storage, message: "Session \(intent.sessionId) not found")
            }
            guard sessionRecord.revision == expectedRevision else {
                throw PracticeFailure(
                    code: .staleRevision,
                    message: "Revision mismatch. Expected \(expectedRevision), current is \(sessionRecord.revision)"
                )
            }

            var presDesc = FetchDescriptor<SchemaV3.PracticePresentationRecord>(
                predicate: #Predicate { $0.id == intent.id }
            )
            presDesc.fetchLimit = 1
            if let existing = try modelContext.fetch(presDesc).first {
                try PracticeRecordMapper.updateRecord(existing, from: intent)
            } else {
                let record = try PracticeRecordMapper.toRecord(intent)
                modelContext.insert(record)
            }

            var session = try PracticeRecordMapper.toDomain(sessionRecord)
            var intents = session.checkpoint.presentationIntents.filter { $0.id != intent.id }
            intents.append(intent)
            let newCheckpoint = PracticeCheckpoint(
                pendingTurnId: session.checkpoint.pendingTurnId,
                requestId: session.checkpoint.requestId,
                presentationIntents: intents,
                exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
                currentSupportLevel: session.checkpoint.currentSupportLevel,
                objectiveResults: session.checkpoint.objectiveResults,
                difficultyOutcomes: session.checkpoint.difficultyOutcomes
            )
            session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: newCheckpoint,
                revision: session.revision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
            try PracticeRecordMapper.updateRecord(sessionRecord, from: session)
        }
    }

    public func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) throws {
        try performTransaction {
            guard let sessionRecord = try findSessionRecord(id: exposure.sessionId) else {
                throw PracticeFailure(code: .storage, message: "Session \(exposure.sessionId) not found")
            }
            guard sessionRecord.revision == expectedRevision else {
                throw PracticeFailure(
                    code: .staleRevision,
                    message: "Revision mismatch. Expected \(expectedRevision), current is \(sessionRecord.revision)"
                )
            }

            var presDesc = FetchDescriptor<SchemaV3.PracticePresentationRecord>(
                predicate: #Predicate { $0.id == id }
            )
            presDesc.fetchLimit = 1
            if let presRecord = try modelContext.fetch(presDesc).first {
                presRecord.statusRaw = PracticePresentationStatus.confirmed.rawValue
            }

            var expDesc = FetchDescriptor<SchemaV3.SupportExposureRecord>(
                predicate: #Predicate { $0.id == exposure.id }
            )
            expDesc.fetchLimit = 1
            if try modelContext.fetch(expDesc).first == nil {
                let expRecord = try PracticeRecordMapper.toRecord(exposure)
                modelContext.insert(expRecord)
            }

            var session = try PracticeRecordMapper.toDomain(sessionRecord)
            let updatedIntents = session.checkpoint.presentationIntents.map { item in
                if item.id == id {
                    return PracticePresentationIntent(
                        id: item.id,
                        sessionId: item.sessionId,
                        turnId: item.turnId,
                        content: item.content,
                        channel: item.channel,
                        possibleWordIds: item.possibleWordIds,
                        proposedLevel: item.proposedLevel,
                        status: .confirmed
                    )
                }
                return item
            }
            let newCheckpoint = PracticeCheckpoint(
                pendingTurnId: session.checkpoint.pendingTurnId,
                requestId: session.checkpoint.requestId,
                presentationIntents: updatedIntents,
                exposureUncertainWordIds: session.checkpoint.exposureUncertainWordIds,
                currentSupportLevel: session.checkpoint.currentSupportLevel,
                objectiveResults: session.checkpoint.objectiveResults,
                difficultyOutcomes: session.checkpoint.difficultyOutcomes
            )
            session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: newCheckpoint,
                revision: session.revision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
            try PracticeRecordMapper.updateRecord(sessionRecord, from: session)
        }
    }

    // MARK: - Revision & Finalization

    public func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) throws -> Int {
        try performTransaction {
            guard let sessionRecord = try findSessionRecord(id: sessionId) else {
                throw PracticeFailure(code: .storage, message: "Session \(sessionId) not found")
            }
            guard sessionRecord.revision == expectedRevision else {
                throw PracticeFailure(
                    code: .staleRevision,
                    message: "Revision mismatch. Expected \(expectedRevision), current is \(sessionRecord.revision)"
                )
            }

            let newRevision = expectedRevision + 1
            var session = try PracticeRecordMapper.toDomain(sessionRecord)
            session = PracticeSession(
                id: session.id,
                missionSnapshot: session.missionSnapshot,
                status: session.status,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                checkpoint: checkpoint,
                revision: newRevision,
                initialInputMode: session.initialInputMode,
                policyVersion: session.policyVersion
            )
            try PracticeRecordMapper.updateRecord(sessionRecord, from: session)
            return newRevision
        }
    }

    public func finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) throws -> PracticeSummary {
        try performTransaction {
            guard let sessionRecord = try findSessionRecord(id: sessionId) else {
                throw PracticeFailure(code: .storage, message: "Session \(sessionId) not found")
            }
            guard sessionRecord.revision == expectedRevision else {
                throw PracticeFailure(
                    code: .staleRevision,
                    message: "Revision mismatch. Expected \(expectedRevision), current is \(sessionRecord.revision)"
                )
            }

            let newStatus: PracticeSessionStatus = (completion == .completed) ? .completed : .partial
            sessionRecord.statusRaw = newStatus.rawValue
            if sessionRecord.completedAt == nil {
                sessionRecord.completedAt = Date()
            }
        }

        guard let snapshot = try loadSession(id: sessionId) else {
            throw PracticeFailure(code: .storage, message: "Session \(sessionId) missing after finalize")
        }

        let summaryStatus: PracticeSessionStatus = (completion == .completed) ? .completed : .partial
        return PracticeSummary(
            sessionId: sessionId,
            status: summaryStatus,
            objectiveResults: snapshot.session.checkpoint.objectiveResults,
            perWordProgress: snapshot.progress,
            evidenceIds: snapshot.evidence.map(\.id),
            persisted: true
        )
    }

    // MARK: - Deletion & Rebuild

    public func deleteSession(id: UUID) throws {
        try performTransaction {
            guard let sessionRecord = try findSessionRecord(id: id) else {
                return
            }
            let session = try PracticeRecordMapper.toDomain(sessionRecord)
            var affectedWordIds = Set(session.missionSnapshot.targetWordIds)

            let evDesc = FetchDescriptor<SchemaV3.WordUseEvidenceRecord>(
                predicate: #Predicate { $0.sessionId == id }
            )
            let evRecords = try modelContext.fetch(evDesc)
            for evidenceRecord in evRecords {
                affectedWordIds.insert(evidenceRecord.wordId)
                modelContext.delete(evidenceRecord)
            }

            let turnDesc = FetchDescriptor<SchemaV3.PracticeTurnRecord>(
                predicate: #Predicate { $0.sessionId == id }
            )
            let turns = try modelContext.fetch(turnDesc)
            for turn in turns { modelContext.delete(turn) }

            let expDesc = FetchDescriptor<SchemaV3.SupportExposureRecord>(
                predicate: #Predicate { $0.sessionId == id }
            )
            let exposures = try modelContext.fetch(expDesc)
            for exposure in exposures { modelContext.delete(exposure) }

            let presDesc = FetchDescriptor<SchemaV3.PracticePresentationRecord>(
                predicate: #Predicate { $0.sessionId == id }
            )
            let presentations = try modelContext.fetch(presDesc)
            for presentation in presentations { modelContext.delete(presentation) }

            modelContext.delete(sessionRecord)

            try rebuildProgress(for: affectedWordIds)
        }
    }

    public func deleteAllPractice() throws {
        try performTransaction {
            try modelContext.delete(model: SchemaV3.PracticeSessionRecord.self)
            try modelContext.delete(model: SchemaV3.PracticeTurnRecord.self)
            try modelContext.delete(model: SchemaV3.SupportExposureRecord.self)
            try modelContext.delete(model: SchemaV3.PracticePresentationRecord.self)
            try modelContext.delete(model: SchemaV3.WordUseEvidenceRecord.self)
            try modelContext.delete(model: SchemaV3.CommunicationProgressRecord.self)
        }
    }

    public func resetAllLearningProgress() throws {
        try performTransaction {
            try modelContext.delete(model: SchemaV3.PracticeSessionRecord.self)
            try modelContext.delete(model: SchemaV3.PracticeTurnRecord.self)
            try modelContext.delete(model: SchemaV3.SupportExposureRecord.self)
            try modelContext.delete(model: SchemaV3.PracticePresentationRecord.self)
            try modelContext.delete(model: SchemaV3.WordUseEvidenceRecord.self)
            try modelContext.delete(model: SchemaV3.CommunicationProgressRecord.self)

            try modelContext.delete(model: SchemaV3.UserWordProgress.self)
            try modelContext.delete(model: SchemaV3.ReflexSessionLog.self)
            try modelContext.delete(model: SchemaV3.QuickReflexAttemptRecord.self)
        }
    }

    // MARK: - Progress Cache Rebuild Engine

    private func rebuildProgress(for wordIds: Set<Int64>) throws {
        let now = Date()
        for wordId in wordIds {
            let desc = FetchDescriptor<SchemaV3.WordUseEvidenceRecord>(
                predicate: #Predicate { $0.wordId == wordId }
            )
            let records = try modelContext.fetch(desc)
            let domainEvidence = try records.map { try PracticeRecordMapper.toDomain($0) }

            let progDesc = FetchDescriptor<SchemaV3.CommunicationProgressRecord>(
                predicate: #Predicate { $0.wordId == wordId }
            )
            let existingProgRecords = try modelContext.fetch(progDesc)

            var modesToRebuild = Set(domainEvidence.map(\.inputMode))
            for progressRecord in existingProgRecords {
                if let mode = PracticeInputMode(rawValue: progressRecord.inputModeRaw) {
                    modesToRebuild.insert(mode)
                }
            }

            if modesToRebuild.isEmpty {
                modesToRebuild.insert(.voice)
            }

            for mode in modesToRebuild {
                let key = PracticeRecordMapper.logicalKey(wordId: wordId, mode: mode)
                let updatedProgress = progressPolicy.rebuild(
                    wordId: wordId,
                    mode: mode,
                    evidence: domainEvidence,
                    now: now
                )

                if let existingRecord = existingProgRecords.first(where: { $0.logicalKey == key }) {
                    try PracticeRecordMapper.updateRecord(existingRecord, from: updatedProgress)
                } else {
                    let newRecord = try PracticeRecordMapper.toRecord(updatedProgress)
                    modelContext.insert(newRecord)
                }
            }
        }
    }
}
#endif
