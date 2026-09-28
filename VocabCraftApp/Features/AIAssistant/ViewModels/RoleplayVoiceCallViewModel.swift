import CraftUIKit
import Foundation
import Observation

/// ViewModel orchestrating state, muting, captions, haptic feedback, and call termination for full-screen voice roleplay.
@MainActor
@Observable
public final class RoleplayVoiceCallViewModel {
    public let engine: VoiceConversationEngineProtocol
    public var sessionSummary: RoleplaySessionSummary?
    public private(set) var isCallCancelled: Bool = false
    public var showDiscardAlert: Bool = false
    public var isHintsExpanded: Bool = false
    private let ttsService: (any TextToSpeechProtocol)?
    private let callStartTime: Date
    private var previousMasteredCount: Int = 0

    public init(
        engine: VoiceConversationEngineProtocol,
        ttsService: (any TextToSpeechProtocol)? = nil,
        callStartTime: Date = Date()
    ) {
        self.engine = engine
        self.ttsService = ttsService
        self.callStartTime = callStartTime
        self.previousMasteredCount = engine.masteredTargetWords.count
    }

    public var state: VoiceCallState { engine.state }
    public var scenario: RoleplayScenario { engine.scenario }
    public var masteredTargetWords: Set<String> { engine.masteredTargetWords }
    public var isMuted: Bool { engine.isMuted }
    public var isSubtitlesVisible: Bool { engine.isSubtitlesVisible }
    public var suggestedResponses: [String] { engine.suggestedResponses }
    public var audioLevel: Float { engine.audioLevel }

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

    public func toggleHints() {
        isHintsExpanded.toggle()
    }

    public func playSamplePronunciation(_ text: String) {
        ttsService?.speak(text: text)
    }

    public func endCall() async {
        let summary = await engine.endCall()
        let elapsed = Date().timeIntervalSince(callStartTime)
        if elapsed < 3.0 && summary.totalTurns == 0 {
            // Accidental quick dismissal
            self.sessionSummary = nil
            self.isCallCancelled = true
        } else {
            self.sessionSummary = summary
        }
    }

    public func handleCloseButton() {
        let elapsed = Date().timeIntervalSince(callStartTime)
        let turns = engine.messages.filter { $0.sender == .user }.count
        if elapsed < 3.0 && turns == 0 {
            cancelCall()
        } else {
            showDiscardAlert = true
        }
    }

    public func cancelCall() {
        engine.cancelCall()
        sessionSummary = nil
        isCallCancelled = true
    }

    public func checkForNewTargetWordMastered() {
        if engine.masteredTargetWords.count > previousMasteredCount {
            previousMasteredCount = engine.masteredTargetWords.count
            CraftHapticFeedback.success()
        }
    }
}
