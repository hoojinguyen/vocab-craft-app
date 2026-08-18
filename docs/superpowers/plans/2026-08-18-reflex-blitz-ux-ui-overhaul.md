# Reflex Blitz UX/UI & Learning Experience Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Spoken Reflex Blitz drill UX/UI to eliminate visual dead space, integrate speech feedback directly into the challenge card, provide dynamic perimeter countdown timer pressure, inject target words into cloze blanks upon correct speech, support IPA phonetics, and enrich the summary screen with pronunciation replay.

**Architecture:** Maintain MVVM with Observation in SwiftUI. Extend `ReflexBlitzModels` with IPA and cloze morphing helpers. Upgrade `ReflexBlitzViewModel` with high-frequency (50ms) countdown fraction calculations. Rebuild `ReflexBlitzCardView` with `RoundedRectangle.trim` perimeter stroke and embedded audio visualizer. Upgrade `ReflexBlitzSummaryView` with interactive TTS mini speakers and full definition metadata.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Observation, AVFoundation / SFSpeechRecognizer, XCTest / ImageRenderer.

**Spec:** [`docs/superpowers/specs/2026-08-18-reflex-blitz-ux-ui-overhaul-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-18-reflex-blitz-ux-ui-overhaul-design.md)

## Global Constraints
- Target platform: iOS 17.0+
- Design system: Use semantic color tokens `Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabHeroAccent`, `Color.vocabMint`, `Color.vocabPeach`, `Color.vocabCoral`, `Color.vocabInk`, `Color.vocabMuted`, `Color.vocabHairline`.
- Minimum touch target: 44x44 pt for all interactive controls.
- Apple HIG & Voice accessibility compliant.

---

### Task 1: Extend ReflexBlitzModels with IPA Phonetics & Cloze Morphing

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`

**Interfaces:**
- Consumes: Existing `ReflexBlitzWordItem`, `ReflexBlitzAttempt`, `ReflexBlitzSessionSummary`
- Produces:
  - `ReflexBlitzWordItem.init(id:lemma:pos:ipa:definitionVi:exampleSentenceEn:exampleSentenceVi:clozeSentenceEn:)`
  - `ReflexBlitzWordItem.ipa: String`
  - `ReflexBlitzWordItem.completedSentenceWithTargetWord: String`
  - `ReflexBlitzWeakWordAttempt.ipa: String`
  - `ReflexBlitzWeakWordAttempt.definitionVi: String`

- [ ] **Step 1: Write failing unit tests for model extensions**

```swift
// Add to VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift
func testReflexBlitzWordItemIPAPhoneticsAndCompletedSentence() {
    let word = ReflexBlitzWordItem(
        id: 10,
        lemma: "serendipity",
        pos: "n.",
        ipa: "/ˌser.ənˈdɪp.ə.ti/",
        definitionVi: "Sự may mắn bất ngờ",
        exampleSentenceEn: "Finding this was pure serendipity.",
        exampleSentenceVi: "Tìm thấy thứ này là may mắn bất ngờ."
    )
    XCTAssertEqual(word.ipa, "/ˌser.ənˈdɪp.ə.ti/")
    XCTAssertEqual(word.initialLetterHint, "s... • n.")
    XCTAssertEqual(word.completedSentenceWithTargetWord, "Finding this was pure serendipity.")
}

func testSummaryPreservesWeakWordIPAndDefinition() {
    let word = ReflexBlitzWordItem(
        id: 11,
        lemma: "resilient",
        pos: "adj.",
        ipa: "/rɪˈzɪl.jənt/",
        definitionVi: "Kiên cường, mau hồi phục",
        exampleSentenceEn: "They remained resilient.",
        exampleSentenceVi: "Họ vẫn kiên cường."
    )
    let attempt = ReflexBlitzAttempt(
        wordId: 11,
        lemma: "resilient",
        pos: "adj.",
        ipa: "/rɪˈzɪl.jənt/",
        definitionVi: "Kiên cường, mau hồi phục",
        responseTimeMs: 6000,
        usedHint: true,
        isCorrect: false
    )
    let summary = ReflexBlitzSessionSummary.create(from: [attempt], maxCombo: 0)
    XCTAssertEqual(summary.weakWordAttempts.count, 1)
    XCTAssertEqual(summary.weakWordAttempts.first?.ipa, "/rɪˈzɪl.jənt/")
    XCTAssertEqual(summary.weakWordAttempts.first?.definitionVi, "Kiên cường, mau hồi phục")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzModelsTests`
Expected: FAIL (compilation error due to missing `ipa` property/arguments)

- [ ] **Step 3: Update ReflexBlitzModels.swift implementation**

Update `ReflexBlitzWordItem`, `ReflexBlitzAttempt`, and `ReflexBlitzWeakWordAttempt` with `ipa: String = ""` and `definitionVi: String = ""`, and provide `completedSentenceWithTargetWord`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzModelsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift
git commit -m "feat(reflex): add IPA phonetics and completed sentence helpers to ReflexBlitzModels"
```

---

### Task 2: Extend ReflexBlitzViewModel with Timer Dynamics & Speak Helpers

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `TextToSpeechProtocol`
- Produces:
  - `ReflexBlitzViewModel.fractionRemaining: Double` (1.0 to 0.0)
  - `ReflexBlitzViewModel.timerStage: ReflexBlitzTimerStage` (`.steady`, `.warning`, `.urgent`)
  - `ReflexBlitzViewModel.speakCurrentWord()`
  - `ReflexBlitzViewModel.speakLemma(_ lemma: String)`

- [ ] **Step 1: Write failing unit tests for ViewModel timer fraction and speak helpers**

```swift
// Add to VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
func testTimerFractionRemainingAndStages() {
    let (vm, _, _, _) = makeViewModel()
    vm.beginSessionDirectly()

    vm.simulateElapsedTime(ms: 0)
    XCTAssertEqual(vm.fractionRemaining, 1.0, accuracy: 0.01)
    XCTAssertEqual(vm.timerStage, .steady)

    vm.simulateElapsedTime(ms: 3600)
    XCTAssertEqual(vm.fractionRemaining, 0.40, accuracy: 0.01)
    XCTAssertEqual(vm.timerStage, .warning)

    vm.simulateElapsedTime(ms: 5400)
    XCTAssertEqual(vm.fractionRemaining, 0.10, accuracy: 0.01)
    XCTAssertEqual(vm.timerStage, .urgent)
}

func testSpeakLemmaDelegatesToTTSService() {
    let (vm, _, mockTTS, _) = makeViewModel()
    vm.speakLemma("serendipity")
    XCTAssertTrue(mockTTS.isSpeaking)
    XCTAssertEqual(mockTTS.lastSpokenText, "serendipity")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: FAIL (missing `fractionRemaining`, `timerStage`, and `speakLemma`)

- [ ] **Step 3: Implement ViewModel timer fraction and speak helpers**

In `ReflexBlitzViewModel.swift`:
- Add enum `ReflexBlitzTimerStage: Equatable, Sendable { case steady, warning, urgent }`
- Implement computed property `fractionRemaining`:
  `max(0.0, min(1.0, 1.0 - Double(elapsedTimeMs) / 6000.0))`
- Implement computed property `timerStage`:
  - `< 3500ms`: `.steady`
  - `3500..<5000ms`: `.warning`
  - `>= 5000ms`: `.urgent`
- Implement `speakLemma(_ lemma: String)` using `ttsService.speak(text: lemma, rate: 0.5, locale: "en-US")`
- In `handleSpokenMatch`, pass `pos`, `ipa`, and `definitionVi` to `ReflexBlitzAttempt`.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): add countdown fraction remaining and audio speak helper to ViewModel"
```

---

### Task 3: Redesign ReflexBlitzCardView with Perimeter Stroke, Target Morphing & Integrated Voice Dock

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `fractionRemaining: Double`, `timerStage: ReflexBlitzTimerStage`, `liveTranscript: String`, `isKeyboardActive: Bool`, `onSubmitKeyboard: (String) -> Void`
- Produces: Integrated `ReflexBlitzCardView` combining visual challenge, dynamic perimeter stroke timer, morphing cloze sentence, IPA subtitle, and inline audio wave dock.

- [ ] **Step 1: Write component tests for upgraded ReflexBlitzCardView**

```swift
// Add to VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
func testCardViewRendersWithPerimeterTimerAndIntegratedDock() {
    let word = ReflexBlitzWordItem(
        id: 1,
        lemma: "ephemeral",
        pos: "adj.",
        ipa: "/ɪˈfem.ər.əl/",
        definitionVi: "Phù du, chóng tàn",
        exampleSentenceEn: "Her fame is ephemeral in nature.",
        exampleSentenceVi: "Danh tiếng của cô ấy phù du."
    )
    let card = ReflexBlitzCardView(
        word: word,
        fractionRemaining: 0.8,
        timerStage: .steady,
        showHint: false,
        isCorrect: false,
        isTimeout: false,
        liveTranscript: "Her fame",
        elapsedTimeMs: 1200,
        isKeyboardFallbackActive: false,
        onSubmitKeyboard: { _ in }
    )
    XCTAssertNotNil(card.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: FAIL

- [ ] **Step 3: Implement upgraded ReflexBlitzCardView.swift**

Key elements:
1. Outer border with `RoundedRectangle(cornerRadius: 28).trim(from: 0, to: fractionRemaining)` colored dynamically:
   - Steady: `Color.vocabHeroAccent`
   - Warning: `Color.vocabPeach`
   - Urgent: `Color.vocabCoral`
2. Text area with morphing:
   - Correct: `word.exampleSentenceEn` with `word.lemma` highlighted in `Color.vocabMint` + IPA badge `/ɪˈfem.ər.əl/` below.
   - Timeout: `word.exampleSentenceEn` in `Color.vocabCoral`.
   - Drilling: `word.clozeSentenceEn`.
3. Hint Pill: `💡 Gợi ý: \(word.initialLetterHint) • \(word.ipa)`.
4. Bottom Integrated Voice Waveform & Transcript Dock:
   - Divider hairline.
   - 7 animated waveform capsules + live transcript string right below the sentence.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(reflex): redesign ReflexBlitzCardView with perimeter timer, IPA phonetics, and integrated voice dock"
```

---

### Task 4: Streamline ReflexBlitzView Layout & Eliminate Dead Space

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzViewModel`, `ReflexBlitzHeaderView`, upgraded `ReflexBlitzCardView`, `ReflexBlitzSummaryView`
- Produces: Streamlined `ReflexBlitzView` with centered, single-focus visual composition and keyboard switch button.

- [ ] **Step 1: Write integration tests for streamlined ReflexBlitzView**

Verify `ReflexBlitzView` instantiates and renders drilling phase cleanly without detached bottom visualizers.

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzViewIntegrationTests/testBlitzViewDrillingPhaseRendering`
Expected: FAIL (argument mismatch for updated CardView)

- [ ] **Step 3: Update ReflexBlitzView.swift**

Wire `ReflexBlitzCardView` with `viewModel.fractionRemaining`, `viewModel.timerStage`, `viewModel.liveTranscript`, and keyboard toggle action. Place keyboard toggle pill button directly below the card with comfortable 16pt spacing.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzViewIntegrationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift
git commit -m "feat(reflex): streamline ReflexBlitzView layout and consolidate visual focal point"
```

---

### Task 5: Upgrade ReflexBlitzSummaryView with Rich Weak Word Rows & Audio Speakers

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzSessionSummary`, `onSpeakWord: (String) -> Void`, `onReDrillWeak: () -> Void`, `onFinish: () -> Void`
- Produces: Enhanced `ReflexBlitzSummaryView` with Vietnamese meaning, IPA, and tap-to-listen speaker buttons on weak word rows.

- [ ] **Step 1: Write summary view unit tests for speaker audio button & rich metadata**

```swift
// Add to VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift
func testSummaryViewWithRichWeakWordAndSpeakAction() {
    let attempt = ReflexBlitzAttempt(
        wordId: 1,
        lemma: "ephemeral",
        pos: "adj.",
        ipa: "/ɪˈfem.ər.əl/",
        definitionVi: "Phù du, chóng tàn",
        responseTimeMs: 6000,
        usedHint: true,
        isCorrect: false
    )
    let summary = ReflexBlitzSessionSummary.create(from: [attempt], maxCombo: 0)
    var spokenWord: String?
    let view = ReflexBlitzSummaryView(
        summary: summary,
        onSpeakWord: { spokenWord = $0 },
        onReDrillWeak: {},
        onFinish: {}
    )
    XCTAssertNotNil(view.body)
    XCTAssertNotNil(view.summaryContent)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzSummaryViewTests`
Expected: FAIL

- [ ] **Step 3: Update ReflexBlitzSummaryView.swift**

Add `onSpeakWord: ((String) -> Void)? = nil`. For each weak word:
- Left: Lemma + `pos • ipa` + Vietnamese definition.
- Right: Mini circular speaker button `Image(systemName: "speaker.wave.2.fill")` + time badge.

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzSummaryViewTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift
git commit -m "feat(reflex): add IPA, Vietnamese definitions, and tap-to-speak audio to ReflexBlitzSummaryView"
```

---

### Task 6: Visual Snapshot Automation & Full Regression Verification

**Files:**
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`
- Test: All tests in `VocabCraftAppTests`

- [ ] **Step 1: Update snapshot test to capture new visual designs for all 8 states**
- [ ] **Step 2: Run snapshot test suite on iPhone 17 Simulator**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B' -only-testing:VocabCraftAppTests/ReflexBlitzViewIntegrationTests/testCaptureAllReflexBlitzScreenshots`
Expected: PASS, 8 high-resolution PNG images written to brain screenshots directory.

- [ ] **Step 3: Run full app test suite to ensure 0 regressions**

Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'id=9953AFC9-4A27-442F-A35A-54412DE25E2B'`
Expected: ALL TESTS PASS

- [ ] **Step 4: Update UX/UI Audit Walkthrough artifact with comparison images**
- [ ] **Step 5: Final commit**

```bash
git add .
git commit -m "test(reflex): verify all Reflex Blitz screens with automated snapshot tests"
```
