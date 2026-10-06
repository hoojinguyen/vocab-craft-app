import AVFoundation
import Testing
@testable import VocabCraftApp

private final class CallbackTracker: @unchecked Sendable {
    var wasCalled = false
}

@Suite("Apple Enhanced TTS Engine Tests")
struct AppleEnhancedTTSEngineTests {
    @Test("Verify makeUtterance applies warm pitch and gentle acoustic delays")
    @MainActor
    func test_makeUtterance_prosodyParameters() {
        let engine = AppleEnhancedTTSEngine()
        let utterance = engine.makeUtterance(text: "Hello world", rate: 1.0, locale: "en-US")

        #expect(utterance != nil)
        if let utterance {
            #expect(utterance.pitchMultiplier >= 1.04 && utterance.pitchMultiplier <= 1.08)
            #expect(utterance.pitchMultiplier == 1.06)
            #expect(utterance.preUtteranceDelay == 0.05)
            #expect(utterance.postUtteranceDelay == 0.10)
        }
    }

    @Test("Verify speech rate scaling and min/max clamping")
    @MainActor
    func test_makeUtterance_rateScalingAndClamping() {
        let engine = AppleEnhancedTTSEngine()
        let baseRate = AVSpeechUtteranceDefaultSpeechRate * 0.98

        let normalUtterance = engine.makeUtterance(text: "Normal rate", rate: 1.0, locale: "en-US")
        #expect(normalUtterance != nil)
        if let normalUtterance {
            #expect(abs(normalUtterance.rate - baseRate) < 0.001)
        }

        let slowUtterance = engine.makeUtterance(text: "Slow rate", rate: 0.5, locale: "en-US")
        #expect(slowUtterance != nil)
        if let slowUtterance {
            #expect(abs(slowUtterance.rate - (baseRate * 0.5)) < 0.001)
        }

        let clampedMaxUtterance = engine.makeUtterance(text: "Excessive fast", rate: 100.0, locale: "en-US")
        #expect(clampedMaxUtterance != nil)
        if let clampedMaxUtterance {
            #expect(clampedMaxUtterance.rate <= AVSpeechUtteranceMaximumSpeechRate)
        }

        let clampedMinUtterance = engine.makeUtterance(text: "Excessive slow", rate: 0.0, locale: "en-US")
        #expect(clampedMinUtterance != nil)
        if let clampedMinUtterance {
            #expect(clampedMinUtterance.rate >= AVSpeechUtteranceMinimumSpeechRate)
        }
    }

    @Test("Verify empty or whitespace strings return nil utterance")
    @MainActor
    func test_makeUtterance_emptyOrWhitespace() {
        let engine = AppleEnhancedTTSEngine()

        #expect(engine.makeUtterance(text: "", rate: 1.0, locale: "en-US") == nil)
        #expect(engine.makeUtterance(text: "   \t\n   ", rate: 1.0, locale: "en-US") == nil)
    }

    @Test("Verify voice assignment uses AppleVoiceSelector")
    @MainActor
    func test_makeUtterance_voiceAssignment() {
        let engine = AppleEnhancedTTSEngine()
        let utterance = engine.makeUtterance(text: "Check voice", rate: 1.0, locale: "en-US")

        #expect(utterance != nil)
        let resolved = AppleVoiceSelector.resolveBestVoice(for: "en-US")
        if let resolved, let utterance {
            #expect(utterance.voice?.identifier == resolved.identifier)
        }
    }

    @Test("Verify makeUtterance applies custom pitch and bounds clamps")
    @MainActor
    func test_makeUtterance_customPitch() {
        let engine = AppleEnhancedTTSEngine()
        let utterance = engine.makeUtterance(text: "Pitch test", rate: 1.0, locale: "en-US", pitch: 0.90)

        #expect(utterance != nil)
        if let utterance {
            #expect(abs(utterance.pitchMultiplier - 0.90) < 0.001)
        }

        let clampedLow = engine.makeUtterance(text: "Low pitch", rate: 1.0, locale: "en-US", pitch: 0.1)
        #expect(clampedLow?.pitchMultiplier == 0.5)

        let clampedHigh = engine.makeUtterance(text: "High pitch", rate: 1.0, locale: "en-US", pitch: 3.0)
        #expect(clampedHigh?.pitchMultiplier == 2.0)
    }

    @Test("Verify makeUtterance selects voice matching voiceIdentifier when available")
    @MainActor
    func test_makeUtterance_customVoiceIdentifier() {
        let engine = AppleEnhancedTTSEngine()
        if let availableVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            !AppleVoiceSelector.isBlacklisted(voiceName: $0.name)
        }) {
            let utterance = engine.makeUtterance(
                text: "Voice identifier test",
                rate: 1.0,
                locale: availableVoice.language,
                voiceIdentifier: availableVoice.name
            )

            #expect(utterance != nil)
            #expect(utterance?.voice?.name.lowercased() == availableVoice.name.lowercased())
        }

        // Test fallback when voiceIdentifier does not exist
        let fallbackUtterance = engine.makeUtterance(
            text: "Fallback test",
            rate: 1.0,
            locale: "en-US",
            voiceIdentifier: "non-existent-voice-xyz"
        )
        #expect(fallbackUtterance != nil)
        #expect(fallbackUtterance?.voice != nil)
    }

    @Test("Verify speakAsync supports custom voiceIdentifier and pitch")
    @MainActor
    func test_speakAsync_withCustomVoiceAndPitch() async {
        let engine = AppleEnhancedTTSEngine()
        await engine.speakAsync(
            text: "Async with voice and pitch",
            rate: 1.1,
            locale: "en-US",
            voiceIdentifier: "daniel",
            pitch: 0.9
        )
        #expect(!engine.isSpeaking)
        #expect(engine.currentUtterance == nil)
    }

    @Test("Verify speak and stop lifecycle in test environment")
    @MainActor
    func test_speakAndStop_lifecycle() {
        let engine = AppleEnhancedTTSEngine()

        #expect(!engine.isSpeaking)
        engine.speak(text: "Testing speak")
        #expect(engine.isSpeaking)

        engine.stop()
        #expect(!engine.isSpeaking)
        #expect(engine.currentUtterance == nil)
    }

    @Test("Verify speak with empty text does not initiate speaking")
    @MainActor
    func test_speak_emptyTextDoesNotInitiateSpeaking() {
        let engine = AppleEnhancedTTSEngine()

        engine.speak(text: "   ")
        #expect(!engine.isSpeaking)
        #expect(engine.currentUtterance == nil)
    }

    @Test("Verify speakAsync completes without hanging in test environment")
    @MainActor
    func test_speakAsync_testEnvironment() async {
        let engine = AppleEnhancedTTSEngine()

        await engine.speakAsync(text: "Async speak testing", rate: 1.0, locale: "en-US")
        #expect(!engine.isSpeaking)
        #expect(engine.currentUtterance == nil)

        await engine.speakAsync(text: "   ", rate: 1.0, locale: "en-US")
        #expect(!engine.isSpeaking)
        #expect(engine.currentUtterance == nil)
    }

    @Test("Verify onFinished callback is executed on stop")
    @MainActor
    func test_onFinished_calledOnStop() {
        let engine = AppleEnhancedTTSEngine()
        let tracker = CallbackTracker()

        engine.speak(text: "Testing callback", rate: 1.0, locale: "en-US") {
            tracker.wasCalled = true
        }

        #expect(engine.isSpeaking)
        #expect(!tracker.wasCalled)

        engine.stop()
        #expect(!engine.isSpeaking)
        #expect(tracker.wasCalled)
    }

    @Test("Verify delegate didFinish and didCancel callbacks reset state")
    @MainActor
    func test_delegateCallbacks_resetState() async {
        let engine = AppleEnhancedTTSEngine()
        let synth = AVSpeechSynthesizer()

        let trackerFinish = CallbackTracker()
        engine.speak(text: "Delegate test", rate: 1.0, locale: "en-US") {
            trackerFinish.wasCalled = true
        }
        #expect(engine.isSpeaking)
        guard let activeUtterance = engine.currentUtterance else {
            Issue.record("Expected non-nil currentUtterance while speaking")
            return
        }

        // Calling didFinish with stale utterance should NOT reset state
        let staleUtterance = AVSpeechUtterance(string: "Stale")
        engine.speechSynthesizer(synth, didFinish: staleUtterance)
        await Task.yield()
        #expect(engine.isSpeaking)
        #expect(!trackerFinish.wasCalled)

        // Calling didFinish with matching utterance resets state
        engine.speechSynthesizer(synth, didFinish: activeUtterance)
        for _ in 0..<10 {
            if !engine.isSpeaking { break }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 5_000_000)
        }

        #expect(!engine.isSpeaking)
        #expect(engine.currentUtterance == nil)
        #expect(trackerFinish.wasCalled)

        // Now test didCancel
        let trackerCancel = CallbackTracker()
        engine.speak(text: "Delegate test 2", rate: 1.0, locale: "en-US") {
            trackerCancel.wasCalled = true
        }
        #expect(engine.isSpeaking)
        guard let activeUtterance2 = engine.currentUtterance else {
            Issue.record("Expected non-nil currentUtterance while speaking")
            return
        }

        // Calling didCancel with stale utterance should NOT reset state
        engine.speechSynthesizer(synth, didCancel: staleUtterance)
        await Task.yield()
        #expect(engine.isSpeaking)
        #expect(!trackerCancel.wasCalled)

        // Calling didCancel with matching utterance resets state
        engine.speechSynthesizer(synth, didCancel: activeUtterance2)
        for _ in 0..<10 {
            if !engine.isSpeaking { break }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 5_000_000)
        }

        #expect(!engine.isSpeaking)
        #expect(engine.currentUtterance == nil)
        #expect(trackerCancel.wasCalled)
    }
}
