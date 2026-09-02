import Foundation

public protocol LessonPlanGeneratorProtocol: Sendable {
    func generatePlan(from words: [TopicWordDTO], distractorPool: [TopicWordDTO]) -> [LessonStep]
}

public final class LessonPlanGenerator: LessonPlanGeneratorProtocol, Sendable {
    public init() {}

    public func generatePlan(from words: [TopicWordDTO], distractorPool: [TopicWordDTO]) -> [LessonStep] {
        guard !words.isEmpty else { return [] }

        let chunkSize = words.count <= 4 ? words.count : 3
        let chunks = stride(from: 0, to: words.count, by: chunkSize).map {
            Array(words[$0..<min($0 + chunkSize, words.count)])
        }

        var steps: [LessonStep] = []
        let allModes: [ReflexBlitzMode] = [.listening, .multipleChoice, .speaking, .typing]
        let pool = distractorPool.isEmpty ? words : distractorPool

        for chunk in chunks {
            // 1. Discovery Phase for words in this micro-cycle
            for (index, word) in chunk.enumerated() {
                steps.append(.discovery(word: word, index: index + 1, totalInCycle: chunk.count))
            }

            // 2. Interactive Practice Phase across 4 modalities
            for (wIdx, word) in chunk.enumerated() {
                let mode = allModes[wIdx % allModes.count]
                let options: [ReflexBlitzOption] = (mode == .multipleChoice || mode == .listening)
                    ? ReflexDistractorGenerator.generateOptions(
                        mode: mode,
                        target: ReflexBlitzWordItem(from: word),
                        pool: pool.map { ReflexBlitzWordItem(from: $0) }
                    )
                    : []
                let clozeStages = ReflexHintMaskGenerator.generateStages(
                    lemma: word.lemma,
                    sentenceEn: word.exampleEn,
                    pos: word.pos
                )
                let item = LessonExerciseItem(
                    id: "\(mode.rawValue)-\(word.id)-\(UUID().uuidString.prefix(6))",
                    word: word,
                    assignedMode: mode,
                    options: options,
                    clozeStages: clozeStages,
                    attemptCount: 1,
                    isRequeued: false
                )
                steps.append(.exercise(item: item))
            }
        }

        return steps
    }
}
