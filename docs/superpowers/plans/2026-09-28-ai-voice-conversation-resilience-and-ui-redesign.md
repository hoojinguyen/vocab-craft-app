# Speaking AI Voice Conversation Resilience & UI/UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate microphone drops, integrate SpeechKit 2-tier fuzzy matching for long conversational utterances, naturalize conversation turn-taking, and redesign the AI voice calling UI/UX to strictly conform to CraftUIKit and iOS safe areas.

**Architecture:** Session-scoped `ResilientConversationSpeechEngine` leveraging `AudioBufferRelay` and `SpeechAudioEngineController` to keep a continuous warm duplex audio pipeline (< 50ms turn transitions); 2-tier `SpeechKit` fuzzy tolerance (`ReflexSpeechMatcher` for morphological target vocabulary, `FuzzySpeechMatcher` for suggested sentence alignment); Native Call Canvas with a dedicated Scaffolding Bottom Drawer displaying 100% multi-line text without truncation.

**Tech Stack:** Swift 6, SwiftUI, Observation, AVFoundation, Speech, SpeechKit, CraftUIKit, Swift Testing.

**Spec:** `docs/superpowers/specs/2026-09-28-ai-voice-conversation-resilience-and-ui-redesign.md`

## Global Constraints
- Target platforms: iOS 17+, macOS (Catalyst/Mac).
- Swift 6 strict concurrency compliance (`@MainActor` isolation, `Sendable` types).
- 100% `CraftUIKit`-first component hierarchy and design token conformance (`CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`). Zero raw colors, fonts, or padding.
- 100% bilingual parity (EN & VI) in `Localizable.xcstrings` under `app.ai_call.*` namespace.
- Zero compiler warnings, zero lint errors, and 100% test pass rate before declaring completion.

---

### Task 1: Localization & Resource Keys (`Localizable.xcstrings` & `AppStrings.swift`)

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Resources/AppStrings.swift`
- Test: `VocabCraftAppTests/Resources/LocalizationTests.swift`

**Interfaces:**
- Consumes: None
- Produces: `AppStrings.AICall` localization keys:
  - `activeBadge`: `"app.ai_call.active_badge"`
  - `suggestedTitle`: `"app.ai_call.suggested_title"`
  - `suggestedToggle`: `"app.ai_call.suggested_toggle"`
  - `listenSample`: `"app.ai_call.listen_sample"`
  - `finishSpeaking`: `"app.ai_call.finish_speaking"`
  - `micMuted`: `"app.ai_call.mic_muted"`
  - `listeningPrompt`: `"app.ai_call.listening_prompt"`
  - `retryListening`: `"app.ai_call.retry_listening"`

- [ ] **Step 1: Write the failing localization test**

Add unit tests in `VocabCraftAppTests/Resources/LocalizationTests.swift` asserting the presence and non-empty translation of `app.ai_call.*` keys in both `en` and `vi`.

```swift
@Test("Verify Speaking AI Call localization keys exist in EN and VI")
func testAICallLocalizationKeysExist() {
    let keys = [
        "app.ai_call.active_badge",
        "app.ai_call.suggested_title",
        "app.ai_call.suggested_toggle",
        "app.ai_call.listen_sample",
        "app.ai_call.finish_speaking",
        "app.ai_call.mic_muted",
        "app.ai_call.listening_prompt",
        "app.ai_call.retry_listening"
    ]
    for key in keys {
        #expect(Bundle.main.localizedString(forKey: key, value: nil, table: nil) != key)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testAICallLocalizationKeysExist`
Expected: FAIL due to missing keys in `Localizable.xcstrings`.

- [ ] **Step 3: Add strings to `Localizable.xcstrings` and `AppStrings.swift`**

Add bilingual entries (`en` and `vi`) with `extractionState: "manual"` and `state: "translated"` to `VocabCraftApp/Resources/Localizable.xcstrings`:
- `app.ai_call.active_badge`: "Live Call" / "Đang gọi"
- `app.ai_call.suggested_title`: "Suggested Responses" / "Gợi ý câu trả lời"
- `app.ai_call.suggested_toggle`: "Suggested responses (%lld)" / "Gợi ý câu trả lời (%lld)"
- `app.ai_call.listen_sample`: "Listen to sample pronunciation" / "Nghe phát âm mẫu"
- `app.ai_call.finish_speaking`: "Tap when finished speaking" / "Chạm khi nói xong"
- `app.ai_call.mic_muted`: "Microphone muted" / "Đã tắt mic"
- `app.ai_call.listening_prompt`: "Speak into the microphone..." / "Hãy nói vào microphone..."
- `app.ai_call.retry_listening`: "Tap to retry microphone" / "Chạm để thử lại mic"

Add `AppStrings.AICall` struct inside `VocabCraftApp/Resources/AppStrings.swift`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter testAICallLocalizationKeysExist`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Resources/AppStrings.swift VocabCraftAppTests/Resources/LocalizationTests.swift
git commit -m "feat(l10n): add bilingual strings for speaking ai call redesign"
```

---

### Task 2: SpeechKit Two-Tier Fuzzy Matching in `ExecuteRoleplayTurnUseCase`

**Files:**
- Modify: `VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift`
- Create: `VocabCraftAppTests/AI/ExecuteRoleplayTurnUseCaseFuzzyTests.swift`

**Interfaces:**
- Consumes: `SpeechKit.ReflexSpeechMatcher`, `SpeechKit.FuzzySpeechMatcher`, `SpeechKit.StringNormalizer`
- Produces: Enhanced `ExecuteRoleplayTurnUseCase.execute` detecting target words through morphological inflections and aligning user speech with `suggestedResponses`.

- [ ] **Step 1: Write the failing unit tests for fuzzy target word detection**

Create `VocabCraftAppTests/AI/ExecuteRoleplayTurnUseCaseFuzzyTests.swift` testing:
1. Target word with plural inflection: user says "I would like two warm beverages", target word is "beverage" $\rightarrow$ detected.
2. Target word with past tense inflection: user says "I ordered a pastry", target word is "order" $\rightarrow$ detected.
3. Target word with slight accent/phonetic variation ($\ge 70\%$ ratio): target word "complimentary" $\rightarrow$ detected.
4. Suggested response alignment: user speaks sentence with $\ge 70\%$ match to a suggested response $\rightarrow$ recognized, credited, and passed to LLM.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ExecuteRoleplayTurnUseCaseFuzzyTests`
Expected: FAIL because existing logic uses strict regex `\bword\b`.

- [ ] **Step 3: Implement 2-tier fuzzy matching in `ExecuteRoleplayTurnUseCase`**

Modify `ExecuteRoleplayTurnUseCase.swift`:
1. Use `ReflexSpeechMatcher.isReflexMatch(spokenText: userUtterance, targetLemma: word, toleranceThreshold: 0.70)` to detect target vocabulary across all grammatical inflections and phonetic variants.
2. Check if user utterance matches any of `scenario.starterSuggestions` or previous turn's `suggestedResponses` using `FuzzySpeechMatcher.evaluate(spokenText: userUtterance, targetSentence: suggestion, passThreshold: 0.70)`.
3. If matched, union all target words found in the suggested response into `detectedLocalWords`.
4. Include recognized candidate sentence in prompt context if applicable.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ExecuteRoleplayTurnUseCaseFuzzyTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift VocabCraftAppTests/AI/ExecuteRoleplayTurnUseCaseFuzzyTests.swift
git commit -m "feat(ai): integrate SpeechKit two-tier fuzzy matching in roleplay turn execution"
```

---

### Task 3: Resilient Audio & Conversation Speech Engine (`ResilientConversationSpeechEngine`)

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Services/ResilientConversationSpeechEngine.swift`
- Modify: `VocabCraftApp/Domain/Protocols/VoiceConversationEngineProtocol.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Create: `VocabCraftAppTests/AI/ResilientConversationSpeechEngineTests.swift`

**Interfaces:**
- Consumes: `SpeechAudioEngineController`, `AudioBufferRelay`, `AudioSessionCoordinator`, `SilenceDetector`, `TextToSpeechProtocol`, `ExecuteRoleplayTurnUseCase`, `CompleteRoleplaySessionUseCase`
- Produces: `ResilientConversationSpeechEngine: VoiceConversationEngineProtocol` with warm audio session, sub-50ms mute/unmute buffer switching, real-time metering, and hybrid turn-taking.

- [ ] **Step 1: Write the failing tests for `ResilientConversationSpeechEngine`**

Create `VocabCraftAppTests/AI/ResilientConversationSpeechEngineTests.swift` testing:
1. Engine initializes with warm session and enters `.speaking` on `startCall`.
2. When TTS speaks, `bufferRelay` is muted so AI audio does not feed into STT.
3. When TTS completes, `bufferRelay` un-mutes and speech recognizer starts without recreating `AVAudioEngine`.
4. Audio level streams continuously to `audioLevel` property.
5. VAD trailing silence (1.8s) triggers turn completion when user stops speaking.
6. `finishUserTurnManually()` immediately triggers `.thinking` without waiting for silence timer.
7. `endCall()` cleanly releases audio lease and returns session summary.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ResilientConversationSpeechEngineTests`
Expected: FAIL (type not found).

- [ ] **Step 3: Implement `ResilientConversationSpeechEngine`**

Create `VocabCraftApp/Features/AIAssistant/Services/ResilientConversationSpeechEngine.swift`:
1. Use `SpeechAudioEngineControlling` and `AudioBufferRelay` for session-scoped lifecycle.
2. Acquire `.duplexSpeech` audio lease once on `startCall()`.
3. Keep hardware running; during TTS playback, call `bufferRelay.mute()`; when TTS finishes, call `bufferRelay.unmute()` and start `SFSpeechAudioBufferRecognitionRequest`.
4. Install buffer listener on `AudioBufferRelay` to calculate RMS and publish `audioLevel` (clamped 0.0...1.0) on `MainActor`.
5. Wire `SilenceDetector` with `trailingSilenceDuration: .milliseconds(1800)` and `firesSilenceOnInitialTimeout: false`.
6. Implement `finishUserTurnManually()`, `toggleMute()`, `toggleSubtitles()`, and `endCall()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ResilientConversationSpeechEngineTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Services/ResilientConversationSpeechEngine.swift VocabCraftAppTests/AI/ResilientConversationSpeechEngineTests.swift
git commit -m "feat(audio): implement ResilientConversationSpeechEngine with warm duplex session and buffer relay"
```

---

### Task 4: Scaffolding Drawer Component (`RoleplaySuggestedDrawer`)

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/Components/RoleplaySuggestedDrawer.swift`
- Create: `VocabCraftAppTests/AI/RoleplaySuggestedDrawerTests.swift`

**Interfaces:**
- Consumes: `RoleplayVoiceCallViewModel`, `CraftUIKit` tokens (`theme.colors`, `theme.typography`, `theme.spacing`, `theme.radii`), `CraftButton`, `CraftIconButton`, `CraftCard`
- Produces: `RoleplaySuggestedDrawer: View` with collapsed pill handle and expanded full multi-line bottom sheet drawer.

- [ ] **Step 1: Write the failing tests for `RoleplaySuggestedDrawer` state logic**

Create `VocabCraftAppTests/AI/RoleplaySuggestedDrawerTests.swift` verifying:
1. When `suggestedResponses` is empty, view renders empty.
2. When collapsed, capsule button shows item count.
3. Attributed text properly highlights all target words present in each suggestion with bold `brandPrimary`.
4. Tapping pronunciation preview invokes `viewModel.playSamplePronunciation`.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter RoleplaySuggestedDrawerTests`
Expected: FAIL (component not found).

- [ ] **Step 3: Implement `RoleplaySuggestedDrawer`**

Create `RoleplaySuggestedDrawer.swift`:
1. Design collapsed capsule: `CraftButton` with chevron up and `AppStrings.AICall.suggestedToggle(count)`.
2. Design expanded sheet / drawer:
   - Header with `AppStrings.AICall.suggestedTitle` and close button.
   - Scrollable `VStack` of suggestions.
   - Each suggestion card uses `CraftCard` with full multi-line text wrapping (`.lineLimit(nil)`, `.fixedSize(horizontal: false, vertical: true)`).
   - Target words highlighted using `AttributedString` with `theme.colors.brandPrimary` and bold typography.
   - Pronunciation preview `CraftIconButton(symbol: .speakerWave2, variant: .subtle)`.
3. Auto-collapse drawer on state change to `.speaking` or `.thinking`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter RoleplaySuggestedDrawerTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/Components/RoleplaySuggestedDrawer.swift VocabCraftAppTests/AI/RoleplaySuggestedDrawerTests.swift
git commit -m "feat(ui): create RoleplaySuggestedDrawer with full multi-line wrapping and audio preview"
```

---

### Task 5: Safe Area & Layout Overhaul in `RoleplayVoiceCallView` & ViewModel Wiring

**Files:**
- Modify: `VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift`
- Modify: `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift`
- Test: `VocabCraftAppTests/AI/RoleplayVoiceCallViewModelTests.swift`

**Interfaces:**
- Consumes: `RoleplaySuggestedDrawer`, `ResilientConversationSpeechEngine`, `CraftVoiceOrbView`, `CraftUIKit` tokens
- Produces: Polished `RoleplayVoiceCallView` with 100% safe area compliance (Top status bar & Dynamic Island clearance, Bottom Home Indicator clearance) and seamless call controls.

- [ ] **Step 1: Write test for ViewModel lifecycle and drawer bindings**

Update `VocabCraftAppTests/AI/RoleplayVoiceCallViewModelTests.swift` testing:
1. `isHintsExpanded` toggling.
2. `finishSpeaking()` invocation forwarding to engine.
3. Clean discard alert handling on close button.

- [ ] **Step 2: Run test to verify it passes or fails**

Run: `swift test --filter RoleplayVoiceCallViewModelTests`
Expected: Verify test assertions.

- [ ] **Step 3: Overhaul `RoleplayVoiceCallView` layout**

Modify `RoleplayVoiceCallView.swift`:
1. Remove `.ignoresSafeArea()` from the entire content container; apply `theme.colors.canvasBackground.ignoresSafeArea()` strictly as background.
2. Enforce `.safeAreaPadding(.top)` so header HUD sits gracefully below Dynamic Island and status bar clock.
3. Enforce `.safeAreaPadding(.bottom)` so call action dock sits above Home Indicator.
4. Scale `CraftVoiceOrbView` to 140pt balanced diameter.
5. Replace old inline cramped suggested responses view with `RoleplaySuggestedDrawer`.
6. Add "Finish speaking" `CraftButton` directly above call dock when in `.listening` state.
7. Ensure all typography and colors use `theme.typography.*` and `theme.colors.*`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter RoleplayVoiceCallViewModelTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/RoleplayVoiceCallView.swift VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayVoiceCallViewModel.swift VocabCraftAppTests/AI/RoleplayVoiceCallViewModelTests.swift
git commit -m "feat(ui): overhaul RoleplayVoiceCallView safe area insets, dock controls, and drawer integration"
```

---

### Task 6: DI Container Wiring & Full Quality Gate Verification

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Test: Full test suite

**Interfaces:**
- Consumes: `ResilientConversationSpeechEngine`, `AppContainer`
- Produces: Production wiring of `ResilientConversationSpeechEngine` in `AppContainer.makeRoleplayVoiceCallViewModel`.

- [ ] **Step 1: Update `AppContainer.swift`**

Wire `ResilientConversationSpeechEngine` into `makeRoleplayVoiceCallViewModel(for scenario:)` so production calls use the resilient duplex engine.

- [ ] **Step 2: Run full test suite**

Run: `swift test`
Expected: 100% tests pass.

- [ ] **Step 3: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Verify build with zero compiler warnings**

Run: `swift build`
Expected: Build complete with 0 errors and 0 warnings.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift
git commit -m "chore(di): wire ResilientConversationSpeechEngine as default roleplay call engine"
```
