import Foundation

/// Defines asynchronous interaction contracts for generating guided practice dialogue and evaluating learner performance.
public protocol PracticeAIProtocol: Sendable {
    /// Advertised capabilities supported by this AI provider instance.
    func capability() async -> PracticeCapability

    /// Generates communicative character response and structured assessment for the current practice turn.
    func respond(to request: PracticeAIRequest) async throws -> PracticeAIResponse
}
