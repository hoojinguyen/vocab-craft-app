import Foundation
import Observation

@MainActor
@Observable
public final class ConversationMockSession {
    public private(set) var conversation: ConversationScript
    public private(set) var role: ConversationRole
    public private(set) var phase: ConversationSessionPhase = .preview
    public private(set) var passedTurnIDs: Set<String> = []
    public private(set) var hasCompletedAchievement = false
    public private(set) var regenerationStatus: ConversationRegenerationStatus = .idle
    public var selectedOutcome: ConversationMockOutcome = .pass

    private var currentTurnIndex = 0
    private var resolutionToken = UUID()
    private let storage: any ConversationSessionStorage

    public var pendingResolutionToken: UUID { resolutionToken }
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
        storage: any ConversationSessionStorage = InMemoryConversationSessionStorage()
    ) {
        self.conversation = conversation
        self.role = role
        self.storage = storage
    }

    public static func restore(
        conversation: ConversationScript,
        storage: any ConversationSessionStorage
    ) -> ConversationMockSession? {
        guard let snapshot = storage.load(), snapshot.conversationID == conversation.id else { return nil }
        let session = ConversationMockSession(conversation: conversation, role: snapshot.role, storage: storage)
        session.currentTurnIndex = max(0, min(snapshot.currentTurnIndex, conversation.turns.count))
        session.passedTurnIDs = snapshot.passedTurnIDs
        session.hasCompletedAchievement = snapshot.hasCompletedAchievement
        session.phase = snapshot.currentTurnIndex >= conversation.turns.count ? .completed : .awaitingContinue
        return session
    }

    public func chooseRole(_ role: ConversationRole) {
        guard phase == .preview || phase == .completed else { return }
        self.role = role
        restartAttempt()
    }

    public func start() {
        guard phase == .preview else { return }
        currentTurnIndex = 0
        enterCurrentTurn()
    }

    public func continueRestoredAttempt() {
        guard phase == .awaitingContinue else { return }
        enterCurrentTurn()
    }

    public func finishPartnerTurn() {
        guard case .partnerPlayback = phase else { return }
        advance()
    }

    public func resolve(_ outcome: ConversationMockOutcome, token: UUID) {
        guard token == resolutionToken, case let .listening(turnID) = phase else { return }
        switch outcome {
        case .pass:
            passedTurnIDs.insert(turnID)
            advance()
        case .retry, .noSpeech:
            phase = .waitingToRetry(turnID: turnID, outcome: outcome)
            persist()
        }
    }

    public func retry() {
        guard case let .waitingToRetry(turnID, _) = phase else { return }
        resolutionToken = UUID()
        phase = .listening(turnID: turnID)
        persist()
    }

    public func pause() {
        guard phase != .preview, phase != .completed else { return }
        resolutionToken = UUID()
        phase = .paused
        persist()
    }

    public func resume() {
        guard phase == .paused else { return }
        enterCurrentTurn()
    }

    public func switchRole() {
        role = role == .speakerA ? .speakerB : .speakerA
        restartAttempt()
    }

    public func requestNewConversation(from repository: any ConversationRepository) async {
        guard phase != .partnerPlayback(turnID: activeTurnID ?? ""),
              phase != .listening(turnID: activeTurnID ?? "") else { return }
        guard regenerationStatus != .loading else { return }
        regenerationStatus = .loading
        do {
            let replacement = try await repository.nextConversation(after: conversation.id)
            conversation = replacement
            restartAttempt(preserveAchievement: true)
            regenerationStatus = .idle
        } catch {
            regenerationStatus = .failed
        }
    }

    private func advance() {
        currentTurnIndex += 1
        if currentTurnIndex >= conversation.turns.count {
            phase = .completed
            hasCompletedAchievement = true
            persist()
        } else {
            enterCurrentTurn()
        }
    }

    private func enterCurrentTurn() {
        guard conversation.turns.indices.contains(currentTurnIndex) else {
            phase = .completed
            return
        }
        resolutionToken = UUID()
        let turn = conversation.turns[currentTurnIndex]
        phase = turn.speaker == role ? .listening(turnID: turn.id) : .partnerPlayback(turnID: turn.id)
        persist()
    }

    private func restartAttempt(preserveAchievement: Bool = true) {
        resolutionToken = UUID()
        currentTurnIndex = 0
        passedTurnIDs = []
        if !preserveAchievement { hasCompletedAchievement = false }
        phase = .preview
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
