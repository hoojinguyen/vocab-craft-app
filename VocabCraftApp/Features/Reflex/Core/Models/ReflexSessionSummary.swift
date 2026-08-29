import Foundation

/// Performance speed tier classification based on response time and hint usage.
public enum ReflexSpeedTier: String, Sendable, Codable, CaseIterable {
    case flash
    case hinted
    case needsPractice

    public static func from(responseTimeMs: Int, usedHint: Bool) -> ReflexSpeedTier {
        if responseTimeMs < 2500 && !usedHint {
            return .flash
        } else if responseTimeMs < 6000 {
            return .hinted
        } else {
            return .needsPractice
        }
    }
}

/// An individual drill attempt recording accuracy, latency, and hint metadata.
public struct ReflexBlitzAttempt: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let wordId: Int
    public let lemma: String
    public let pos: String
    public let ipa: String
    public let definitionVi: String
    public let responseTimeMs: Int
    public let usedHint: Bool
    public let isCorrect: Bool
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        wordId: Int,
        lemma: String,
        pos: String = "",
        ipa: String = "",
        definitionVi: String = "",
        responseTimeMs: Int,
        usedHint: Bool,
        isCorrect: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.lemma = lemma
        self.pos = pos
        self.ipa = ipa
        self.definitionVi = definitionVi
        self.responseTimeMs = responseTimeMs
        self.usedHint = usedHint
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }

    public var speedTier: ReflexSpeedTier {
        ReflexSpeedTier.from(responseTimeMs: responseTimeMs, usedHint: usedHint)
    }
}

extension ReflexBlitzAttempt: ReflexDrillable {
    public var exampleSentenceEn: String { "" }
    public var exampleSentenceVi: String { "" }
    public var clozeSentenceEn: String { "" }
    public var cefrLevel: String { "" }
    public var audioResourceUrl: String? { nil }
}

public typealias ReflexBlitzWeakWordAttempt = ReflexBlitzAttempt

/// Performance rating for a completed Reflex session.
public enum ReflexPerformanceRating: String, Sendable, Codable, CaseIterable {
    case master
    case swift
    case steady

    public var emoji: String {
        switch self {
        case .master: return "⚡️"
        case .swift:  return "🔥"
        case .steady: return "🌱"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .master: return String(localized: "app.reflex.summary.rating_master")
        case .swift:  return String(localized: "app.reflex.summary.rating_swift")
        case .steady: return String(localized: "app.reflex.summary.rating_steady")
        }
    }

    public var starCount: Int {
        switch self {
        case .master: return 3
        case .swift:  return 2
        case .steady: return 1
        }
    }

    public var iconName: String {
        switch self {
        case .master: return "bolt.shield.fill"
        case .swift:  return "flame.fill"
        case .steady: return "sparkles"
        }
    }

    public var displayTitle: String {
        "\(emoji) \(localizedTitle)"
    }
}

/// Aggregated metrics and summary for a completed Reflex drilling session.
public struct ReflexSessionSummary: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let totalWords: Int
    public let correctWords: Int
    public let averageResponseTimeMs: Int
    public let maxComboStreak: Int
    public let attempts: [ReflexBlitzAttempt]
    public let weakWordAttempts: [ReflexBlitzAttempt]
    public let ratingTier: ReflexPerformanceRating

    public var speedRating: String {
        ratingTier.displayTitle
    }

    public init(
        id: UUID = UUID(),
        totalWords: Int,
        correctWords: Int,
        averageResponseTimeMs: Int,
        maxComboStreak: Int,
        attempts: [ReflexBlitzAttempt],
        weakWordAttempts: [ReflexBlitzAttempt],
        ratingTier: ReflexPerformanceRating
    ) {
        self.id = id
        self.totalWords = totalWords
        self.correctWords = correctWords
        self.averageResponseTimeMs = averageResponseTimeMs
        self.maxComboStreak = maxComboStreak
        self.attempts = attempts
        self.weakWordAttempts = weakWordAttempts
        self.ratingTier = ratingTier
    }

    public init(
        id: UUID = UUID(),
        totalWords: Int,
        correctWords: Int,
        averageResponseTimeMs: Int,
        maxComboStreak: Int,
        attempts: [ReflexBlitzAttempt],
        weakWordAttempts: [ReflexBlitzAttempt],
        speedRating: String
    ) {
        let rating: ReflexPerformanceRating
        if speedRating.contains("Master") {
            rating = .master
        } else if speedRating.contains("Swift") {
            rating = .swift
        } else {
            rating = .steady
        }
        self.init(
            id: id,
            totalWords: totalWords,
            correctWords: correctWords,
            averageResponseTimeMs: averageResponseTimeMs,
            maxComboStreak: maxComboStreak,
            attempts: attempts,
            weakWordAttempts: weakWordAttempts,
            ratingTier: rating
        )
    }

    public static func create(from attempts: [ReflexBlitzAttempt], maxCombo: Int) -> ReflexSessionSummary {
        let total = attempts.count
        let correct = attempts.filter { $0.isCorrect }.count
        let avgTime = total > 0 ? attempts.reduce(0) { $0 + $1.responseTimeMs } / total : 0
        let weak = attempts.filter { !$0.isCorrect || $0.speedTier == .needsPractice }

        let rating: ReflexPerformanceRating
        if total > 0 && avgTime <= 2500 && correct == total {
            rating = .master
        } else if total > 0 && avgTime <= 4000 && Double(correct) / Double(max(1, total)) >= 0.7 {
            rating = .swift
        } else {
            rating = .steady
        }

        return ReflexSessionSummary(
            id: UUID(),
            totalWords: total,
            correctWords: correct,
            averageResponseTimeMs: avgTime,
            maxComboStreak: maxCombo,
            attempts: attempts,
            weakWordAttempts: weak,
            ratingTier: rating
        )
    }
}

public typealias ReflexBlitzSessionSummary = ReflexSessionSummary
