import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
public final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate, TextToSpeechProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool = false
    private var activeContinuation: CheckedContinuation<Void, Never>?
    private var interruptionObserver: (any NSObjectProtocol)?

    public let audioSessionCoordinator: any AudioSessionCoordinating
    private(set) var activeLease: AudioSessionLease?
    private(set) var playbackStartTask: Task<Void, Never>?
    private(set) var playbackReleaseTask: Task<Void, Never>?
    private(set) var currentUtterance: AVSpeechUtterance?
    private var requestGeneration: UInt = 0

    public override convenience init() {
        self.init(audioSessionCoordinator: AudioSessionCoordinator())
    }

    public init(audioSessionCoordinator: any AudioSessionCoordinating) {
        self.audioSessionCoordinator = audioSessionCoordinator
        super.init()
        synthesizer.delegate = self
        setupInterruptionObserver()
        prewarm()
    }

    public func prewarm() {
        _ = Self.resolveVoice(for: "en-US")
    }

    private func setupInterruptionObserver() {
        #if os(iOS) && !targetEnvironment(simulator)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .began {
                Task { @MainActor [weak self] in
                    self?.stop()
                }
            }
        }
        #endif
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

    private func makeUtterance(text: String, rate: Float, locale: String) -> AVSpeechUtterance? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let utterance = AVSpeechUtterance(string: trimmed)

        // Scale rate relative to AVSpeechUtteranceDefaultSpeechRate (0.5) so 1.0x = normal speed
        let scaledRate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        if let voice = Self.resolveVoice(for: locale) {
            utterance.voice = voice
        }
        return utterance
    }

    public func speak(text: String, rate: Float = 1.0, locale: String = "en-US") {
        guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else { return }
        LessonPerformanceDiagnostics.event("TTSRequest")

        stop()

        isSpeaking = true
        currentUtterance = utterance
        requestGeneration += 1
        let currentGeneration = requestGeneration

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
            self.synthesizer.speak(utterance)
        }
    }

    public func speakAsync(text: String, rate: Float = 1.0, locale: String = "en-US") async {
        guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else {
            isSpeaking = false
            currentUtterance = nil
            return
        }

        stop()

        isSpeaking = true
        currentUtterance = utterance
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

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            if self.requestGeneration == currentGeneration {
                self.isSpeaking = false
                self.currentUtterance = nil
                self.releaseActiveLease()
            }
            return
        }

        let timeoutTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 8_000_000_000)
            } catch {
                return
            }
            guard let self = self else { return }
            if self.activeContinuation != nil {
                if self.synthesizer.isSpeaking {
                    self.synthesizer.stopSpeaking(at: .immediate)
                }
                self.isSpeaking = false
                self.currentUtterance = nil
                self.releaseActiveLease()
                if let continuation = self.activeContinuation {
                    self.activeContinuation = nil
                    continuation.resume()
                }
            }
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.activeContinuation = continuation
            self.isSpeaking = true
            self.synthesizer.speak(utterance)
        }

        timeoutTask.cancel()
    }

    public func stop() {
        playbackStartTask?.cancel()
        playbackStartTask = nil
        requestGeneration += 1

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
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSFinished")
            guard let self = self else { return }
            guard utterance === self.currentUtterance else { return }
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
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSCancelled")
            guard let self = self else { return }
            guard utterance === self.currentUtterance else { return }
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
