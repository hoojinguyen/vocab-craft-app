import Foundation
import SpeechKit
import SwiftData

public enum ContentAvailability: Equatable, Sendable {
    case ready
    case unavailable(String)
}

/// Centralized Composition Root / Dependency Injection Container.
@MainActor
public final class AppContainer {
    // MARK: - Configuration
    /// Toggle to switch between curated sample dataset and production data source.
    public let useSampleData: Bool
    public let contentAvailability: ContentAvailability

    public let datasetEngine: DatasetEngine?
    public let modelContainer: ModelContainer?

    // MARK: - Data Sources & Repositories
    public let vocabularyDataSource: VocabularyDataSourceProtocol
    public private(set) var contentRepository: (any ContentRepository)?
    public let learningJournal: LearningJournal?
    public let bundleManager: (any ContentBundleManagerProtocol)?
    public let stageProgressRepository: StageProgressRepositoryProtocol
    public let userProgressRepository: any UserProgressRepositoryProtocol

    public let vocabularyRepository: VocabularyRepositoryProtocol
    public let srsRepository: SRSRepositoryProtocol
    public let quickReflexAttemptRepository: QuickReflexAttemptRepositoryProtocol

    // MARK: - Services
    public let audioSessionCoordinator: any AudioSessionCoordinating
    public let ttsService: TextToSpeechProtocol
    public let sttService: SpeechRecognitionProtocol
    public let speechAssessmentService: SpeechAssessmentProtocol

    // MARK: - Domain Use Cases
    public let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    public let resetUserProgressUseCase: ResetUserProgressUseCaseProtocol

    public private(set) var fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol
    public private(set) var completeLessonUseCase: CompleteLessonUseCaseProtocol
    public let recordSenseAttemptUseCase: (any RecordSenseAttemptUseCaseProtocol)?

    public private(set) var fetchPersonalVaultUseCase: FetchPersonalVaultUseCaseProtocol
    public private(set) var reviewWeakWordsUseCase: ReviewWeakWordsUseCaseProtocol
    public let toggleWordBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol
    public let generateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol
    public let practiceDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol
    public let recordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol
    public let initializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol

    // MARK: - Stores & Navigation
    public let userSettingsStore: UserSettingsStore
    public let appRouter: AppRouter

    public init(
        datasetEngine: DatasetEngine? = nil,
        modelContainer: ModelContainer? = nil,
        useMockData: Bool? = nil,
        useSampleData: Bool = true,
        vocabularyDataSource: VocabularyDataSourceProtocol? = nil,
        contentRepository: (any ContentRepository)? = nil,
        learningJournal: LearningJournal? = nil,
        bundleManager: (any ContentBundleManagerProtocol)? = nil,
        stageProgressRepository: StageProgressRepositoryProtocol? = nil,
        userProgressRepository: (any UserProgressRepositoryProtocol)? = nil,
        fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol? = nil,
        completeLessonUseCase: CompleteLessonUseCaseProtocol? = nil,
        recordSenseAttemptUseCase: (any RecordSenseAttemptUseCaseProtocol)? = nil,
        generateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol? = nil,
        practiceDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol? = nil,
        recordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol? = nil,
        initializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol? = nil,
        audioSessionCoordinator: (any AudioSessionCoordinating)? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        speechAssessmentService: SpeechAssessmentProtocol? = nil,
        userSettingsStore: UserSettingsStore? = nil,
        appRouter: AppRouter? = nil,
        bundle: Bundle? = .main
    ) {
        self.useSampleData = useSampleData
        self.datasetEngine = datasetEngine
        self.modelContainer = modelContainer

        self.bundleManager = Self.resolveBundleManager(
            provided: bundleManager,
            useSampleData: useSampleData,
            bundle: bundle
        )

        let contentContext = Self.resolveContentContext(
            contentRepository: contentRepository,
            learningJournal: learningJournal,
            useSampleData: useSampleData,
            bundle: bundle
        )
        self.contentAvailability = contentContext.availability
        self.contentRepository = contentContext.repository
        self.learningJournal = contentContext.journal

        let storage = Self.resolveStorage(
            env: StorageEnvironment(
                modelContainer: modelContainer,
                datasetEngine: datasetEngine,
                useMockData: useMockData,
                useSampleData: useSampleData
            ),
            userProgressRepository: userProgressRepository,
            vocabularyDataSource: vocabularyDataSource,
            stageProgressRepository: stageProgressRepository
        )
        self.userProgressRepository = storage.userProgressRepo
        self.vocabularyDataSource = storage.dataSource
        self.stageProgressRepository = storage.stageRepo
        self.vocabularyRepository = storage.vocabRepo
        self.srsRepository = storage.srsRepo
        self.quickReflexAttemptRepository = storage.quickReflexRepo

        let coordinator = audioSessionCoordinator ?? AudioSessionCoordinator()
        self.audioSessionCoordinator = coordinator
        self.ttsService = ttsService ?? TextToSpeechService(audioSessionCoordinator: coordinator)
        self.sttService = sttService ?? SpeechRecognitionService()
        self.speechAssessmentService = speechAssessmentService ?? SpeechAssessmentService()

        self.evaluateSRSUseCase = EvaluateSRSUseCase(srsRepository: storage.srsRepo)
        self.resetUserProgressUseCase = ResetUserProgressUseCase(srsRepository: storage.srsRepo)

        // Learning Path Use Cases
        self.fetchLearningPathUseCase = Self.resolveLearningPathUseCase(
            provided: fetchLearningPathUseCase,
            contentContext: contentContext,
            dataSource: storage.dataSource,
            stageRepo: storage.stageRepo
        )
        self.completeLessonUseCase = completeLessonUseCase ?? CompleteLessonUseCase(
            stageRepo: storage.stageRepo,
            progressRepo: storage.userProgressRepo,
            journal: contentContext.journal,
            profileID: LearningJournal.defaultGuestProfileID
        )
        self.recordSenseAttemptUseCase = Self.resolveRecordSenseAttemptUseCase(
            provided: recordSenseAttemptUseCase,
            contentContext: contentContext
        )

        // Personal Vault & Mixed Reflex Use Cases
        let vaultUseCases = Self.resolveVaultUseCases(
            contentContext: contentContext,
            dataSource: storage.dataSource,
            progressRepo: storage.userProgressRepo
        )
        self.fetchPersonalVaultUseCase = vaultUseCases.vault
        self.reviewWeakWordsUseCase = vaultUseCases.review
        self.toggleWordBookmarkUseCase = Self.resolveToggleBookmarkUseCase(
            contentContext: contentContext,
            progressRepo: storage.userProgressRepo
        )
        self.generateMixedReflexQueueUseCase = generateMixedReflexQueueUseCase ?? GenerateMixedReflexQueueUseCase()
        self.practiceDrillPlanGenerator = practiceDrillPlanGenerator ?? PracticeDrillPlanGenerator()
        self.recordMixedDrillAttemptUseCase = recordMixedDrillAttemptUseCase ?? RecordMixedDrillAttemptUseCase(
            progressRepo: storage.userProgressRepo,
            dataSource: storage.dataSource
        )

        let effectiveUserSettingsStore = Self.resolveUserSettingsStore(provided: userSettingsStore, modelContainer: modelContainer)
        self.userSettingsStore = effectiveUserSettingsStore
        self.appRouter = appRouter ?? AppRouter()

        self.initializeUserRoadmapUseCase = initializeUserRoadmapUseCase ?? InitializeUserRoadmapUseCase(
            dataSource: storage.dataSource,
            stageRepo: storage.stageRepo,
            userSettings: effectiveUserSettingsStore
        )
    }

    // MARK: - Private Helpers

    private struct ResolvedStorage {
        let userProgressRepo: any UserProgressRepositoryProtocol
        let dataSource: VocabularyDataSourceProtocol
        let stageRepo: StageProgressRepositoryProtocol
        let vocabRepo: VocabularyRepositoryProtocol
        let srsRepo: SRSRepositoryProtocol
        let quickReflexRepo: QuickReflexAttemptRepositoryProtocol
    }

    private struct StorageEnvironment {
        let modelContainer: ModelContainer?
        let datasetEngine: DatasetEngine?
        let useMockData: Bool?
        let useSampleData: Bool
    }

    private static func resolveStorage(
        env: StorageEnvironment,
        userProgressRepository: (any UserProgressRepositoryProtocol)?,
        vocabularyDataSource: VocabularyDataSourceProtocol?,
        stageProgressRepository: StageProgressRepositoryProtocol?
    ) -> ResolvedStorage {
        let progressActor: UserProgressModelActor? = env.modelContainer.map { UserProgressModelActor(modelContainer: $0) }
        let userProgress = userProgressRepository ?? (progressActor ?? MockUserProgressRepository())
        let dataSource = vocabularyDataSource ?? (env.useSampleData ? SampleVocabularyDataSource() : UnavailableVocabularyDataSource())
        let stage = stageProgressRepository ?? (env.modelContainer.map { StageProgressRepositoryImpl(modelContext: $0.mainContext) } ?? MockStageProgressRepository())
        let shouldMock = env.useMockData ?? (env.datasetEngine == nil)
        let vocab: VocabularyRepositoryProtocol = shouldMock
            ? MockVocabularyRepository()
            : VocabularyRepositoryImpl(datasetEngine: env.datasetEngine, progressActor: progressActor)
        let srs = SRSRepositoryImpl(modelContext: env.modelContainer?.mainContext)
        let quick = QuickReflexAttemptRepositoryImpl(modelContext: env.modelContainer?.mainContext)
        return ResolvedStorage(
            userProgressRepo: userProgress,
            dataSource: dataSource,
            stageRepo: stage,
            vocabRepo: vocab,
            srsRepo: srs,
            quickReflexRepo: quick
        )
    }

    private static func resolveUserSettingsStore(
        provided: UserSettingsStore?,
        modelContainer: ModelContainer?
    ) -> UserSettingsStore {
        if let provided { return provided }
        #if canImport(SwiftDataMacros)
        let hasPersistedRecords = modelContainer.map { SharedAppGroupContainer.hasPersistedUserRecords(in: $0) } ?? false
        #else
        let hasPersistedRecords = false
        #endif
        return UserSettingsStore(hasPersistedAppData: hasPersistedRecords)
    }

    private static func resolveBundleManager(
        provided: (any ContentBundleManagerProtocol)?,
        useSampleData: Bool,
        bundle: Bundle? = .main
    ) -> (any ContentBundleManagerProtocol)? {
        if let provided { return provided }
        guard let bundle else { return nil }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let contentRootURL = appSupport.appendingPathComponent("VocabCraft/Content", isDirectory: true)
        let baselineDbURL = bundle.url(forResource: "vocab_content", withExtension: "sqlite")
        let baselineManifestURL = bundle.url(forResource: "manifest", withExtension: "json")
        let baselineManifest: PublishedManifest?
        if let baselineManifestURL, let data = try? Data(contentsOf: baselineManifestURL) {
            baselineManifest = try? JSONDecoder().decode(PublishedManifest.self, from: data)
        } else {
            baselineManifest = nil
        }
        if !useSampleData || baselineDbURL != nil {
            return ContentBundleManager(
                rootURL: contentRootURL,
                baselineURL: baselineDbURL,
                baselineManifest: baselineManifest
            )
        }
        return nil
    }

    private struct ResolvedContentContext {
        let availability: ContentAvailability
        let repository: (any ContentRepository)?
        let journal: LearningJournal?
    }

    private static func resolveContentContext(
        contentRepository: (any ContentRepository)?,
        learningJournal: LearningJournal?,
        useSampleData: Bool,
        bundle: Bundle? = .main
    ) -> ResolvedContentContext {
        if let contentRepository {
            return ResolvedContentContext(
                availability: .ready,
                repository: contentRepository,
                journal: learningJournal
            )
        }
        if useSampleData {
            return ResolvedContentContext(
                availability: .ready,
                repository: nil,
                journal: nil
            )
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let journalURL = appSupport.appendingPathComponent("learning_journal.sqlite")
        let journal = try? LearningJournal(url: journalURL)

        let contentRootURL = appSupport.appendingPathComponent("VocabCraft/Content", isDirectory: true)
        let activeURL = contentRootURL.appendingPathComponent("active.json")
        if let activeData = try? Data(contentsOf: activeURL),
           let pointer = try? JSONDecoder().decode(ActiveContentPointer.self, from: activeData) {
            let dbURL = contentRootURL.appendingPathComponent(pointer.databaseRelativePath)
            if let repo = try? SQLiteContentRepository(url: dbURL) {
                return ResolvedContentContext(availability: .ready, repository: repo, journal: journal)
            }
        }

        if let bundle {
            let bundleDbURL = bundle.url(forResource: "vocab_content", withExtension: "sqlite")
            let bundleManifestURL = bundle.url(forResource: "manifest", withExtension: "json")
            if let dbURL = bundleDbURL, let manifestURL = bundleManifestURL,
               let manifestData = try? Data(contentsOf: manifestURL),
               let manifest = try? JSONDecoder().decode(ContentManifest.self, from: manifestData),
               let repo = try? SQLiteContentRepository(url: dbURL, manifest: manifest) {
                return ResolvedContentContext(availability: .ready, repository: repo, journal: journal)
            }
        }
        return ResolvedContentContext(
            availability: .unavailable("Content database not found in bundle."),
            repository: nil,
            journal: journal
        )
    }

    private static func resolveLearningPathUseCase(
        provided: FetchLearningPathUseCaseProtocol?,
        contentContext: ResolvedContentContext,
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol
    ) -> FetchLearningPathUseCaseProtocol {
        if let provided {
            return provided
        }
        if let repo = contentContext.repository, let journal = contentContext.journal {
            let defaultProfileID = LearningJournal.defaultGuestProfileID
            let adapter = ContentLearningPathAdapter(repository: repo, journal: journal, profileID: defaultProfileID)
            return FetchLearningPathUseCase(adapter: adapter)
        }
        return FetchLearningPathUseCase(dataSource: dataSource, stageRepo: stageRepo)
    }

    private struct ResolvedVaultUseCases {
        let vault: FetchPersonalVaultUseCaseProtocol
        let review: ReviewWeakWordsUseCaseProtocol
    }

    private static func resolveVaultUseCases(
        contentContext: ResolvedContentContext,
        dataSource: VocabularyDataSourceProtocol,
        progressRepo: any UserProgressRepositoryProtocol
    ) -> ResolvedVaultUseCases {
        if let repo = contentContext.repository, let journal = contentContext.journal {
            let defaultProfileID = LearningJournal.defaultGuestProfileID
            return ResolvedVaultUseCases(
                vault: FetchPersonalVaultUseCase(
                    contentRepository: repo,
                    journal: journal,
                    profileID: defaultProfileID
                ),
                review: ReviewWeakWordsUseCase(
                    contentRepository: repo,
                    journal: journal,
                    profileID: defaultProfileID
                )
            )
        }
        return ResolvedVaultUseCases(
            vault: FetchPersonalVaultUseCase(dataSource: dataSource, progressRepo: progressRepo),
            review: ReviewWeakWordsUseCase(dataSource: dataSource, progressRepo: progressRepo)
        )
    }

    private static func resolveToggleBookmarkUseCase(
        contentContext: ResolvedContentContext,
        progressRepo: any UserProgressRepositoryProtocol
    ) -> ToggleWordBookmarkUseCaseProtocol {
        if let journal = contentContext.journal {
            let defaultProfileID = LearningJournal.defaultGuestProfileID
            return ToggleWordBookmarkUseCase(
                progressRepo: progressRepo,
                journal: journal,
                profileID: defaultProfileID
            )
        }
        return ToggleWordBookmarkUseCase(progressRepo: progressRepo)
    }

    private static func resolveRecordSenseAttemptUseCase(
        provided: (any RecordSenseAttemptUseCaseProtocol)?,
        contentContext: ResolvedContentContext
    ) -> (any RecordSenseAttemptUseCaseProtocol)? {
        if let provided {
            return provided
        }
        guard let journal = contentContext.journal else {
            return nil
        }
        return RecordSenseAttemptUseCase(
            journal: journal,
            profileID: LearningJournal.defaultGuestProfileID
        )
    }

    public static var mock: AppContainer {
        let defaults = UserDefaults(suiteName: "mock_app_container_\(UUID().uuidString)") ?? .standard
        defaults.set(14, forKey: "current_streak")
        defaults.set(8, forKey: "today_words_learned")
        defaults.set(10, forKey: "daily_goal_count")
        defaults.set(true, forKey: "has_completed_onboarding")
        let settings = UserSettingsStore(defaults: defaults)
        return AppContainer(useMockData: true, useSampleData: true, userSettingsStore: settings)
    }
    public static let shared = AppContainer(useMockData: false, useSampleData: false)
}

// MARK: - Factory Methods

extension AppContainer {
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
            ttsService: ttsService,
            userSettings: userSettingsStore
        )
    }

    public func makeReflexSpeechEngine() -> ReflexSpeechEngineProtocol {
        ResilientReflexSpeechEngine(audioSessionCoordinator: audioSessionCoordinator)
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

    public func makeLessonLearningViewModel(
        stageId: String,
        deckId: String,
        words: [TopicWordDTO]
    ) -> LessonLearningViewModel {
        LessonLearningViewModel(
            stageId: stageId,
            deckId: deckId,
            words: words,
            completeLessonUseCase: completeLessonUseCase,
            recordSenseAttemptUseCase: recordSenseAttemptUseCase,
            ttsService: ttsService,
            soundEffectService: SoundEffectService.shared,
            speechEngine: makeReflexSpeechEngine()
        )
    }

    public func makeRecordSenseAttemptUseCase() -> (any RecordSenseAttemptUseCaseProtocol)? {
        recordSenseAttemptUseCase
    }

    @discardableResult
    public func openActiveHandle() async throws -> ContentHandle {
        guard let bundleManager else {
            throw ContentBundleError.missingBaseline
        }
        let handle = try await bundleManager.openActive()
        self.contentRepository = handle.reader
        if let journal = self.learningJournal {
            let defaultProfileID = LearningJournal.defaultGuestProfileID
            let adapter = ContentLearningPathAdapter(
                repository: handle.reader,
                journal: journal,
                profileID: defaultProfileID
            )
            self.fetchLearningPathUseCase = FetchLearningPathUseCase(adapter: adapter)
            self.fetchPersonalVaultUseCase = FetchPersonalVaultUseCase(
                contentRepository: handle.reader,
                journal: journal,
                profileID: defaultProfileID
            )
            self.reviewWeakWordsUseCase = ReviewWeakWordsUseCase(
                contentRepository: handle.reader,
                journal: journal,
                profileID: defaultProfileID
            )
            self.completeLessonUseCase = CompleteLessonUseCase(
                stageRepo: stageProgressRepository,
                progressRepo: userProgressRepository,
                journal: journal,
                profileID: defaultProfileID
            )
        }
        return handle
    }

    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            store: userSettingsStore,
            ttsService: ttsService,
            resetProgressUseCase: resetUserProgressUseCase
        )
    }

    public func makeInitializeUserRoadmapUseCase() -> InitializeUserRoadmapUseCaseProtocol {
        initializeUserRoadmapUseCase
    }

    public func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(
            useCase: makeInitializeUserRoadmapUseCase(),
            userSettings: userSettingsStore,
            notificationScheduler: AppNotificationScheduler(),
            progressRepo: userProgressRepository,
            stageRepo: stageProgressRepository
        )
    }
}
