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
                exampleEn: "This is word \(idx).",
                exampleVi: "Đây là từ số \(idx)."
            )
        }
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
    }

    @Test("Handles empty input gracefully")
    func testEmptyWords() {
        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: [], distractorPool: [])
        #expect(steps.isEmpty)
    }

    @Test("Handles single word or small lesson (<=4 words) in a single micro-cycle")
    func testSmallLesson() {
        let sampleWords = makeSampleWords(count: 3)
        let generator = LessonPlanGenerator()
        let steps = generator.generatePlan(from: sampleWords, distractorPool: sampleWords)

        #expect(steps.count == 6) // 3 discovery + 3 exercises
        if case .discovery(let word, let idx, let total) = steps[0] {
            #expect(word.id == 1)
            #expect(idx == 1)
            #expect(total == 3)
        } else {
            #expect(Bool(false), "First step should be discovery")
        }
    }
}
#endif
