import Foundation

/// Represents the active state of an AI voice call session.
public enum VoiceCallState: Equatable, Sendable {
    case idle
    case speaking(characterText: String)
    case listening(liveTranscript: String)
    case thinking
    case ended
}

/// Abstract contract for the voice roleplay engine coordinating audio and LLM turns.
@MainActor
public protocol VoiceConversationEngineProtocol: AnyObject, Sendable {
    var state: VoiceCallState { get }
    var isMuted: Bool { get }
    var isSubtitlesVisible: Bool { get }
    var audioErrorMessage: String? { get }
    var scenario: RoleplayScenario { get }
    var messages: [RoleplayMessage] { get }
    var masteredTargetWords: Set<String> { get }

    func startCall() async
    func finishUserTurnManually()
    func retryListening()
    func toggleMute()
    func toggleSubtitles()
    func endCall() async -> RoleplaySessionSummary
}

public extension VoiceConversationEngineProtocol {
    var audioErrorMessage: String? { nil }
    func retryListening() {}
}
