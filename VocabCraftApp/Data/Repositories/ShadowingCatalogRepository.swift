import Foundation

public final class ShadowingCatalogRepository: ShadowingCatalogRepositoryProtocol, Sendable {
    private let database: ShadowingSQLiteDatabase

    public init(database: ShadowingSQLiteDatabase) {
        self.database = database
    }

    public convenience init(fileURL: URL) throws {
        self.init(database: try ShadowingSQLiteDatabase(fileURL: fileURL))
    }

    public convenience init(bundle: Bundle = .main) throws {
        self.init(database: try ShadowingSQLiteDatabase(bundle: bundle))
    }

    public func fetchTopics() async throws -> [ShadowingTopicItem] {
        try database.fetchTopics()
    }

    public func fetchVideos(topicId: String?, level: String?) async throws -> [ShadowingVideo] {
        try database.fetchVideos(topicId: topicId, level: level)
    }

    public func fetchVideo(byId id: String) async throws -> ShadowingVideo? {
        try database.fetchVideo(byId: id)
    }
}
