import AVFoundation
import Foundation
import Observation

private final class TTSCleanupBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _eventSubscriptionTask: Task<Void, Never>?

    var eventSubscriptionTask: Task<Void, Never>? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _eventSubscriptionTask
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _eventSubscriptionTask = newValue
        }
    }

    func cleanup() {
        lock.lock()
        let task = _eventSubscriptionTask
        _eventSubscriptionTask = nil
        lock.unlock()
        task?.cancel()
    }
}

/// Identifies which underlying speech synthesis engine handled the latest utterance.
public enum ActiveEngineType: Sendable, Equatable {
    case apple
    case gemini
    case kokoro
}

@MainActor
@Observable
public final class TextToSpeechService: NSObject, TextToSpeechProtocol {
    public private(set) var isSpeaking: Bool = false
    private let cleanupBox = TTSCleanupBox()
    private var eventSubscriptionTask: Task<Void, Never>? {
        get { cleanupBox.eventSubscriptionTask }
        set { cleanupBox.eventSubscriptionTask = newValue }
    }

    public let audioSessionCoordinator: any AudioSessionCoordinating
    public let appleEngine: AppleEnhancedTTSEngine
    public let geminiEngine: any GeminiAudioSynthesizing
    public let kokoroEngine: any KokoroAudioSynthesizing
    public private(set) weak var settingsStore: UserSettingsStore?
    private let apiKeyProvider: (@MainActor @Sendable () -> String?)?

    public private(set) var lastActiveEngine: ActiveEngineType?
    private(set) var activeLease: AudioSessionLease?
    private(set) var playbackStartTask: Task<Void, Never>?
    private(set) var playbackReleaseTask: Task<Void, Never>?
    private(set) var currentUtterance: AVSpeechUtterance?
    fileprivate var requestGeneration: UInt = 0

    public override convenience init() {
        self.init(audioSessionCoordinator: AudioSessionCoordinator())
    }

    public convenience init(
        settingsStore: UserSettingsStore?,
        audioSessionCoordinator: any AudioSessionCoordinating = AudioSessionCoordinator(),
        appleEngine: AppleEnhancedTTSEngine = AppleEnhancedTTSEngine(),
        geminiEngine: any GeminiAudioSynthesizing = GeminiAudioSpeechEngine(),
        kokoroEngine: any KokoroAudioSynthesizing = KokoroTTSEngine(),
        apiKeyProvider: (@MainActor @Sendable () -> String?)? = nil
    ) {
        self.init(
            audioSessionCoordinator: audioSessionCoordinator,
            appleEngine: appleEngine,
            geminiEngine: geminiEngine,
            kokoroEngine: kokoroEngine,
            settingsStore: settingsStore,
            apiKeyProvider: apiKeyProvider
        )
    }

    public init(
        audioSessionCoordinator: any AudioSessionCoordinating = AudioSessionCoordinator(),
        appleEngine: AppleEnhancedTTSEngine = AppleEnhancedTTSEngine(),
        geminiEngine: any GeminiAudioSynthesizing = GeminiAudioSpeechEngine(),
        kokoroEngine: any KokoroAudioSynthesizing = KokoroTTSEngine(),
        settingsStore: UserSettingsStore? = nil,
        apiKeyProvider: (@MainActor @Sendable () -> String?)? = nil
    ) {
        self.audioSessionCoordinator = audioSessionCoordinator
        self.appleEngine = appleEngine
        self.geminiEngine = geminiEngine
        self.kokoroEngine = kokoroEngine
        self.settingsStore = settingsStore
        self.apiKeyProvider = apiKeyProvider
        super.init()
        subscribeToAudioSessionEvents()
        prewarm()
    }

    deinit {
        cleanupBox.cleanup()
    }

    public func prewarm() {
        _ = AppleVoiceSelector.resolveBestVoice(for: "en-US")
        _ = Self.resolveVoice(for: "en-US")
    }

    fileprivate var resolvedApiKey: String? {
        if let providerKey = apiKeyProvider?()?.trimmingCharacters(in: .whitespacesAndNewlines), !providerKey.isEmpty {
            return providerKey
        }
        if let storeKey = settingsStore?.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines), !storeKey.isEmpty {
            return storeKey
        }
        return nil
    }

    private func subscribeToAudioSessionEvents() {
        let events = audioSessionCoordinator.events
        let task = Task { @MainActor [weak self] in
            for await event in events {
                guard let self else { break }
                switch event {
                case .interruptionBegan, .mediaServicesReset:
                    self.stop()
                default:
                    break
                }
            }
        }
        self.eventSubscriptionTask = task
    }

    private nonisolated(unsafe) static var cachedVoices: [String: AVSpeechSynthesisVoice] = [:]
    private nonisolated static let voiceLock = NSLock()

    public nonisolated static func resolveVoice(for locale: String) -> AVSpeechSynthesisVoice? {
        voiceLock.lock()
        defer { voiceLock.unlock() }
        if let cached = cachedVoices[locale] { return cached }
        #if targetEnvironment(simulator)
        let voice = AVSpeechSynthesisVoice(language: locale)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        #else
        let voice = AVSpeechSynthesisVoice(language: locale)
            ?? AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language.hasPrefix("en") })
            ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        #endif
        if let voice { cachedVoices[locale] = voice }
        return voice
    }

    @discardableResult
    fileprivate func acquirePlaybackLease(generation: UInt) async -> Bool {
        let lease: AudioSessionLease
        do {
            lease = try await audioSessionCoordinator.acquire(.playback)
        } catch {
            LessonPerformanceDiagnostics.error("tts.audioSession.acquire", error: error)
            if self.requestGeneration == generation {
                self.isSpeaking = false
                self.currentUtterance = nil
            }
            return false
        }

        guard !Task.isCancelled, self.requestGeneration == generation else {
            await self.audioSessionCoordinator.release(lease)
            return false
        }

        self.activeLease = lease
        return true
    }

    @discardableResult
    func releaseActiveLease() -> Task<Void, Never>? {
        guard let lease = activeLease else { return nil }
        activeLease = nil
        let coordinator = audioSessionCoordinator
        let task = Task {
            await coordinator.release(lease)
        }
        playbackReleaseTask = task
        return task
    }

    fileprivate func releaseActiveLeaseAsync() async {
        guard let lease = activeLease else { return }
        activeLease = nil
        let coordinator = audioSessionCoordinator
        let task = Task {
            await coordinator.release(lease)
        }
        playbackReleaseTask = task
        await task.value
    }

    public func makeUtterance(
        text: String,
        rate: Float,
        locale: String,
        persona: VoicePersona? = nil,
        voiceIdentifier: String? = nil,
        pitch: Float? = nil
    ) -> AVSpeechUtterance? {
        appleEngine.makeUtterance(
            text: text,
            rate: rate,
            locale: locale,
            persona: persona,
            voiceIdentifier: voiceIdentifier,
            pitch: pitch
        )
    }

    public func previewVoice(profile: RoleplayVoiceProfile, rate: Double = 1.0, pitch: Double = 1.0) async {
        stop()

        requestGeneration += 1
        let currentGeneration = requestGeneration

        let acquired = await acquirePlaybackLease(generation: currentGeneration)
        guard acquired, !Task.isCancelled, self.requestGeneration == currentGeneration else { return }

        isSpeaking = true
        defer {
            if self.requestGeneration == currentGeneration {
                self.isSpeaking = false
            }
            Task { [weak self] in await self?.releaseActiveLeaseAsync() }
        }

        switch profile.engine {
        case .kokoroNeural:
            if kokoroEngine.isReady {
                lastActiveEngine = .kokoro
                do {
                    try await kokoroEngine.synthesizeAndPlay(text: profile.sampleText, persona: profile.geminiPersona ?? .friendlyFemale)
                    return
                } catch {
                    // Fallthrough to Apple if it fails
                }
            } else {
                lastActiveEngine = .apple
                await appleEngine.speakAsync(
                    text: "Kokoro model is not downloaded. Please download it in On-Device Models settings.",
                    rate: Float(rate),
                    locale: "en-US",
                    persona: profile.geminiPersona,
                    voiceIdentifier: nil,
                    pitch: Float(pitch)
                )
                return
            }
            fallthrough
        case .geminiNeural:
            if let persona = profile.geminiPersona, let apiKey = resolvedApiKey, !apiKey.isEmpty {
                lastActiveEngine = .gemini
                do {
                    try await geminiEngine.synthesizeAndPlay(text: profile.sampleText, persona: persona, apiKey: apiKey)
                    return
                } catch {
                    // Fallthrough to Apple if it fails
                }
            } else {
                lastActiveEngine = .apple
                await appleEngine.speakAsync(
                    text: "API key is required for Studio Neural voices. Please configure it in AI settings.",
                    rate: Float(rate),
                    locale: "en-US",
                    persona: profile.geminiPersona,
                    voiceIdentifier: nil,
                    pitch: Float(pitch)
                )
                return
            }
            fallthrough
        case .appleEnhanced:
            lastActiveEngine = .apple
            let voiceId = profile.appleVoiceIdentifier
            await appleEngine.speakAsync(
                text: profile.sampleText,
                rate: Float(rate),
                locale: profile.locale,
                persona: profile.geminiPersona,
                voiceIdentifier: voiceId,
                pitch: Float(pitch)
            )
        }
    }

    public func speak(text: String, rate: Float = 1.0, locale: String = "en-US") {
        speak(text: text, context: .pronunciation(locale: locale), rate: rate)
    }

    public func speak(text: String, context: SpeechContext, rate: Float = 1.0) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        LessonPerformanceDiagnostics.event("TTSRequest")

        stop()

        isSpeaking = true
        requestGeneration += 1
        let currentGeneration = requestGeneration

        playbackStartTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performPlaybackAsync(text: text, context: context, rate: rate, generation: currentGeneration)
        }
    }

    public func speakAsync(text: String, rate: Float = 1.0, locale: String = "en-US") async {
        await speakAsync(text: text, context: .pronunciation(locale: locale), rate: rate)
    }

    public func speakAsync(text: String, context: SpeechContext, rate: Float = 1.0) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isSpeaking = false
            currentUtterance = nil
            return
        }

        stop()

        isSpeaking = true
        requestGeneration += 1
        let currentGeneration = requestGeneration

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performPlaybackAsync(text: text, context: context, rate: rate, generation: currentGeneration)
        }
        playbackStartTask = task
        await task.value
    }

    public static func calculateSafetyTimeoutNanoseconds(for text: String) -> UInt64 {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordsCount = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).count
        let timeoutSeconds = max(25.0, Double(wordsCount) * 0.9 + 10.0)
        return UInt64(timeoutSeconds * 1_000_000_000)
    }

    public func stop() {
        playbackStartTask?.cancel()
        playbackStartTask = nil
        requestGeneration += 1

        kokoroEngine.stop()
        geminiEngine.stop()
        appleEngine.stop()

        isSpeaking = false
        currentUtterance = nil
        releaseActiveLease()
    }
}

// MARK: - Playback Execution

extension TextToSpeechService {
    func performPlaybackAsync(text: String, context: SpeechContext, rate: Float, generation: UInt) async {
        let acquired = await acquirePlaybackLease(generation: generation)
        guard acquired, !Task.isCancelled, self.requestGeneration == generation else {
            if self.requestGeneration == generation {
                self.isSpeaking = false
                self.currentUtterance = nil
                self.releaseActiveLease()
            }
            return
        }

        self.isSpeaking = true

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            await performTestingPlaybackAsync(text: text, context: context, generation: generation)
            return
        }

        switch context {
        case .conversation(let persona, let locale):
            await playConversation(text: text, persona: persona, locale: locale, rate: rate, generation: generation)
        case .pronunciation(let locale):
            lastActiveEngine = .apple
            currentUtterance = makeUtterance(text: text, rate: rate, locale: locale)
            await appleEngine.speakAsync(text: text, rate: rate, locale: locale)
        }

        if self.requestGeneration == generation {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        await releaseActiveLeaseAsync()
    }

    private func playConversation(
        text: String,
        persona: VoicePersona,
        locale: String,
        rate: Float,
        generation: UInt
    ) async {
        if await playProfileIfConfigured(text: text, persona: persona, rate: rate, generation: generation) {
            return
        }

        if kokoroEngine.isReady {
            await playWithKokoro(text: text, persona: persona, locale: locale, rate: rate, generation: generation)
        } else if let apiKey = resolvedApiKey {
            await playWithGemini(
                text: text,
                persona: persona,
                fallbackLocale: locale,
                apiKey: apiKey,
                generation: generation
            )
        } else {
            lastActiveEngine = .apple
            currentUtterance = makeUtterance(text: text, rate: rate, locale: locale)
            await appleEngine.speakAsync(text: text, rate: rate, locale: locale, persona: persona)
        }
    }

    private func playProfileIfConfigured(
        text: String,
        persona: VoicePersona,
        rate: Float,
        generation: UInt
    ) async -> Bool {
        guard let configuredVoiceId = settingsStore?.roleplayVoiceId, configuredVoiceId != "systemAuto",
              let profile = RoleplayVoiceProfileCatalog.profile(for: configuredVoiceId) else {
            return false
        }

        switch profile.engine {
        case .kokoroNeural:
            let targetPersona = profile.geminiPersona ?? persona
            if kokoroEngine.isReady {
                await playWithKokoro(text: text, persona: targetPersona, locale: profile.locale, rate: rate, generation: generation)
                return true
            }
            
            // Fallback to Gemini if Kokoro is not ready (missing ML weights) to provide a neural voice experience
            if let apiKey = resolvedApiKey {
                lastActiveEngine = .gemini
                do {
                    try await geminiEngine.synthesizeAndPlay(text: text, persona: targetPersona, apiKey: apiKey)
                    if self.requestGeneration == generation {
                        self.isSpeaking = false
                        self.currentUtterance = nil
                    }
                    await releaseActiveLeaseAsync()
                    return true
                } catch {
                    // Fallthrough to Apple if Gemini also fails
                    guard self.requestGeneration == generation, !Task.isCancelled else {
                        if self.requestGeneration == generation {
                            self.isSpeaking = false
                            self.currentUtterance = nil
                        }
                        await releaseActiveLeaseAsync()
                        return true
                    }
                    LessonPerformanceDiagnostics.event("TTSGeminiFallbackToApple", detail: error.localizedDescription)
                }
            }
            
            await playAppleEnhancedProfile(
                text: text,
                profile: profile,
                defaultPersona: persona,
                baseRate: rate,
                generation: generation
            )
            return true
        case .geminiNeural:
            if let apiKey = resolvedApiKey {
                lastActiveEngine = .gemini
                let targetPersona = profile.geminiPersona ?? persona
                do {
                    try await geminiEngine.synthesizeAndPlay(text: text, persona: targetPersona, apiKey: apiKey)
                    if self.requestGeneration == generation {
                        self.isSpeaking = false
                        self.currentUtterance = nil
                    }
                    await releaseActiveLeaseAsync()
                    return true
                } catch {
                    guard self.requestGeneration == generation, !Task.isCancelled else {
                        if self.requestGeneration == generation {
                            self.isSpeaking = false
                            self.currentUtterance = nil
                        }
                        await releaseActiveLeaseAsync()
                        return true
                    }
                    LessonPerformanceDiagnostics.event("TTSGeminiFallbackToApple", detail: error.localizedDescription)
                }
            }
            await playAppleEnhancedProfile(
                text: text,
                profile: profile,
                defaultPersona: persona,
                baseRate: rate,
                generation: generation
            )
            return true
        case .appleEnhanced:
            await playAppleEnhancedProfile(
                text: text,
                profile: profile,
                defaultPersona: persona,
                baseRate: rate,
                generation: generation
            )
            return true
        }
    }

    private func playWithKokoro(
        text: String,
        persona: VoicePersona,
        locale: String,
        rate: Float,
        generation: UInt
    ) async {
        lastActiveEngine = .kokoro
        do {
            try await kokoroEngine.synthesizeAndPlay(text: text, persona: persona)
        } catch {
            guard self.requestGeneration == generation, !Task.isCancelled else {
                if self.requestGeneration == generation {
                    self.isSpeaking = false
                    self.currentUtterance = nil
                }
                await releaseActiveLeaseAsync()
                return
            }
            LessonPerformanceDiagnostics.event("TTSFallbackFromKokoro", detail: error.localizedDescription)
            if let apiKey = self.resolvedApiKey {
                lastActiveEngine = .gemini
                do {
                    let targetPersona = persona
                    try await geminiEngine.synthesizeAndPlay(text: text, persona: targetPersona, apiKey: apiKey)
                    return
                } catch {
                    LessonPerformanceDiagnostics.event("TTSFallbackToApple", detail: error.localizedDescription)
                }
            }
            
            lastActiveEngine = .apple
            currentUtterance = makeUtterance(text: text, rate: rate, locale: locale)
            await appleEngine.speakAsync(text: text, rate: rate, locale: locale, persona: persona)
        }
    }

    private func playWithGemini(
        text: String,
        persona: VoicePersona,
        fallbackLocale: String,
        apiKey: String,
        generation: UInt
    ) async {
        lastActiveEngine = .gemini
        do {
            try await geminiEngine.synthesizeAndPlay(text: text, persona: persona, apiKey: apiKey)
        } catch {
            guard self.requestGeneration == generation, !Task.isCancelled else {
                if self.requestGeneration == generation {
                    self.isSpeaking = false
                    self.currentUtterance = nil
                }
                await releaseActiveLeaseAsync()
                return
            }
            LessonPerformanceDiagnostics.event("TTSFallbackToApple", detail: error.localizedDescription)
            lastActiveEngine = .apple
            currentUtterance = makeUtterance(text: text, rate: 1.0, locale: fallbackLocale)
            await appleEngine.speakAsync(text: text, rate: 1.0, locale: fallbackLocale, persona: persona)
        }
    }

    private func playAppleEnhancedProfile(
        text: String,
        profile: RoleplayVoiceProfile,
        defaultPersona: VoicePersona,
        baseRate: Float,
        generation: UInt
    ) async {
        lastActiveEngine = .apple
        let userRate = Float(baseRate * Float(settingsStore?.roleplaySpeechRate ?? 1.0))
        let userPitch = Float(settingsStore?.roleplaySpeechPitch ?? 1.0)
        let effectivePersona = profile.geminiPersona ?? defaultPersona
        currentUtterance = makeUtterance(
            text: text,
            rate: userRate,
            locale: profile.locale,
            persona: effectivePersona,
            voiceIdentifier: profile.appleVoiceIdentifier,
            pitch: userPitch
        )
        await appleEngine.speakAsync(
            text: text,
            rate: userRate,
            locale: profile.locale,
            persona: effectivePersona,
            voiceIdentifier: profile.appleVoiceIdentifier,
            pitch: userPitch
        )
        if self.requestGeneration == generation {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        await releaseActiveLeaseAsync()
    }

    private func performTestingPlaybackAsync(text: String, context: SpeechContext, generation: UInt) async {
        switch context {
        case .conversation(let persona, _):
            await performTestingConversationPlayback(text: text, persona: persona, generation: generation)
        case .pronunciation:
            lastActiveEngine = .apple
        }

        if self.requestGeneration == generation {
            self.isSpeaking = false
            self.currentUtterance = nil
            self.releaseActiveLease()
        }
    }

    private func performTestingConversationPlayback(
        text: String,
        persona: VoicePersona,
        generation: UInt
    ) async {
        if await performTestingProfilePlayback(text: text, persona: persona, generation: generation) {
            return
        }

        if kokoroEngine.isReady {
            lastActiveEngine = .kokoro
            do {
                try await kokoroEngine.synthesizeAndPlay(text: text, persona: persona)
            } catch {
                guard self.requestGeneration == generation, !Task.isCancelled else {
                    if self.requestGeneration == generation {
                        self.isSpeaking = false
                        self.currentUtterance = nil
                    }
                    await releaseActiveLeaseAsync()
                    return
                }
                LessonPerformanceDiagnostics.event("TTSFallbackToApple", detail: error.localizedDescription)
                lastActiveEngine = .apple
            }
        } else if let apiKey = resolvedApiKey {
            lastActiveEngine = .gemini
            do {
                try await geminiEngine.synthesizeAndPlay(text: text, persona: persona, apiKey: apiKey)
            } catch {
                guard self.requestGeneration == generation, !Task.isCancelled else {
                    if self.requestGeneration == generation {
                        self.isSpeaking = false
                        self.currentUtterance = nil
                    }
                    await releaseActiveLeaseAsync()
                    return
                }
                LessonPerformanceDiagnostics.event("TTSFallbackToApple", detail: error.localizedDescription)
                lastActiveEngine = .apple
            }
        } else {
            lastActiveEngine = .apple
        }
    }

    private func performTestingProfilePlayback(
        text: String,
        persona: VoicePersona,
        generation: UInt
    ) async -> Bool {
        guard let configuredVoiceId = settingsStore?.roleplayVoiceId, configuredVoiceId != "systemAuto",
              let profile = RoleplayVoiceProfileCatalog.profile(for: configuredVoiceId) else {
            return false
        }

        switch profile.engine {
        case .kokoroNeural:
            if kokoroEngine.isReady {
                let targetPersona = profile.geminiPersona ?? persona
                lastActiveEngine = .kokoro
                do {
                    try await kokoroEngine.synthesizeAndPlay(text: text, persona: targetPersona)
                } catch {
                    guard self.requestGeneration == generation, !Task.isCancelled else {
                        if self.requestGeneration == generation {
                            self.isSpeaking = false
                            self.currentUtterance = nil
                        }
                        await releaseActiveLeaseAsync()
                        return true
                    }
                    lastActiveEngine = .apple
                }
            } else {
                lastActiveEngine = .apple
            }
        case .geminiNeural:
            if let apiKey = resolvedApiKey {
                lastActiveEngine = .gemini
                let targetPersona = profile.geminiPersona ?? persona
                do {
                    try await geminiEngine.synthesizeAndPlay(text: text, persona: targetPersona, apiKey: apiKey)
                } catch {
                    guard self.requestGeneration == generation, !Task.isCancelled else {
                        if self.requestGeneration == generation {
                            self.isSpeaking = false
                            self.currentUtterance = nil
                        }
                        await releaseActiveLeaseAsync()
                        return true
                    }
                    LessonPerformanceDiagnostics.event("TTSGeminiFallbackToApple", detail: error.localizedDescription)
                    lastActiveEngine = .apple
                }
            } else {
                lastActiveEngine = .apple
            }
        case .appleEnhanced:
            lastActiveEngine = .apple
        }
        return true
    }
}
