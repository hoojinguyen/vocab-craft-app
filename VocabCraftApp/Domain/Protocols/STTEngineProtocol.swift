import Foundation

public protocol STTEngineProtocol: Sendable {
    var engineName: String { get }
    var isReady: Bool { get }
    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error>
    func stopRecognition()
}
