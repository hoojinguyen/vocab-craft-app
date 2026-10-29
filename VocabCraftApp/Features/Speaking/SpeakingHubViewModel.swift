import Foundation
import Observation

protocol SpeakingWordPicking: Sendable {
    func pick(limit: Int) async throws -> [SpeakingTargetWord]
}

extension SpeakingWordPicker: SpeakingWordPicking {}

struct SpeakingProgressSummary: Equatable {
    let fluency: Double
    let grammar: Double
    let vocabulary: Double
    let pronunciation: Double
    let sessionCount: Int
}

@MainActor
@Observable
public final class SpeakingHubViewModel {
    private let repository: any SpeakingRepositoryProtocol
    private let wordPicker: any SpeakingWordPicking
    private let precheck: SpeakingPrecheck

    private(set) var scenarios: [SpeakingBlueprint] = []
    private(set) var topics: [SpeakingBlueprint] = []
    private(set) var history: [SpeakingSessionSnapshot] = []
    private(set) var progress: SpeakingProgressSummary?

    init(repository: any SpeakingRepositoryProtocol, wordPicker: any SpeakingWordPicking, precheck: SpeakingPrecheck) {
        self.repository = repository
        self.wordPicker = wordPicker
        self.precheck = precheck
    }

    func load() async {
        scenarios = SpeakingBlueprintCatalog.all.filter { $0.kind == .scenario }
        topics = SpeakingBlueprintCatalog.all.filter { $0.kind == .topic }
        do {
            let sessions = try await repository.sessions(limit: nil).sorted { $0.startedAt > $1.startedAt }
            history = Array(sessions.prefix(20))
            let analyzed = sessions.filter { $0.status == .analyzed && $0.analysis != nil }.prefix(5)
            guard !analyzed.isEmpty else {
                progress = nil
                return
            }
            let scores = analyzed.compactMap(\.analysis?.scores)
            guard !scores.isEmpty else {
                progress = nil
                return
            }
            let count = Double(scores.count)
            progress = SpeakingProgressSummary(
                fluency: Double(scores.reduce(0) { $0 + $1.fluency.value }) / count,
                grammar: Double(scores.reduce(0) { $0 + $1.grammar.value }) / count,
                vocabulary: Double(scores.reduce(0) { $0 + $1.vocabulary.value }) / count,
                pronunciation: Double(scores.reduce(0) { $0 + $1.pronunciation.value }) / count,
                sessionCount: scores.count
            )
        } catch {
            history = []
            progress = nil
        }
    }

    func makePlan(blueprintId: String, level: SpeakingLevel, includeWords: Bool) async -> SpeakingSessionPlan? {
        guard let blueprint = SpeakingBlueprintCatalog.blueprint(id: blueprintId) else { return nil }
        let words: [SpeakingTargetWord]
        if includeWords {
            do {
                words = try await wordPicker.pick(limit: 3)
            } catch {
                return nil
            }
        } else {
            words = []
        }
        return SpeakingSessionPlan(blueprint: blueprint, level: level, targetWords: words)
    }

    func runPrecheck() async -> [SpeakingPrecheck.Issue] {
        await precheck.run()
    }
}
