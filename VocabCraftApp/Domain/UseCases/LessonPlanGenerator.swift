import Foundation

public protocol LessonPlanGeneratorProtocol: Sendable {
    func generatePlan(from words: [TopicWordDTO], distractorPool: [TopicWordDTO]) -> [LessonStep]
    func generatePlan(from senses: [SenseDetail], distractorPool: [SenseDetail]) -> [LessonStep]
}

public final class LessonPlanGenerator: LessonPlanGeneratorProtocol, Sendable {
    public init() {}

    public func generatePlan(from words: [TopicWordDTO], distractorPool: [TopicWordDTO]) -> [LessonStep] {
        guard !words.isEmpty else { return [] }

        let chunks = partitionIntoMicroCycles(words)

        var steps: [LessonStep] = []
        let allModes: [ReflexBlitzMode] = [.listening, .multipleChoice, .speaking, .typing]
        let pool = distractorPool.isEmpty ? words : distractorPool
        var globalWordIndex = 0

        for chunk in chunks {
            // 1. Discovery Phase for words in this micro-cycle
            for (index, word) in chunk.enumerated() {
                steps.append(.discovery(word: word, index: index + 1, totalInCycle: chunk.count))
            }

            // 2. Interactive Practice Phase across 4 modalities
            for word in chunk {
                let mode = allModes[globalWordIndex % allModes.count]
                globalWordIndex += 1

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

    public func generatePlan(from senses: [SenseDetail], distractorPool: [SenseDetail]) -> [LessonStep] {
        guard !senses.isEmpty else { return [] }

        let chunks = partitionIntoMicroCycles(senses)

        var steps: [LessonStep] = []
        let allModes: [ReflexBlitzMode] = [.listening, .multipleChoice, .speaking, .typing]
        let pool = distractorPool.isEmpty ? senses : distractorPool
        var globalSenseIndex = 0

        for chunk in chunks {
            // 1. Discovery Phase for senses in this micro-cycle
            for (index, sense) in chunk.enumerated() {
                steps.append(.senseDiscovery(sense: sense, index: index + 1, totalInCycle: chunk.count))
            }

            // 2. Interactive Practice Phase across 4 modalities
            for sense in chunk {
                let mode = allModes[globalSenseIndex % allModes.count]
                globalSenseIndex += 1

                let options: [ReflexBlitzOption] = (mode == .multipleChoice || mode == .listening)
                    ? ReflexDistractorGenerator.generateOptions(
                        mode: mode,
                        target: ReflexBlitzWordItem(from: sense),
                        pool: pool.map { ReflexBlitzWordItem(from: $0) }
                    )
                    : []
                let sentenceEn = sense.examples.first?.textEN ?? ""
                let clozeStages = ReflexHintMaskGenerator.generateStages(
                    lemma: sense.headword,
                    sentenceEn: sentenceEn,
                    pos: sense.partOfSpeech.rawValue
                )
                let item = LessonExerciseItem(
                    id: "\(mode.rawValue)-\(sense.id.rawValue.uuidString.lowercased())-\(UUID().uuidString.prefix(6))",
                    sense: sense,
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

    private func partitionIntoMicroCycles<T>(_ items: [T]) -> [[T]] {
        guard items.count > 5 else { return [items] }
        var chunks: [[T]] = []
        var remaining = items[...]
        while !remaining.isEmpty {
            let count = remaining.count
            let take: Int
            if count <= 4 {
                take = count
            } else if count % 3 == 1 || count == 8 {
                take = 4
            } else {
                take = 3
            }
            chunks.append(Array(remaining.prefix(take)))
            remaining = remaining.dropFirst(take)
        }
        return chunks
    }
}
