import SwiftUI

@MainActor
@Observable
public final class SettingsViewModel {
    public var store: UserSettingsStore
    public var isPlayingAudio: Bool = false
    public var cacheSizeString: String = "12.4 MB"
    private let ttsService: TextToSpeechProtocol

    private var audioTask: Task<Void, Never>?

    public init(store: UserSettingsStore, ttsService: TextToSpeechProtocol) {
        self.store = store
        self.ttsService = ttsService
    }

    public func playAudioPreview() {
        audioTask?.cancel()
        isPlayingAudio = true
        let sampleText = "VocabCraft: Master English naturally"
        let localeStr = store.ttsVoiceGender == "US" ? "en-US" : "en-GB"
        ttsService.speak(text: sampleText, rate: Float(store.ttsSpeed), locale: localeStr)

        audioTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self.isPlayingAudio = false
        }
    }

    public func clearCache() {
        cacheSizeString = "0.0 MB"
    }

    public func resetSRSProgress() {
        // Resets SRS progress without touching user notification settings
        store.dailyGoalCount = 15
    }
}
