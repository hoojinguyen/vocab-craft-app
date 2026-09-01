# Reflex Speaking Mode UI Layout & Fallback Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve Speaking mode UI layout inconsistency (eliminate nested cards in Mixed Drill), completely remove accidental keyboard fallback across the app, and standardize "Can't speak now" action in Zone 2 of `ReflexSpeakingModeView`.

**Architecture:** Render `ReflexSpeakingModeView` directly in `MixedReflexDrillView` using its native Dual-Zone 3D Flip Card architecture (`CraftFlipCard` + `CraftTactileMicHubView`) with standard horizontal padding, wire a ghost button in Zone 2 for "Can't speak now" (`AppStrings.Practice.cantSpeakNowCTA`), and purge all `isKeyboardFallbackActive` state, methods, and UI toggles across ViewModels and Views.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit design tokens, Observation framework, XCTest & Swift Testing.

**Spec:** [`docs/superpowers/specs/2026-09-01-reflex-speaking-mode-ui-layout-and-fallback-cleanup-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-01-reflex-speaking-mode-ui-layout-and-fallback-cleanup-design.md)

## Global Constraints

- **Strict No-Hardcode Rule**: Zero hardcoded strings. All copy comes from `Localizable.xcstrings` via `AppStrings`.
- **CraftUIKit-First**: Zero raw styling or ad-hoc colors. Use `theme.spacing`, `theme.colors`, `theme.radii`, `theme.typography`.
- **Zero Compiler Warnings**: Build must be 100% clean with 0 errors and 0 warnings.
- **Strict Quality Gate**: All tests must pass via `swift test`. SwiftLint must pass.

---

### Task 1: Refactor `ReflexSpeakingModeView` & `ReflexTypingModeView` APIs

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift:20-90, 260-295`
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift:20-90, 380-400`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexContainerComponentsTests.swift`

**Interfaces:**
- Consumes: `AppStrings.Practice.cantSpeakNowCTA` (`"Không thể nói lúc này"` / `"Can't speak now"`), `CraftButton`, `CraftTactileMicHubView`.
- Produces: `ReflexSpeakingModeView` accepting `onCantSpeakNow: (() -> Void)?`, removing `onSwitchToKeyboard`; `ReflexTypingModeView` removing `onSwitchToVoice`.

- [ ] **Step 1: Update `ReflexSpeakingModeView.swift`**
  - Replace property `public let onSwitchToKeyboard: (() -> Void)?` with `public let onCantSpeakNow: (() -> Void)?`.
  - Update both `init` initializers to accept `onCantSpeakNow: (() -> Void)? = nil` instead of `onSwitchToKeyboard`.
  - In `micHubArea`, replace the `onSwitchToKeyboard` button with:
    ```swift
    if !isReviewed, let onCantSpeakNow {
        CraftButton(
            AppStrings.Practice.cantSpeakNowCTA,
            iconName: "waveform.slash",
            variant: .ghost,
            size: .sm,
            action: onCantSpeakNow
        )
    }
    ```

- [ ] **Step 2: Update `ReflexTypingModeView.swift`**
  - Remove property `public let onSwitchToVoice: (() -> Void)?`.
  - Remove `onSwitchToVoice` parameter from all `init` initializers.
  - In `floatingInputBar`, remove the `if let onSwitchToVoice` conditional block and unconditionally render the keyboard icon:
    ```swift
    Image(systemName: "keyboard")
        .foregroundColor(theme.colors.textMuted)
        .font(theme.typography.bodyMedium)
    ```

- [ ] **Step 3: Verify component builds and tests pass**
  Run: `swift test --filter ReflexContainerComponentsTests`
  Expected: PASS

- [ ] **Step 4: Commit component changes**
  ```bash
  git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift
  git commit -m "refactor(reflex): standardize ReflexSpeakingModeView and ReflexTypingModeView APIs"
  ```

---

### Task 2: Purge Keyboard Fallback from `ReflexBlitzViewModel`

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift:30-40, 150-160, 175-245, 290-300, 580-585`
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel+Configuration.swift:80-120`
- Modify: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift:155-220`

**Interfaces:**
- Consumes: `ReflexSpeechEngineProtocol`, `ReflexBlitzAttempt`, `EvaluateSRSUseCaseProtocol`.
- Produces: Cleaned `ReflexBlitzViewModel` without `isKeyboardFallbackActive`, `toggleKeyboardFallback()`, or `submitKeyboardInput()`.

- [ ] **Step 1: Update `ReflexBlitzViewModel.swift`**
  - Remove `public var isKeyboardFallbackActive: Bool = false` and its `didSet`.
  - In `setupSpeechEngineBindings()`, update `speechEngine.onError` to:
    ```swift
    speechEngine.onError = { [weak self] error in
        print("[ReflexBlitzViewModel] Speech engine error: \(error.localizedDescription)")
    }
    ```
  - In `startDrillSession()`, `startCountdown()`, `beginSessionDirectly()`: Remove `self.isKeyboardFallbackActive = false`.
  - In `loadWord()`: Remove `!isKeyboardFallbackActive` condition on `speechEngine.beginWord(...)`.
  - Remove `submitKeyboardInput()` method.

- [ ] **Step 2: Update `ReflexBlitzViewModel+Configuration.swift`**
  - Remove `toggleKeyboardFallback()` method.
  - In `finishSession()`, `cancelSession()`, `resetToModeSelection()`: Remove `isKeyboardFallbackActive = false`.

- [ ] **Step 3: Update `ReflexBlitzViewModelSpeakingTests.swift`**
  - Remove obsolete tests: `testSpeakingMode_speechEngineError_activatesKeyboardFallback`, `testSpeakingMode_advanceWithKeyboardFallback_doesNotCallBeginWord`, `testSpeakingMode_startDrillSession_resetsKeyboardFallback`, `testSpeakingMode_cancelSession_duringKeyboardFallback_doesNotCallBeginWord`, `testSpeakingMode_startDrillSession_duringKeyboardFallback_doesNotCallBeginWordTwice`.
  - Add test verifying error does not crash or toggle mode:
    ```swift
    func testSpeakingMode_speechEngineError_doesNotTriggerKeyboardFallback() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        let testError = NSError(domain: "test", code: 403, userInfo: nil)
        mockSpeechEngine.simulateError(testError)
        XCTAssertEqual(viewModel.selectedMode, .speaking)
        XCTAssertEqual(viewModel.cardPhase, .activeCountdown)
    }
    ```

- [ ] **Step 4: Run tests to verify ViewModel behavior**
  Run: `swift test --filter ReflexBlitzViewModelSpeakingTests`
  Expected: PASS

- [ ] **Step 5: Commit ViewModel changes**
  ```bash
  git add VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel+Configuration.swift VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift
  git commit -m "refactor(reflex): remove keyboard fallback state and methods from ReflexBlitzViewModel"
  ```

---

### Task 3: Update `ReflexBlitzView` & Integration Tests

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift:215-305`
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift:1-30, 500-530`

**Interfaces:**
- Consumes: `ReflexBlitzViewModel`, `ReflexSpeakingModeView`, `ReflexTypingModeView`.
- Produces: `ReflexBlitzView` wired with `onCantSpeakNow: { viewModel.handleTimeout() }`.

- [ ] **Step 1: Update `ReflexBlitzView.swift`**
  - In `cardContent(for:)`, simplify `.speaking` branch:
    ```swift
    } else if viewModel.selectedMode == .speaking {
        speakingCard(for: word)
    }
    ```
  - In `speakingCard(for:)`:
    - Replace `onSwitchToKeyboard: { viewModel.toggleKeyboardFallback() }` with `onCantSpeakNow: { viewModel.handleTimeout() }`.
  - In `typingCard(for:)`:
    - Remove `onSwitchToVoice` parameter.

- [ ] **Step 2: Update `ReflexBlitzViewIntegrationTests.swift`**
  - Replace `testKeyboardFallbackInputToggleAndSubmit` with `testSpeakingModeCantSpeakNowTriggersTimeout`:
    ```swift
    func testSpeakingModeCantSpeakNowTriggersTimeout() {
        let (vm, _, _, _, mockSpeechEngine) = makeViewModel()
        vm.selectMode(.speaking)
        vm.beginSessionDirectly()

        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.drillingView)

        vm.handleTimeout()
        if case .reviewed(let result) = vm.cardPhase {
            XCTAssertTrue(result.isTimeout)
            XCTAssertFalse(result.isCorrect)
        } else {
            XCTFail("Expected cardPhase to be .reviewed")
        }
        XCTAssertEqual(mockSpeechEngine.endWordCallCount, 1)
    }
    ```

- [ ] **Step 3: Run integration tests**
  Run: `swift test --filter ReflexBlitzViewIntegrationTests`
  Expected: PASS

- [ ] **Step 4: Commit Blitz view changes**
  ```bash
  git add VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift
  git commit -m "refactor(reflex): update ReflexBlitzView speaking card and integration tests"
  ```

---

### Task 4: Fix `MixedReflexDrillView` Layout & Eliminate Nested Cards

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift:20-40, 160-205, 230-245, 320-362, 370-375`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`

**Interfaces:**
- Consumes: `MixedReflexDrillViewModel`, `ReflexSpeakingModeView`, `ContinuousReflexSpeechProtocol`.
- Produces: Direct `ReflexSpeakingModeView` rendering with `theme.spacing.base` padding without nested `ReflexCardContainerView`.

- [ ] **Step 1: Update `MixedReflexDrillView.swift`**
  - Remove `@State private var isKeyboardFallbackActive: Bool = false`.
  - In `startDrillItem()`: Remove `isKeyboardFallbackActive = false`.
  - Remove `containerChallengeCard()`.
  - Add `speakingChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool)`:
    ```swift
    @ViewBuilder
    func speakingChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexSpeakingModeView(
            word: item,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
            hintBadgeText: viewModel.currentHintBadgeText,
            speechState: cardPhase == .activeCountdown ? .listening() : .evaluated(overallScore: isResultCorrect ? 100 : 0),
            liveTranscript: liveTranscript,
            onCantSpeakNow: {
                timerTask?.cancel()
                if viewModel.allowSpeakingSkip {
                    viewModel.skipSpeakingCurrentWord()
                    if let next = viewModel.currentItem {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            startDrillItem(next)
                        }
                    }
                } else {
                    handleTimeout()
                }
            },
            onReplayAudio: {
                viewModel.playAudioForCurrentWord()
            }
        )
        .padding(.horizontal, theme.spacing.base)
    }
    ```
  - In `challengeCard(for item: MixedReflexDrillItem)`:
    ```swift
    switch item.assignedMode {
    case .multipleChoice:
        multipleChoiceChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
    case .listening:
        listeningChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
    case .typing:
        typingChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
    case .speaking:
        speakingChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
    }
    ```
  - In `drillingSessionContent`:
    Update the bottom skip button area to only render for `.typing` mode (since Speaking mode has its "Không thể nói lúc này" button in Zone 2):
    ```swift
    // Skip Button for Typing
    if cardPhase == .activeCountdown && currentItem.assignedMode == .typing {
        CraftButton(
            AppStrings.ReflexBlitz.skip,
            iconName: "forward.fill",
            variant: .outline,
            size: .md,
            isFullWidth: true,
            style: .outlined,
            action: {
                handleTimeout()
            }
        )
        .padding(.horizontal, theme.spacing.lg)
        .padding(.bottom, theme.spacing.lg)
        .transition(.opacity)
    }
    ```

- [ ] **Step 2: Run Mixed Reflex Drill tests**
  Run: `swift test --filter MixedReflexDrillViewsTests`
  Expected: PASS

- [ ] **Step 3: Commit Mixed Drill layout fixes**
  ```bash
  git add VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift
  git commit -m "fix(reflex): resolve speaking mode nested card and eliminate duplicate action buttons in MixedReflexDrillView"
  ```

---

### Task 5: Clean Up Localization Strings & Run Verification Suite

**Files:**
- Modify: `VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift:120-135`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: All tests across the test suite.

**Interfaces:**
- Consumes: `AppStrings`, `Localizable.xcstrings`.
- Produces: Cleaned localization catalogue with zero obsolete keys.

- [ ] **Step 1: Clean up unused string keys**
  - In `AppStrings+ReflexBlitz.swift`, remove:
    - `switchToKeyboard` / `switchToKeyboardText`
    - `switchToVoice` / `switchToVoiceText`
  - In `Localizable.xcstrings`, remove keys:
    - `app.reflex.drill.switch_to_keyboard`
    - `app.reflex.drill.switch_to_voice`

- [ ] **Step 2: Run localization test suite**
  Run: `swift test --filter LocalizationTests`
  Expected: PASS

- [ ] **Step 3: Run full application test suite**
  Run: `swift test`
  Expected: 100% tests PASS

- [ ] **Step 4: Run SwiftLint**
  Run: `swiftlint`
  Expected: 0 errors, 0 warnings

- [ ] **Step 5: Commit localization cleanup**
  ```bash
  git add VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift VocabCraftApp/Resources/Localizable.xcstrings
  git commit -m "chore(localization): remove obsolete keyboard/voice fallback string keys"
  ```
