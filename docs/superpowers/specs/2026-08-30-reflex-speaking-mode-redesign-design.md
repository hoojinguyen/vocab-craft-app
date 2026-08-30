# Reflex Speaking Mode Redesign — Full 3D Flip Card Architecture + Resilient Speech Pipeline

## Summary

Redesign the Reflex Speaking Mode to achieve full visual and architectural parity with the 3 completed modes (Multiple Choice, Listening, Typing). This includes rebuilding the view with the Dual-Zone 3D Flip Card architecture, adding `CraftTactileMicHubView` as the mic interaction hub, and replacing the crash-prone `ContinuousReflexSpeechService` with a new `ResilientReflexSpeechEngine` that separates `AVAudioEngine` lifecycle from `SFSpeechRecognitionRequest` lifecycle.

## Core Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Challenge type | **Single-word recall** (Vi def → speak English lemma) | Fits Blitz pacing, consistent with existing Speaking behavior |
| Mic interaction | **Auto-open, continuous listening** | No tap needed, mic starts when card appears |
| Mic visual | **`CraftTactileMicHubView`** on canvas below card | 72pt visual indicator, not wrapped in card |
| Outcome model | **Correct or Timeout only** — no "wrong" | User can say multiple words, any match within time limit = correct |
| Keyboard fallback | **Removed entirely** | Speaking mode is purely speaking |
| Live transcript | **Shown** via `CraftBadge` below mic hub | User sees what mic recognizes, adjusts pronunciation |
| Hint type | **Visual-only** (no TTS hint) | TTS during active challenge causes feedback loop — mic picks up speaker |
| Speech pipeline | **Resilient engine** — persistent `AVAudioEngine` + per-word `SFSpeechRecognitionRequest` | Fixes crash/lag bug from engine restart between questions |

---

## 1. Interaction Flow & State Machine

### Session Lifecycle

```
Session Start (Countdown 3-2-1)
  └─ AVAudioEngine start (1 TIME ONLY)
  └─ Mic hub: .idle
       │
       ▼
Load Word
  └─ Create NEW SFSpeechRecognitionRequest (lightweight)
  └─ Attach request to running engine
  └─ Front face: Vi def + cloze masked
  └─ Mic hub: .listening (pulsing aura)
  └─ Timer 6.0s starts
  └─ Transcript badge: empty
       │
       ▼
Active Challenge (0 – 6.0s)
  └─ User speaks → transcript updates → badge shows recognized words
  └─ Hint stages (visual-only):
       ├─ Stage 0 (0.0 – 2.5s): Vi def + cloze masked
       ├─ Stage 1 (2.5s): POS badge fade in
       ├─ Stage 2 (4.0s): Initial letter hint ("h...")
       └─ Stage 3 (5.0s): Pattern reveal ("h _ _ _ t")
  └─ Match detected → Reviewed (correct)
  └─ 6.0s elapsed → Reviewed (timeout)
       │
       ▼
Reviewed State
  └─ End recognition request (DO NOT stop engine)
  └─ Card flip → back face (consolidation)
  └─ Mic hub: .evaluated (✓ green / ⏰ neutral)
  └─ Transcript badge: shows last recognized word
  └─ Sound: success chime / timeout chime
  └─ CraftFeedbackSheet slides up from bottom
  └─ TTS pronounces target word (mic request ended → no feedback loop)
       │
       ▼
User taps "Tiếp tục"
  └─ Feedback sheet dismiss
  └─ Card flip back → front face (new word)
  └─ Create NEW SFSpeechRecognitionRequest
  └─ Loop back to "Load Word"
  └─ (AVAudioEngine NEVER restarts — still running)
       │
       ▼
Repeat until all words done
       │
       ▼
Session End
  └─ Stop AVAudioEngine
  └─ Phase → .summary
  └─ Show ReflexBlitzSummaryView
```

### TTS Safety in Reviewed State

TTS playback is safe in reviewed state because the recognition request has already been ended before TTS fires. The audio engine tap still runs but buffers are discarded (`activeRequest == nil`), so the microphone does not pick up the speaker output as a match.

---

## 2. View Architecture

### Layout — 3 Zones

```
┌─────────────────────────────────────────┐
│            ReflexBlitzView              │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │     Zone 1: CraftFlipCard         │  │
│  │     (.tactile3D)                  │  │
│  │                                   │  │
│  │  Front: Vi def + badges + cloze   │  │
│  │  Back: Lemma + IPA + speaker +    │  │
│  │        badges + sentence          │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Zone 2: Mic Hub + Transcript     │  │
│  │  (on canvas, NO card wrapper)     │  │
│  │                                   │  │
│  │     CraftTactileMicHubView        │  │
│  │     CraftBadge (transcript)       │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Zone 3: CraftFeedbackSheet       │  │
│  │  (reviewed state only, docked)    │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Zone 1 — Front Face (Active Challenge)

| Element | Component | Style |
|---|---|---|
| Vietnamese definition | `CraftText` | `.titleLarge`, `.textPrimary`, center, lineLimit 2 |
| POS badge | `CraftBadge` | `.subtle`, `.neutral`, `.capsule` — hidden stage 0, fade in stage 1 |
| CEFR badge | `CraftBadge` | `.subtle`, `.warning`, `.capsule` — always visible |
| Cloze sentence | `activeClozeText()` | Reuse `ReflexClozeStageSet` progressive reveal from MC/Typing |
| Hint badge | `CraftBadge` | `.outline`, `.warning`, `.capsule` — visible from stage 2 |

### Zone 1 — Back Face (Reviewed Consolidation)

Identical to MC/Typing/Listening back face — 5 standardized rows:

1. **Lemma** (`CraftText`, `.titleLargeSerif`) + **`CraftSpeakerButton`** (`.subtle`, `.md`) for replay
2. **IPA phonetic** (`CraftText`, `.caption`, `.textMuted`)
3. **POS + CEFR badges** (`CraftBadge`, `.subtle`)
4. **Vietnamese definition** (`CraftText`, `.titleMedium`)
5. **Full sentence** (highlighted target word, `.bodySerif`) + Vietnamese translation (`.caption`, `.textMuted`)

### Zone 2 — Mic Hub Area (on canvas)

| State | `CraftTactileMicHubView` | Transcript Badge |
|---|---|---|
| Active (listening) | `.listening` — pulsing aura, mic icon | `CraftBadge(liveTranscript, icon: "waveform", .solid, .primary, .capsule)` or `"🎤 Đang nghe..."` if empty |
| Match detected | `.evaluated` — green aura, ✓ icon | `CraftBadge(transcript, .subtle, .success, .capsule)` |
| Timeout | `.evaluated` — neutral, ⏰ icon | Badge shows last recognized word (if any), or hidden |

### Zone 3 — Feedback Sheet

Reuse `CraftFeedbackSheet` — no changes. Standard layout: status badge, combo streak pill, "Tiếp tục" CTA.

### Visual Consistency Standard

All components MUST follow the established style standard across all 4 modes:

| Component Type | Mandatory Style |
|---|---|
| `CraftFlipCard` | `.tactile3D` |
| `CraftChoiceCard` | `.tactile3D` |
| `CraftBadge` (info) | `.subtle` |
| `CraftBadge` (hint) | `.outline`, tone `.warning` |
| `CraftBadge` (result) | `.subtle`, tone `.success/.danger` |
| `CraftBadge` (live transcript) | `.solid`, tone `.primary` |
| `CraftSpeakerButton` | `.subtle` |
| `CraftFeedbackSheet` | Standard |
| `CraftButton` (CTA) | Standard primary |

No ad-hoc style mixing. Every component follows the same variant across all modes.

### File

```
Features/Reflex/Core/Components/Modes/
└── ReflexSpeakingModeView.swift    ← FULL REBUILD (~200-250 lines)
```

---

## 3. Speech Pipeline Architecture

### Problem: Engine Restart Causes Crashes

The current `ContinuousReflexSpeechService` couples `AVAudioEngine` lifecycle with `SFSpeechRecognitionRequest` lifecycle. When transitioning between words, the engine is stopped and restarted (~200ms), causing crashes, audio glitches, and recognition failures on the next question.

### Solution: Separate Engine from Request

```
Engine layer (1 time per session):
  ├─ AVAudioEngine.start()          ← Once
  └─ installTap(onBus: 0)          ← Once, forwards buffers to active request

Request layer (lightweight, per word):
  ├─ SFSpeechRecognitionRequest()   ← Create new
  ├─ recognitionTask.start()        ← Attach to running engine
  └─ endAudio() + cancel()          ← End cleanly, <1ms
```

### New Service: `ResilientReflexSpeechEngine`

```swift
@MainActor
@Observable
public final class ResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    // Observable State
    public private(set) var isSessionActive: Bool = false
    public private(set) var isWordActive: Bool = false
    public private(set) var liveTranscript: String = ""

    // Callbacks
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // Session Lifecycle (once per drill session)
    func startSession(contextualPhrases: [String])
    func stopSession()

    // Word Lifecycle (per question — lightweight)
    func beginWord(targetLemma: String, contextualPhrases: [String])
    func endWord()
}
```

### Protocol for Testability

```swift
@MainActor
public protocol ReflexSpeechEngineProtocol: AnyObject {
    var isSessionActive: Bool { get }
    var isWordActive: Bool { get }
    var liveTranscript: String { get }
    var onMatchDetected: ((String) -> Void)? { get set }
    var onTranscriptUpdate: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func startSession(contextualPhrases: [String])
    func stopSession()
    func beginWord(targetLemma: String, contextualPhrases: [String])
    func endWord()
}
```

### Internal Operation

**`startSession()`:**
1. Configure `AVAudioSession` (`.playAndRecord`, `.spokenAudio`, speaker + bluetooth options)
2. Create `AVAudioEngine`, store reference
3. Install tap on `engine.inputNode` — forwards buffers to `activeRequest` (nil-safe)
4. `engine.prepare()` → `engine.start()`
5. `isSessionActive = true`

**`beginWord(targetLemma:contextualPhrases:)`:**
1. Call `endWord()` if previous word still active
2. Create new `SFSpeechAudioBufferRecognitionRequest` (partial results enabled, contextual strings set)
3. Start recognition task with the new request
4. Recognition results → evaluate via `ReflexSpeechMatcher` against target lemma
5. Match found → fire `onMatchDetected`
6. Partial results → fire `onTranscriptUpdate`
7. `liveTranscript = ""`, `isWordActive = true`

**`endWord()`:**
1. `activeRequest?.endAudio()` — lightweight, <1ms
2. `activeTask?.cancel()` — lightweight
3. Set both to nil
4. `isWordActive = false`
5. Engine keeps running — tap still fires but buffers discarded (no active request)

**`stopSession()`:**
1. `endWord()` if active
2. Remove tap from input node
3. Stop engine
4. `isSessionActive = false`

### Apple 60s Recognition Limit — Proactive Renewal

- Track `sessionStartTime` when `startSession()` is called
- In `endWord()`: if `Date() - sessionStartTime > 50s`, set `needsEngineRenew = true`
- In next `beginWord()`: if `needsEngineRenew`, cycle engine (remove tap → stop → install tap → start → reset timer)
- Edge case: if 60s limit hits during active word, catch error code 216/1110 → immediately `endWord()` + `beginWord(same target)` — user sees brief transcript reset

### Concurrency Model

- **`@MainActor` isolation** — no `NSLock`, no manual thread dispatch
- **Structured concurrency** — recognition task callbacks dispatched to MainActor
- Consistent with existing `SpeechAssessmentService` pattern in `SpeechKit`

---

## 4. ViewModel Integration

### Dependency Change

```swift
// Old
let continuousSpeechService: ContinuousReflexSpeechProtocol

// New
let speechEngine: ReflexSpeechEngineProtocol
```

### Method Mapping

| Old (`ContinuousReflexSpeechService`) | New (`ResilientReflexSpeechEngine`) |
|---|---|
| `startSession(contextualPhrases:)` | `startSession(contextualPhrases:)` |
| `stopSession()` | `stopSession()` |
| `setTargetWord(lemma:, contextualPhrases:)` | `beginWord(targetLemma:, contextualPhrases:)` |
| `pauseListening()` | `endWord()` |
| `resumeListening()` | *(not needed — `beginWord` resumes)* |
| `resetBuffer()` | *(not needed — each word has its own request)* |

### Removed Code

- `isKeyboardFallbackActive` property and all keyboard fallback logic
- `submitKeyboardInput()` method
- `pauseListening()` / `resumeListening()` calls scattered across ViewModel
- `resetBuffer()` calls
- Thread dispatch boilerplate in callback bindings (`Thread.isMainThread` / `MainActor.assumeIsolated`)

### Simplified Callback Binding

```swift
private func setupSpeechBindings() {
    speechEngine.onMatchDetected = { [weak self] matched in
        self?.handleSpokenMatch(matched)
    }
    speechEngine.onTranscriptUpdate = { [weak self] transcript in
        self?.liveTranscript = transcript
    }
    speechEngine.onError = { [weak self] _ in
        // Show error state on mic hub — no keyboard fallback
    }
}
```

### Impact Summary

| File | Change |
|---|---|
| `ReflexBlitzViewModel.swift` | Replace dependency type, simplify 5 call sites, remove keyboard fallback |
| `ReflexBlitzViewModel+Configuration.swift` | Update DI init |
| `ReflexBlitzView.swift` | Remove keyboard fallback UI branch for speaking |
| `ReflexSpeakingModeView.swift` | **Full rebuild** |
| `ResilientReflexSpeechEngine.swift` | **New file** |
| `ReflexSpeechEngineProtocol.swift` | **New file** |
| `MockResilientReflexSpeechEngine.swift` | **New file** |
| Tests | Update mock type, remove keyboard fallback tests, add new engine tests |

Estimated net code change: **~80 lines reduction** — primarily from removing keyboard fallback logic and thread dispatch boilerplate.

---

## 5. Error Handling

| Scenario | Detection | UX Response |
|---|---|---|
| Mic permission denied | `SFSpeechRecognizer.requestAuthorization` returns `.denied/.restricted` | Mic hub `.idle` with `.danger` tint. Badge: "Cần quyền truy cập microphone". Session continues (timeout advances). |
| Speech recognizer unavailable | `SFSpeechRecognizer.isAvailable == false` | Same as above — mic hub error state |
| Recognition task error mid-word | Error code != 216 in recognition callback | **Auto-recover**: `endWord()` → `beginWord(same target)` — seamless |
| 60s Apple limit | Error code 1110 or unexpected task completion | Proactive renewal in reviewed gap |
| Audio route change | `AVAudioSession.routeChangeNotification` | Cycle request only (not engine). If engine crashes → full restart |
| Engine crash (rare) | `AVAudioEngine` throws | Full restart: `stopSession()` → `startSession()`. Self-recovers for next word. |

---

## 6. Testing Plan

### Automated Tests — ViewModel

| Test | Assertion |
|---|---|
| `testSpeakingMode_matchDetected_transitionsToReviewed` | `beginWord()` → simulate match → `cardPhase == .reviewed`, `isCorrect == true` |
| `testSpeakingMode_timeout_transitionsToReviewed` | 6.0s elapsed → `cardPhase == .reviewed`, `isTimeout == true` |
| `testSpeakingMode_hintProgression_3Stages` | Stage 0→1 at 2.5s, 1→2 at 4.0s, 2→3 at 5.0s |
| `testSpeakingMode_transcriptUpdates` | Transcript callback → `liveTranscript` updates |
| `testSpeakingMode_wordTransition_callsEndWordThenBeginWord` | Match → advance → verify call order |
| `testSpeakingMode_sessionLifecycle` | Countdown → `startSession()`, summary → `stopSession()` |
| `testSpeakingMode_noKeyboardFallback` | No keyboard-related logic exists |
| `testSpeakingMode_errorRecovery` | Simulate error → verify auto-recover |

### Automated Tests — `ResilientReflexSpeechEngine`

| Test | Assertion |
|---|---|
| `testEngine_beginWord_createsNewRequest` | Each `beginWord()` creates new request |
| `testEngine_endWord_doesNotStopEngine` | `endWord()` → engine still running |
| `testEngine_multipleWordCycles_nocrash` | 10× `beginWord/endWord` cycles without crash |
| `testEngine_matchDetection_fuzzyThreshold` | `ReflexSpeechMatcher` tolerance 0.70 |
| `testEngine_60sRenewal_proactive` | Simulate near-limit → verify renewal |
| `testEngine_bufferRouting_nilSafe` | Buffers discarded when `activeRequest == nil` |

### Manual Device Testing

| Scenario | Device Required |
|---|---|
| Speak 10 words consecutively without lag | iPhone (physical) |
| Plug/unplug headphones mid-session | iPhone (physical) |
| Background/foreground mid-session | iPhone (physical) |
| Noisy environment recognition | iPhone (physical) |
| Difficult pronunciation words ("rhythm", "phenomenon") | iPhone (physical) |
