import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Lesson Plan Generator Tests")
struct LessonPlanGeneratorTests {
    private func makeSampleWords(count: Int) -> [TopicWordDTO] {
        (1...count).map { idx in
            TopicWordDTO(
                id: Int64(idx),
                stageId: "stage_1",
                lemma: "word\(idx)",
                phonetic: "/wɜːd\(idx)/",
                pos: "noun",
                cefrLevel: "A1",
                definitionVi: "từ số \(idx)",
                definitionEn: "word number \(idx)",
                exampleEn: "This is word\(idx).",
                exampleVi: "Đây là từ số \(idx)."
            )
        }
    }

    @Test("Partitions 5 words into single cycle with exactly 5 discovery words and no duplicates")
    func testPartitioningFiveWords() {
        let sampleWords = makeSampleWords(count: 5)
        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: sampleWords, distractorPool: sampleWords)

        let discoveryWords = steps.compactMap { step -> TopicWordDTO? in
            if case .discovery(let word, _, _) = step { return word }
            return nil
        }
        #expect(discoveryWords.count == 5)
        let uniqueIds = Set(discoveryWords.map(\.id))
        #expect(uniqueIds.count == 5, "Discovery steps must contain exactly 5 unique words without duplicates")
        #expect(uniqueIds == Set(sampleWords.map(\.id)))
    }

    @Test("Partitions 6 words into 2 micro-cycles with discovery and exercises")
    func testPartitioningSixWords() {
        let sampleWords = makeSampleWords(count: 6)
        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: sampleWords, distractorPool: sampleWords)

        #expect(!steps.isEmpty)
        let discoverySteps = steps.filter { step in
            if case .discovery = step { return true }
            return false
        }
        #expect(discoverySteps.count == 6)

        let exerciseSteps = steps.compactMap { step -> LessonExerciseItem? in
            if case .exercise(let item) = step { return item }
            return nil
        }
        #expect(exerciseSteps.count == 6)

        // Verify that Multiple Choice and Listening items have 4 options
        for item in exerciseSteps {
            if item.assignedMode == .multipleChoice || item.assignedMode == .listening {
                #expect(item.options.count == 4)
                #expect(item.options.contains(where: { $0.isCorrect }))
            }
        }

        // With global index rotation, 6 words cover all 4 modalities
        let modes = Set(exerciseSteps.map(\.assignedMode))
        #expect(modes.contains(.listening))
        #expect(modes.contains(.multipleChoice))
        #expect(modes.contains(.speaking))
        #expect(modes.contains(.typing))
    }

    @Test("Single chunk of 4 words covers all 4 modalities including typing")
    func testAllFourModalitiesCoveredWithFourWords() {
        let sampleWords = makeSampleWords(count: 4)
        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: sampleWords, distractorPool: sampleWords)

        let exerciseSteps = steps.compactMap { step -> LessonExerciseItem? in
            if case .exercise(let item) = step { return item }
            return nil
        }
        #expect(exerciseSteps.count == 4)

        let modes = exerciseSteps.map(\.assignedMode)
        #expect(modes == [.listening, .multipleChoice, .speaking, .typing])
    }

    @Test("Partitions 7 words into balanced chunks of 4 and 3 without tiny 1-word chunk")
    func testBalancedChunkingSevenWords() {
        let sampleWords = makeSampleWords(count: 7)
        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: sampleWords, distractorPool: sampleWords)

        let discoverySteps = steps.compactMap { step -> (Int, Int)? in
            if case .discovery(_, let idx, let total) = step { return (idx, total) }
            return nil
        }
        #expect(discoverySteps.count == 7)

        // The chunks should have totals of 4 and 3, never 1
        let totals = discoverySteps.map(\.1)
        #expect(totals == [4, 4, 4, 4, 3, 3, 3])
    }

    @Test("Handles empty input gracefully")
    func testEmptyWords() {
        let generator = LessonPlanGenerator()
        let emptyWords: [TopicWordDTO] = []
        let steps = generator.generatePlan(from: emptyWords, distractorPool: emptyWords)
        #expect(steps.isEmpty)

        let emptySenses: [SenseDetail] = []
        let senseSteps = generator.generatePlan(from: emptySenses, distractorPool: emptySenses)
        #expect(senseSteps.isEmpty)
    }

    @Test("Generated exercise items include valid cloze stages with masked slots")
    func testGeneratedClozeStages() {
        let sampleWords = makeSampleWords(count: 2)
        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: sampleWords, distractorPool: sampleWords)

        let exerciseSteps = steps.compactMap { step -> LessonExerciseItem? in
            if case .exercise(let item) = step { return item }
            return nil
        }
        #expect(!exerciseSteps.isEmpty)

        for item in exerciseSteps {
            let stages = item.clozeStages
            #expect(stages.initialParts.slot.contains("_"))
            let lemma = item.word.lemma.lowercased()
            #expect(!stages.initialParts.prefix.lowercased().contains(lemma))
            #expect(!stages.initialParts.suffix.lowercased().contains(lemma))
        }
    }

    @Test("Generates plan from SenseDetail models with multiword support")
    func testGeneratePlanFromSenses() {
        let senseID1 = SenseID(rawValue: UUID())
        let sense1 = SenseDetail(
            id: senseID1,
            entryID: EntryID(rawValue: UUID()),
            headword: "look up",
            entryKind: .phrasalVerb,
            partOfSpeech: .verb,
            definitionEN: "To search for information",
            definitionVI: "Tra cứu thông tin",
            cefrLevel: .a2,
            examples: [
                ExampleSnapshot(
                    id: "ex1",
                    senseID: senseID1,
                    textEN: "I looked up the word in the dictionary.",
                    textVI: "Tôi đã tra cứu từ trong từ điển."
                )
            ]
        )
        let senseID2 = SenseID(rawValue: UUID())
        let sense2 = SenseDetail(
            id: senseID2,
            entryID: EntryID(rawValue: UUID()),
            headword: "resilience",
            entryKind: .word,
            partOfSpeech: .noun,
            definitionEN: "The capacity to recover quickly from difficulties",
            definitionVI: "Sự kiên cường",
            cefrLevel: .b2,
            examples: [
                ExampleSnapshot(
                    id: "ex2",
                    senseID: senseID2,
                    textEN: "She showed great resilience in facing adversity.",
                    textVI: "Cô ấy đã thể hiện sự kiên cường tuyệt vời."
                )
            ]
        )

        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: [sense1, sense2], distractorPool: [sense1, sense2])
        #expect(steps.count == 4)

        let discoverySteps = steps.compactMap { step -> SenseDetail? in
            if case .senseDiscovery(let sense, _, _) = step { return sense }
            return nil
        }
        #expect(discoverySteps.count == 2)
        #expect(discoverySteps[0].headword == "look up")
        #expect(discoverySteps[1].headword == "resilience")

        let exerciseSteps = steps.compactMap { step -> LessonExerciseItem? in
            if case .exercise(let item) = step { return item }
            return nil
        }
        #expect(exerciseSteps.count == 2)
        let multiwordItem = exerciseSteps.first(where: { $0.lemma == "look up" })
        #expect(multiwordItem != nil)
        #expect(multiwordItem?.clozeStages.initialParts.slot.contains("_") == true)
        #expect(multiwordItem?.senseID == sense1.id)
        #expect(multiwordItem?.word.lemma == "look up")
        #expect(multiwordItem?.word.id != 0)
    }
}
#endif
