# Technical Design Specification: Phase 2 — On-Device Llama-3.2-1B & Unified Offline AI Pack

- **Author**: Antigravity Agent
- **Date**: 2026-10-08
- **Status**: Approved
- **Scope**: `VocabCraftApp` Core Audio/AI, Domain Models, concrete `OfflineAIPack`, UI Download Card & Settings
- **Dependencies**: `llama.cpp` (Metal & CPU runtime), `OnDemandAIModelManager`, `CraftUIKit`

---

## 1. Executive Summary

Phase 1 successfully integrated studio-grade 24kHz neural text-to-speech (**Kokoro-82M**) with distinct personas (Nova, Orion, Sarah, Michael), 4-file integrity checks, zero silent fallbacks, and 100% bilingual parity.

**Phase 2** upgrades the offline reasoning core of the `Offline AI Pack` by replacing `IntelligentMockLLMProvider` with an authentic, private, on-device Large Language Model: **Llama-3.2-1B-Instruct** (4-bit quantized GGUF, ~740MB). In addition, Phase 2 consolidates the three offline modalities (Kokoro TTS ~85MB, WhisperKit STT ~150MB, and Llama LLM ~740MB) into a **Unified Offline AI Pack Download** (~975MB total) triggered by a single one-click action in the UI.

---

## 2. Core Architecture & Component Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           VocabCraftApp (iOS / iPadOS)                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   TurnBasedVoiceConversationEngine / ExecuteRoleplayTurnUseCase                 │
│                                      │                                          │
│                                      ▼                                          │
│                           AIPackRegistry (.offlineAI)                           │
│                                      │                                          │
│              ┌───────────────────────┼───────────────────────┐                  │
│              ▼                       ▼                       ▼                  │
│     KokoroTTSEngineAdapter  WhisperKitSTTAdapter   LlamaLocalLLMProvider        │
│              │                       │                       │                  │
│              ▼                       ▼                       ▼                  │
│     KokoroInferenceWorker    WhisperKitEngine       LlamaInferenceWorker        │
│     (24kHz Neural TTS)       (On-Device STT)        (4-bit GGUF + GBNF Grammar) │
│              │                       │                       │                  │
│              └───────────────────────┼───────────────────────┘                  │
│                                      ▼                                          │
│                          OnDemandAIModelManager                                 │
│          Unified Offline Pack Download Coordinator (~975MB Total)               │
│               [Kokoro ~85MB + Whisper ~150MB + Llama ~740MB]                    │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Technical Design

### 3.1 Domain & Model Management Layer (`OnDemandAIModelManager.swift`)

1. **`AIModelType.llama` Enum Case**:
   ```swift
   public enum AIModelType: String, CaseIterable, Sendable {
       case kokoro
       case whisper
       case llama    // Llama-3.2-1B-Instruct (4-bit GGUF, ~740MB)
   }
   ```
2. **Model Specifications for Llama**:
   - `displayName`: "Llama 3.2 1B Neural LLM"
   - `sizeMB`: `740`
   - `remoteURL`: Official, validated huggingface GGUF mirror URL (`bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf`).
   - `storageDirectory`: `Application Support/VocabCraft/AIModels/llama/`
   - `targetFile`: `model.gguf`
3. **Integrity & Storage Governance**:
   - `isModelReady(.llama)` validates:
     1. `model.gguf` exists in the model directory.
     2. File size is greater than 700MB (preventing truncated or partial downloads).
   - Entire directory is tagged with `URLResourceValues.isExcludedFromBackup = true` to protect iCloud user quota.
4. **Unified Download Coordinator**:
   - `OnDemandAIModelManager` exposes unified pack APIs:
     ```swift
     public var fullOfflinePackState: AIModelDownloadState { get }
     public var fullOfflinePackProgress: Double { get } // 0.0 ... 1.0 (weighted: Kokoro 9%, Whisper 15%, Llama 76%)
     public func isFullOfflinePackReady() -> Bool
     public func startFullOfflinePackDownload()
     public func cancelFullOfflinePackDownload()
     public func deleteFullOfflinePack()
     ```
   - Automatically chains/orchestrates sequential or parallel downloads of `.kokoro`, `.whisper`, and `.llama`.

---

### 3.2 LLM Inference Layer (`LlamaInferenceWorker.swift` & `LlamaLocalLLMProvider.swift`)

#### A. `LlamaInferenceWorker` (Background Actor)
- **Actor Isolation**: All model loading, Metal context allocation, and autoregressive generation run strictly off the Main Thread.
- **Hardware Acceleration**: Apple Metal GPU shaders on physical iOS devices (`GGML_USE_METAL`); CPU fallback on macOS / iOS Simulator.
- **Memory Footprint Control**:
  - Context size capped at `2,048 tokens` on iOS.
  - Active RAM footprint: **~950 MB** (safely below the 1.5GB iOS Jetsam memory limit on 6GB iPhones).
  - Unloads inactive context or resets KV-cache when idle.
- **GBNF Grammar-Constrained Decoding**:
  - Employs Grammar-Based Sampling (GBNF) for [`RoleplayTurnOutput`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Domain/Entities/RoleplayTurnOutput.swift):
    - Guarantees valid JSON output matching keys: `characterReply`, `targetWordsUsed`, `refinementSuggestion`, `pedagogicalNote`, `suggestedResponses`, `isConcluded`.
    - Eliminates conversational hallucination, markdown fences, or schema parse failures.
- **Cooperative Cancellation**:
  - Evaluates `Task.isCancelled` during token generation. If cancelled, immediately halts token generation, releases compute resources, and throws `CancellationError`.

#### B. `LlamaLocalLLMProvider` (Domain Adapter)
- Conforms to `LLMProviderProtocol`:
  ```swift
  public final class LlamaLocalLLMProvider: LLMProviderProtocol, @unchecked Sendable {
      public let providerIdentifier: String = "llama-3.2-1b-local"
      private let worker: LlamaInferenceWorker
      private let modelManager: OnDemandAIModelManager

      public func sendStructuredMessage<T: Decodable & Sendable>(
          messages: [LLMChatMessage],
          systemPrompt: String,
          responseSchema: T.Type
      ) async throws -> T
  }
  ```
- **Zero Silent Fallback**:
  - When `!modelManager.isModelReady(.llama)`, immediately throws `AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")`.
  - When generation fails, throws `AIPackError.llmFailed(packName: "Offline AI Pack", underlyingMessage: error.localizedDescription)`.
  - Propagates `CancellationError` untouched.

---

### 3.3 Concrete Pack Integration (`OfflineAIPack.swift`)

[`OfflineAIPack`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Data/AIPacks/OfflineAIPack.swift) is updated:
1. **Full Readiness Gate**:
   - `isReady`: Returns `true` only when `isKokoroReady() && isWhisperReady() && isLlamaReady()`.
   - `status`: Returns `.ready` when all 3 models are loaded; otherwise `.needsDownload(sizeDescription: "~975MB")`.
2. **Factory Methods**:
   - `makeLLMProvider()`: Throws `.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")` if unready; otherwise constructs `LlamaLocalLLMProvider`.
   - `makeTTSEngine()`: Throws `.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")` if unready; otherwise constructs `KokoroTTSEngineAdapter`.
   - `makeSTTEngine()`: Throws `.downloadRequired(packName: "WhisperKit", sizeDescription: "~150MB")` if unready; otherwise constructs `WhisperKitSTTEngineAdapter`.
3. **No Fallback to Mock**: `IntelligentMockLLMProvider` is retired from production `OfflineAIPack` and retained solely for isolated mock test environments.

---

### 3.4 User Interface & 100% Bilingual Localization

#### A. Unified Download UI
- In [`RoleplayModelDownloadCard.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayModelDownloadCard.swift) and [`AIConfigSheet.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift):
  - Primary button: **"Download Complete Offline AI Pack (~975MB)"** / **"Tải Trọn Bộ Gói AI Ngoại Tuyến (~975MB)"**.
  - Unified progress bar with breakdown pills (Kokoro 85MB, Whisper 150MB, Llama 740MB).
  - Built exclusively using `CraftUIKit` design tokens (`CraftColor`, `CraftButton`, `CraftProgressBar`, `CraftSpacingTokens`).

#### B. Localization Catalog (`Localizable.xcstrings`)
Strict adherence to `AGENTS.md` (100% bilingual parity, `extractionState: "manual"`, `state: "translated"`):

| Key | English (en) | Vietnamese (vi) |
|---|---|---|
| `app.ai.pack.offline.download_all_title` | Complete Offline AI Pack | Trọn Bộ Gói AI Ngoại Tuyến |
| `app.ai.pack.offline.download_all_desc` | Private on-device Neural Voices, Speech Recognition & Llama 3.2 AI (975MB) | Giọng đọc nơ-ron, nhận dạng giọng nói & Llama 3.2 AI bảo mật trên thiết bị (975MB) |
| `app.ai.pack.offline.download_all_action` | Download Offline Pack (975MB) | Tải Gói Ngoại Tuyến (975MB) |
| `app.ai.model.llama_title` | Llama 3.2 1B AI | Trí Tuệ Nhân Tạo Llama 3.2 1B |
| `app.ai.model.llama_desc` | On-device language model for private conversations (740MB) | Mô hình ngôn ngữ trên thiết bị cho hội thoại riêng tư (740MB) |

---

## 4. Quality Gates & Acceptance Criteria

1. **Compilation & Concurrency**:
   - 0 compiler warnings under Swift 6 strict concurrency.
   - Clean actor isolation and `Sendable` compliance across all new files.
2. **Zero Silent Fallback**:
   - `LlamaLocalLLMProvider`, `KokoroTTSEngineAdapter`, and `OfflineAIPack` strictly fail fast with typed errors when models are missing.
3. **SwiftLint Compliance**:
   - 0 violations, 0 warnings across the entire codebase (`swiftlint --strict`).
4. **Unit Test Pass Rate**:
   - 100% test pass rate across `OnDemandAIModelManagerTests`, `LlamaLocalLLMProviderTests`, `ConcreteAIPackTests`, and `AIAssistantLocalizationTests`.
5. **No Hardcoded Strings**:
   - Zero raw text in view bodies or view models; all user-facing strings resolved via `Localizable.xcstrings`.
