import AVFoundation
import Foundation
import Observation

#if os(iOS)
protocol AudioSessionControlling: AnyObject {
    var category: AVAudioSession.Category { get }
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AVAudioSession: AudioSessionControlling {}
#endif

@MainActor
@Observable
public final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate, TextToSpeechProtocol {
    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool = false
    private var activeContinuation: CheckedContinuation<Void, Never>?
    private var interruptionObserver: (any NSObjectProtocol)?

    private var isAudioSessionConfigured: Bool = false
    #if os(iOS)
    private let audioSession: any AudioSessionControlling

    public override convenience init() {
        self.init(audioSession: AVAudioSession.sharedInstance())
    }

    init(audioSession: any AudioSessionControlling) {
        self.audioSession = audioSession
        super.init()
        synthesizer.delegate = self
        setupInterruptionObserver()
        prewarm()
    }
    #else
    public override init() {
        super.init()
        synthesizer.delegate = self
        prewarm()
    }
    #endif

    public func prewarm() {
        #if os(iOS) && !targetEnvironment(simulator)
        Task.detached(priority: .utility) {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            } catch {
                // Non-fatal pre-warming failure
            }
        }
        #endif
        _ = Self.resolveVoice(for: "en-US")
    }

    #if os(iOS)
    private func ensureAudioSessionActive() {
        #if targetEnvironment(simulator)
        if audioSession is AVAudioSession { return }
        #endif
        let startedAt = CFAbsoluteTimeGetCurrent()
        LessonPerformanceDiagnostics.event("TTSAudioSessionStart")
        do {
            // When speech recognition is active, the session is already .playAndRecord
            // which supports both mic input AND audio output.
            // The speech session already activated the audio session, so we reuse it without
            // calling setActive(true), avoiding redundant main-thread stalls.
            if audioSession.category == .playAndRecord {
                let elapsed = CFAbsoluteTimeGetCurrent() - startedAt
                LessonPerformanceDiagnostics.event(
                    "TTSAudioSessionReady",
                    detail: "elapsedMs=\(Int(elapsed * 1_000)) reusedPlayAndRecord=true"
                )
                return
            }
            if !isAudioSessionConfigured || audioSession.category != .playback {
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                isAudioSessionConfigured = true
            }
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let elapsed = CFAbsoluteTimeGetCurrent() - startedAt
            LessonPerformanceDiagnostics.event(
                "TTSAudioSessionReady",
                detail: "elapsedMs=\(Int(elapsed * 1_000)) reusedPlayAndRecord=false"
            )
        } catch {
            LessonPerformanceDiagnostics.error("tts.audioSession.activate", error: error)
        }
    }
    #endif

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

    public func speak(text: String, rate: Float = 1.0, locale: String = "en-US") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        LessonPerformanceDiagnostics.event("TTSRequest")

        stop()

        let utterance = AVSpeechUtterance(string: trimmed)

        // Scale rate relative to AVSpeechUtteranceDefaultSpeechRate (0.5) so 1.0x = normal speed
        let scaledRate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        if let voice = Self.resolveVoice(for: locale) {
            utterance.voice = voice
        }

#if os(iOS)
        ensureAudioSessionActive()
#endif

        isSpeaking = true
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            self.isSpeaking = true
            return
        }
        synthesizer.speak(utterance)
    }

    public func speakAsync(text: String, rate: Float = 1.0, locale: String = "en-US") async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isSpeaking = false
            return
        }

        stop()

        let utterance = AVSpeechUtterance(string: trimmed)

        // Scale rate relative to AVSpeechUtteranceDefaultSpeechRate (0.5) so 1.0x = normal speed
        let scaledRate = AVSpeechUtteranceDefaultSpeechRate * rate
        utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        utterance.voice = Self.resolveVoice(for: locale)

#if os(iOS)
        ensureAudioSessionActive()
#endif

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            self.isSpeaking = false
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
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume()
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSFinished")
            guard let self = self else { return }
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            LessonPerformanceDiagnostics.event("TTSCancelled")
            guard let self = self else { return }
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
        }
    }
}
