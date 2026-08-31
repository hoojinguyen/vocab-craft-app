import CraftUIKit
import Foundation

/// Centralized economy policy for Learning Path rewards & duration estimates.
/// Extracted from `LearningPathDataMapper` hardcoded values to enable A/B testing and balance tuning.
public enum LessonEconomyPolicy: Sendable {
    /// XP reward for a standard lesson node.
    public static let standardXP: Int = 25
    /// XP reward for a checkpoint / boss exam node.
    public static let checkpointXP: Int = 80
    /// XP reward for a treasure chest milestone.
    public static let treasureXP: Int = 150

    public static func xpReward(for kind: LessonNodeKind) -> Int {
        switch kind {
        case .checkpoint: return checkpointXP
        case .treasureChest: return treasureXP
        case .standard: return standardXP
        }
    }

    /// Estimated minutes derived from word count for standard stages.
    /// Formula: `max(1, ceil(words * 0.3))` → ~3 min per 10 words.
    public static func estimatedMinutes(wordCount: Int) -> Int {
        max(1, Int(ceil(Double(wordCount) * 0.3)))
    }

    /// Estimated minutes for checkpoint (deck review).
    /// Formula: `max(3, ceil(deckWordCount * 0.2))`.
    public static func checkpointEstimatedMinutes(deckWordCount: Int) -> Int {
        max(3, Int(ceil(Double(deckWordCount) * 0.2)))
    }
}
