import Foundation

public protocol ShadowingVideoRepositoryProtocol: Sendable {
    func fetchCuratedVideos() async throws -> [ShadowingVideo]
    func fetchVideo(byId id: String) async throws -> ShadowingVideo?
}
