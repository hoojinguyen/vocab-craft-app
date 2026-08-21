import Foundation
import SwiftData

/// Centralized Composition Root / Dependency Injection Container.
@MainActor
public final class AppContainer {
    public let datasetEngine: DatasetEngine?
    public let modelContainer: ModelContainer?

    public let vocabularyRepository: VocabularyRepositoryProtocol
    public let srsRepository: SRSRepositoryProtocol
    public let quickReflexAttemptRepository: QuickReflexAttemptRepositoryProtocol

    public let ttsService: TextToSpeechProtocol
    public let sttService: SpeechRecognitionProtocol
    public let speechAssessmentService: SpeechAssessmentProtocol

    public let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol
    public let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    public let resetUserProgressUseCase: ResetUserProgressUseCaseProtocol

    public let userSettingsStore: UserSettingsStore
    public let appRouter: AppRouter

    public init(
        datasetEngine: DatasetEngine? = nil,
        modelContainer: ModelContainer? = nil,
        useMockData: Bool? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        speechAssessmentService: SpeechAssessmentProtocol? = nil,
        userSettingsStore: UserSettingsStore? = nil,
        appRouter: AppRouter? = nil
    ) {
        self.datasetEngine = datasetEngine
        self.modelContainer = modelContainer

        let progressActor: UserProgressModelActor? = modelContainer.map { UserProgressModelActor(modelContainer: $0) }

        let shouldMock = useMockData ?? (datasetEngine == nil)
        let vocabRepo: VocabularyRepositoryProtocol = shouldMock
            ? MockVocabularyRepository()
            : VocabularyRepositoryImpl(datasetEngine: datasetEngine, progressActor: progressActor)
        let srsRepo = SRSRepositoryImpl(modelContext: modelContainer?.mainContext)
        let quickReflexAttemptRepo = QuickReflexAttemptRepositoryImpl(modelContext: modelContainer?.mainContext)

        self.vocabularyRepository = vocabRepo
        self.srsRepository = srsRepo
        self.quickReflexAttemptRepository = quickReflexAttemptRepo

        self.ttsService = ttsService ?? TextToSpeechService()
        self.sttService = sttService ?? SpeechRecognitionService()
        self.speechAssessmentService = speechAssessmentService ?? SpeechAssessmentService()

        self.fetchVocabularyUseCase = FetchVocabularyUseCase(repository: vocabRepo)
        self.evaluateSRSUseCase = EvaluateSRSUseCase(srsRepository: srsRepo)
        self.resetUserProgressUseCase = ResetUserProgressUseCase(srsRepository: srsRepo)

        self.userSettingsStore = userSettingsStore ?? UserSettingsStore()
        self.appRouter = appRouter ?? AppRouter()
    }

    public func makeHomepageViewModel() -> HomepageViewModel {
        HomepageViewModel(
            fetchVocabularyUseCase: fetchVocabularyUseCase,
            ttsService: ttsService
        )
    }

    public func makeReflexDrillViewModel(cefrLevel: String = "B1") -> ReflexDrillViewModel {
        ReflexDrillViewModel(
            fetchVocabularyUseCase: fetchVocabularyUseCase,
            evaluateSRSUseCase: evaluateSRSUseCase,
            ttsService: ttsService,
            sttService: sttService,
            speechAssessmentService: speechAssessmentService,
            cefrLevel: cefrLevel
        )
    }

    public func makeReflexBlitzViewModel(words: [ReflexBlitzWordItem] = []) -> ReflexBlitzViewModel {
        let blitzWords = !words.isEmpty ? words : ReflexBlitzWordItem.defaultStarterWords
        return ReflexBlitzViewModel(
            words: blitzWords,
            continuousSpeechService: ContinuousReflexSpeechService(),
            ttsService: ttsService,
            evaluateSRSUseCase: evaluateSRSUseCase
        )
    }

    public func makeStudySessionViewModel(words: [TopicWord]) -> StudySessionViewModel {
        StudySessionViewModel(
            words: words,
            ttsService: ttsService
        )
    }

    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            store: userSettingsStore,
            ttsService: ttsService,
            resetProgressUseCase: resetUserProgressUseCase
        )
    }

    public func makeVocabularyViewModel() -> VocabularyViewModel {
        VocabularyViewModel(
            fetchVocabularyUseCase: fetchVocabularyUseCase,
            ttsService: ttsService
        )
    }

    public func makeQuickReflexDrillViewModel(
        targetWord: WordItem,
        allWords: [WordItem]
    ) -> QuickReflexDrillViewModel {
        QuickReflexDrillViewModel(
            targetWord: targetWord,
            allWords: allWords,
            ttsService: ttsService,
            sttService: sttService,
            speechAssessmentService: speechAssessmentService,
            evaluateSRSUseCase: evaluateSRSUseCase,
            attemptRepository: quickReflexAttemptRepository
        )
    }

    public static let mock = AppContainer(useMockData: true)
    public static let shared = AppContainer.mock
}
