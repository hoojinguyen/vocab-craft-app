import Foundation

public protocol ShadowingCatalogRepositoryProtocol: Sendable {
    func fetchTopics() async throws -> [ShadowingTopicItem]
    func fetchVideos(topicId: String?, level: String?) async throws -> [ShadowingVideo]
    func fetchVideo(byId id: String) async throws -> ShadowingVideo?
}
