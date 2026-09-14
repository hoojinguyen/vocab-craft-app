import Testing
@testable import VocabCraftApp

@Suite("Conversation live session")
@MainActor
struct ConversationLiveSessionTests {
    @Test("partner playback must finish before the user turn prepares capture")
    func playbackFinishesBeforeCapture() async {
        let audio = TestConversationAudioClient(playbackResult: .finished)
        let session = makeSession(role: .speakerB, audio: audio)
        session.start()

        await session.performCurrentTurn()

        #expect(session.phase == .preparing(turnID: "cafe-2"))
        #expect(audio.playedTexts == ["Yes, I have a reservation for two people."])
        #expect(audio.captureTargets.isEmpty)
    }

    @Test("cancelled partner playback cannot advance")
    func cancelledPlaybackDoesNotAdvance() async {
        let audio = TestConversationAudioClient(playbackResult: .cancelled)
        let session = makeSession(role: .speakerB, audio: audio)
        session.start()

        await session.performCurrentTurn()

        #expect(session.phase == .waitingToRetry(turnID: "cafe-1", failure: .playbackFailed))
        #expect(session.passedTurnIDs.isEmpty)
    }

    @Test("a final passing transcript advances and target sentence precedes vocabulary hints")
    func passingTranscriptAdvances() async {
        let audio = TestConversationAudioClient(
            captureResult: .transcript("Yes I have a reservation for two people")
        )
        let session = makeSession(role: .speakerA, audio: audio)
        session.start()

        await session.performCurrentTurn()

        #expect(session.passedTurnIDs == ["cafe-1"])
        #expect(session.phase == .partnerPlayback(turnID: "cafe-2"))
        #expect(audio.contextualPhrases.first == "Yes, I have a reservation for two people.")
        #expect(audio.partialWasShown)
    }

    @Test("permission denial waits for explicit retry without progress")
    func permissionDeniedWaitsForRetry() async {
        let audio = TestConversationAudioClient(captureResult: .permissionDenied)
        let session = makeSession(role: .speakerA, audio: audio)
        session.start()

        await session.performCurrentTurn()

        #expect(session.phase == .waitingToRetry(turnID: "cafe-1", failure: .permissionDenied))
        #expect(session.passedTurnIDs.isEmpty)
        session.retry()
        #expect(session.phase == .preparing(turnID: "cafe-1"))
    }

    @Test("pause invalidates a capture result that arrives later")
    func pauseInvalidatesLateCapture() async {
        let audio = TestConversationAudioClient(suspendsCapture: true)
        let session = makeSession(role: .speakerA, audio: audio)
        session.start()
        let task = Task { await session.performCurrentTurn() }
        await audio.waitUntilCaptureStarted()

        session.pause()
        audio.resumeCapture(with: .transcript("Yes I have a reservation for two people"))
        _ = await task.result

        #expect(session.phase == .paused)
        #expect(session.passedTurnIDs.isEmpty)
        #expect(audio.stopCount == 1)
    }

    @Test("duplicate completion does not corrupt state or advance beyond end")
    func duplicateCompletionDoesNotCorruptState() async {
        let audio = TestConversationAudioClient(
            captureResult: .transcript("Yes I have a reservation for two people")
        )
        let session = makeSession(role: .speakerA, audio: audio)
        session.start()

        // Turn 1 (Speaker A)
        await session.performCurrentTurn()
        #expect(session.phase == .partnerPlayback(turnID: "cafe-2"))

        // Turn 2 (Speaker B)
        audio.playbackResult = .finished
        await session.performCurrentTurn()
        #expect(session.phase == .completed)
        #expect(session.hasCompletedAchievement)

        // Attempt duplicate turn
        await session.performCurrentTurn()
        #expect(session.phase == .completed)
        #expect(session.passedTurnIDs == ["cafe-1"])
    }

    @Test("stale partial does not update transcript after pause")
    func stalePartialDoesNotUpdateTranscriptAfterPause() async {
        let audio = TestConversationAudioClient(suspendsCapture: true)
        let session = makeSession(role: .speakerA, audio: audio)
        session.start()
        let task = Task { await session.performCurrentTurn() }
        await audio.waitUntilCaptureStarted()

        #expect(session.liveTranscript == "Yes I have a reservation")

        session.pause()
        audio.invokePartial("Stale late arriving transcript")
        audio.resumeCapture(with: .cancelled)
        _ = await task.result

        #expect(session.phase == .paused)
        #expect(session.liveTranscript != "Stale late arriving transcript")
    }

    @Test("learner finishes their turns while remaining partner turn plays before completion")
    func learnerFinishesBeforeRemainingPartnerTurn() async {
        let audio = TestConversationAudioClient(
            captureResult: .transcript("Yes I have a reservation for two people")
        )
        let session = makeSession(role: .speakerA, audio: audio)
        session.start()

        // Learner finishes their only turn
        await session.performCurrentTurn()

        #expect(session.progress == 1.0)
        #expect(session.phase == .partnerPlayback(turnID: "cafe-2"))
        #expect(!session.hasCompletedAchievement)

        // Partner playback completes
        audio.playbackResult = .finished
        await session.performCurrentTurn()

        #expect(session.phase == .completed)
        #expect(session.hasCompletedAchievement)
    }

    @Test("sample playback does not advance progress or change phase")
    func samplePlaybackDoesNotAdvanceProgressOrChangePhase() async {
        let audio = TestConversationAudioClient(playbackResult: .finished)
        let session = makeSession(role: .speakerA, audio: audio)

        #expect(session.phase == .ready)
        #expect(session.progress == 0)

        await session.playCurrentSample()

        #expect(session.phase == .ready)
        #expect(session.progress == 0)
        #expect(session.passedTurnIDs.isEmpty)
        #expect(audio.playedTexts == ["Yes, I have a reservation for two people."])

        // Start and fail a turn to reach waitingToRetry
        session.start()
        audio.captureResult = .silence
        await session.performCurrentTurn()

        #expect(session.phase == .waitingToRetry(turnID: "cafe-1", failure: .noSpeech))
        #expect(session.progress == 0)

        await session.playCurrentSample()

        #expect(session.phase == .waitingToRetry(turnID: "cafe-1", failure: .noSpeech))
        #expect(session.progress == 0)
        #expect(!session.isPlayingSample)
    }

    @Test("restore restores in-progress and completed sessions and filters invalid IDs")
    func restoreValidatesAndFiltersSnapshot() {
        let storage = InMemoryConversationSessionStorage()
        let audio = TestConversationAudioClient()

        // In-progress snapshot with extra invalid turn ID
        storage.save(ConversationSessionSnapshot(
            conversationID: "cafe-live",
            role: .speakerA,
            currentTurnIndex: 1,
            passedTurnIDs: ["cafe-1", "invalid-turn-id", "cafe-2"],
            hasCompletedAchievement: false
        ))

        let inProgress = ConversationLiveSession.restore(
            conversation: .liveTestFixture,
            storage: storage,
            audio: audio
        )
        #expect(inProgress != nil)
        #expect(inProgress?.phase == .awaitingContinue)
        #expect(inProgress?.role == .speakerA)
        #expect(inProgress?.passedTurnIDs == ["cafe-1"]) // cafe-2 belongs to speakerB, invalid-turn-id filtered
        #expect(inProgress?.hasCompletedAchievement == false)

        // Completed snapshot
        storage.save(ConversationSessionSnapshot(
            conversationID: "cafe-live",
            role: .speakerA,
            currentTurnIndex: 2,
            passedTurnIDs: ["cafe-1"],
            hasCompletedAchievement: true
        ))

        let completed = ConversationLiveSession.restore(
            conversation: .liveTestFixture,
            storage: storage,
            audio: audio
        )
        #expect(completed != nil)
        #expect(completed?.phase == .completed)
        #expect(completed?.hasCompletedAchievement == true)

        // Mismatched conversation ID returns nil
        storage.save(ConversationSessionSnapshot(
            conversationID: "other-script",
            role: .speakerA,
            currentTurnIndex: 0,
            passedTurnIDs: [],
            hasCompletedAchievement: false
        ))
        let mismatched = ConversationLiveSession.restore(
            conversation: .liveTestFixture,
            storage: storage,
            audio: audio
        )
        #expect(mismatched == nil)

        // Out-of-bounds turn index returns nil
        storage.save(ConversationSessionSnapshot(
            conversationID: "cafe-live",
            role: .speakerA,
            currentTurnIndex: 99,
            passedTurnIDs: ["cafe-1"],
            hasCompletedAchievement: false
        ))
        let outOfBounds = ConversationLiveSession.restore(
            conversation: .liveTestFixture,
            storage: storage,
            audio: audio
        )
        #expect(outOfBounds == nil)
    }

    @Test("role switch resets attempt while preserving completion achievement")
    func roleSwitchResetsAttemptPreservingAchievement() async {
        let audio = TestConversationAudioClient(
            playbackResult: .finished,
            captureResult: .transcript("Yes I have a reservation for two people")
        )
        let session = makeSession(role: .speakerA, audio: audio)
        session.start()

        // Complete session
        await session.performCurrentTurn()
        await session.performCurrentTurn()
        #expect(session.phase == .completed)
        #expect(session.hasCompletedAchievement)

        // Switch role
        session.switchRole()

        #expect(session.role == .speakerB)
        #expect(session.phase == .ready)
        #expect(session.passedTurnIDs.isEmpty)
        #expect(session.progress == 0)
        #expect(session.hasCompletedAchievement) // Preserved
    }

    @Test("failed regeneration preserves existing session and conversation")
    func failedRegenerationPreservesSession() async {
        let audio = TestConversationAudioClient()
        let session = makeSession(role: .speakerA, audio: audio)
        let repo = TestConversationRepository(shouldFail: true)

        await session.requestNewConversation(from: repo)

        #expect(session.regenerationStatus == .failed)
        #expect(session.conversation.id == "cafe-live")
        #expect(session.phase == .ready)
    }

    private func makeSession(
        role: ConversationRole,
        audio: TestConversationAudioClient
    ) -> ConversationLiveSession {
        ConversationLiveSession(
            conversation: .liveTestFixture,
            role: role,
            storage: InMemoryConversationSessionStorage(),
            audio: audio
        )
    }
}

private extension ConversationScript {
    static let liveTestFixture = ConversationScript(
        id: "cafe-live",
        situation: "At a café",
        situationVi: "Ở quán cà phê",
        vocabularyReferences: ["reservation"],
        turns: [
            .init(
                id: "cafe-1",
                speaker: .speakerA,
                english: "Yes, I have a reservation for two people.",
                vietnamese: "Vâng, tôi đã đặt bàn cho hai người."
            ),
            .init(
                id: "cafe-2",
                speaker: .speakerB,
                english: "Welcome. Do you have a reservation?",
                vietnamese: "Chào mừng. Bạn đã đặt bàn chưa?"
            )
        ]
    )
}

@MainActor
private final class TestConversationAudioClient: ConversationAudioClient {
    var playbackResult: ConversationPlaybackResult
    var captureResult: ConversationCaptureResult
    let suspendsCapture: Bool
    private(set) var playedTexts: [String] = []
    private(set) var captureTargets: [String] = []
    private(set) var contextualPhrases: [String] = []
    private(set) var partialWasShown = false
    private(set) var stopCount = 0
    private var captureStartedContinuation: CheckedContinuation<Void, Never>?
    private var captureContinuation: CheckedContinuation<ConversationCaptureResult, Never>?
    private(set) var didStartCapture = false
    private var onPartialHandler: (@MainActor @Sendable (String) -> Void)?

    init(
        playbackResult: ConversationPlaybackResult = .finished,
        captureResult: ConversationCaptureResult = .silence,
        suspendsCapture: Bool = false
    ) {
        self.playbackResult = playbackResult
        self.captureResult = captureResult
        self.suspendsCapture = suspendsCapture
    }

    func play(text: String, locale: String) async -> ConversationPlaybackResult {
        playedTexts.append(text)
        return playbackResult
    }

    func capture(
        targetSentence: String,
        contextualPhrases: [String],
        onListening: @escaping @MainActor @Sendable () -> Void,
        onPartial: @escaping @MainActor @Sendable (String) -> Void
    ) async -> ConversationCaptureResult {
        didStartCapture = true
        captureTargets.append(targetSentence)
        self.contextualPhrases = contextualPhrases
        self.onPartialHandler = onPartial
        captureStartedContinuation?.resume()
        captureStartedContinuation = nil
        onListening()
        onPartial("Yes I have a reservation")
        partialWasShown = true
        guard suspendsCapture else { return captureResult }
        return await withCheckedContinuation { captureContinuation = $0 }
    }

    func stop() {
        stopCount += 1
    }

    func waitUntilCaptureStarted() async {
        if didStartCapture { return }
        await withCheckedContinuation { captureStartedContinuation = $0 }
    }

    func resumeCapture(with result: ConversationCaptureResult) {
        captureContinuation?.resume(returning: result)
        captureContinuation = nil
    }

    func invokePartial(_ transcript: String) {
        onPartialHandler?(transcript)
    }
}

private final class TestConversationRepository: ConversationRepository, @unchecked Sendable {
    var shouldFail: Bool
    var nextScript: ConversationScript

    init(shouldFail: Bool = false, nextScript: ConversationScript = .liveTestFixture) {
        self.shouldFail = shouldFail
        self.nextScript = nextScript
    }

    func nextConversation(after currentID: String) async throws -> ConversationScript {
        if shouldFail {
            throw ConversationRepositoryError.simulatedFailure
        }
        return nextScript
    }
}
