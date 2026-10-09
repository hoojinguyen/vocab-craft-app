# Offline Pack Download Feedback & iOS Native Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate silent error fallbacks during AI pack downloads, replace `posix_spawn` `/usr/bin/tar` with iOS sandbox-compliant in-process extraction, provide dynamic remaining download size, and give explicit Error/Retry UI states.

**Architecture:** Implement in-process streaming BZip2 decompression (via system `libbz2.dylib`) and Tar parsing in `OnDemandAIModelManager`, add archive directory auto-flattening, compute `remainingOfflinePackSizeMB`, and update `AIConfigSheet` and `RoleplayModelDownloadCard` with explicit error badges, retry actions, and dynamic remaining size buttons.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit, system `libbz2.dylib`, XCTest / Swift Testing.

**Spec:** `/Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-09-offline-pack-download-feedback-and-ios-extraction-design.md`

## Global Constraints
- **Zero Silent Fallback**: Every failure state (`.error`) must be surfaced to the user with actionable feedback and retry mechanisms.
- **iOS Sandbox Safety**: Zero calls to `posix_spawn` or external command-line tools. All file and archive operations run in-process.
- **Zero Hardcoded Strings**: All user-facing strings must be declared in `VocabCraftApp/Resources/Localizable.xcstrings` with 100% bilingual parity (`en` and `vi`).
- **CraftUIKit-First**: All UI elements must use `CraftUIKit` tokens (`CraftBadge`, `CraftButton`, `CraftProgressBar`, `theme.colors.*`, `theme.typography.*`, `theme.spacing.*`).
- **Quality Gates**: Zero compiler warnings, 0 SwiftLint violations, 100% test pass rate.

---

### Task 1: Bilingual Localization Keys & AppStrings Accessors

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Produces:
  - `AppStrings.AIModelDownload.statusError`: `LocalizedStringKey`
  - `AppStrings.AIModelDownload.statusErrorText`: `String`
  - `AppStrings.AIModelDownload.actionRetry`: `LocalizedStringKey`
  - `AppStrings.AIModelDownload.actionRetryText`: `String`
  - `AppStrings.AIPack.downloadRemainingAction(_ remainingMB: Int) -> LocalizedStringKey`
  - `AppStrings.AIPack.downloadRemainingActionText(_ remainingMB: Int) -> String`
  - `AppStrings.AIPack.statusDownloadFailed`: `LocalizedStringKey`
  - `AppStrings.AIPack.statusDownloadFailedText`: `String`

- [ ] **Step 1: Write the failing localization test**

Add `testDownloadErrorAndRemainingLocalizationKeys` in `AIAssistantLocalizationTests.swift`:
```swift
@Test("Verify offline pack error and remaining download localization keys in en and vi")
func testDownloadErrorAndRemainingLocalizationKeys() throws {
    let keys = [
        "app.ai.model_download.status_error",
        "app.ai.model_download.action_retry",
        "app.ai.pack.offline.download_remaining_action",
        "app.ai.pack.status.download_failed"
    ]
    for key in keys {
        #expect(hasTranslation(for: key, locale: "en"), "Missing English translation for \(key)")
        #expect(hasTranslation(for: key, locale: "vi"), "Missing Vietnamese translation for \(key)")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests/testDownloadErrorAndRemainingLocalizationKeys`
Expected: FAIL with missing keys.

- [ ] **Step 3: Add keys to Localizable.xcstrings and AppStrings.swift**

In `Localizable.xcstrings`, add:
- `app.ai.model_download.status_error`: en: "Download Failed", vi: "Tải Thất Bại"
- `app.ai.model_download.action_retry`: en: "Retry", vi: "Thử Lại"
- `app.ai.pack.offline.download_remaining_action`: en: "Download Remaining Pack (~%lldMB)", vi: "Tải Gói Còn Lại (~%lldMB)"
- `app.ai.pack.status.download_failed`: en: "Download Failed", vi: "Tải Thất Bại"

In `AppStrings.swift`, add computed properties and helpers under `AIModelDownload` and `AIPack`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests/testDownloadErrorAndRemainingLocalizationKeys`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "feat(ai): add bilingual localization keys for download errors and remaining pack size"
```

---

### Task 2: In-Process iOS Sandbox-Compliant Archive Extraction & Auto-Flattening

**Files:**
- Modify: `VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift`
- Test: `VocabCraftAppTests/Core/Audio/OnDemandAIModelManagerTests.swift`

**Interfaces:**
- Consumes: `libbz2.dylib` C dynamic symbols (`BZ2_bzReadOpen`, `BZ2_bzRead`, `BZ2_bzReadClose`).
- Produces:
  - `OnDemandAIModelManager.extractArchive(at:to:)`: In-process streaming archive extractor that decompress `.tar.bz2`, `.tar`, and raw directories without `posix_spawn`.
  - `OnDemandAIModelManager.remainingOfflinePackSizeMB: Int`: Dynamic remaining MB.
  - `OnDemandAIModelManager.isModelReady(.kokoro)`: Validates 4 required files and auto-flattens any nested directory (e.g. `kokoro-en-v0_19/`).

- [ ] **Step 1: Write failing tests for in-process extraction and auto-flattening**

In `OnDemandAIModelManagerTests.swift`, add:
```swift
@Test("In-process archive extractor extracts tar and tar.bz2 without posix_spawn")
func testInProcessArchiveExtraction() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let destDir = tempDir.appendingPathComponent("extracted")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    // Test directory extraction
    let sourceDir = tempDir.appendingPathComponent("source")
    try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
    let fileA = sourceDir.appendingPathComponent("model.onnx")
    try "dummy-model".write(to: fileA, atomically: true, encoding: .utf8)

    try OnDemandAIModelManager.extractArchive(at: sourceDir, to: destDir)
    #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("model.onnx").path))
}

@Test("Auto-flattening of nested kokoro directory")
@MainActor
func testKokoroAutoFlattening() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let kokoroDir = tempDir.appendingPathComponent("kokoro")
    let nestedDir = kokoroDir.appendingPathComponent("kokoro-en-v0_19")
    try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    try "dummy".write(to: nestedDir.appendingPathComponent("model.onnx"), atomically: true, encoding: .utf8)
    try "dummy".write(to: nestedDir.appendingPathComponent("voices.bin"), atomically: true, encoding: .utf8)
    try "dummy".write(to: nestedDir.appendingPathComponent("tokens.txt"), atomically: true, encoding: .utf8)
    try FileManager.default.createDirectory(at: nestedDir.appendingPathComponent("espeak-ng-data"), withIntermediateDirectories: true)

    let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
    #expect(manager.isModelReady(.kokoro))
    #expect(FileManager.default.fileExists(atPath: kokoroDir.appendingPathComponent("model.onnx").path))
}

@Test("Remaining offline pack size computation")
@MainActor
func testRemainingOfflinePackSize() {
    let manager = OnDemandAIModelManager.shared
    #expect(manager.remainingOfflinePackSizeMB >= 0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests`
Expected: FAIL on `testKokoroAutoFlattening` or `remainingOfflinePackSizeMB`.

- [ ] **Step 3: Implement in-process archive extraction and auto-flattening**

In `OnDemandAIModelManager.swift`:
1. Add `remainingOfflinePackSizeMB`:
```swift
public var remainingOfflinePackSizeMB: Int {
    AIModelType.allCases
        .filter { !isModelReady($0) }
        .reduce(0) { $0 + $1.sizeMB }
}
```
2. Replace `executeTarExtraction` with pure Swift in-process tar parsing + `libbz2` streaming decompressor.
3. Update `isModelReady(.kokoro)` to search for nested directories containing the 4 required files and auto-flatten them into the base directory.
4. Update `startFullOfflinePackDownload()` to ensure models in `.error` state are also retried.

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/OnDemandAIModelManager.swift VocabCraftAppTests/Core/Audio/OnDemandAIModelManagerTests.swift
git commit -m "fix(audio): implement in-process sandbox archive extraction and nested folder auto-flattening"
```

---

### Task 3: UI Error State & Dynamic Remaining Size in AIConfigSheet and Download Card

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayModelDownloadCard.swift`

**Interfaces:**
- Consumes:
  - `modelManager.isFullOfflinePackReady()`
  - `modelManager.fullOfflinePackState`
  - `modelManager.remainingOfflinePackSizeMB`
  - `modelManager.state(for: type)`
- Produces:
  - Explicit `.error` handling in `modelRow(type:)` with danger subtitle and `CraftButton(AppStrings.Common.retry)`.
  - Explicit `.error` handling in the top unified pack card with error badge and retry button.
  - Dynamic button label reflecting remaining MB (e.g. `Download Remaining Pack (~85MB)`) when partial models are downloaded.
  - Checkmark badge and "Free up storage" when all models are downloaded.

- [ ] **Step 1: Update AIConfigSheet.swift**

In `AIConfigSheet.swift`:
1. Top Card:
   - If `modelManager.isFullOfflinePackReady()`: show `AppStrings.AIPack.statusReady` ("Ready"), checkmark badge, and "Free up storage" button.
   - If `case .downloading`: show progress bar.
   - If `case .error(let msg)`: show error badge (`.danger` tone), status text `AppStrings.AIPack.statusDownloadFailed`, and button `AppStrings.AIPack.retryAction`.
   - Else (partial / not downloaded):
     - Show remaining size button `AppStrings.AIPack.downloadRemainingAction(modelManager.remainingOfflinePackSizeMB)`.
2. `modelRow(type:)`:
   - If `isReady`: show "Free up storage".
   - If `case .downloading`: show progress bar.
   - If `case .error(let message)`:
     - Subtitle: `AppStrings.AIModelDownload.statusErrorText` in `theme.colors.statusDanger`.
     - Action: `CraftButton(AppStrings.Common.retry, variant: .outline, size: .sm)` with danger tint.
   - Else (`.notDownloaded`):
     - Subtitle: `~85MB`.
     - Action: `CraftButton(AppStrings.AIModelDownload.actionDownload, variant: .secondary, size: .sm)`.

- [ ] **Step 2: Update RoleplayModelDownloadCard.swift**

In `RoleplayModelDownloadCard.swift`:
1. If `modelManager.isFullOfflinePackReady()`, dismiss or display ready checkmark.
2. If `case .error` in `fullOfflinePackState`:
   - Show error message and "Retry" button.
3. Otherwise, use `AppStrings.AIPack.downloadRemainingAction(modelManager.remainingOfflinePackSizeMB)`.

- [ ] **Step 3: Verify build and UI tests**

Run: `xcodebuild build -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17"`
Expected: BUILD SUCCEEDED with 0 errors, 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/AIConfigSheet.swift VocabCraftApp/Features/AIAssistant/Views/Components/RoleplayModelDownloadCard.swift
git commit -m "fix(ui): surface explicit download error states, retry actions, and dynamic remaining pack size"
```

---

### Task 4: Full Verification, SwiftLint & Regression Testing

**Files:**
- Entire repository

- [ ] **Step 1: Run SwiftLint**
Run: `swiftlint lint --strict`
Expected: 0 violations.

- [ ] **Step 2: Run all AI & Model Manager Test Suites**
Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests -only-testing:VocabCraftAppTests/ConcreteAIPackTests -only-testing:VocabCraftAppTests/KokoroTTSEngineTests -only-testing:VocabCraftAppTests/LlamaInferenceWorkerTests`
Expected: 100% PASS.

- [ ] **Step 3: Run CraftUIKit Package Tests**
Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% PASS.

- [ ] **Step 4: Check for auto-generated files or git status**
Run: `git status`
Expected: Clean working tree.
