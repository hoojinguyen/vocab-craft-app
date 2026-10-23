import Foundation
import Testing
@testable import VocabCraftApp

// MARK: - Mocks

private final class PracticeTestSTTEngine: STTEngineProtocol, @unchecked Sendable {
    var engineName: String = "Mock STT"
    var isReady: Bool = true
    var onStartRecognition: ((String) -> Void)?
    var onStopRecognition: (() -> Void)?
    var streamContinuation: AsyncThrowingStream<String, Error>.Continuation?

    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        onStartRecognition?(locale)
        return AsyncThrowingStream { continuation in
            self.streamContinuation = continuation
        }
    }

    func stopRecognition() {
        onStopRecognition?()
        streamContinuation?.finish()
        streamContinuation = nil
    }
}

private final class PracticeTestReportingTTSEngine: PlaybackReportingTTSEngineProtocol, @unchecked Sendable {
    var engineName: String = "Mock Reporting TTS"
    var isReady: Bool = true
    var stopCalled: Bool = false
    var shouldFailBeforePlayback: Error?
    var shouldFailAfterPlayback: Error?
    var playbackStartDelay: Duration?
    var playbackDuration: Duration?
    var manualClock: ManualPracticeClock?
    var onStop: (() -> Void)?

    func synthesizeAndPlay(
        text: String,
        voice: VoiceConfiguration,
        onPlaybackStarted: @escaping @Sendable () -> Void
    ) async throws {
        if let error = shouldFailBeforePlayback {
            throw error
        }

        if let delay = playbackStartDelay, let clock = manualClock {
            try await clock.sleep(for: delay)
        }

        onPlaybackStarted()

        if let error = shouldFailAfterPlayback {
            throw error
        }

        if let duration = playbackDuration, let clock = manualClock {
            try await clock.sleep(for: duration)
        }
    }

    func stop() {
        stopCalled = true
        onStop?()
    }
}

private final class PracticeTestNonReportingTTSEngine: TTSEngineProtocol, @unchecked Sendable {
    var engineName: String = "Mock Non-Reporting TTS"
    var isReady: Bool = true
    var stopCalled: Bool = false

    func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
    }

    func stop() {
        stopCalled = true
    }
}

private actor PracticeTestAudioCoordinator: AudioSessionCoordinating {
    private var activeLeases: [UUID: AudioSessionLease] = [:]
    private var currentGeneration: UInt = 0

    var activeLeaseCount: Int {
        activeLeases.count
    }

    var leases: [AudioSessionLease] {
        Array(activeLeases.values)
    }

    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        currentGeneration += 1
        let lease = AudioSessionLease(id: UUID(), generation: currentGeneration, intent: intent)
        activeLeases[lease.id] = lease
        return lease
    }

    func release(_ lease: AudioSessionLease) async {
        activeLeases.removeValue(forKey: lease.id)
    }

    nonisolated var events: AsyncStream<AudioSessionEvent> {
        AsyncStream { _ in }
    }
}

// MARK: - Test Suite

@Suite("PracticeSpeechAdapter Tests")
struct PracticeSpeechAdapterTests {
    @Test("captureStopsBeforeActualPlayback")
    @MainActor
    func captureStopsBeforeActualPlayback() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let coordinator = PracticeTestAudioCoordinator()
        let clock = ManualPracticeClock()
        tts.manualClock = clock
        tts.playbackStartDelay = .seconds(1)

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            audioCoordinator: coordinator,
            clock: clock,
            ttsPreparationTimeout: 20
        )

        final class EventCollector: @unchecked Sendable {
            var events: [PracticeSpeechEvent] = []
            var preparationFailureEvents: [PracticeSpeechEvent] = []
        }
        let collector = EventCollector()

        let captureStream = adapter.capture(locale: "en-US")
        let captureTask = Task { @MainActor in
            do {
                for try await event in captureStream {
                    collector.events.append(event)
                }
            } catch {
                collector.events.append(.failed(PracticeFailure(code: .audio, message: error.localizedDescription)))
            }
        }

        // Allow capture to start
        await Task.yield()

        let voice = VoiceConfiguration(gender: .female, style: .friendly)
        let playStream = adapter.play(text: "Hello learner", voice: voice)
        let playTask = Task { @MainActor in
            do {
                for try await event in playStream {
                    collector.events.append(event)
                }
            } catch {
                collector.events.append(.failed(PracticeFailure(code: .audio, message: error.localizedDescription)))
            }
        }

        // Wait for preparation timeout and playback delay sleepers
        await clock.waitForSleepers(count: 2)
        clock.advance(by: .seconds(2))

        _ = await playTask.result
        _ = await captureTask.result

        let events = collector.events
        let stopped = try #require(events.firstIndex(of: .captureStopped))
        let started = try #require(events.firstIndex(of: .playbackStarted))
        #expect(stopped < started)

        // Preparation failure test verification
        let failingTTS = PracticeTestReportingTTSEngine()
        failingTTS.shouldFailBeforePlayback = PracticeFailure(code: .audio, message: "Synthesis error")
        let failingAdapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: failingTTS,
            audioCoordinator: coordinator,
            clock: clock,
            ttsPreparationTimeout: 20
        )
        let failureStream = failingAdapter.play(text: "Fail test", voice: voice)
        for try await event in failureStream {
            collector.preparationFailureEvents.append(event)
        }
        let preparationFailureEvents = collector.preparationFailureEvents
        #expect(preparationFailureEvents.contains(.playbackStarted) == false)
    }

    @Test("Preparation failure does not emit playbackStarted")
    @MainActor
    func test_preparationFailure_doesNotEmitPlaybackStarted() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        tts.shouldFailBeforePlayback = URLError(.networkConnectionLost)
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            clock: clock,
            ttsPreparationTimeout: 20
        )

        var events: [PracticeSpeechEvent] = []
        let voice = VoiceConfiguration(gender: .male, style: .friendly)
        for try await event in adapter.play(text: "Test failure", voice: voice) {
            events.append(event)
        }

        #expect(!events.contains(.playbackStarted))
        #expect(events.contains(where: {
            if case .failed = $0 { return true }
            return false
        }))
    }

    @Test("PlaybackStarted is emitted only once")
    @MainActor
    func test_playbackStarted_emittedOnlyOnce() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            clock: clock,
            ttsPreparationTimeout: 20
        )

        var events: [PracticeSpeechEvent] = []
        let voice = VoiceConfiguration(gender: .female, style: .expressive)
        for try await event in adapter.play(text: "Hello", voice: voice) {
            events.append(event)
        }

        let startedCount = events.filter { $0 == .playbackStarted }.count
        #expect(startedCount == 1)
        #expect(events.contains(.playbackFinished))
    }

    @Test("TTS preparation timeout enforces 20s and cancels when started")
    @MainActor
    func test_ttsPreparationTimeout_enforcedAndCancelledWhenStarted() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let clock = ManualPracticeClock()
        tts.manualClock = clock
        tts.playbackStartDelay = .seconds(25) // Takes 25s, should time out at 20s

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            clock: clock,
            ttsPreparationTimeout: 20
        )

        var events: [PracticeSpeechEvent] = []
        let voice = VoiceConfiguration(gender: .female, style: .friendly)

        let task = Task { @MainActor in
            for try await event in adapter.play(text: "Timeout test", voice: voice) {
                events.append(event)
            }
        }

        // Wait for both sleepers: timeoutTask (20s) and playbackStartDelay (25s)
        await clock.waitForSleepers(count: 2)
        clock.advance(by: .seconds(20))

        _ = await task.result

        #expect(!events.contains(.playbackStarted))
        #expect(events.contains(.failed(PracticeFailure(code: .timeout, message: "TTS preparation timed out"))))
    }

    @Test("Long playback after started is not cut off by preparation timer")
    @MainActor
    func test_longPlayback_notCutOffByPreparationTimer() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let clock = ManualPracticeClock()
        tts.manualClock = clock
        tts.playbackStartDelay = .seconds(2)
        tts.playbackDuration = .seconds(30) // Long playback > 20s

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            clock: clock,
            ttsPreparationTimeout: 20
        )

        var events: [PracticeSpeechEvent] = []
        let voice = VoiceConfiguration(gender: .male, style: .authoritative)

        let task = Task { @MainActor in
            for try await event in adapter.play(text: "Long speech text", voice: voice) {
                events.append(event)
            }
        }

        // Wait for timeoutTask and playbackStartDelay
        await clock.waitForSleepers(count: 2)
        clock.advance(by: .seconds(2)) // Start playback

        // Allow main actor loop to process onPlaybackStarted callback
        while !events.contains(.playbackStarted) {
            await Task.yield()
        }

        #expect(events.contains(.playbackStarted))

        // Wait for playback duration sleeper (30s)
        await clock.waitForSleepers(count: 1)

        // Advance past 20s preparation timeout (total 25s elapsed)
        clock.advance(by: .seconds(23))
        await Task.yield()

        #expect(!events.contains(.playbackFinished))

        // Advance remaining 7s to complete 30s playback
        clock.advance(by: .seconds(7))

        _ = await task.result

        #expect(events.contains(.playbackFinished))
    }

    @Test("Cancel releases mic, TTS, and audio lease")
    @MainActor
    func test_cancel_releasesResourcesCleanly() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let coordinator = PracticeTestAudioCoordinator()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            audioCoordinator: coordinator,
            clock: clock
        )

        let captureStream = adapter.capture(locale: "en-US")
        var iterator = captureStream.makeAsyncIterator()
        let event = try await iterator.next()
        #expect(event == .captureStarted)

        let countBefore = await coordinator.activeLeaseCount
        #expect(countBefore == 1)

        await adapter.stop()

        let countAfter = await coordinator.activeLeaseCount
        #expect(countAfter == 0)
    }

    @Test("Playback started then failed preserves exposure candidate")
    @MainActor
    func test_playbackStartedThenFailed_preservesStartedEvent() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        tts.shouldFailAfterPlayback = URLError(.timedOut)
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            clock: clock
        )

        var events: [PracticeSpeechEvent] = []
        let voice = VoiceConfiguration(gender: .female, style: .friendly)
        for try await event in adapter.play(text: "Exposure test", voice: voice) {
            events.append(event)
        }

        let startedIndex = events.firstIndex(of: .playbackStarted)
        let failedIndex = events.firstIndex(where: {
            if case .failed = $0 { return true }
            return false
        })

        #expect(startedIndex != nil)
        #expect(failedIndex != nil)
        if let startedIndex, let failedIndex {
            #expect(startedIndex < failedIndex)
        }
    }

    @Test("Stop awaits completion before next capture")
    @MainActor
    func test_stopAwaitsBeforeNextCapture() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let coordinator = PracticeTestAudioCoordinator()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            audioCoordinator: coordinator,
            clock: clock
        )

        let captureStream = adapter.capture(locale: "en-US")
        var iterator = captureStream.makeAsyncIterator()
        let event = try await iterator.next()
        #expect(event == .captureStarted)

        await adapter.stop()
        let count = await coordinator.activeLeaseCount
        #expect(count == 0)

        var restartedEvents: [PracticeSpeechEvent] = []
        let restartStream = adapter.capture(locale: "en-US")
        let restartTask = Task { @MainActor in
            for try await event in restartStream {
                restartedEvents.append(event)
                if event == .captureStarted {
                    adapter.stopCapture()
                }
            }
        }
        _ = await restartTask.result

        #expect(restartedEvents.contains(.captureStarted))
        #expect(restartedEvents.contains(.captureStopped))
    }

    @Test("STT partials are needsConfirmation and clean finish promotes non-empty to usable")
    @MainActor
    func test_sttTranscriptsReliability() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            clock: clock
        )

        var events: [PracticeSpeechEvent] = []
        let stream = adapter.capture(locale: "en-US")

        let task = Task { @MainActor in
            for try await event in stream {
                events.append(event)
            }
        }
        await Task.yield()

        // Yield partial transcripts
        stt.streamContinuation?.yield("Hel")
        stt.streamContinuation?.yield("Hello")
        stt.streamContinuation?.yield("Hello world")
        // End cleanly
        stt.streamContinuation?.finish()

        _ = await task.result

        let partials = events.compactMap { event -> (String, PracticeTranscriptReliability)? in
            if case let .transcript(text, reliability) = event {
                return (text, reliability)
            }
            return nil
        }

        #expect(partials.contains(where: { $0.0 == "Hel" && $0.1 == .needsConfirmation }))
        #expect(partials.contains(where: { $0.0 == "Hello" && $0.1 == .needsConfirmation }))
        #expect(partials.last?.0 == "Hello world")
        #expect(partials.last?.1 == .usable)
    }

    @Test("STT empty text or interruption retains needsConfirmation")
    @MainActor
    func test_sttEmptyOrInterrupted_retainsNeedsConfirmation() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            clock: clock
        )

        var events: [PracticeSpeechEvent] = []
        let stream = adapter.capture(locale: "en-US")

        let task = Task { @MainActor in
            for try await event in stream {
                events.append(event)
            }
        }
        await Task.yield()

        stt.streamContinuation?.yield("   ")
        stt.streamContinuation?.finish()

        _ = await task.result

        let transcripts = events.compactMap { event -> PracticeTranscriptReliability? in
            if case let .transcript(_, reliability) = event { return reliability }
            return nil
        }
        #expect(transcripts.allSatisfy { $0 == .needsConfirmation })
    }

    @Test("Capability reflects reporting support and engine readiness")
    @MainActor
    func test_capabilityReflectsReadinessAndReporting() {
        let stt = PracticeTestSTTEngine()
        stt.isReady = true

        let reportingTTS = PracticeTestReportingTTSEngine()
        reportingTTS.isReady = true

        let clock = ManualPracticeClock()
        let adapter1 = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: reportingTTS,
            clock: clock
        )
        let cap1 = adapter1.capability()
        #expect(cap1.canCaptureSpeech == true)
        #expect(cap1.canPlaySpeech == true)

        let nonReportingTTS = PracticeTestNonReportingTTSEngine()
        let adapter2 = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: nonReportingTTS,
            clock: clock
        )
        let cap2 = adapter2.capability()
        #expect(cap2.canCaptureSpeech == true)
        #expect(cap2.canPlaySpeech == false)

        stt.isReady = false
        reportingTTS.isReady = false
        let adapter3 = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: reportingTTS,
            clock: clock
        )
        let cap3 = adapter3.capability()
        #expect(cap3.canCaptureSpeech == false)
        #expect(cap3.canPlaySpeech == false)
    }

    @Test("Consecutive capture calls seamlessly transition without state clobbering or cancellation")
    @MainActor
    func test_consecutiveCapture_transitionsCleanly() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let coordinator = PracticeTestAudioCoordinator()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            audioCoordinator: coordinator,
            clock: clock
        )

        final class SafeEvents: @unchecked Sendable {
            var events: [PracticeSpeechEvent] = []
        }

        // Start first capture
        let safeEvents1 = SafeEvents()
        let stream1 = adapter.capture(locale: "en-US")
        let task1 = Task { @MainActor in
            for try await event in stream1 {
                safeEvents1.events.append(event)
            }
        }

        // Wait until first capture has started
        while !safeEvents1.events.contains(.captureStarted) {
            await Task.yield()
        }

        // Immediately start second capture while first is still active
        let safeEvents2 = SafeEvents()
        let stream2 = adapter.capture(locale: "en-US")
        let task2 = Task { @MainActor in
            for try await event in stream2 {
                safeEvents2.events.append(event)
            }
        }

        // Wait until second capture has started
        while !safeEvents2.events.contains(.captureStarted) {
            await Task.yield()
        }

        // First capture should have stopped cleanly without failure
        _ = await task1.result
        #expect(safeEvents1.events.contains(.captureStarted))
        #expect(safeEvents1.events.contains(.captureStopped))
        #expect(!safeEvents1.events.contains(where: {
            if case .failed = $0 { return true }
            return false
        }))

        // Second capture is running properly without failure
        #expect(safeEvents2.events.contains(.captureStarted))
        #expect(!safeEvents2.events.contains(where: {
            if case .failed = $0 { return true }
            return false
        }))

        // Stop adapter
        adapter.stopCapture()
        _ = await task2.result
        #expect(safeEvents2.events.contains(.captureStopped))
    }

    @Test("Cancellation during capture setup aborts before lease acquisition or engine start")
    @MainActor
    func test_cancellationDuringCaptureSetup_abortsCleanly() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let coordinator = PracticeTestAudioCoordinator()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            audioCoordinator: coordinator,
            clock: clock
        )

        final class SafeEvents: @unchecked Sendable {
            var events: [PracticeSpeechEvent] = []
        }

        // Start first capture
        let safeEvents1 = SafeEvents()
        let stream1 = adapter.capture(locale: "en-US")
        let task1 = Task { @MainActor in
            for try await event in stream1 {
                safeEvents1.events.append(event)
            }
        }

        while !safeEvents1.events.contains(.captureStarted) {
            await Task.yield()
        }

        // Start second capture, but immediately stop capture while it is still in setup
        let safeEvents2 = SafeEvents()
        let stream2 = adapter.capture(locale: "en-US")
        let task2 = Task { @MainActor in
            for try await event in stream2 {
                safeEvents2.events.append(event)
            }
        }

        // Cancel while stream2 is still in setup
        adapter.stopCapture()

        _ = await task1.result
        _ = await task2.result

        #expect(safeEvents2.events.contains(.captureStopped))
        #expect(!safeEvents2.events.contains(.captureStarted))
        #expect(adapter.isCapturing == false)
    }

    @Test("Cancellation during playback setup aborts before synthesis or lease acquisition")
    @MainActor
    func test_cancellationDuringPlaybackSetup_abortsCleanly() async throws {
        let stt = PracticeTestSTTEngine()
        let tts = PracticeTestReportingTTSEngine()
        let coordinator = PracticeTestAudioCoordinator()
        let clock = ManualPracticeClock()

        let adapter = PracticeSpeechAdapter(
            sttEngine: stt,
            ttsEngine: tts,
            audioCoordinator: coordinator,
            clock: clock
        )

        final class SafeEvents: @unchecked Sendable {
            var events: [PracticeSpeechEvent] = []
        }

        // Start capture so playback has to wait for capture to stop
        let stream1 = adapter.capture(locale: "en-US")
        let task1 = Task { @MainActor in
            for try await _ in stream1 {}
        }
        await Task.yield()

        // Start playback and immediately stop before capture teardown finishes
        let safeEvents2 = SafeEvents()
        let voice = VoiceConfiguration(gender: .female, style: .friendly)
        let stream2 = adapter.play(text: "Hello", voice: voice)
        let task2 = Task { @MainActor in
            for try await event in stream2 {
                safeEvents2.events.append(event)
            }
        }

        // Stop playback during setup
        await adapter.stop()

        _ = await task1.result
        _ = await task2.result

        #expect(!safeEvents2.events.contains(.playbackStarted))
        #expect(adapter.isPlaying == false)
    }
}
