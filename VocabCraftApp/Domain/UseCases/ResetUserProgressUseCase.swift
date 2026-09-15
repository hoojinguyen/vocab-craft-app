import Foundation

@MainActor
public protocol ResetUserProgressUseCaseProtocol: AnyObject, Sendable {
    func executeResetAllProgress() async throws
}

@MainActor
public final class ResetUserProgressUseCase: ResetUserProgressUseCaseProtocol {
    private let srsRepository: SRSRepositoryProtocol

    public init(srsRepository: SRSRepositoryProtocol) {
        self.srsRepository = srsRepository
    }

    public func executeResetAllProgress() async throws {
        try await srsRepository.resetAllProgress()
    }
}
