import SwiftUI

@MainActor
@Observable
public final class SettingsViewModel {
    public var store: UserSettingsStore
    public var isPlayingAudio: Bool = false
    public var isPlayingRoleplayAudio: Bool = false
    public var cacheSizeString: String = "12.4 MB"
    public let ttsService: TextToSpeechProtocol
    private let resetProgressUseCase: ResetUserProgressUseCaseProtocol?

    private var audioTask: Task<Void, Never>?
    private var roleplayAudioTask: Task<Void, Never>?

    public init(
        store: UserSettingsStore,
        ttsService: TextToSpeechProtocol,
        resetProgressUseCase: ResetUserProgressUseCaseProtocol? = nil
    ) {
        self.store = store
        self.ttsService = ttsService
        self.resetProgressUseCase = resetProgressUseCase
    }

    public func playAudioPreview() {
        audioTask?.cancel()
        isPlayingAudio = true
        let sampleText = "VocabCraft: Master English naturally"
        let localeStr = "en-US"
        ttsService.speak(text: sampleText, rate: Float(store.ttsSpeed), locale: localeStr)

        audioTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self.isPlayingAudio = false
        }
    }

    public func playRoleplayVoicePreview() {
        if isPlayingRoleplayAudio {
            stopRoleplayVoicePreview()
            return
        }
        roleplayAudioTask?.cancel()
        isPlayingRoleplayAudio = true
        let profile = RoleplayVoiceProfileCatalog.profile(for: store.roleplayVoiceId)
            ?? RoleplayVoiceProfileCatalog.defaultProfile
        roleplayAudioTask = Task {
            await ttsService.previewVoice(
                profile: profile,
                rate: store.roleplaySpeechRate,
                pitch: store.roleplaySpeechPitch
            )
            guard !Task.isCancelled else { return }
            self.isPlayingRoleplayAudio = false
        }
    }

    public func stopRoleplayVoicePreview() {
        roleplayAudioTask?.cancel()
        ttsService.stop()
        isPlayingRoleplayAudio = false
    }

    public func clearCache() {
        cacheSizeString = "0.0 MB"
    }

    public func resetSRSProgress() async {
        store.dailyGoalCount = 15
        try? await resetProgressUseCase?.executeResetAllProgress()
    }
}
