import Foundation

@MainActor
public protocol ResetUserProgressUseCaseProtocol: AnyObject, Sendable {
    func executeResetAllProgress() async throws
}

@MainActor
public final class ResetUserProgressUseCase: ResetUserProgressUseCaseProtocol {
    private let srsRepository: SRSRepositoryProtocol
    private let practiceRepository: (any PracticeRepositoryProtocol)?

    public init(
        srsRepository: SRSRepositoryProtocol,
        practiceRepository: (any PracticeRepositoryProtocol)? = nil
    ) {
        self.srsRepository = srsRepository
        self.practiceRepository = practiceRepository
    }

    public func executeResetAllProgress() async throws {
        if let practiceRepository {
            try await practiceRepository.resetAllLearningProgress()
        } else {
            try await srsRepository.resetAllProgress()
        }
    }
}
