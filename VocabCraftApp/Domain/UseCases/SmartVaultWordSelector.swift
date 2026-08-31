import Foundation

/// Protocol for selecting high-priority vocabulary items from a user's vault for reflex practice.
public protocol SmartVaultWordSelectorProtocol: Sendable {
    func selectWords(from pool: [VaultWordItem], targetCount: Int) -> [VaultWordItem]
}

/// Selects words prioritizing unmastered modes, lower streaks, and longer intervals since last practice.
public final class SmartVaultWordSelector: SmartVaultWordSelectorProtocol, Sendable {
    private let dateProvider: @Sendable () -> Date
    private let jitterProvider: (@Sendable () -> Double)?

    public init(
        dateProvider: @escaping @Sendable () -> Date = { Date() },
        jitterProvider: (@Sendable () -> Double)? = nil
    ) {
        self.dateProvider = dateProvider
        self.jitterProvider = jitterProvider
    }

    public func selectWords(from pool: [VaultWordItem], targetCount: Int) -> [VaultWordItem] {
        guard targetCount > 0, !pool.isEmpty else { return [] }

        let now = dateProvider()

        let scoredWords: [(word: VaultWordItem, score: Double)] = pool.map { word in
            let score = calculatePriorityScore(for: word, now: now)
            return (word, score)
        }

        let sorted = scoredWords.sorted { lhs, rhs in
            lhs.score > rhs.score
        }

        return Array(sorted.prefix(targetCount).map(\.word))
    }

    private func calculatePriorityScore(for word: VaultWordItem, now: Date) -> Double {
        // 1. Mode unmastered weight: (4 - modeCount) * 10
        let completedModeCount = word.modeStats.completedModes.count
        let modeWeight = Double(max(0, 4 - completedModeCount) * 10)

        // 2. Streak weight: max(0, 5 - streak) * 3
        let streakWeight = Double(max(0, 5 - word.correctStreak) * 3)

        // 3. Time weight: min(10, daysSinceLastPractice) * 2
        let daysSinceLastPractice: Double
        if let lastPracticed = word.lastPracticedAt {
            let elapsedSeconds = max(0.0, now.timeIntervalSince(lastPracticed))
            daysSinceLastPractice = min(10.0, elapsedSeconds / 86400.0)
        } else {
            daysSinceLastPractice = 10.0
        }
        let timeWeight = daysSinceLastPractice * 2.0

        // 4. Jitter (small tie-breaker in 0.0..<1.0)
        let jitter = jitterProvider?() ?? Double.random(in: 0.0..<1.0)

        return modeWeight + streakWeight + timeWeight + jitter
    }
}
