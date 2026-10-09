# Offline Pack Download Feedback & iOS Native Extraction Design

## 1. Context & Motivation

In the VocabCraft AI Assistant configuration screen (`AIConfigSheet`), users can download the **Complete Offline AI Pack** (~975MB total), containing:
- **Kokoro Neural Voice** (~85MB TTS)
- **WhisperKit Speech Recognition** (~48MB STT)
- **Llama 3.2 1B Reasoning Model** (~740MB LLM)

### Observed Bug
On a physical iOS device, when the user taps "Download Complete Pack (~975MB)":
1. WhisperKit and Llama 3.2 download and become `.ready` (showing "~48MB (Downloaded)" and "~740MB (Downloaded)").
2. Kokoro finishes downloading, but during archive extraction, `posix_spawn(&pid, "/usr/bin/tar", ...)` fails because third-party sandboxed iOS apps cannot execute command-line tools and `/usr/bin/tar` does not exist on iOS.
3. Kokoro's download state transitions to `.error(...)`.
4. In `AIConfigSheet.swift`, `modelRow(type:)` and the unified pack card lack branches for `.error(...)`. Instead, they silently fall through into the default `else` branch, resetting Kokoro to "Download" and "~85MB", and resetting the top card to "Download Required" and "Download Complete Pack (~975MB)".
5. The user is left confused: the download appears to have succeeded, but the button keeps reappearing without error notice or feedback.

---

## 2. Architectural Design

```
+-----------------------------------------------------------------------------------+
|                           AIConfigSheet / Download UI                             |
|                                                                                   |
|  [Complete Offline AI Pack]                                                       |
|  - If all ready: Status "Ready" (green), Checkmark Badge, [Free up storage]       |
|  - If downloading: Progress Bar, Status "Downloading..."                          |
|  - If any error: Status "Download Failed" (red), [Retry Download (~remainingMB)]   |
|  - If partial (Whisper+Llama ready): [Download Remaining Pack (~85MB)]            |
|                                                                                   |
|  Breakdown:                                                                       |
|  - Kokoro: [Free up storage] (ready) | [Retry] (error) | [Download] (notDownloaded) |
|  - WhisperKit: [Free up storage]                                                 |
|  - Llama 3.2: [Free up storage]                                                   |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                             OnDemandAIModelManager                                |
|                                                                                   |
|  - remainingOfflinePackSizeMB: Computes missing MB (e.g. 85MB instead of 975MB)   |
|  - extractArchive: Native In-Process Streaming BZip2 + Tar Reader (No posix_spawn)|
|    * Uses libbz2 (BZ2_bzReadOpen, BZ2_bzRead, BZ2_bzReadClose) via dlopen/dynamic  |
|    * Streams uncompressed bytes to pure Swift Tar reader with 512-byte blocks     |
|    * Auto-flattens nested directory (e.g. kokoro-en-v0_19/ -> kokoro/)             |
|  - isModelReady(.kokoro):                                                         |
|    * Validates model.onnx, voices.bin, tokens.txt, espeak-ng-data                 |
|    * Auto-flattens nested subfolder if files exist inside kokoro-en-v0_19/        |
+-----------------------------------------------------------------------------------+
```

---

## 3. Detailed Component Specifications

### 3.1 Native In-Process Archive Extractor (`OnDemandAIModelManager.swift`)
- **Removal of `posix_spawn`**: Eliminate any dependency on external system processes or `/usr/bin/tar`.
- **In-Process BZip2 Decompressor**:
  - Dynamically binds to `/usr/lib/libbz2.dylib` (available on iOS and macOS).
  - Uses `BZ2_bzReadOpen`, `BZ2_bzRead`, and `BZ2_bzReadClose` with a 64KB buffer.
- **Pure Swift Tar Parser**:
  - Reads 512-byte header blocks.
  - Parses file path (bytes 0..<100, prefix 345..<500), file size (bytes 124..<136 octal), and typeflag (byte 156: '0' for file, '5' for directory).
  - Skips directory entries, creates intermediate destination directories, and streams file content to disk.
  - Automatically strips leading top-level directory (e.g. `kokoro-en-v0_19/`) so all files land directly in `destinationURL`.
- **Auto-Flattening Guarantee**:
  - If files are found in a nested directory inside `destinationURL`, `isModelReady(.kokoro)` and `extractArchive` auto-flatten all files into `destinationURL`.

### 3.2 Dynamic Remaining Pack Size & Error States (`OnDemandAIModelManager.swift`)
- Add `public var remainingOfflinePackSizeMB: Int`:
  - Sums `sizeMB` for all `type in AIModelType.allCases where !isModelReady(type)`.
  - When Whisper and Llama are ready, returns `85`.
- Update `startFullOfflinePackDownload()`:
  - Iterates over unready models and starts download, clearing any previous `.error` state.

### 3.3 Explicit UI Error Feedback & State Transitions (`AIConfigSheet.swift`)
- **Top Unified Pack Card**:
  - `isFullOfflinePackReady()` == true:
    - Status text: `AppStrings.AIPack.statusReady` ("Ready") with `theme.colors.statusSuccess`.
    - Badge: `CraftBadge` with `.check`, `.success` tone.
    - Button: `AppStrings.Settings.modelsFreeSpace` ("Free up storage").
  - `case .downloading` in `fullOfflinePackState`:
    - Shows `CraftProgressBar` and percentage.
  - `case .error(let msg)` in `fullOfflinePackState`:
    - Status text: `AppStrings.AIModelDownload.statusErrorText` with `theme.colors.statusDanger`.
    - Badge: `CraftBadge` with `.warning`, `.danger` tone.
    - Button: `AppStrings.AIPack.retryAction` ("Retry Download").
  - Default (unready):
    - Status text: `AppStrings.AIPack.statusNeedsDownload`.
    - Button: If partial models ready, uses `AppStrings.AIPack.downloadRemainingAction(remainingMB)`.
- **Breakdown Rows (`modelRow(type:)`)**:
  - `isReady`: "Free up storage" button.
  - `case .downloading(progress)`: Progress bar.
  - `case .error(message)`:
    - Subtitle: `AppStrings.AIModelDownload.statusErrorText` colored with `theme.colors.statusDanger`.
    - Action: `CraftButton(AppStrings.Common.retry, variant: .outline)` colored with `theme.colors.statusDanger`.
  - `.notDownloaded`:
    - Subtitle: `~85MB`.
    - Action: `CraftButton(AppStrings.AIModelDownload.actionDownload, variant: .secondary)`.

### 3.4 RoleplayModelDownloadCard.swift Updates
- Handles `.error` by displaying retry button and error tone.
- When `modelManager.isFullOfflinePackReady()`, invokes `onDismiss()` or displays checkmark.

### 3.5 100% Bilingual Localization (`Localizable.xcstrings` & `AppStrings.swift`)
- Add required keys in `Localizable.xcstrings`:
  - `app.ai.model_download.status_error`:
    - `en`: "Download Failed"
    - `vi`: "Tải Thất Bại"
  - `app.ai.model_download.action_retry`:
    - `en`: "Retry"
    - `vi`: "Thử Lại"
  - `app.ai.pack.offline.download_remaining_action`:
    - `en`: "Download Remaining Pack (~%lldMB)"
    - `vi`: "Tải Gói Còn Lại (~%lldMB)"
  - `app.ai.pack.status.download_failed`:
    - `en`: "Download Failed"
    - `vi`: "Tải Thất Bại"
- In `AppStrings.swift`:
  - Computed `var` for all keys (no non-Sendable static var).

---

## 4. Verification Plan
1. Unit tests in `OnDemandAIModelManagerTests.swift`:
   - Verify native in-process bzip2/tar archive extraction without `posix_spawn`.
   - Verify directory auto-flattening of nested folders.
   - Verify `remainingOfflinePackSizeMB` computation.
   - Verify retry and error state propagation.
2. Localization tests in `AIAssistantLocalizationTests.swift`:
   - Verify all new keys in EN and VI catalogs.
3. Quality gates:
   - Zero compiler warnings, 0 SwiftLint violations, 100% unit tests pass.
