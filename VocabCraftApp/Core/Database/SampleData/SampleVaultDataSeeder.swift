import Foundation

/// Utility that seeds realistic sample user progress data for development, testing, and UI previews.
public enum SampleVaultDataSeeder {
    public struct SampleProgressEntry: Sendable {
        public let wordId: Int64
        public let cefrLevel: String
        public let masteryLevel: Int
        public let isBookmarked: Bool
        public let needsReview: Bool
        public let mistakeCount: Int
        public let streak: Int
        public let modes: Set<ReflexBlitzMode>
        public let isMastered: Bool
        public let sourceDeckId: String
        public let sourceNodeId: String

        public init(
            wordId: Int64,
            cefrLevel: String,
            masteryLevel: Int,
            isBookmarked: Bool,
            needsReview: Bool,
            mistakeCount: Int,
            streak: Int,
            modes: Set<ReflexBlitzMode>,
            isMastered: Bool,
            sourceDeckId: String,
            sourceNodeId: String
        ) {
            self.wordId = wordId
            self.cefrLevel = cefrLevel
            self.masteryLevel = masteryLevel
            self.isBookmarked = isBookmarked
            self.needsReview = needsReview
            self.mistakeCount = mistakeCount
            self.streak = streak
            self.modes = modes
            self.isMastered = isMastered
            self.sourceDeckId = sourceDeckId
            self.sourceNodeId = sourceNodeId
        }
    }

    /// Curated sample entries covering unmastered, mastered, and bookmarked words across 4 domains.
    public static let sampleEntries: [SampleProgressEntry] = [
        // MARK: - Chưa thuộc (Not Mastered - 13 words)
        SampleProgressEntry(
            wordId: 1, cefrLevel: "B2", masteryLevel: 1, isBookmarked: true,
            needsReview: true, mistakeCount: 1, streak: 1, modes: [.multipleChoice],
            isMastered: false, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1"
        ),
        SampleProgressEntry(
            wordId: 2, cefrLevel: "B1", masteryLevel: 0, isBookmarked: false,
            needsReview: true, mistakeCount: 2, streak: 0, modes: [],
            isMastered: false, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1"
        ),
        SampleProgressEntry(
            wordId: 3, cefrLevel: "B2", masteryLevel: 2, isBookmarked: false,
            needsReview: false, mistakeCount: 0, streak: 2, modes: [.typing],
            isMastered: false, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1"
        ),
        SampleProgressEntry(
            wordId: 5, cefrLevel: "B2", masteryLevel: 1, isBookmarked: true,
            needsReview: true, mistakeCount: 3, streak: 1, modes: [.speaking],
            isMastered: false, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1"
        ),
        SampleProgressEntry(
            wordId: 9, cefrLevel: "B1", masteryLevel: 0, isBookmarked: false,
            needsReview: true, mistakeCount: 1, streak: 0, modes: [],
            isMastered: false, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_2"
        ),
        SampleProgressEntry(
            wordId: 11, cefrLevel: "B1", masteryLevel: 2, isBookmarked: false,
            needsReview: false, mistakeCount: 1, streak: 2, modes: [.listening],
            isMastered: false, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_2"
        ),
        SampleProgressEntry(
            wordId: 14, cefrLevel: "B1", masteryLevel: 1, isBookmarked: true,
            needsReview: true, mistakeCount: 0, streak: 1, modes: [.multipleChoice],
            isMastered: false, sourceDeckId: "deck_business", sourceNodeId: "stage_biz_1"
        ),
        SampleProgressEntry(
            wordId: 18, cefrLevel: "B2", masteryLevel: 0, isBookmarked: false,
            needsReview: true, mistakeCount: 2, streak: 0, modes: [],
            isMastered: false, sourceDeckId: "deck_business", sourceNodeId: "stage_biz_1"
        ),
        SampleProgressEntry(
            wordId: 26, cefrLevel: "B2", masteryLevel: 2, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 2, modes: [.typing],
            isMastered: false, sourceDeckId: "deck_tech", sourceNodeId: "stage_tech_1"
        ),
        SampleProgressEntry(
            wordId: 30, cefrLevel: "B2", masteryLevel: 1, isBookmarked: false,
            needsReview: true, mistakeCount: 1, streak: 1, modes: [.listening],
            isMastered: false, sourceDeckId: "deck_tech", sourceNodeId: "stage_tech_1"
        ),
        SampleProgressEntry(
            wordId: 32, cefrLevel: "C1", masteryLevel: 0, isBookmarked: false,
            needsReview: true, mistakeCount: 1, streak: 0, modes: [],
            isMastered: false, sourceDeckId: "deck_tech", sourceNodeId: "stage_tech_2"
        ),
        SampleProgressEntry(
            wordId: 38, cefrLevel: "B2", masteryLevel: 1, isBookmarked: true,
            needsReview: true, mistakeCount: 2, streak: 1, modes: [.multipleChoice],
            isMastered: false, sourceDeckId: "deck_academic", sourceNodeId: "stage_acad_1"
        ),
        SampleProgressEntry(
            wordId: 47, cefrLevel: "C1", masteryLevel: 0, isBookmarked: false,
            needsReview: true, mistakeCount: 1, streak: 0, modes: [],
            isMastered: false, sourceDeckId: "deck_academic", sourceNodeId: "stage_acad_2"
        ),

        // MARK: - Đã thuộc (Mastered - 13 words)
        SampleProgressEntry(
            wordId: 4, cefrLevel: "B1", masteryLevel: 5, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 4, modes: [.multipleChoice, .speaking, .typing],
            isMastered: true, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1"
        ),
        SampleProgressEntry(
            wordId: 6, cefrLevel: "B2", masteryLevel: 4, isBookmarked: false,
            needsReview: false, mistakeCount: 0, streak: 3, modes: [.speaking, .listening],
            isMastered: true, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1"
        ),
        SampleProgressEntry(
            wordId: 7, cefrLevel: "A2", masteryLevel: 5, isBookmarked: false,
            needsReview: false, mistakeCount: 0, streak: 5, modes: [.multipleChoice, .typing],
            isMastered: true, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_1"
        ),
        SampleProgressEntry(
            wordId: 8, cefrLevel: "B1", masteryLevel: 4, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 3, modes: [.listening, .speaking],
            isMastered: true, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_2"
        ),
        SampleProgressEntry(
            wordId: 10, cefrLevel: "B2", masteryLevel: 5, isBookmarked: false,
            needsReview: false, mistakeCount: 0, streak: 4, modes: [.multipleChoice, .speaking],
            isMastered: true, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_2"
        ),
        SampleProgressEntry(
            wordId: 12, cefrLevel: "B1", masteryLevel: 5, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 5, modes: [.multipleChoice, .typing, .listening],
            isMastered: true, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_2"
        ),
        SampleProgressEntry(
            wordId: 13, cefrLevel: "B2", masteryLevel: 4, isBookmarked: false,
            needsReview: false, mistakeCount: 0, streak: 3, modes: [.speaking, .typing],
            isMastered: true, sourceDeckId: "deck_daily", sourceNodeId: "stage_daily_2"
        ),
        SampleProgressEntry(
            wordId: 15, cefrLevel: "A2", masteryLevel: 5, isBookmarked: false,
            needsReview: false, mistakeCount: 0, streak: 5, modes: [.multipleChoice, .listening],
            isMastered: true, sourceDeckId: "deck_business", sourceNodeId: "stage_biz_1"
        ),
        SampleProgressEntry(
            wordId: 16, cefrLevel: "B2", masteryLevel: 5, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 4, modes: [.speaking, .typing],
            isMastered: true, sourceDeckId: "deck_business", sourceNodeId: "stage_biz_1"
        ),
        SampleProgressEntry(
            wordId: 17, cefrLevel: "B2", masteryLevel: 4, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 3, modes: [.multipleChoice, .speaking],
            isMastered: true, sourceDeckId: "deck_business", sourceNodeId: "stage_biz_1"
        ),
        SampleProgressEntry(
            wordId: 27, cefrLevel: "B1", masteryLevel: 5, isBookmarked: false,
            needsReview: false, mistakeCount: 0, streak: 4, modes: [.typing, .listening],
            isMastered: true, sourceDeckId: "deck_tech", sourceNodeId: "stage_tech_1"
        ),
        SampleProgressEntry(
            wordId: 39, cefrLevel: "B2", masteryLevel: 4, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 3, modes: [.speaking, .listening],
            isMastered: true, sourceDeckId: "deck_academic", sourceNodeId: "stage_acad_1"
        ),
        SampleProgressEntry(
            wordId: 46, cefrLevel: "C1", masteryLevel: 5, isBookmarked: true,
            needsReview: false, mistakeCount: 0, streak: 4, modes: [.multipleChoice, .typing],
            isMastered: true, sourceDeckId: "deck_academic", sourceNodeId: "stage_acad_2"
        )
    ]

    /// Seeds sample entries into the given repository.
    public static func seed(repository: any UserProgressRepositoryProtocol) async {
        for entry in sampleEntries {
            try? await repository.saveProgress(
                wordId: entry.wordId,
                cefrLevel: entry.cefrLevel,
                masteryLevel: entry.masteryLevel,
                isBookmarked: entry.isBookmarked,
                needsReview: entry.needsReview,
                mistakeCount: entry.mistakeCount,
                sourceDeckId: entry.sourceDeckId,
                sourceNodeId: entry.sourceNodeId
            )
            try? await repository.recordDrillResult(
                wordId: entry.wordId,
                isCorrect: entry.streak > 0,
                newStreak: entry.streak,
                newModes: entry.modes,
                isMastered: entry.isMastered
            )
        }
    }

    /// Seeds sample data only if the repository currently has no recorded progress.
    public static func seedIfEmpty(repository: any UserProgressRepositoryProtocol) async {
        let existing = try? await repository.fetchAllProgress()
        if existing == nil || existing?.isEmpty == true {
            await seed(repository: repository)
        }
    }
}
