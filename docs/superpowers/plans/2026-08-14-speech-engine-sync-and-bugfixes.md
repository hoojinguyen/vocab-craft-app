# Speech Engine Synchronization & Critical Voice Flaws Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 6 critical speech recognition, silence detection, audio routing, and evaluation bugs, and synchronize both Reflex Drill and Quick Reflex Drill under `SpeechKit` with 100% accuracy.

**Architecture:** Refactor `SilenceDetector` with dual-phase timeouts (5s initial, 1.3s trailing), add `.defaultToSpeaker` and on-device fallback to `SpeechRecognitionEngine`, refine `SpeechAssessmentService` instant-pass threshold, guarantee completion state evaluation in `ReflexDrillViewModel`, and upgrade `QuickReflexDrillViewModel` to `SpeechAssessmentProtocol` with word highlighting in `QuickReflexDrillSheetView`.

**Tech Stack:** Swift 5.10+, iOS 17+, Speech framework (`SFSpeechRecognizer`), AVFoundation (`AVAudioEngine`, `AVAudioSession`), Observation framework, SwiftUI, Swift Testing / XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-14-speech-engine-sync-and-bugfixes-design.md`](../specs/2026-08-14-speech-engine-sync-and-bugfixes-design.md)

## Global Constraints
- Target Platform: iOS 17.0+, macOS 14.0+
- 100% On-Device capable with zero cloud API costs; graceful online/hybrid fallback if offline dictation assets are not downloaded
- Dual Silence Detection: 5.0s initial preparation timeout, 1.3s trailing silence after speech activity
- Instant Reflex Pass condition: $\ge 75\%$ similarity AND ($\ge 85\%$ target token coverage OR $\ge 95\%$ overall score)
- Clean Architecture: ViewModel depends only on `SpeechAssessmentProtocol` and domain structs
- Zero test regressions across entire test suite

---

### Task 1: Core SpeechKit Engine Fixes (`SilenceDetector`, `SpeechRecognitionEngine`, `SpeechAssessmentService`)

**Files:**
- Modify: `VocabCraftApp/Core/SpeechKit/Engine/SilenceDetector.swift`
- Modify: `VocabCraftApp/Core/SpeechKit/Engine/SpeechRecognitionEngine.swift`
- Modify: `VocabCraftApp/Core/SpeechKit/SpeechAssessmentService.swift`
- Test: `VocabCraftAppTests/SpeechKitTests/SpeechAssessmentServiceTests.swift`

**Interfaces:**
- Consumes: `SpeechRecognitionEngineProtocol`, `FuzzySpeechMatcher`, `SpeechEvaluationResult`
- Produces:
  - `SilenceDetector(initialSilenceDuration: Duration = .seconds(5), trailingSilenceDuration: Duration = .milliseconds(1300), onSilence: @escaping @Sendable () -> Void)`
  - `SilenceDetector.registerActivity()` (switches active timer to trailing duration)
  - `SpeechRecognitionEngine.start(...)` (with `.defaultToSpeaker` and fallback on `requiresOnDeviceRecognition`)
  - `SpeechAssessmentService.startAssessing(...)` (refined instant trigger)

- [ ] **Step 1: Write failing unit tests for dual-phase silence detector and refined instant pass in `SpeechAssessmentServiceTests.swift`**

```swift
func testSilenceDetector_initialSilenceTimeout() async throws {
    var didFireSilence = false
    let detector = SilenceDetector(
        initialSilenceDuration: .milliseconds(100),
        trailingSilenceDuration: .milliseconds(50)
    ) {
        didFireSilence = true
    }
    detector.arm()
    try await Task.sleep(for: .milliseconds(150))
    XCTAssertTrue(didFireSilence, "Initial silence timer should fire if no activity registered")
}

func testSilenceDetector_activityResetsToTrailingDuration() async throws {
    var didFireSilence = false
    let detector = SilenceDetector(
        initialSilenceDuration: .milliseconds(200),
        trailingSilenceDuration: .milliseconds(80)
    ) {
        didFireSilence = true
    }
    detector.arm()
    try await Task.sleep(for: .milliseconds(50))
    detector.registerActivity()
    XCTAssertFalse(didFireSilence)
    try await Task.sleep(for: .milliseconds(100))
    XCTAssertTrue(didFireSilence, "Trailing silence timer should fire after activity registered")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SpeechAssessmentServiceTests`
Expected: Compilation failure or assertion failure due to missing initializer parameters.

- [ ] **Step 3: Update `SilenceDetector.swift`, `SpeechRecognitionEngine.swift`, and `SpeechAssessmentService.swift`**

Update `SilenceDetector.swift`:
```swift
import Foundation

public final class SilenceDetector: @unchecked Sendable {
    private let initialSilenceDuration: Duration
    private let trailingSilenceDuration: Duration
    private let onSilence: @Sendable () -> Void
    private let lock = NSLock()
    private var timerTask: Task<Void, Never>?
    private var hasRegisteredActivity = false

    public init(
        initialSilenceDuration: Duration = .seconds(5),
        trailingSilenceDuration: Duration = .milliseconds(1300),
        onSilence: @escaping @Sendable () -> Void
    ) {
        self.initialSilenceDuration = initialSilenceDuration
        self.trailingSilenceDuration = trailingSilenceDuration
        self.onSilence = onSilence
    }

    public convenience init(
        silenceDuration: Duration = .milliseconds(1300),
        onSilence: @escaping @Sendable () -> Void
    ) {
        self.init(
            initialSilenceDuration: .seconds(5),
            trailingSilenceDuration: silenceDuration,
            onSilence: onSilence
        )
    }

    deinit {
        cancel()
    }

    public func arm() {
        lock.lock()
        timerTask?.cancel()
        hasRegisteredActivity = false
        let duration = initialSilenceDuration
        let callback = onSilence

        timerTask = Task {
            do {
                try await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                callback()
            } catch {
                // Cancelled
            }
        }
        lock.unlock()
    }

    public func registerActivity() {
        lock.lock()
        timerTask?.cancel()
        hasRegisteredActivity = true
        let duration = trailingSilenceDuration
        let callback = onSilence

        timerTask = Task {
            do {
                try await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                callback()
            } catch {
                // Cancelled
            }
        }
        lock.unlock()
    }

    public func cancel() {
        lock.lock()
        timerTask?.cancel()
        timerTask = nil
        lock.unlock()
    }
}
```

Update `SpeechRecognitionEngine.swift`:
- Change line 108:
```swift
try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
```
- Change lines 100-103:
```swift
let supportsOnDevice = recognizer.supportsOnDeviceRecognition
```
- Change line 116:
```swift
request.requiresOnDeviceRecognition = supportsOnDevice
```

Update `SpeechAssessmentService.swift`:
- In `startAssessing`:
```swift
let detector = SilenceDetector(
    initialSilenceDuration: .seconds(5),
    trailingSilenceDuration: silenceDuration
) { [weak self] in
    Task { @MainActor [weak self] in
        guard let self, self.isListening, self.currentSessionToken == sessionToken else { return }
        let finalEval = self.currentEvaluation ?? FuzzySpeechMatcher.evaluate(
            spokenText: "",
            targetSentence: targetSentence,
            passThreshold: toleranceThreshold,
            durationMs: Int(Date().timeIntervalSince(startTime) * 1000)
        )
        self.stopAssessing()
        onCompletion(finalEval)
    }
}
self.silenceDetector = detector
detector.arm()
```
- In `onPartialResult`:
```swift
// Instant Reflex Trigger: pass threshold reached with sufficient token coverage
let matchedTokensCount = eval.tokens.filter { $0.status != .missing }.count
let requiredCoverage = max(1, Int(Double(eval.tokens.count) * 0.85))
let hasSufficientCoverage = matchedTokensCount >= requiredCoverage || eval.overallScore >= 95.0

if eval.isPassed && hasSufficientCoverage {
    self.stopAssessing()
    onCompletion(eval)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SpeechAssessmentServiceTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/SpeechKit VocabCraftAppTests/SpeechKitTests
git commit -m "fix(speechkit): add dual-phase silence detector, speaker routing, and refined instant pass"
```

---

### Task 2: Reflex Drill Evaluation Flow Fix (`ReflexDrillViewModel`)

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrillViewModelSpeechTests.swift`

**Interfaces:**
- Consumes: `SpeechAssessmentProtocol`, `SpeechEvaluationResult`, `EvaluateSRSUseCaseProtocol`
- Produces: `ReflexDrillViewModel.evaluateAnswer(_ answer: String)` called reliably for both pass and failure outcomes

- [ ] **Step 1: Write failing test in `ReflexDrillViewModelSpeechTests.swift` for failure on completion**

```swift
func testSilenceTimeoutOrFailedSpeech_triggersEvaluationAndShowsFeedback() {
    viewModel.startVoiceRecognition()
    XCTAssertTrue(viewModel.isListening)

    let failedResult = SpeechEvaluationResult(
        targetSentence: "A black dog jumps over the fence",
        spokenText: "A red cat",
        tokens: [],
        overallScore: 20.0,
        isPassed: false,
        durationMs: 2500
    )
    mockSpeechAssessment.simulateCompletion(failedResult)

    XCTAssertFalse(viewModel.isListening)
    XCTAssertTrue(viewModel.state.isEvaluated)
    XCTAssertFalse(viewModel.state.isCorrect)
    XCTAssertFalse(viewModel.state.feedbackText.isEmpty)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexDrillViewModelSpeechTests`
Expected: FAIL (`isEvaluated` is false because `onCompletion` currently ignores failed result).

- [ ] **Step 3: Fix `onCompletion` in `ReflexDrillViewModel.swift`**

```swift
onCompletion: { [weak self] evaluation in
    guard let self = self else { return }
    self.speechEvaluationResult = evaluation
    self.internalRecognizedText = evaluation.spokenText
    self.evaluateAnswer(evaluation.spokenText)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexDrillViewModelSpeechTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift VocabCraftAppTests/Features/ReflexDrillViewModelSpeechTests.swift
git commit -m "fix(reflex-drill): guarantee state evaluation on failed and timed out speech attempts"
```

---

### Task 3: Quick Reflex Drill Upgrade to SpeechKit (`QuickReflexDrillViewModel`, `QuickReflexDrillSheetView`, `AppContainer`)

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/QuickReflexDrillViewModelTests.swift`

**Interfaces:**
- Consumes: `SpeechAssessmentProtocol`, `SpeechEvaluationResult`, `WordTokenResult`
- Produces:
  - `QuickReflexDrillViewModel.speechEvaluationResult: SpeechEvaluationResult?`
  - `QuickReflexDrillViewModel.init(..., speechAssessmentService: SpeechAssessmentProtocol? = nil)`
  - `QuickReflexDrillSheetView` rendering word highlight chips in Step 3

- [ ] **Step 1: Write failing tests in `QuickReflexDrillViewModelTests.swift`**

```swift
func testStep3_singleWordDoesNotPassFullSentence() {
    let viewModel = QuickReflexDrillViewModel(
        targetWord: targetWord,
        allWords: samplePool,
        speechAssessmentService: mockSpeechAssessment
    )
    // Advance to Step 3
    viewModel.submitAnswer(viewModel.state.steps[0].targetText)
    viewModel.nextStep()
    viewModel.submitAnswer(viewModel.state.steps[1].targetText)
    viewModel.nextStep()
    XCTAssertEqual(viewModel.state.currentStepIndex, 2)

    // User says just "the" for multi-word sentence
    viewModel.startRecording()
    let partialResult = SpeechEvaluationResult(
        targetSentence: viewModel.state.steps[2].targetText,
        spokenText: "the",
        tokens: [],
        overallScore: 15.0,
        isPassed: false,
        durationMs: 500
    )
    mockSpeechAssessment.simulateProgress(partialResult)

    XCTAssertFalse(viewModel.state.isStepEvaluated, "Single word must not trigger premature pass")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter QuickReflexDrillViewModelTests`
Expected: Compilation failure or assertion failure.

- [ ] **Step 3: Update `QuickReflexDrillViewModel.swift`, `QuickReflexDrillSheetView.swift`, and `AppContainer.swift`**

In `QuickReflexDrillViewModel.swift`:
```swift
public var speechEvaluationResult: SpeechEvaluationResult?
private let speechAssessmentService: SpeechAssessmentProtocol?

public init(
    targetWord: WordItem,
    allWords: [WordItem],
    ttsService: TextToSpeechProtocol? = nil,
    sttService: SpeechRecognitionProtocol? = nil,
    speechAssessmentService: SpeechAssessmentProtocol? = nil,
    evaluateSRSUseCase: EvaluateSRSUseCaseProtocol? = nil
) {
    self.targetWord = targetWord
    self.allWords = allWords
    self.ttsService = ttsService ?? TextToSpeechService()
    self.sttService = sttService ?? SpeechRecognitionService()
    self.speechAssessmentService = speechAssessmentService
    self.evaluateSRSUseCase = evaluateSRSUseCase
    generateSteps()
    startTimer()
}

public var isListening: Bool {
    if let assessment = speechAssessmentService {
        return assessment.isListening
    }
    return (sttService as? SpeechRecognitionService)?.isListening ?? sttService.isListening
}

public var recognizedText: String {
    if let eval = speechEvaluationResult, !eval.spokenText.isEmpty {
        return eval.spokenText
    }
    return (sttService as? SpeechRecognitionService)?.recognizedText ?? sttService.recognizedText
}

public func startRecording() {
    guard !isListening && !state.isStepEvaluated else { return }
    ttsService.stop()
    state.errorMessage = nil
    speechEvaluationResult = nil

    guard state.currentStepIndex < state.steps.count else { return }
    let currentStep = state.steps[state.currentStepIndex]

    if let assessment = speechAssessmentService {
        assessment.startAssessing(
            targetSentence: currentStep.targetText,
            toleranceThreshold: 0.75,
            contextualPhrases: [targetWord.lemma, currentStep.targetText],
            onProgress: { [weak self] evaluation in
                guard let self = self else { return }
                self.speechEvaluationResult = evaluation
            },
            onCompletion: { [weak self] evaluation in
                guard let self = self else { return }
                self.speechEvaluationResult = evaluation
                self.stopRecordingAndEvaluate()
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.state.errorMessage = "Không thể thu âm: \(error.localizedDescription). Vui lòng kiểm tra quyền Micro."
            }
        )
    } else {
        sttService.startListening(
            onResult: { [weak self] text in
                guard let self = self else { return }
                if self.isAnswerMatching(userText: text, targetText: currentStep.targetText) {
                    self.stopRecordingAndEvaluate()
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.state.errorMessage = "Không thể thu âm: \(error.localizedDescription)."
            }
        )
    }
}

public func stopRecordingAndEvaluate() {
    speechAssessmentService?.stopAssessing()
    sttService.stopListening()

    let answer = recognizedText
    if !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        submitAnswer(answer)
    } else {
        state.errorMessage = "Chưa nghe thấy câu trả lời. Hãy chạm micro và đọc câu mẫu."
    }
}

private func isAnswerMatching(userText: String, targetText: String) -> Bool {
    let u = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    let t = targetText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    guard !u.isEmpty, !t.isEmpty else { return false }

    if let eval = speechEvaluationResult, state.currentStepIndex < state.steps.count, state.steps[state.currentStepIndex].type == .pronunciation {
        return eval.isPassed
    }

    return u == t
}
```

In `QuickReflexDrillSheetView.swift`:
```swift
VocabSpeechVisualizerView(
    isListening: viewModel.isListening,
    recognizedText: viewModel.recognizedText,
    placeholderText: String(localized: "reflex.micPlaceholder"),
    evaluationResult: viewModel.speechEvaluationResult
)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter QuickReflexDrillViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/Features/Vocabulary
git commit -m "feat(quick-reflex): integrate SpeechKit assessment, word tokens highlighting, and fix single-word bug"
```

---

### Task 4: Full Verification and Regression Test Suite

**Files:**
- All modified code & test files across the repository

- [ ] **Step 1: Run full test suite**

Run: `swift test`
Expected: All tests PASS with 0 failures across XCTest and Swift Testing suites.

- [ ] **Step 2: Verify Xcode scheme build settings and warnings**

Run: `swift build`
Expected: Clean build without errors or warnings.

- [ ] **Step 3: Commit all remaining changes and update plan status**

```bash
git status
git add .
git commit -m "chore(speech): verify all unit tests and finalize speech engine synchronization"
```
