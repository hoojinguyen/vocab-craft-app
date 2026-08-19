import Foundation

/// Protocol abstraction for Text-to-Speech audio playback.
@MainActor
public protocol TextToSpeechProtocol: AnyObject {
    var isSpeaking: Bool { get }
    func speak(text: String, rate: Float, locale: String)
    func speakAsync(text: String, rate: Float, locale: String) async
    func stop()
}

public extension TextToSpeechProtocol {
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

    func startListening(onResult: @escaping (String) -> Void, onError: @escaping (Error) -> Void)
    func stopListening()
}
