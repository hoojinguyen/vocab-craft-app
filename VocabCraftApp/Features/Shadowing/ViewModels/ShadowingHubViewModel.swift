import Foundation
import Observation

@Observable
@MainActor
public final class ShadowingHubViewModel {
    public var topics: [ShadowingTopicItem] = []
    public var allVideos: [ShadowingVideo] = []
    public var progressMap: [String: ShadowingProgressRecord] = [:]
    public var selectedLevelFilter: String?
    public var isLoading: Bool = false
    public var streakDays: Int = 4

    private let catalogRepository: any ShadowingCatalogRepositoryProtocol
    private let progressRepository: any ShadowingProgressRepositoryProtocol

    public init(
        catalogRepository: any ShadowingCatalogRepositoryProtocol,
        progressRepository: any ShadowingProgressRepositoryProtocol,
        streakDays: Int = 4
    ) {
        self.catalogRepository = catalogRepository
        self.progressRepository = progressRepository
        self.streakDays = streakDays
    }

    public var filteredVideos: [ShadowingVideo] {
        guard let level = selectedLevelFilter, !level.isEmpty, level.lowercased() != "all" else {
            return allVideos
        }
        return allVideos.filter { $0.level.localizedCaseInsensitiveCompare(level) == .orderedSame }
    }

    public var dailyChallengeVideo: ShadowingVideo? {
        let pool = (selectedLevelFilter != nil) ? filteredVideos : allVideos
        return pool.first(where: { progressMap[$0.id] == nil }) ?? pool.first
    }

    public var videosByTopic: [ShadowingTopicItem: [ShadowingVideo]] {
        var map: [ShadowingTopicItem: [ShadowingVideo]] = [:]
        for topic in topics {
            let matching = filteredVideos.filter { $0.topic.rawValue == topic.id }
            map[topic] = matching
        }
        return map
    }

    public func loadCatalog() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let fetchedTopics = catalogRepository.fetchTopics()
            async let fetchedVideos = catalogRepository.fetchVideos(topicId: nil, level: nil)
            async let fetchedProgress = progressRepository.getAllProgress()

            let (topicsResult, videosResult, progressResult) = try await (fetchedTopics, fetchedVideos, fetchedProgress)
            self.topics = topicsResult.sorted(by: { $0.displayOrder < $1.displayOrder })
            self.allVideos = videosResult
            self.progressMap = progressResult
        } catch {
            // Retain existing state gracefully upon network or database error
        }
    }

    public func selectLevelFilter(_ level: String?) {
        if let level, level.lowercased() == "all" {
            self.selectedLevelFilter = nil
        } else {
            self.selectedLevelFilter = level
        }
    }
}
