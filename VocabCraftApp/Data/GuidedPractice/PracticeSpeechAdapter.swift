import Foundation

// MARK: - Internal Playback Tracker

private final class PlaybackTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var _hasStarted = false
    private var _hasTimedOut = false

    var isStarted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _hasStarted
    }

    var hasTimedOut: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _hasTimedOut
    }

    func markStarted() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if _hasStarted || _hasTimedOut { return false }
        _hasStarted = true
        return true
    }

    func markTimedOut() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if _hasStarted || _hasTimedOut { return false }
        _hasTimedOut = true
        return true
    }
}

// MARK: - PracticeSpeechAdapter

@MainActor
public final class PracticeSpeechAdapter: PracticeSpeechProtocol {
    private let sttEngine: any STTEngineProtocol
    private let ttsEngine: any TTSEngineProtocol
    private let audioCoordinator: (any AudioSessionCoordinating)?
    private let clock: any PracticeClock
    private let ttsPreparationTimeout: TimeInterval

    // State tracking
    private var activeCaptureTask: Task<Void, Never>?
    private var activePlaybackTask: Task<Void, Never>?
    private var activeTimeoutTask: Task<Void, Never>?
    private var activeCaptureContinuation: AsyncThrowingStream<PracticeSpeechEvent, Error>.Continuation?
    private var activePlaybackContinuation: AsyncThrowingStream<PracticeSpeechEvent, Error>.Continuation?
    private var activeCaptureId: UUID?
    private var activePlaybackId: UUID?
    private var activeLease: AudioSessionLease?

    public private(set) var isCapturing: Bool = false
    public private(set) var isPlaying: Bool = false

    public init(
        sttEngine: any STTEngineProtocol,
        ttsEngine: any TTSEngineProtocol,
        audioCoordinator: (any AudioSessionCoordinating)? = nil,
        clock: any PracticeClock = ProductionPracticeClock(),
        ttsPreparationTimeout: TimeInterval = 20
    ) {
        self.sttEngine = sttEngine
        self.ttsEngine = ttsEngine
        self.audioCoordinator = audioCoordinator
        self.clock = clock
        self.ttsPreparationTimeout = ttsPreparationTimeout
    }

    // MARK: - Capability

    public func capability() -> PracticeCapability {
        let canCapture = sttEngine.isReady
        let canPlay = (ttsEngine as? PlaybackReportingTTSEngineProtocol) != nil && ttsEngine.isReady
        var reasons: [String] = []
        if !canCapture {
            reasons.append("STT engine is not ready")
        }
        if (ttsEngine as? PlaybackReportingTTSEngineProtocol) == nil {
            reasons.append("TTS engine does not support playback reporting")
        } else if !ttsEngine.isReady {
            reasons.append("TTS engine is not ready")
        }
        let unavailableReason = reasons.isEmpty ? nil : reasons.joined(separator: "; ")

        return PracticeCapability(
            canGenerateDialogue: false,
            canAssessUsage: false,
            canCaptureSpeech: canCapture,
            canPlaySpeech: canPlay,
            providerIdentity: "\(sttEngine.engineName)+\(ttsEngine.engineName)",
            unavailableReason: unavailableReason
        )
    }

    // MARK: - Lease Management

    @discardableResult
    private func acquireLease(for intent: AudioSessionIntent) async throws -> AudioSessionLease? {
        guard !Task.isCancelled else { throw CancellationError() }

        if let existing = activeLease {
            if existing.intent == intent {
                return existing
            }
            await audioCoordinator?.release(existing)
            activeLease = nil
        }

        guard !Task.isCancelled else { throw CancellationError() }

        if let coordinator = audioCoordinator {
            let lease = try await coordinator.acquire(intent)
            guard !Task.isCancelled,
                  (intent == .speechCapture && isCapturing) || (intent == .playback && isPlaying) else {
                await coordinator.release(lease)
                throw CancellationError()
            }
            activeLease = lease
            return lease
        }
        return nil
    }

    private func releaseLease(_ lease: AudioSessionLease? = nil) async {
        if let leaseToRelease = lease {
            if activeLease?.id == leaseToRelease.id {
                activeLease = nil
            }
            await audioCoordinator?.release(leaseToRelease)
        } else if let current = activeLease {
            activeLease = nil
            await audioCoordinator?.release(current)
        }
    }

    // MARK: - Capture

    public func capture(locale: String) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        let previousCaptureTask = activeCaptureTask
        let previousPlaybackTask = activePlaybackTask
        let captureId = UUID()
        self.activeCaptureId = captureId

        return AsyncThrowingStream { continuation in
            let captureTask = Task { @MainActor [weak self] in
                guard let self else { return }

                // 1. Stop existing playback and await prior playback task
                await self.stopPreviousPlayback(previousPlaybackTask)

                // 2. Stop prior capture and await prior capture task
                await self.stopPreviousCapture(previousCaptureTask)

                guard !Task.isCancelled, self.activeCaptureId == captureId else {
                    continuation.yield(.captureStopped)
                    continuation.finish()
                    return
                }

                await self.runCapture(
                    captureId: captureId,
                    locale: locale,
                    continuation: continuation
                )
            }

            self.activeCaptureTask = captureTask
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.stopCaptureInternal(for: captureId)
                }
            }
        }
    }

    private func stopPreviousCapture(_ previousTask: Task<Void, Never>?) async {
        if isCapturing {
            isCapturing = false
            sttEngine.stopRecognition()
            if let cont = activeCaptureContinuation {
                activeCaptureContinuation = nil
                cont.yield(.captureStopped)
                cont.finish()
            }
        }
        previousTask?.cancel()
        _ = await previousTask?.result
    }

    private func stopPreviousPlayback(_ previousTask: Task<Void, Never>?) async {
        if isPlaying {
            isPlaying = false
            activeTimeoutTask?.cancel()
            activeTimeoutTask = nil
            ttsEngine.stop()
            if let cont = activePlaybackContinuation {
                activePlaybackContinuation = nil
                cont.finish()
            }
        }
        previousTask?.cancel()
        _ = await previousTask?.result
    }

    private func runCapture(
        captureId: UUID,
        locale: String,
        continuation: AsyncThrowingStream<PracticeSpeechEvent, Error>.Continuation
    ) async {
        guard !Task.isCancelled, self.activeCaptureId == captureId else {
            continuation.yield(.captureStopped)
            continuation.finish()
            return
        }

        self.isCapturing = true
        self.activeCaptureContinuation = continuation

        var capturedLease: AudioSessionLease?
        do {
            capturedLease = try await self.acquireLease(for: .speechCapture)
        } catch is CancellationError {
            self.cleanupCapture(for: captureId)
            continuation.yield(.captureStopped)
            continuation.finish()
            return
        } catch {
            self.cleanupCapture(for: captureId)
            continuation.yield(.failed(PracticeFailure(code: .audio, message: error.localizedDescription)))
            continuation.yield(.captureStopped)
            continuation.finish()
            return
        }

        continuation.yield(.captureStarted)

        var lastCapturedText = ""
        var wasInterrupted = false

        let sttStream = self.sttEngine.startRecognition(locale: locale)

        do {
            for try await text in sttStream {
                guard self.isCapturing, self.activeCaptureId == captureId else {
                    wasInterrupted = true
                    break
                }
                lastCapturedText = text
                continuation.yield(.transcript(text: text, reliability: .needsConfirmation))
            }

            let trimmed = lastCapturedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !wasInterrupted, self.isCapturing, self.activeCaptureId == captureId {
                if !trimmed.isEmpty {
                    continuation.yield(.transcript(text: trimmed, reliability: .usable))
                } else {
                    continuation.yield(.transcript(text: trimmed, reliability: .needsConfirmation))
                }
            } else if !trimmed.isEmpty {
                continuation.yield(.transcript(text: trimmed, reliability: .needsConfirmation))
            }
        } catch {
            continuation.yield(.failed(PracticeFailure(code: .audio, message: error.localizedDescription)))
        }

        if self.activeCaptureId == captureId {
            self.cleanupCapture(for: captureId)
            continuation.yield(.captureStopped)
            continuation.finish()
        }
        await self.releaseLease(capturedLease)
    }

    private func cleanupCapture(for id: UUID) {
        guard activeCaptureId == id else { return }
        activeCaptureId = nil
        isCapturing = false
        activeCaptureContinuation = nil
    }

    public func stopCapture() {
        stopCaptureInternal(for: nil)
    }

    private func stopCaptureInternal(for id: UUID?) {
        if let id, activeCaptureId != id { return }
        let wasCapturing = isCapturing
        isCapturing = false
        activeCaptureId = nil
        if wasCapturing {
            sttEngine.stopRecognition()
        }
        if let cont = activeCaptureContinuation {
            activeCaptureContinuation = nil
            cont.yield(.captureStopped)
            cont.finish()
        }
        activeCaptureTask?.cancel()
    }

    // MARK: - Playback

    public func play(text: String, voice: VoiceConfiguration) -> AsyncThrowingStream<PracticeSpeechEvent, Error> {
        let previousCaptureTask = activeCaptureTask
        let previousPlaybackTask = activePlaybackTask
        let playbackId = UUID()
        self.activePlaybackId = playbackId

        return AsyncThrowingStream { continuation in
            let playTask = Task { @MainActor [weak self] in
                guard let self else { return }

                // 1. Verify capability
                guard let reportingTTS = self.ttsEngine as? PlaybackReportingTTSEngineProtocol,
                      self.ttsEngine.isReady else {
                    continuation.yield(.failed(PracticeFailure(code: .capability, message: "TTS engine does not support playback reporting or is not ready")))
                    continuation.finish()
                    return
                }

                // 2. Stop capture before playback starts and await prior capture
                await self.stopPreviousCapture(previousCaptureTask)

                // 3. Stop existing playback and await prior playback
                await self.stopPreviousPlayback(previousPlaybackTask)

                guard !Task.isCancelled, self.activePlaybackId == playbackId else {
                    continuation.finish()
                    return
                }

                await self.runPlayback(
                    playbackId: playbackId,
                    reportingTTS: reportingTTS,
                    text: text,
                    voice: voice,
                    continuation: continuation
                )
            }

            self.activePlaybackTask = playTask
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.stopPlaybackInternal(for: playbackId)
                }
            }
        }
    }

    private func runPlayback(
        playbackId: UUID,
        reportingTTS: PlaybackReportingTTSEngineProtocol,
        text: String,
        voice: VoiceConfiguration,
        continuation: AsyncThrowingStream<PracticeSpeechEvent, Error>.Continuation
    ) async {
        guard !Task.isCancelled, self.activePlaybackId == playbackId else {
            continuation.finish()
            return
        }

        self.isPlaying = true
        self.activePlaybackContinuation = continuation

        // Acquire playback audio lease
        var playbackLease: AudioSessionLease?
        do {
            playbackLease = try await self.acquireLease(for: .playback)
        } catch is CancellationError {
            self.cleanupPlayback(for: playbackId)
            continuation.finish()
            return
        } catch {
            self.cleanupPlayback(for: playbackId)
            continuation.yield(.failed(PracticeFailure(code: .audio, message: error.localizedDescription)))
            continuation.finish()
            return
        }

        let tracker = PlaybackTracker()

        // Preparation timeout task
        let timeoutTask = Task { [clock = self.clock, timeout = self.ttsPreparationTimeout, weak self] in
            do {
                try await clock.sleep(for: .seconds(timeout))
                guard !Task.isCancelled else { return }
                if tracker.markTimedOut() {
                    await MainActor.run {
                        guard let self, self.activePlaybackId == playbackId else { return }
                        self.activePlaybackTask?.cancel()
                        self.ttsEngine.stop()
                        continuation.yield(.failed(PracticeFailure(code: .timeout, message: "TTS preparation timed out")))
                        continuation.finish()
                        self.cleanupPlayback(for: playbackId)
                    }
                }
            } catch {
                // Sleep cancelled
            }
        }
        self.activeTimeoutTask = timeoutTask

        // Synthesize and play
        do {
            try await reportingTTS.synthesizeAndPlay(text: text, voice: voice) {
                if tracker.markStarted() {
                    timeoutTask.cancel()
                    continuation.yield(.playbackStarted)
                }
            }

            timeoutTask.cancel()

            if !tracker.hasTimedOut, self.isPlaying, self.activePlaybackId == playbackId {
                self.cleanupPlayback(for: playbackId)
                continuation.yield(.playbackFinished)
                continuation.finish()
            }
        } catch is CancellationError {
            // Cancelled by timeout or stop
        } catch {
            timeoutTask.cancel()
            if !tracker.hasTimedOut, self.isPlaying, self.activePlaybackId == playbackId {
                self.cleanupPlayback(for: playbackId)
                continuation.yield(.failed(PracticeFailure(code: .audio, message: error.localizedDescription)))
                continuation.finish()
            }
        }

        await self.releaseLease(playbackLease)
    }

    private func cleanupPlayback(for id: UUID) {
        guard activePlaybackId == id else { return }
        activePlaybackId = nil
        isPlaying = false
        activePlaybackContinuation = nil
    }

    private func stopPlaybackInternal(for id: UUID? = nil) {
        if let id, activePlaybackId != id { return }
        let wasPlaying = isPlaying
        isPlaying = false
        activePlaybackId = nil
        activeTimeoutTask?.cancel()
        activeTimeoutTask = nil
        if wasPlaying {
            ttsEngine.stop()
        }
        if let cont = activePlaybackContinuation {
            activePlaybackContinuation = nil
            cont.finish()
        }
        activePlaybackTask?.cancel()
    }

    // MARK: - Lifecycle

    public func stop() async {
        stopCapture()
        await stopPreviousCapture(activeCaptureTask)
        activeCaptureTask = nil

        stopPlaybackInternal()
        await stopPreviousPlayback(activePlaybackTask)
        activePlaybackTask = nil

        await releaseLease()
    }
}
