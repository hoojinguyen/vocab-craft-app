import Foundation

/// Represents the active state of an AI voice call session.
public enum VoiceCallState: Equatable, Sendable {
    case idle
    case speaking(characterText: String)
    case listening(liveTranscript: String)
    case thinking
    case error(AIPackError)
    case ended
}

/// Abstract contract for the voice roleplay engine coordinating audio and LLM turns.
@MainActor
public protocol VoiceConversationEngineProtocol: AnyObject, Sendable {
    var state: VoiceCallState { get }
    var isMuted: Bool { get }
    var isSubtitlesVisible: Bool { get }
    var audioErrorMessage: String? { get }
    var audioLevel: Float { get }
    var suggestedResponses: [String] { get }
    var scenario: RoleplayScenario { get }
    var messages: [RoleplayMessage] { get }
    var masteredTargetWords: Set<String> { get }
    var onSessionAutoConcluded: ((RoleplaySessionSummary) -> Void)? { get set }

    func startCall() async
    func finishUserTurnManually()
    func retryListening()
    func toggleMute()
    func toggleSubtitles()
    func cancelCall()
    func endCall() async -> RoleplaySessionSummary
}

public extension VoiceConversationEngineProtocol {
    var audioErrorMessage: String? { nil }
    var audioLevel: Float { 0.0 }
    var suggestedResponses: [String] { [] }
    var onSessionAutoConcluded: ((RoleplaySessionSummary) -> Void)? {
        get { nil }
        set { _ = newValue }
    }
    func retryListening() {}
    func cancelCall() {}
}
