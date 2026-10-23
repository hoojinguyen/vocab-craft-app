import Foundation

/// Presentation projection derived from active practice session state and system capabilities.
public struct PracticePresentationState: Equatable, Sendable {
    public let canSubmit: Bool
    public let canCapture: Bool
    public let canRequestHelp: Bool
    public let showUnsaved: Bool
    public let messageKey: String?
    public let isProcessing: Bool
    public let isCapturing: Bool
    public let isPlayingCharacter: Bool
    public let isCoaching: Bool
    public let isPaused: Bool
    public let isError: Bool

    public init(
        canSubmit: Bool,
        canCapture: Bool,
        canRequestHelp: Bool,
        showUnsaved: Bool,
        messageKey: String? = nil,
        isProcessing: Bool = false,
        isCapturing: Bool = false,
        isPlayingCharacter: Bool = false,
        isCoaching: Bool = false,
        isPaused: Bool = false,
        isError: Bool = false
    ) {
        self.canSubmit = canSubmit
        self.canCapture = canCapture
        self.canRequestHelp = canRequestHelp
        self.showUnsaved = showUnsaved
        self.messageKey = messageKey
        self.isProcessing = isProcessing
        self.isCapturing = isCapturing
        self.isPlayingCharacter = isPlayingCharacter
        self.isCoaching = isCoaching
        self.isPaused = isPaused
        self.isError = isError
    }

    /// Derives the appropriate presentation state from the current session state, capability flags, and optional summary persistence.
    public static func make(
        from state: PracticeSessionState,
        capability: PracticeCapability,
        summary: PracticeSummary? = nil
    ) -> PracticePresentationState {
        let isUnsaved = summary.map { !$0.persisted } ?? false

        switch state {
        case .preparing:
            return PracticePresentationState(canSubmit: false, canCapture: false, canRequestHelp: false, showUnsaved: isUnsaved)
        case .awaitingLearner:
            return PracticePresentationState(
                canSubmit: true,
                canCapture: capability.canCaptureSpeech,
                canRequestHelp: true,
                showUnsaved: isUnsaved
            )
        case .capturing:
            return PracticePresentationState(
                canSubmit: true,
                canCapture: false,
                canRequestHelp: false,
                showUnsaved: isUnsaved,
                messageKey: "app.ai_assistant.guided.session.listening",
                isCapturing: true
            )
        case .processing:
            return PracticePresentationState(
                canSubmit: false,
                canCapture: false,
                canRequestHelp: false,
                showUnsaved: isUnsaved,
                messageKey: "app.ai_assistant.guided.session.processing",
                isProcessing: true
            )
        case .playingCharacter:
            return PracticePresentationState(
                canSubmit: false,
                canCapture: false,
                canRequestHelp: false,
                showUnsaved: isUnsaved,
                isPlayingCharacter: true
            )
        case .coaching:
            return PracticePresentationState(
                canSubmit: false,
                canCapture: false,
                canRequestHelp: false,
                showUnsaved: isUnsaved,
                isCoaching: true
            )
        case .paused:
            return PracticePresentationState(
                canSubmit: false,
                canCapture: false,
                canRequestHelp: false,
                showUnsaved: isUnsaved,
                messageKey: "app.ai_assistant.guided.session.paused_message",
                isPaused: true
            )
        case .recoverableError:
            return PracticePresentationState(
                canSubmit: false,
                canCapture: false,
                canRequestHelp: false,
                showUnsaved: true,
                messageKey: "app.ai_assistant.guided.error.desc",
                isError: true
            )
        case .saving:
            return PracticePresentationState(
                canSubmit: false,
                canCapture: false,
                canRequestHelp: false,
                showUnsaved: isUnsaved,
                messageKey: "app.ai_assistant.guided.session.processing",
                isProcessing: true
            )
        case .completed, .partial:
            return PracticePresentationState(canSubmit: false, canCapture: false, canRequestHelp: false, showUnsaved: isUnsaved)
        }
    }
}
