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
        let quickReflexAttemptRepo = QuickReflexAttemptRepositoryImpl(modelContext: modelContainer?.mainContext)

        self.vocabularyRepository = vocabRepo
        self.srsRepository = srsRepo
        self.quickReflexAttemptRepository = quickReflexAttemptRepo

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

    public func makeReflexBlitzViewModel(words: [ReflexBlitzWordItem] = []) -> ReflexBlitzViewModel {
        let blitzWords: [ReflexBlitzWordItem] = !words.isEmpty ? words : [
            ReflexBlitzWordItem(id: 1, lemma: "ephemeral", pos: "adj.", definitionVi: "Phù du, chóng tàn", exampleSentenceEn: "Her fame is ephemeral in nature.", exampleSentenceVi: "Danh tiếng của cô ấy phù du."),
            ReflexBlitzWordItem(id: 2, lemma: "serendipity", pos: "n.", definitionVi: "Sự may mắn bất ngờ", exampleSentenceEn: "Finding this book was pure serendipity.", exampleSentenceVi: "Tìm thấy cuốn sách này là may mắn bất ngờ."),
            ReflexBlitzWordItem(id: 3, lemma: "ubiquitous", pos: "adj.", definitionVi: "Phổ biến khắp nơi", exampleSentenceEn: "Smartphones are ubiquitous today.", exampleSentenceVi: "Điện thoại thông minh phổ biến khắp nơi."),
            ReflexBlitzWordItem(id: 4, lemma: "resilience", pos: "n.", definitionVi: "Sự kiên cường phục hồi", exampleSentenceEn: "She showed great resilience in crisis.", exampleSentenceVi: "Cô ấy thể hiện sự kiên cường trong khủng hoảng."),
            ReflexBlitzWordItem(id: 5, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện lưu loát", exampleSentenceEn: "He gave an eloquent speech.", exampleSentenceVi: "Anh ấy đã có bài phát biểu hùng biện.")
        ]
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
            ttsService: ttsService
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
