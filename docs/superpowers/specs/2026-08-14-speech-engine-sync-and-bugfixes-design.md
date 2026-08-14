# Speech Engine Synchronization & Critical Voice Flaws Resolution Design

**Date:** 2026-08-14  
**Author:** AI Pair Programmer & Lead iOS Engineer  
**Status:** Approved for Implementation  
**Scope:** Core SpeechKit Engine, Reflex Drill Feature, Quick Reflex Drill Feature, Audio Session Routing, and Word Highlighting UI.

---

## 1. Executive Summary & Goals

This specification defines the architectural improvements and bug fixes to achieve 100% reliable, synchronized speech assessment across two core features:
1. **Reflex Drill** (`ReflexDrillView`, `ReflexDrillViewModel`)
2. **Luyện phản xạ nhanh / Quick Reflex Drill** (`QuickReflexDrillSheetView`, `QuickReflexDrillViewModel`)

### Key Objectives
1. **Fix premature silence auto-stop:** Replace single-timer detector with a dual-phase silence detector (5.0s initial preparation timeout, 1.3s trailing silence after speech activity).
2. **Prevent premature Instant Reflex cutoff:** Ensure partial recognition triggers Instant Pass only when spoken token count reaches $\ge 85\%$ of the target sentence length or matches all target words.
3. **Fix un-evaluated limbo state in Reflex Drill:** Ensure `onCompletion` always invokes `evaluateAnswer` even when the evaluation fails or times out.
4. **Fix false 100% pass on single words in Quick Reflex Drill:** Eliminate naive `t.contains(u)` string checking and adopt `SpeechAssessmentProtocol` across the pronunciation step.
5. **Fix low-volume audio on TTS playback:** Ensure `AVAudioSession` options include `.defaultToSpeaker` alongside `.playAndRecord` and `.allowBluetoothHFP`.
6. **Graceful On-Device Speech Fallback:** Prevent `SpeechRecognitionEngine` crashes on Simulator or non-downloaded offline models by gracefully falling back from strict on-device requirement to standard recognition.
7. **Unified Word Highlighting UI:** Wire `VocabSpeechVisualizerView` and `SpeechWordHighlightView` in Quick Reflex Drill with `SpeechEvaluationResult`.

---

## 2. Architecture & Detailed Component Changes

### A. Core SpeechKit Layer (`VocabCraftApp/Core/SpeechKit/`)

#### 1. `SilenceDetector.swift`
- **Current State:** Single 1.3s timer started immediately via `arm()`. If the user pauses for > 1.3s before speaking, they immediately fail with an empty string.
- **Target State:**
  - `initialSilenceDuration: Duration` (default: 5.0s) for initial speech onset.
  - `trailingSilenceDuration: Duration` (default: 1.3s) after speech activity is registered.
  - `hasRegisteredActivity: Bool` tracks whether speech has begun.
  - `registerActivity()` switches active timer from initial to trailing duration.
  - `cancel()` cleanly terminates pending tasks.

#### 2. `SpeechRecognitionEngine.swift`
- **Audio Session Category:**
  ```swift
  try audioSession.setCategory(
      .playAndRecord,
      mode: .measurement,
      options: [.defaultToSpeaker, .allowBluetoothHFP]
  )
  ```
- **On-Device Requirement:**
  ```swift
  let request = SFSpeechAudioBufferRecognitionRequest()
  if let recognizer = speechRecognizer, recognizer.supportsOnDeviceRecognition {
      request.requiresOnDeviceRecognition = true
  } else {
      request.requiresOnDeviceRecognition = false
  }
  ```
  Do not throw `recognizerUnavailable` solely because `supportsOnDeviceRecognition` is false.

#### 3. `SpeechAssessmentService.swift`
- **Dual-Timer Initialization:**
  ```swift
  let detector = SilenceDetector(
      initialSilenceDuration: .seconds(5),
      trailingSilenceDuration: silenceDuration
  ) { [weak self] in ... }
  ```
- **Instant Pass Refinement:**
  Instant Reflex Pass triggers if:
  - `eval.isPassed == true` AND
  - (`eval.tokens.filter { $0.status != .missing }.count >= max(1, Int(Double(eval.tokens.count) * 0.85))` OR `eval.overallScore >= 95.0`)

---

### B. Reflex Drill Feature (`VocabCraftApp/Features/ReflexDrill/`)

#### `ReflexDrillViewModel.swift`
- In `startVoiceRecognition()`:
  ```swift
  onCompletion: { [weak self] evaluation in
      guard let self = self else { return }
      self.speechEvaluationResult = evaluation
      self.internalRecognizedText = evaluation.spokenText
      self.evaluateAnswer(evaluation.spokenText)
  }
  ```
- Guaranteed state evaluation: Regardless of whether `evaluation.isPassed` is `true` or `false`, the drill always exits the listening state, stops the timer, and computes the SRS result with feedback.

---

### C. Quick Reflex Drill Feature (`VocabCraftApp/Features/Vocabulary/`)

#### 1. `QuickReflexDrillViewModel.swift`
- Inject `speechAssessmentService: SpeechAssessmentProtocol?` in initializer.
- Expose `@Observable public var speechEvaluationResult: SpeechEvaluationResult?`.
- In Step 3 (`.pronunciation`):
  - Call `speechAssessmentService.startAssessing(targetSentence: currentStep.targetText, contextualPhrases: [targetWord.lemma, currentStep.targetText], onProgress: ..., onCompletion: ..., onError: ...)`.
  - Handle `onProgress` to update `speechEvaluationResult`.
  - Handle `onCompletion` to invoke `submitAnswer(evaluation.spokenText, isPassed: evaluation.isPassed)`.
- In `isAnswerMatching`:
  - For Step 1 (Meaning choice) & Step 2 (Fill in blank choice): Exact matching (`cleanUser == cleanTarget`).
  - For Step 3: `speechEvaluationResult?.isPassed ?? false` (or `FuzzySpeechMatcher.similarityRatio >= 0.75`).
  - Remove buggy `target.contains(user)` logic.

#### 2. `QuickReflexDrillSheetView.swift`
- Pass `evaluationResult: viewModel.speechEvaluationResult` into `VocabSpeechVisualizerView`.
- Render live word chips with exact/fuzzy/missing color badges.

---

## 3. Verification & Testing Strategy

1. **`SilenceDetectorTests`**:
   - Verify initial 5s timeout fires if no activity is registered.
   - Verify `registerActivity()` resets timer to 1.3s trailing duration.
2. **`SpeechAssessmentServiceTests`**:
   - Verify partial results with < 85% token coverage do not prematurely trigger completion.
   - Verify final completion callback triggers on failure.
3. **`ReflexDrillViewModelSpeechTests`**:
   - Verify failed speech assessment transitions state to `.isEvaluated = true` and `isCorrect = false`.
4. **`QuickReflexDrillViewModelTests`**:
   - Verify Step 3 speech evaluation using `MockSpeechAssessmentService`.
   - Verify single-word utterance on multi-word sentence fails and does not auto-pass.
5. **End-to-End Test Suite**:
   - `swift test` passes 100% with zero regressions.
