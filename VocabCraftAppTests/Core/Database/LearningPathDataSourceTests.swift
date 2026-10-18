import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Learning Path Data Source Tests")
struct LearningPathDataSourceTests {
    private var dbURL: URL {
        get throws {
            for bundle in Bundle.allBundles {
                if let url = bundle.url(forResource: "vocab_content", withExtension: "sqlite") {
                    return url
                }
                if let subURL = bundle.url(
                    forResource: "vocab_content",
                    withExtension: "sqlite",
                    subdirectory: "VocabCraftApp_VocabCraftApp.bundle/Contents/Resources"
                ) {
                    return subURL
                }
                if let subURL = bundle.url(
                    forResource: "vocab_content",
                    withExtension: "sqlite",
                    subdirectory: "VocabCraftApp_VocabCraftApp.bundle"
                ) {
                    return subURL
                }
            }
            let currentFilePath = URL(fileURLWithPath: #filePath)
            let sourceURL = currentFilePath
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("VocabCraftApp/Resources/Content/vocab_content.sqlite")
            if FileManager.default.fileExists(atPath: sourceURL.path) {
                return sourceURL
            }
            struct MissingDatabaseError: Error {}
            throw MissingDatabaseError()
        }
    }

    @Test("Fetch all four curated learning paths and verify path counts and codes")
    func testFetchAllFourLearningPaths() async throws {
        let repo = try SQLiteContentRepository(url: dbURL)
        let paths = try await repo.fetchLearningPaths()
        #expect(paths.count == 4)
        let pathCodes = Set(paths.map(\.code))
        #expect(pathCodes.contains("essential-english-mastery"))
        #expect(pathCodes.contains("daily-life-travel"))
        #expect(pathCodes.contains("business-career"))
        #expect(pathCodes.contains("academic-research"))

        let dailyDecks = try await repo.fetchTopicDecks(for: "c11e8a24-9b2f-4e67-881a-637dc44d3201")
        #expect(dailyDecks.count == 26)
    }

    @Test("Verify all four learning paths have correct metadata and sort order")
    func testCuratedLearningPathsMetadata() async throws {
        let repo = try SQLiteContentRepository(url: dbURL)
        let paths = try await repo.fetchLearningPaths()
        #expect(paths.count == 4)

        let pathsByCode = Dictionary(uniqueKeysWithValues: paths.map { ($0.code, $0) })

        // 1. Essential English Mastery
        let essential = try #require(pathsByCode["essential-english-mastery"])
        #expect(essential.id == "7147ba7e-0728-471d-97af-f3e2262a6d23")
        #expect(essential.goalCategory == "general")
        #expect(essential.targetLevelMin == "A1")
        #expect(essential.targetLevelMax == "C2")
        #expect(essential.sortOrder == 0)

        // 2. Daily Life & Travel Fluency
        let daily = try #require(pathsByCode["daily-life-travel"])
        #expect(daily.id == "c11e8a24-9b2f-4e67-881a-637dc44d3201")
        #expect(daily.titleEn == "Everyday Life & Travel Fluency")
        #expect(daily.titleVi == "Giao Tiếp Đời Sống & Du Lịch Thực Tế")
        #expect(daily.goalCategory == "travel")
        #expect(daily.targetLevelMin == "A1")
        #expect(daily.targetLevelMax == "B1")
        #expect(daily.iconKey == "airplane.departure")
        #expect(daily.themeKey == "forest_green")
        #expect(daily.sortOrder == 1)

        // 3. Business & Workplace Excellence
        let business = try #require(pathsByCode["business-career"])
        #expect(business.id == "d22f9b35-0c30-4f78-992b-748ed55e4312")
        #expect(business.titleEn == "Business & Workplace Excellence")
        #expect(business.titleVi == "Tiếng Anh Công Sở & Phát Triển Sự Nghiệp")
        #expect(business.goalCategory == "business")
        #expect(business.targetLevelMin == "B1")
        #expect(business.targetLevelMax == "B2")
        #expect(business.iconKey == "briefcase.fill")
        #expect(business.themeKey == "ocean_blue")
        #expect(business.sortOrder == 2)

        // 4. Academic Mastery & Critical Inquiries
        let academic = try #require(pathsByCode["academic-research"])
        #expect(academic.id == "e33a0c46-1d41-4089-aa3c-859fe66f5423")
        #expect(academic.titleEn == "Academic Mastery & Critical Inquiries")
        #expect(academic.titleVi == "Tiếng Anh Học Thuật & Nghiên Cứu Chuyên Sâu")
        #expect(academic.goalCategory == "academic")
        #expect(academic.targetLevelMin == "B2")
        #expect(academic.targetLevelMax == "C2")
        #expect(academic.iconKey == "graduationcap.fill")
        #expect(academic.themeKey == "royal_purple")
        #expect(academic.sortOrder == 3)
    }

    @Test("Verify deck counts and deck mappings for each curated path")
    func testCuratedPathDeckMappings() async throws {
        let repo = try SQLiteContentRepository(url: dbURL)

        // Path 1: Essential (48 decks)
        let essentialDecks = try await repo.fetchTopicDecks(for: "7147ba7e-0728-471d-97af-f3e2262a6d23")
        #expect(essentialDecks.count == 48)

        // Path 2: Daily Life & Travel (26 decks)
        let dailyDecks = try await repo.fetchTopicDecks(for: "c11e8a24-9b2f-4e67-881a-637dc44d3201")
        #expect(dailyDecks.count == 26)

        // Path 3: Business & Career (10 decks)
        let businessDecks = try await repo.fetchTopicDecks(for: "d22f9b35-0c30-4f78-992b-748ed55e4312")
        #expect(businessDecks.count == 10)

        // Path 4: Academic & Research (16 decks)
        let academicDecks = try await repo.fetchTopicDecks(for: "e33a0c46-1d41-4089-aa3c-859fe66f5423")
        #expect(academicDecks.count == 16)
    }

    @Test("Verify content_version in dataset_metadata is incremented")
    func testContentVersionIncremented() throws {
        let version = SQLiteContentRepository.readContentVersion(at: try dbURL)
        #expect(version != nil)
        #expect((version ?? 0) >= 8)
    }
}
