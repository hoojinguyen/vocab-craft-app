import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ShadowingCatalogRepository Tests")
struct ShadowingCatalogRepositoryTests {
    private func resolveCatalogURL() throws -> URL {
        let testBundle = Bundle(for: BundleLocator.self)
        if let url = testBundle.url(forResource: "ShadowingCatalog", withExtension: "sqlite") {
            return url
        }
        if let subURL = testBundle.url(
            forResource: "ShadowingCatalog",
            withExtension: "sqlite",
            subdirectory: "VocabCraftApp_VocabCraftApp.bundle"
        ) {
            return subURL
        }
        let currentFilePath = URL(fileURLWithPath: #filePath)
        let sourceURL = currentFilePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("VocabCraftApp/Resources/ShadowingCatalog.sqlite")
        if FileManager.default.fileExists(atPath: sourceURL.path) {
            return sourceURL
        }
        struct MissingCatalogDatabaseError: Error {}
        throw MissingCatalogDatabaseError()
    }

    private func makeRepository() throws -> ShadowingCatalogRepository {
        let url = try resolveCatalogURL()
        return try ShadowingCatalogRepository(fileURL: url)
    }

    @Test("Verifies fetching topics returns all 4 curated topics in display order")
    func testFetchTopics() async throws {
        let repository = try makeRepository()
        let topics = try await repository.fetchTopics()

        #expect(topics.count >= 4)
        #expect(topics == topics.sorted(by: { $0.displayOrder < $1.displayOrder }))

        let dailyTopic = topics.first(where: { $0.id == "dailyLife" })
        #expect(dailyTopic != nil)
        #expect(dailyTopic?.titleEn == "Daily Life")
        #expect(dailyTopic?.titleVi == "Đời sống hàng ngày")
        #expect(dailyTopic?.iconName.isEmpty == false)
    }

    @Test("Verifies fetching all videos without filters returns at least 5 lessons")
    func testFetchAllVideos() async throws {
        let repository = try makeRepository()
        let videos = try await repository.fetchVideos(topicId: nil, level: nil)

        #expect(videos.count >= 5)
        for video in videos {
            #expect(!video.id.isEmpty)
            #expect(!video.youtubeVideoId.isEmpty)
            #expect(!video.title.isEmpty)
            #expect(video.durationSeconds > 0)
            #expect(!video.sentences.isEmpty)
        }
    }

    @Test("Verifies filtering videos by topicId returns only matching videos")
    func testFetchVideosFilteredByTopic() async throws {
        let repository = try makeRepository()
        let videos = try await repository.fetchVideos(topicId: "dailyLife", level: nil)

        #expect(!videos.isEmpty)
        for video in videos {
            #expect(video.topic == .dailyLife)
        }
    }

    @Test("Verifies filtering videos by CEFR level")
    func testFetchVideosFilteredByLevel() async throws {
        let repository = try makeRepository()
        let a1Videos = try await repository.fetchVideos(topicId: nil, level: "A1")
        #expect(!a1Videos.isEmpty)
        for video in a1Videos {
            #expect(video.level == "A1")
        }

        let b1Videos = try await repository.fetchVideos(topicId: nil, level: "B1")
        #expect(!b1Videos.isEmpty)
        for video in b1Videos {
            #expect(video.level == "B1")
        }
    }

    @Test("Verifies filtering videos by topic and level simultaneously")
    func testFetchVideosFilteredByTopicAndLevel() async throws {
        let repository = try makeRepository()
        let videos = try await repository.fetchVideos(topicId: "dailyLife", level: "A2")

        #expect(!videos.isEmpty)
        for video in videos {
            #expect(video.topic == .dailyLife)
            #expect(video.level == "A2")
        }
    }

    @Test("Verifies fetching video by ID includes parsed words_json and keywords")
    func testFetchVideoByIdWithWordsAndKeywords() async throws {
        let repository = try makeRepository()
        let video = try await repository.fetchVideo(byId: "yt_daily_coffee_01")

        #expect(video != nil)
        guard let video else { return }

        #expect(video.id == "yt_daily_coffee_01")
        #expect(video.level == "A2")
        #expect(video.topic == .dailyLife)
        #expect(video.accent == "American")
        #expect(video.thumbnailUrl != nil)
        #expect(!video.sentences.isEmpty)

        // Check word timestamps
        let firstSentence = video.sentences[0]
        #expect(!firstSentence.words.isEmpty)
        let firstWord = firstSentence.words[0]
        #expect(!firstWord.word.isEmpty)
        #expect(firstWord.end >= firstWord.start)

        // Check keywords
        let secondSentence = video.sentences.first(where: { $0.orderIndex == 1 })
        #expect(secondSentence != nil)
        #expect(secondSentence?.keyWords.contains(where: { $0.lemma == "flat white" }) == true)
    }

    @Test("Verifies fetching video by non-existent ID returns nil")
    func testFetchVideoByNonExistentId() async throws {
        let repository = try makeRepository()
        let video = try await repository.fetchVideo(byId: "unknown_id_xyz")
        #expect(video == nil)
    }

    @Test("Verifies database throws error on non-existent file path")
    func testDatabaseThrowsOnMissingFile() {
        let nonExistentURL = FileManager.default.temporaryDirectory.appendingPathComponent("non_existent_\(UUID().uuidString).sqlite")
        #expect(throws: ShadowingSQLiteError.self) {
            _ = try ShadowingSQLiteDatabase(fileURL: nonExistentURL)
        }
    }
}

private final class BundleLocator {}
