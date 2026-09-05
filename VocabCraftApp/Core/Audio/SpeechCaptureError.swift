import AVFoundation
import Foundation
import Speech

public enum SpeechCaptureError: Error, Hashable, Sendable {
    case speechRecognitionDenied
    case microphoneDenied
    case audioSessionActivationFailed
    case enginePreparationFailed
    case recognizerUnavailable
    case cancelled
}

public protocol SpeechAuthorizing: Sendable {
    func requestSpeechAuthorization() async -> Bool
    func requestMicrophoneAuthorization() async -> Bool
}

public final class LiveSpeechAuthorizer: SpeechAuthorizing, @unchecked Sendable {
    public init() {}

    public func requestSpeechAuthorization() async -> Bool {
        #if os(iOS) && !targetEnvironment(simulator)
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { newStatus in
                    continuation.resume(returning: newStatus == .authorized)
                }
            }
        default:
            return false
        }
        #else
        return true
        #endif
    }

    public func requestMicrophoneAuthorization() async -> Bool {
        #if os(iOS) && !targetEnvironment(simulator)
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        #else
        return true
        #endif
    }
}
