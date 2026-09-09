import Foundation

/// Protocol for toggling the bookmark state of a vocabulary word or sense.
public protocol ToggleWordBookmarkUseCaseProtocol: Sendable {
    @discardableResult
    func execute(wordId: Int64) async throws -> Bool

    @discardableResult
    func execute(senseID: SenseID) async throws -> Bool
}

public extension ToggleWordBookmarkUseCaseProtocol {
    @discardableResult
    func execute(senseID: SenseID) async throws -> Bool {
        false
    }
}

/// Toggles the bookmark status of a word in UserProgress or a sense in LearningJournal.
public final class ToggleWordBookmarkUseCase: ToggleWordBookmarkUseCaseProtocol, Sendable {
    private let progressRepo: (any UserProgressRepositoryProtocol)?
    private let journal: LearningJournal?
    private let profileID: ProfileID?

    public init(progressRepo: any UserProgressRepositoryProtocol) {
        self.progressRepo = progressRepo
        self.journal = nil
        self.profileID = nil
    }

    public init(
        progressRepo: (any UserProgressRepositoryProtocol)? = nil,
        journal: LearningJournal? = nil,
        profileID: ProfileID? = nil
    ) {
        self.progressRepo = progressRepo
        self.journal = journal
        self.profileID = profileID
    }

    @discardableResult
    public func execute(wordId: Int64) async throws -> Bool {
        guard let progressRepo else { return false }
        return try await progressRepo.toggleBookmark(wordId: wordId)
    }

    @discardableResult
    public func execute(senseID: SenseID) async throws -> Bool {
        guard let journal else { return false }
        let pid: ProfileID
        if let profileID {
            pid = try await journal.ensureDefaultGuestProfile(id: profileID)
        } else {
            pid = try await journal.createGuestProfile()
        }
        return try await journal.toggleBookmark(profileID: pid, senseID: senseID)
    }
}
