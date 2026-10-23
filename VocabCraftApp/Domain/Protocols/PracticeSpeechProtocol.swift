import Foundation

@MainActor
public protocol PracticeSpeechProtocol: AnyObject, Sendable {
    func capability() -> PracticeCapability
    func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error>
    func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error>
    func stop() async
}
