---
type: core
title: Audio and Speech
description: SpeechKit engine, TTS/STT services, fuzzy matching, and Reflex speaking flow.
tags: ["audio", "speech", "speechkit", "reflex"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-c9097ed47de4a633d16b2d54
    resource: repo://Packages/SpeechKit/Sources/SpeechKit/Evaluation/FuzzySpeechMatcher.swift
  - id: openwiki-source-cd34bf9205e5a17ef1af12d5
    resource: repo://Packages/SpeechKit/Sources/SpeechKit/SpeechAssessmentService.swift
  - id: openwiki-source-dcec839911afebca1e7d2c4d
    resource: repo://VocabCraftApp/Core/Audio/SpeechRecognitionService.swift
  - id: openwiki-source-b9a7e8d3ca914df9b1f3dd38
    resource: repo://VocabCraftApp/Core/Audio/TextToSpeechService.swift
  - id: openwiki-source-a6f7d13141c497b0fa57ec39
    resource: repo://VocabCraftApp/Features/Reflex/Blitz/ViewModels/Handlers/SpeakingModeHandler.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Handles all audio I/O: text-to-speech prompts, speech recognition for speaking modes, pronunciation evaluation via fuzzy alignment, silence detection for mic gating, and tactile mic UI.

## Entrypoints

- **Package**: `Packages/SpeechKit` — `SpeechAssessmentService`, `SpeechRecognitionEngine`, `FuzzySpeechMatcher`, `SequenceAligner`, `StringNormalizer`, `SilenceDetector`, models `SpeechEvaluationResult`, `WordTokenResult`.
- **App audio**: `VocabCraftApp/Core/Audio` — `TextToSpeechService` (`AVSpeechSynthesizer`), `SpeechRecognitionService` (`SFSpeechRecognizer`), `ResilientReflexSpeechEngine` (wrapper with retry + haptics), `ReflexSpeechMatcher`, `SoundEffectService`.
- **Reflex handlers**: `Features/Reflex/Blitz/ViewModels/Handlers/SpeakingModeHandler.swift` et al., plus `CraftTactileMicHubView` + `CraftSpeechWordTokenView`.

## Mechanisms

- **TTS**: `TextToSpeechService` wraps `AVSpeechSynthesizer` with locale/rate control, tested with `CraftTactileMicHubView` for echo.
- **STT**: `SpeechRecognitionEngine` via `SFSpeechRecognizer` streams audio buffers; `SilenceDetector` gates start/stop, tuning threshold/duration to avoid premature cutoff.
- **Evaluation**: `FuzzySpeechMatcher` + `SequenceAligner` compute `SpeechEvaluationResult` with `WordMatchStatus` per token; `StringNormalizer` lowercases, strips punctuation/diacritics, normalizes whitespace before comparison. Thresholds define .exact / .fuzzy / .mismatch.
- **Reflex speaking**: `SpeakingModeHandler` orchestrates: play prompt via TTS → start engine → collect partials → silence timeout → evaluate → emit `ReflexCardResult`. `ResilientReflexSpeechEngine` adds retry and fallbacks (simulated engine in tests).
- **Haptics**: `CraftHaptics` triggers on correct/incorrect.

## Relationships

- **Upstream**: `AppContainer.ttsService/sttService/speechAssessmentService` feed ViewModels.
- **Downstream**: `ReflexBlitzViewModel` and `MixedReflexDrillViewModel` delegate speaking to handlers; feedback sheets display `CraftSpeechWordTokenView`.

## State and Lifecycle

Speech sessions are transient; engine retains buffer until evaluation. `ResilientReflexSpeechEngine` resets state per drill item. No persistence beyond attempt logs.

## Invariants

- Normalizer is idempotent; evaluation is deterministic for same hypothesis/reference.
- Silence detector must not fire during user speech — tuned hysteresis.
- Permissions: STT requests `SFSpeechRecognizer` + microphone authorization; failure surfaces as guidance UI, not crash.

## Failure

- `SpeechKitError` enumerates recognizer unavailable, authorization denied, audio session failure, evaluation mismatch. Handlers surface retry UI and allow skip when `allowSpeakingSkip` true (Mixed drills).
- TTS failure falls back to silent prompt with visual text.

## Configuration

TTS locale follows `UserSettingsStore`; assessment tolerance configurable via `ReflexSpeechMatcher`.

## Extension

Implement `SpeechAssessmentProtocol` or `ReflexSpeechEngineProtocol` to plug alternative engine; add mode by conforming to `ReflexModeHandlerProtocol`.

## Tests

- `SpeechKitTests/FuzzySpeechMatcherTests.swift`, `SilenceDetectorTests.swift`, `SpeechAssessmentServiceTests.swift`
- `CraftSpeechEngineTests.swift`, `CraftSpeechUIComponentTests.swift`
