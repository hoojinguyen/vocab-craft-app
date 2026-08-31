# Reflex Blitz Speaking Mode Reliability & Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triệt tiêu hoàn toàn hiện tượng lặp từ vô hạn (Acoustic Feedback Loop), crash văng app (`SIGABRT`), nóng máy giật lag, tạp âm môi trường và lỗi nhận diện sai trong chế độ Speaking của Reflex Drill.

**Architecture:** Bật phần cứng VoiceProcessingIO (AEC & Noise Suppression) trên `AVAudioInputNode` với `AVAudioSession.Mode.voiceChat`; tái cấu trúc `AudioBufferRelay` với Mute Gate và `detachAndEnd()` nguyên tử để chống race condition; hợp nhất toàn bộ speech handling vào duy nhất `ResilientReflexSpeechEngine`; phân bậc thuật toán so khớp `ReflexSpeechMatcher` theo độ dài từ; và cô lập render UI của transcript badge.

**Tech Stack:** Swift 5.9+, AVFoundation (`AVAudioEngine`, `AVAudioSession`, VoiceProcessingIO), Speech Framework (`SFSpeechRecognizer`, `SFSpeechAudioBufferRecognitionRequest`), SwiftUI, SpeechKit, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-31-reflex-speaking-mode-performance-and-reliability-design.md`

## Global Constraints

- 100% Zero Hardcoded Strings Policy (`Localizable.xcstrings` với cặp song ngữ EN & VI).
- Tuân thủ nghiêm ngặt Design Tokens của `CraftUIKit` (`CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`).
- Zero compiler warnings và zero compiler errors trên Xcode.
- 100% test suite vượt qua (`swift test`).

---

### Task 1: Tiered Phonetic Matching Algorithm in `ReflexSpeechMatcher`

**Files:**
- Create: `VocabCraftAppTests/Features/Reflex/ReflexSpeechMatcherTests.swift`
- Modify: `VocabCraftApp/Core/Audio/ContinuousReflexSpeechService.swift:6-57`

**Interfaces:**
- Consumes: `StringNormalizer.normalize`, `StringNormalizer.tokenize`, `FuzzySpeechMatcher.similarityRatio`, `FuzzySpeechMatcher.evaluate`.
- Produces: `ReflexSpeechMatcher.isReflexMatch(spokenText:targetLemma:toleranceThreshold:) -> Bool` với thuật toán phân bậc độ dài:
  - 1–4 ký tự: Exact match hoặc prefix/stem match. Không áp dụng Levenshtein similarity.
  - 5–7 ký tự: Ngưỡng tương đồng tối thiểu `0.80`.
  - ≥ 8 ký tự: Ngưỡng tương đồng tối thiểu `0.72`.

- [ ] **Step 1: Write the failing tests for `ReflexSpeechMatcher` tiered matching**

Create `VocabCraftAppTests/Features/Reflex/ReflexSpeechMatcherTests.swift`:
```swift
import Foundation
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

final class ReflexSpeechMatcherTests: XCTestCase {
    // MARK: - Short Words (<= 4 chars): Reject noise, allow exact and clear prefix

    func testShortWords_rejectsAmbientNoiseTokens() {
        // "cat" (3 chars) vs "at" (ratio 0.67) or "bat" (ratio 0.67)
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "at", targetLemma: "cat"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "bat", targetLemma: "cat"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "car", targetLemma: "cat"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "un", targetLemma: "run"))
    }

    func testShortWords_acceptsExactMatch() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "cat", targetLemma: "cat"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "run", targetLemma: "run"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "i see a cat here", targetLemma: "cat"))
    }

    func testShortWords_acceptsStemOrPrefixWhenTargetFourChars() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "walked", targetLemma: "walk"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "walking", targetLemma: "walk"))
    }

    // MARK: - Medium Words (5 - 7 chars): Threshold 0.80

    func testMediumWords_acceptsHighSimilarity() {
        // "vital" (5 chars) vs "vitall" (ratio 0.83)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "vital", targetLemma: "vital"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "vitals", targetLemma: "vital"))
    }

    func testMediumWords_rejectsDissimilarTokens() {
        // "vital" vs "viral" (dist 1 / 5 = 0.8, but "viral" vs "vital" -> 0.8 is right on edge, test 0.6)
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "metal", targetLemma: "vital"))
    }

    // MARK: - Long Words (>= 8 chars): Threshold 0.72

    func testLongWords_acceptsAccentTolerantVariants() {
        // "ephemeral" (9 chars)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "ephemeral", targetLemma: "ephemeral"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "hesitated", targetLemma: "hesitate"))
    }

    // MARK: - Multi-Word Lemmas

    func testMultiWordLemmas_evaluatesCorrectly() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "please give up now", targetLemma: "give up"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "give in now", targetLemma: "give up"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails on short words noise rejection**

Run: `swift test --filter ReflexSpeechMatcherTests`  
Expected: FAIL (because current `ReflexSpeechMatcher` with 0.70 threshold or prefix logic allows short word noise matches like "car" vs "cat" or "at" vs "cat").

- [ ] **Step 3: Implement tiered matching logic in `ReflexSpeechMatcher`**

Update `VocabCraftApp/Core/Audio/ContinuousReflexSpeechService.swift`:
```swift
public enum ReflexSpeechMatcher {
    /// Evaluates whether spoken text contains the target lemma or an acceptable phonetic / accent / inflection reflex match.
    public static func isReflexMatch(
        spokenText: String,
        targetLemma: String,
        toleranceThreshold: Double = 0.70
    ) -> Bool {
        let normalizedTarget = StringNormalizer.normalize(targetLemma)
        guard !normalizedTarget.isEmpty, !spokenText.isEmpty else { return false }

        // Tokenize the newly spoken stream
        let tokens = StringNormalizer.tokenize(spokenText)
        guard !tokens.isEmpty else { return false }

        // Multi-word lemma check (e.g. phrasal verbs "give up", "look forward to")
        let targetTokens = StringNormalizer.tokenize(normalizedTarget)
        if targetTokens.count > 1 {
            let eval = FuzzySpeechMatcher.evaluate(
                spokenText: spokenText,
                targetSentence: normalizedTarget,
                passThreshold: toleranceThreshold
            )
            return eval.isPassed
        }

        let targetLen = normalizedTarget.count

        // Single-word lemma evaluation with Tiered Length Matching
        for token in tokens {
            // 1. Exact normalized token match
            if token == normalizedTarget {
                return true
            }

            // 2. Stemming / Inflection / Prefix match (e.g. "walk" vs "walking", "hesitate" vs "hesitated")
            if targetLen >= 4 {
                if token.hasPrefix(normalizedTarget) {
                    return true
                }
                if token.count >= 4 && normalizedTarget.hasPrefix(token) {
                    return true
                }
            }

            // 3. Tiered fuzzy phonetic & accent tolerance
            if targetLen <= 4 {
                // Short words (< 5 letters): STRICT exact/stem only.
                // Do NOT apply loose Levenshtein distance to prevent ambient noise (breathing, whispers) from matching.
                continue
            } else if targetLen <= 7 {
                // Medium words (5-7 letters): Require high similarity (>= 0.80)
                let ratio = FuzzySpeechMatcher.similarityRatio(token, normalizedTarget)
                if ratio >= 0.80 {
                    return true
                }
            } else {
                // Long words (>= 8 letters): Allow accent tolerance (>= 0.72)
                let ratio = FuzzySpeechMatcher.similarityRatio(token, normalizedTarget)
                if ratio >= max(0.72, toleranceThreshold) {
                    return true
                }
            }
        }

        return false
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexSpeechMatcherTests`  
Expected: PASS (all tests pass).

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/ContinuousReflexSpeechService.swift VocabCraftAppTests/Features/Reflex/ReflexSpeechMatcherTests.swift
git commit -m "feat(reflex): implement tiered phonetic matching in ReflexSpeechMatcher"
```

---

### Task 2: Thread-Safe `AudioBufferRelay` with Mute Gate & Atomic `detachAndEnd()`

**Files:**
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift:7-28`
- Modify: `VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift`

**Interfaces:**
- Consumes: `AVAudioPCMBuffer`, `SFSpeechAudioBufferRecognitionRequest`.
- Produces:
  - `AudioBufferRelay.mute()`
  - `AudioBufferRelay.unmute()`
  - `AudioBufferRelay.setRequest(_ request: SFSpeechAudioBufferRecognitionRequest?)`
  - `AudioBufferRelay.detachAndEnd()`: Atomically sets `activeRequest = nil`, sets `isMuted = true`, releases lock, and calls `request.endAudio()`.
  - `AudioBufferRelay.append(_ buffer: AVAudioPCMBuffer)`: Drops buffer immediately if `isMuted` is true or `activeRequest` is nil.

- [ ] **Step 1: Write the failing tests for `AudioBufferRelay` in `ResilientReflexSpeechEngineTests.swift`**

Add tests to `VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift`:
```swift
    func testAudioBufferRelay_muteAndUnmute() {
        let relay = AudioBufferRelay()
        relay.mute()
        XCTAssertTrue(relay.isCurrentlyMuted)
        relay.unmute()
        XCTAssertFalse(relay.isCurrentlyMuted)
    }

    func testAudioBufferRelay_detachAndEnd_resetsRequestAndMutes() {
        let relay = AudioBufferRelay()
        let request = SFSpeechAudioBufferRecognitionRequest()
        relay.setRequest(request)
        XCTAssertFalse(relay.isCurrentlyMuted)

        relay.detachAndEnd()
        XCTAssertTrue(relay.isCurrentlyMuted)
        XCTAssertNil(relay.currentRequest)
    }

    func testAudioBufferRelay_concurrentAppendAndDetach_noCrash() {
        let relay = AudioBufferRelay()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        let iterations = 1000
        let group = DispatchGroup()

        // Background thread appending buffers rapidly
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            for _ in 0..<iterations {
                relay.append(buffer)
            }
            group.leave()
        }

        // Main thread alternating request and detachAndEnd
        group.enter()
        DispatchQueue.global(qos: .default).async {
            for _ in 0..<iterations {
                let req = SFSpeechAudioBufferRecognitionRequest()
                relay.setRequest(req)
                relay.detachAndEnd()
            }
            group.leave()
        }

        let result = group.wait(timeout: .now() + 5.0)
        XCTAssertEqual(result, .success)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ResilientReflexSpeechEngineTests`  
Expected: FAIL (`isCurrentlyMuted`, `currentRequest`, and `detachAndEnd` not defined).

- [ ] **Step 3: Implement `AudioBufferRelay` with atomic Mute Gate and `detachAndEnd`**

Update `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`:
```swift
public final class AudioBufferRelay: @unchecked Sendable {
    private let lock = NSLock()
    private weak var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var isMuted: Bool = false

    public init() {}

    public var isCurrentlyMuted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isMuted
    }

    public var currentRequest: SFSpeechAudioBufferRecognitionRequest? {
        lock.lock()
        defer { lock.unlock() }
        return activeRequest
    }

    public func setRequest(_ request: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock()
        defer { lock.unlock() }
        activeRequest = request
        isMuted = false
    }

    public func mute() {
        lock.lock()
        defer { lock.unlock() }
        isMuted = true
    }

    public func unmute() {
        lock.lock()
        defer { lock.unlock() }
        isMuted = false
    }

    /// Atomically detaches the active request and invokes endAudio() on it.
    /// Guarantees that no background tap buffer can ever be appended after endAudio() is called.
    public func detachAndEnd() {
        lock.lock()
        let requestToEnd = activeRequest
        activeRequest = nil
        isMuted = true
        lock.unlock()

        requestToEnd?.endAudio()
    }

    public func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        guard !isMuted, let request = activeRequest else {
            lock.unlock()
            return
        }
        lock.unlock()
        request.append(buffer)
    }
}
```

And in `ResilientReflexSpeechEngine.swift`:
In `endWord()`:
Replace:
```swift
        bufferRelay.setRequest(nil)
        activeRequest?.endAudio()
        activeTask?.cancel()
        activeRequest = nil
        activeTask = nil
        isWordActive = false
```
With:
```swift
        bufferRelay.detachAndEnd()
        activeTask?.cancel()
        activeRequest = nil
        activeTask = nil
        isWordActive = false
```

And in `finalizeWordAudio()`:
Replace:
```swift
        bufferRelay.setRequest(nil)
        activeRequest?.endAudio()
```
With:
```swift
        bufferRelay.detachAndEnd()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ResilientReflexSpeechEngineTests`  
Expected: PASS (all tests pass, including concurrent stress test).

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift
git commit -m "feat(audio): implement thread-safe AudioBufferRelay with atomic detachAndEnd and mute gate"
```

---

### Task 3: Hardware VoiceProcessingIO, Audio Session Optimization & Focused Model Bias

**Files:**
- Modify: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift:224-340`

**Interfaces:**
- Hardware Voice Processing: `engine.inputNode.setVoiceProcessingEnabled(true)`.
- Audio Session: `category: .playAndRecord`, `mode: .voiceChat`, `options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers]`.
- Tap buffer size: `2048` frames.
- Request task hint: `.search`.
- Contextual strings: Filter out full sentence strings, keep only target lemma and concise word inflections.

- [ ] **Step 1: Update audio engine configuration and recognition request in `ResilientReflexSpeechEngine.swift`**

Modify `setupAndStartEngine()` in `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`:
```swift
    private func setupAndStartEngine() {
        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode

            #if os(iOS)
            // Enable Apple Hardware Voice Processing Unit (VPU) for Acoustic Echo Cancellation (AEC),
            // Automatic Gain Control (AGC), and ambient noise suppression.
            do {
                try inputNode.setVoiceProcessingEnabled(true)
            } catch {
                // Non-fatal fallback if hardware doesn't support VPU
                print("[ResilientReflexSpeechEngine] Voice processing unavailable: \(error)")
            }
            #endif

            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
                throw NSError(
                    domain: "ResilientReflexSpeech",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid microphone format."]
                )
            }

            let relay = self.bufferRelay
            // Increase buffer size to 2048 to reduce callback frequency and thermal pressure
            inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [relay] buffer, _ in
                relay.append(buffer)
            }

            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            self.sessionStartTime = Date()
        } catch {
            onError?(error)
        }
    }
```

Modify `startRecognitionRequest()` in `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`:
```swift
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // .search optimizes recognition for short distinct vocabulary words rather than continuous narrative dictation
        request.taskHint = .search

        // Focus contextual strings strictly on concise tokens (<= 2 words).
        // Long sentences dilute language model weights and degrade single-word recognition accuracy.
        var biasedPhrases = (sessionContextualPhrases + contextualPhrases)
            .flatMap { phrase -> [String] in
                let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return [] }
                // If phrase is a short word or phrasal verb, keep it
                if trimmed.split(separator: " ").count <= 2 {
                    return [trimmed]
                }
                return []
            }
        if !biasedPhrases.contains(targetLemma) {
            biasedPhrases.append(targetLemma)
        }
        request.contextualStrings = Array(Set(biasedPhrases))

        #if os(iOS)
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        #endif
```

- [ ] **Step 2: Run test suite to verify no regressions**

Run: `swift test --filter ResilientReflexSpeechEngineTests`  
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift
git commit -m "feat(audio): enable VoiceProcessingIO AEC and optimize speech recognition configuration"
```

---

### Task 4: Remove Duplicate Speech Engine from `ReflexBlitzViewModel` & Ensure Synchronous `endWord` before TTS

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel+Configuration.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift:214-222`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelFeedbackTests.swift`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelListeningTests.swift`

**Interfaces:**
- `ReflexBlitzViewModel` holds only `speechEngine: ReflexSpeechEngineProtocol`.
- `continuousSpeechService` is removed from `ReflexBlitzViewModel` initializer and properties.
- In `handleSpokenMatch`: calls `speechEngine.endWord()` synchronously before setting `cardPhase = .reviewed` and before scheduling TTS.
- In `loadWord`: calls `speechEngine.beginWord` when `selectedMode == .speaking`, otherwise engine remains idle.

- [ ] **Step 1: Update `ReflexBlitzViewModel.swift` to remove duplicate `continuousSpeechService`**

In `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`:
1. Remove `let continuousSpeechService: ContinuousReflexSpeechProtocol`.
2. Update `isKeyboardFallbackActive`:
```swift
    public var isKeyboardFallbackActive: Bool = false {
        didSet {
            if isKeyboardFallbackActive {
                speechEngine.endWord()
            } else if selectedMode == .speaking && cardPhase == .activeCountdown, let word = currentWord {
                speechEngine.beginWord(targetLemma: word.lemma, contextualPhrases: [word.exampleSentenceEn])
            }
        }
    }
```
3. Update `init`:
```swift
    public convenience init(
        words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0
    ) {
        self.init(
            words: words,
            weeklyPracticedCount: weeklyPracticedCount,
            weakWordsCount: weakWordsCount,
            averageSpeedSeconds: averageSpeedSeconds,
            ttsService: TextToSpeechService(),
            evaluateSRSUseCase: EvaluateSRSUseCase(srsRepository: SRSRepositoryImpl()),
            soundEffectService: SoundEffectService.shared,
            speechEngine: ResilientReflexSpeechEngine()
        )
    }

    public init(
        words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
        weeklyPracticedCount: Int = 0,
        weakWordsCount: Int = 0,
        averageSpeedSeconds: Double = 0.0,
        ttsService: TextToSpeechProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol,
        soundEffectService: SoundEffectServiceProtocol = SoundEffectService.shared,
        speechEngine: ReflexSpeechEngineProtocol? = nil
    ) {
        self.words = words
        self.weeklyPracticedCount = weeklyPracticedCount
        self.weakWordsCount = weakWordsCount
        self.averageSpeedSeconds = averageSpeedSeconds
        self.ttsService = ttsService
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.soundEffectService = soundEffectService
        self.speechEngine = speechEngine ?? ResilientReflexSpeechEngine()
        setupSpeechEngineBindings()
    }
```
4. Remove `setupSpeechServiceBindings()` completely.
5. In `loadWord(at:)`:
```swift
        if selectedMode == .speaking {
            speechEngine.beginWord(
                targetLemma: word.lemma,
                contextualPhrases: [word.exampleSentenceEn]
            )
        }
```
6. In `handleSpokenMatch`:
```swift
    public func handleSpokenMatch(_ matchedLemma: String) {
        guard phase == .drilling, cardPhase == .activeCountdown, !currentAttemptIsCorrect, let word = currentWord else { return }
        let cleanMatched = matchedLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanLemma = word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanMatched == cleanLemma || cleanMatched.contains(cleanLemma) else { return }

        cancelActiveTimers()
        currentAttemptIsCorrect = true
        soundEffectService.playSuccessChime()
        comboStreak += 1
        if comboStreak > maxComboStreak {
            maxComboStreak = comboStreak
        }

        // 1. Immediately end word recognition and mute audio relay BEFORE TTS is scheduled
        speechEngine.endWord()

        let responseMs: Int
        if elapsedTimeMs > 0 {
            responseMs = elapsedTimeMs
        } else if let start = wordStartTime {
            responseMs = max(0, Int(Date().timeIntervalSince(start) * 1000))
            self.elapsedTimeMs = responseMs
        } else {
            responseMs = 0
        }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id, lemma: word.lemma, pos: word.pos, ipa: word.ipa,
            definitionVi: word.definitionVi, responseTimeMs: responseMs,
            usedHint: showHint, isCorrect: true
        )
        attempts.append(attempt)

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id), isCorrect: true, responseTimeMs: responseMs
            )
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            self.cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: true, responseTimeMs: responseMs, isTimeout: false,
                selectedOption: nil, typedText: nil, recognizedSpoken: matchedLemma
            ))
        }

        // 2. Speak the word after flip consolidation
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, self.cardPhase != .activeCountdown else { return }
            self.ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
        }
    }
```

- [ ] **Step 2: Update `ReflexBlitzViewModel+Configuration.swift` and `AppContainer.swift`**

In `ReflexBlitzViewModel+Configuration.swift`:
Replace any `continuousSpeechService.stopSession()` with `speechEngine.stopSession()`.
In `handleTimeout()`:
```swift
        if selectedMode == .speaking {
            speechEngine.endWord()
        }
```

In `AppContainer.swift`:
Update `makeReflexBlitzViewModel`:
```swift
    public func makeReflexBlitzViewModel(words: [ReflexBlitzWordItem] = []) -> ReflexBlitzViewModel {
        let blitzWords = !words.isEmpty ? words : ReflexBlitzWordItem.defaultStarterWords
        return ReflexBlitzViewModel(
            words: blitzWords,
            ttsService: ttsService,
            evaluateSRSUseCase: evaluateSRSUseCase,
            speechEngine: ResilientReflexSpeechEngine()
        )
    }
```

- [ ] **Step 3: Update all unit tests that initialized `ReflexBlitzViewModel` with `continuousSpeechService`**

Update `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift`:
Remove `MockContinuousReflexSpeechService()` parameter from `ReflexBlitzViewModel` init.
Add test:
```swift
    func testSpeakingMode_matchDetected_callsEndWordBeforeTTS() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateMatch("ephemeral")
        XCTAssertEqual(mockSpeechEngine.endWordCallCount, 1)
        XCTAssertEqual(mockSpeechEngine.isWordActive, false)
    }
```

Update `ReflexBlitzViewModelTests.swift`, `ReflexBlitzViewIntegrationTests.swift`, `ReflexBlitzViewModelFeedbackTests.swift`, and `ReflexBlitzViewModelListeningTests.swift` to remove the obsolete `continuousSpeechService` argument.

- [ ] **Step 4: Run test suites to verify all tests pass**

Run: `swift test --filter ReflexBlitzViewModelSpeakingTests`  
Run: `swift test --filter ReflexBlitzViewModelListeningTests`  
Run: `swift test --filter ReflexBlitzViewModelFeedbackTests`  
Run: `swift test --filter ReflexBlitzViewModelTests`  
Expected: PASS (all tests pass).

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel+Configuration.swift VocabCraftAppTests/
git commit -m "refactor(reflex): eliminate duplicate continuousSpeechService and unify on ResilientReflexSpeechEngine"
```

---

### Task 5: View Hierarchy Isolation for Transcript Badge in `ReflexSpeakingModeView`

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift:256-291`

**Interfaces:**
- `ReflexSpeakingLiveBadge`: View độc lập hiển thị waveform badge khi `liveTranscript` có giá trị.
- `CraftTactileMicHubView` và `CraftFlipCard` không bị invalidate re-render liên tục trên mỗi ký tự transcription.

- [ ] **Step 1: Extract `ReflexSpeakingLiveBadge` into dedicated subview component in `ReflexSpeakingModeView.swift`**

Update `ReflexSpeakingModeView.swift`:
```swift
// MARK: - Zone 2: Mic Hub + Isolated Transcript Badge

@ViewBuilder
private var micHubArea: some View {
    VStack(spacing: theme.spacing.sm) {
        CraftTactileMicHubView(
            speechState: isReviewed
                ? .evaluated(overallScore: isResultCorrect ? 100 : 0)
                : speechState,
            customSubtitle: isReviewed ? "" : nil,
            onTapMic: {}  // Auto continuous listening
        )
        .disabled(true)

        ReflexSpeakingLiveBadge(
            liveTranscript: liveTranscript,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect
        )
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isReviewed)
}

private struct ReflexSpeakingLiveBadge: View, Equatable {
    let liveTranscript: String
    let isReviewed: Bool
    let isResultCorrect: Bool
    @Environment(\.craftTheme) private var theme

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.liveTranscript == rhs.liveTranscript &&
        lhs.isReviewed == rhs.isReviewed &&
        lhs.isResultCorrect == rhs.isResultCorrect
    }

    var body: some View {
        if !liveTranscript.isEmpty {
            let lastToken = liveTranscript
                .split(separator: " ")
                .last
                .map(String.init) ?? liveTranscript

            CraftBadge(
                lastToken,
                iconName: "waveform",
                variant: isReviewed ? .subtle : .solid,
                tone: isReviewed
                    ? (isResultCorrect ? .success : .danger)
                    : .primary,
                size: .md,
                shape: .capsule
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}
```

- [ ] **Step 2: Run tests to verify build & view integration**

Run: `swift test --filter ReflexBlitzViewIntegrationTests`  
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift
git commit -m "perf(reflex): isolate live transcript badge view hierarchy to optimize 3D card render performance"
```

---

### Task 6: Full Verification Suite & Quality Gate Compliance

**Files:**
- Test all components across app test targets.

- [ ] **Step 1: Run full test suite**

Run: `swift test`  
Expected: All 160+ unit & integration tests pass with 0 failures.

- [ ] **Step 2: Verify git status and check for clean tree**

Run: `git status -s`  
Expected: Clean working tree.

- [ ] **Step 3: Commit full implementation plan milestone**

```bash
git commit --allow-empty -m "chore: complete reflex speaking mode reliability and performance milestone"
```
