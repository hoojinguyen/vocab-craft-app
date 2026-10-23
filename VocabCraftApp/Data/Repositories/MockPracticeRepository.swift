import Foundation

/// In-memory mock implementation of `PracticeRepositoryProtocol` for testing, previews, and container fallback.
public actor MockPracticeRepository: PracticeRepositoryProtocol {
    private var sessions: [UUID: PracticeSession] = [:]
    private var turns: [UUID: [PracticeTurn]] = [:]
    private var exposures: [UUID: [SupportExposure]] = [:]
    private var presentations: [UUID: [PracticePresentationIntent]] = [:]
    private var evidenceList: [WordUseEvidence] = []
    private var progressList: [CommunicationProgress] = []

    public init(
        sessions: [PracticeSession] = [],
        turns: [PracticeTurn] = [],
        exposures: [SupportExposure] = [],
        evidence: [WordUseEvidence] = [],
        progress: [CommunicationProgress] = []
    ) {
        for sessionItem in sessions {
            self.sessions[sessionItem.id] = sessionItem
        }
        for turnItem in turns {
            self.turns[turnItem.sessionId, default: []].append(turnItem)
        }
        for exposureItem in exposures {
            self.exposures[exposureItem.sessionId, default: []].append(exposureItem)
        }
        self.evidenceList = evidence
        self.progressList = progress
    }

    public func create(_ session: PracticeSession) async throws {
        sessions[session.id] = session
    }

    public func loadSession(id: UUID) async throws -> PracticeSessionSnapshot? {
        guard let session = sessions[id] else { return nil }
        return PracticeSessionSnapshot(
            session: session,
            turns: turns[id] ?? [],
            exposures: exposures[id] ?? [],
            evidence: evidenceList.filter { $0.sessionId == id },
            progress: progressList,
            pendingPresentations: presentations[id] ?? []
        )
    }

    public func activeSession() async throws -> PracticeSessionSnapshot? {
        guard let session = sessions.values.first(where: { $0.status == .inProgress }) else {
            return nil
        }
        return try await loadSession(id: session.id)
    }

    public func progress() async throws -> [CommunicationProgress] {
        progressList
    }

    public func evidence() async throws -> [WordUseEvidence] {
        evidenceList
    }

    public func savePendingTurn(_ turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int) async throws {
        guard var session = sessions[turn.sessionId] else {
            throw PracticeFailure(code: .storage, message: "Session not found")
        }
        if session.revision != expectedRevision {
            throw PracticeFailure(code: .staleRevision, message: "Mismatched revision")
        }
        var sessionTurns = turns[turn.sessionId] ?? []
        if let idx = sessionTurns.firstIndex(where: { $0.id == turn.id }) {
            sessionTurns[idx] = turn
        } else {
            sessionTurns.append(turn)
        }
        turns[turn.sessionId] = sessionTurns

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
        sessions[turn.sessionId] = session
    }

    public func commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot {
        guard var session = sessions[value.sessionId] else {
            throw PracticeFailure(code: .storage, message: "Session not found")
        }
        if let turn = value.turn {
            var sessionTurns = turns[value.sessionId] ?? []
            if let idx = sessionTurns.firstIndex(where: { $0.id == turn.id }) {
                sessionTurns[idx] = turn
            } else {
                sessionTurns.append(turn)
            }
            turns[value.sessionId] = sessionTurns
        }
        if let assessment = value.assessment {
            evidenceList.append(contentsOf: assessment.evidence)
        }
        session = PracticeSession(
            id: session.id,
            missionSnapshot: session.missionSnapshot,
            status: session.status,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            checkpoint: value.checkpoint,
            revision: session.revision,
            initialInputMode: session.initialInputMode,
            policyVersion: session.policyVersion
        )
        sessions[value.sessionId] = session

        guard let snapshot = try await loadSession(id: value.sessionId) else {
            throw PracticeFailure(code: .storage, message: "Snapshot missing")
        }
        return snapshot
    }

    public func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws {
        presentations[intent.sessionId, default: []].append(intent)
    }

    public func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws {
        presentations[exposure.sessionId]?.removeAll(where: { $0.id == id })
        exposures[exposure.sessionId, default: []].append(exposure)
    }

    public func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int {
        guard var session = sessions[sessionId] else {
            throw PracticeFailure(code: .storage, message: "Session not found")
        }
        let nextRev = expectedRevision + 1
        session = PracticeSession(
            id: session.id,
            missionSnapshot: session.missionSnapshot,
            status: session.status,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            checkpoint: checkpoint,
            revision: nextRev,
            initialInputMode: session.initialInputMode,
            policyVersion: session.policyVersion
        )
        sessions[sessionId] = session
        return nextRev
    }

    public func finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) async throws -> PracticeSummary {
        guard var session = sessions[sessionId] else {
            throw PracticeFailure(code: .storage, message: "Session not found")
        }
        let newStatus: PracticeSessionStatus = completion == .completed ? .completed : .partial
        session = PracticeSession(
            id: session.id,
            missionSnapshot: session.missionSnapshot,
            status: newStatus,
            startedAt: session.startedAt,
            completedAt: Date(),
            checkpoint: session.checkpoint,
            revision: session.revision,
            initialInputMode: session.initialInputMode,
            policyVersion: session.policyVersion
        )
        sessions[sessionId] = session

        return PracticeSummary(
            sessionId: sessionId,
            status: newStatus,
            objectiveResults: session.checkpoint.objectiveResults,
            perWordProgress: progressList,
            evidenceIds: evidenceList.filter { $0.sessionId == sessionId }.map(\.id),
            persisted: true
        )
    }

    public func deleteSession(id: UUID) async throws {
        sessions.removeValue(forKey: id)
        turns.removeValue(forKey: id)
        exposures.removeValue(forKey: id)
        presentations.removeValue(forKey: id)
        evidenceList.removeAll(where: { $0.sessionId == id })
    }

    public func deleteAllPractice() async throws {
        sessions.removeAll()
        turns.removeAll()
        exposures.removeAll()
        presentations.removeAll()
        evidenceList.removeAll()
        progressList.removeAll()
    }

    public func resetAllLearningProgress() async throws {
        try await deleteAllPractice()
    }
}
