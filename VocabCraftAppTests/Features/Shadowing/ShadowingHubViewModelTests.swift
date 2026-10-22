import Foundation
import Testing
@testable import VocabCraftApp

// MARK: - Mocks

private final class MockShadowingCatalogRepository: ShadowingCatalogRepositoryProtocol, @unchecked Sendable {
    var mockTopics: [ShadowingTopicItem] = []
    var mockVideos: [ShadowingVideo] = []
    var shouldThrow: Bool = false

    func fetchTopics() async throws -> [ShadowingTopicItem] {
        if shouldThrow {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch topics failed"])
        }
        return mockTopics
    }

    func fetchVideos(topicId: String?, level: String?) async throws -> [ShadowingVideo] {
        if shouldThrow {
            throw NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fetch videos failed"])
        }
        var filtered = mockVideos
        if let topicId, !topicId.isEmpty {
            filtered = filtered.filter { $0.topic.rawValue == topicId }
        }
        if let level, !level.isEmpty, level.lowercased() != "all" {
            filtered = filtered.filter { $0.level.localizedCaseInsensitiveCompare(level) == .orderedSame }
        }
        return filtered
    }

    func fetchVideo(byId id: String) async throws -> ShadowingVideo? {
        if shouldThrow {
            throw NSError(domain: "test", code: 3, userInfo: [NSLocalizedDescriptionKey: "Fetch video failed"])
        }
        return mockVideos.first(where: { $0.id == id })
    }
}

private final class MockShadowingProgressRepository: ShadowingProgressRepositoryProtocol, @unchecked Sendable {
    var mockProgress: [String: ShadowingProgressRecord] = [:]

    func getProgress(videoId: String) async -> ShadowingProgressRecord? {
        mockProgress[videoId]
    }

    func recordCompletion(videoId: String, score: Double, sentenceScores: [String: Double]) async throws {
        let record = ShadowingProgressRecord(
            videoId: videoId,
            bestScore: score,
            lastCompletedAt: Date(),
            timesCompleted: (mockProgress[videoId]?.timesCompleted ?? 0) + 1,
            sentenceScores: sentenceScores
        )
        mockProgress[videoId] = record
    }

    func getAllProgress() async -> [String: ShadowingProgressRecord] {
        mockProgress
    }
}

// MARK: - Test Suite

@Suite("ShadowingHubViewModel Tests")
@MainActor
struct ShadowingHubViewModelTests {
    private func makeSampleData() -> ([ShadowingTopicItem], [ShadowingVideo]) {
        let topics = [
            ShadowingTopicItem(id: "dailyLife", titleEn: "Daily Life", titleVi: "Đời sống", iconName: "sun.max", displayOrder: 1),
            ShadowingTopicItem(id: "moviesAndSeries", titleEn: "Movies", titleVi: "Phim ảnh", iconName: "film", displayOrder: 2),
            ShadowingTopicItem(id: "businessEnglish", titleEn: "Business", titleVi: "Kinh doanh", iconName: "briefcase", displayOrder: 3)
        ]

        let videos = [
            ShadowingVideo(
                id: "v_a1_01",
                youtubeVideoId: "yt01",
                title: "Ordering Coffee",
                topic: .dailyLife,
                level: "A1",
                durationSeconds: 120,
                sentences: []
            ),
            ShadowingVideo(
                id: "v_a1_02",
                youtubeVideoId: "yt02",
                title: "Morning Routine",
                topic: .dailyLife,
                level: "A1",
                durationSeconds: 95,
                sentences: []
            ),
            ShadowingVideo(
                id: "v_a2_01",
                youtubeVideoId: "yt03",
                title: "Movie Scene Dialogue",
                topic: .moviesAndSeries,
                level: "A2",
                durationSeconds: 150,
                sentences: []
            ),
            ShadowingVideo(
                id: "v_b1_01",
                youtubeVideoId: "yt04",
                title: "Pitching an Idea",
                topic: .businessEnglish,
                level: "B1",
                durationSeconds: 180,
                sentences: []
            )
        ]

        return (topics, videos)
    }

    @Test("Verifies initial state of ViewModel")
    func testInitialState() {
        let catalogRepo = MockShadowingCatalogRepository()
        let progressRepo = MockShadowingProgressRepository()
        let viewModel = ShadowingHubViewModel(
            catalogRepository: catalogRepo,
            progressRepository: progressRepo,
            streakDays: 7
        )

        #expect(viewModel.topics.isEmpty)
        #expect(viewModel.allVideos.isEmpty)
        #expect(viewModel.progressMap.isEmpty)
        #expect(viewModel.selectedLevelFilter == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.streakDays == 7)
        #expect(viewModel.dailyChallengeVideo == nil)
        #expect(viewModel.filteredVideos.isEmpty)
        #expect(viewModel.videosByTopic.isEmpty)
    }

    @Test("Verifies loading catalog populates topics in order, allVideos, and progressMap")
    func testLoadCatalogSuccess() async {
        let (topics, videos) = makeSampleData()
        let catalogRepo = MockShadowingCatalogRepository()
        catalogRepo.mockTopics = topics.reversed() // purposefully reverse to test sorting by displayOrder
        catalogRepo.mockVideos = videos

        let progressRepo = MockShadowingProgressRepository()
        let progress = ShadowingProgressRecord(videoId: "v_a1_01", bestScore: 92.0, timesCompleted: 1)
        progressRepo.mockProgress = ["v_a1_01": progress]

        let viewModel = ShadowingHubViewModel(
            catalogRepository: catalogRepo,
            progressRepository: progressRepo
        )

        await viewModel.loadCatalog()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.topics.count == 3)
        #expect(viewModel.topics.map(\.id) == ["dailyLife", "moviesAndSeries", "businessEnglish"])
        #expect(viewModel.allVideos.count == 4)
        #expect(viewModel.progressMap["v_a1_01"]?.bestScore == 92.0)
    }

    @Test("Verifies loading catalog gracefully handles errors and resets isLoading")
    func testLoadCatalogError() async {
        let catalogRepo = MockShadowingCatalogRepository()
        catalogRepo.shouldThrow = true
        let progressRepo = MockShadowingProgressRepository()

        let viewModel = ShadowingHubViewModel(
            catalogRepository: catalogRepo,
            progressRepository: progressRepo
        )

        await viewModel.loadCatalog()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.topics.isEmpty)
        #expect(viewModel.allVideos.isEmpty)
    }

    @Test("Verifies filtering videos by CEFR level")
    func testFilteringByLevel() async {
        let (topics, videos) = makeSampleData()
        let catalogRepo = MockShadowingCatalogRepository()
        catalogRepo.mockTopics = topics
        catalogRepo.mockVideos = videos

        let progressRepo = MockShadowingProgressRepository()
        let viewModel = ShadowingHubViewModel(catalogRepository: catalogRepo, progressRepository: progressRepo)
        await viewModel.loadCatalog()

        // Default: no filter
        #expect(viewModel.selectedLevelFilter == nil)
        #expect(viewModel.filteredVideos.count == 4)

        // Filter A1
        viewModel.selectLevelFilter("A1")
        #expect(viewModel.selectedLevelFilter == "A1")
        #expect(viewModel.filteredVideos.count == 2)
        #expect(viewModel.filteredVideos.allSatisfy { $0.level == "A1" })

        // Filter A2
        viewModel.selectLevelFilter("A2")
        #expect(viewModel.selectedLevelFilter == "A2")
        #expect(viewModel.filteredVideos.count == 1)
        #expect(viewModel.filteredVideos.first?.id == "v_a2_01")

        // Filter All reset
        viewModel.selectLevelFilter("All")
        #expect(viewModel.selectedLevelFilter == nil)
        #expect(viewModel.filteredVideos.count == 4)

        // Filter nil reset
        viewModel.selectLevelFilter("B1")
        #expect(viewModel.filteredVideos.count == 1)
        viewModel.selectLevelFilter(nil)
        #expect(viewModel.selectedLevelFilter == nil)
        #expect(viewModel.filteredVideos.count == 4)
    }

    @Test("Verifies daily challenge selects first uncompleted video or falls back to first video")
    func testDailyChallengeSelection() async {
        let (topics, videos) = makeSampleData()
        let catalogRepo = MockShadowingCatalogRepository()
        catalogRepo.mockTopics = topics
        catalogRepo.mockVideos = videos

        let progressRepo = MockShadowingProgressRepository()
        let viewModel = ShadowingHubViewModel(catalogRepository: catalogRepo, progressRepository: progressRepo)
        await viewModel.loadCatalog()

        // 1. None completed: picks first uncompleted ("v_a1_01")
        #expect(viewModel.dailyChallengeVideo?.id == "v_a1_01")

        // 2. First completed: picks second uncompleted ("v_a1_02")
        progressRepo.mockProgress["v_a1_01"] = ShadowingProgressRecord(videoId: "v_a1_01", bestScore: 85.0)
        await viewModel.loadCatalog()
        #expect(viewModel.dailyChallengeVideo?.id == "v_a1_02")

        // 3. First two completed: picks next uncompleted ("v_a2_01")
        progressRepo.mockProgress["v_a1_02"] = ShadowingProgressRecord(videoId: "v_a1_02", bestScore: 90.0)
        await viewModel.loadCatalog()
        #expect(viewModel.dailyChallengeVideo?.id == "v_a2_01")

        // 4. All completed: falls back to the first video ("v_a1_01")
        progressRepo.mockProgress["v_a2_01"] = ShadowingProgressRecord(videoId: "v_a2_01", bestScore: 95.0)
        progressRepo.mockProgress["v_b1_01"] = ShadowingProgressRecord(videoId: "v_b1_01", bestScore: 88.0)
        await viewModel.loadCatalog()
        #expect(viewModel.dailyChallengeVideo?.id == "v_a1_01")

        // 5. Level filter applied (e.g. "B1"): selects B1 video
        viewModel.selectLevelFilter("B1")
        #expect(viewModel.dailyChallengeVideo?.id == "v_b1_01")

        // 6. Level filter with no matching videos: returns nil
        viewModel.selectLevelFilter("C1")
        #expect(viewModel.dailyChallengeVideo == nil)
    }

    @Test("Verifies grouping videos by topic item")
    func testVideoGroupingByTopic() async {
        let (topics, videos) = makeSampleData()
        let catalogRepo = MockShadowingCatalogRepository()
        catalogRepo.mockTopics = topics
        catalogRepo.mockVideos = videos

        let progressRepo = MockShadowingProgressRepository()
        let viewModel = ShadowingHubViewModel(catalogRepository: catalogRepo, progressRepository: progressRepo)
        await viewModel.loadCatalog()

        let dailyTopic = topics.first(where: { $0.id == "dailyLife" })!
        let moviesTopic = topics.first(where: { $0.id == "moviesAndSeries" })!
        let businessTopic = topics.first(where: { $0.id == "businessEnglish" })!

        let grouped = viewModel.videosByTopic
        #expect(grouped[dailyTopic]?.count == 2)
        #expect(grouped[moviesTopic]?.count == 1)
        #expect(grouped[businessTopic]?.count == 1)

        // With level filter "A1", movies and business have 0 videos
        viewModel.selectLevelFilter("A1")
        let filteredGrouped = viewModel.videosByTopic
        #expect(filteredGrouped[dailyTopic]?.count == 2)
        #expect(filteredGrouped[moviesTopic]?.isEmpty == true)
        #expect(filteredGrouped[businessTopic]?.isEmpty == true)
    }
}
