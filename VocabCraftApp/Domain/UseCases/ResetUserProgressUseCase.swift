import Foundation

public protocol ResetUserProgressUseCaseProtocol: AnyObject {
    func executeResetAllProgress() async throws
}

public final class ResetUserProgressUseCase: ResetUserProgressUseCaseProtocol {
    private let srsRepository: SRSRepositoryProtocol

    public init(srsRepository: SRSRepositoryProtocol) {
        self.srsRepository = srsRepository
    }

    public func executeResetAllProgress() async throws {
        try await srsRepository.resetAllProgress()
    }
}
