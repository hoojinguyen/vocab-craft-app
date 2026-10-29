import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking hub view model")
@MainActor
struct SpeakingHubViewModelTests {
    @Test func progressAveragesLatestFiveAnalyzedSessions() async {
        let scores = [1, 2, 3, 4, 5, 1]
        let sessions = scores.enumerated().map { index, score in
            snapshot(score: score, status: .analyzed, startedAt: Date(timeIntervalSince1970: Double(index + 1)))
        } + [snapshot(score: 5, status: .analysisFailed, startedAt: Date(timeIntervalSince1970: 7))]
        let model = makeViewModel(sessions: sessions)

        await model.load()

        #expect(model.progress == SpeakingProgressSummary(fluency: 3, grammar: 3, vocabulary: 3, pronunciation: 3, sessionCount: 5))
    }

    @Test func progressIncludesAnalyzedSessionsOlderThanLatestTwentySessions() async {
        let analyzedSessions = [1, 2, 3, 4, 5].enumerated().map { index, score in
            snapshot(score: score, status: .analyzed, startedAt: Date(timeIntervalSince1970: Double(index + 1)))
        }
        let newerSessions = (6...27).map { timestamp in
            snapshot(score: 5, status: .analysisFailed, startedAt: Date(timeIntervalSince1970: Double(timestamp)))
        }
        let model = makeViewModel(sessions: analyzedSessions + newerSessions)

        await model.load()

        #expect(model.progress == SpeakingProgressSummary(fluency: 3, grammar: 3, vocabulary: 3, pronunciation: 3, sessionCount: 5))
        #expect(model.history.count == 20)
        #expect(model.history.first?.startedAt == Date(timeIntervalSince1970: 27))
    }

    @Test func makePlanIncludesWordsOnlyWhenToggled() async {
        let words = [SpeakingTargetWord(wordId: 1, lemma: "market", definitionVi: "chợ")]
        let model = makeViewModel(words: words)

        let withoutWords = await model.makePlan(blueprintId: "cafe_order", level: .a2, includeWords: false)
        let withWords = await model.makePlan(blueprintId: "cafe_order", level: .a2, includeWords: true)

        #expect(withoutWords?.targetWords.isEmpty == true)
        #expect(withWords?.targetWords == words)
    }

    @Test func makePlanWithToggleButNoLearnedWordsReturnsEmptyWords() async {
        let model = makeViewModel()

        let plan = await model.makePlan(blueprintId: "cafe_order", level: .b1, includeWords: true)

        #expect(plan?.targetWords.isEmpty == true)
    }

    private func makeViewModel(sessions: [SpeakingSessionSnapshot] = [], words: [SpeakingTargetWord] = []) -> SpeakingHubViewModel {
        let settings = UserSettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        let precheck = SpeakingPrecheck(settings: settings, microphone: { true }, isOnline: { true })
        return SpeakingHubViewModel(
            repository: HubRepository(sessions: sessions),
            wordPicker: HubWordPicker(words: words),
            precheck: precheck
        )
    }

    private func snapshot(score: Int, status: SpeakingSessionStatus, startedAt: Date) -> SpeakingSessionSnapshot {
        let scoreValue = SpeakingAnalysis.Score(value: score, reason: "")
        let analysis = SpeakingAnalysis(
            learnerTranscript: [],
            scores: .init(fluency: scoreValue, grammar: scoreValue, vocabulary: scoreValue, pronunciation: scoreValue),
            corrections: [], naturalPhrasings: [], pronunciation: [], targetWords: [], objective: nil,
            summary: .init(strengths: [], focusNext: [])
        )
        let blueprint = SpeakingBlueprint(
            id: "cafe_order", kind: .scenario, titleKey: "", briefKey: "", aiRole: "", setting: "", objective: nil
        )
        return SpeakingSessionSnapshot(
            id: UUID(), plan: SpeakingSessionPlan(blueprint: blueprint, level: .a2, targetWords: []),
            startedAt: startedAt, duration: 10, status: status, endReason: .learnerEnded,
            hintCount: 0, audioFileName: nil, turns: [], analysis: status == .analyzed ? analysis : nil
        )
    }
}

private struct HubWordPicker: SpeakingWordPicking {
    let words: [SpeakingTargetWord]
    func pick(limit: Int) async throws -> [SpeakingTargetWord] { Array(words.prefix(limit)) }
}

private actor HubRepository: SpeakingRepositoryProtocol {
    private let values: [SpeakingSessionSnapshot]
    init(sessions: [SpeakingSessionSnapshot]) { values = sessions }
    func save(_ session: SpeakingSessionSnapshot) async throws {}
    func session(id: UUID) async throws -> SpeakingSessionSnapshot? { values.first { $0.id == id } }
    func sessions(limit: Int?) async throws -> [SpeakingSessionSnapshot] {
        let sorted = values.sorted { $0.startedAt > $1.startedAt }
        return limit.map { Array(sorted.prefix($0)) } ?? sorted
    }
    func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) async throws {}
    func savePhrase(_ phrase: SavedPhrase) async throws -> Bool { true }
    func phrases() async throws -> [SavedPhrase] { [] }
    func deletePhrase(id: UUID) async throws {}
    func detachAudio(keepingLatest count: Int) async throws -> [String] { [] }
}
