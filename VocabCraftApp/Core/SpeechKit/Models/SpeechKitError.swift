import Foundation

public enum SpeechKitError: Error, LocalizedError, Equatable, Sendable {
    case speechRecognitionNotAuthorized
    case microphoneNotAuthorized
    case recognizerUnavailable
    case audioSessionConfigurationFailed
    case audioBufferCreationFailed
    case emptyTargetSentence

    public var errorDescription: String? {
        switch self {
        case .speechRecognitionNotAuthorized:
            return "Speech recognition authorization was denied or not determined."
        case .microphoneNotAuthorized:
            return "Microphone access was denied or not determined."
        case .recognizerUnavailable:
            return "Speech recognizer is not available on this device or for this locale."
        case .audioSessionConfigurationFailed:
            return "Failed to configure the audio session for recording."
        case .audioBufferCreationFailed:
            return "Failed to allocate audio buffer for recognition."
        case .emptyTargetSentence:
            return "The target sentence for evaluation cannot be empty."
        }
    }
}
