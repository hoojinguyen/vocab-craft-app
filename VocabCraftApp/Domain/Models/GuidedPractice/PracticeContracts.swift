// swiftlint:disable file_length
import Foundation

// MARK: - Duration Helpers

extension Duration {
    public var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return Double(seconds) + Double(attoseconds) * 1e-18
    }
}

// MARK: - Practice Clock

/// Clock abstraction governing scheduling, timeouts, and temporal policy transitions.
public protocol PracticeClock: Sendable {
    func now() -> Date
    func sleep(for duration: Duration) async throws
}

extension PracticeClock {
    public var now: Date {
        self.now()
    }
}

/// Production implementation backed by Foundation Date and standard Task sleep.
public struct ProductionPracticeClock: PracticeClock {
    public init() {}

    public func now() -> Date {
        Date()
    }

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}

public typealias SystemPracticeClock = ProductionPracticeClock

/// Deterministic, synchronized test clock allowing explicit time advancement.
public final class ManualPracticeClock: PracticeClock, @unchecked Sendable {
    private struct Waiter {
        let deadline: Date
        let continuation: CheckedContinuation<Void, Error>
    }

    private let lock = NSLock()
    private var currentDate: Date
    private var waiters: [UUID: Waiter] = [:]

    public init(initialDate: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.currentDate = initialDate
    }

    public func now() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return currentDate
    }

    public func setNow(_ date: Date) {
        lock.lock()
        currentDate = date
        let ready = extractReadyWaiters(underCurrentDate: date)
        lock.unlock()

        for continuation in ready {
            continuation.resume()
        }
    }

    public func advance(by duration: Duration) {
        let seconds = duration.timeInterval
        lock.lock()
        currentDate = currentDate.addingTimeInterval(seconds)
        let ready = extractReadyWaiters(underCurrentDate: currentDate)
        lock.unlock()

        for continuation in ready {
            continuation.resume()
        }
    }

    private func extractReadyWaiters(underCurrentDate now: Date) -> [CheckedContinuation<Void, Error>] {
        var ready: [CheckedContinuation<Void, Error>] = []
        var remaining: [UUID: Waiter] = [:]
        for (id, waiter) in waiters {
            if waiter.deadline <= now {
                ready.append(waiter.continuation)
            } else {
                remaining[id] = waiter
            }
        }
        waiters = remaining
        return ready
    }

    public var waiterCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return waiters.count
    }

    public func waitForSleepers(count: Int) async {
        while waiterCount < count {
            await Task.yield()
        }
    }

    public func sleep(for duration: Duration) async throws {
        try Task.checkCancellation()
        let seconds = duration.timeInterval
        if seconds <= 0 { return }

        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                let deadline = currentDate.addingTimeInterval(seconds)
                if deadline <= currentDate {
                    lock.unlock()
                    continuation.resume()
                    return
                }
                waiters[id] = Waiter(deadline: deadline, continuation: continuation)
                lock.unlock()
            }
        } onCancel: {
            lock.lock()
            let waiter = waiters.removeValue(forKey: id)
            lock.unlock()
            waiter?.continuation.resume(throwing: CancellationError())
        }
    }
}

// MARK: - Policy Configuration

/// Pedagogical intervals, retry delays, and technical timeouts for guided practice.
public struct PracticePolicyConfiguration: Codable, Sendable, Equatable, Hashable {
    public let version: Int
    public let transferDelay: TimeInterval
    public let assistedDelay: TimeInterval
    public let familiarDelay: TimeInterval
    public let transferredDelay: TimeInterval
    public let generationTimeout: TimeInterval
    public let ttsPreparationTimeout: TimeInterval

    // swiftlint:disable:next identifier_name
    public static let v1 = PracticePolicyConfiguration(
        version: 1,
        transferDelay: 86_400,
        assistedDelay: 86_400,
        familiarDelay: 259_200,
        transferredDelay: 604_800,
        generationTimeout: 30,
        ttsPreparationTimeout: 20
    )

    public init(
        version: Int = 1,
        transferDelay: TimeInterval = 86_400,
        assistedDelay: TimeInterval = 86_400,
        familiarDelay: TimeInterval = 259_200,
        transferredDelay: TimeInterval = 604_800,
        generationTimeout: TimeInterval = 30,
        ttsPreparationTimeout: TimeInterval = 20
    ) {
        self.version = version
        self.transferDelay = transferDelay
        self.assistedDelay = assistedDelay
        self.familiarDelay = familiarDelay
        self.transferredDelay = transferredDelay
        self.generationTimeout = generationTimeout
        self.ttsPreparationTimeout = ttsPreparationTimeout
    }
}

// MARK: - Learning Context

/// Aggregated learner progress snapshots passed into mission selection.
public struct PracticeLearningContext: Codable, Sendable, Equatable {
    public let words: [PracticeWordSnapshot]
    public let progress: [UserWordProgressData]
    public let communication: [CommunicationProgress]
    public let evidence: [WordUseEvidence]
    public let recentReflexWordIds: Set<Int64>

    public init(
        words: [PracticeWordSnapshot],
        progress: [UserWordProgressData] = [],
        communication: [CommunicationProgress] = [],
        evidence: [WordUseEvidence] = [],
        recentReflexWordIds: Set<Int64> = []
    ) {
        self.words = words
        self.progress = progress
        self.communication = communication
        self.evidence = evidence
        self.recentReflexWordIds = recentReflexWordIds
    }
}

// MARK: - Templates & Curated Content

/// Bounding envelope for difficulty adaptation within a template.
public struct PracticeDifficultyBounds: Codable, Sendable, Equatable, Hashable {
    public let min: PracticeDifficulty
    public let max: PracticeDifficulty

    public init(min: PracticeDifficulty, max: PracticeDifficulty) {
        self.min = min
        self.max = max
    }
}

/// Curated communicative scenario specification.
public struct PracticeTemplate: Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let version: Int
    public let contextFamily: PracticeContextFamily
    public let titleKey: String
    public let briefKey: String
    public let roleKeys: [String]
    public let objectiveIds: [String]
    public let supportedWordSenses: [PracticeWordSense]
    public let variants: [String]
    public let difficultyBounds: PracticeDifficultyBounds
    public let shadowingVideoId: String?

    public init(
        id: String,
        version: Int = 1,
        contextFamily: PracticeContextFamily,
        titleKey: String,
        briefKey: String,
        roleKeys: [String],
        objectiveIds: [String],
        supportedWordSenses: [PracticeWordSense],
        variants: [String] = [],
        difficultyBounds: PracticeDifficultyBounds,
        shadowingVideoId: String? = nil
    ) {
        self.id = id
        self.version = version
        self.contextFamily = contextFamily
        self.titleKey = titleKey
        self.briefKey = briefKey
        self.roleKeys = roleKeys
        self.objectiveIds = objectiveIds
        self.supportedWordSenses = supportedWordSenses
        self.variants = variants
        self.difficultyBounds = difficultyBounds
        self.shadowingVideoId = shadowingVideoId
    }
}

// MARK: - AI Dialogue & Assessment Contracts

/// Structured input request supplied to the AI conversation provider.
public struct PracticeAIRequest: Codable, Sendable, Equatable {
    public let mission: PracticeMission
    public let acceptedTurns: [PracticeTurn]
    public let supportBudget: PracticeSupportLevel
    public let providerIdentity: String

    public init(
        mission: PracticeMission,
        acceptedTurns: [PracticeTurn],
        supportBudget: PracticeSupportLevel,
        providerIdentity: String
    ) {
        self.mission = mission
        self.acceptedTurns = acceptedTurns
        self.supportBudget = supportBudget
        self.providerIdentity = providerIdentity
    }
}

/// Specific vocabulary assessment generated by AI.
public struct PracticeWordAssessment: Codable, Sendable, Equatable, Hashable {
    public let wordId: Int64
    public let objectiveId: String
    public let usageVerdict: PracticeUsageVerdict
    public let quotedSpan: String?

    public init(
        wordId: Int64,
        objectiveId: String,
        usageVerdict: PracticeUsageVerdict,
        quotedSpan: String? = nil
    ) {
        self.wordId = wordId
        self.objectiveId = objectiveId
        self.usageVerdict = usageVerdict
        self.quotedSpan = quotedSpan
    }
}

/// Communicative objective evaluation generated by AI.
public struct PracticeObjectiveAssessment: Codable, Sendable, Equatable, Hashable {
    public let objectiveId: String
    public let intentVerdict: PracticeIntentVerdict

    public init(objectiveId: String, intentVerdict: PracticeIntentVerdict) {
        self.objectiveId = objectiveId
        self.intentVerdict = intentVerdict
    }
}

/// Verified communicative outcome for an objective.
public struct PracticeObjectiveResult: Codable, Sendable, Equatable, Hashable {
    public let objectiveId: String
    public let intentVerdict: PracticeIntentVerdict
    public let opportunityObserved: Bool

    public init(
        objectiveId: String,
        intentVerdict: PracticeIntentVerdict,
        opportunityObserved: Bool
    ) {
        self.objectiveId = objectiveId
        self.intentVerdict = intentVerdict
        self.opportunityObserved = opportunityObserved
    }
}

/// Structured response output returned by the AI provider.
public struct PracticeAIResponse: Codable, Sendable, Equatable {
    public let characterReply: String
    public let objectiveAssessments: [PracticeObjectiveAssessment]
    public let wordAssessments: [PracticeWordAssessment]
    public let coachFeedback: String?
    public let hintCandidate: String?

    public init(
        characterReply: String,
        objectiveAssessments: [PracticeObjectiveAssessment] = [],
        wordAssessments: [PracticeWordAssessment] = [],
        coachFeedback: String? = nil,
        hintCandidate: String? = nil
    ) {
        self.characterReply = characterReply
        self.objectiveAssessments = objectiveAssessments
        self.wordAssessments = wordAssessments
        self.coachFeedback = coachFeedback
        self.hintCandidate = hintCandidate
    }
}

/// Verified turn evaluation bundle combining raw AI response and validated evidence.
public struct PracticeAssessment: Codable, Sendable, Equatable {
    public let evidence: [WordUseEvidence]
    public let objectiveResults: [PracticeObjectiveResult]
    public let response: PracticeAIResponse

    public init(
        evidence: [WordUseEvidence],
        objectiveResults: [PracticeObjectiveResult],
        response: PracticeAIResponse
    ) {
        self.evidence = evidence
        self.objectiveResults = objectiveResults
        self.response = response
    }
}

/// Summary report produced upon session completion or exit.
public struct PracticeSummary: Codable, Sendable, Equatable {
    public let sessionId: UUID
    public let status: PracticeSessionStatus
    public let objectiveResults: [PracticeObjectiveResult]
    public let perWordProgress: [CommunicationProgress]
    public let evidenceIds: [UUID]
    public let persisted: Bool

    public init(
        sessionId: UUID,
        status: PracticeSessionStatus,
        objectiveResults: [PracticeObjectiveResult],
        perWordProgress: [CommunicationProgress],
        evidenceIds: [UUID],
        persisted: Bool = false
    ) {
        self.sessionId = sessionId
        self.status = status
        self.objectiveResults = objectiveResults
        self.perWordProgress = perWordProgress
        self.evidenceIds = evidenceIds
        self.persisted = persisted
    }
}

// MARK: - Presentation Intent & Checkpoint

/// Scaffolding or character prompt reserved prior to actual rendering.
public enum PracticePresentationStatus: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case pending, confirmed, cancelled
}

public struct PracticePresentationIntent: Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let turnId: UUID?
    public let content: String
    public let channel: PracticePresentationChannel
    public let possibleWordIds: [Int64]
    public let proposedLevel: PracticeSupportLevel
    public let status: PracticePresentationStatus
    public let origin: SupportOrigin

    public init(
        id: UUID,
        sessionId: UUID,
        turnId: UUID? = nil,
        content: String,
        channel: PracticePresentationChannel,
        possibleWordIds: [Int64],
        proposedLevel: PracticeSupportLevel,
        status: PracticePresentationStatus = .pending,
        origin: SupportOrigin = .coachSuggested
    ) {
        self.id = id
        self.sessionId = sessionId
        self.turnId = turnId
        self.content = content
        self.channel = channel
        self.possibleWordIds = possibleWordIds
        self.proposedLevel = proposedLevel
        self.status = status
        self.origin = origin
    }
}

/// Pedagogical observation outcome for a single lexical opportunity.
public struct PracticeOpportunityOutcome: Codable, Sendable, Equatable, Hashable {
    public let opportunityId: String
    public let wordId: Int64?
    public let objectiveId: String?
    public let intentVerdict: PracticeIntentVerdict
    public let usageVerdict: PracticeUsageVerdict
    public let supportLevel: PracticeSupportLevel
    public let primed: Bool
    public let eligible: Bool

    public var success: Bool {
        intentVerdict == .achieved && usageVerdict == .appropriate
    }

    public init(
        opportunityId: String = UUID().uuidString,
        wordId: Int64? = nil,
        objectiveId: String? = nil,
        intentVerdict: PracticeIntentVerdict,
        usageVerdict: PracticeUsageVerdict,
        supportLevel: PracticeSupportLevel,
        primed: Bool,
        eligible: Bool = true
    ) {
        self.opportunityId = opportunityId
        self.wordId = wordId
        self.objectiveId = objectiveId
        self.intentVerdict = intentVerdict
        self.usageVerdict = usageVerdict
        self.supportLevel = supportLevel
        self.primed = primed
        self.eligible = eligible
    }

    public init(
        opportunityId: UUID,
        wordId: Int64? = nil,
        objectiveId: String? = nil,
        intentVerdict: PracticeIntentVerdict,
        usageVerdict: PracticeUsageVerdict,
        supportLevel: PracticeSupportLevel,
        primed: Bool,
        eligible: Bool = true
    ) {
        self.opportunityId = opportunityId.uuidString
        self.wordId = wordId
        self.objectiveId = objectiveId
        self.intentVerdict = intentVerdict
        self.usageVerdict = usageVerdict
        self.supportLevel = supportLevel
        self.primed = primed
        self.eligible = eligible
    }

    public init(
        opportunityId: String = UUID().uuidString,
        wordId: Int64,
        objectiveId: String,
        success: Bool,
        supportLevel: PracticeSupportLevel,
        primed: Bool,
        eligible: Bool = true
    ) {
        self.opportunityId = opportunityId
        self.wordId = wordId
        self.objectiveId = objectiveId
        self.intentVerdict = success ? .achieved : .notYet
        self.usageVerdict = success ? .appropriate : .inappropriate
        self.supportLevel = supportLevel
        self.primed = primed
        self.eligible = eligible
    }
}

/// Dynamic adaptation proposal adjusting support or difficulty.
public struct PracticeAdaptationDecision: Codable, Sendable, Equatable, Hashable {
    public let difficulty: PracticeDifficulty
    public let suggestedSupport: PracticeSupportLevel
    public let explanationKey: String?

    public var recommendedDifficulty: PracticeDifficulty { difficulty }
    public var recommendedSupportLevel: PracticeSupportLevel { suggestedSupport }

    public init(
        difficulty: PracticeDifficulty,
        suggestedSupport: PracticeSupportLevel = .none,
        explanationKey: String? = nil
    ) {
        self.difficulty = difficulty
        self.suggestedSupport = suggestedSupport
        self.explanationKey = explanationKey
    }

    public init(
        recommendedSupportLevel: PracticeSupportLevel,
        recommendedDifficulty: PracticeDifficulty,
        explanationKey: String? = nil
    ) {
        self.difficulty = recommendedDifficulty
        self.suggestedSupport = recommendedSupportLevel
        self.explanationKey = explanationKey
    }
}

/// Session checkpoint persisted across interruptions and background transitions.
public struct PracticeCheckpoint: Codable, Sendable, Equatable {
    public let pendingTurnId: UUID?
    public let requestId: String?
    public let presentationIntents: [PracticePresentationIntent]
    public let exposureUncertainWordIds: Set<Int64>
    public let currentSupportLevel: PracticeSupportLevel
    public let objectiveResults: [PracticeObjectiveResult]
    public let difficultyOutcomes: [PracticeOpportunityOutcome]

    public init(
        pendingTurnId: UUID? = nil,
        requestId: String? = nil,
        presentationIntents: [PracticePresentationIntent] = [],
        exposureUncertainWordIds: Set<Int64> = [],
        currentSupportLevel: PracticeSupportLevel = .none,
        objectiveResults: [PracticeObjectiveResult] = [],
        difficultyOutcomes: [PracticeOpportunityOutcome] = []
    ) {
        self.pendingTurnId = pendingTurnId
        self.requestId = requestId
        self.presentationIntents = presentationIntents
        self.exposureUncertainWordIds = exposureUncertainWordIds
        self.currentSupportLevel = currentSupportLevel
        self.objectiveResults = objectiveResults
        self.difficultyOutcomes = difficultyOutcomes
    }
}

/// Concurrency token isolating in-flight asynchronous operations.
public struct PracticeOperationToken: Codable, Sendable, Equatable, Hashable {
    public let sessionId: UUID
    public let requestId: String
    public let revision: Int

    public init(sessionId: UUID, requestId: String, revision: Int) {
        self.sessionId = sessionId
        self.requestId = requestId
        self.revision = revision
    }
}

/// Atomic repository commit payload bundling turn, evaluation, and checkpoint.
public struct PracticeCommit: Codable, Sendable, Equatable {
    public let sessionId: UUID
    public let expectedRevision: Int
    public let turn: PracticeTurn?
    public let assessment: PracticeAssessment?
    public let checkpoint: PracticeCheckpoint

    public init(
        sessionId: UUID,
        expectedRevision: Int,
        turn: PracticeTurn? = nil,
        assessment: PracticeAssessment? = nil,
        checkpoint: PracticeCheckpoint
    ) {
        self.sessionId = sessionId
        self.expectedRevision = expectedRevision
        self.turn = turn
        self.assessment = assessment
        self.checkpoint = checkpoint
    }
}

/// Completion mode for practice sessions.
public enum PracticeCompletion: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case completed
    case partial
}

/// Codable domain failure encapsulating system, AI, and storage errors.
public struct PracticeFailure: Error, Codable, Sendable, Equatable {
    public enum Code: String, Codable, Sendable, CaseIterable, Equatable {
        case capability
        case schema
        case network
        case timeout
        case storage
        case staleRevision
        case audio
        case domainValidation
    }

    public let code: Code
    public let message: String
    public let underlyingError: String?

    public init(
        code: Code,
        message: String,
        underlyingError: String? = nil
    ) {
        self.code = code
        self.message = message
        self.underlyingError = underlyingError
    }

    public init(
        code: Code,
        underlyingError: String? = nil
    ) {
        self.code = code
        self.message = underlyingError ?? code.rawValue
        self.underlyingError = underlyingError
    }
}

/// Real-time audio and speech recognition lifecycle events.
public enum PracticeSpeechEvent: Sendable, Equatable {
    case captureStarted
    case transcript(text: String, reliability: PracticeTranscriptReliability)
    case captureStopped
    case playbackStarted
    case playbackFinished
    case failed(PracticeFailure)
}

/// System capabilities advertised by active AI and audio providers.
public struct PracticeCapability: Codable, Sendable, Equatable, Hashable {
    public let canGenerateDialogue: Bool
    public let canAssessUsage: Bool
    public let canCaptureSpeech: Bool
    public let canPlaySpeech: Bool
    public let providerIdentity: String
    public let unavailableReason: String?

    public init(
        canGenerateDialogue: Bool,
        canAssessUsage: Bool,
        canCaptureSpeech: Bool,
        canPlaySpeech: Bool,
        providerIdentity: String,
        unavailableReason: String? = nil
    ) {
        self.canGenerateDialogue = canGenerateDialogue
        self.canAssessUsage = canAssessUsage
        self.canCaptureSpeech = canCaptureSpeech
        self.canPlaySpeech = canPlaySpeech
        self.providerIdentity = providerIdentity
        self.unavailableReason = unavailableReason
    }

    public static let standardCloud = PracticeCapability(
        canGenerateDialogue: true,
        canAssessUsage: true,
        canCaptureSpeech: true,
        canPlaySpeech: true,
        providerIdentity: "standardCloud"
    )
}

/// Selection outcome produced by the mission selection use case.
public enum PracticeSelectionResult: Codable, Sendable, Equatable {
    case mission(PracticeMission)
    case needsVocabulary
    case noCompatibleTemplate
}

/// Complete in-memory or persisted archive of a practice session and related entities.
public struct PracticeSessionSnapshot: Codable, Sendable, Equatable {
    public let session: PracticeSession
    public let turns: [PracticeTurn]
    public let exposures: [SupportExposure]
    public let evidence: [WordUseEvidence]
    public let progress: [CommunicationProgress]
    public let pendingPresentations: [PracticePresentationIntent]

    public init(
        session: PracticeSession,
        turns: [PracticeTurn] = [],
        exposures: [SupportExposure] = [],
        evidence: [WordUseEvidence] = [],
        progress: [CommunicationProgress] = [],
        pendingPresentations: [PracticePresentationIntent] = []
    ) {
        self.session = session
        self.turns = turns
        self.exposures = exposures
        self.evidence = evidence
        self.progress = progress
        self.pendingPresentations = pendingPresentations
    }
}
