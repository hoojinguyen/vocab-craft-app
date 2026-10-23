import Foundation
import Testing
@testable import VocabCraftApp

// MARK: - Test Doubles

private final class PresentationTestRepository: PracticeRepositoryProtocol, @unchecked Sendable {
    var shouldFailPrepare = false
    var shouldFailConfirm = false
    var shouldFailRevise = false

    var persistedSession: PracticeSession?
    var persistedTurns: [PracticeTurn] = []
    var persistedExposures: [SupportExposure] = []
    var persistedEvidence: [WordUseEvidence] = []
    var persistedProgress: [CommunicationProgress] = []
    var pendingIntents: [PracticePresentationIntent] = []
    var revisions: [(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint)] = []
    var callEvents: [String] = []

    func create(_ session: PracticeSession) async throws {
        callEvents.append("create")
        persistedSession = session
    }

    func loadSession(id: UUID) async throws -> PracticeSessionSnapshot? {
        callEvents.append("loadSession")
        guard let session = persistedSession, session.id == id else { return nil }
        return PracticeSessionSnapshot(
            session: session,
            turns: persistedTurns,
            exposures: persistedExposures,
            evidence: persistedEvidence,
            progress: persistedProgress,
            pendingPresentations: pendingIntents
        )
    }

    func activeSession() async throws -> PracticeSessionSnapshot? {
        guard let session = persistedSession, session.status == .inProgress else { return nil }
        return try await loadSession(id: session.id)
    }

    func progress() async throws -> [CommunicationProgress] {
        persistedProgress
    }

    func evidence() async throws -> [WordUseEvidence] {
        persistedEvidence
    }

    func savePendingTurn(_ turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int) async throws {
        callEvents.append("savePendingTurn")
        persistedTurns.append(turn)
        if var current = persistedSession {
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: checkpoint,
                revision: current.revision,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
    }

    func commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot {
        callEvents.append("commit")
        if let turn = value.turn {
            if let index = persistedTurns.firstIndex(where: { $0.id == turn.id }) {
                persistedTurns[index] = turn
            } else {
                persistedTurns.append(turn)
            }
        }
        if let assessment = value.assessment {
            persistedEvidence.append(contentsOf: assessment.evidence)
        }
        if var current = persistedSession {
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: value.checkpoint,
                revision: current.revision,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
        guard let snapshot = try await loadSession(id: value.sessionId) else {
            throw PracticeFailure(code: .storage, message: "Session missing")
        }
        return snapshot
    }

    func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws {
        callEvents.append("preparePresentation")
        if shouldFailPrepare {
            throw PracticeFailure(code: .storage, message: "Simulated preparePresentation error")
        }
        pendingIntents.removeAll { $0.id == intent.id }
        pendingIntents.append(intent)

        if var current = persistedSession {
            var intents = current.checkpoint.presentationIntents.filter { $0.id != intent.id }
            intents.append(intent)
            let updatedCheckpoint = PracticeCheckpoint(
                pendingTurnId: current.checkpoint.pendingTurnId,
                requestId: current.checkpoint.requestId,
                presentationIntents: intents,
                exposureUncertainWordIds: current.checkpoint.exposureUncertainWordIds,
                currentSupportLevel: current.checkpoint.currentSupportLevel,
                objectiveResults: current.checkpoint.objectiveResults,
                difficultyOutcomes: current.checkpoint.difficultyOutcomes
            )
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: updatedCheckpoint,
                revision: current.revision,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
    }

    func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws {
        callEvents.append("confirmPresentation")
        if shouldFailConfirm {
            throw PracticeFailure(code: .storage, message: "Simulated confirmPresentation error")
        }
        pendingIntents.removeAll { $0.id == id }
        persistedExposures.append(exposure)

        if var current = persistedSession {
            let updatedIntents = current.checkpoint.presentationIntents.map { item in
                if item.id == id {
                    return PracticePresentationIntent(
                        id: item.id,
                        sessionId: item.sessionId,
                        turnId: item.turnId,
                        content: item.content,
                        channel: item.channel,
                        possibleWordIds: item.possibleWordIds,
                        proposedLevel: item.proposedLevel,
                        status: .confirmed,
                        origin: item.origin
                    )
                }
                return item
            }
            let updatedCheckpoint = PracticeCheckpoint(
                pendingTurnId: current.checkpoint.pendingTurnId,
                requestId: current.checkpoint.requestId,
                presentationIntents: updatedIntents,
                exposureUncertainWordIds: current.checkpoint.exposureUncertainWordIds,
                currentSupportLevel: current.checkpoint.currentSupportLevel,
                objectiveResults: current.checkpoint.objectiveResults,
                difficultyOutcomes: current.checkpoint.difficultyOutcomes
            )
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: updatedCheckpoint,
                revision: current.revision,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
    }

    func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int {
        callEvents.append("revise")
        if shouldFailRevise {
            throw PracticeFailure(code: .storage, message: "Simulated revise error")
        }
        revisions.append((sessionId, expectedRevision, checkpoint))
        let nextRevision = expectedRevision + 1
        if var current = persistedSession {
            current = PracticeSession(
                id: current.id,
                missionSnapshot: current.missionSnapshot,
                status: current.status,
                startedAt: current.startedAt,
                completedAt: current.completedAt,
                checkpoint: checkpoint,
                revision: nextRevision,
                initialInputMode: current.initialInputMode,
                policyVersion: current.policyVersion
            )
            persistedSession = current
        }
        return nextRevision
    }

    func finalize(
        sessionId: UUID,
        completion: PracticeCompletion,
        expectedRevision: Int
    ) async throws -> PracticeSummary {
        callEvents.append("finalize")
        return PracticeSummary(
            sessionId: sessionId,
            status: completion == .completed ? .completed : .partial,
            objectiveResults: [],
            perWordProgress: [],
            evidenceIds: [],
            persisted: true
        )
    }

    func deleteSession(id: UUID) async throws {}
    func deleteAllPractice() async throws {}
    func resetAllLearningProgress() async throws {}
}

private final class PresentationTestAI: PracticeAIProtocol, @unchecked Sendable {
    var respondCallCount = 0

    func capability() async -> PracticeCapability {
        PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: false,
            canPlaySpeech: false,
            providerIdentity: "test-ai"
        )
    }

    func respond(to request: PracticeAIRequest) async throws -> PracticeAIResponse {
        respondCallCount += 1
        return PracticeAIResponse(
            characterReply: "Here is your order.",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "menu"
                )
            ],
            coachFeedback: "Well done!",
            hintCandidate: "Could I have the menu?"
        )
    }
}

private final class PresentationTestSpeech: PracticeSpeechProtocol, @unchecked Sendable {
    var playedTexts: [String] = []

    func capability() -> PracticeCapability {
        PracticeCapability(
            canGenerateDialogue: false,
            canAssessUsage: false,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "test-speech"
        )
    }

    func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        playedTexts.append(text)
        return AsyncThrowingStream { continuation in
            continuation.yield(.playbackStarted)
            continuation.yield(.playbackFinished)
            continuation.finish()
        }
    }

    func stop() async {}
}

// MARK: - Test Suite

@Suite("Practice Presentation Intent, Exposure & Support Tests")
@MainActor
struct PracticePresentationTests {
    private func makeSUT(
        wordIds: [Int64] = [101]
    ) throws -> (
        coordinator: PracticeSessionCoordinator,
        repo: PresentationTestRepository,
        clock: ManualPracticeClock,
        mission: PracticeMission
    ) {
        let repo = PresentationTestRepository()
        let aiProvider = PresentationTestAI()
        let speech = PresentationTestSpeech()
        let clock = ManualPracticeClock(initialDate: Date(timeIntervalSince1970: 1_700_000_000))
        let coordinator = PracticeSessionCoordinator(
            repository: repo,
            ai: aiProvider,
            speech: speech,
            clock: clock,
            policy: .v1
        )
        let mission = try PracticeFixtures.mission(wordIds: wordIds)
        return (coordinator, repo, clock, mission)
    }

    // MARK: - Mandatory Standard Test Case

    @Test("failedConfirmationRetainsConservativeExposure keeps pending intent and blocks independence")
    func failedConfirmationRetainsConservativeExposure() async throws {
        let (coordinator, repo, clock, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)
        let sessionId = try #require(coordinator.session?.id)

        // 1. Prepare presentation intent
        let intent = await coordinator.preparePresentation(
            content: "Could I see the menu, please?",
            channel: .visual,
            origin: .coachSuggested,
            wordIds: [101],
            level: .lexical
        )
        let validIntent = try #require(intent)
        #expect(coordinator.pendingPresentations.count == 1)

        // 2. Set repository to fail on confirmPresentation
        repo.shouldFailConfirm = true

        // 3. Confirm presented fails
        clock.advance(by: .seconds(5))
        await coordinator.confirmPresented(intentId: validIntent.id, at: clock.now())

        // 4. Verify restored session checkpoint retains exposureUncertainWordIds
        guard let restored = try await repo.loadSession(id: sessionId) else {
            Issue.record("Failed to restore session from repository")
            return
        }

        #expect(restored.session.checkpoint.exposureUncertainWordIds.contains(101))

        // 5. Build evidence for word 101 with an otherwise independent usage
        let evidenceTimestamp = clock.now().addingTimeInterval(10)
        let supportPolicy = SupportPolicy()
        let isPrimed = supportPolicy.isPrimed(
            wordId: 101,
            exposures: coordinator.exposures,
            uncertainWordIds: restored.session.checkpoint.exposureUncertainWordIds,
            before: evidenceTimestamp
        )
        #expect(isPrimed == true)

        let testEvidence = WordUseEvidence(
            id: UUID(),
            sessionId: sessionId,
            turnId: UUID(),
            wordId: 101,
            objectiveId: "order_food",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            supportExposureIds: [],
            primed: isPrimed,
            contextFamily: .dining,
            inputMode: .voice,
            quotedSpan: "menu",
            assessmentVersion: 1,
            providerIdentity: "test-ai",
            status: .valid,
            timestamp: evidenceTimestamp,
            turnRevision: 1
        )

        let progressPolicy = CommunicationProgressPolicy()
        let rebuilt = progressPolicy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [testEvidence],
            now: evidenceTimestamp.addingTimeInterval(5)
        )

        #expect(rebuilt.independentEvidenceIds.isEmpty)
    }

    // MARK: - Generation without Render

    @Test("generation without render produces NO exposure")
    func generationWithoutRenderProducesNoExposure() async throws {
        let (coordinator, _, _, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)

        let intent = await coordinator.preparePresentation(
            content: "Vocabulary hint: menu",
            channel: .visual,
            origin: .coachSuggested,
            wordIds: [101],
            level: .lexical
        )
        #expect(intent != nil)
        #expect(coordinator.pendingPresentations.count == 1)
        #expect(coordinator.exposures.isEmpty)
    }

    // MARK: - Various Origins Create Valid Exposures

    @Test("prelessonReview, characterSpeech, correction, transcriptReplay create valid exposures when confirmed")
    func variousOriginsCreateValidExposuresWhenConfirmed() async throws {
        let (coordinator, _, clock, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)

        let testOrigins: [(SupportOrigin, PracticeSupportLevel, PracticePresentationChannel)] = [
            (.prelessonReview, .lexical, .visual),
            (.characterSpeech, .lexical, .audio),
            (.correction, .model, .visual),
            (.transcriptReplay, .lexical, .audio)
        ]

        for (origin, level, channel) in testOrigins {
            clock.advance(by: .seconds(2))
            let intent = await coordinator.preparePresentation(
                content: "Content for \(origin.rawValue)",
                channel: channel,
                origin: origin,
                wordIds: [101],
                level: level
            )
            let validIntent = try #require(intent)
            #expect(coordinator.pendingPresentations.contains(where: { $0.id == validIntent.id }))

            await coordinator.confirmPresented(intentId: validIntent.id, at: clock.now())
            #expect(!coordinator.pendingPresentations.contains(where: { $0.id == validIntent.id }))

            guard let recordedExposure = coordinator.exposures.last else {
                Issue.record("Expected recorded exposure for \(origin.rawValue)")
                continue
            }
            #expect(recordedExposure.origin == origin)
            #expect(recordedExposure.level == level)
            #expect(recordedExposure.channel == channel)
            #expect(recordedExposure.wordIds == [101])
        }

        #expect(coordinator.exposures.count == testOrigins.count)
    }

    // MARK: - Unknown Word Mapping

    @Test("unknown word mapping primes all mission target words conservatively")
    func unknownWordMappingPrimesAllMissionTargetsConservatively() async throws {
        let (coordinator, _, clock, mission) = try makeSUT(wordIds: [101, 102])
        await coordinator.start(mission: mission)

        let intent = await coordinator.preparePresentation(
            content: "General Scaffolding",
            channel: .visual,
            origin: .coachSuggested,
            wordIds: [],
            level: .frame
        )
        let validIntent = try #require(intent)
        #expect(Set(validIntent.possibleWordIds) == Set([101, 102]))

        await coordinator.confirmPresented(intentId: validIntent.id, at: clock.now())
        let exposure = try #require(coordinator.exposures.last)
        #expect(Set(exposure.wordIds) == Set([101, 102]))

        let supportPolicy = SupportPolicy()
        let evaluationDate = clock.now().addingTimeInterval(5)
        #expect(supportPolicy.isPrimed(wordId: 101, exposures: coordinator.exposures, before: evaluationDate) == true)
        #expect(supportPolicy.isPrimed(wordId: 102, exposures: coordinator.exposures, before: evaluationDate) == true)
    }

    // MARK: - Prepare Save Failure

    @Test("prepare save failure does not present content")
    func prepareSaveFailureDoesNotPresentContent() async throws {
        let (coordinator, repo, _, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)

        repo.shouldFailPrepare = true

        let intent = await coordinator.preparePresentation(
            content: "Unsaved prompt",
            channel: .visual,
            origin: .learnerRequested,
            wordIds: [101],
            level: .lexical
        )
        #expect(intent == nil)
        #expect(coordinator.pendingPresentations.isEmpty)
        #expect(coordinator.exposures.isEmpty)
    }

    // MARK: - Confirm Save Failure

    @Test("confirm save failure keeps pending intent and marks exposureUncertainWordIds")
    func confirmSaveFailureKeepsPendingIntentAndMarksUncertainWordIds() async throws {
        let (coordinator, repo, clock, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)

        let intent = await coordinator.preparePresentation(
            content: "Sentence frame: Would you like ___?",
            channel: .visual,
            origin: .learnerRequested,
            wordIds: [101],
            level: .frame
        )
        let validIntent = try #require(intent)

        repo.shouldFailConfirm = true

        await coordinator.confirmPresented(intentId: validIntent.id, at: clock.now())

        #expect(coordinator.pendingPresentations.contains(where: { $0.id == validIntent.id }))
        #expect(coordinator.exposures.isEmpty)
        #expect(coordinator.session?.checkpoint.exposureUncertainWordIds.contains(101) == true)
    }

    // MARK: - Crash Before Confirm Resumes Conservatively

    @Test("crash after render before confirm resumes conservatively")
    func crashAfterRenderBeforeConfirmResumesConservatively() async throws {
        let (coordinator, repo, clock, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)
        let sessionId = try #require(coordinator.session?.id)

        // Simulate crash: intent was prepared, confirm failed / app crashed, uncertainty marked in checkpoint
        let intent = await coordinator.preparePresentation(
            content: "Model: I would like a menu.",
            channel: .visual,
            origin: .learnerRequested,
            wordIds: [101],
            level: .model
        )
        let validIntent = try #require(intent)

        repo.shouldFailConfirm = true
        await coordinator.confirmPresented(intentId: validIntent.id, at: clock.now())

        // Recreate coordinator and resume session
        let aiProvider = PresentationTestAI()
        let speech = PresentationTestSpeech()
        let restoredCoordinator = PracticeSessionCoordinator(
            repository: repo,
            ai: aiProvider,
            speech: speech,
            clock: clock,
            policy: .v1
        )
        await restoredCoordinator.resume(sessionId: sessionId)

        #expect(restoredCoordinator.session?.checkpoint.exposureUncertainWordIds.contains(101) == true)

        let supportPolicy = SupportPolicy()
        let isPrimed = supportPolicy.isPrimed(
            wordId: 101,
            exposures: restoredCoordinator.exposures,
            uncertainWordIds: restoredCoordinator.session?.checkpoint.exposureUncertainWordIds ?? [],
            before: clock.now().addingTimeInterval(10)
        )
        #expect(isPrimed == true)
    }

    // MARK: - Double Tap Help Guard

    @Test("double tap help does not jump two levels")
    func doubleTapHelpDoesNotJumpTwoLevels() async throws {
        let (coordinator, _, _, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)
        #expect(coordinator.currentSupport == .none)

        // Trigger two rapid help requests
        async let firstHelp: Void = coordinator.requestHelp(fullModel: false)
        async let secondHelp: Void = coordinator.requestHelp(fullModel: false)
        _ = await (firstHelp, secondHelp)

        #expect(coordinator.currentSupport == .intent)
        #expect(coordinator.pendingPresentations.count == 1)
        #expect(coordinator.pendingPresentations.first?.proposedLevel == .intent)
    }

    // MARK: - Full Model Request

    @Test("full model request goes straight to model")
    func fullModelRequestGoesStraightToModel() async throws {
        let (coordinator, _, _, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)
        #expect(coordinator.currentSupport == .none)

        await coordinator.requestHelp(fullModel: true)

        #expect(coordinator.currentSupport == .model)
        #expect(coordinator.pendingPresentations.last?.proposedLevel == .model)
    }

    // MARK: - Intent-Only Does Not Cause Lexical Priming

    @Test("intent-only does not cause lexical priming")
    func intentOnlyDoesNotCauseLexicalPriming() async throws {
        let (coordinator, _, clock, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)

        let intent = await coordinator.preparePresentation(
            content: "Remember to state what you need politely.",
            channel: .visual,
            origin: .learnerRequested,
            wordIds: [101],
            level: .intent
        )
        let validIntent = try #require(intent)
        await coordinator.confirmPresented(intentId: validIntent.id, at: clock.now())

        #expect(coordinator.exposures.count == 1)
        #expect(coordinator.exposures.first?.level == .intent)

        let supportPolicy = SupportPolicy()
        let isPrimed = supportPolicy.isPrimed(
            wordId: 101,
            exposures: coordinator.exposures,
            uncertainWordIds: coordinator.session?.checkpoint.exposureUncertainWordIds ?? [],
            before: clock.now().addingTimeInterval(5)
        )
        #expect(isPrimed == false)
    }

    // MARK: - Retry With Less Support

    @Test("retry with less support fades level and preserves prior priming")
    func retryWithLessSupportFadesLevelAndPreservesPriming() async throws {
        let (coordinator, _, clock, mission) = try makeSUT(wordIds: [101])
        await coordinator.start(mission: mission)

        // Request help up to model
        await coordinator.requestHelp(fullModel: true)
        #expect(coordinator.currentSupport == .model)

        let intent = try #require(coordinator.pendingPresentations.last)
        await coordinator.confirmPresented(intentId: intent.id, at: clock.now())
        #expect(coordinator.exposures.count == 1)

        // Retry with less support fades .model -> .frame
        await coordinator.retryWithLessSupport()
        #expect(coordinator.currentSupport == .frame)

        // Exposures are retained, attempt remains primed
        let supportPolicy = SupportPolicy()
        let isPrimed = supportPolicy.isPrimed(
            wordId: 101,
            exposures: coordinator.exposures,
            uncertainWordIds: coordinator.session?.checkpoint.exposureUncertainWordIds ?? [],
            before: clock.now().addingTimeInterval(10)
        )
        #expect(isPrimed == true)

        // Retry again fades .frame -> .lexical
        await coordinator.retryWithLessSupport()
        #expect(coordinator.currentSupport == .lexical)

        // Retry again fades .lexical -> .intent
        await coordinator.retryWithLessSupport()
        #expect(coordinator.currentSupport == .intent)

        // Retry again fades .intent -> .none
        await coordinator.retryWithLessSupport()
        #expect(coordinator.currentSupport == .none)
    }
}
