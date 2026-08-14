import Foundation
import SwiftData

/// Centralized Composition Root / Dependency Injection Container.
@MainActor
public final class AppContainer {
    public let datasetEngine: DatasetEngine?
    public let modelContainer: ModelContainer?

    public let vocabularyRepository: VocabularyRepositoryProtocol
    public let srsRepository: SRSRepositoryProtocol

    public let ttsService: TextToSpeechProtocol
    public let sttService: SpeechRecognitionProtocol
    public let speechAssessmentService: SpeechAssessmentProtocol

    public let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol
    public let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol

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

        let shouldMock = useMockData ?? (datasetEngine == nil)
        let vocabRepo: VocabularyRepositoryProtocol = shouldMock
            ? MockVocabularyRepository()
            : VocabularyRepositoryImpl(datasetEngine: datasetEngine)
        let srsRepo = SRSRepositoryImpl(modelContext: modelContainer?.mainContext)

        self.vocabularyRepository = vocabRepo
        self.srsRepository = srsRepo

        self.ttsService = ttsService ?? TextToSpeechService()
        self.sttService = sttService ?? SpeechRecognitionService()
        self.speechAssessmentService = speechAssessmentService ?? SpeechAssessmentService()

        self.fetchVocabularyUseCase = FetchVocabularyUseCase(repository: vocabRepo)
        self.evaluateSRSUseCase = EvaluateSRSUseCase(srsRepository: srsRepo)

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

    public func makeStudySessionViewModel(words: [TopicWord]) -> StudySessionViewModel {
        StudySessionViewModel(
            words: words,
            ttsService: ttsService
        )
    }

    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            store: userSettingsStore,
            ttsService: ttsService
        )
    }

    public func makeVocabularyViewModel() -> VocabularyViewModel {
        VocabularyViewModel(
            fetchVocabularyUseCase: fetchVocabularyUseCase,
            ttsService: ttsService
        )
    }

    public static let mock = AppContainer(useMockData: true)
    public static let shared = AppContainer.mock
}
