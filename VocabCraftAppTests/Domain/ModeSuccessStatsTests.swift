import Foundation
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("ModeSuccessStats Tests")
struct ModeSuccessStatsTests {
    @Test("Default initialization has zero counts")
    func testDefaultInit() {
        let stats = ModeSuccessStats()
        #expect(stats.speaking == 0)
        #expect(stats.typing == 0)
        #expect(stats.multipleChoice == 0)
        #expect(stats.listening == 0)
        #expect(stats.totalSuccesses == 0)
        #expect(stats.completedModes.isEmpty)
        #expect(!stats.isFullyMasteredAllModes)
        #expect(stats.lowestSuccessModes.count == 4)
    }

    @Test("Custom initialization with counts")
    func testCustomInit() {
        let stats = ModeSuccessStats(speaking: 1, typing: 2, multipleChoice: 3, listening: 4)
        #expect(stats.count(for: .speaking) == 1)
        #expect(stats.count(for: .typing) == 2)
        #expect(stats.count(for: .multipleChoice) == 3)
        #expect(stats.count(for: .listening) == 4)
        #expect(stats.totalSuccesses == 10)
        #expect(stats.completedModes == [.speaking, .typing, .multipleChoice, .listening])
        #expect(stats.isFullyMasteredAllModes)
        #expect(stats.lowestSuccessModes == [.speaking])
    }

    @Test("Incrementing modes updates counts and lowestSuccessModes")
    func testIncrementAndLowestModes() {
        var stats = ModeSuccessStats()
        stats.increment(for: .speaking)
        stats.increment(for: .speaking)
        stats.increment(for: .typing)

        #expect(stats.count(for: .speaking) == 2)
        #expect(stats.count(for: .typing) == 1)
        #expect(stats.count(for: .multipleChoice) == 0)
        #expect(stats.count(for: .listening) == 0)
        #expect(stats.lowestSuccessModes.contains(.multipleChoice))
        #expect(stats.lowestSuccessModes.contains(.listening))
        #expect(!stats.lowestSuccessModes.contains(.speaking))
        #expect(!stats.lowestSuccessModes.contains(.typing))
    }

    @Test("Codec encode and decode matches exact values")
    func testCodecRoundTrip() {
        let stats = ModeSuccessStats(speaking: 3, typing: 5, multipleChoice: 1, listening: 2)
        let encoded = ModeSuccessStatsCodec.encode(stats)
        let decoded = ModeSuccessStatsCodec.decode(encoded)
        #expect(decoded == stats)
    }

    @Test("Codec handles empty and partial inputs gracefully")
    func testCodecEdgeCases() {
        let emptyDecoded = ModeSuccessStatsCodec.decode("")
        #expect(emptyDecoded == ModeSuccessStats())

        let partialDecoded = ModeSuccessStatsCodec.decode("s:2,t:1")
        #expect(partialDecoded.speaking == 2)
        #expect(partialDecoded.typing == 1)
        #expect(partialDecoded.multipleChoice == 0)
        #expect(partialDecoded.listening == 0)

        let invalidDecoded = ModeSuccessStatsCodec.decode("random_string,invalid:format,s:5")
        #expect(invalidDecoded.speaking == 5)
        #expect(invalidDecoded.typing == 0)
    }

    @Test("UserWordProgress convenience modeStats property syncs with raw string")
    func testUserWordProgressModeStats() {
        let progress = UserWordProgress(wordId: 101)
        #expect(progress.modeStats == ModeSuccessStats())
        #expect(progress.modeSuccessCountsRaw == "")

        var stats = ModeSuccessStats()
        stats.increment(for: .speaking)
        stats.increment(for: .listening)
        progress.modeStats = stats

        #expect(progress.modeStats.speaking == 1)
        #expect(progress.modeStats.listening == 1)
        #expect(progress.modeStats.typing == 0)
        #expect(progress.modeStats.multipleChoice == 0)
        #expect(progress.modeSuccessCountsRaw.contains("s:1"))
        #expect(progress.modeSuccessCountsRaw.contains("l:1"))
    }

    @Test("VaultWordItem default and custom modeStats initialization")
    func testVaultWordItemModeStats() {
        let defaultItem = VaultWordItem(id: 1, lemma: "test", pos: "n", definitionVi: "thử")
        #expect(defaultItem.modeStats == ModeSuccessStats())

        let customStats = ModeSuccessStats(speaking: 2, typing: 1, multipleChoice: 3, listening: 0)
        let customItem = VaultWordItem(
            id: 2,
            lemma: "test2",
            pos: "v",
            definitionVi: "thử 2",
            modeStats: customStats
        )
        #expect(customItem.modeStats == customStats)
    }
}
#endif

final class ModeSuccessStatsXCTestCase: XCTestCase {
    func testDefaultInit() {
        let stats = ModeSuccessStats()
        XCTAssertEqual(stats.speaking, 0)
        XCTAssertEqual(stats.typing, 0)
        XCTAssertEqual(stats.multipleChoice, 0)
        XCTAssertEqual(stats.listening, 0)
        XCTAssertEqual(stats.totalSuccesses, 0)
        XCTAssertTrue(stats.completedModes.isEmpty)
        XCTAssertFalse(stats.isFullyMasteredAllModes)
        XCTAssertEqual(stats.lowestSuccessModes.count, 4)
    }

    func testCustomInit() {
        let stats = ModeSuccessStats(speaking: 1, typing: 2, multipleChoice: 3, listening: 4)
        XCTAssertEqual(stats.count(for: .speaking), 1)
        XCTAssertEqual(stats.count(for: .typing), 2)
        XCTAssertEqual(stats.count(for: .multipleChoice), 3)
        XCTAssertEqual(stats.count(for: .listening), 4)
        XCTAssertEqual(stats.totalSuccesses, 10)
        XCTAssertEqual(stats.completedModes, [.speaking, .typing, .multipleChoice, .listening])
        XCTAssertTrue(stats.isFullyMasteredAllModes)
        XCTAssertEqual(stats.lowestSuccessModes, [.speaking])
    }

    func testIncrementAndLowestModes() {
        var stats = ModeSuccessStats()
        stats.increment(for: .speaking)
        stats.increment(for: .speaking)
        stats.increment(for: .typing)

        XCTAssertEqual(stats.count(for: .speaking), 2)
        XCTAssertEqual(stats.count(for: .typing), 1)
        XCTAssertEqual(stats.count(for: .multipleChoice), 0)
        XCTAssertEqual(stats.count(for: .listening), 0)
        XCTAssertTrue(stats.lowestSuccessModes.contains(.multipleChoice))
        XCTAssertTrue(stats.lowestSuccessModes.contains(.listening))
        XCTAssertFalse(stats.lowestSuccessModes.contains(.speaking))
        XCTAssertFalse(stats.lowestSuccessModes.contains(.typing))
    }

    func testCodecRoundTrip() {
        let stats = ModeSuccessStats(speaking: 3, typing: 5, multipleChoice: 1, listening: 2)
        let encoded = ModeSuccessStatsCodec.encode(stats)
        let decoded = ModeSuccessStatsCodec.decode(encoded)
        XCTAssertEqual(decoded, stats)
    }

    func testCodecEdgeCases() {
        let emptyDecoded = ModeSuccessStatsCodec.decode("")
        XCTAssertEqual(emptyDecoded, ModeSuccessStats())

        let partialDecoded = ModeSuccessStatsCodec.decode("s:2,t:1")
        XCTAssertEqual(partialDecoded.speaking, 2)
        XCTAssertEqual(partialDecoded.typing, 1)
        XCTAssertEqual(partialDecoded.multipleChoice, 0)
        XCTAssertEqual(partialDecoded.listening, 0)

        let invalidDecoded = ModeSuccessStatsCodec.decode("random_string,invalid:format,s:5")
        XCTAssertEqual(invalidDecoded.speaking, 5)
        XCTAssertEqual(invalidDecoded.typing, 0)
    }

    func testUserWordProgressModeStats() {
        let progress = UserWordProgress(wordId: 101)
        XCTAssertEqual(progress.modeStats, ModeSuccessStats())
        XCTAssertEqual(progress.modeSuccessCountsRaw, "")

        var stats = ModeSuccessStats()
        stats.increment(for: .speaking)
        stats.increment(for: .listening)
        progress.modeStats = stats

        XCTAssertEqual(progress.modeStats.speaking, 1)
        XCTAssertEqual(progress.modeStats.listening, 1)
        XCTAssertEqual(progress.modeStats.typing, 0)
        XCTAssertEqual(progress.modeStats.multipleChoice, 0)
        XCTAssertTrue(progress.modeSuccessCountsRaw.contains("s:1"))
        XCTAssertTrue(progress.modeSuccessCountsRaw.contains("l:1"))
    }

    func testVaultWordItemModeStats() {
        let defaultItem = VaultWordItem(id: 1, lemma: "test", pos: "n", definitionVi: "thử")
        XCTAssertEqual(defaultItem.modeStats, ModeSuccessStats())

        let customStats = ModeSuccessStats(speaking: 2, typing: 1, multipleChoice: 3, listening: 0)
        let customItem = VaultWordItem(
            id: 2,
            lemma: "test2",
            pos: "v",
            definitionVi: "thử 2",
            modeStats: customStats
        )
        XCTAssertEqual(customItem.modeStats, customStats)
    }
}
