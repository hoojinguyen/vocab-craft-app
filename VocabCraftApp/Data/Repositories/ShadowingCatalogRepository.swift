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

public final class FallbackShadowingCatalogRepository: ShadowingCatalogRepositoryProtocol, Sendable {
    public init() {}

    public func fetchTopics() async throws -> [ShadowingTopicItem] {
        [
            ShadowingTopicItem(
                id: "dailyLife",
                titleEn: "Daily Life",
                titleVi: "Đời sống hàng ngày",
                iconName: "cup.and.saucer.fill",
                displayOrder: 1
            )
        ]
    }

    public func fetchVideos(topicId: String?, level: String?) async throws -> [ShadowingVideo] {
        let sample = ShadowingVideoRepositoryImpl.sampleVideo
        if let level, !level.isEmpty, level.lowercased() != "all" {
            if sample.level.localizedCaseInsensitiveCompare(level) != .orderedSame {
                return []
            }
        }
        return [sample]
    }

    public func fetchVideo(byId id: String) async throws -> ShadowingVideo? {
        let sample = ShadowingVideoRepositoryImpl.sampleVideo
        return sample.id == id ? sample : nil
    }
}
