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

    public let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol
    public let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol

    public init(
        datasetEngine: DatasetEngine? = nil,
        modelContainer: ModelContainer? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil
    ) {
        self.datasetEngine = datasetEngine
        self.modelContainer = modelContainer
        
        let vocabRepo = VocabularyRepositoryImpl(datasetEngine: datasetEngine)
        let srsRepo = SRSRepositoryImpl(modelContext: modelContainer?.mainContext)
        
        self.vocabularyRepository = vocabRepo
        self.srsRepository = srsRepo
        
        self.ttsService = ttsService ?? TextToSpeechService()
        self.sttService = sttService ?? SpeechRecognitionService()
        
        self.fetchVocabularyUseCase = FetchVocabularyUseCase(repository: vocabRepo)
        self.evaluateSRSUseCase = EvaluateSRSUseCase(srsRepository: srsRepo)
    }

    public func makeHomepageViewModel() -> HomepageViewModel {
        HomepageViewModel()
    }

    public func makeReflexDrillViewModel(cefrLevel: String = "B1") -> ReflexDrillViewModel {
        ReflexDrillViewModel(
            fetchVocabularyUseCase: fetchVocabularyUseCase,
            evaluateSRSUseCase: evaluateSRSUseCase,
            ttsService: ttsService,
            sttService: sttService,
            cefrLevel: cefrLevel
        )
    }

    public func makeStudySessionViewModel(words: [TopicWord]) -> StudySessionViewModel {
        StudySessionViewModel(
            words: words,
            ttsService: ttsService
        )
    }
}
