# Reflex Blitz Typing Mode Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor and stabilize the Reflex Blitz and Mixed Reflex Typing Mode with zero-jitter multi-stage hinting, external typed word review badge, reliable keyboard auto-focus lifecycle, and full Mixed Reflex drill parity.

**Architecture:** 
Update `ReflexTypingModeView` to present a 3D `CraftFlipCard` with pre-allocated character length slots (`[ _ _ _ _ _ ]`) and multi-stage hint scaffolding (Stage 1: POS fade-in, Stage 2: letter reveal in warning color). Place the user's typed submission outside the card as a dedicated `CraftBadge` below the card (hidden on empty timeout). Fix `MixedReflexDrillView` to remove double container nesting and evaluate incorrect answers properly. Sequence sound effects and TTS audio.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit (`CraftFlipCard`, `CraftBadge`, `CraftButton`, `CraftSpeakerButton`, `CraftFeedbackSheet`, `CraftTheme`), Swift Testing, XCTest.

**Spec:** `docs/superpowers/specs/2026-08-29-reflex-typing-mode-redesign-design.md`

## Global Constraints

- **Theme & Token Discipline**: Zero hardcoded colors, fonts, or padding. 100% `CraftTheme` tokens via `@Environment(\.craftTheme)`.
- **Zero Hardcoded Strings**: All user-facing strings must use `Localizable.xcstrings` and `AppStrings.ReflexBlitz`.
- **Quality Gate**: 0 Swift compiler warnings, 0 SwiftLint warnings, 100% test pass rate.

---

### Task 1: Update ViewModel Hint Stages, Typing Handling & Audio Sequencing

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift:352-370,467-520,582-618`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift:525-546`

**Interfaces:**
- Consumes: `ReflexBlitzMode.typing`, `ReflexClozeStageSet`, `SoundEffectServiceProtocol`, `TextToSpeechProtocol`.
- Produces: `ReflexBlitzViewModel.hintStage` multi-stage timers (2.5s for POS, 4.5s for cloze letters), delayed TTS playback on answer submission/timeout.

- [ ] **Step 1: Write the failing tests for Typing multi-stage hint timing and audio delay**

```swift
// In VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
func testTypingModeMultiStageHintTiming() {
    viewModel.selectMode(.typing)
    viewModel.beginSessionDirectly()
    XCTAssertEqual(viewModel.hintStage, 0)
    XCTAssertFalse(viewModel.showHint)

    // Before Stage 1 (2.5s)
    viewModel.simulateElapsedTime(ms: 2499)
    XCTAssertEqual(viewModel.hintStage, 0)
    XCTAssertFalse(viewModel.showHint)

    // Stage 1 (>= 2.5s): POS Badge
    viewModel.simulateElapsedTime(ms: 2500)
    XCTAssertEqual(viewModel.hintStage, 1)
    XCTAssertTrue(viewModel.showHint)

    // Before Stage 2 (4.5s)
    viewModel.simulateElapsedTime(ms: 4499)
    XCTAssertEqual(viewModel.hintStage, 1)

    // Stage 2 (>= 4.5s): Letter / pattern reveal
    viewModel.simulateElapsedTime(ms: 4500)
    XCTAssertEqual(viewModel.hintStage, 2)
    XCTAssertTrue(viewModel.showHint)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzViewModelTests/testTypingModeMultiStageHintTiming`
Expected: FAIL (hintStage was previously 1 at 4.5s without stage 1 at 2.5s).

- [ ] **Step 3: Update `ReflexBlitzViewModel` hint timers, simulateElapsedTime, and delayed TTS**

In `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`:
1. In `startStopwatch()`:
   - For `.typing`, launch `hintTimerTask` at 2.5s (`hintStage = max(hintStage, 1)`) and `hintStage2Task` at 4.5s (`hintStage = max(hintStage, 2)`).
2. In `simulateElapsedTime(ms:)`:
   - For `.typing`, set `if ms >= 2500 { hintStage = max(hintStage, 1) }` and `if ms >= 4500 { hintStage = max(hintStage, 2) }`.
3. In `submitTypingAnswer(_:)` and `handleTimeout()`:
   - Play chime immediately.
   - Dispatch TTS speech asynchronously after a 250ms task sleep:
     ```swift
     Task { @MainActor [weak self] in
         try? await Task.sleep(for: .milliseconds(250))
         guard let self, self.cardPhase != .activeCountdown else { return }
         self.ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")
     }
     ```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter ReflexBlitzViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
git commit -m "feat: implement typing multi-stage hint timing and audio delay in ReflexBlitzViewModel"
```

---

### Task 2: Redesign `ReflexTypingModeView` with Zero-Jitter Front Face & External Review Badge

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift`

**Interfaces:**
- Consumes: `word: any ReflexDrillable`, `isReviewed: Bool`, `isResultCorrect: Bool`, `isResultTimeout: Bool`, `hintStage: Int`, `clozeStages: ReflexClozeStageSet?`, `typingText: Binding<String>`, `userSubmittedText: String?`.
- Produces: Clean front face (no CEFR, pre-allocated `[ _ _ _ _ _ ]` slot, POS fade-in at Stage >= 1, letter reveal at Stage >= 2), clean back face (no typed text inside), and external typed answer badge rendered below the card when `isReviewed && userSubmittedText != nil && !userSubmittedText.trimmingCharacters().isEmpty`.

- [ ] **Step 1: Write the failing tests for `ReflexTypingModeView`**

```swift
// In VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift
@Test("ReflexTypingModeView front face cloze parts and hint stage slots")
func testTypingModeClozeStages() {
    let item = ReflexBlitzWordItem.defaultStarterWords[0]
    let stageSet = ReflexHintMaskGenerator.generateStages(
        lemma: item.lemma,
        sentenceEn: item.clozeSentenceEn,
        pos: item.cleanPos
    )
    var text = ""
    let binding = Binding(get: { text }, set: { text = $0 })

    // Stage 0: Initial length mask slot
    let stage0View = ReflexTypingModeView(
        word: item,
        hintStage: 0,
        typingText: binding,
        clozeStages: stageSet
    )
    #expect(stage0View.activeClozeParts?.slot == stageSet.initialParts.slot)

    // Stage 1: Length mask slot
    let stage1View = ReflexTypingModeView(
        word: item,
        hintStage: 1,
        typingText: binding,
        clozeStages: stageSet
    )
    #expect(stage1View.activeClozeParts?.slot == stageSet.lengthMaskedParts.slot)

    // Stage 2: Pattern revealed slot
    let stage2View = ReflexTypingModeView(
        word: item,
        hintStage: 2,
        typingText: binding,
        clozeStages: stageSet
    )
    #expect(stage2View.activeClozeParts?.slot == stageSet.patternRevealedParts.slot)
}
```

- [ ] **Step 2: Run test to verify it passes/fails**

Run: `swift test --filter ReflexOtherModesTests`

- [ ] **Step 3: Implement `ReflexTypingModeView` changes**

In `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift`:
1. **Front Face**:
   - `CraftText(word.definitionVi, style: .titleLarge, textAlignment: .center)`
   - POS badge only (no CEFR badge on front):
     ```swift
     HStack(alignment: .center, spacing: theme.spacing.xs) {
         if !word.cleanPos.isEmpty {
             CraftBadge(
                 word.cleanPos,
                 variant: .subtle,
                 tone: .neutral,
                 size: .sm,
                 shape: .capsule
             )
         }
     }
     .opacity(hintStage >= 1 ? 1.0 : 0.0)
     .animation(.easeInOut(duration: 0.2), value: hintStage)
     ```
   - Cloze sentence using `activeClozeParts` with slot color `(hintStage >= 2 ? theme.colors.statusWarning : theme.colors.brandPrimary)`.
2. **Back Face**:
   - Remove Row 3 (`subtitleText` "Bạn đã nhập...").
   - Back face contains: Lemma (Serif) + Speaker button, IPA, POS capsule badge, Vietnamese Definition, and Full example sentence (EN & VI).
3. **External Typed Answer Badge**:
   - Add a computed view `externalTypedBadge`:
     ```swift
     @ViewBuilder
     private var externalTypedBadge: some View {
         if isReviewed,
            let submitted = userSubmittedText?.trimmingCharacters(in: .whitespacesAndNewlines),
            !submitted.isEmpty {
             CraftBadge(
                 isResultCorrect
                     ? AppStrings.ReflexBlitz.typingEnteredPrefix(submitted)
                     : AppStrings.ReflexBlitz.typingYouTypedPrefix(submitted),
                 variant: .subtle,
                 tone: isResultCorrect ? .success : .danger,
                 size: .md,
                 shape: .capsule
             )
             .padding(.top, theme.spacing.sm)
             .transition(.opacity.combined(with: .scale(scale: 0.95)))
         }
     }
     ```
4. **Body Structure & Auto-Focus**:
   ```swift
   public var body: some View {
       VStack(spacing: theme.spacing.md) {
           flipStimulusCard

           if isReviewed {
               externalTypedBadge
           } else {
               floatingInputBar
           }
       }
       .onAppear {
           requestDelayedFocus()
       }
       .onChange(of: isReviewed) { _, reviewed in
           if reviewed {
               isTextFieldFocused = false
           } else {
               requestDelayedFocus()
           }
       }
   }

   private func requestDelayedFocus() {
       Task { @MainActor in
           try? await Task.sleep(for: .milliseconds(80))
           guard !isReviewed else { return }
           isTextFieldFocused = true
       }
   }
   ```

- [ ] **Step 4: Run tests to verify all pass**

Run: `swift test --filter ReflexOtherModesTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexTypingModeView.swift VocabCraftAppTests/Features/Reflex/ReflexOtherModesTests.swift
git commit -m "feat: redesign ReflexTypingModeView with zero-jitter front face and external typed badge"
```

---

### Task 3: Integrate with `ReflexBlitzView` for Word Identity & Keyboard Coordination

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift:266-289`

**Interfaces:**
- Consumes: `ReflexBlitzViewModel`, `ReflexTypingModeView`.
- Produces: View identity binding (`.id(word.id)`), reliable auto-focus across sequential words.

- [ ] **Step 1: Update `typingCard(for:)` in `ReflexBlitzView.swift`**

In `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift`:
Ensure `typingCard` attaches `.id(word.id)` and supplies trimmed `userSubmittedText`:
```swift
@ViewBuilder
private func typingCard(for word: ReflexBlitzWordItem) -> some View {
    ReflexTypingModeView(
        word: word,
        isReviewed: isReviewed,
        isResultCorrect: viewModel.currentAttemptIsCorrect,
        isResultTimeout: isReviewedTimeout,
        showHint: viewModel.showHint,
        hintStage: viewModel.hintStage,
        typingText: $typingInput,
        userSubmittedText: reviewResult?.typedText ?? typingInput,
        clozeStages: viewModel.currentClozeStages,
        clozeParts: ReflexClozeFormatter.extractTemplateParts(from: word.clozeSentenceEn),
        displayedSentence: isReviewed ? word.completedSentenceWithTargetWord : word.clozeSentenceEn,
        hintBadgeText: viewModel.currentHintBadgeText,
        onSubmit: {
            viewModel.submitTypingAnswer(typingInput)
        },
        onReplayAudio: {
            viewModel.speakCurrentWord()
        }
    )
    .id(word.id)
    .padding(.horizontal, theme.spacing.base)
}
```

- [ ] **Step 2: Run test suite to verify integration**

Run: `swift test --filter ReflexBlitzViewIntegrationTests`
Expected: PASS

- [ ] **Step 3: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift
git commit -m "fix: attach word identity to ReflexTypingModeView for seamless focus lifecycle"
```

---

### Task 4: Fix Mixed Reflex Drill (`MixedReflexDrillView`) Incorrect Submission & Container

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift:186-200,253-308,373-393`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`

**Interfaces:**
- Consumes: `MixedReflexDrillItem`, `MixedReflexDrillViewModel`, `ReflexTypingModeView`.
- Produces: Unblocked submission of incorrect answers in typing modality, direct rendering without `ReflexCardContainerView` double nesting, 3D flip card review in Mixed mode.

- [ ] **Step 1: Write the failing tests for `MixedReflexDrillView` typing submissions**

```swift
// In VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift
@Test("Mixed Reflex Drill handles incorrect typing submission without silent drop")
func testMixedReflexIncorrectTypingSubmission() async {
    let mockEvaluator = MockEvaluateSRSUseCase()
    let viewModel = MixedReflexDrillViewModel(
        words: ReflexBlitzWordItem.defaultStarterWords,
        evaluateSRSUseCase: mockEvaluator
    )
    viewModel.startSession()
    // Find or assign typing mode item
    guard let current = viewModel.currentItem else { return }
    #expect(viewModel.attempts.isEmpty)
    await viewModel.submitAnswer(isCorrect: false, responseTimeMs: 1200)
    #expect(viewModel.attempts.count == 1)
    #expect(viewModel.attempts[0].isCorrect == false)
}
```

- [ ] **Step 2: Run test to verify it passes/fails**

Run: `swift test --filter MixedReflexDrillViewsTests`

- [ ] **Step 3: Implement fixes in `MixedReflexDrillView.swift`**

1. In `challengeCard(for:)`:
   Route `.typing` to a dedicated `typingChallengeCard(for:hintStage:isHintActive:)` method (outside `containerChallengeCard`):
   ```swift
   if item.assignedMode == .multipleChoice {
       multipleChoiceChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
   } else if item.assignedMode == .listening {
       listeningChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
   } else if item.assignedMode == .typing {
       typingChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
   } else {
       containerChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
   }
   ```
2. Implement `typingChallengeCard(for:hintStage:isHintActive:)`:
   ```swift
   @ViewBuilder
   private func typingChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
       ReflexTypingModeView(
           word: item,
           isReviewed: isReviewed,
           isResultCorrect: isResultCorrect,
           isResultTimeout: isResultTimeout,
           showHint: isHintActive,
           hintStage: hintStage,
           typingText: $typingText,
           userSubmittedText: reviewedResult?.typedText ?? typingText,
           clozeStages: viewModel.currentClozeStages,
           clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
           displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
           hintBadgeText: viewModel.currentHintBadgeText,
           onSubmit: {
               submitTypingAnswer(typingText)
           },
           onReplayAudio: {
               viewModel.playAudioForCurrentWord()
           }
       )
       .id(item.id)
       .padding(.horizontal, theme.spacing.base)
   }
   ```
3. In `submitTypingAnswer(_:)`:
   Remove `guard isCorrect else { return }`:
   ```swift
   private func submitTypingAnswer(_ text: String) {
       guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
       let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
       guard !cleanText.isEmpty else { return }

       let isCorrect = cleanText.lowercased() == current.word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
       timerTask?.cancel()

       withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
           cardPhase = .reviewed(result: ReflexCardResult(
               isCorrect: isCorrect,
               responseTimeMs: max(500, elapsedTimeMs),
               isTimeout: false,
               typedText: cleanText
           ))
       }

       if isCorrect {
           SoundEffectService.shared.playSuccessChime()
       } else {
           SoundEffectService.shared.playIncorrectChime()
       }

       Task {
           await viewModel.submitAnswer(isCorrect: isCorrect, responseTimeMs: max(500, elapsedTimeMs))
       }
   }
   ```

- [ ] **Step 4: Run tests to verify all pass**

Run: `swift test --filter MixedReflexDrillViewsTests` and `swift test --filter MixedReflexDrillViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift
git commit -m "fix: resolve silent drop of incorrect typing answers and eliminate double card nesting in Mixed Reflex"
```

---

### Task 5: Full Verification, Localization Audit & SwiftLint Compliance

**Files:**
- Test all: `swift test`
- Lint: `swiftlint`

- [ ] **Step 1: Run complete test suite across packages and app**

Run: `swift test`
Expected: 100% tests pass.

- [ ] **Step 2: Run SwiftLint check**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Commit any final test cleanups and verification adjustments**

```bash
git commit -m "test: verify 100% test pass rate and clean lint for typing mode redesign"
```
