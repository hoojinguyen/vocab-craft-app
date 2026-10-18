import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Onboarding Roadmap Tests")
struct OnboardingRoadmapTests {
    private var dbURL: URL {
        get throws {
            for bundle in Bundle.allBundles {
                if let url = bundle.url(forResource: "vocab_content", withExtension: "sqlite") {
                    return url
                }
                if let subURL = bundle.url(
                    forResource: "vocab_content",
                    withExtension: "sqlite",
                    subdirectory: "VocabCraftApp_VocabCraftApp.bundle/Contents/Resources"
                ) {
                    return subURL
                }
                if let subURL = bundle.url(
                    forResource: "vocab_content",
                    withExtension: "sqlite",
                    subdirectory: "VocabCraftApp_VocabCraftApp.bundle"
                ) {
                    return subURL
                }
            }
            let currentFilePath = URL(fileURLWithPath: #filePath)
            let sourceURL = currentFilePath
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Content/vocab_content.sqlite")
            if FileManager.default.fileExists(atPath: sourceURL.path) {
                return sourceURL
            }
            struct MissingDatabaseError: Error {}
            throw MissingDatabaseError()
        }
    }

    @MainActor
    private func makeSettings() -> UserSettingsStore {
        let suite = "test_onboarding_roadmap_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return UserSettingsStore(defaults: defaults)
    }

    @Test("Initialize roadmap with real SQLite learning path ID")
    @MainActor
    func testInitializeRoadmapWithRealLearningPathId() async throws {
        let realDataSource = try SQLiteContentRepository(url: dbURL)
        let stageRepo = InMemoryStageProgressRepository()
        let userSettings = makeSettings()

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: realDataSource,
            stageRepo: stageRepo,
            userSettings: userSettings
        )

        let result = try await useCase.execute(
            pathId: "daily-life-travel",
            cefrLevel: "A1",
            dailyGoalCount: 10,
            notificationTimeInterval: 72000
        )

        #expect(!result.startingStage.id.isEmpty)
        #expect(userSettings.selectedLearningPathId == "daily-life-travel")
        #expect(userSettings.selectedGoalDeckId == "29cb49b8-f9b3-45b3-bfb6-3a3f56d41e81")
        #expect(result.starterWords.count >= 3)
    }

    @Test("Initialize roadmap with UUID path ID for core curriculum")
    @MainActor
    func testInitializeRoadmapWithUUIDPathId() async throws {
        let realDataSource = try SQLiteContentRepository(url: dbURL)
        let stageRepo = InMemoryStageProgressRepository()
        let userSettings = makeSettings()

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: realDataSource,
            stageRepo: stageRepo,
            userSettings: userSettings
        )

        let result = try await useCase.execute(
            pathId: "7147ba7e-0728-471d-97af-f3e2262a6d23",
            cefrLevel: "B1",
            dailyGoalCount: 15,
            notificationTimeInterval: 36000
        )

        #expect(!result.startingStage.id.isEmpty)
        #expect(userSettings.selectedLearningPathId == "7147ba7e-0728-471d-97af-f3e2262a6d23")
        #expect(!userSettings.selectedGoalDeckId.isEmpty)
    }

    @Test("OnboardingViewModel loads real learning paths from data source")
    @MainActor
    func testOnboardingViewModelLoadsRealLearningPaths() async throws {
        let realDataSource = try SQLiteContentRepository(url: dbURL)
        let stageRepo = InMemoryStageProgressRepository()
        let userSettings = makeSettings()

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: realDataSource,
            stageRepo: stageRepo,
            userSettings: userSettings
        )

        let vm = OnboardingViewModel(
            useCase: useCase,
            userSettings: userSettings,
            stageRepo: stageRepo,
            dataSource: realDataSource
        )

        await vm.loadLearningPaths()

        #expect(vm.learningPaths.count == 4)
        let codes = Set(vm.learningPaths.map(\.code))
        #expect(codes.contains("essential-english-mastery"))
        #expect(codes.contains("daily-life-travel"))
        #expect(codes.contains("business-career"))
        #expect(codes.contains("academic-research"))
    }
}

@MainActor
private final class InMemoryStageProgressRepository: StageProgressRepositoryProtocol, @unchecked Sendable {
    private var storage: [String: UserStageProgressData] = [:]

    func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        storage[stageId]
    }

    func saveStageProgress(
        stageId: String,
        deckId: String,
        isCompleted: Bool,
        score: Int,
        progressFraction: Double
    ) async throws {
        storage[stageId] = UserStageProgressData(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: score,
            progressFraction: progressFraction
        )
    }

    func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        Array(storage.values)
    }

    func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        Set(storage.values.filter { $0.deckId == deckId && $0.isCompleted }.map(\.stageId))
    }

    func resetProgress() async throws {
        storage.removeAll()
    }
}
