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
    public private(set) weak var settingsStore: UserSettingsStore?

    public private(set) var lastActiveEngine: ActiveEngineType?
    private(set) var activeLease: AudioSessionLease?
    private(set) var playbackStartTask: Task<Void, Never>?
    private(set) var playbackReleaseTask: Task<Void, Never>?
    private(set) var currentUtterance: AVSpeechUtterance?
    fileprivate var requestGeneration: UInt = 0

    public override convenience init() {
        self.init(audioSessionCoordinator: AudioSessionCoordinator())
    }

    public init(
        audioSessionCoordinator: any AudioSessionCoordinating = AudioSessionCoordinator(),
        settingsStore: UserSettingsStore? = nil,
        appleEngine: AppleEnhancedTTSEngine = AppleEnhancedTTSEngine()
    ) {
        self.audioSessionCoordinator = audioSessionCoordinator
        self.settingsStore = settingsStore
        self.appleEngine = appleEngine
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
            if self.requestGeneration == generation {
                self.isSpeaking = false
                self.currentUtterance = nil
            }
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

    public func previewVoice(profile: VoiceProfile, rate: Double = 1.0, pitch: Double = 1.0) async {
        stop()
        requestGeneration += 1
        let generation = requestGeneration
        isSpeaking = true
        let task = Task { @MainActor [weak self] in
            guard let self, await self.acquirePlaybackLease(generation: generation) else { return }
            guard !Task.isCancelled, self.requestGeneration == generation else {
                await self.finishPlayback(generation: generation)
                return
            }
            self.lastActiveEngine = .apple
            await self.appleEngine.speakAsync(
                text: profile.sampleText,
                rate: Float(rate),
                locale: profile.locale,
                voiceIdentifier: profile.appleVoiceIdentifier,
                pitch: Float(pitch)
            )
            await self.finishPlayback(generation: generation)
        }
        playbackStartTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
            Task { @MainActor [weak self] in
                guard let self, self.requestGeneration == generation else { return }
                self.stop()
            }
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
            await self.performPlaybackAsync(
                text: text, context: context, rate: rate, generation: currentGeneration, waitsForCompletion: false
            )
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
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
            Task { @MainActor [weak self] in
                guard let self, self.requestGeneration == currentGeneration else { return }
                self.stop()
            }
        }
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

        appleEngine.stop()

        isSpeaking = false
        currentUtterance = nil
        releaseActiveLease()
    }
}

// MARK: - Playback Execution

extension TextToSpeechService {
    func performPlaybackAsync(
        text: String,
        context: SpeechContext,
        rate: Float,
        generation: UInt,
        waitsForCompletion: Bool = true
    ) async {
        guard await acquirePlaybackLease(generation: generation) else { return }
        guard !Task.isCancelled, requestGeneration == generation else {
            await finishPlayback(generation: generation)
            return
        }

        let locale: String
        let persona: VoicePersona?
        switch context {
        case .conversation(let contextPersona, let contextLocale):
            locale = contextLocale
            persona = contextPersona
        case .pronunciation(let contextLocale):
            locale = contextLocale
            persona = nil
        }
        let profile = VoiceProfileCatalog.resolve(id: settingsStore?.voiceProfileId ?? "systemAuto")
        let voiceLocale = profile.engine == .system ? locale : profile.locale
        let userRate = rate * Float(settingsStore?.speechRate ?? 1.0)
        let userPitch = Float(settingsStore?.speechPitch ?? 1.0)
        lastActiveEngine = .apple
        currentUtterance = makeUtterance(
            text: text, rate: userRate, locale: voiceLocale, persona: persona,
            voiceIdentifier: profile.appleVoiceIdentifier, pitch: userPitch
        )
        if waitsForCompletion {
            await appleEngine.speakAsync(
                text: text, rate: userRate, locale: voiceLocale, persona: persona,
                voiceIdentifier: profile.appleVoiceIdentifier, pitch: userPitch
            )
            await finishPlayback(generation: generation)
        } else {
            appleEngine.speak(
                text: text, rate: userRate, locale: voiceLocale, persona: persona,
                voiceIdentifier: profile.appleVoiceIdentifier, pitch: userPitch,
                onFinished: { [weak self] in
                    Task { @MainActor in await self?.finishPlayback(generation: generation) }
                }
            )
        }
    }

    private func finishPlayback(generation: UInt) async {
        guard requestGeneration == generation else { return }
        isSpeaking = false
        currentUtterance = nil
        await releaseActiveLeaseAsync()
    }
}
