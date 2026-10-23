import Foundation
import Observation

/// Orchestrates state management, session resumption, and mission recommendation
/// for the AI Guided Communication Practice Hub.
@Observable @MainActor
public final class PracticeHubViewModel {
    /// Comprehensive state representing the user-facing status of the practice hub.
    public enum State: Equatable, Sendable {
        case loading
        case recommended(PracticeMission)
        case resumable(UUID)
        case needsVocabulary
        case noCompatibleTemplate
        case error(PracticeFailure)
    }

    public private(set) var state: State = .loading

    /// Visible target vocabulary snapshots.
    /// In the hub, target words are intentionally concealed to avoid pre-exposure priming.
    public var shownTargetWords: [PracticeWordSnapshot] {
        []
    }

    public let contextReader: PracticeLearningContextReader
    public let repository: any PracticeRepositoryProtocol
    public let selector: SelectPracticeMissionUseCase
    public let clock: any PracticeClock
    public let templates: [PracticeTemplate]

    public init(
        contextReader: PracticeLearningContextReader,
        repository: any PracticeRepositoryProtocol,
        selector: SelectPracticeMissionUseCase = SelectPracticeMissionUseCase(),
        clock: any PracticeClock = SystemPracticeClock(),
        templates: [PracticeTemplate] = PracticeTemplateCatalog.curatedTemplates
    ) {
        self.contextReader = contextReader
        self.repository = repository
        self.selector = selector
        self.clock = clock
        self.templates = templates
    }

    /// Loads active sessions or evaluates pedagogical context to recommend a new mission.
    ///
    /// Execution order:
    /// 1. Resumable in-progress session takes highest precedence.
    /// 2. If no active session, reads aggregated learning context.
    /// 3. Ensures minimum learned vocabulary threshold (>= 2 learned words).
    /// 4. Executes deterministic mission selection against curated templates.
    /// 5. On failure, preserves domain error integrity without fabricating demo data.
    public func load() async {
        state = .loading

        do {
            // 1. Resumable active session always wins over recommending a new mission
            if let active = try await repository.activeSession() {
                state = .resumable(active.session.id)
                return
            }

            // 2. Load learner context
            let context = try await contextReader.load()

            // 3. Insufficient learned words check (< 2)
            guard context.words.count >= 2 else {
                state = .needsVocabulary
                return
            }

            // 4. Run selector
            let result = selector.select(context: context, templates: templates, now: clock.now)
            switch result {
            case .mission(let mission):
                state = .recommended(mission)
            case .needsVocabulary:
                state = .needsVocabulary
            case .noCompatibleTemplate:
                state = .noCompatibleTemplate
            }
        } catch let failure as PracticeFailure {
            state = .error(failure)
        } catch {
            state = .error(
                PracticeFailure(
                    code: .storage,
                    message: error.localizedDescription,
                    underlyingError: error.localizedDescription
                )
            )
        }
    }
}
