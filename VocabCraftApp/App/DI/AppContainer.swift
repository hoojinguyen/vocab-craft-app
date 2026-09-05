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

    public let fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol
    public let completeLessonUseCase: CompleteLessonUseCaseProtocol
    public let recordSenseAttemptUseCase: (any RecordSenseAttemptUseCaseProtocol)?

    public let fetchPersonalVaultUseCase: FetchPersonalVaultUseCaseProtocol
    public let reviewWeakWordsUseCase: ReviewWeakWordsUseCaseProtocol
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
        appRouter: AppRouter? = nil
    ) {
        self.useSampleData = useSampleData
        self.datasetEngine = datasetEngine
        self.modelContainer = modelContainer

        self.bundleManager = Self.resolveBundleManager(provided: bundleManager, useSampleData: useSampleData)

        let contentContext = Self.resolveContentContext(
            contentRepository: contentRepository,
            learningJournal: learningJournal,
            useSampleData: useSampleData
        )
        self.contentAvailability = contentContext.availability
        self.contentRepository = contentContext.repository
        self.learningJournal = contentContext.journal

        let progressActor: UserProgressModelActor? = modelContainer.map { UserProgressModelActor(modelContainer: $0) }
        let resolvedUserProgressRepo: any UserProgressRepositoryProtocol = userProgressRepository
            ?? (progressActor ?? MockUserProgressRepository())
        self.userProgressRepository = resolvedUserProgressRepo

        let resolvedDataSource: VocabularyDataSourceProtocol = vocabularyDataSource
            ?? (useSampleData ? SampleVocabularyDataSource() : UnavailableVocabularyDataSource())
        self.vocabularyDataSource = resolvedDataSource

        let resolvedStageRepo: StageProgressRepositoryProtocol = stageProgressRepository
            ?? (modelContainer.map { StageProgressRepositoryImpl(modelContext: $0.mainContext) } ?? MockStageProgressRepository())
        self.stageProgressRepository = resolvedStageRepo

        let shouldMock = useMockData ?? (datasetEngine == nil)
        let vocabRepo: VocabularyRepositoryProtocol = shouldMock
            ? MockVocabularyRepository()
            : VocabularyRepositoryImpl(datasetEngine: datasetEngine, progressActor: progressActor)
        let srsRepo = SRSRepositoryImpl(modelContext: modelContainer?.mainContext)
        self.vocabularyRepository = vocabRepo
        self.srsRepository = srsRepo
        self.quickReflexAttemptRepository = QuickReflexAttemptRepositoryImpl(modelContext: modelContainer?.mainContext)

        let coordinator = audioSessionCoordinator ?? AudioSessionCoordinator()
        self.audioSessionCoordinator = coordinator
        self.ttsService = ttsService ?? TextToSpeechService(audioSessionCoordinator: coordinator)
        self.sttService = sttService ?? SpeechRecognitionService()
        self.speechAssessmentService = speechAssessmentService ?? SpeechAssessmentService()

        self.evaluateSRSUseCase = EvaluateSRSUseCase(srsRepository: srsRepo)
        self.resetUserProgressUseCase = ResetUserProgressUseCase(srsRepository: srsRepo)

        // Learning Path Use Cases
        self.fetchLearningPathUseCase = Self.resolveLearningPathUseCase(
            provided: fetchLearningPathUseCase,
            contentContext: contentContext,
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo
        )
        self.completeLessonUseCase = completeLessonUseCase ?? CompleteLessonUseCase(
            stageRepo: resolvedStageRepo,
            progressRepo: resolvedUserProgressRepo,
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
            dataSource: resolvedDataSource,
            progressRepo: resolvedUserProgressRepo
        )
        self.fetchPersonalVaultUseCase = vaultUseCases.vault
        self.reviewWeakWordsUseCase = vaultUseCases.review
        self.toggleWordBookmarkUseCase = Self.resolveToggleBookmarkUseCase(
            contentContext: contentContext,
            progressRepo: resolvedUserProgressRepo
        )
        self.generateMixedReflexQueueUseCase = generateMixedReflexQueueUseCase ?? GenerateMixedReflexQueueUseCase()
        self.practiceDrillPlanGenerator = practiceDrillPlanGenerator ?? PracticeDrillPlanGenerator()
        self.recordMixedDrillAttemptUseCase = recordMixedDrillAttemptUseCase ?? RecordMixedDrillAttemptUseCase(
            progressRepo: resolvedUserProgressRepo,
            dataSource: resolvedDataSource
        )

        #if canImport(SwiftDataMacros)
        let hasPersistedRecords = modelContainer.map { SharedAppGroupContainer.hasPersistedUserRecords(in: $0) } ?? false
        #else
        let hasPersistedRecords = false
        #endif
        let effectiveUserSettingsStore = userSettingsStore ?? UserSettingsStore(hasPersistedAppData: hasPersistedRecords)
        self.userSettingsStore = effectiveUserSettingsStore
        self.appRouter = appRouter ?? AppRouter()

        self.initializeUserRoadmapUseCase = initializeUserRoadmapUseCase ?? InitializeUserRoadmapUseCase(
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo,
            userSettings: effectiveUserSettingsStore
        )
    }

    // MARK: - Private Helpers

    private static func resolveBundleManager(
        provided: (any ContentBundleManagerProtocol)?,
        useSampleData: Bool
    ) -> (any ContentBundleManagerProtocol)? {
        if let provided { return provided }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let contentRootURL = appSupport.appendingPathComponent("VocabCraft/Content", isDirectory: true)
        let baselineDbURL = Bundle.main.url(forResource: "vocab_content", withExtension: "sqlite")
        let baselineManifestURL = Bundle.main.url(forResource: "manifest", withExtension: "json")
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
        useSampleData: Bool
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

        let bundleDbURL = Bundle.main.url(forResource: "vocab_content", withExtension: "sqlite")
        let bundleManifestURL = Bundle.main.url(forResource: "manifest", withExtension: "json")
        if let dbURL = bundleDbURL, let manifestURL = bundleManifestURL,
           let manifestData = try? Data(contentsOf: manifestURL),
           let manifest = try? JSONDecoder().decode(ContentManifest.self, from: manifestData),
           let repo = try? SQLiteContentRepository(url: dbURL, manifest: manifest) {
            return ResolvedContentContext(availability: .ready, repository: repo, journal: journal)
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
