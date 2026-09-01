# Reflex Speaking Mode UI Layout Inconsistency & Keyboard Fallback Removal — Design Specification

## Summary

This design specification addresses GitHub Issue [#9](https://github.com/hoojinguyen/vocab-craft-app/issues/9) by:
1. **Resolving UI/UX Inconsistency and Nested Card Bug in Mixed Practice**: Removing redundant `ReflexCardContainerView` / `ReflexReviewedConsolidationView` wrapping around `ReflexSpeakingModeView` in `MixedReflexDrillView`, ensuring direct rendering with standard horizontal padding matching `ReflexBlitzView`.
2. **Completely Removing Accidental Keyboard Fallback**: Eliminating `isKeyboardFallbackActive`, `toggleKeyboardFallback()`, `onSwitchToKeyboard`, `onSwitchToVoice`, and all keyboard fallback UI/logic across `ReflexSpeakingModeView`, `ReflexTypingModeView`, `ReflexBlitzView`, `ReflexBlitzViewModel`, and `MixedReflexDrillView`.
3. **Standardizing the "Can't Speak Now" Action**: Placing a ghost button inside Zone 2 of `ReflexSpeakingModeView` below the mic hub (`AppStrings.Practice.cantSpeakNowCTA` / `app.practice.drill.cant_speak_now`), wiring it to skip/timeout callbacks without any keyboard switching, and removing duplicate buttons.

---

## 1. Problem Description & Root Cause Analysis

### 1.1 Nested Card Bug in `MixedReflexDrillView`
- **Current State**: `MixedReflexDrillView` routes `.speaking` mode through `containerChallengeCard()`, which wraps the view in `ReflexCardContainerView` (`surfaceCard` background + border + shadow + padding). When reviewed, it completely replaces `ReflexSpeakingModeView` with `ReflexReviewedConsolidationView`.
- **Root Cause**: `ReflexSpeakingModeView` already has a self-contained Dual-Zone architecture:
  - **Zone 1**: `CraftFlipCard` with 3D horizontal flip animation (front: definition + cloze prompt; back: consolidation review).
  - **Zone 2**: `CraftTactileMicHubView` on canvas + `ReflexSpeakingLiveBadge`.
- **Impact**: In Mixed Drill, Speaking mode has a card nested inside another card (nested card bug), breaks the 3D flip card visual consistency, and differs significantly from `ReflexBlitzView`.

### 1.2 Accidental Keyboard Fallback Contamination
- **Current State**: `isKeyboardFallbackActive` state was added to `ReflexBlitzViewModel`, `MixedReflexDrillView`, `ReflexBlitzView`, and `ReflexSpeakingModeView`. Furthermore, when `speechEngine.onError` fires, it automatically sets `isKeyboardFallbackActive = true`.
- **Root Cause**: A legacy fallback mechanism converted speaking exercises into typing exercises.
- **Impact**: Dilutes the purpose of spoken reflex drills (Speak Drill / Blitz), turning speech challenges into typing challenges.

### 1.3 Duplicate / Unstandardized "Can't Speak Now"
- **Current State**: `MixedReflexDrillView` rendered a bottom CTA button for "Không thể nói lúc này" / "Bỏ qua", while `ReflexSpeakingModeView` rendered a "Chuyển sang gõ từ" button inside Zone 2.
- **Impact**: Confusing UX with conflicting action pathways.

---

## 2. Core Architecture & Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| **Speaking Mode Container in Mixed Drill** | Direct rendering with `theme.spacing.base` padding | Eliminates outer `ReflexCardContainerView`, restores 3D flip card & canvas mic hub consistency across all modes. |
| **Keyboard Fallback in Speaking Mode** | **Removed 100%** | Speaking drills remain strictly audio-based. No typing mode toggling. |
| **Speech Engine Error Behavior** | Log and remain in speaking mode | Does not forcefully toggle to keyboard mode. User can use "Không thể nói lúc này" or wait for timeout. |
| **"Không thể nói lúc này" (Can't Speak Now) Placement** | **Inside Zone 2 of `ReflexSpeakingModeView`** (under mic hub & live badge) | Clean, context-aware ghost button with `waveform.slash` icon. Standard across Blitz and Mixed drills. |
| **Mixed Drill Bottom Button Cleanup** | Remove duplicate bottom speaking buttons in `MixedReflexDrillView` | Avoids duplicate buttons on screen. |
| **Typing Mode Mic Icon** | Removed `onSwitchToVoice` | Typing mode in Blitz/Mixed is strictly keyboard-driven. |

---

## 3. Detailed Component Modifications

### 3.1 `ReflexSpeakingModeView.swift`

```
┌───────────────────────────────────────────────────────────┐
│                 ReflexSpeakingModeView                    │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │             Zone 1: CraftFlipCard                   │  │
│  │             (.tactile3D, 180° flip)                 │  │
│  │  Front: Vietnamese definition + cloze prompt       │  │
│  │  Back: Lemma + IPA + Audio replay + Full sentence   │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │             Zone 2: Mic Hub & Actions               │  │
│  │             (on canvas, NO card wrapper)            │  │
│  │                                                     │  │
│  │              CraftTactileMicHubView                 │  │
│  │                                                     │  │
│  │             ReflexSpeakingLiveBadge                 │  │
│  │                                                     │  │
│  │  [if !isReviewed && onCantSpeakNow]                 │  │
│  │  CraftButton("Không thể nói lúc này",              │  │
│  │              icon: "waveform.slash",                │  │
│  │              variant: .ghost, size: .sm)            │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

#### API Interface Changes:
- **Remove**: `public let onSwitchToKeyboard: (() -> Void)?`
- **Add**: `public let onCantSpeakNow: (() -> Void)?`
- **Update Inits**: Replace `onSwitchToKeyboard` parameter with `onCantSpeakNow`.
- **Zone 2 UI Update**:
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

---

### 3.2 `ReflexTypingModeView.swift`

#### API Interface & UI Changes:
- **Remove**: `public let onSwitchToVoice: (() -> Void)?`
- **Remove**: `onSwitchToVoice` from all `init` methods.
- **Update `floatingInputBar`**: Remove `if let onSwitchToVoice` condition, standardizing the prefix element to `Image(systemName: "keyboard")` with `theme.colors.textMuted`.

---

### 3.3 `MixedReflexDrillView.swift`

#### Architecture & View Hierarchy:
1. **Remove State**: `@State private var isKeyboardFallbackActive: Bool = false`.
2. **Remove**: `containerChallengeCard()` and its `ReflexCardContainerView` / `ReflexReviewedConsolidationView` wrapper.
3. **Add `speakingChallengeCard`**:
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
4. **Update `challengeCard(for:)`**:
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
5. **Update Bottom Button Container**:
   Remove the speaking mode button branch from `drillingSessionContent`, retaining only typing mode skip if applicable.

---

### 3.4 `ReflexBlitzView.swift`

#### View Updates:
1. **Update `cardContent(for:)`**:
   ```swift
   } else if viewModel.selectedMode == .speaking {
       speakingCard(for: word)
   }
   ```
2. **Update `speakingCard(for:)`**:
   - Pass `onCantSpeakNow: { viewModel.handleTimeout() }`.
   - Remove `onSwitchToKeyboard`.
3. **Update `typingCard(for:)`**:
   - Remove `onSwitchToVoice` argument.

---

### 3.5 `ReflexBlitzViewModel.swift` & `ReflexBlitzViewModel+Configuration.swift`

#### ViewModel Logic & State Cleanup:
1. **Remove Property**: `public var isKeyboardFallbackActive: Bool = false`.
2. **Update `setupSpeechEngineBindings()`**:
   ```swift
   speechEngine.onError = { error in
       print("[ReflexBlitzViewModel] Speech engine error: \(error.localizedDescription)")
   }
   ```
3. **Remove Methods**:
   - `toggleKeyboardFallback()`
   - `submitKeyboardInput()`
4. **Clean up Lifecycle**:
   Remove all resets of `isKeyboardFallbackActive = false` from:
   - `startDrillSession()`
   - `startCountdown()`
   - `beginSessionDirectly()`
   - `loadWord()`
   - `finishSession()`
   - `cancelSession()`
   - `resetToModeSelection()`

---

### 3.6 Localization & AppStrings Cleanup

1. Inspect `Localizable.xcstrings` and `AppStrings+ReflexBlitz.swift`.
2. Clean up unreferenced string identifiers:
   - `app.reflex.drill.switch_to_keyboard` / `switchToKeyboard` / `switchToKeyboardText`
   - `app.reflex.drill.switch_to_voice` / `switchToVoice` / `switchToVoiceText`
3. Maintain 100% bilingual parity for `app.practice.drill.cant_speak_now` (`"Không thể nói lúc này"` / `"Can't speak now"`).

---

## 4. Verification & Testing Strategy

### 4.1 Unit & Integration Test Updates
- **`ReflexBlitzViewModelSpeakingTests.swift`**:
  - Remove obsolete tests: `testSpeakingMode_speechEngineError_activatesKeyboardFallback`, `testSpeakingMode_advanceWithKeyboardFallback_doesNotCallBeginWord`, `testSpeakingMode_startDrillSession_resetsKeyboardFallback`, `testSpeakingMode_cancelSession_duringKeyboardFallback_doesNotCallBeginWord`, `testSpeakingMode_startDrillSession_duringKeyboardFallback_doesNotCallBeginWordTwice`.
  - Add test validating `speechEngine.onError` does not trigger fallback and keeps engine state intact.
  - Add test validating `handleTimeout` triggered by `onCantSpeakNow`.
- **`ReflexBlitzViewIntegrationTests.swift`**:
  - Replace `testKeyboardFallbackInputToggleAndSubmit` with testing speaking mode view callbacks and "Can't speak now" action.
- **`MixedReflexDrillViewsTests.swift`**:
  - Ensure `testMixedReflexDrillViewSkipSpeakingButtonAction` and all other tests pass without regression.

### 4.2 Quality Gate Checklist
- [ ] `swift test` runs cleanly with 100% pass rate.
- [ ] SwiftLint check completes with 0 errors and 0 warnings.
- [ ] Zero compiler errors and zero compiler warnings.
