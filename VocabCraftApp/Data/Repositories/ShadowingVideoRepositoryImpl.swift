import Foundation

public final class ShadowingVideoRepositoryImpl: ShadowingVideoRepositoryProtocol, @unchecked Sendable {
    private let curatedVideos: [ShadowingVideo]

    public init(customVideos: [ShadowingVideo]? = nil) {
        if let customVideos {
            self.curatedVideos = customVideos
        } else {
            self.curatedVideos = [
                ShadowingVideo(
                    id: "yt_daily_coffee_01",
                    youtubeVideoId: "NhiOn8f-kdM",
                    title: "Ordering at a Café",
                    topic: .dailyLife,
                    level: "A2",
                    durationSeconds: 32.0,
                    sentences: [
                        ShadowingSentence(
                            id: "s_01",
                            orderIndex: 0,
                            startTime: 0.5,
                            endTime: 3.5,
                            textEn: "Hi! What can I get for you?",
                            textVi: "Xin chào! Tôi có thể lấy gì cho bạn?",
                            keyWords: []
                        ),
                        ShadowingSentence(
                            id: "s_02",
                            orderIndex: 1,
                            startTime: 3.6,
                            endTime: 7.2,
                            textEn: "Can I get a small flat white, please?",
                            textVi: "Cho tôi một ly flat white nhỏ được không?",
                            keyWords: [
                                ShadowingKeyWord(lemma: "flat white", phonetic: "/ˌflæt ˈwaɪt/", definitionVi: "cà phê sữa kiểu Úc"),
                                ShadowingKeyWord(lemma: "small", phonetic: "/smɑːl/", definitionVi: "nhỏ")
                            ]
                        ),
                        ShadowingSentence(
                            id: "s_03",
                            orderIndex: 2,
                            startTime: 7.5,
                            endTime: 12.0,
                            textEn: "Sure. Anything else?",
                            textVi: "Được chứ. Còn gì nữa không?",
                            keyWords: []
                        )
                    ]
                )
            ]
        }
    }

    public func fetchCuratedVideos() async throws -> [ShadowingVideo] {
        curatedVideos
    }

    public func fetchVideo(byId id: String) async throws -> ShadowingVideo? {
        curatedVideos.first(where: { $0.id == id })
    }

    public static var sampleVideo: ShadowingVideo {
        let repo = ShadowingVideoRepositoryImpl()
        if let first = repo.curatedVideos.first {
            return first
        }
        return ShadowingVideo(
            id: "fallback",
            youtubeVideoId: "NhiOn8f-kdM",
            title: "Ordering at a Café",
            topic: .dailyLife,
            level: "A2",
            durationSeconds: 32.0,
            sentences: []
        )
    }
}
