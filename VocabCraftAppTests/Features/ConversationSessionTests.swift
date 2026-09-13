import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Conversation mock session")
@MainActor
struct ConversationSessionTests {
    @Test("retry outcome waits for an explicit retry")
    func retryWaits() {
        let session = makeSession(role: .speakerB)
        session.start()
        session.finishPartnerTurn()
        let token = session.pendingResolutionToken
        session.resolve(.retry, token: token)

        #expect(session.phase == .waitingToRetry(turnID: "cafe-2", outcome: .retry))
        #expect(session.passedTurnIDs.isEmpty)

        session.retry()
        #expect(session.phase == .listening(turnID: "cafe-2"))
    }

    @Test("role B begins with role A partner playback")
    func roleBStartsWithPartner() {
        let session = makeSession(role: .speakerB)
        session.start()

        #expect(session.phase == .partnerPlayback(turnID: "cafe-1"))
    }

    @Test("pause cancels a pending result callback")
    func staleCallbackAfterPauseIsIgnored() {
        let session = makeSession(role: .speakerB)
        session.start()
        session.finishPartnerTurn()
        let staleToken = session.pendingResolutionToken
        session.pause()
        session.resolve(.pass, token: staleToken)

        #expect(session.phase == .paused)
        #expect(session.passedTurnIDs.isEmpty)
    }

    @Test("completion waits for the trailing partner turn")
    func completionIncludesTrailingPartnerTurn() {
        let session = makeSession(role: .speakerB)
        session.start()
        session.finishPartnerTurn()
        session.resolve(.pass, token: session.pendingResolutionToken)

        #expect(session.phase == .partnerPlayback(turnID: "cafe-3"))
        #expect(session.hasCompletedAchievement == false)

        session.finishPartnerTurn()
        #expect(session.phase == .completed)
        #expect(session.hasCompletedAchievement)
    }

    @Test("restored active session waits for Continue")
    func restoredSessionDoesNotAutoListen() throws {
        let storage = InMemoryConversationSessionStorage()
        let original = makeSession(role: .speakerB, storage: storage)
        original.start()
        original.finishPartnerTurn()
        original.resolve(.pass, token: original.pendingResolutionToken)

        let restored = try #require(ConversationMockSession.restore(
            conversation: .testFixture,
            storage: storage
        ))
        #expect(restored.phase == .awaitingContinue)
        #expect(restored.role == .speakerB)
        #expect(restored.passedTurnIDs == ["cafe-2"])
    }

    @Test("failed regeneration retains conversation and progress")
    func regenerationRollback() async {
        let session = makeSession(role: .speakerB)
        session.start()
        session.finishPartnerTurn()
        session.resolve(.pass, token: session.pendingResolutionToken)
        session.pause()
        let repository = FailingConversationRepository()

        await session.requestNewConversation(from: repository)

        #expect(session.conversation.id == "cafe")
        #expect(session.passedTurnIDs == ["cafe-2"])
        #expect(session.regenerationStatus == .failed)
    }

    @Test("switching roles preserves earned achievement")
    func switchingRolesKeepsAchievement() {
        let session = makeSession(role: .speakerB)
        session.start()
        session.finishPartnerTurn()
        session.resolve(.pass, token: session.pendingResolutionToken)
        session.finishPartnerTurn()
        session.switchRole()
        #expect(session.hasCompletedAchievement)
        #expect(session.passedTurnIDs.isEmpty)
    }

    @Test("sample variants preserve the target vocabulary")
    func variantsKeepVocabulary() async throws {
        let scripts = try SampleConversationRepository.loadScripts()
        #expect(scripts.count == 2)
        #expect(Set(scripts[0].vocabularyReferences) == Set(scripts[1].vocabularyReferences))
        let replacement = try await SampleConversationRepository().nextConversation(after: scripts[0].id)
        #expect(replacement.id != scripts[0].id)
        #expect(replacement.turns.allSatisfy { !$0.english.isEmpty && !$0.vietnamese.isEmpty })
    }

    @Test("no speech waits without crediting a turn")
    func noSpeechWaits() {
        let session = makeSession(role: .speakerA)
        session.start()
        session.resolve(.noSpeech, token: session.pendingResolutionToken)
        #expect(session.phase == .waitingToRetry(turnID: "cafe-1", outcome: .noSpeech))
        #expect(session.passedTurnIDs.isEmpty)
    }

    private func makeSession(
        role: ConversationRole,
        storage: any ConversationSessionStorage = InMemoryConversationSessionStorage()
    ) -> ConversationMockSession {
        ConversationMockSession(conversation: .testFixture, role: role, storage: storage)
    }
}

private extension ConversationScript {
    static let testFixture = ConversationScript(
        id: "cafe",
        situation: "At a café",
        situationVi: "Ở quán cà phê",
        vocabularyReferences: ["habit"],
        turns: [
            .init(id: "cafe-1", speaker: .speakerA, english: "Hello.", vietnamese: "Xin chào."),
            .init(id: "cafe-2", speaker: .speakerB, english: "Coffee, please.", vietnamese: "Cho tôi cà phê."),
            .init(id: "cafe-3", speaker: .speakerA, english: "Of course.", vietnamese: "Tất nhiên.")
        ]
    )
}

private struct FailingConversationRepository: ConversationRepository {
    func nextConversation(after _: String) async throws -> ConversationScript {
        throw ConversationRepositoryError.simulatedFailure
    }
}
