import AVFoundation
import Foundation
import Observation

public enum SpeechPlaybackCompletion: Equatable, Sendable {
    case finished
    case cancelled
    case failed
}

@MainActor
public protocol TextToSpeechSynthesizing: AnyObject {
    var delegate: (any AVSpeechSynthesizerDelegate)? { get set }
    var isSpeaking: Bool { get }
    func speak(_ utterance: AVSpeechUtterance)
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool
}

@MainActor
final class DefaultTextToSpeechSynthesizer: TextToSpeechSynthesizing {
    private let synthesizer = AVSpeechSynthesizer()

    var delegate: (any AVSpeechSynthesizerDelegate)? {
        get { synthesizer.delegate }
        set { synthesizer.delegate = newValue }
    }

    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    func speak(_ utterance: AVSpeechUtterance) {
        synthesizer.speak(utterance)
    }

    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        synthesizer.stopSpeaking(at: boundary)
    }
}

@MainActor
@Observable
public final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate, TextToSpeechProtocol {
    private let synthesizer: any TextToSpeechSynthesizing
    public var playbackTimeout: Duration = .seconds(30)
    public var isSpeaking: Bool = false
    private var activeContinuation: CheckedContinuation<SpeechPlaybackCompletion, Never>?
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

    public convenience init(audioSessionCoordinator: any AudioSessionCoordinating) {
        self.init(
            audioSessionCoordinator: audioSessionCoordinator,
            synthesizer: DefaultTextToSpeechSynthesizer()
        )
    }

    public init(
        audioSessionCoordinator: any AudioSessionCoordinating,
        synthesizer: any TextToSpeechSynthesizing
    ) {
        self.audioSessionCoordinator = audioSessionCoordinator
        self.synthesizer = synthesizer
        super.init()
        self.synthesizer.delegate = self
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
        _ = await speakWithCompletion(text: text, rate: rate, locale: locale)
    }

    public func speakWithCompletion(
        text: String,
        rate: Float = 1.0,
        locale: String = "en-US"
    ) async -> SpeechPlaybackCompletion {
        guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else {
            isSpeaking = false
            currentUtterance = nil
            return .failed
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
        if Task.isCancelled || self.requestGeneration != currentGeneration {
            if self.requestGeneration == currentGeneration {
                self.isSpeaking = false
                self.currentUtterance = nil
                _ = self.releaseActiveLease()
                await self.playbackReleaseTask?.value
            }
            return .cancelled
        }

        guard acquired else {
            if self.requestGeneration == currentGeneration {
                self.isSpeaking = false
                self.currentUtterance = nil
                _ = self.releaseActiveLease()
                await self.playbackReleaseTask?.value
            }
            return .failed
        }

        self.isSpeaking = true

        let timeoutDuration = playbackTimeout
        let timeoutTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: timeoutDuration)
            } catch {
                return
            }
            guard let self = self else { return }
            guard self.requestGeneration == currentGeneration else { return }
            if self.activeContinuation != nil {
                if self.synthesizer.isSpeaking {
                    _ = self.synthesizer.stopSpeaking(at: .immediate)
                }
                self.isSpeaking = false
                self.currentUtterance = nil
                self.releaseActiveLease()
                if let continuation = self.activeContinuation {
                    self.activeContinuation = nil
                    continuation.resume(returning: .failed)
                }
            }
        }

        let result = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                self.activeContinuation = continuation
                self.isSpeaking = true
                self.synthesizer.speak(utterance)
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                guard let self, self.requestGeneration == currentGeneration else { return }
                self.stop()
            }
        }

        timeoutTask.cancel()
        if self.requestGeneration == currentGeneration {
            _ = releaseActiveLease()
            await playbackReleaseTask?.value
        } else {
            await playbackReleaseTask?.value
        }
        return result
    }

    public func stop() {
        playbackStartTask?.cancel()
        playbackStartTask = nil
        requestGeneration += 1

        if synthesizer.isSpeaking {
            _ = synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume(returning: .cancelled)
        }
        releaseActiveLease()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSFinished")
            guard let self = self else { return }
            guard let currentUtterance = self.currentUtterance,
                  ObjectIdentifier(currentUtterance) == utteranceID else {
                return
            }
            self.currentUtterance = nil
            self.isSpeaking = false
            self.releaseActiveLease()
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(returning: .finished)
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSCancelled")
            guard let self = self else { return }
            guard let currentUtterance = self.currentUtterance,
                  ObjectIdentifier(currentUtterance) == utteranceID else {
                return
            }
            self.currentUtterance = nil
            self.isSpeaking = false
            self.releaseActiveLease()
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(returning: .cancelled)
            }
        }
    }
}
