import Foundation

public protocol STTEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error>
    func startRecognition(locale: String, onAudioLevel: (@Sendable (Float) -> Void)?) -> AsyncThrowingStream<String, Error>
    func stopRecognition()
}

public extension STTEngineProtocol {
    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        startRecognition(locale: locale, onAudioLevel: nil)
    }

    func startRecognition(locale: String, onAudioLevel: (@Sendable (Float) -> Void)?) -> AsyncThrowingStream<String, Error> {
        startRecognition(locale: locale)
    }
}
