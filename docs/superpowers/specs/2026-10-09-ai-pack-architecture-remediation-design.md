# Technical Design Specification: AI Pack Architecture Remediation & Audio Lifecycle Fix

- **Date:** 2026-10-09
- **Status:** Approved
- **Scope:** `VocabCraftApp` AI Pack Registry, Audio/STT/TTS Lifecycle, Gemini Cloud Models, On-Device Context Dialogue Engine, Suggestions Scaffolding
- **Document Path:** `docs/superpowers/specs/2026-10-09-ai-pack-architecture-remediation-design.md`

---

## 1. Executive Summary & Root Cause Analysis

In real-world testing of the AI Assistant and Quick Voice Practice (`RoleplayVoiceCallView`), users experienced:
1. **No audio responses during voice chat (Silent responses / Hang):**
   - In [`AppleSTTEngineAdapter.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Data/Audio/Engines/AppleSTTEngineAdapter.swift), `stopRecognition()` was an empty no-op method. `SpeechRecognitionService`'s `AVAudioEngine` remained running with an active input tap and held the audio session lease (`.speechCapture`), causing playback audio conflicts that silenced or deadlocked TTS playback.
   - `audioLevel` was never bridged from `SpeechRecognitionService` to `TurnBasedVoiceConversationEngine`, causing the UI Voice Orb to remain static (0.0).
2. **Cross-Pack Dependency Leakage (Offline Pack requiring Gemini API Key):**
   - [`AIPackRegistry.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Data/AIPacks/AIPackRegistry.swift) defaulted to `activePackId = .geminiCloud` on fresh install. When `OfflineAIPack` was selected prior to completing full ~975MB downloads, `selectPack` threw an error and left the active pack locked on `geminiCloud`, causing the UI to complain about Gemini API Key even when the user wanted offline usage.
3. **HTTP 404 Failure on Gemini Cloud LLM:**
   - [`GeminiLLMProvider.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Data/AI/GeminiLLMProvider.swift) configured non-existent candidate models (`gemini-flash-lite-latest`, `gemini-3.1-flash-lite`, `gemini-flash-latest`), causing Google Gemini v1beta endpoint to return 404 errors.
4. **Inaccurate / Static Suggestions:**
   - [`FetchRoleplayScenariosUseCase.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift) created `adaptiveDaily` with empty `starterSuggestions = []`.
   - When Gemini failed or when offline, [`IntelligentMockLLMProvider.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Data/AI/IntelligentMockLLMProvider.swift) ran a static 3-turn script (turns 1, 2, 3) ignoring what the user actually said.

This specification refactors the architecture to guarantee **pure pack isolation**, **explicit default on launch**, **correct audio hardware teardown**, and **context-aware dynamic suggestions**.

---

## 2. Architecture & Pure Pack Isolation Model

```
┌────────────────────────────────────────────────────────────────────────┐
│                          AIPackRegistry                                │
│          Default on fresh install: .appleDefault                       │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│  Apple Default  │       │ Offline AI Pack │       │Gemini Cloud Pack│
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ • STT: Apple    │       │ • STT: Whisper  │       │ • STT: Apple    │
│ • TTS: Apple    │       │ • TTS: Kokoro   │       │ • TTS: Gemini/  │
│ • LLM: Apple FM │       │ • LLM: Llama    │       │        Apple    │
│   / Context     │       │   Local / On-   │       │ • LLM: Gemini   │
│   Dialogue      │       │   Device Engine │       │   2.5 Flash API │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ Status:         │       │ Status:         │       │ Status:         │
│ Always .ready   │       │ .ready iff 100% │       │ .ready iff key  │
│ (Zero setup,    │       │ models present  │       │ configured.     │
│  0MB download,  │       │ (~975MB local). │       │ Needs key only  │
│  0 API key)     │       │ Zero API keys.  │       │ when active.    │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

### 2.1 Pack Contract & Rules
1. **`AppleDefaultPack`**:
   - Status is **always `.ready`**.
   - Requires 0MB download and 0 API keys.
   - Powers out-of-the-box Quick Voice Practice on every iOS device immediately upon app installation.
2. **`OfflineAIPack`**:
   - Status is `.ready` **strictly when all 3 models are present** (`isKokoroReady && isWhisperReady && isLlamaReady`).
   - If missing any model, status is `.needsDownload(sizeDescription: "~975MB")`.
   - Completely decoupled from `geminiApiKey`. Never checks, queries, or alerts for cloud keys.
3. **`GeminiCloudPack`**:
   - Status is `.ready` when `isGeminiApiKeyConfigured == true`, otherwise `.needsApiKey(providerName: "Google Gemini")`.
   - Never queries local model filesystem or download states.
4. **`AIPackRegistry`**:
   - Fresh install defaults to `.appleDefault`.
   - `selectPack(id)` validates prerequisite states cleanly and preserves previous pack if preconditions fail.
   - `AppContainer` resolves `activePack` without silent fallback to mock. If an active pack fails at runtime, it reports typed `AIPackError` transparently.

---

## 3. Modality Engines & Audio Hardware Lifecycle

### 3.1 STT Engine Teardown & Audio Metering
1. **`AppleSTTEngineAdapter`**:
   - Stores active `SpeechRecognitionService` and stream continuation.
   - `stopRecognition()` cleanly stops `SpeechRecognitionService`, stops `AVAudioEngine`, removes input node tap, and releases audio session lease.
   - Forwards real RMS audio level (0.0 to 1.0) through `STTEngineProtocol` callback to `TurnBasedVoiceConversationEngine.audioLevel`.
2. **`TurnBasedVoiceConversationEngine`**:
   - Audio session handshake: When transitioning from `.listening` to `.thinking`, invokes `sttEngine.stopRecognition()` and ensures microphone audio engine is fully deactivated before calling `playCharacterSpeech(...)`.
   - `audioLevel` binds directly to `CraftVoiceOrbView` waveform animation during speech input.

### 3.2 Conversational Intelligence (LLM)
1. **`AppleDefaultPack` (`AppleIntelligenceOrLocalDialogueProvider`)**:
   - Priority 1: Apple Foundation Models on iOS 26+ when runtime framework is available.
   - Priority 2: `OnDeviceContextDialogueEngine` on current iOS (iOS 17/18).
   - `OnDeviceContextDialogueEngine`:
     - Parses scenario context (`RoleplayScenario`), user roles, character persona, and target vocabulary.
     - Detects user intent and verifies target words using `ReflexSpeechMatcher`.
     - Analyzes sentence structure for grammatical refinements.
     - Generates 3 dynamic, branching suggestions:
       - Branch 1 (Target Word): Natural sentence containing a target lemma.
       - Branch 2 (Question): Natural conversational follow-up question.
       - Branch 3 (Reaction): Natural colloquial reaction or short response.
2. **`OfflineAIPack` (`LlamaLocalLLMProvider`)**:
   - On-device GGUF inference when Llama weights are downloaded; uses `OnDeviceContextDialogueEngine` as the on-device inference provider if native runtime is not bound.
   - Zero network requests.
3. **`GeminiCloudPack` (`GeminiLLMProvider`)**:
   - Fixes candidate models to official Google Gemini endpoints:
     ```swift
     public static let defaultModels: [String] = [
         "gemini-2.5-flash",
         "gemini-2.5-flash-lite",
         "gemini-2.0-flash"
     ]
     ```
   - Corrects `GeminiAudioSpeechEngine` URL and test expectations to match Google v1beta specifications.

### 3.3 Text-To-Speech (TTS)
1. **`AppleTTSEngineAdapter`**: Uses `AppleEnhancedTTSEngine` with natural iOS voices (`AVSpeechSynthesizer`).
2. **`KokoroTTSEngineAdapter`**: Uses 24kHz neural voices via `sherpa-onnx` on-device.
3. **`GeminiTTSEngineAdapter`**: Uses Gemini Studio Voice over API.

---

## 4. Suggestions Scaffolding & Scenario Enhancement

1. **`FetchRoleplayScenariosUseCase`**:
   - For `adaptiveDaily` (built from `userWeakWords`), automatically generates non-empty `starterSuggestions` based on weak words, e.g.:
     - *"I'd like to practice using \(word) in our conversation."*
     - *"Could you help me practice \(word) today?"*
     - *"Hello! Let's work on my vocabulary."*
   - Guarantees `starterSuggestions` is never empty on turn 0.
2. **`ExecuteRoleplayTurnUseCase`**:
   - Unifies suggestion evaluation: ensures 2-3 natural candidate suggestions are returned for every turn.

---

## 5. Testing & Verification Plan

1. **Pack Isolation & Registry Tests**:
   - `test_appleDefaultPack_readyOnFreshInstall`: Verifies `AppleDefaultPack` is ready out-of-the-box with no setup.
   - `test_offlinePack_isolatedFromGeminiKey`: Verifies `OfflineAIPack` ignores `geminiApiKey`.
   - `test_geminiCloudPack_requiresApiKeyOnly`: Verifies `GeminiCloudPack` only checks API key.
   - `test_freshInstall_defaultsToAppleDefault`: Verifies initial active pack is `appleDefault`.
2. **STT Lifecycle & Audio Tests**:
   - `test_appleSTTEngineAdapter_stopRecognition_cleansUp`: Verifies audio engine stops and stream finishes.
   - `test_audioLevel_streamsToEngine`: Verifies audio levels update engine and voice orb.
3. **Gemini API & Test Alignment**:
   - Fix `GeminiAudioSpeechEngineTests` to expect official model names.
   - Verify `GeminiLLMProvider` models avoid 404 errors.
4. **Dynamic Suggestions Tests**:
   - `test_dailyAdaptiveScenario_starterSuggestionsNotEmpty`: Verifies non-empty suggestions for adaptive daily scenario.
   - `test_contextDialogueEngine_generatesThreeBranchSuggestions`: Verifies 3 branching suggestions.
5. **Quality Gate Verification**:
   - Full `swift test` suite passes 100%.
   - `swiftlint` clean (0 warnings, 0 errors).
