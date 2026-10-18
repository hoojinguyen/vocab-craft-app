import Foundation

/// Protocol defining the contract for sampling vocabulary words for milestone checkpoint drills.
public protocol SmartCheckpointWordSamplerProtocol: Sendable {
    /// Samples a focused, balanced selection of vocabulary words across a unit's stages, prioritizing weak words.
    /// - Parameters:
    ///   - stages: The ordered sub-stages comprising the topic deck.
    ///   - wordsByStage: Dictionary mapping each stage ID to its available topic words.
    ///   - weakWordIds: Set of word IDs identified as needing review or having low mastery scores.
    ///   - targetCount: Target number of words to sample (typically 10–12).
    /// - Returns: A deduplicated array of up to `targetCount` sampled words.
    func sample(
        stages: [SubTopicStageDTO],
        wordsByStage: [String: [TopicWordDTO]],
        weakWordIds: Set<Int64>,
        targetCount: Int
    ) -> [TopicWordDTO]
}

public extension SmartCheckpointWordSamplerProtocol {
    /// Samples words with default empty weak word IDs.
    func sample(
        stages: [SubTopicStageDTO],
        wordsByStage: [String: [TopicWordDTO]],
        targetCount: Int = 10
    ) -> [TopicWordDTO] {
        sample(
            stages: stages,
            wordsByStage: wordsByStage,
            weakWordIds: [],
            targetCount: targetCount
        )
    }

    /// Convenience overload supporting array representation of weak word IDs.
    func sample(
        stages: [SubTopicStageDTO],
        wordsByStage: [String: [TopicWordDTO]],
        weakWordIds: [Int64],
        targetCount: Int = 10
    ) -> [TopicWordDTO] {
        sample(
            stages: stages,
            wordsByStage: wordsByStage,
            weakWordIds: Set(weakWordIds),
            targetCount: targetCount
        )
    }
}

/// Intelligent sampler that stratifies vocabulary selection across sub-stages
/// while prioritizing SRS weak words for micro-learning milestone review drills.
public final class SmartCheckpointWordSampler: SmartCheckpointWordSamplerProtocol, Sendable {
    private struct StageCandidatePool {
        let stageId: String
        var weakWords: [TopicWordDTO]
        var normalWords: [TopicWordDTO]
    }

    public init() {}

    public func sample(
        stages: [SubTopicStageDTO],
        wordsByStage: [String: [TopicWordDTO]],
        weakWordIds: Set<Int64> = [],
        targetCount: Int = 10
    ) -> [TopicWordDTO] {
        guard targetCount > 0, !stages.isEmpty, !wordsByStage.isEmpty else {
            return []
        }

        let activeStages = activeStages(from: stages, wordsByStage: wordsByStage)
        guard !activeStages.isEmpty else {
            return []
        }

        let allUniqueWords = collectUniqueWords(from: activeStages, wordsByStage: wordsByStage)
        if allUniqueWords.count <= targetCount {
            return allUniqueWords
        }

        var pools = makeStagePools(from: activeStages, wordsByStage: wordsByStage, weakWordIds: weakWordIds)
        var selectedWords: [TopicWordDTO] = []
        selectedWords.reserveCapacity(targetCount)
        var selectedIds = Set<Int64>()

        allocateStratifiedQuotas(
            pools: &pools,
            targetCount: targetCount,
            selectedWords: &selectedWords,
            selectedIds: &selectedIds
        )

        backfillRemainingSlots(
            pools: &pools,
            targetCount: targetCount,
            selectedWords: &selectedWords,
            selectedIds: &selectedIds
        )

        return selectedWords
    }

    private func activeStages(
        from stages: [SubTopicStageDTO],
        wordsByStage: [String: [TopicWordDTO]]
    ) -> [SubTopicStageDTO] {
        stages
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { stage in
                guard let words = wordsByStage[stage.id] else { return false }
                return !words.isEmpty
            }
    }

    private func collectUniqueWords(
        from stages: [SubTopicStageDTO],
        wordsByStage: [String: [TopicWordDTO]]
    ) -> [TopicWordDTO] {
        var uniqueWords: [TopicWordDTO] = []
        var seenIds = Set<Int64>()
        for stage in stages {
            let stageWords = wordsByStage[stage.id] ?? []
            for word in stageWords where seenIds.insert(word.id).inserted {
                uniqueWords.append(word)
            }
        }
        return uniqueWords
    }

    private func makeStagePools(
        from stages: [SubTopicStageDTO],
        wordsByStage: [String: [TopicWordDTO]],
        weakWordIds: Set<Int64>
    ) -> [StageCandidatePool] {
        stages.map { stage in
            let stageWords = wordsByStage[stage.id] ?? []
            var seen = Set<Int64>()
            var weak: [TopicWordDTO] = []
            var normal: [TopicWordDTO] = []

            for word in stageWords where seen.insert(word.id).inserted {
                if weakWordIds.contains(word.id) {
                    weak.append(word)
                } else {
                    normal.append(word)
                }
            }
            return StageCandidatePool(stageId: stage.id, weakWords: weak, normalWords: normal)
        }
    }

    private func allocateStratifiedQuotas(
        pools: inout [StageCandidatePool],
        targetCount: Int,
        selectedWords: inout [TopicWordDTO],
        selectedIds: inout Set<Int64>
    ) {
        let stageCount = pools.count
        guard stageCount > 0 else { return }

        let baseQuota = targetCount / stageCount
        let remainder = targetCount % stageCount

        for index in 0..<pools.count {
            let quota = baseQuota + (index < remainder ? 1 : 0)
            guard quota > 0 else { continue }

            var stageSelected = 0
            while stageSelected < quota, !pools[index].weakWords.isEmpty {
                let candidate = pools[index].weakWords.removeFirst()
                if selectedIds.insert(candidate.id).inserted {
                    selectedWords.append(candidate)
                    stageSelected += 1
                }
            }
            while stageSelected < quota, !pools[index].normalWords.isEmpty {
                let candidate = pools[index].normalWords.removeFirst()
                if selectedIds.insert(candidate.id).inserted {
                    selectedWords.append(candidate)
                    stageSelected += 1
                }
            }
        }
    }

    private func backfillRemainingSlots(
        pools: inout [StageCandidatePool],
        targetCount: Int,
        selectedWords: inout [TopicWordDTO],
        selectedIds: inout Set<Int64>
    ) {
        guard selectedWords.count < targetCount else { return }

        // Drain any unselected weak words first
        for index in 0..<pools.count where selectedWords.count < targetCount {
            while selectedWords.count < targetCount, !pools[index].weakWords.isEmpty {
                let candidate = pools[index].weakWords.removeFirst()
                if selectedIds.insert(candidate.id).inserted {
                    selectedWords.append(candidate)
                }
            }
        }

        // Drain remaining normal words in round-robin fashion
        while selectedWords.count < targetCount {
            var addedAny = false
            for index in 0..<pools.count where selectedWords.count < targetCount {
                if !pools[index].normalWords.isEmpty {
                    let candidate = pools[index].normalWords.removeFirst()
                    if selectedIds.insert(candidate.id).inserted {
                        selectedWords.append(candidate)
                        addedAny = true
                    }
                }
            }
            if !addedAny {
                break
            }
        }
    }
}
