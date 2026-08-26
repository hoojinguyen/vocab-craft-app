# CraftVoiceMatchCard UI & Word-Matching Component Design Spec

**Author:** Senior iOS & SwiftUI Design Agent  
**Date:** 2026-08-26  
**Target:** CraftUIKit Component Addition — `CraftVoiceMatchCard`  
**Platforms:** iOS 17.0+ (SwiftUI, Xcode 16+)

---

## 1. Overview & Objective

`CraftVoiceMatchCard` is a standalone, reusable SwiftUI component built natively within `CraftUIKit` to serve speaking drills, pronunciation assessments, and voice reflex exercises across the application.

### Key Tenets:
1. **Strict UI-Only Separation**: All speech-to-text, audio engine recording, microphone permissions, and scoring logic reside externally within the app (`VocabCraftApp` / `SpeechKit`). `CraftUIKit` only consumes state/properties and emits user actions (`onTapMic`, `onReset`).
2. **Dual-Input Token Matching Engine**:
   - **Real-time / Text Mode**: Accepts `originText: String` and streaming `actualText: String?`. Uses a built-in lightweight normalization and sequence diff algorithm to automatically highlight words as the user speaks.
   - **Explicit Token Mode**: Accepts pre-computed `[CraftSpeechWordToken]` from advanced phoneme/fuzzy assessment services.
3. **Multi-State Tactile Mic Control Hub**: Prominent tactile microphone button featuring multi-tier pulsing aura rings, audio level waveform visualizer integration, dynamic icon transitions, and haptic sensory feedback.
4. **100% Bilingual Parity & Zero Hardcoded Strings**: Full compliance with `craft.*` naming taxonomy across English and Vietnamese localizations.

---

## 2. Visual Hierarchy & Architecture

```
┌────────────────────────────────────────────────────────┐
│ [Optional Subtitle / Translation / IPA: "Đó là..."]    │
│                                                        │
│  [It]  [was]  [a]  [good]  [job.]  ← (Word Match Flow) │
│  (✓ xanh)       (⚡ cam)  (✓ xanh)                     │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ ılılıllı [CraftWaveformView] (Active Audio Bar)   │  │
│  │ "live transcript text..."                        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│                       ╭───────╮                        │
│                      │ 🎙️ Mic │ ← (Pulsing Aura Ring)  │
│                       ╰───────╯                        │
│               "Tap to speak" / "Listening..."          │
└────────────────────────────────────────────────────────┘
```

---

## 3. Data Models & API Contracts

### 3.1 Status & Token Enums

```swift
/// Match status of individual target words.
public enum CraftSpeechWordStatus: String, Sendable, Equatable, CaseIterable {
    case pending       // Not spoken yet (neutral muted)
    case matched       // Correctly spoken (emerald / theme.colors.statusSuccess)
    case fuzzy         // Near-match / partial (amber / theme.colors.statusWarning)
    case mismatched    // Mispronounced or missed (coral / theme.colors.statusDanger)
}

/// Token representing a single word in the target sentence.
public struct CraftSpeechWordToken: Identifiable, Sendable, Equatable {
    public let id: String
    public let targetWord: String
    public let status: CraftSpeechWordStatus
    public let spokenWord: String?
    public let confidence: Double?

    public init(
        id: String = UUID().uuidString,
        targetWord: String,
        status: CraftSpeechWordStatus = .pending,
        spokenWord: String? = nil,
        confidence: Double? = nil
    ) {
        self.id = id
        self.targetWord = targetWord
        self.status = status
        self.spokenWord = spokenWord
        self.confidence = confidence
    }
}

/// Active interaction state of the speaking component.
public enum CraftSpeechState: Equatable, Sendable {
    case idle
    case listening(audioLevels: [CGFloat] = [])
    case processing
    case evaluated(overallScore: Double)
}
```

### 3.2 Lightweight Built-in Matching Engine (`CraftTextMatchEngine`)

A fast, pure-Swift algorithm that normalizes punctuation and performs word-level sequence comparison:
- Strips punctuation (`.`, `,`, `!`, `?`, `"`, `'`) for token comparison while preserving display punctuation in the target word.
- Converts target sentence into an array of `CraftSpeechWordToken`.
- Matches recognized streaming words sequentially or via Levenshtein edit distance:
  - Exact normalized match -> `.matched`
  - Normalized edit distance <= 1 or prefix match -> `.fuzzy`
  - Unmatched after processing -> `.mismatched`
  - Unspoken remainder -> `.pending`

### 3.3 Main Component Interface (`CraftVoiceMatchCard`)

```swift
public struct CraftVoiceMatchCard: View {
    public let originText: String
    public let actualText: String?
    public let explicitTokens: [CraftSpeechWordToken]?
    public let subtitle: String?
    public let speechState: CraftSpeechState
    public let customInstruction: String?
    public let onTapMic: () -> Void
    public let onReset: (() -> Void)?

    public init(
        originText: String,
        actualText: String? = nil,
        explicitTokens: [CraftSpeechWordToken]? = nil,
        subtitle: String? = nil,
        speechState: CraftSpeechState = .idle,
        customInstruction: String? = nil,
        onTapMic: @escaping () -> Void,
        onReset: (() -> Void)? = nil
    ) {
        self.originText = originText
        self.actualText = actualText
        self.explicitTokens = explicitTokens
        self.subtitle = subtitle
        self.speechState = speechState
        self.customInstruction = customInstruction
        self.onTapMic = onTapMic
        self.onReset = onReset
    }
}
```

---

## 4. UI Components & Micro-Interactions

1. **`CraftSpeechWordFlowLayout` & `CraftSpeechWordTokenView`**:
   - Wrap/Flow layout supporting multiline sentences, centered alignment.
   - Smooth spring scale and color transition when token status updates.
   - Token chip badges with status-tinted background, stroke, and optional icon (e.g. checkmark for matched).
2. **Real-Time Visualizer**:
   - Uses `CraftWaveformView` to visualize incoming `audioLevels`.
   - Displays live `actualText` transcript preview with typography emphasis.
3. **Tactile Mic Hub**:
   - 80x80pt circular button with `LinearGradient` fill.
   - Dynamic `CraftPulsingAuraRing` animation when `speechState == .listening`.
   - Sensory feedback triggered on mic tap.
   - Localized status caption beneath the mic button.

---

## 5. Localization Taxonomy (`craft.speech.*`)

Added to `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:

| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `craft.speech.tap_to_speak` | "Tap to speak" | "Chạm để nói" |
| `craft.speech.listening` | "Listening..." | "Đang lắng nghe..." |
| `craft.speech.analyzing` | "Analyzing pronunciation..." | "Đang phân tích phát âm..." |
| `craft.speech.try_again` | "Try speaking again" | "Thử nói lại" |
| `craft.speech.mic_start_a11y` | "Start speaking" | "Bắt đầu nói" |
| `craft.speech.mic_stop_a11y` | "Stop recording" | "Dừng ghi âm" |
| `craft.speech.score_format` | "Score: %lld%%" | "Điểm: %lld%%" |

---

## 6. Verification & Test Plan

1. **Engine & Token Diffing Unit Tests**:
   - Exact sentence matching tests.
   - Partial sentence streaming tests (words matching in real-time).
   - Case-insensitivity and punctuation stripping tests.
   - Fuzzy match tolerance tests.
2. **SwiftUI Component Tests & Previews**:
   - `CraftVoiceMatchCard` idle state.
   - `CraftVoiceMatchCard` listening state with simulated audio waveform levels.
   - `CraftVoiceMatchCard` evaluating state with spinner.
   - `CraftVoiceMatchCard` completed/evaluated state with score badge and token highlights.
3. **Localization Tests**:
   - `swift test --filter LocalizationTests` to guarantee 100% EN/VI pair completeness and format specifier match.
