import Foundation
import Testing
@testable import VocabCraftApp

// MARK: - Test Mocks

final class TestVocabularyDataSource: VocabularyDataSourceProtocol, @unchecked Sendable {
    var words: [Int64: TopicWordDTO] = [:]
    var shouldThrowError: Error?

    init(words: [TopicWordDTO] = []) {
        for word in words {
            self.words[word.id] = word
        }
    }

    func fetchTopicDecks() async throws -> [TopicDeckDTO] { [] }
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] { [] }
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] { [] }
    func searchWords(query: String) async throws -> [TopicWordDTO] { [] }

    func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        if let error = shouldThrowError { throw error }
        return words[id]
    }

    func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        if let error = shouldThrowError { throw error }
        return ids.compactMap { words[$0] }
    }

    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] {
        if let error = shouldThrowError { throw error }
        return words
    }
}

final class TestUserProgressRepository: UserProgressRepositoryProtocol, @unchecked Sendable {
    var storedProgress: [UserWordProgressData] = []
    var shouldThrowError: Error?

    init(progress: [UserWordProgressData] = []) {
        self.storedProgress = progress
    }

    func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) async throws {}
    func toggleBookmark(wordId: Int64) async throws -> Bool { false }
    func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws {}
    func clearNeedsReview(wordId: Int64) async throws {}

    func fetchAllProgress() async throws -> [UserWordProgressData] {
        if let error = shouldThrowError { throw error }
        return storedProgress
    }

    func getProgress(wordId: Int64) async throws -> UserWordProgressData? {
        if let error = shouldThrowError { throw error }
        return storedProgress.first { $0.wordId == wordId }
    }

    func recordDrillResult(
        wordId: Int64,
        isCorrect: Bool,
        newStreak: Int,
        newModes: Set<ReflexBlitzMode>,
        isMastered: Bool,
        modeStats: ModeSuccessStats?
    ) async throws {}

    // swiftlint:disable:next function_parameter_count
    func saveProgress(
        wordId: Int64,
        cefrLevel: String,
        masteryLevel: Int,
        isBookmarked: Bool,
        needsReview: Bool,
        mistakeCount: Int,
        sourceDeckId: String?,
        sourceNodeId: String?
    ) async throws {}
}

final class TestPracticeRepository: PracticeRepositoryProtocol, @unchecked Sendable {
    var storedProgress: [CommunicationProgress] = []
    var storedEvidence: [WordUseEvidence] = []
    var storedActiveSession: PracticeSessionSnapshot?
    var shouldThrowError: Error?

    init(
        progress: [CommunicationProgress] = [],
        evidence: [WordUseEvidence] = [],
        activeSession: PracticeSessionSnapshot? = nil
    ) {
        self.storedProgress = progress
        self.storedEvidence = evidence
        self.storedActiveSession = activeSession
    }

    func progress() async throws -> [CommunicationProgress] {
        if let error = shouldThrowError { throw error }
        return storedProgress
    }

    func evidence() async throws -> [WordUseEvidence] {
        if let error = shouldThrowError { throw error }
        return storedEvidence
    }

    func activeSession() async throws -> PracticeSessionSnapshot? {
        if let error = shouldThrowError { throw error }
        return storedActiveSession
    }

    func loadSession(id: UUID) async throws -> PracticeSessionSnapshot? {
        if let error = shouldThrowError { throw error }
        return storedActiveSession?.session.id == id ? storedActiveSession : nil
    }
}

// MARK: - Test Suite

@Suite("Select Practice Mission Tests")
struct SelectPracticeMissionTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let catalog = PracticeTemplateCatalog.templates
    private let selector = SelectPracticeMissionUseCase()

    private func makeDTO(id: Int64, lemma: String) -> TopicWordDTO {
        TopicWordDTO(
            id: id,
            stageId: "stage_daily_1",
            lemma: lemma,
            phonetic: "/\(lemma)/",
            pos: "noun",
            cefrLevel: "A2",
            definitionVi: "Nghĩa tiếng Việt của \(lemma)",
            definitionEn: "English definition of \(lemma)",
            exampleEn: "Example sentence with \(lemma).",
            exampleVi: "Câu ví dụ với \(lemma)."
        )
    }

    private func makeProgress(
        wordId: Int64,
        totalReviews: Int = 1,
        masteryLevel: Int = 1,
        isBookmarked: Bool = false,
        nextReviewDate: Date = Date(timeIntervalSince1970: 1_700_000_000),
        lastReviewDate: Date = Date(timeIntervalSince1970: 1_699_000_000)
    ) -> UserWordProgressData {
        UserWordProgressData(
            wordId: wordId,
            cefrLevel: "A2",
            masteryLevel: masteryLevel,
            isBookmarked: isBookmarked,
            nextReviewDate: nextReviewDate,
            lastReviewDate: lastReviewDate,
            totalReviews: totalReviews
        )
    }

    private func makeSnapshot(wordId: Int64, lemma: String) -> PracticeWordSnapshot {
        PracticeWordSnapshot(
            wordId: wordId,
            lemma: lemma,
            definitionEn: "Definition of \(lemma)",
            definitionVi: "Nghia cua \(lemma)"
        )
    }

    // MARK: - Core Requirement Tests

    @Test("Bookmark-only does not become learned word and returns needsVocabulary")
    func bookmarkOnlyDoesNotBecomeLearnedWord() {
        // Arrange
        let bookmarkOnlyProgress = [
            makeProgress(wordId: 4, totalReviews: 0, masteryLevel: 0, isBookmarked: true),
            makeProgress(wordId: 11, totalReviews: 0, masteryLevel: 0, isBookmarked: true)
        ]
        let snapshots = [
            makeSnapshot(wordId: 4, lemma: "Gratitude"),
            makeSnapshot(wordId: 11, lemma: "Hesitate")
        ]
        let bookmarkOnly = PracticeLearningContext(
            words: snapshots,
            progress: bookmarkOnlyProgress,
            communication: [],
            evidence: []
        )

        // Act & Assert standard requirement:
        #expect(selector.select(context: bookmarkOnly, templates: catalog, now: now) == .needsVocabulary)

        // Assert when valid learned words exist, selected mission has <= 3 target words
        let learnedProgress = [
            makeProgress(wordId: 4, totalReviews: 2, masteryLevel: 1, isBookmarked: false),
            makeProgress(wordId: 11, totalReviews: 1, masteryLevel: 1, isBookmarked: false),
            makeProgress(wordId: 13, totalReviews: 3, masteryLevel: 2, isBookmarked: false)
        ]
        let learnedSnapshots = [
            makeSnapshot(wordId: 4, lemma: "Gratitude"),
            makeSnapshot(wordId: 11, lemma: "Hesitate"),
            makeSnapshot(wordId: 13, lemma: "Genuine")
        ]
        let learnedContext = PracticeLearningContext(
            words: learnedSnapshots,
            progress: learnedProgress,
            communication: [],
            evidence: []
        )

        let result = selector.select(context: learnedContext, templates: catalog, now: now)
        guard case .mission(let selectedMission) = result else {
            Issue.record("Expected mission, got \(result)")
            return
        }

        #expect(selectedMission.targetWordIds.count <= 3)
        #expect(!selectedMission.targetWordIds.isEmpty)
    }

    @Test("Prioritizes assisted-due over communication-due and noEvidence")
    func priorityOrderingAssistedDueFirst() {
        // Word 4 (Gratitude): assisted-due (practicing, nextPracticeAt <= now)
        // Word 11 (Hesitate): communication-due (independentFamiliar, nextPracticeAt <= now)
        // Word 13 (Genuine): no communication evidence
        let commProgress: [CommunicationProgress] = [
            CommunicationProgress(
                wordId: 4,
                inputMode: .voice,
                stage: .practicing,
                nextPracticeAt: now.addingTimeInterval(-3600)
            ),
            CommunicationProgress(
                wordId: 11,
                inputMode: .voice,
                stage: .independentFamiliar,
                nextPracticeAt: now.addingTimeInterval(-3600)
            )
        ]

        let progress = [
            makeProgress(wordId: 4, totalReviews: 3),
            makeProgress(wordId: 11, totalReviews: 3),
            makeProgress(wordId: 13, totalReviews: 3)
        ]
        let snapshots = [
            makeSnapshot(wordId: 4, lemma: "Gratitude"),
            makeSnapshot(wordId: 11, lemma: "Hesitate"),
            makeSnapshot(wordId: 13, lemma: "Genuine")
        ]
        let context = PracticeLearningContext(
            words: snapshots,
            progress: progress,
            communication: commProgress,
            evidence: []
        )

        let result = selector.select(context: context, templates: catalog, now: now)
        guard case .mission(let mission) = result else {
            Issue.record("Expected mission, got \(result)")
            return
        }

        // Assisted-due word 4 must be the primary target word
        #expect(mission.targetWordIds.first == 4)
        #expect(mission.selectionReasons.contains(.retryAssisted))
    }

    @Test("Prioritizes communication-due over noEvidence when no assisted-due words")
    func priorityOrderingCommunicationDueOverNoEvidence() {
        // Word 11 (Hesitate): communication-due
        // Word 13 (Genuine): noEvidence
        let commProgress: [CommunicationProgress] = [
            CommunicationProgress(
                wordId: 11,
                inputMode: .voice,
                stage: .independentFamiliar,
                nextPracticeAt: now.addingTimeInterval(-100)
            )
        ]
        let progress = [
            makeProgress(wordId: 11, totalReviews: 2),
            makeProgress(wordId: 13, totalReviews: 2)
        ]
        let snapshots = [
            makeSnapshot(wordId: 11, lemma: "Hesitate"),
            makeSnapshot(wordId: 13, lemma: "Genuine")
        ]
        let context = PracticeLearningContext(
            words: snapshots,
            progress: progress,
            communication: commProgress,
            evidence: []
        )

        let result = selector.select(context: context, templates: catalog, now: now)
        guard case .mission(let mission) = result else {
            Issue.record("Expected mission, got \(result)")
            return
        }

        #expect(mission.targetWordIds.first == 11)
        #expect(mission.selectionReasons.contains(.communicationDue))
    }

    @Test("Tie-breaks within same priority tier by SRS nextReviewDate ascending, then wordId")
    func tieBreakingByNextReviewDateThenWordId() {
        // Both words have no communication evidence (same tier)
        // Word 11 has earlier nextReviewDate than Word 4
        let earlierDate = now.addingTimeInterval(-7200)
        let laterDate = now.addingTimeInterval(-3600)

        let progress = [
            makeProgress(wordId: 4, totalReviews: 2, nextReviewDate: laterDate),
            makeProgress(wordId: 11, totalReviews: 2, nextReviewDate: earlierDate)
        ]
        let snapshots = [
            makeSnapshot(wordId: 4, lemma: "Gratitude"),
            makeSnapshot(wordId: 11, lemma: "Hesitate")
        ]
        let context = PracticeLearningContext(
            words: snapshots,
            progress: progress,
            communication: [],
            evidence: []
        )

        let result = selector.select(context: context, templates: catalog, now: now)
        guard case .mission(let mission) = result else {
            Issue.record("Expected mission, got \(result)")
            return
        }

        // Word 11 has earlier nextReviewDate so it must be selected first
        #expect(mission.targetWordIds.first == 11)

        // When dates are equal, lower wordId tie-breaks
        let equalDateProgress = [
            makeProgress(wordId: 13, totalReviews: 2, nextReviewDate: earlierDate),
            makeProgress(wordId: 4, totalReviews: 2, nextReviewDate: earlierDate)
        ]
        let equalDateSnapshots = [
            makeSnapshot(wordId: 13, lemma: "Genuine"),
            makeSnapshot(wordId: 4, lemma: "Gratitude")
        ]
        let equalDateContext = PracticeLearningContext(
            words: equalDateSnapshots,
            progress: equalDateProgress,
            communication: [],
            evidence: []
        )

        let result2 = selector.select(context: equalDateContext, templates: catalog, now: now)
        guard case .mission(let mission2) = result2 else {
            Issue.record("Expected mission, got \(result2)")
            return
        }
        #expect(mission2.targetWordIds.first == 4) // 4 < 13
    }

    @Test("Transfer candidate prioritizes template in novel context family")
    func transferSelectsNovelContextFamily() {
        // Word 8 (Compromise) is supported in .dining (transfer), .shopping (basic), and .planning (transfer)
        // Learner has independentFamiliar stage on Word 8 with previous evidence in .dining
        let diningEvidence = WordUseEvidence(
            id: UUID(),
            sessionId: UUID(),
            turnId: UUID(),
            wordId: 8,
            objectiveId: "resolve_order_issue",
            usageVerdict: .appropriate,
            intentVerdict: .achieved,
            transcriptReliability: .usable,
            contextFamily: .dining,
            inputMode: .voice,
            timestamp: now.addingTimeInterval(-86400 * 2)
        )

        let commProgress = [
            CommunicationProgress(
                wordId: 8,
                inputMode: .voice,
                stage: .independentFamiliar,
                nextPracticeAt: now.addingTimeInterval(-100)
            )
        ]

        let progress = [makeProgress(wordId: 8, totalReviews: 5)]
        let snapshots = [makeSnapshot(wordId: 8, lemma: "Compromise")]

        let context = PracticeLearningContext(
            words: snapshots,
            progress: progress,
            communication: commProgress,
            evidence: [diningEvidence]
        )

        let result = selector.select(context: context, templates: catalog, now: now)
        guard case .mission(let mission) = result else {
            Issue.record("Expected mission, got \(result)")
            return
        }

        // The chosen contextFamily must NOT be .dining
        #expect(mission.contextFamily != .dining)
        #expect(mission.contextFamily == .shopping || mission.contextFamily == .planning)
    }

    @Test("Returns noCompatibleTemplate when no template supports the candidate words")
    func returnsNoCompatibleTemplateWhenNoMatch() {
        // Word 999 is a learned word, but no template supports word 999
        let progress = [makeProgress(wordId: 999, totalReviews: 3)]
        let snapshots = [makeSnapshot(wordId: 999, lemma: "UnmatchedWord")]
        let context = PracticeLearningContext(
            words: snapshots,
            progress: progress,
            communication: [],
            evidence: []
        )

        let result = selector.select(context: context, templates: catalog, now: now)
        #expect(result == .noCompatibleTemplate)
    }

    // MARK: - Context Reader Tests

    @Test("PracticeLearningContextReader filters learned words and disqualifies bookmark-only")
    func readerFiltersLearnedWords() async throws {
        let vocab = TestVocabularyDataSource(words: [
            makeDTO(id: 4, lemma: "Gratitude"),
            makeDTO(id: 11, lemma: "Hesitate"),
            makeDTO(id: 99, lemma: "BookmarkOnlyWord")
        ])

        let userProgress = TestUserProgressRepository(progress: [
            makeProgress(wordId: 4, totalReviews: 2, masteryLevel: 0, isBookmarked: false),
            makeProgress(wordId: 11, totalReviews: 0, masteryLevel: 2, isBookmarked: false),
            makeProgress(wordId: 99, totalReviews: 0, masteryLevel: 0, isBookmarked: true)
        ])

        let practiceRepo = TestPracticeRepository()

        let reader = PracticeLearningContextReader(
            vocabularyDataSource: vocab,
            progressRepository: userProgress,
            practiceRepository: practiceRepo
        )

        let context = try await reader.load()

        #expect(context.words.count == 2)
        #expect(context.words.contains { $0.wordId == 4 })
        #expect(context.words.contains { $0.wordId == 11 })
        #expect(!context.words.contains { $0.wordId == 99 }) // Disqualified
    }

    @Test("PracticeLearningContextReader cleanly rethrows repository errors without fake data")
    func readerRethrowsErrorsWithoutFakeData() async {
        struct DummyError: Error, Equatable {}

        let vocab = TestVocabularyDataSource()
        let userProgress = TestUserProgressRepository()
        userProgress.shouldThrowError = DummyError()

        let practiceRepo = TestPracticeRepository()

        let reader = PracticeLearningContextReader(
            vocabularyDataSource: vocab,
            progressRepository: userProgress,
            practiceRepository: practiceRepo
        )

        do {
            _ = try await reader.load()
            Issue.record("Expected error to be thrown, but succeeded.")
        } catch {
            #expect(error is DummyError)
        }
    }
}
