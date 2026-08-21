import Foundation

/// Protocol for toggling the bookmark state of a vocabulary word.
public protocol ToggleWordBookmarkUseCaseProtocol: Sendable {
    @discardableResult
    func execute(wordId: Int64) async throws -> Bool
}

/// Toggles the bookmark status of a personal word in the user's progress store.
public final class ToggleWordBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol, Sendable {
    private let progressRepo: any UserProgressRepositoryProtocol

    public init(progressRepo: any UserProgressRepositoryProtocol) {
        self.progressRepo = progressRepo
    }

    @discardableResult
    public func execute(wordId: Int64) async throws -> Bool {
        try await progressRepo.toggleBookmark(wordId: wordId)
    }
}
