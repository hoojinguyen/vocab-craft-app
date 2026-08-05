import SwiftUI

@MainActor
@Observable
public final class SettingsViewModel {
    public var store: UserSettingsStore
    public var isPlayingAudio: Bool = false
    public var cacheSizeString: String = "12.4 MB"
    private let ttsService: TextToSpeechProtocol?

    public init(store: UserSettingsStore = UserSettingsStore(), ttsService: TextToSpeechProtocol? = nil) {
        self.store = store
        self.ttsService = ttsService
    }

    public func playAudioPreview() {
        isPlayingAudio = true
        let sampleText = "VocabCraft: Master English naturally"
        let localeStr = store.ttsVoiceGender == "US" ? "en-US" : "en-GB"
        ttsService?.speak(text: sampleText, rate: Float(store.ttsSpeed), locale: localeStr)
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.isPlayingAudio = false
        }
    }

    public func clearCache() {
        cacheSizeString = "0.0 MB"
    }
}
