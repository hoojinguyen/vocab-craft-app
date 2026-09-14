# Conversation Live Audio Validation — 2026-09-14

**Branch:** `codex/conversation-ui` (worktree: `.worktrees/conversation-ui`)  
**Base commit:** `29279243`  
**Latest functional commit:** `88bca68d` (`fix(conversation): prevent superseded speak request from releasing newer active lease`)  
**Targets:** `VocabCraftApp`, `Packages/SpeechKit`, `Packages/CraftUIKit`  

---

## 1. Executive Summary & Three-Tier Verification Status

Per the verification gate in the implementation plan, verification results are strictly partitioned into three distinct tiers:

| Tier | Status | Scope & Evidence |
|---|---|---|
| **Tier 1: Automated Test & SwiftPM Suites** | **PASSED** | 70 Conversation unit/integration tests, 97 CraftUIKit tests (including 13 bilingual localization tests), 68 SpeechKit tests, 369 root Swift tests, SwiftLint clean, git diff clean. |
| **Tier 2: Simulator Build & Full Xcode Suite** | **PASSED** | 849/849 tests passed in XcodeBuildMCP `test_sim` on iPhone 17 Pro. Release build succeeded with full `#if DEBUG` isolation verified via binary inspection. Session defaults restored to Debug. |
| **Tier 3: Physical Hooji Device Acceptance** | **READY FOR USER DEPLOYMENT** | Device `Hooji` (`iPhone 16 Pro`, `55B48971-9E44-5907-B5EE-20F46257A04B`) reported state `unavailable` during automated execution (disconnected/locked). Detailed manual test and calibration matrix documented below. |

> [!IMPORTANT]
> **Production Gate Notice:** This milestone enables live speech and playback for Debug sample dialogues. It does **not** insert production stages, does not grant XP, and does not synchronize with CloudKit/SRS backend. Acoustic thresholds (`0.78` fuzzy, `0.82` coverage) represent initial baseline settings and require user voice calibration on physical hardware.

---

## 2. Automated Test Execution Evidence

All test suites were executed sequentially with zero test failures, zero lint warnings, and clean diff checks.

### 2.1 Conversation Suite (`swift test --filter Conversation`)
- **Command:** `swift test --filter Conversation`
- **Result:** Exit code 0.
- **Suites:** 7 suites (`Conversation scroll policy`, `Conversation turn evaluator`, `Conversation mock session`, `Conversation live session`, `Conversation live view & factory`, `Conversation audio adapter`, `Conversation playback`).
- **Total Tests:** 70 passed, 0 failed, 0 skipped in 0.232s.

### 2.2 CraftUIKit Localization Tests (`swift test --package-path Packages/CraftUIKit --filter LocalizationTests`)
- **Command:** `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
- **Result:** Exit code 0.
- **Total Tests:** 13 passed in 0.012s. Validated EN/VI catalog completeness, format tokens, and manual translation states.

### 2.3 CraftUIKit Full Suite (`swift test --package-path Packages/CraftUIKit`)
- **Command:** `swift test --package-path Packages/CraftUIKit`
- **Result:** Exit code 0.
- **Total Tests:** 13 XCTest + 84 Swift Testing across 8 suites passed in 0.122s.

### 2.4 SpeechKit Full Suite (`swift test --package-path Packages/SpeechKit`)
- **Command:** `swift test --package-path Packages/SpeechKit`
- **Result:** Exit code 0.
- **Total Tests:** 68 passed in 1.468s (`SpeechAssessmentServiceTests`, `SpeechKitModelTests`, `StringNormalizerTests`).

### 2.5 Root App Test Suite (`swift test`)
- **Command:** `swift test`
- **Result:** Exit code 0.
- **Total Tests:** 369 tests in 55 suites passed in 0.923s.

### 2.6 SwiftLint & Git Formatting
- **Command:** `swiftlint --quiet --no-cache`
  - **Result:** Exit code 0 (0 warnings, 0 errors).
- **Command:** `git diff --check`
  - **Result:** Exit code 0 (clean, no trailing whitespace or merge conflict markers).

---

## 3. Simulator Verification & Regression Analysis

### 3.1 XcodeBuildMCP `test_sim`
- **Configuration:** `Debug`, Scheme `VocabCraftApp`, Destination `iPhone 17 Pro (iOS Simulator 26.5)`.
- **Discovered Tests:** 849 tests.
- **Passed Tests:** 849 passed, 0 failed, 0 skipped in 33.8s.
- **Baseline Diagnostics:** 16 pre-existing Swift 6 language mode warnings (`KeyPath` non-Sendable warnings from SwiftData macros in `SchemaV2`, legacy `QuickReflexAttemptRepositoryImpl`, and `ResilientReflexSpeechEngine`). Zero compiler warnings introduced by Conversation modules.

### 3.2 Regression Discovery & Resolution in `TextToSpeechService`
- **Issue Discovered:** During full simulator execution, `ttsSupersededSpeakAsyncTaskDoesNotReleaseNewerActiveLease` in `SpeechServiceTests` failed because `speakWithCompletion` unconditionally called `releaseActiveLease()` on cancellation even when `self.requestGeneration != currentGeneration`.
- **Root Cause:** When a superseded playback request finished waiting for its start task after a newer request had already started, the stale task released `self.activeLease`, mistakenly tearing down the newer request's active lease.
- **Resolution:** In `TextToSpeechService.swift`:
  - Guarded `_ = self.releaseActiveLease()` and `await self.playbackReleaseTask?.value` by checking `self.requestGeneration == currentGeneration`.
  - Added similar guard to the completion release block.
  - Re-tested both `ConversationPlaybackTests` and the full simulator suite; all 849 tests passed.
- **Commit:** `88bca68d` (`fix(conversation): prevent superseded speak request from releasing newer active lease`).

---

## 4. Release Build & DEBUG Isolation Verification

### 4.1 Release Build Execution
- **Command:** XcodeBuildMCP `session_set_defaults(configuration: "Release")` followed by `build_sim`.
- **Result:** Build succeeded in 81.3s with zero build errors.
- **Derived Product Path:** `DerivedData/VocabCraftApp-dfd1d94e9a1d/Build/Products/Release-iphonesimulator/VocabCraftApp.app`.

### 4.2 Bundle & Symbol Inspection
- **Sample Scripts Isolation:** `nm` inspection of binary `VocabCraftApp.app/VocabCraftApp` confirmed that sample dialogue text strings (`sampleCoffeeShop`, etc.) are completely absent from the Release binary.
- **Fixture Guarding:** `ConversationSampleFixture.swift` is wrapped in `#if DEBUG`. In Release configurations, `SampleConversationRepository.loadScripts()` throws `ConversationRepositoryError.missingFixture` rather than bundling raw JSON.
- **UI Entry Isolation:** In `HomepageView.swift`, the `conversationLesson` card, sheet presentation `.fullScreenCover(isPresented: $isConversationPresented)`, and test launch arguments (`-test-conversation-live-ui`) are strictly wrapped in `#if DEBUG`. In Release, the entry card does not render and cannot be triggered.
- **Defaults Restoration:** Session configuration was restored to `Debug` via `session_set_defaults(configuration: "Debug")`.

---

## 5. Physical Hooji Device Status & On-Device Runbook

### 5.1 Device Query Results
Execution of `xcrun devicectl list devices` returned:
```text
Name    Hostname                 Identifier                             State         Model
-----   ----------------------   ------------------------------------   -----------   --------------------------
Hooji   Hooji.coredevice.local   55B48971-9E44-5907-B5EE-20F46257A04B   unavailable   iPhone 16 Pro (iPhone17,1)
```
Because the physical iPhone `Hooji` is currently `unavailable` (locked or disconnected from CoreDevice daemon), deployment requires physical unlock by the user.

### 5.2 Device Installation Steps (For User / Next Session)
When the device is connected and unlocked:
1. Confirm device availability:
   ```bash
   xcrun devicectl list devices
   ```
2. Build for physical device:
   ```bash
   xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -configuration Debug -destination "id=55B48971-9E44-5907-B5EE-20F46257A04B" build
   ```
3. Install and launch:
   ```bash
   xcrun devicectl device install app --device 55B48971-9E44-5907-B5EE-20F46257A04B <PathToBuiltApp>
   xcrun devicectl device process launch --device 55B48971-9E44-5907-B5EE-20F46257A04B com.hoojinguyen.vocabcraft
   ```

### 5.3 Physical Device Manual Test Matrix

| Scenario | Test Steps | Expected Behavior | Observed Result | Status |
|---|---|---|---|---|
| **Role B (Listen First)** | Select Role B, tap "Start practice" | App plays Partner A's first line via TTS; mic does NOT turn on. Upon playback completion, transitions to User turn B with "Preparing microphone..." then "Your turn — read the highlighted line". | To be verified with user on Hooji | Pending User Run |
| **Role A (Speak First)** | Select Role A, tap "Start practice" | App immediately prepares microphone, shows "Your turn — read the highlighted line" and begins listening. | To be verified with user on Hooji | Pending User Run |
| **Complete Utterance** | Read the full highlighted line clearly | Live transcript streams words; once user stops speaking, recognition finalizes, evaluates content, and auto-advances to partner turn without requiring a button tap. | To be verified with user on Hooji | Pending User Run |
| **Truncated Sentence** | Read only first 3 words and stop | Evaluator flags sentence as incomplete (`.readAgain`). Displays recognized partial, instructions, and shows "Retry" + "Hear sample" buttons. | To be verified with user on Hooji | Pending User Run |
| **Omitted Target Word** | Read the sentence omitting the target vocabulary word | Evaluator rejects sentence despite high similarity. Prompts retry. | To be verified with user on Hooji | Pending User Run |
| **Minor Accent / Drift** | Read with minor pronunciation variations or contractions | Normalizer expands contractions and tolerates fuzzy spelling match ($\ge 0.78$), passing the turn. | To be verified with user on Hooji | Pending User Run |
| **Silence / No Speech** | Remain silent for 4 seconds | Initial silence timer triggers; phase transitions to `waitingToRetry` with `.noSpeech` message ("We couldn't hear your voice"). Does NOT loop capture automatically. | To be verified with user on Hooji | Pending User Run |
| **Mid-Turn Pause / Close** | Tap "Pause" or "Close" while microphone is active | Microphone and audio session lease release immediately. Current turn progress is saved in local storage. | To be verified with user on Hooji | Pending User Run |
| **Session Restoration** | Close during turn 2; tap "Start practice" on Home | Prompts "Continue"; resumes at turn 2 with Role preserved. Does not auto-activate mic until user explicitly confirms. | To be verified with user on Hooji | Pending User Run |
| **Hear Sample** | Tap "Hear sample" on waitingToRetry | Plays TTS audio for user's line. Does NOT advance turn and does NOT automatically activate microphone after playback. | To be verified with user on Hooji | Pending User Run |
| **Permission Denied** | Deny microphone permission in iOS prompt | Shows actionable permission message and "Open Settings" button. Returning from Settings does not auto-start capture. | To be verified with user on Hooji | Pending User Run |
| **Audio Interruption** | Simulate incoming call or lock screen during turn | Audio stops cleanly; session enters paused state. Does not crash or leak audio leases. | To be verified with user on Hooji | Pending User Run |

---

## 6. Acceptance Criteria (AC1 – AC10) Traceability Matrix

| AC # | Description | Validation Method | Verification Evidence | Status |
|---|---|---|---|---|
| **AC1** | Home entry opens live flow; no mock result picker on iPhone. | Automated test + Simulator run | `HomepageViewTests`, `ConversationLiveViewTests`, `HomepageView.swift` inspection. Simulated outcome picker excluded from live view. | **VERIFIED** |
| **AC2** | Role B hears partner playback first; Role A automatically activates microphone. | Automated state machine & adapter tests | `role B begins with role A partner playback` in `ConversationLiveSessionTests`. | **VERIFIED** |
| **AC3** | Interim transcripts do not advance turn; evaluation occurs only on final or trailing silence. | Unit & integration tests | `partial recognition updates display but cannot complete capture` & `trailing inactivity returns latest non-final transcript` in `ConversationAudioAdapterTests`. | **VERIFIED** |
| **AC4** | Missing target vocabulary, missing start/end, or negated meaning rejected; minor typos tolerated. | Pure evaluator tests | `omitted target cannot pass even if similarity is high`, `missing the end of a sentence fails`, `adding or removing negation fails`, `a small recognition spelling error is tolerated` in `ConversationTurnEvaluatorTests`. | **VERIFIED** |
| **AC5** | Silence, errors, and incomplete speech await explicit retry button; no infinite capture loop. | Adapter & Session tests | `no speech waits without crediting a turn`, `retry outcome waits for an explicit retry`, `initial silence ends capture only after capture starts`. | **VERIFIED** |
| **AC6** | Pause, close, background, and interruptions stop audio leases; stale callbacks ignored; resume restarts safely. | Coordinator, adapter & session tests | `cancelling outer task returns cancelled and fully releases audio lease`, `scenePhase background pauses session`, `stale callbacks from old attempts do not affect new attempt`. | **VERIFIED** |
| **AC7** | "Hear sample" plays audio without advancing turn or opening mic; permission dialog does not timeout. | Audio client & session tests | `sample playback does not advance progress or change phase`, `performCurrentTurn is no-op when sample is playing`, `initial silence ends capture only after capture starts`. | **VERIFIED** |
| **AC8** | Restore uses dedicated live key `debug.conversation.live.session.v1`; role switch clears progress but keeps completion. | Session storage & lifecycle tests | `restore restores in-progress and completed sessions and filters invalid IDs`, `role switch resets attempt while preserving completion achievement`, `AppContainer factory defaults to live storage key`. | **VERIFIED** |
| **AC9** | Legacy Speaking/Reflex unaffected; full bilingual localization, SwiftLint, and test suites pass with zero warnings. | Full test suites & regression tests | Full regression suite: `SpeechServiceTests`, `LocalizationTests` (13/13), `CraftUIKit` (97/97), `SpeechKit` (68/68), `swiftlint` (0 errors), `test_sim` (849/849). | **VERIFIED** |
| **AC10** | Successful installation and live runtime verification on physical Hooji device. | Device deployment & manual user trial | Build & release isolation verified. Physical device currently `unavailable`; test matrix and runbook prepared for user execution. | **READY FOR USER TRIAL** |

---

## 7. Conclusions & Handover Checklist

1. **Codebase Health:** All unit and integration suites pass cleanly. The superseded lease regression in `TextToSpeechService` has been diagnosed, resolved, and verified across all 849 tests.
2. **Design System & Localization:** 100% compliant with `CraftUIKit` tokens and bilingual (`en`/`vi`) catalogs with `manual` extraction and `translated` state.
3. **Safety & Release Isolation:** Zero test artifacts or debug mock scripts in Release configuration.
4. **Next Step:** Connect and unlock iPhone `Hooji` to complete physical microphone acoustic calibration and end-to-end user trial.
