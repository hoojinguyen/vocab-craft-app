import Foundation
import SwiftData

/// Centralized Composition Root / Dependency Injection Container.
@MainActor
public final class AppContainer {
    // MARK: - Configuration
    /// Toggle to switch between curated sample dataset and production data source.
    public let useSampleData: Bool

    public let modelContainer: ModelContainer?

    // MARK: - Data Sources & Repositories
    public let vocabularyDataSource: VocabularyDataSourceProtocol
    public let stageProgressRepository: StageProgressRepositoryProtocol
    public let userProgressRepository: any UserProgressRepositoryProtocol

    public let vocabularyRepository: VocabularyRepositoryProtocol
    public let srsRepository: SRSRepositoryProtocol
    public let quickReflexAttemptRepository: QuickReflexAttemptRepositoryProtocol
    public let shadowingProgressRepository: any ShadowingProgressRepositoryProtocol
    public let speakingRepository: any SpeakingRepositoryProtocol
    public let analyzeSpeakingSessionUseCase: AnalyzeSpeakingSessionUseCase

    // MARK: - Services
    public let audioSessionCoordinator: any AudioSessionCoordinating
    public let ttsService: TextToSpeechProtocol

    // MARK: - Domain Use Cases
    public let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    public let resetUserProgressUseCase: ResetUserProgressUseCaseProtocol

    public let fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol
    public let completeLessonUseCase: CompleteLessonUseCaseProtocol
    public let refreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol
    public let claimTreasureRewardUseCase: ClaimTreasureRewardUseCaseProtocol
    public let fastTrackUnitUseCase: FastTrackUnitUseCaseProtocol

    public let fetchPersonalVaultUseCase: FetchPersonalVaultUseCaseProtocol
    public let reviewWeakWordsUseCase: ReviewWeakWordsUseCaseProtocol
    public let toggleWordBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol
    public let generateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol
    public let practiceDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol
    public let recordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol
    public let initializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol
    public let fetchVocabGrowthMetricsUseCase: FetchVocabGrowthMetricsUseCaseProtocol

    // MARK: - Stores & Navigation
    public let userSettingsStore: UserSettingsStore
    public let appRouter: AppRouter

    // swiftlint:disable:next function_body_length
    public init(
        modelContainer: ModelContainer? = nil,
        useMockData: Bool? = nil,
        useSampleData: Bool = true,
        vocabularyDataSource: VocabularyDataSourceProtocol? = nil,
        stageProgressRepository: StageProgressRepositoryProtocol? = nil,
        userProgressRepository: (any UserProgressRepositoryProtocol)? = nil,
        fetchLearningPathUseCase: FetchLearningPathUseCaseProtocol? = nil,
        completeLessonUseCase: CompleteLessonUseCaseProtocol? = nil,
        refreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol? = nil,
        claimTreasureRewardUseCase: ClaimTreasureRewardUseCaseProtocol? = nil,
        fastTrackUnitUseCase: FastTrackUnitUseCaseProtocol? = nil,
        generateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol? = nil,
        practiceDrillPlanGenerator: PracticeDrillPlanGeneratorProtocol? = nil,
        recordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol? = nil,
        initializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol? = nil,
        fetchVocabGrowthMetricsUseCase: FetchVocabGrowthMetricsUseCaseProtocol? = nil,
        audioSessionCoordinator: (any AudioSessionCoordinating)? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        userSettingsStore: UserSettingsStore? = nil,
        appRouter: AppRouter? = nil,
        shadowingProgressRepository: (any ShadowingProgressRepositoryProtocol)? = nil
    ) {
        self.useSampleData = useSampleData
        self.modelContainer = modelContainer

        let progressActor: UserProgressModelActor? = modelContainer.map { UserProgressModelActor(modelContainer: $0) }
        let resolvedUserProgressRepo: any UserProgressRepositoryProtocol = userProgressRepository
            ?? (progressActor ?? MockUserProgressRepository())
        self.userProgressRepository = resolvedUserProgressRepo

        let resolvedDataSource: VocabularyDataSourceProtocol = vocabularyDataSource
            ?? Self.getProductionDataSource()
        self.vocabularyDataSource = resolvedDataSource

        let resolvedStageRepo: StageProgressRepositoryProtocol = stageProgressRepository
            ?? (modelContainer.map { StageProgressRepositoryImpl(modelContext: $0.mainContext) } ?? MockStageProgressRepository())
        self.stageProgressRepository = resolvedStageRepo

        let shouldMock = useMockData ?? false
        let vocabRepo: VocabularyRepositoryProtocol = shouldMock
            ? MockVocabularyRepository()
            : VocabularyRepositoryImpl(dataSource: resolvedDataSource, progressActor: progressActor)
        let srsRepo = SRSRepositoryImpl(modelContext: modelContainer?.mainContext)
        let quickReflexAttemptRepo = QuickReflexAttemptRepositoryImpl(modelContext: modelContainer?.mainContext)

        self.vocabularyRepository = vocabRepo
        self.srsRepository = srsRepo
        self.quickReflexAttemptRepository = quickReflexAttemptRepo
        self.shadowingProgressRepository = shadowingProgressRepository ?? ShadowingProgressRepositoryImpl()

        let speakingRepository: any SpeakingRepositoryProtocol
        if shouldMock || modelContainer == nil {
            speakingRepository = InMemorySpeakingRepository()
        } else if let modelContainer {
            speakingRepository = SpeakingModelActor(modelContainer: modelContainer)
        } else {
            speakingRepository = InMemorySpeakingRepository()
        }
        self.speakingRepository = speakingRepository

        #if canImport(SwiftDataMacros) || canImport(SwiftData)
        let hasPersistedRecords = modelContainer.map { SharedAppGroupContainer.hasPersistedUserRecords(in: $0) } ?? false
        #else
        let hasPersistedRecords = false
        #endif
        let effectiveUserSettingsStore = userSettingsStore ?? UserSettingsStore(hasPersistedAppData: hasPersistedRecords)
        self.userSettingsStore = effectiveUserSettingsStore
        self.appRouter = appRouter ?? AppRouter()

        let speakingStorage = Self.makeSpeakingAudioStorage()
        let speakingAnalyzer = GeminiSpeakingAnalyzer(apiKey: { [effectiveUserSettingsStore] in
            await MainActor.run { effectiveUserSettingsStore.geminiApiKey }
        })
        self.analyzeSpeakingSessionUseCase = AnalyzeSpeakingSessionUseCase(
            repository: speakingRepository,
            analyzer: speakingAnalyzer,
            storage: speakingStorage
        )

        let resolvedAudioCoordinator: any AudioSessionCoordinating = audioSessionCoordinator
            ?? AudioSessionCoordinator()
        self.audioSessionCoordinator = resolvedAudioCoordinator

        let resolvedTTS = ttsService ?? TextToSpeechService(
            audioSessionCoordinator: resolvedAudioCoordinator,
            settingsStore: effectiveUserSettingsStore
        )
        self.ttsService = resolvedTTS

        // Existing Use Cases
        self.evaluateSRSUseCase = EvaluateSRSUseCase(srsRepository: srsRepo)
        self.resetUserProgressUseCase = ResetUserProgressUseCase(srsRepository: srsRepo)

        // Learning Path Use Cases
        let resolvedFetchLearningPath: FetchLearningPathUseCaseProtocol = fetchLearningPathUseCase ?? FetchLearningPathUseCase(
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo,
            userSettings: effectiveUserSettingsStore
        )
        self.fetchLearningPathUseCase = resolvedFetchLearningPath
        // Constructing is side-effect free; the App Group is only touched when execute() runs.
        let resolvedRefreshWidgetDeck: RefreshWidgetDeckUseCaseProtocol = refreshWidgetDeckUseCase ?? RefreshWidgetDeckUseCase(
            fetchLearningPath: resolvedFetchLearningPath,
            progressRepository: resolvedUserProgressRepo,
            dataSource: resolvedDataSource,
            store: .appGroup(),
            reloader: WidgetCenterReloader()
        )
        self.refreshWidgetDeckUseCase = resolvedRefreshWidgetDeck
        // Only the production default is decorated; injected use cases stay untouched so tests have no widget side effects.
        self.completeLessonUseCase = completeLessonUseCase ?? WidgetRefreshingCompleteLessonUseCase(
            wrapped: CompleteLessonUseCase(
                stageRepo: resolvedStageRepo,
                progressRepo: resolvedUserProgressRepo
            ),
            refresh: resolvedRefreshWidgetDeck
        )
        self.claimTreasureRewardUseCase = claimTreasureRewardUseCase ?? ClaimTreasureRewardUseCase(
            stageRepo: resolvedStageRepo
        )
        self.fastTrackUnitUseCase = fastTrackUnitUseCase ?? FastTrackUnitUseCase(
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo,
            progressRepo: resolvedUserProgressRepo
        )

        // Personal Vault & Mixed Reflex Use Cases
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

        self.initializeUserRoadmapUseCase = initializeUserRoadmapUseCase ?? InitializeUserRoadmapUseCase(
            dataSource: resolvedDataSource,
            stageRepo: resolvedStageRepo,
            userSettings: effectiveUserSettingsStore
        )

        self.fetchVocabGrowthMetricsUseCase = fetchVocabGrowthMetricsUseCase ?? FetchVocabGrowthMetricsUseCase(
            progressRepo: resolvedUserProgressRepo,
            dataSource: resolvedDataSource
        )
    }

    // MARK: - Use Case Factories

    public func makeFetchLearningPathUseCase() -> FetchLearningPathUseCaseProtocol {
        fetchLearningPathUseCase
    }

    public func makeCompleteLessonUseCase() -> CompleteLessonUseCaseProtocol {
        completeLessonUseCase
    }

    public func makeClaimTreasureRewardUseCase() -> ClaimTreasureRewardUseCaseProtocol {
        claimTreasureRewardUseCase
    }

    public func makeFastTrackUnitUseCase() -> FastTrackUnitUseCaseProtocol {
        fastTrackUnitUseCase
    }

    public func makeGenerateMixedReflexQueueUseCase() -> GenerateMixedReflexQueueUseCaseProtocol {
        generateMixedReflexQueueUseCase
    }

    public func makeRecordMixedDrillAttemptUseCase() -> RecordMixedDrillAttemptUseCaseProtocol {
        recordMixedDrillAttemptUseCase
    }

    public func makeFetchVocabGrowthMetricsUseCase() -> FetchVocabGrowthMetricsUseCaseProtocol {
        fetchVocabGrowthMetricsUseCase
    }

    // MARK: - View Model Factories

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
            fetchVocabGrowthMetricsUseCase: fetchVocabGrowthMetricsUseCase,
            ttsService: ttsService,
            userSettings: userSettingsStore,
            claimTreasureRewardUseCase: claimTreasureRewardUseCase,
            fastTrackUnitUseCase: fastTrackUnitUseCase
        )
    }

    public func makeSpeakingHubViewModel() -> SpeakingHubViewModel {
        let wordPicker = SpeakingWordPicker(progressRepository: userProgressRepository, vocabulary: vocabularyDataSource)
        return SpeakingHubViewModel(
            repository: speakingRepository,
            wordPicker: wordPicker,
            precheck: SpeakingPrecheck(settings: userSettingsStore)
        )
    }

    public func makeSpeakingCallController(plan: SpeakingSessionPlan) -> SpeakingCallController? {
        let apiKey = userSettingsStore.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else { return nil }
        let storage = Self.makeSpeakingAudioStorage()
        return SpeakingCallController(
            plan: plan,
            apiKey: apiKey,
            transport: URLSessionLiveTransport(),
            audio: VoiceProcessingAudioIO(),
            recorder: LearnerRecorder(storage: storage),
            audioSession: audioSessionCoordinator
        )
    }

    public func makeReflexSpeechEngine() -> ReflexSpeechEngineProtocol {
        ResilientReflexSpeechEngine(audioSessionCoordinator: audioSessionCoordinator)
    }

    public func makeSpeechRecognitionService(locale: String = "en-US") -> SpeechRecognitionProtocol {
        SpeechRecognitionService(locale: locale, audioSessionCoordinator: audioSessionCoordinator)
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
            speechEngine: makeReflexSpeechEngine(),
            allowSpeakingSkip: allowSpeakingSkip
        )
    }

    public func makeLessonLearningViewModel(
        stageId: String,
        deckId: String,
        words: [TopicWordDTO],
        isFastTrack: Bool = false
    ) -> LessonLearningViewModel {
        LessonLearningViewModel(
            stageId: stageId,
            deckId: deckId,
            words: words,
            isFastTrack: isFastTrack,
            completeLessonUseCase: completeLessonUseCase,
            ttsService: ttsService,
            soundEffectService: SoundEffectService.shared,
            speechEngine: makeReflexSpeechEngine()
        )
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
            stageRepo: stageProgressRepository,
            dataSource: vocabularyDataSource
        )
    }
}

// MARK: - Shadowing Factories

extension AppContainer {
    @MainActor
    public func makeShadowingPracticeViewModel(for video: ShadowingVideo) -> ShadowingPracticeViewModel {
        let coordinator = ShadowingSessionCoordinator(audioCoordinator: audioSessionCoordinator)
        return ShadowingPracticeViewModel(
            video: video,
            sessionCoordinator: coordinator,
            toggleBookmarkUseCase: toggleWordBookmarkUseCase
        )
    }

    @MainActor
    public func makeShadowingStudioViewModel(for video: ShadowingVideo) -> ShadowingStudioViewModel {
        let coordinator = ShadowingSessionCoordinator(audioCoordinator: audioSessionCoordinator)
        return ShadowingStudioViewModel(
            video: video,
            sessionCoordinator: coordinator,
            toggleBookmarkUseCase: toggleWordBookmarkUseCase,
            progressRepository: shadowingProgressRepository
        )
    }

    @MainActor
    public func makeShadowingHubViewModel(
        catalogRepository: (any ShadowingCatalogRepositoryProtocol)? = nil
    ) -> ShadowingHubViewModel {
        let catalogRepo: any ShadowingCatalogRepositoryProtocol
        if let custom = catalogRepository {
            catalogRepo = custom
        } else if let repo = try? ShadowingCatalogRepository(bundle: .main) {
            catalogRepo = repo
        } else {
            catalogRepo = FallbackShadowingCatalogRepository()
        }
        return ShadowingHubViewModel(
            catalogRepository: catalogRepo,
            progressRepository: shadowingProgressRepository,
            streakDays: max(userSettingsStore.currentStreak, 1)
        )
    }

    /// Whether the installed content database must be replaced by the bundled one.
    /// Comparing against the bundle's own path count (not a fixed number) lets a copy with fewer
    /// paths settle after one replacement instead of being recopied on every launch.
    static func shouldCopyBundledContent( // swiftlint:disable:this function_parameter_count
        destExists: Bool,
        bundleVersion: Int,
        destVersion: Int,
        savedVersion: Int,
        bundlePathCount: Int,
        destPathCount: Int
    ) -> Bool {
        !destExists
            || bundleVersion > destVersion
            || bundleVersion > savedVersion
            || destPathCount < bundlePathCount
    }

    public static func getProductionDataSource() -> VocabularyDataSourceProtocol {
        do {
            let fileManager = FileManager.default
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            // We use a stable directory now, instead of v5/v6.
            let dir = appSupport.appendingPathComponent("VocabCraft/Content", isDirectory: true)
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            let dest = dir.appendingPathComponent("vocab_content.sqlite")

            let src = Bundle.main.url(forResource: "vocab_content", withExtension: "sqlite")
                ?? Bundle.main.url(forResource: "vocab_content", withExtension: "sqlite", subdirectory: "Content")

            if let src {
                let bundleVersion = SQLiteContentRepository.readContentVersion(at: src) ?? 0
                let destVersion = SQLiteContentRepository.readContentVersion(at: dest) ?? 0
                let bundlePathCount = SQLiteContentRepository.readLearningPathCount(at: src)
                let destPathCount = SQLiteContentRepository.readLearningPathCount(at: dest)
                let savedVersion = UserDefaults.standard.integer(forKey: "current_content_version")

                let shouldCopy = shouldCopyBundledContent(
                    destExists: fileManager.fileExists(atPath: dest.path),
                    bundleVersion: bundleVersion,
                    destVersion: destVersion,
                    savedVersion: savedVersion,
                    bundlePathCount: bundlePathCount,
                    destPathCount: destPathCount
                )

                if shouldCopy {
                    if fileManager.fileExists(atPath: dest.path) {
                        try fileManager.removeItem(at: dest)
                    }
                    try fileManager.copyItem(at: src, to: dest)
                    let newVersion = max(bundleVersion, destVersion, 8)
                    UserDefaults.standard.set(newVersion, forKey: "current_content_version")
                }
            }

            return try SQLiteContentRepository(url: dest)
        } catch {
            print("Failed to initialize SQLite content: \(error)")
            return BundledVocabularyDataSource() // Safe fallback
        }
    }

    public static var mock: AppContainer {
        let defaults = UserDefaults(suiteName: "mock_app_container_\(UUID().uuidString)") ?? .standard
        defaults.set(14, forKey: "current_streak")
        defaults.set(8, forKey: "today_words_learned")
        defaults.set(10, forKey: "daily_goal_count")
        defaults.set(true, forKey: "has_completed_onboarding")
        let settings = UserSettingsStore(defaults: defaults)
        return AppContainer(
            useMockData: true,
            useSampleData: true,
            refreshWidgetDeckUseCase: NoOpRefreshWidgetDeckUseCase(),
            userSettingsStore: settings
        )
    }
    public static let shared = AppContainer(useMockData: false, useSampleData: false)

    private static func makeSpeakingAudioStorage() -> SpeakingAudioStorage {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = baseDirectory
            .appendingPathComponent("VocabCraft", isDirectory: true)
            .appendingPathComponent("SpeakingAudio", isDirectory: true)
        return SpeakingAudioStorage(directory: directory)
    }
}

private actor InMemorySpeakingRepository: SpeakingRepositoryProtocol {
    private var sessionsByID: [UUID: SpeakingSessionSnapshot] = [:]
    private var savedPhrases: [UUID: SavedPhrase] = [:]

    func save(_ session: SpeakingSessionSnapshot) { sessionsByID[session.id] = session }
    func session(id: UUID) -> SpeakingSessionSnapshot? { sessionsByID[id] }
    func sessions(limit: Int?) -> [SpeakingSessionSnapshot] {
        let values = sessionsByID.values.sorted { $0.startedAt > $1.startedAt }
        return limit.map { Array(values.prefix(max(0, $0))) } ?? values
    }
    func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) {
        guard var session = sessionsByID[sessionId] else { return }
        session.status = status
        session.analysis = analysis
        sessionsByID[sessionId] = session
    }
    func savePhrase(_ phrase: SavedPhrase) -> Bool {
        let key = QuoteNormalizer.normalize(phrase.suggestion)
        guard !savedPhrases.values.contains(where: { QuoteNormalizer.normalize($0.suggestion) == key }) else { return false }
        savedPhrases[phrase.id] = phrase
        return true
    }
    func phrases() -> [SavedPhrase] { savedPhrases.values.sorted { $0.createdAt > $1.createdAt } }
    func deletePhrase(id: UUID) { savedPhrases[id] = nil }
    func detachAudio(keepingLatest count: Int) -> [String] {
        let ordered = sessionsByID.values.sorted { $0.startedAt > $1.startedAt }
        var removed: [String] = []
        for var session in ordered.dropFirst(max(0, count)) {
            if let fileName = session.audioFileName {
                removed.append(fileName)
                session.audioFileName = nil
                sessionsByID[session.id] = session
            }
        }
        return removed
    }
}

/// Keeps previews and tests from reading or writing the real App Group widget deck.
private struct NoOpRefreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol {
    func execute() async {}
}
