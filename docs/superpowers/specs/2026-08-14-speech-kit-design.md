# SpeechKit: High-Accuracy, Accent-Tolerant On-Device Speech Evaluation Engine

- **Author**: Antigravity & hoojinguyen
- **Date**: 2026-08-14
- **Status**: Approved Design Specification
- **Target Platform**: iOS 17.0+ (Swift 5.10+, Observation Framework)

---

## 1. Overview & Problem Statement

### 1.1 The Challenge
In language learning and reflex drill applications, non-native English speakers frequently struggle with default speech recognition engines (e.g. standard `SFSpeechRecognizer`). Standard STT engines are tuned for native dictation; minor accent inflections, omitted final consonants (e.g., `/s/`, `/ed/`), or dialect variations cause the acoustic decoder to substitute entire words, resulting in false negatives and frustrating user experience.

### 1.2 Objectives
1. **High Accuracy & Accent Tolerance**: Tolerate common ESL / Vietnamese accent discrepancies, contractions, and plural/tense inflections while correctly validating sentence comprehension.
2. **Instant Reflex Response (0ms Latency)**: 100% on-device processing with immediate threshold checking ($\ge 75\%$) for reflex fluency drills.
3. **Smart Voice Interaction (Auto-Stop)**: Immediate success evaluation when threshold is reached during speech, plus automatic stop after 1.3s of silence when speech concludes.
4. **Self-Contained "Kit" Architecture**: Modularized under `VocabCraftApp/Core/SpeechKit/` following Clean Architecture and Apple modern guidelines (zero external SPM package resolution overhead, ready to be extracted into a standalone CocoaPod or Swift Package if needed in the future).
5. **Real-time Word Token Highlighting**: Visual feedback indicating matched (green), fuzzy-matched (yellow/light green), and missing (muted gray) words.

---

## 2. System Architecture & Module Boundaries

Following Clean Architecture and `swift-architecture` guidelines, `SpeechKit` operates as an independent Core Infrastructure module. View models depend solely on protocols and domain models.

```
┌───────────────────────────────────────────────────────────┐
│ Presentation Layer (VocabCraftApp/Features/ReflexDrill)   │
│ - ReflexDrillViewModel (@Observable)                      │
│ - ReflexDrillView / VocabSpeechVisualizerView             │
└─────────────────────────────┬─────────────────────────────┘
                              │ (Depends on Protocol)
                              ▼
┌───────────────────────────────────────────────────────────┐
│ Domain Layer (VocabCraftApp/Domain)                       │
│ - SpeechAssessmentProtocol                                │
│ - SpeechEvaluationResult, WordTokenResult                 │
└─────────────────────────────▲─────────────────────────────┘
                              │ (Implements Protocol)
┌─────────────────────────────┴─────────────────────────────┐
│ Core Layer: SpeechKit (VocabCraftApp/Core/SpeechKit)      │
│ ├── Engine/                                               │
│ │   ├── SpeechRecognitionEngine.swift                     │
│ │   └── SilenceDetector.swift                             │
│ ├── Evaluation/                                           │
│ │   ├── FuzzySpeechMatcher.swift                          │
│ │   ├── StringNormalizer.swift                            │
│ │   └── SequenceAligner.swift                             │
│ ├── Models/                                               │
│ │   ├── SpeechEvaluationResult.swift                      │
│ │   └── WordTokenResult.swift                             │
│ └── UI/                                                   │
│     └── SpeechWordHighlightView.swift                     │
└───────────────────────────────────────────────────────────┘
```

### 2.1 SPM & Build Optimization Analysis (`spm-build-analysis`)
- Placing the kit within `VocabCraftApp/Core/SpeechKit/` avoids redundant `ScanDependencies`, `SwiftEmitModule`, and package resolution cycles during Xcode clean/incremental builds.
- The module has **zero dependencies** on app storage, database, or external third-party SDKs, relying exclusively on Apple's standard frameworks (`Foundation`, `AVFoundation`, `Speech`, `SwiftUI`).

---

## 3. Detailed Component Specifications

### 3.1 Audio Pipeline & Acoustic Biasing (`SpeechRecognitionEngine`)
- **Contextual Biasing**: Passes the expected sentence and keywords into `SFSpeechAudioBufferRecognitionRequest.contextualStrings = [targetSentence, promptText...]`. This biases Apple's acoustic-language model towards the drill vocabulary.
- **Audio Session & Engine**: Configures `AVAudioSession` with `.playAndRecord`, `.measurement` mode, and `.allowBluetoothHFP`.
- **Live Stream**: Emits partial transcriptions via Swift async streams or closures to the evaluation engine in real-time.

### 3.2 Smart Silence Detector (`SilenceDetector`)
- Tracks speech activity state (`hasSpoken: Bool`).
- When speech starts and a partial transcription arrives, a debounce timer of `1.3 seconds` is scheduled and continuously reset with every incoming audio buffer/partial string.
- If `1.3 seconds` elapses after speech without new tokens, the detector automatically ends recording and triggers final score calculation.
- Manual mic tap stops immediately and bypasses silence wait time.

### 3.3 Text Normalization & Contraction Dictionary (`StringNormalizer`)
- **Case & Punctuation**: Lowercases text, strips punctuation marks (`,`, `.`, `?`, `!`, `"`), and trims whitespaces.
- **Contraction Expansion**: Bidirectionally handles common English contractions:
  - `"i'm"` $\leftrightarrow$ `"i am"`
  - `"you're"` $\leftrightarrow$ `"you are"`
  - `"it's"` $\leftrightarrow$ `"it is"`
  - `"don't"` $\leftrightarrow$ `"do not"`
  - `"doesn't"` $\leftrightarrow$ `"does not"`
  - `"didn't"` $\leftrightarrow$ `"did not"`
  - `"can't"` $\leftrightarrow$ `"cannot"` / `"can not"`
  - `"won't"` $\leftrightarrow$ `"will not"`
  - `"they're"` $\leftrightarrow$ `"they are"`
  - `"we're"` $\leftrightarrow$ `"we are"`
  - `"haven't"` $\leftrightarrow$ `"have not"` / `"hasn't"` $\leftrightarrow$ `"has not"`
- **Number & Digit Normalization**: Converts `"1"` $\leftrightarrow$ `"one"`, `"2"` $\leftrightarrow$ `"two"`, etc.

### 3.4 Sequence Alignment & Fuzzy Matching (`FuzzySpeechMatcher` & `SequenceAligner`)
- **Word Similarity Function**: Computes normalized Levenshtein distance ratio:
  $$\text{Ratio}(w_1, w_2) = 1.0 - \frac{\text{LevenshteinDistance}(w_1, w_2)}{\max(\text{len}(w_1), \text{len}(w_2))}$$
- **Token Classification**:
  - `exactMatch` (Score = 1.0): Exact string match.
  - `fuzzyMatch` (Score = 0.75 - 0.99): Levenshtein ratio $\ge 0.75$ (tolerates missing plural/tense suffixes like `jump` vs `jumps`, `walk` vs `walked`).
  - `missing` (Score = 0.0): Word omitted or distance $< 0.75$.
- **Sequence Alignment Algorithm**: Uses dynamic programming (Longest Common Subsequence variant) to match user words against target words in left-to-right order without losing alignment if filler words (e.g., *"um"*, *"ah"*, *"like"*) are inserted.
- **Overall Sentence Score**:
  $$\text{OverallScore} = \frac{\sum_{i=1}^{N} \text{TokenScore}_i}{N} \times 100\%$$
- **Pass Threshold**: Default `75.0%`. If `overallScore >= 75.0%`, the response is evaluated as `isPassed = true`.

---

## 4. Data Models & Protocol Contracts

### 4.1 Data Models
```swift
public enum WordMatchStatus: String, Sendable, Equatable {
    case exactMatch   // 100% match
    case fuzzyMatch   // Tolerated accent / inflection (>= 75%)
    case missing      // Not spoken or incorrect
}

public struct WordTokenResult: Identifiable, Sendable, Equatable {
    public let id: Int
    public let targetWord: String
    public let spokenWord: String?
    public let status: WordMatchStatus
    public let similarityScore: Double
}

public struct SpeechEvaluationResult: Sendable, Equatable {
    public let targetSentence: String
    public let spokenText: String
    public let tokens: [WordTokenResult]
    public let overallScore: Double // 0.0 to 100.0
    public let isPassed: Bool       // overallScore >= 75.0
    public let durationMs: Int
}
```

### 4.2 Protocol Definition
```swift
@MainActor
public protocol SpeechAssessmentProtocol: AnyObject {
    var isListening: Bool { get }
    var currentEvaluation: SpeechEvaluationResult? { get }
    
    func startAssessing(
        targetSentence: String,
        toleranceThreshold: Double,
        onProgress: @escaping (SpeechEvaluationResult) -> Void,
        onCompletion: @escaping (SpeechEvaluationResult) -> Void,
        onError: @escaping (Error) -> Void
    )
    
    func stopAssessing()
}
```

---

## 5. UI & Presentation Integration

### 5.1 `VocabSpeechVisualizerView` & Word Highlighting
- Displays token chips dynamically during speech:
  - **Green background/text**: `exactMatch`
  - **Yellow/Light Green background/text**: `fuzzyMatch`
  - **Muted gray**: `missing`
- When evaluated, displays score badge (e.g. `⚡️ 88% Match • 1.6s`) with sparkle animation when passed.

### 5.2 `ReflexDrillViewModel` Wiring
- Replaces legacy exact string matching `isCorrectAnswer` with `SpeechAssessmentProtocol`.
- Immediate completion when `evaluationResult.isPassed == true` for maximum reflex satisfaction.
- Integrates cleanly with existing Spaced Repetition System (`EvaluateSRSUseCaseProtocol`).

---

## 6. Edge Cases & Error Handling

| Scenario | Handling Strategy |
| :--- | :--- |
| **Microphone permission denied** | Returns `SpeechKitError.microphoneNotAuthorized`, prompts user with UI alert to open Settings. |
| **Speech recognition unauthorized** | Returns `SpeechKitError.speechRecognitionNotAuthorized`. |
| **Background noise / short breath** | Minimum token duration and speech detection threshold prevents false trigger of completion. |
| **Rapid mic taps (debouncing)** | Engine safely cancels active tasks and resets audio engine without audio session crashes. |
| **Audio interruptions (Phone call / Siri)** | Listens to `AVAudioSession.interruptionNotification`, automatically stops assessment and preserves partial results. |

---

## 7. Verification & Testing Strategy

1. **Unit Tests (`VocabSpeechKitTests`)**:
   - `StringNormalizerTests`: Test contractions (`"don't"`, `"I'm"`, `"can't"`), numbers, punctuation removal.
   - `FuzzySpeechMatcherTests`: Test accent variations (`"a black dog jump over fence"` vs `"a black dog jumps over the fence"`), inflections, missing articles, filler words.
   - `SequenceAlignerTests`: Test order preservation and resilience to extraneous words.
2. **ViewModel Integration Tests (`ReflexDrillViewModelTests`)**:
   - Test mock speech evaluation stream, threshold pass triggering, and SRS rating updates.
3. **Manual Audio Verification on Device / Simulator**:
   - Simulator: Automated mock speech stream verification.
   - Physical iOS Device: Real-time speaking with various pronunciation speeds and accent variations.
