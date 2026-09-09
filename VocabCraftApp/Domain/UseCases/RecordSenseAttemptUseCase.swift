import Foundation

public protocol RecordSenseAttemptUseCaseProtocol: Sendable {
    func execute(attempt: AttemptSubmission) async throws -> AppendResult
}

public final class RecordSenseAttemptUseCase: RecordSenseAttemptUseCaseProtocol, Sendable {
    private let journal: LearningJournal
    private let profileID: ProfileID

    public init(journal: LearningJournal, profileID: ProfileID) {
        self.journal = journal
        self.profileID = profileID
    }

    public func execute(attempt: AttemptSubmission) async throws -> AppendResult {
        try await journal.append(attempt, profileID: profileID)
    }
}
