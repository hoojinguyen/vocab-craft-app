import CraftUIKit
import Foundation
import Observation

/// ViewModel orchestrating state, muting, captions, haptic feedback, and call termination for full-screen voice roleplay.
@MainActor
@Observable
public final class RoleplayVoiceCallViewModel {
    public let engine: VoiceConversationEngineProtocol
    public var sessionSummary: RoleplaySessionSummary?
    private var previousMasteredCount: Int = 0

    public init(engine: VoiceConversationEngineProtocol) {
        self.engine = engine
        self.previousMasteredCount = engine.masteredTargetWords.count
    }

    public var state: VoiceCallState { engine.state }
    public var scenario: RoleplayScenario { engine.scenario }
    public var masteredTargetWords: Set<String> { engine.masteredTargetWords }
    public var isMuted: Bool { engine.isMuted }
    public var isSubtitlesVisible: Bool { engine.isSubtitlesVisible }

    public func startCall() async {
        await engine.startCall()
    }

    public func finishSpeaking() {
        engine.finishUserTurnManually()
    }

    public func toggleMute() {
        engine.toggleMute()
    }

    public func toggleSubtitles() {
        engine.toggleSubtitles()
    }

    public func endCall() async {
        let summary = await engine.endCall()
        self.sessionSummary = summary
    }

    public func checkForNewTargetWordMastered() {
        if engine.masteredTargetWords.count > previousMasteredCount {
            previousMasteredCount = engine.masteredTargetWords.count
            CraftHapticFeedback.success()
        }
    }
}
