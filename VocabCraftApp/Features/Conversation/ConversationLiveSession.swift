import Foundation
import Observation
import SpeechKit

public enum ConversationLiveFailure: String, Codable, CaseIterable, Equatable, Sendable {
    case readAgain
    case noSpeech
    case permissionDenied
    case recognitionUnavailable
    case captureFailed
    case playbackFailed
}

public enum ConversationLivePhase: Equatable, Sendable {
    case ready
    case preparing(turnID: String)
    case partnerPlayback(turnID: String)
    case listening(turnID: String)
    case evaluating(turnID: String)
    case waitingToRetry(turnID: String, failure: ConversationLiveFailure)
    case paused
    case awaitingContinue
    case completed
}

@MainActor
@Observable
public final class ConversationLiveSession {
    public static let liveStorageKey = "debug.conversation.live.session.v1"

    public private(set) var conversation: ConversationScript
    public private(set) var role: ConversationRole
    public private(set) var phase: ConversationLivePhase = .ready
    public private(set) var passedTurnIDs: Set<String> = []
    public private(set) var hasCompletedAchievement: Bool = false
    public private(set) var liveTranscript: String = ""
    public private(set) var pendingResolutionToken: UUID = UUID()
    public private(set) var isPlayingSample: Bool = false
    public private(set) var regenerationStatus: ConversationRegenerationStatus = .idle

    private var currentTurnIndex: Int = 0
    private var isPerformingTurn: Bool = false
    @ObservationIgnored private let storage: any ConversationSessionStorage
    @ObservationIgnored private let audio: any ConversationAudioClient
    @ObservationIgnored private let evaluator: ConversationTurnEvaluator

    public var activeTurnID: String? {
        guard conversation.turns.indices.contains(currentTurnIndex) else { return nil }
        return conversation.turns[currentTurnIndex].id
    }

    public var progress: Double {
        let required = conversation.turns.filter { $0.speaker == role }.count
        guard required > 0 else { return 0 }
        return Double(passedTurnIDs.count) / Double(required)
    }

    public init(
        conversation: ConversationScript,
        role: ConversationRole = .speakerA,
        storage: any ConversationSessionStorage,
        audio: any ConversationAudioClient,
        evaluator: ConversationTurnEvaluator = .init()
    ) {
        self.conversation = conversation
        self.role = role
        self.storage = storage
        self.audio = audio
        self.evaluator = evaluator
    }

    public static func restore(
        conversation: ConversationScript,
        storage: any ConversationSessionStorage,
        audio: any ConversationAudioClient,
        evaluator: ConversationTurnEvaluator = .init()
    ) -> ConversationLiveSession? {
        guard let snapshot = storage.load() else { return nil }
        guard snapshot.conversationID == conversation.id else { return nil }
        guard conversation.turns.contains(where: { $0.speaker == snapshot.role }) else { return nil }
        guard snapshot.currentTurnIndex >= 0, snapshot.currentTurnIndex <= conversation.turns.count else {
            return nil
        }

        let learnerTurnIDs = Set(conversation.turns.filter { $0.speaker == snapshot.role }.map(\.id))
        let validPassed = snapshot.passedTurnIDs.intersection(learnerTurnIDs)

        let isCompleted = snapshot.currentTurnIndex == conversation.turns.count
            && validPassed == learnerTurnIDs
            && snapshot.hasCompletedAchievement

        if snapshot.currentTurnIndex == conversation.turns.count && !isCompleted {
            return nil
        }

        let session = ConversationLiveSession(
            conversation: conversation,
            role: snapshot.role,
            storage: storage,
            audio: audio,
            evaluator: evaluator
        )
        session.currentTurnIndex = snapshot.currentTurnIndex
        session.passedTurnIDs = validPassed
        session.hasCompletedAchievement = snapshot.hasCompletedAchievement
        session.phase = isCompleted ? .completed : .awaitingContinue

        return session
    }

    public func start() {
        guard phase == .ready else { return }
        currentTurnIndex = 0
        enterCurrentTurn()
    }

    public func chooseRole(_ role: ConversationRole) {
        guard phase == .ready || phase == .completed else { return }
        self.role = role
        restartAttempt()
    }

    public func performCurrentTurn() async {
        guard !isPerformingTurn else { return }
        guard !isPlayingSample else { return }
        guard conversation.turns.indices.contains(currentTurnIndex) else { return }
        let turn = conversation.turns[currentTurnIndex]

        if turn.speaker != role {
            await performPartnerTurn(turn)
        } else {
            await performUserTurn(turn)
        }
    }

    private func performPartnerTurn(_ turn: ConversationTurn) async {
        guard phase == .partnerPlayback(turnID: turn.id) else { return }
        isPerformingTurn = true
        defer { isPerformingTurn = false }

        let token = pendingResolutionToken
        let result = await audio.play(text: turn.english, locale: "en-US")
        guard token == pendingResolutionToken, !Task.isCancelled else { return }

        switch result {
        case .finished:
            advance()
        case .cancelled, .failed:
            phase = .waitingToRetry(turnID: turn.id, failure: .playbackFailed)
            persist()
        }
    }

    private func performUserTurn(_ turn: ConversationTurn) async {
        guard phase == .preparing(turnID: turn.id) else { return }
        isPerformingTurn = true
        defer { isPerformingTurn = false }

        let token = pendingResolutionToken
        var contextualPhrases = [turn.english]
        for ref in conversation.vocabularyReferences where ref != turn.english {
            if !contextualPhrases.contains(ref) {
                contextualPhrases.append(ref)
            }
        }

        let result = await audio.capture(
            targetSentence: turn.english,
            contextualPhrases: contextualPhrases,
            onListening: { [weak self] in
                guard let self, self.pendingResolutionToken == token, !Task.isCancelled else { return }
                self.phase = .listening(turnID: turn.id)
            },
            onPartial: { [weak self] transcript in
                guard let self, self.pendingResolutionToken == token, !Task.isCancelled else { return }
                self.liveTranscript = transcript
            }
        )

        guard token == pendingResolutionToken, !Task.isCancelled else { return }
        phase = .evaluating(turnID: turn.id)
        handleCaptureResult(result, for: turn)
    }

    private func handleCaptureResult(_ result: ConversationCaptureResult, for turn: ConversationTurn) {
        switch result {
        case let .transcript(transcript):
            evaluateTranscript(transcript, for: turn)
        case .silence:
            phase = .waitingToRetry(turnID: turn.id, failure: .noSpeech)
            persist()
        case .permissionDenied:
            phase = .waitingToRetry(turnID: turn.id, failure: .permissionDenied)
            persist()
        case .unavailable:
            phase = .waitingToRetry(turnID: turn.id, failure: .recognitionUnavailable)
            persist()
        case .failed, .cancelled:
            phase = .waitingToRetry(turnID: turn.id, failure: .captureFailed)
            persist()
        }
    }

    private func evaluateTranscript(_ transcript: String, for turn: ConversationTurn) {
        liveTranscript = transcript
        let requiredTerms = requiredTerms(for: turn)
        let evaluation = evaluator.evaluate(
            transcript: transcript,
            target: turn.english,
            requiredTerms: requiredTerms
        )
        if evaluation.isPassed {
            passedTurnIDs.insert(turn.id)
            advance()
        } else {
            let failure: ConversationLiveFailure = (evaluation.failure == .silence) ? .noSpeech : .readAgain
            phase = .waitingToRetry(turnID: turn.id, failure: failure)
            persist()
        }
    }

    public func retry() {
        guard case .waitingToRetry = phase else { return }
        guard conversation.turns.indices.contains(currentTurnIndex) else { return }
        enterCurrentTurn()
    }

    public func pause() {
        guard phase != .ready, phase != .completed else { return }
        pendingResolutionToken = UUID()
        isPlayingSample = false
        audio.stop()
        phase = .paused
        persist()
    }

    public func resume() {
        guard phase == .paused else { return }
        enterCurrentTurn()
    }

    public func continueRestoredAttempt() {
        guard phase == .awaitingContinue else { return }
        enterCurrentTurn()
    }

    public func switchRole() {
        role = (role == .speakerA) ? .speakerB : .speakerA
        restartAttempt()
    }

    public func playCurrentSample() async {
        guard !isPlayingSample else { return }
        guard phase == .ready || isWaitingToRetry else { return }
        guard let sampleText = sampleTextForLearner() else { return }

        let token = pendingResolutionToken
        isPlayingSample = true
        defer {
            if pendingResolutionToken == token {
                isPlayingSample = false
            }
        }

        _ = await audio.play(text: sampleText, locale: "en-US")
        guard token == pendingResolutionToken, !Task.isCancelled else {
            isPlayingSample = false
            return
        }
        isPlayingSample = false
    }

    public func requestNewConversation(from repository: any ConversationRepository) async {
        guard phase != .partnerPlayback(turnID: activeTurnID ?? ""),
              phase != .listening(turnID: activeTurnID ?? ""),
              phase != .preparing(turnID: activeTurnID ?? ""),
              phase != .evaluating(turnID: activeTurnID ?? ""),
              !isPlayingSample else { return }
        guard regenerationStatus != .loading else { return }

        regenerationStatus = .loading
        do {
            let replacement = try await repository.nextConversation(after: conversation.id)
            conversation = replacement
            restartAttempt()
            regenerationStatus = .idle
        } catch {
            regenerationStatus = .failed
        }
    }

    private var isWaitingToRetry: Bool {
        if case .waitingToRetry = phase { return true }
        return false
    }

    private func sampleTextForLearner() -> String? {
        if conversation.turns.indices.contains(currentTurnIndex),
           conversation.turns[currentTurnIndex].speaker == role {
            return conversation.turns[currentTurnIndex].english
        }
        return conversation.turns.first(where: { $0.speaker == role })?.english
    }

    private func requiredTerms(for turn: ConversationTurn) -> [String] {
        let turnTokens = Set(StringNormalizer.tokenize(turn.english))
        return conversation.vocabularyReferences.filter { reference in
            let refTokens = StringNormalizer.tokenize(reference)
            guard !refTokens.isEmpty else { return false }
            return refTokens.allSatisfy(turnTokens.contains)
        }
    }

    private func advance() {
        currentTurnIndex += 1
        if currentTurnIndex >= conversation.turns.count {
            completeSession()
        } else {
            enterCurrentTurn()
        }
    }

    private func completeSession() {
        pendingResolutionToken = UUID()
        phase = .completed
        hasCompletedAchievement = true
        persist()
    }

    private func enterCurrentTurn() {
        guard conversation.turns.indices.contains(currentTurnIndex) else {
            completeSession()
            return
        }
        pendingResolutionToken = UUID()
        liveTranscript = ""
        let turn = conversation.turns[currentTurnIndex]
        phase = turn.speaker == role ? .preparing(turnID: turn.id) : .partnerPlayback(turnID: turn.id)
        persist()
    }

    private func restartAttempt() {
        pendingResolutionToken = UUID()
        isPlayingSample = false
        audio.stop()
        currentTurnIndex = 0
        passedTurnIDs = []
        liveTranscript = ""
        phase = .ready
        persist()
    }

    private func persist() {
        storage.save(.init(
            conversationID: conversation.id,
            role: role,
            currentTurnIndex: currentTurnIndex,
            passedTurnIDs: passedTurnIDs,
            hasCompletedAchievement: hasCompletedAchievement
        ))
    }
}
