# SpeechKit: High-Accuracy, Accent-Tolerant Speech Evaluation Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a modular, on-device, accent-tolerant speech evaluation kit (`SpeechKit`) that delivers instant reflex scoring ($\ge 75\%$), dynamic word-level highlighting, smart silence detection, and contextual biasing for English learners.

**Architecture:** A self-contained Core layer (`VocabCraftApp/Core/SpeechKit/`) following Clean Architecture with strict protocol boundaries (`SpeechAssessmentProtocol`), token sequence alignment, Levenshtein fuzzy scoring, contraction normalization, and `SFSpeechAudioBufferRecognitionRequest.contextualStrings` biasing.

**Tech Stack:** Swift 5.10+, iOS 17+, Speech framework (`SFSpeechRecognizer`), AVFoundation (`AVAudioEngine`), Observation framework, SwiftUI, Swift Testing.

**Spec:** [`docs/superpowers/specs/2026-08-14-speech-kit-design.md`](../specs/2026-08-14-speech-kit-design.md)

## Global Constraints
- Target Platform: iOS 17.0+, macOS 14.0+
- 100% On-device, 0 third-party cloud API costs, 0 external package resolution overhead
- Default tolerance threshold: 75.0% (0.75)
- Smart auto-stop silence threshold: 1.3 seconds
- Protocol-driven: UI & ViewModels only depend on `SpeechAssessmentProtocol` and domain structs

---

### Task 1: Core Models & Protocol Contracts

**Files:**
- Create: `VocabCraftApp/Core/SpeechKit/Models/WordMatchStatus.swift`
- Create: `VocabCraftApp/Core/SpeechKit/Models/WordTokenResult.swift`
- Create: `VocabCraftApp/Core/SpeechKit/Models/SpeechEvaluationResult.swift`
- Create: `VocabCraftApp/Core/SpeechKit/Models/SpeechKitError.swift`
- Create: `VocabCraftApp/Core/SpeechKit/Protocols/SpeechAssessmentProtocol.swift`
- Test: `VocabCraftAppTests/SpeechKitTests/SpeechKitModelTests.swift`

**Interfaces:**
- Produces:
  - `enum WordMatchStatus: String, Sendable, Equatable { case exactMatch, fuzzyMatch, missing }`
  - `struct WordTokenResult: Identifiable, Sendable, Equatable`
  - `struct SpeechEvaluationResult: Sendable, Equatable`
  - `enum SpeechKitError: Error, LocalizedError, Equatable`
  - `protocol SpeechAssessmentProtocol: AnyObject`

- [ ] **Step 1: Write the failing unit tests for Core Models & Protocol defaults**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `WordMatchStatus`, `WordTokenResult`, `SpeechEvaluationResult`, `SpeechKitError`, and `SpeechAssessmentProtocol`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Core/SpeechKit/Models VocabCraftApp/Core/SpeechKit/Protocols VocabCraftAppTests/SpeechKitTests/SpeechKitModelTests.swift
git commit -m "feat(speechkit): add core models and speech assessment protocol"
```

---

### Task 2: String Normalization & Contraction Mapping (`StringNormalizer`)

**Files:**
- Create: `VocabCraftApp/Core/SpeechKit/Evaluation/StringNormalizer.swift`
- Test: `VocabCraftAppTests/SpeechKitTests/StringNormalizerTests.swift`

**Interfaces:**
- Consumes: Task 1 models
- Produces:
  - `public enum StringNormalizer { public static func normalize(_ text: String) -> String; public static func tokenize(_ text: String) -> [String]; public static func expandContractions(_ text: String) -> String }`

- [ ] **Step 1: Write failing tests for normalization, contractions ("i'm" -> "i am", "don't" -> "do not", "can't" -> "cannot", "1" -> "one") and punctuation trimming**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `StringNormalizer` with comprehensive bidirectional contraction map and tokenizer**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Core/SpeechKit/Evaluation/StringNormalizer.swift VocabCraftAppTests/SpeechKitTests/StringNormalizerTests.swift
git commit -m "feat(speechkit): implement StringNormalizer with contraction expansion"
```

---

### Task 3: Levenshtein Distance & Token Sequence Alignment (`FuzzySpeechMatcher`, `SequenceAligner`)

**Files:**
- Create: `VocabCraftApp/Core/SpeechKit/Evaluation/SequenceAligner.swift`
- Create: `VocabCraftApp/Core/SpeechKit/Evaluation/FuzzySpeechMatcher.swift`
- Test: `VocabCraftAppTests/SpeechKitTests/FuzzySpeechMatcherTests.swift`

**Interfaces:**
- Consumes: `StringNormalizer`, `SpeechEvaluationResult`, `WordTokenResult`, `WordMatchStatus`
- Produces:
  - `public enum FuzzySpeechMatcher { public static func evaluate(spokenText: String, targetSentence: String, passThreshold: Double = 0.75) -> SpeechEvaluationResult; public static func similarityRatio(_ s1: String, _ s2: String) -> Double }`

- [ ] **Step 1: Write failing tests for accent variations (omitted "s", "ed", minor misspellings, extraneous filler words like "um/like", pass threshold calculation)**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `SequenceAligner` (LCS dynamic alignment) and `FuzzySpeechMatcher`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Core/SpeechKit/Evaluation/SequenceAligner.swift VocabCraftApp/Core/SpeechKit/Evaluation/FuzzySpeechMatcher.swift VocabCraftAppTests/SpeechKitTests/FuzzySpeechMatcherTests.swift
git commit -m "feat(speechkit): implement SequenceAligner and FuzzySpeechMatcher with accent tolerance"
```

---

### Task 4: Silence Detector & Acoustic Recognition Engine (`SilenceDetector`, `SpeechRecognitionEngine`, `SpeechAssessmentService`)

**Files:**
- Create: `VocabCraftApp/Core/SpeechKit/Engine/SilenceDetector.swift`
- Create: `VocabCraftApp/Core/SpeechKit/Engine/SpeechRecognitionEngine.swift`
- Create: `VocabCraftApp/Core/SpeechKit/SpeechAssessmentService.swift`
- Test: `VocabCraftAppTests/SpeechKitTests/SilenceDetectorTests.swift`
- Test: `VocabCraftAppTests/SpeechKitTests/SpeechAssessmentServiceTests.swift`

**Interfaces:**
- Consumes: `SpeechAssessmentProtocol`, `FuzzySpeechMatcher`, `SpeechEvaluationResult`, `SpeechKitError`
- Produces:
  - `public final class SilenceDetector: @unchecked Sendable`
  - `public final class SpeechRecognitionEngine: @unchecked Sendable`
  - `public final class SpeechAssessmentService: SpeechAssessmentProtocol, @unchecked Sendable`

- [ ] **Step 1: Write unit tests for silence timeout debouncing and speech assessment service lifecycle**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `SilenceDetector` (1.3s auto-stop), `SpeechRecognitionEngine` (with `contextualStrings` biasing), and `SpeechAssessmentService`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Core/SpeechKit/Engine VocabCraftApp/Core/SpeechKit/SpeechAssessmentService.swift VocabCraftAppTests/SpeechKitTests/
git commit -m "feat(speechkit): implement SilenceDetector and SpeechAssessmentService with contextual biasing"
```

---

### Task 5: Reusable Word Highlighting UI Component (`SpeechWordHighlightView`)

**Files:**
- Create: `VocabCraftApp/Core/SpeechKit/UI/SpeechWordHighlightView.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift`
- Test: `VocabCraftAppTests/SpeechKitTests/SpeechWordHighlightViewTests.swift`

**Interfaces:**
- Consumes: `SpeechEvaluationResult`, `WordTokenResult`, `WordMatchStatus`
- Produces:
  - `public struct SpeechWordHighlightView: View`
  - Enhanced `VocabSpeechVisualizerView` accepting optional `evaluationResult: SpeechEvaluationResult?`

- [ ] **Step 1: Write snapshot / view unit tests verifying word color mapping (.exactMatch -> green, .fuzzyMatch -> yellow/mint, .missing -> gray)**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `SpeechWordHighlightView` and integrate token chips into `VocabSpeechVisualizerView`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Core/SpeechKit/UI/SpeechWordHighlightView.swift VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift VocabCraftAppTests/SpeechKitTests/SpeechWordHighlightViewTests.swift
git commit -m "feat(speechkit): add SpeechWordHighlightView and enhance VocabSpeechVisualizerView"
```

---

### Task 6: Wire SpeechKit into App DI & `ReflexDrillViewModel`

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/App/DI/EnvironmentKeys.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexDrillViewModel.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/ReflexDrillView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrillViewModelSpeechTests.swift`

**Interfaces:**
- Consumes: `SpeechAssessmentProtocol`, `SpeechAssessmentService`, `VocabSpeechVisualizerView`
- Produces:
  - Instant reflex evaluation when score $\ge 75\%$
  - Real-time word highlight updates
  - Clean dependency injection via `AppContainer.speechAssessmentService`

- [ ] **Step 1: Write integration tests for `ReflexDrillViewModel` verifying speech assessment flow, early pass trigger, and silence auto-stop**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Update `AppContainer`, `EnvironmentKeys`, `ReflexDrillViewModel`, and `ReflexDrillView`**
- [ ] **Step 4: Run full test suite to verify all unit and integration tests pass**
- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/App/DI VocabCraftApp/Features/ReflexDrill VocabCraftAppTests/
git commit -m "feat(reflex): wire SpeechKit into ReflexDrillViewModel with instant evaluation"
```
