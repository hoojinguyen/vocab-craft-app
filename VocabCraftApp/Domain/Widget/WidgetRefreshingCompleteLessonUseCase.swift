import Foundation

/// Decorates lesson completion so the widget deck is rebuilt afterwards.
/// The refresh is fire-and-forget and never delays or alters the lesson result.
public final class WidgetRefreshingCompleteLessonUseCase: CompleteLessonUseCaseProtocol {
    private let wrapped: CompleteLessonUseCaseProtocol
    private let refresh: RefreshWidgetDeckUseCaseProtocol

    public init(wrapped: CompleteLessonUseCaseProtocol, refresh: RefreshWidgetDeckUseCaseProtocol) {
        self.wrapped = wrapped
        self.refresh = refresh
    }

    // swiftlint:disable:next function_parameter_count
    public func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        practicedWordIds: [Int64],
        weakWordIds: [Int64],
        progressFraction: Double,
        cefrLevel: String?
    ) async throws -> LessonCompletionResult {
        let result = try await wrapped.execute(
            stageId: stageId,
            deckId: deckId,
            stars: stars,
            practicedWordIds: practicedWordIds,
            weakWordIds: weakWordIds,
            progressFraction: progressFraction,
            cefrLevel: cefrLevel
        )
        scheduleRefresh()
        return result
    }

    // swiftlint:disable:next function_parameter_count
    public func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        practicedWordIds: [Int64],
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult {
        let result = try await wrapped.execute(
            stageId: stageId,
            deckId: deckId,
            stars: stars,
            practicedWordIds: practicedWordIds,
            weakWordIds: weakWordIds,
            progressFraction: progressFraction
        )
        scheduleRefresh()
        return result
    }

    private func scheduleRefresh() {
        let refresh = self.refresh
        Task { await refresh.execute() }
    }
}
