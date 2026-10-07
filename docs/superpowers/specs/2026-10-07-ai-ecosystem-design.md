# AI Ecosystem Bundles & Fallback Redesign

## 1. Overview
The current AI conversation system relies on ad-hoc providers (LLM, TTS, STT) with internal, silent fallbacks (e.g., `ResilientLLMProvider`) that cause unpredictable behavior and confuse the user. This redesign introduces an Abstract Factory pattern (`AIEcosystemFactory`) to group services into consistent "Bundles" (Ecosystems). It removes silent fallbacks in favor of explicit user intervention via BottomSheets, and cleanly integrates on-demand local model downloads (Kokoro, Whisper, Llama).

## 2. Core Architecture

### 2.1. AIEcosystemFactory (Protocol)
Defines the boundary for an AI bundle.
```swift
public protocol AIEcosystemFactory: Sendable {
    var ecosystemID: String { get }
    var displayNameKey: String { get }
    
    func resolveLLM() throws -> any LLMProviderProtocol
    func resolveTTS() throws -> any TTSProviderProtocol
    func resolveSTT() throws -> any STTProviderProtocol
    
    // Check if models need to be downloaded (for local AI)
    func checkReadiness() async -> EcosystemReadinessState
}

public enum EcosystemReadinessState {
    case ready
    case requiresDownload(models: [AIModelDependency])
}
```

### 2.2. Ecosystem Implementations
- **`AppleEcosystem`**: Native Apple SDKs. (Mock LLM or Basic Prompting, Apple Enhanced TTS, SFSpeechRecognizer).
- **`GeminiEcosystem`**: Cloud-based. (Gemini LLM, Gemini Voice API, Apple STT/Whisper).
- **`OfflineEcosystem`**: On-Device AI. (Llama.cpp LLM, Kokoro TTS, WhisperKit STT).

### 2.3. AIEcosystemManager
A global actor or `@Observable` class that manages the currently active ecosystem based on user settings.
- Emits changes when the user switches ecosystems.
- Validates readiness (downloads) before switching.

## 3. Error Handling & UX (No Silent Fallbacks)

### 3.1. Removing Obsolete Routers
- Delete `ResilientLLMProvider`.
- Delete internal silent fallback logic inside Speech engines.
- Providers now strictly throw `AIEcosystemError` (e.g., `.networkUnavailable`, `.modelNotLoaded`, `.rateLimited`).

### 3.2. User-Facing Fallback UX
When an error is thrown during a conversation (e.g., `RoleplayVoiceCallViewModel`):
1. **Halt**: Audio recording and TTS playback stop immediately.
2. **Alert**: A BottomSheet or interactive Alert is presented.
3. **Actionable UI**: 
   - Title: "Connection Lost / Provider Unavailable"
   - Body: "Gemini is currently unavailable. Would you like to switch to Apple Native to continue?"
   - Buttons: `[Switch to Apple]` | `[Retry]` | `[End Conversation]`

## 4. On-Demand Model Downloads
Integrated via `OnDemandAIModelManager`.
- If the user selects `OfflineEcosystem` but Kokoro/Whisper weights are missing, `checkReadiness()` returns `.requiresDownload`.
- The settings UI or Conversation Entry UI displays the `RoleplayModelDownloadCard`.
- The ecosystem is only marked as active once the download yields 100% completion.

## 5. Migration Strategy
1. Introduce `AIEcosystemFactory` and its implementations.
2. Refactor App Container and Settings to inject and track the active `AIEcosystemFactory`.
3. Strip out `ResilientLLMProvider` and update ViewModels to handle thrown errors natively.
4. Build the Fallback BottomSheet UI components in `VocabCraftApp/Features/AIAssistant/Views/`.
