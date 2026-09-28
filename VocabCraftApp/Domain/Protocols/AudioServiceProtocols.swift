import Foundation

/// Protocol abstraction for Text-to-Speech audio playback.
@MainActor
public protocol TextToSpeechProtocol: AnyObject, Sendable {
    var isSpeaking: Bool { get }
    func speak(text: String, rate: Float, locale: String)
    func speakAsync(text: String, rate: Float, locale: String) async
    func stop()
    func prewarm()
}

public extension TextToSpeechProtocol {
    func prewarm() {}

    func speak(text: String) {
        speak(text: text, rate: 0.5, locale: "en-US")
    }

    func speakAsync(text: String) async {
        await speakAsync(text: text, rate: 0.5, locale: "en-US")
    }

    func speakAsync(text: String, rate: Float, locale: String) async {
        speak(text: text, rate: rate, locale: locale)
    }
}

/// Protocol abstraction for Speech-to-Text voice recognition.
@MainActor
public protocol SpeechRecognitionProtocol: AnyObject {
    var isListening: Bool { get }
    var recognizedText: String { get }
    var audioLevel: Float { get }

    func startListening(
        onResult: @escaping (String) -> Void,
        onAudioLevel: ((Float) -> Void)?,
        onError: @escaping (Error) -> Void
    )
    func stopListening()
}

public extension SpeechRecognitionProtocol {
    var audioLevel: Float {
        0.0
    }

    func startListening(
        onResult: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        startListening(onResult: onResult, onAudioLevel: nil, onError: onError)
    }
}
