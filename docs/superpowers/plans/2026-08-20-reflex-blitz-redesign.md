# Reflex Blitz Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign Reflex Blitz into a multi-modality rapid reflex learning experience with 4 distinct modes (Speaking, Typing, Multiple Choice, Listening), pre-session mode selection, paused review consolidation state, and common A1-B2 starter vocabulary.

**Architecture:** Extend `ReflexBlitzModels` with `ReflexBlitzMode`, `ReflexCardPhase`, `ReflexCardResult`, and `ReflexBlitzOption`. Upgrade `ReflexBlitzViewModel` to drive a 2-phase card state machine (`activeCountdown` vs. `reviewed`) with mode-specific timer limits and option generation. Update SwiftUI views with `ReflexBlitzModeSelectionView`, `ReflexBlitzAdvanceDockView`, and upgraded `ReflexBlitzCardView`.

**Tech Stack:** Swift 6 / iOS 17+, SwiftUI, Observation framework, AVFoundation / Speech Framework, XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-20-reflex-blitz-redesign.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-20-reflex-blitz-redesign.md)

## Global Constraints
- Target Module: `VocabCraftApp/Features/ReflexDrill`
- 4 Modes: Speaking (6.0s), Typing (7.5s), Multiple Choice (4.5s), Listening (5.5s).
- Review state halts stopwatch; `responseTimeMs` strictly records active countdown deliberation time.
- Default word count sourced from `UserSettingsStore.dailyGoalCount` or caller.
- Retain existing sound effect, speech recognition, and SRS evaluation protocols.

---

### Task 1: Update Data Models, Enums & Curated Starter Vocabulary

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`

**Interfaces:**
- Produces:
  - `public enum ReflexBlitzMode: String, CaseIterable, Identifiable, Sendable, Codable`
  - `public enum ReflexCardPhase: Equatable, Sendable`
  - `public struct ReflexCardResult: Equatable, Sendable`
  - `public struct ReflexBlitzOption: Identifiable, Equatable, Sendable`
  - `ReflexBlitzWordItem.generateOptions(mode:allPool:) -> [ReflexBlitzOption]`
  - Updated `ReflexBlitzWordItem.defaultStarterWords` (12 A1-B2 words: habit, improve, focus, create, journey, relax, challenge, protect, connect, energy, simple, success).

- [ ] **Step 1: Write the failing tests in `ReflexBlitzModelsTests.swift`**

```swift
func testReflexBlitzModeProperties() {
    XCTAssertEqual(ReflexBlitzMode.multipleChoice.timeLimitSeconds, 4.5)
    XCTAssertEqual(ReflexBlitzMode.listening.timeLimitSeconds, 5.5)
    XCTAssertEqual(ReflexBlitzMode.speaking.timeLimitSeconds, 6.0)
    XCTAssertEqual(ReflexBlitzMode.typing.timeLimitSeconds, 7.5)
}

func testGenerateOptionsForMultipleChoice() {
    let words = ReflexBlitzWordItem.defaultStarterWords
    let target = words[0]
    let options = target.generateOptions(mode: .multipleChoice, allPool: words)
    XCTAssertEqual(options.count, 4)
    XCTAssertEqual(options.filter { $0.isCorrect }.count, 1)
    XCTAssertTrue(options.contains { $0.text == target.lemma && $0.isCorrect })
}

func testGenerateOptionsForListening() {
    let words = ReflexBlitzWordItem.defaultStarterWords
    let target = words[0]
    let options = target.generateOptions(mode: .listening, allPool: words)
    XCTAssertEqual(options.count, 4)
    XCTAssertEqual(options.filter { $0.isCorrect }.count, 1)
    XCTAssertTrue(options.contains { $0.text == target.definitionVi && $0.isCorrect })
}

func testCuratedStarterWordsCount() {
    XCTAssertEqual(ReflexBlitzWordItem.defaultStarterWords.count, 12)
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzModelsTests`
Expected: FAIL due to missing `ReflexBlitzMode`, `generateOptions`, etc.

- [ ] **Step 3: Implement new models and helper methods in `ReflexBlitzModels.swift`**

Add `ReflexBlitzMode`, `ReflexCardPhase`, `ReflexCardResult`, `ReflexBlitzOption`, `generateOptions`, and update `defaultStarterWords`.

- [ ] **Step 4: Run tests to verify pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzModelsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift
git commit -m "feat(reflex): add ReflexBlitzMode, ReflexCardPhase, and curated starter words"
```

---

### Task 2: Refactor ViewModel for 4 Modalities & Review Pause State

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: Models from Task 1.
- Produces:
  - `var selectedMode: ReflexBlitzMode`
  - `var cardPhase: ReflexCardPhase` (`.activeCountdown` vs `.reviewed(result:)`)
  - `var currentOptions: [ReflexBlitzOption]`
  - `func selectMode(_ mode: ReflexBlitzMode)`
  - `func selectOption(_ option: ReflexBlitzOption)`
  - `func submitTypingAnswer(_ text: String)`
  - `func advanceToNextWord()`
  - Accurate `responseTimeMs` recording only during active countdown.

- [ ] **Step 1: Write failing unit tests in `ReflexBlitzViewModelTests.swift`**

```swift
func testModeSelectionStartsCountdown() {
    viewModel.selectMode(.multipleChoice)
    XCTAssertEqual(viewModel.selectedMode, .multipleChoice)
    XCTAssertEqual(viewModel.phase, .countdown)
}

func testMultipleChoiceCorrectOptionTransitionsToReviewed() async throws {
    viewModel.selectMode(.multipleChoice)
    viewModel.beginSessionDirectly()
    guard let correctOption = viewModel.currentOptions.first(where: { $0.isCorrect }) else {
        XCTFail("No correct option found")
        return
    }
    viewModel.selectOption(correctOption)
    if case .reviewed(let result) = viewModel.cardPhase {
        XCTAssertTrue(result.isCorrect)
        XCTAssertFalse(result.isTimeout)
    } else {
        XCTFail("Expected cardPhase to be .reviewed")
    }
}

func testAdvanceToNextWordLoadsNextWord() {
    viewModel.selectMode(.typing)
    viewModel.beginSessionDirectly()
    XCTAssertEqual(viewModel.currentWordIndex, 0)
    viewModel.submitTypingAnswer(viewModel.currentWord!.lemma)
    viewModel.advanceToNextWord()
    XCTAssertEqual(viewModel.currentWordIndex, 1)
    XCTAssertEqual(viewModel.cardPhase, .activeCountdown)
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: FAIL.

- [ ] **Step 3: Implement ViewModel logic in `ReflexBlitzViewModel.swift`**

Implement mode handling, cardPhase transitions, `selectOption`, `submitTypingAnswer`, `advanceToNextWord`, stopwatch pausing, and SRS recording.

- [ ] **Step 4: Run tests to verify pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): refactor ReflexBlitzViewModel for 4 modalities and review state"
```

---

### Task 3: Create Mode Selection View & Advance Dock Components

**Files:**
- Create: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift`
- Create: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzAdvanceDockView.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Produces:
  - `ReflexBlitzModeSelectionView(onSelectMode: (ReflexBlitzMode) -> Void, onDismiss: () -> Void)`
  - `ReflexBlitzAdvanceDockView(isReviewed: Bool, responseTimeMs: Int, isCorrect: Bool, onAdvance: () -> Void)`

- [ ] **Step 1: Write failing component tests in `ReflexBlitzComponentsTests.swift`**

```swift
func testModeSelectionViewRenders4Modes() {
    var selected: ReflexBlitzMode?
    let view = ReflexBlitzModeSelectionView(onSelectMode: { selected = $0 }, onDismiss: {})
    XCTAssertNotNil(view)
}

func testAdvanceDockViewDisplaysFormattedTime() {
    let view = ReflexBlitzAdvanceDockView(isReviewed: true, responseTimeMs: 1400, isCorrect: true, onAdvance: {})
    XCTAssertNotNil(view)
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: FAIL (missing files).

- [ ] **Step 3: Create `ReflexBlitzModeSelectionView.swift` and `ReflexBlitzAdvanceDockView.swift`**

Build the Bento cards for 4 modes and the sticky bottom action dock button `⚡️ 1.4s • Từ tiếp theo ➔`.

- [ ] **Step 4: Run tests to verify pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzAdvanceDockView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(reflex): create ReflexBlitzModeSelectionView and ReflexBlitzAdvanceDockView"
```

---

### Task 4: Upgrade Header & Card Views for 4 Modalities & Review State

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: Models, `ReflexBlitzOption`, `ReflexCardPhase`, `ReflexCardResult`.
- Produces:
  - `ReflexBlitzHeaderView` showing active mode badge.
  - `ReflexBlitzCardView` supporting all 4 modes (Voice, Typing, 4-Option grid, Listening audio) and the complete `.reviewed` transformation.

- [ ] **Step 1: Write failing card component tests**

```swift
func testCardViewInMultipleChoiceModeRendersOptions() {
    let word = ReflexBlitzWordItem.defaultStarterWords[0]
    let options = word.generateOptions(mode: .multipleChoice, allPool: ReflexBlitzWordItem.defaultStarterWords)
    let cardView = ReflexBlitzCardView(
        word: word,
        mode: .multipleChoice,
        cardPhase: .activeCountdown,
        options: options,
        onSelectOption: { _ in }
    )
    XCTAssertNotNil(cardView)
}

func testCardViewInReviewedStateRendersCompletedSentence() {
    let word = ReflexBlitzWordItem.defaultStarterWords[0]
    let cardView = ReflexBlitzCardView(
        word: word,
        mode: .speaking,
        cardPhase: .reviewed(result: ReflexCardResult(isCorrect: true, responseTimeMs: 1200, isTimeout: false, selectedOption: nil, typedText: nil, recognizedSpoken: "habit")),
        options: []
    )
    XCTAssertEqual(cardView.displayedSentence, word.completedSentenceWithTargetWord)
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: FAIL.

- [ ] **Step 3: Update `ReflexBlitzHeaderView.swift` and `ReflexBlitzCardView.swift`**

Implement mode-specific inputs, animated transitions, option buttons, audio waveforms, and the reviewed state reveal.

- [ ] **Step 4: Run tests to verify pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(reflex): update Header and Card views to support 4 modalities and review state"
```

---

### Task 5: Update Main ReflexBlitzView Container & Xcode Project Configuration

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`

**Interfaces:**
- Connects: `ReflexBlitzModeSelectionView` $\rightarrow$ `ReflexCountdownOverlayView` $\rightarrow$ `ReflexBlitzCardView` + `ReflexBlitzAdvanceDockView` $\rightarrow$ `ReflexBlitzSummaryView`.

- [ ] **Step 1: Write integration tests in `ReflexBlitzViewIntegrationTests.swift`**

```swift
func testFullReflexBlitzFlowFromModeSelectionToSummary() {
    let (vm, _, _, _) = makeViewModel()
    XCTAssertEqual(vm.phase, .modeSelection)
    vm.selectMode(.multipleChoice)
    XCTAssertEqual(vm.phase, .countdown)
    vm.beginSessionDirectly()
    XCTAssertEqual(vm.phase, .drilling)
    XCTAssertEqual(vm.cardPhase, .activeCountdown)
}
```

- [ ] **Step 2: Update `ReflexBlitzView.swift` and `AppContainer.swift`**

Wire the complete multi-modal lifecycle and add new Swift files to `project.pbxproj`.

- [ ] **Step 3: Run integration tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzViewIntegrationTests`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp.xcodeproj/project.pbxproj VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift
git commit -m "feat(reflex): integrate full ReflexBlitzView lifecycle and update Xcode project"
```

---

### Task 6: Full Verification & Integration Test Suite

**Files:**
- Test: All Reflex Drill test suites.

- [ ] **Step 1: Run complete Reflex Drill test suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: 100% Tests Pass.

- [ ] **Step 2: Final cleanup and commit**

```bash
git status
git commit -am "chore(reflex): complete verification of Reflex Blitz redesign"
```
