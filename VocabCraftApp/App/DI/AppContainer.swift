import Foundation
import SpeechKit
import SwiftData

/// Centralized Composition Root / Dependency Injection Container.
@MainActor
public final class AppContainer {
    // MARK: - Configuration
    /// Toggle to switch between curated sample dataset and production data source.
    public let useSampleData: Bool

    public let datasetEngine: DatasetEngine?
    public let modelContainer: ModelContainer?

    // MARK: - Data Sources & Repositories
    public let vocabularyDataSource: VocabularyDataSourceProtocol
    public let stageProgressRepository: StageProgressRepositoryProtocol
    public let userProgressRepository: any UserProgressRepositoryProtocol

    public let vocabularyRepository: VocabularyRepositoryProtocol
    public let srsRepository: SRSRepositoryProtocol
    public let quickReflexAttemptRepository: QuickReflexAttemptRepositoryProtocol

    // MARK: - Services
    public let ttsService: TextToSpeechProtocol
    public let sttService: SpeechRecognitionProtocol
    public let speechAssessmentService: SpeechAssessmentProtocol

    // MARK: - Domain Use Cases
    public let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    public let resetUserProgressUseCase: ResetUserProgressUseCaseProtocol

    public let fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol
    public let completeLessonUseCase: CompleteLessonUseCaseProtocol

    public let fetchTopicDecksUseCase: FetchTopicDecksUseCaseProtocol
    public let fetchDeckRoadmapUseCase: FetchDeckRoadmapUseCaseProtocol
    public let completeStageChallengeUseCase: CompleteStageChallengeUseCaseProtocol
    public let fetchPersonalVaultUseCase: FetchPersonalVaultUseCaseProtocol
    public let reviewWeakWordsUseCase: ReviewWeakWordsUseCaseProtocol
    public let toggleWordBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol
    public let generateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol
    public let practiceDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol
    public let recordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol

    // MARK: - Stores & Navigation
    public let userSettingsStore: UserSettingsStore
    public let appRouter: AppRouter

    public init(
        datasetEngine: DatasetEngine? = nil,
        modelContainer: ModelContainer? = nil,
        useMockData: Bool? = nil,
        useSampleData: Bool = true,
        vocabularyDataSource: VocabularyDataSourceProtocol? = nil,
        stageProgressRepository: StageProgressRepositoryProtocol? = nil,
        userProgressRepository: (any UserProgressRepositoryProtocol)? = nil,
        fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol? = nil,
        completeLessonUseCase: CompleteLessonUseCaseProtocol? = nil,
        generateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol? = nil,
        practiceDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol? = nil,
        recordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        speechAssessmentService: SpeechAssessmentProtocol? = nil,
        userSettingsStore: UserSettingsStore? = nil,
        appRouter: AppRouter? = nil
    ) {
        self.useSampleData = useSampleData
        self.datasetEngine = datasetEngine
        self.modelContainer = modelContainer

        let progressActor: UserProgressModelActor? = modelContainer.map { UserProgressModelActor(modelContainer: $0) }
        let resolvedUserProgressRepo: any UserProgressRepositoryProtocol = userProgressRepository
            ?? (progressActor ?? MockUserProgressRepository())
        self.userProgressRepository = resolvedUserProgressRepo

        let resolvedDataSource: VocabularyDataSourceProtocol = vocabularyDataSource
            ?? (useSampleData ? SampleVocabularyDataSource() : SampleVocabularyDataSource())
        self.vocabularyDataSource = resolvedDataSource

        let resolvedStageRepo: StageProgressRepositoryProtocol = stageProgressRepository
            ?? (modelContainer.map { StageProgressRepositoryImpl(modelContext: $0.mainContext) } ?? MockStageProgressRepository())
        self.stageProgressRepository = resolvedStageRepo

        let shouldMock = useMockData ?? (datasetEngine == nil)
        let vocabRepo: VocabularyRepositoryProtocol = shouldMock
            ? MockVocabularyRepository()
            : VocabularyRepositoryImpl(datasetEngine: datasetEngine, progressActor: progressActor)
        let srsRepo = SRSRepositoryImpl(modelContext: modelContainer?.mainContext)
        let quickReflexAttemptRepo = QuickReflexAttemptRepositoryImpl(modelContext: modelContainer?.mainContext)

        self.vocabularyRepository = vocabRepo
        self.srsRepository = srsRepo
        self.quickReflexAttemptRepository = quickReflexAttemptRepo

        let resolvedTTS = ttsService ?? TextToSpeechService()
        self.ttsService = resolvedTTS
        self.sttService = sttService ?? SpeechRecognitionService()
        self.speechAssessmentService = speechAssessmentService ?? SpeechAssessmentService()

        // Existing Use Cases
        self.evaluateSRSUseCase = EvaluateSRSUseCase(srsRepository: srsRepo)
        self.resetUserProgressUseCase = ResetUserProgressUseCase(srsRepository: srsRepo)

        // Learning Path Use Cases
        self.fetchLearningPathUseCase = fetchLearningPathUseCase ?? FetchLearningPathUseCase(
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo
        )
        self.completeLessonUseCase = completeLessonUseCase ?? CompleteLessonUseCase(
            stageRepo: resolvedStageRepo,
            progressRepo: resolvedUserProgressRepo
        )

        // Vocabulary Hub Use Cases
        self.fetchTopicDecksUseCase = FetchTopicDecksUseCase(
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo
        )
        self.fetchDeckRoadmapUseCase = FetchDeckRoadmapUseCase(
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo
        )
        self.completeStageChallengeUseCase = CompleteStageChallengeUseCase(
            stageRepo: resolvedStageRepo,
            progressRepo: resolvedUserProgressRepo
        )
        self.fetchPersonalVaultUseCase = FetchPersonalVaultUseCase(
            dataSource: resolvedDataSource,
            progressRepo: resolvedUserProgressRepo
        )
        self.reviewWeakWordsUseCase = ReviewWeakWordsUseCase(
            dataSource: resolvedDataSource,
            progressRepo: resolvedUserProgressRepo
        )
        self.toggleWordBookmarkUseCase = ToggleWordBookmarkUseCase(
            progressRepo: resolvedUserProgressRepo
        )
        self.generateMixedReflexQueueUseCase = generateMixedReflexQueueUseCase ?? GenerateMixedReflexQueueUseCase()
        self.practiceDrillPlanGenerator = practiceDrillPlanGenerator ?? PracticeDrillPlanGenerator()
        self.recordMixedDrillAttemptUseCase = recordMixedDrillAttemptUseCase ?? RecordMixedDrillAttemptUseCase(
            progressRepo: resolvedUserProgressRepo,
            dataSource: resolvedDataSource
        )

        self.userSettingsStore = userSettingsStore ?? UserSettingsStore()
        self.appRouter = appRouter ?? AppRouter()
    }

    // MARK: - Use Case Factories

    public func makeFetchLearningPathUseCase() -> FetchLearningPathUseCaseProtocol {
        fetchLearningPathUseCase
    }

    public func makeCompleteLessonUseCase() -> CompleteLessonUseCaseProtocol {
        completeLessonUseCase
    }

    public func makeGenerateMixedReflexQueueUseCase() -> GenerateMixedReflexQueueUseCaseProtocol {
        generateMixedReflexQueueUseCase
    }

    public func makeRecordMixedDrillAttemptUseCase() -> RecordMixedDrillAttemptUseCaseProtocol {
        recordMixedDrillAttemptUseCase
    }

    // MARK: - View Model Factories

    public func makeTopicDecksViewModel() -> TopicDecksViewModel {
        TopicDecksViewModel(
            fetchTopicDecksUseCase: fetchTopicDecksUseCase
        )
    }

    public func makeTopicRoadmapViewModel(deckId: String) -> TopicRoadmapViewModel {
        TopicRoadmapViewModel(
            deckId: deckId,
            fetchDeckRoadmapUseCase: fetchDeckRoadmapUseCase
        )
    }

    public func makeStageChallengeViewModel(stage: SubTopicStage) -> StageChallengeViewModel {
        StageChallengeViewModel(
            stage: stage,
            completeUseCase: completeStageChallengeUseCase,
            ttsService: ttsService
        )
    }

    public func makePersonalVaultViewModel() -> PersonalVaultViewModel {
        PersonalVaultViewModel(
            fetchVaultUseCase: fetchPersonalVaultUseCase,
            toggleBookmarkUseCase: toggleWordBookmarkUseCase,
            ttsService: ttsService,
            userSettingsStore: userSettingsStore
        )
    }

    public func makeSmartReviewViewModel(weakWords: [PersonalWord] = []) -> SmartReviewViewModel {
        SmartReviewViewModel(
            weakWords: weakWords,
            reviewUseCase: reviewWeakWordsUseCase,
            ttsService: ttsService
        )
    }

    public func makeHomepageViewModel() -> HomepageViewModel {
        HomepageViewModel(
            fetchLearningPathUseCase: fetchLearningPathUseCase,
            ttsService: ttsService
        )
    }

    public func makeReflexSpeechEngine() -> ReflexSpeechEngineProtocol {
        ResilientReflexSpeechEngine()
    }

    public func makeReflexBlitzViewModel(words: [ReflexBlitzWordItem] = []) -> ReflexBlitzViewModel {
        let blitzWords = !words.isEmpty ? words : ReflexBlitzWordItem.defaultStarterWords
        return ReflexBlitzViewModel(
            words: blitzWords,
            ttsService: ttsService,
            evaluateSRSUseCase: evaluateSRSUseCase,
            speechEngine: makeReflexSpeechEngine()
        )
    }

    public func makeMixedReflexDrillViewModel(
        selectedWords: [VaultWordItem],
        allowSpeakingSkip: Bool = false
    ) -> MixedReflexDrillViewModel {
        MixedReflexDrillViewModel(
            selectedWords: selectedWords,
            queueUseCase: generateMixedReflexQueueUseCase,
            planGenerator: practiceDrillPlanGenerator,
            recordAttemptUseCase: recordMixedDrillAttemptUseCase,
            ttsService: ttsService,
            allowSpeakingSkip: allowSpeakingSkip
        )
    }

    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            store: userSettingsStore,
            ttsService: ttsService,
            resetProgressUseCase: resetUserProgressUseCase
        )
    }

    public static var mock: AppContainer {
        AppContainer(useMockData: true, useSampleData: true)
    }
    public static let shared = AppContainer(useMockData: false, useSampleData: false)
}
