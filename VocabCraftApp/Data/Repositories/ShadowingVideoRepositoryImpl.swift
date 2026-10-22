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
                    youtubeVideoId: "kJQP7kiw5Fk",
                    title: "Ordering at a Café",
                    topic: .dailyLife,
                    level: "A2",
                    durationSeconds: 32.0,
                    sentences: [
                        ShadowingSentence(
                            id: "s_01",
                            orderIndex: 0,
                            startTime: 1.0,
                            endTime: 4.5,
                            textEn: "Hi there! What can I get started for you today?",
                            textVi: "Xin chào! Tôi có thể lấy gì cho bạn hôm nay?",
                            keyWords: [
                                ShadowingKeyWord(lemma: "started", phonetic: "/ˈstɑːr.t̬ɪd/", definitionVi: "bắt đầu")
                            ]
                        ),
                        ShadowingSentence(
                            id: "s_02",
                            orderIndex: 1,
                            startTime: 5.0,
                            endTime: 9.2,
                            textEn: "Could I get a medium iced latte with oat milk, please?",
                            textVi: "Cho tôi một ly latte đá cỡ vừa với sữa yến mạch được không?",
                            keyWords: [
                                ShadowingKeyWord(lemma: "latte", phonetic: "/ˈlɑː.teɪ/", definitionVi: "cà phê sữa"),
                                ShadowingKeyWord(lemma: "medium", phonetic: "/ˈmiː.di.əm/", definitionVi: "cỡ vừa")
                            ]
                        ),
                        ShadowingSentence(
                            id: "s_03",
                            orderIndex: 2,
                            startTime: 10.0,
                            endTime: 13.5,
                            textEn: "Sure thing! Would you like that for here or to go?",
                            textVi: "Được chứ! Bạn muốn dùng tại đây hay mang đi?",
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
            youtubeVideoId: "kJQP7kiw5Fk",
            title: "Ordering at a Café",
            topic: .dailyLife,
            level: "A2",
            durationSeconds: 32.0,
            sentences: []
        )
    }
}
