import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("SmartCheckpointWordSampler Tests")
struct SmartCheckpointWordSamplerTests {
    private func makeWord(
        id: Int64,
        stageId: String,
        lemma: String? = nil
    ) -> TopicWordDTO {
        TopicWordDTO(
            id: id,
            stageId: stageId,
            lemma: lemma ?? "word_\(id)",
            phonetic: "/w\(id)/",
            pos: "noun",
            cefrLevel: "A1",
            definitionVi: "Nghĩa \(id)",
            definitionEn: "Def \(id)",
            exampleEn: "Example \(id)",
            exampleVi: "Ví dụ \(id)"
        )
    }

    private func makeStage(
        id: String,
        deckId: String = "deck-1",
        sortOrder: Int = 1
    ) -> SubTopicStageDTO {
        SubTopicStageDTO(
            id: id,
            deckId: deckId,
            titleEn: "Stage \(id)",
            titleVi: "Giai đoạn \(id)",
            iconName: "star",
            sortOrder: sortOrder,
            words: []
        )
    }

    @Test("Sampler returns exact target count when pool has sufficient words")
    func testSamplerReturnsExactTargetCount() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [
            makeStage(id: "stage-1", sortOrder: 1),
            makeStage(id: "stage-2", sortOrder: 2),
            makeStage(id: "stage-3", sortOrder: 3),
            makeStage(id: "stage-4", sortOrder: 4)
        ]
        var wordsByStage: [String: [TopicWordDTO]] = [:]
        for stage in stages {
            wordsByStage[stage.id] = (1...6).map { i in
                let wordId = Int64(stage.sortOrder * 100 + i)
                return makeWord(id: wordId, stageId: stage.id)
            }
        }

        let result = sampler.sample(stages: stages, wordsByStage: wordsByStage, targetCount: 10)
        #expect(result.count == 10)
    }

    @Test("Sampler prioritizes weak words")
    func testSamplerPrioritizesWeakWords() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [
            makeStage(id: "stage-1", sortOrder: 1),
            makeStage(id: "stage-2", sortOrder: 2)
        ]
        let weakId: Int64 = 42
        var wordsByStage: [String: [TopicWordDTO]] = [:]
        wordsByStage["stage-1"] = [
            makeWord(id: 101, stageId: "stage-1"),
            makeWord(id: 102, stageId: "stage-1"),
            makeWord(id: weakId, stageId: "stage-1"),
            makeWord(id: 104, stageId: "stage-1"),
            makeWord(id: 105, stageId: "stage-1"),
            makeWord(id: 106, stageId: "stage-1")
        ]
        wordsByStage["stage-2"] = [
            makeWord(id: 201, stageId: "stage-2"),
            makeWord(id: 202, stageId: "stage-2"),
            makeWord(id: 203, stageId: "stage-2"),
            makeWord(id: 204, stageId: "stage-2"),
            makeWord(id: 205, stageId: "stage-2"),
            makeWord(id: 206, stageId: "stage-2")
        ]

        let result = sampler.sample(stages: stages, wordsByStage: wordsByStage, weakWordIds: [weakId], targetCount: 10)
        #expect(result.contains(where: { $0.id == weakId }))
    }

    @Test("Sampler distributes words across all stages")
    func testSamplerDistributesWordsAcrossStages() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [
            makeStage(id: "s1", sortOrder: 1),
            makeStage(id: "s2", sortOrder: 2),
            makeStage(id: "s3", sortOrder: 3),
            makeStage(id: "s4", sortOrder: 4),
            makeStage(id: "s5", sortOrder: 5)
        ]
        var wordsByStage: [String: [TopicWordDTO]] = [:]
        for (idx, stage) in stages.enumerated() {
            wordsByStage[stage.id] = (1...10).map { i in
                makeWord(id: Int64((idx + 1) * 1000 + i), stageId: stage.id)
            }
        }

        let result = sampler.sample(stages: stages, wordsByStage: wordsByStage, targetCount: 10)
        #expect(result.count == 10)

        // Every stage must have representation
        let stageIdsInResult = Set(result.map(\.stageId))
        #expect(stageIdsInResult.count == 5)
        for stage in stages {
            #expect(stageIdsInResult.contains(stage.id))
        }
    }

    @Test("Sampler handles fewer available words than targetCount")
    func testSamplerHandlesFewerWordsThanTargetCount() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [
            makeStage(id: "s1", sortOrder: 1),
            makeStage(id: "s2", sortOrder: 2)
        ]
        let wordsByStage: [String: [TopicWordDTO]] = [
            "s1": [makeWord(id: 1, stageId: "s1"), makeWord(id: 2, stageId: "s1")],
            "s2": [makeWord(id: 3, stageId: "s2")]
        ]

        let result = sampler.sample(stages: stages, wordsByStage: wordsByStage, targetCount: 10)
        #expect(result.count == 3)
    }

    @Test("Sampler returns empty array on empty stages or empty wordsByStage")
    func testSamplerHandlesEmptyStagesOrWords() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [makeStage(id: "s1")]

        #expect(sampler.sample(stages: [], wordsByStage: [:], targetCount: 10).isEmpty)
        #expect(sampler.sample(stages: stages, wordsByStage: [:], targetCount: 10).isEmpty)
        #expect(sampler.sample(stages: stages, wordsByStage: ["s1": []], targetCount: 10).isEmpty)
    }

    @Test("Sampler returns empty array when targetCount is zero or negative")
    func testSamplerHandlesZeroOrNegativeTargetCount() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [makeStage(id: "s1")]
        let wordsByStage = ["s1": [makeWord(id: 1, stageId: "s1")]]

        #expect(sampler.sample(stages: stages, wordsByStage: wordsByStage, targetCount: 0).isEmpty)
        #expect(sampler.sample(stages: stages, wordsByStage: wordsByStage, targetCount: -5).isEmpty)
    }

    @Test("Sampler deduplicates words with identical IDs")
    func testSamplerDeduplicatesWords() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [
            makeStage(id: "s1", sortOrder: 1),
            makeStage(id: "s2", sortOrder: 2)
        ]
        let duplicateWord = makeWord(id: 99, stageId: "s1")
        let wordsByStage: [String: [TopicWordDTO]] = [
            "s1": [duplicateWord, makeWord(id: 1, stageId: "s1")],
            "s2": [duplicateWord, makeWord(id: 2, stageId: "s2")]
        ]

        let result = sampler.sample(stages: stages, wordsByStage: wordsByStage, targetCount: 10)
        let uniqueIds = Set(result.map(\.id))
        #expect(result.count == uniqueIds.count)
    }

    @Test("Sampler prioritizes multiple weak words in a stage")
    func testSamplerPrioritizesMultipleWeakWordsWithinStage() {
        let sampler = SmartCheckpointWordSampler()
        let stages = [makeStage(id: "s1", sortOrder: 1)]
        let words = (1...10).map { makeWord(id: Int64($0), stageId: "s1") }
        let wordsByStage = ["s1": words]

        let weakIds: Set<Int64> = [10, 8, 5]
        let result = sampler.sample(stages: stages, wordsByStage: wordsByStage, weakWordIds: weakIds, targetCount: 3)

        #expect(result.count == 3)
        let resultIds = Set(result.map(\.id))
        #expect(resultIds == weakIds)
    }
}
#endif
