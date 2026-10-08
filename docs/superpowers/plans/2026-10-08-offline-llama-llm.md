# Phase 2: On-Device Llama-3.2-1B & Unified Offline AI Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate on-device neural reasoning using **Llama-3.2-1B-Instruct** (4-bit GGUF, ~740MB) into `OfflineAIPack` and provide a single-action unified download coordinator (~975MB total) for TTS, STT, and LLM with zero silent fallbacks and 100% bilingual parity.

**Architecture:** A background actor (`LlamaInferenceWorker`) manages `llama.cpp` model loading and autoregressive generation with GBNF grammar constraints for valid JSON. `LlamaLocalLLMProvider` adapts this to `LLMProviderProtocol` and fails fast with `AIPackError.downloadRequired` when model weights are not downloaded. `OnDemandAIModelManager` coordinates unified downloading and progress tracking.

**Tech Stack:** Swift 6 Concurrency (Actors, Sendable), `llama.cpp` (Metal & CPU), `OnDemandAIModelManager`, `CraftUIKit`, XCTest / Swift Testing.

**Spec:** [`docs/superpowers/specs/2026-10-08-offline-llama-llm-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-08-offline-llama-llm-design.md)

## Global Constraints

- Zero Silent Fallbacks: `LlamaLocalLLMProvider` and `OfflineAIPack` must NEVER silently fallback to `IntelligentMockLLMProvider`, Apple system speech, or cloud providers when the offline pack is chosen.
- Zero Hardcoded Strings Policy: All display and button labels must be declared in `Localizable.xcstrings` under `app.ai.*` with 100% bilingual parity (en & vi), `extractionState: "manual"`, and `state: "translated"`.
- CraftUIKit-First: All UI elements must strictly use `CraftUIKit` tokens (`CraftColor`, `CraftButton`, `CraftProgressBar`, `CraftSpacingTokens`) with zero raw styling.
- Strict Concurrency: Clean actor isolation, Sendable, 0 compiler warnings under Swift 6.
- Quality Gates: 0 compiler warnings, 0 SwiftLint violations across codebase, 100% test pass rate.

---

### Task 1: `OnDemandAIModelManager` Llama Support & Unified Pack Coordinator

**Files:**
- Modify: `VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift`
- Modify: `VocabCraftAppTests/Core/Audio/OnDemandAIModelManagerTests.swift`

**Interfaces:**
- Consumes: `AIModelType`, `AIModelDownloadState`, `FileManager`
- Produces:
  - `AIModelType.llama`: displayName "Llama 3.2 1B Neural LLM", sizeMB 740, storage `llama/model.gguf`
  - `isModelReady(.llama) -> Bool`: verifies `model.gguf` exists and fileSize > 700MB
  - `fullOfflinePackState: AIModelDownloadState`
  - `fullOfflinePackProgress: Double` (weighted progress across Kokoro 9%, Whisper 15%, Llama 76%)
  - `isFullOfflinePackReady() -> Bool`
  - `startFullOfflinePackDownload()`
  - `cancelFullOfflinePackDownload()`
  - `deleteFullOfflinePack()`

- [ ] **Step 1: Write failing tests in `OnDemandAIModelManagerTests.swift`**

```swift
@Test("Llama model type configuration, directory URL, and size check")
@MainActor
func testLlamaModelConfiguration() {
    let manager = OnDemandAIModelManager.shared
    #expect(AIModelType.llama.rawValue == "llama")
    #expect(AIModelType.llama.displayName == "Llama 3.2 1B Neural LLM")
    #expect(AIModelType.llama.sizeMB == 740)
    let url = manager.modelURL(for: .llama)
    #expect(url.lastPathComponent == "llama")
}

@Test("Unified full offline pack readiness and progress")
@MainActor
func testFullOfflinePackReadinessAndProgress() {
    let manager = OnDemandAIModelManager.shared
    // Initially not ready if files don't exist
    #expect(!manager.isFullOfflinePackReady() || manager.isModelReady(.llama))
    #expect(manager.fullOfflinePackProgress >= 0.0 && manager.fullOfflinePackProgress <= 1.0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests`
Expected: FAIL (compilation error: `.llama` does not exist on `AIModelType`).

- [ ] **Step 3: Implement `AIModelType.llama` and unified pack download methods**

In `VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift`:
- Add `case llama` to `AIModelType` with display name "Llama 3.2 1B Neural LLM", size 740MB, and remote URL pointing to official GGUF mirror.
- In `isModelReady(_:)`: for `.llama`, check that `model.gguf` exists in `modelURL(for: .llama)` and that file size > 700MB.
- Add `@Published public private(set) var llamaState: AIModelDownloadState = .notDownloaded`.
- Add `fullOfflinePackState`, `fullOfflinePackProgress`, `isFullOfflinePackReady()`, `startFullOfflinePackDownload()`, `cancelFullOfflinePackDownload()`, and `deleteFullOfflinePack()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift VocabCraftAppTests/Core/Audio/OnDemandAIModelManagerTests.swift
git commit -m "feat(ai): add Llama-3.2-1B model type and unified offline pack download coordinator"
```

---

### Task 2: Background `LlamaInferenceWorker` & GBNF Grammar Support

**Files:**
- Create: `VocabCraftApp/Core/AI/LlamaInferenceWorker.swift`
- Create: `VocabCraftAppTests/AI/LlamaInferenceWorkerTests.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `LLMChatMessage`, `RoleplayTurnOutput`, `OnDemandAIModelManager`
- Produces:
  - `actor LlamaInferenceWorker`:
    - `init(modelURL: URL)`
    - `generateStructuredResponse(messages: [LLMChatMessage], systemPrompt: String) async throws -> String`
    - Cooperative cancellation check via `Task.isCancelled`
    - Token generation budget capped for iOS memory (< 1.1GB RAM)

- [ ] **Step 1: Write failing test in `LlamaInferenceWorkerTests.swift`**

```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("LlamaInferenceWorker Tests")
struct LlamaInferenceWorkerTests {
    @Test("LlamaInferenceWorker throws downloadRequired when model file is missing")
    func testWorkerThrowsWhenModelMissing() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let worker = LlamaInferenceWorker(modelURL: tempDir)
        await #expect(throws: AIPackError.self) {
            _ = try await worker.generateStructuredResponse(
                messages: [LLMChatMessage(role: .user, content: "Hello")],
                systemPrompt: "You are a barista."
            )
        }
    }

    @Test("LlamaInferenceWorker produces valid JSON when model is available or mocked")
    func testWorkerProducesValidJSON() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create a dummy model.gguf fixture
        let dummyGGUF = tempDir.appendingPathComponent("model.gguf")
        try Data(repeating: 0x47, count: 1024).write(to: dummyGGUF)

        let worker = LlamaInferenceWorker(modelURL: tempDir, bypassInferenceForTesting: true)
        let jsonString = try await worker.generateStructuredResponse(
            messages: [LLMChatMessage(role: .user, content: "Hi")],
            systemPrompt: "Roleplay prompt"
        )
        let decoder = JSONDecoder()
        let output = try decoder.decode(RoleplayTurnOutput.self, from: Data(jsonString.utf8))
        #expect(!output.characterReply.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/LlamaInferenceWorkerTests`
Expected: FAIL (`LlamaInferenceWorker` does not exist).

- [ ] **Step 3: Implement `LlamaInferenceWorker.swift` and register in project**

Create `VocabCraftApp/Core/AI/LlamaInferenceWorker.swift`:
- Background `actor LlamaInferenceWorker`.
- Checks for existence and size of `model.gguf`. If missing or incomplete, throws `AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")`.
- Formats input messages into Llama-3.2 chat template (`<|begin_of_text|><|start_header_id|>system<|end_header_id|>...`).
- Applies GBNF grammar or schema constraints to guarantee JSON output matching `RoleplayTurnOutput`.
- Checks `Task.isCancelled` during generation and throws `CancellationError()`.
- Add file to Xcode project under `Core/AI` group.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/LlamaInferenceWorkerTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/AI/LlamaInferenceWorker.swift VocabCraftAppTests/AI/LlamaInferenceWorkerTests.swift VocabCraftApp.xcodeproj/project.pbxproj
git commit -m "feat(ai): implement background LlamaInferenceWorker with JSON structured output and cancellation"
```

---

### Task 3: `LlamaLocalLLMProvider` & `OfflineAIPack` Integration

**Files:**
- Create: `VocabCraftApp/Data/AI/LlamaLocalLLMProvider.swift`
- Modify: `VocabCraftApp/Data/AIPacks/OfflineAIPack.swift`
- Modify: `VocabCraftAppTests/AI/ConcreteAIPackTests.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `LLMProviderProtocol`, `LlamaInferenceWorker`, `OnDemandAIModelManager`, `OfflineAIPack`
- Produces:
  - `LlamaLocalLLMProvider`: conforms to `LLMProviderProtocol`, fail-fast `downloadRequired(~740MB)`, zero silent fallback
  - `OfflineAIPack`:
    - `isReady`: checks `isKokoroReady() && isWhisperReady() && isLlamaReady()`
    - `status`: `.needsDownload(sizeDescription: "~975MB")` when any component is missing
    - `makeLLMProvider()`: returns `LlamaLocalLLMProvider`

- [ ] **Step 1: Write failing test in `ConcreteAIPackTests.swift`**

```swift
@Test("OfflineAIPack reports needsDownload with ~975MB when any model is missing")
func testOfflineAIPackCombinedStatus() {
    let pack = OfflineAIPack(
        isKokoroReady: { true },
        isWhisperReady: { true },
        isLlamaReady: { false }
    )
    #expect(pack.status == .needsDownload(sizeDescription: "~975MB"))
}

@Test("OfflineAIPack makeLLMProvider throws downloadRequired when Llama is not downloaded")
func testOfflineAIPackLLMThrowsWhenNotDownloaded() {
    let pack = OfflineAIPack(
        isKokoroReady: { true },
        isWhisperReady: { true },
        isLlamaReady: { false }
    )
    #expect(throws: AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")) {
        try pack.makeLLMProvider()
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/ConcreteAIPackTests`
Expected: FAIL (`isLlamaReady` parameter does not exist on `OfflineAIPack`).

- [ ] **Step 3: Implement `LlamaLocalLLMProvider` and update `OfflineAIPack`**

1. Create `VocabCraftApp/Data/AI/LlamaLocalLLMProvider.swift`:
   - Conforms to `LLMProviderProtocol`.
   - `providerIdentifier: "llama-3.2-1b-local"`.
   - In `sendStructuredMessage`:
     - Checks `guard isReady else { throw AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB") }`.
     - Calls `worker.generateStructuredResponse(...)`.
     - Decodes JSON into `T`.
     - Catches `is CancellationError` and rethrows untouched.
     - Catches any error and wraps into `AIPackError.llmFailed(packName: "Offline AI Pack", underlyingMessage: error.localizedDescription)`.
2. Update `VocabCraftApp/Data/AIPacks/OfflineAIPack.swift`:
   - Add `isLlamaReady: @Sendable () -> Bool`.
   - Update `status`: if any model not ready, returns `.needsDownload(sizeDescription: "~975MB")`.
   - In `makeLLMProvider()`: checks `guard isLlamaReady() else { throw .downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB") }` and returns `LlamaLocalLLMProvider`.
3. Register new file in `VocabCraftApp.xcodeproj/project.pbxproj`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/ConcreteAIPackTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/LlamaLocalLLMProvider.swift VocabCraftApp/Data/AIPacks/OfflineAIPack.swift VocabCraftAppTests/AI/ConcreteAIPackTests.swift VocabCraftApp.xcodeproj/project.pbxproj
git commit -m "feat(ai): integrate LlamaLocalLLMProvider into OfflineAIPack with strict fail-fast error propagation"
```

---

### Task 4: Unified Download UI & 100% Bilingual Localization

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayModelDownloadCard.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift`
- Modify: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Consumes: `AppStrings`, `OnDemandAIModelManager`, `CraftUIKit` tokens
- Produces:
  - Localized strings:
    - `app.ai.pack.offline.download_all_title`
    - `app.ai.pack.offline.download_all_desc`
    - `app.ai.pack.offline.download_all_action`
    - `app.ai.model.llama_title`
    - `app.ai.model.llama_desc`
  - Single "Download Full Offline Pack (~975MB)" button in `RoleplayModelDownloadCard` and `AIConfigSheet` with aggregated progress.

- [ ] **Step 1: Write failing test in `AIAssistantLocalizationTests.swift`**

```swift
@Test("Offline pack and Llama model localization keys exist in both en and vi")
func testOfflinePackAndLlamaLocalizationKeys() throws {
    let keys = [
        "app.ai.pack.offline.download_all_title",
        "app.ai.pack.offline.download_all_desc",
        "app.ai.pack.offline.download_all_action",
        "app.ai.model.llama_title",
        "app.ai.model.llama_desc"
    ]
    for key in keys {
        #expect(hasTranslation(key: key, locale: "en"), "Missing English translation for \(key)")
        #expect(hasTranslation(key: key, locale: "vi"), "Missing Vietnamese translation for \(key)")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests/testOfflinePackAndLlamaLocalizationKeys`
Expected: FAIL (keys not yet in `Localizable.xcstrings`).

- [ ] **Step 3: Add localization keys and update UI views**

1. In `VocabCraftApp/Resources/Localizable.xcstrings`:
   Add all 5 keys with exact pairs (EN and VI), `extractionState: "manual"`, and `state: "translated"`.
2. In `VocabCraftApp/Core/Localization/AppStrings.swift`:
   Add type-safe computed `var` accessors under `AppStrings.AIPack` and `AppStrings.AIModelDownload`.
3. In `RoleplayModelDownloadCard.swift` & `AIConfigSheet.swift`:
   Add the single prominent button to trigger `modelManager.startFullOfflinePackDownload()` with aggregate progress bar and breakdown indicators for Kokoro, Whisper, and Llama using `CraftUIKit` tokens.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayModelDownloadCard.swift VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "feat(ui): add unified offline pack download card and 100% bilingual localization for Llama 3.2"
```

---

### Task 5: End-to-End Verification & Quality Gates

**Files:** None (verification and quality audit)

- [ ] **Step 1: Run comprehensive test suite**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests -only-testing:VocabCraftAppTests/LlamaInferenceWorkerTests -only-testing:VocabCraftAppTests/ConcreteAIPackTests -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests -only-testing:VocabCraftAppTests/AIPackRegistryTests`
Expected: 100% pass rate.

- [ ] **Step 2: Run CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: 100% pass rate.

- [ ] **Step 3: Run SwiftLint strict check**

Run: `swiftlint lint --strict`
Expected: 0 violations, 0 warnings across all files.

- [ ] **Step 4: Full compiler clean build check**

Run: `xcodebuild build -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: Build Succeeded with 0 errors, 0 warnings.
