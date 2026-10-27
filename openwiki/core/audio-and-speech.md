---
type: core
title: Audio and Speech
description: Text-to-speech and speech-recognition engines, the reflex speech engine, audio session coordination, and the SpeechKit package for fuzzy pronunciation evaluation.
tags: ["audio", "speech", "tts", "stt", "speechkit", "reflex"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
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
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

Handles all audio I/O: text-to-speech prompts, speech recognition for speaking and listening drills, roleplay voice output, pronunciation evaluation through fuzzy alignment, silence detection that gates the microphone, and the speech word-token UI.

## Entrypoints

- **SpeechKit package** (`Packages/SpeechKit/Sources/SpeechKit`):
  - `SpeechAssessmentService` (`SpeechAssessmentService.swift`) implements `SpeechAssessmentProtocol`. It starts and stops assessment, creates a silence detector, and begins engine capture.
  - `Engine/`: `SpeechRecognitionEngine`, `SilenceDetector`, `SherpaKokoroTTSWrapper`, and `NoOpAudioSessionCoordinator`.
  - `Evaluation/`: `FuzzySpeechMatcher`, `SequenceAligner`, and `StringNormalizer`.
  - `Models/`: `SpeechEvaluationResult`, `WordTokenResult`, `WordMatchStatus`, and `SpeechKitError`.
  - `Protocols/`: `AudioSessionCoordinating` and `SpeechAssessmentProtocol`.
- **App audio** (`VocabCraftApp/Core/Audio`):
  - `TextToSpeechService` is a `TextToSpeechProtocol` implementation over `AVSpeechSynthesizer`. It resolves voices by locale, caches them, and runs playback leases that handle audio session events.
  - `SpeechRecognitionService` is a `SpeechRecognitionProtocol` implementation over `SFSpeechRecognizer` and `SFSpeechAudioBufferRecognitionRequest`. It computes audio levels from RMS, requests authorization, and starts and stops listening.
  - `ResilientReflexSpeechEngine` (with `+Session`, `+Recognition`, and `+WordLifecycle` extensions) is the reflex-facing engine. It manages sessions, retries, and per-word state.
  - `ReflexSpeechMatcher`, `SoundEffectService`, `AudioSessionCoordinator`, `SpeechAudioEngineController`, `LessonPerformanceDiagnostics`, and `OnDemandAIModelManager` provide supporting services. `WhisperKitSpeechEngine` and `KokoroInferenceWorker` back the on-device engines.
- **Engine adapters** (`VocabCraftApp/Data/Audio/Engines`): `AppleTTSEngineAdapter`, `AppleSTTEngineAdapter`, `GeminiTTSEngineAdapter`, `KokoroTTSEngineAdapter`, and `WhisperKitSTTEngineAdapter` adapt concrete engines to the domain protocols.
- **Reflex handlers** (`VocabCraftApp/Features/Reflex/Blitz/ViewModels/Handlers`): `SpeakingModeHandler`, `ListeningModeHandler`, `TypingModeHandler`, and `MultipleChoiceModeHandler` implement `ReflexModeHandlerProtocol`.

## Protocols

- `TTSEngineProtocol` exposes `engineName`, `isReady`, `synthesizeAndPlay(text:voice:)`, and `stop()`.
- `PlaybackReportingTTSEngineProtocol` adds `synthesizeAndPlay(text:voice:onPlaybackStarted:)`. A default extension on `TTSEngineProtocol` forwards to it when the engine conforms, so callers can rely on the playback-start callback.
- `STTEngineProtocol` exposes `startRecognition(locale:)`, which returns an `AsyncThrowingStream<String, Error>`, and `stopRecognition()`. An overload also accepts an audio-level callback.

## Mechanisms

- **TTS**: `TextToSpeechService` resolves voices through `resolveVoice(for:)` with an `en-US` fallback. It builds utterances with `makeUtterance`. Playback is guarded by an `acquirePlaybackLease(generation:)` lease, a safety timeout is computed from the text length, and `stop()` cancels in-flight speech. Roleplay voice profiles can route to other engines through `previewVoice`.
- **STT**: `SpeechRecognitionService` requests authorization, creates the audio capture session, and streams buffers to `SFSpeechRecognizer`. Audio levels are throttled and normalized from RMS. Start and stop are explicit through `startListening` and `stopListening`.
- **Silence gating**: `SilenceDetector` arms an initial silence timer and a trailing silence timer. It has a standby mode and fires `onSilence` once speech activity has been registered, so the microphone is closed after the user stops talking.
- **Evaluation**: `FuzzySpeechMatcher` and `SequenceAligner` align the hypothesis to the target, producing `WordTokenResult` values with a `WordMatchStatus`. `StringNormalizer` lowercases, strips punctuation and diacritics, and normalizes whitespace before comparison.
- **Speaking drills**: `SpeakingModeHandler` gives each word its plan item's options, cloze stages, and hint badge, and it uses a 6-second time limit. Elapsed time maps to hint stages at 2.5, 4, and 5 seconds. On completion or timeout the handler calls `endWord()` on the speech engine. `ResilientReflexSpeechEngine` and `SpeechAssessmentService` run the capture, silence gating, and evaluation.
- **Haptics**: `CraftHaptics` provides feedback on correct and incorrect answers.

## Relationships

- **Upstream**: `AppContainer` supplies `ttsService` and related speech services. `makeReflexSpeechEngine()` and `makeSpeechRecognitionService(locale:)` build the reflex engine and recognition service.
- **Downstream**: `ReflexBlitzViewModel` and `MixedReflexDrillViewModel` delegate speaking to the handlers. Feedback UI renders results with `CraftSpeechWordTokenView` through `WordTokenResult+CraftUIKit`. [Guided Practice and Roleplay](../features/guided-practice.md) uses the same TTS and speech-recognition services for voice conversations.

## State and Lifecycle

- Speech sessions are transient. The engine holds audio until evaluation, and `ResilientReflexSpeechEngine` resets per drill item.
- `AudioSessionCoordinating` mediates the shared audio session. `TextToSpeechService` and `SpeechRecognitionService` subscribe to its events and pause or resume as needed.
- Only attempt results are persisted, through the reflex attempt repositories.

## Invariants

- The normalizer is idempotent, and evaluation is deterministic for the same hypothesis and reference.
- The silence detector must not close the microphone during active speech, which is why it uses separate initial and trailing timers.
- Each TTS playback holds a lease, so a newer request does not get cut off by an older playback's cleanup.

## Failure

- `SpeechKitError` covers recognizer unavailable, authorization denied, audio session failure, and evaluation mismatch. Handlers show retry UI and allow skipping when `allowSpeakingSkip` is enabled, which is the case in mixed drills.
- Authorization problems appear as guidance UI rather than a crash.
- TTS failure falls back to a silent prompt with on-screen text.

## Configuration

- The TTS locale follows the user's settings through `UserSettingsStore`.
- Matching tolerance is set through `ReflexSpeechMatcher`.
- Engine choice for roleplay voices comes from `RoleplayVoiceProfile`.

## Extension

- Implement `SpeechAssessmentProtocol` or `ReflexSpeechEngineProtocol` to plug in an alternative engine.
- Add a drill modality by conforming to `ReflexModeHandlerProtocol`.
- Add a TTS or STT backend by writing an adapter in `Data/Audio/Engines` that conforms to the domain protocols.

## Tests

- `Packages/SpeechKit/Tests/SpeechKitTests/FuzzySpeechMatcherTests.swift`, `SilenceDetectorTests.swift`, and `SpeechAssessmentServiceTests.swift` cover evaluation, silence gating, and assessment.
- `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftSpeechEngineTests.swift` and `CraftSpeechUIComponentTests.swift` cover the speech UI components.
