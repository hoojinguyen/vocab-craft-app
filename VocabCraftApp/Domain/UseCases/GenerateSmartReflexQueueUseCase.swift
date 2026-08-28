import Foundation

public protocol GenerateSmartReflexQueueUseCaseProtocol: Sendable {
    func execute(
        allLearnedWords: [ReflexDrillItem],
        currentTopicWords: [ReflexDrillItem],
        targetCount: Int
    ) -> [ReflexDrillItem]
}

public extension GenerateSmartReflexQueueUseCaseProtocol {
    func execute(
        allLearnedWords: [ReflexDrillItem],
        currentTopicWords: [ReflexDrillItem]
    ) -> [ReflexDrillItem] {
        execute(
            allLearnedWords: allLearnedWords,
            currentTopicWords: currentTopicWords,
            targetCount: 10
        )
    }
}

public final class GenerateSmartReflexQueueUseCase: GenerateSmartReflexQueueUseCaseProtocol, Sendable {
    public init() {}

    public func execute(
        allLearnedWords: [ReflexDrillItem],
        currentTopicWords: [ReflexDrillItem],
        targetCount: Int = 10
    ) -> [ReflexDrillItem] {
        guard targetCount > 0 else { return [] }

        var selectedItems: [ReflexDrillItem] = []
        var selectedIds: Set<String> = []

        // Helper to append unique item
        func tryAddItem(_ item: ReflexDrillItem) -> Bool {
            guard !selectedIds.contains(item.id) else { return false }
            selectedIds.insert(item.id)
            selectedItems.append(item)
            return true
        }

        // Combine pool of all available words deduplicated
        var combinedPool: [ReflexDrillItem] = []
        var poolIds: Set<String> = []
        for item in allLearnedWords + currentTopicWords where !poolIds.contains(item.id) {
            poolIds.insert(item.id)
            combinedPool.append(item)
        }

        guard !combinedPool.isEmpty else { return [] }

        // --- Tier 1: Weak Words (Up to 5 words) ---
        // Condition: needsReview == true OR (mistakeCount > 0 AND !isMastered)
        // Sorted by: mistakeCount DESC, lastReviewDate ASC (older review date or nil first)
        let tier1Candidates = combinedPool.filter { item in
            item.needsReview || (item.mistakeCount > 0 && !item.isMastered)
        }.sorted { (lhs, rhs) -> Bool in
            if lhs.mistakeCount != rhs.mistakeCount {
                return lhs.mistakeCount > rhs.mistakeCount
            }
            let lhsDate = lhs.lastReviewDate ?? Date.distantPast
            let rhsDate = rhs.lastReviewDate ?? Date.distantPast
            return lhsDate < rhsDate
        }

        var tier1Count = 0
        let tier1Limit = min(5, targetCount)
        for item in tier1Candidates {
            if tier1Count >= tier1Limit || selectedItems.count >= targetCount { break }
            if tryAddItem(item) {
                tier1Count += 1
            }
        }

        // --- Tier 2: Current Topic Words (Up to 5 words) ---
        // Condition: from currentTopicWords, !isMastered, not in Tier 1
        // Sorted by: consecutiveCorrectStreak ASC
        let tier2Candidates = currentTopicWords.filter { item in
            !item.isMastered && !selectedIds.contains(item.id)
        }.sorted { (lhs, rhs) -> Bool in
            lhs.consecutiveCorrectStreak < rhs.consecutiveCorrectStreak
        }

        var tier2Count = 0
        let tier2Limit = min(5, targetCount - selectedItems.count)
        for item in tier2Candidates {
            if tier2Count >= tier2Limit || selectedItems.count >= targetCount { break }
            if tryAddItem(item) {
                tier2Count += 1
            }
        }

        // --- Tier 3: SRS Due Words (Up to 5 words) ---
        // Condition: nextReviewDate <= Date.now, !isMastered, not in Tier 1 or Tier 2
        // Sorted by: nextReviewDate ASC (oldest overdue first)
        let now = Date()
        let tier3Candidates = combinedPool.filter { item in
            guard !item.isMastered, !selectedIds.contains(item.id), let nextReview = item.nextReviewDate else {
                return false
            }
            return nextReview <= now
        }.sorted { (lhs, rhs) -> Bool in
            let lhsDate = lhs.nextReviewDate ?? Date.distantPast
            let rhsDate = rhs.nextReviewDate ?? Date.distantPast
            return lhsDate < rhsDate
        }

        var tier3Count = 0
        let tier3Limit = min(5, targetCount - selectedItems.count)
        for item in tier3Candidates {
            if tier3Count >= tier3Limit || selectedItems.count >= targetCount { break }
            if tryAddItem(item) {
                tier3Count += 1
            }
        }

        // --- Tier 4: Random Learned / Starter Deck (Fill up to targetCount) ---
        // Condition: remaining items from combined pool not yet selected
        if selectedItems.count < targetCount {
            let remainingCandidates = combinedPool.filter { !selectedIds.contains($0.id) }
            for item in remainingCandidates {
                if selectedItems.count >= targetCount { break }
                _ = tryAddItem(item)
            }
        }

        // Final step: Shuffle collected items
        return selectedItems.shuffled()
    }
}
