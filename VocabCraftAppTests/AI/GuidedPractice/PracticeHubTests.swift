import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Practice Hub Tests")
struct PracticeHubTests {
    private func makeDTO(id: Int64, lemma: String) -> TopicWordDTO {
        TopicWordDTO(
            id: id,
            stageId: "stage_daily_1",
            lemma: lemma,
            phonetic: "/\(lemma)/",
            pos: "noun",
            cefrLevel: "A2",
            definitionVi: "Nghĩa tiếng Việt của \(lemma)",
            definitionEn: "English definition of \(lemma)",
            exampleEn: "Example sentence with \(lemma).",
            exampleVi: "Câu ví dụ với \(lemma)."
        )
    }

    private func makeProgress(
        wordId: Int64,
        totalReviews: Int = 1,
        masteryLevel: Int = 1,
        isBookmarked: Bool = false
    ) -> UserWordProgressData {
        UserWordProgressData(
            wordId: wordId,
            cefrLevel: "A2",
            masteryLevel: masteryLevel,
            isBookmarked: isBookmarked,
            nextReviewDate: Date(timeIntervalSince1970: 1_700_100_000),
            lastReviewDate: Date(timeIntervalSince1970: 1_700_000_000),
            totalReviews: totalReviews,
            needsReview: false,
            mistakeCount: 0,
            sourceDeckId: "deck_1",
            sourceNodeId: "node_1"
        )
    }

    @Test("Resumable active session wins over recommendation, concealed target words")
    @MainActor
    func resumableSessionWinsOverRecommendation() async throws {
        let existingID = UUID()
        let mission = try PracticeMission(
            id: UUID(),
            templateId: "dining_basic_v1",
            templateVersion: 1,
            targetWordIds: [4, 11],
            wordSnapshots: [
                PracticeWordSnapshot(wordId: 4, lemma: "Gratitude", definitionEn: "thanks", definitionVi: "cảm ơn"),
                PracticeWordSnapshot(wordId: 11, lemma: "Hesitate", definitionEn: "pause", definitionVi: "ngập ngừng")
            ],
            objectiveIds: ["order_food"],
            contextFamily: .dining,
            difficulty: try PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0),
            selectionReasons: [.noCommunicationEvidence],
            createdAt: Date()
        )
        let activeSession = PracticeSession(
            id: existingID,
            missionSnapshot: mission,
            status: .inProgress,
            startedAt: Date(),
            checkpoint: PracticeCheckpoint(),
            revision: 0
        )
        let snapshot = PracticeSessionSnapshot(session: activeSession)

        let vocab = TestVocabularyDataSource()
        let userProgress = TestUserProgressRepository()
        let practiceRepo = TestPracticeRepository(activeSession: snapshot)
        let reader = PracticeLearningContextReader(
            vocabularyDataSource: vocab,
            progressRepository: userProgress,
            practiceRepository: practiceRepo
        )

        let model = PracticeHubViewModel(
            contextReader: reader,
            repository: practiceRepo
        )

        await model.load()

        let shownTargetWords = model.shownTargetWords
        #expect(model.state == .resumable(existingID))
        #expect(shownTargetWords.isEmpty)
    }

    @Test("Data failure produces error state without fabricating demo data")
    @MainActor
    func dataFailureDoesNotDemoOrFabricateData() async {
        struct TestStorageError: Error, LocalizedError {
            var errorDescription: String? { "Disk read corrupted" }
        }

        let vocab = TestVocabularyDataSource()
        let userProgress = TestUserProgressRepository()
        let practiceRepo = TestPracticeRepository()
        practiceRepo.shouldThrowError = TestStorageError()

        let reader = PracticeLearningContextReader(
            vocabularyDataSource: vocab,
            progressRepository: userProgress,
            practiceRepository: practiceRepo
        )

        let model = PracticeHubViewModel(
            contextReader: reader,
            repository: practiceRepo
        )

        await model.load()

        guard case .error(let failure) = model.state else {
            Issue.record("Expected error state on repository failure, got \(model.state)")
            return
        }
        #expect(failure.code == .storage)
        #expect(failure.underlyingError?.contains("Disk read corrupted") == true)
        #expect(model.shownTargetWords.isEmpty)
    }

    @Test("Needs vocabulary state when insufficient learned words exist (< 2)")
    @MainActor
    func needsVocabularyWhenInsufficientLearnedWords() async {
        let vocab = TestVocabularyDataSource(words: [
            makeDTO(id: 4, lemma: "Gratitude")
        ])
        // Only 1 learned word (< 2)
        let userProgress = TestUserProgressRepository(progress: [
            makeProgress(wordId: 4, totalReviews: 2, masteryLevel: 1)
        ])
        let practiceRepo = TestPracticeRepository()
        let reader = PracticeLearningContextReader(
            vocabularyDataSource: vocab,
            progressRepository: userProgress,
            practiceRepository: practiceRepo
        )

        let model = PracticeHubViewModel(
            contextReader: reader,
            repository: practiceRepo
        )

        await model.load()

        #expect(model.state == .needsVocabulary)
    }

    @Test("No compatible template state when learned words do not match catalog")
    @MainActor
    func noCompatibleTemplateWhenCandidatesDoNotMatchTemplates() async {
        let vocab = TestVocabularyDataSource(words: [
            makeDTO(id: 888, lemma: "Astronomical"),
            makeDTO(id: 999, lemma: "Quantum")
        ])
        // 2 learned words, but neither is supported by any curated template
        let userProgress = TestUserProgressRepository(progress: [
            makeProgress(wordId: 888, totalReviews: 3, masteryLevel: 2),
            makeProgress(wordId: 999, totalReviews: 3, masteryLevel: 2)
        ])
        let practiceRepo = TestPracticeRepository()
        let reader = PracticeLearningContextReader(
            vocabularyDataSource: vocab,
            progressRepository: userProgress,
            practiceRepository: practiceRepo
        )

        let model = PracticeHubViewModel(
            contextReader: reader,
            repository: practiceRepo
        )

        await model.load()

        #expect(model.state == .noCompatibleTemplate)
    }

    @Test("Normal happy path constructs recommended mission")
    @MainActor
    func recommendedMissionConstructedWhenValid() async {
        let vocab = TestVocabularyDataSource(words: [
            makeDTO(id: 4, lemma: "Gratitude"),
            makeDTO(id: 11, lemma: "Hesitate")
        ])
        let userProgress = TestUserProgressRepository(progress: [
            makeProgress(wordId: 4, totalReviews: 2, masteryLevel: 1),
            makeProgress(wordId: 11, totalReviews: 2, masteryLevel: 1)
        ])
        let practiceRepo = TestPracticeRepository()
        let reader = PracticeLearningContextReader(
            vocabularyDataSource: vocab,
            progressRepository: userProgress,
            practiceRepository: practiceRepo
        )

        let model = PracticeHubViewModel(
            contextReader: reader,
            repository: practiceRepo
        )

        await model.load()

        guard case .recommended(let mission) = model.state else {
            Issue.record("Expected recommended mission, got \(model.state)")
            return
        }
        #expect(mission.templateId == "dining_basic_v1")
        #expect(mission.targetWordIds.contains(4))
        #expect(mission.targetWordIds.contains(11))
    }

    @Test("Preflight checks voice mic permission without blocking text mode")
    func preflightChecksVoiceCapabilityWithoutBlockingText() {
        let aiCap = PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: false,
            canPlaySpeech: true,
            providerIdentity: "test"
        )
        let speechCap = PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: false,
            canPlaySpeech: true,
            providerIdentity: "test"
        )

        // Voice mode should require microphone permission
        let voiceResult = PracticePreparationView.preflight(
            mode: .voice,
            aiCapability: aiCap,
            speechCapability: speechCap
        )
        #expect(voiceResult == .speechCaptureRequired(message: AppStrings.GuidedPractice.voicePermissionRequired))

        // Text mode should be completely ready despite disabled microphone
        let textResult = PracticePreparationView.preflight(
            mode: .typed,
            aiCapability: aiCap,
            speechCapability: speechCap
        )
        #expect(textResult == .ready)
    }

    @Test("Missing LLM generation capability rejects both voice and text with clear error")
    func missingLLMDoesNotAdvertiseTextRecovery() {
        let aiCap = PracticeCapability(
            canGenerateDialogue: false,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "test",
            unavailableReason: "Offline"
        )
        let speechCap = PracticeCapability(
            canGenerateDialogue: false,
            canAssessUsage: true,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "test"
        )

        let voiceResult = PracticePreparationView.preflight(
            mode: .voice,
            aiCapability: aiCap,
            speechCapability: speechCap
        )
        #expect(voiceResult == .llmUnavailable(message: AppStrings.GuidedPractice.llmUnavailable))

        let textResult = PracticePreparationView.preflight(
            mode: .typed,
            aiCapability: aiCap,
            speechCapability: speechCap
        )
        #expect(textResult == .llmUnavailable(message: AppStrings.GuidedPractice.llmUnavailable))
    }

    @Test("Preparation view target words concealed initially")
    @MainActor
    func preparationViewTargetWordsConcealedInitially() throws {
        let mission = try PracticeMission(
            id: UUID(),
            templateId: "dining_basic_v1",
            templateVersion: 1,
            targetWordIds: [4, 11],
            wordSnapshots: [
                PracticeWordSnapshot(wordId: 4, lemma: "Gratitude", definitionEn: "thanks", definitionVi: "cảm ơn"),
                PracticeWordSnapshot(wordId: 11, lemma: "Hesitate", definitionEn: "pause", definitionVi: "ngập ngừng")
            ],
            objectiveIds: ["order_food"],
            contextFamily: .dining,
            difficulty: try PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0),
            selectionReasons: [.noCommunicationEvidence],
            createdAt: Date()
        )

        let prepView = PracticePreparationView(
            mission: mission,
            coordinator: nil,
            onStart: { _, _ in },
            onBack: {}
        )

        #expect(prepView.shownTargetWords.isEmpty)
    }
}
