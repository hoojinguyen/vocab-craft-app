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

private final class UtteranceTransferBox: @unchecked Sendable {
    let utterance: AVSpeechUtterance
    init(_ utterance: AVSpeechUtterance) {
        self.utterance = utterance
    }
}

/// Identifies which underlying speech synthesis engine handled the latest utterance.
public enum ActiveEngineType: Sendable, Equatable {
    case apple
    case gemini
}

@MainActor
@Observable
public final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate, TextToSpeechProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    public private(set) var isSpeaking: Bool = false
    private var activeContinuation: CheckedContinuation<Void, Never>?
    private let cleanupBox = TTSCleanupBox()
    private var eventSubscriptionTask: Task<Void, Never>? {
        get { cleanupBox.eventSubscriptionTask }
        set { cleanupBox.eventSubscriptionTask = newValue }
    }

    public let audioSessionCoordinator: any AudioSessionCoordinating
    public let appleEngine: AppleEnhancedTTSEngine
    public let geminiEngine: any GeminiAudioSynthesizing
    public private(set) weak var settingsStore: UserSettingsStore?
    private let apiKeyProvider: (@MainActor @Sendable () -> String?)?

    public private(set) var lastActiveEngine: ActiveEngineType?
    private(set) var activeLease: AudioSessionLease?
    private(set) var playbackStartTask: Task<Void, Never>?
    private(set) var playbackReleaseTask: Task<Void, Never>?
    private(set) var currentUtterance: AVSpeechUtterance?
    private var requestGeneration: UInt = 0

    public override convenience init() {
        self.init(audioSessionCoordinator: AudioSessionCoordinator())
    }

    public init(
        audioSessionCoordinator: any AudioSessionCoordinating = AudioSessionCoordinator(),
        appleEngine: AppleEnhancedTTSEngine = AppleEnhancedTTSEngine(),
        geminiEngine: any GeminiAudioSynthesizing = GeminiAudioSpeechEngine(),
        settingsStore: UserSettingsStore? = nil,
        apiKeyProvider: (@MainActor @Sendable () -> String?)? = nil
    ) {
        self.audioSessionCoordinator = audioSessionCoordinator
        self.appleEngine = appleEngine
        self.geminiEngine = geminiEngine
        self.settingsStore = settingsStore
        self.apiKeyProvider = apiKeyProvider
        super.init()
        synthesizer.delegate = self
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

    private var resolvedApiKey: String? {
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
    private func acquirePlaybackLease(generation: UInt) async -> Bool {
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

    private func releaseActiveLeaseAsync() async {
        guard let lease = activeLease else { return }
        activeLease = nil
        let coordinator = audioSessionCoordinator
        let task = Task {
            await coordinator.release(lease)
        }
        playbackReleaseTask = task
        await task.value
    }

    public func makeUtterance(text: String, rate: Float, locale: String) -> AVSpeechUtterance? {
        appleEngine.makeUtterance(text: text, rate: rate, locale: locale)
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

        switch context {
        case .pronunciation(let locale):
            lastActiveEngine = .apple
            guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else {
                isSpeaking = false
                return
            }
            currentUtterance = utterance

            playbackStartTask = Task { @MainActor [weak self] in
                guard let self else { return }
                let acquired = await self.acquirePlaybackLease(generation: currentGeneration)
                guard acquired, !Task.isCancelled, self.requestGeneration == currentGeneration else {
                    if self.requestGeneration == currentGeneration {
                        self.isSpeaking = false
                        self.currentUtterance = nil
                        self.releaseActiveLease()
                    }
                    return
                }

                self.isSpeaking = true
                let isTesting = NSClassFromString("XCTestCase") != nil
                if isTesting {
                    return
                }
                self.appleEngine.speak(text: text, rate: rate, locale: locale) { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self, self.requestGeneration == currentGeneration else { return }
                        self.isSpeaking = false
                        self.currentUtterance = nil
                        self.releaseActiveLease()
                    }
                }
            }

        case .conversation:
            playbackStartTask = Task { @MainActor [weak self] in
                guard let self else { return }
                await self.speakAsync(text: text, context: context, rate: rate)
            }
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

        let startTask = Task { @MainActor [weak self] in
            guard let self else { return false }
            return await self.acquirePlaybackLease(generation: currentGeneration)
        }
        playbackStartTask = Task {
            _ = await startTask.value
        }

        let acquired = await startTask.value
        guard acquired, !Task.isCancelled, self.requestGeneration == currentGeneration else {
            if self.requestGeneration == currentGeneration {
                self.isSpeaking = false
                self.currentUtterance = nil
                self.releaseActiveLease()
            }
            return
        }

        self.isSpeaking = true

        switch context {
        case .conversation(let persona, let locale):
            if let apiKey = resolvedApiKey {
                lastActiveEngine = .gemini
                do {
                    try await geminiEngine.synthesizeAndPlay(text: text, persona: persona, apiKey: apiKey)
                } catch {
                    guard self.requestGeneration == currentGeneration, !Task.isCancelled else {
                        if self.requestGeneration == currentGeneration {
                            self.isSpeaking = false
                            self.currentUtterance = nil
                        }
                        await releaseActiveLeaseAsync()
                        return
                    }
                    LessonPerformanceDiagnostics.event("TTSFallbackToApple", detail: error.localizedDescription)
                    lastActiveEngine = .apple
                    currentUtterance = makeUtterance(text: text, rate: rate, locale: locale)
                    await appleEngine.speakAsync(text: text, rate: rate, locale: locale)
                }
            } else {
                lastActiveEngine = .apple
                currentUtterance = makeUtterance(text: text, rate: rate, locale: locale)
                await appleEngine.speakAsync(text: text, rate: rate, locale: locale)
            }

        case .pronunciation(let locale):
            lastActiveEngine = .apple
            currentUtterance = makeUtterance(text: text, rate: rate, locale: locale)
            await appleEngine.speakAsync(text: text, rate: rate, locale: locale)
        }

        if self.requestGeneration == currentGeneration {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        await releaseActiveLeaseAsync()
    }

    /// Calculates a safety timeout in nanoseconds scaled to speech text length, guaranteeing minimum 25s window.
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

        geminiEngine.stop()
        appleEngine.stop()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume()
        }
        releaseActiveLease()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let box = UtteranceTransferBox(utterance)
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSFinished")
            guard let self = self else { return }
            guard box.utterance === self.currentUtterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
            self.releaseActiveLease()
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let box = UtteranceTransferBox(utterance)
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSCancelled")
            guard let self = self else { return }
            guard box.utterance === self.currentUtterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
            self.releaseActiveLease()
        }
    }
}
