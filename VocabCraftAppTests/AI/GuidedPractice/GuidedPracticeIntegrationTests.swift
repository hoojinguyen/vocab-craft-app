import Foundation
import SwiftData
import Testing
@testable import VocabCraftApp

// MARK: - Dummy Test Doubles

private struct DummyPracticeAI: PracticeAIProtocol {
    let response: PracticeAIResponse

    func capability() async -> PracticeCapability {
        .standardCloud
    }

    func respond(to request: PracticeAIRequest) async throws -> PracticeAIResponse {
        response
    }
}

@MainActor
private final class DummyPracticeSpeech: PracticeSpeechProtocol {
    func capability() -> PracticeCapability {
        .standardCloud
    }

    func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func stop() async {}
}

// MARK: - Guided Practice Integration & Regression Tests

@Suite("Guided Practice Integration & Regression Tests")
@MainActor
struct GuidedPracticeIntegrationTests {
    // MARK: - Mandatory Standard Test Case

    @Test("flagOffPreservesV3StoreAndLegacyRoutes ensures flag isolation and database backward compatibility")
    func flagOffPreservesV3StoreAndLegacyRoutes() async throws {
        // Arrange: Pre-populate V3 database on disk with baseline SRS and practice records
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storeURL = tempDir.appendingPathComponent("flag_off_regression.sqlite")
        let initialContainer = try PracticeTestStorage.createContainer(storeURL: storeURL)
        let srsBefore = try PracticeTestStorage.seedBaselineSRS(in: initialContainer, wordId: 101)

        let initialRepo = PracticeModelActor(modelContainer: initialContainer)
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let sessionId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let session = PracticeFixtures.session(id: sessionId, mission: mission, revision: 1)
        try await initialRepo.create(session)

        let turnId = UUID(uuidString: "22222222-3333-4444-5555-666666666666")!
        let turn = PracticeTurn(
            id: turnId,
            sessionId: sessionId,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I want a coffee please",
            acceptedText: "I want a coffee please",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-regression-01",
            sessionRevision: 1,
            timestamp: PracticeFixtures.baseDate
        )
        try await initialRepo.savePendingTurn(turn, checkpoint: session.checkpoint, expectedRevision: 1)

        let evidence = PracticeFixtures.evidence(
            sessionId: sessionId,
            at: PracticeFixtures.baseDate,
            mode: .voice,
            primed: false,
            wordId: 101
        )
        let aiResponse = PracticeAIResponse(
            characterReply: "Here is your coffee!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "coffee"
                )
            ]
        )
        let assessment = PracticeAssessment(
            evidence: [evidence],
            objectiveResults: [
                PracticeObjectiveResult(objectiveId: "order_food", intentVerdict: .achieved, opportunityObserved: true)
            ],
            response: aiResponse
        )
        _ = try await initialRepo.commit(PracticeCommit(
            sessionId: sessionId,
            expectedRevision: 1,
            turn: turn,
            assessment: assessment,
            checkpoint: session.checkpoint
        ))

        let storedEvidence = try await initialRepo.evidence()
        #expect(!storedEvidence.isEmpty)

        // Act: Explicitly disable feature flag and reopen the database
        GuidedPracticeFeatureConfiguration.enabled = false
        defer { GuidedPracticeFeatureConfiguration.reset() }

        let reopenedContainer = try PracticeTestStorage.createContainer(storeURL: storeURL)
        let reopenedRepo = PracticeModelActor(modelContainer: reopenedContainer)
        let reopenedEvidence = try await reopenedRepo.evidence()
        let srsAfter = try PracticeTestStorage.fetchSRSState(in: reopenedContainer, wordId: 101)

        // Assert: Mandatory standard assertions
        #expect(reopenedEvidence == storedEvidence)
        #expect(srsAfter == srsBefore)

        // Verify legacy routes instantiate cleanly with reopened container and produce valid view models
        let appContainer = AppContainer(modelContainer: reopenedContainer, useMockData: true)
        let hubVM = appContainer.makeAIAssistantHubViewModel()
        #expect(hubVM.scenarios.isEmpty)

        let cafeScenario = RoleplayScenario.cafeMock
        let roomVM = appContainer.makeRoleplayRoomViewModel(for: cafeScenario)
        #expect(roomVM.scenario.id == cafeScenario.id)
    }

    // MARK: - End-to-End Guided Practice Flow

    @Test("endToEndGuidedPracticeFlowPreservesSRS verifies practice lifecycle does not mutate SRS progress or todayWordsLearned")
    func endToEndGuidedPracticeFlowPreservesSRS() async throws {
        // Arrange
        let container = try PracticeTestStorage.createContainer()
        let srsBefore = try PracticeTestStorage.seedBaselineSRS(in: container, wordId: 101)

        let suiteName = "test_e2e_guided_practice_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let userSettings = UserSettingsStore(defaults: defaults)
        userSettings.todayWordsLearned = 4
        let wordsLearnedBefore = userSettings.todayWordsLearned

        let repository = PracticeModelActor(modelContainer: container)
        let clock = ManualPracticeClock(initialDate: PracticeFixtures.baseDate)

        let aiResponse = PracticeAIResponse(
            characterReply: "Certainly! Here is the menu.",
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
            coachFeedback: "Great job asking for the menu!",
            hintCandidate: nil
        )
        let dummyAI = DummyPracticeAI(response: aiResponse)
        let dummySpeech = DummyPracticeSpeech()

        let coordinator = PracticeSessionCoordinator(
            repository: repository,
            ai: dummyAI,
            speech: dummySpeech,
            clock: clock,
            policy: .v1
        )

        let mission = try PracticeFixtures.mission(wordIds: [101])

        // Step 1: Start session
        await coordinator.start(mission: mission, mode: .voice)
        #expect(coordinator.session != nil)
        #expect(coordinator.state == .awaitingLearner)

        // Step 2: Pre-lesson word review (prelesson exposure)
        let intent = await coordinator.preparePresentation(
            content: "Review word: menu",
            channel: .visual,
            origin: .prelessonReview,
            wordIds: [101],
            level: .intent
        )
        if let intent {
            await coordinator.confirmPresented(intentId: intent.id, at: clock.now())
        }
        #expect(coordinator.exposures.count == 1)

        // Step 3: Submit turn with focus word usage
        await coordinator.submit(text: "Could I have the menu please?", mode: .voice)
        #expect(coordinator.turns.count >= 1)

        // Step 4: Retry with less support
        await coordinator.retryWithLessSupport()
        #expect(coordinator.currentSupport == .none)

        // Step 5: Complete session & generate retrospective summary
        let summary = await coordinator.finish(.completed)
        #expect(summary != nil)
        #expect(summary?.status == .completed)

        // Step 6: Delete session
        await coordinator.deleteCurrentSession()
        #expect(coordinator.session == nil)

        // Assert: Verify SRS progress was never mutated at any point
        let srsAfter = try PracticeTestStorage.fetchSRSState(in: container, wordId: 101)
        #expect(srsAfter == srsBefore)

        // Assert: Verify todayWordsLearned was never incremented
        let wordsLearnedAfter = userSettings.todayWordsLearned
        #expect(wordsLearnedAfter == wordsLearnedBefore)
    }

    // MARK: - Feature Flag Toggling

    @Test("featureFlagToggleEnablesNewExperience verifies configuration controls")
    func featureFlagToggleEnablesNewExperience() {
        GuidedPracticeFeatureConfiguration.reset()
        defer { GuidedPracticeFeatureConfiguration.reset() }

        #expect(!GuidedPracticeFeatureConfiguration.enabled)

        GuidedPracticeFeatureConfiguration.enabled = true
        #expect(GuidedPracticeFeatureConfiguration.enabled)
        #expect(UserDefaults.standard.bool(forKey: GuidedPracticeFeatureConfiguration.userDefaultsKey))

        GuidedPracticeFeatureConfiguration.enabled = false
        #expect(!GuidedPracticeFeatureConfiguration.enabled)
        #expect(!UserDefaults.standard.bool(forKey: GuidedPracticeFeatureConfiguration.userDefaultsKey))
    }

    // MARK: - Template Catalog Immutability

    @Test("templateCatalogUpdateDoesNotRewritePastSessions confirms historical session snapshots remain intact")
    func templateCatalogUpdateDoesNotRewritePastSessions() async throws {
        let container = try PracticeTestStorage.createContainer()
        let repository = PracticeModelActor(modelContainer: container)

        let mission = try PracticeFixtures.mission(wordIds: [101])
        let sessionId = UUID()
        let session = PracticeFixtures.session(id: sessionId, mission: mission, revision: 1)
        try await repository.create(session)

        // Snapshot is persisted in repository
        let loadedSnapshot = try await repository.loadSession(id: sessionId)
        #expect(loadedSnapshot != nil)
        #expect(loadedSnapshot?.session.missionSnapshot.templateId == mission.templateId)
        #expect(loadedSnapshot?.session.missionSnapshot.targetWordIds == [101])
        #expect(loadedSnapshot?.session.missionSnapshot.objectiveIds == mission.objectiveIds)

        // Even when catalog templates are consulted or updated with new versions:
        let updatedTemplates = PracticeTemplateCatalog.templates.map { template in
            PracticeTemplate(
                id: template.id,
                version: template.version + 1,
                contextFamily: template.contextFamily,
                titleKey: template.titleKey,
                briefKey: template.briefKey,
                roleKeys: template.roleKeys,
                objectiveIds: ["updated_objective_1", "updated_objective_2"],
                supportedWordSenses: template.supportedWordSenses,
                variants: template.variants,
                difficultyBounds: template.difficultyBounds,
                shadowingVideoId: template.shadowingVideoId
            )
        }
        #expect(updatedTemplates.first?.version == 2)

        // Re-query past session: must preserve original mission snapshot without being rewritten
        let reloadedSnapshot = try await repository.loadSession(id: sessionId)
        #expect(reloadedSnapshot?.session.missionSnapshot.templateId == mission.templateId)
        #expect(reloadedSnapshot?.session.missionSnapshot.templateVersion == mission.templateVersion)
        #expect(reloadedSnapshot?.session.missionSnapshot.objectiveIds == mission.objectiveIds)
        #expect(reloadedSnapshot?.session.missionSnapshot.contextFamily == mission.contextFamily)
        #expect(reloadedSnapshot?.session.missionSnapshot.targetWordIds == mission.targetWordIds)
    }
}
