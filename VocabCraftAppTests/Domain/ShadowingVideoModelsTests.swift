import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Video Models & Repository Tests")
struct ShadowingVideoModelsTests {
    @Test("Verifies ShadowingVideo and ShadowingSentence initialization and JSON decoding")
    func testShadowingVideoDecoding() throws {
        let json = Data("""
        {
            "id": "yt_coffee_01",
            "youtubeVideoId": "dQw4w9WgXcQ",
            "title": "Ordering Coffee",
            "topic": "dailyLife",
            "level": "A2",
            "durationSeconds": 45.0,
            "sentences": [
                {
                    "id": "s_01",
                    "orderIndex": 0,
                    "startTime": 1.5,
                    "endTime": 4.8,
                    "textEn": "Can I get an iced latte?",
                    "textVi": "Cho tôi một ly latte đá được không?",
                    "keyWords": [
                        {
                            "lemma": "latte",
                            "phonetic": "/ˈlɑː.teɪ/",
                            "definitionVi": "Cà phê sữa"
                        }
                    ]
                }
            ]
        }
        """.utf8)

        let video = try JSONDecoder().decode(ShadowingVideo.self, from: json)
        #expect(video.id == "yt_coffee_01")
        #expect(video.sentences.count == 1)
        #expect(video.sentences.first?.keyWords.first?.lemma == "latte")
    }

    @Test("Verifies ShadowingVideoRepository returns curated videos")
    func testCuratedCatalogFetch() async throws {
        let repository: ShadowingVideoRepositoryProtocol = ShadowingVideoRepositoryImpl()
        let videos = try await repository.fetchCuratedVideos()
        #expect(!videos.isEmpty)
        #expect(videos.first?.sentences.isEmpty == false)
    }
}
