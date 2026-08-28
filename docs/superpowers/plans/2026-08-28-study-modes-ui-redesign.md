# Study Modes UI & Interaction Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the countdown stage, review consolidation card, and bottom feedback dock across study modes (Reflex Blitz & Mixed Reflex Drill) to eliminate countdown question bleed-through, deliver Apple-grade grand typography and motion, dock feedback full-width, and eliminate 100% of duplicate dictionary content.

**Architecture:** 
- `CraftUIKit`: Refactor `CraftCountdownOverlay` to support opaque canvas backdrops with radial ambient glow, hero SF Symbols, bold directive titles, 92pt SF Pro Rounded countdown typography, and tap-to-skip gestures. Refactor `CraftFeedbackSheet` to support true edge-to-edge full-width docking (`maxWidth: .infinity`, `ignoresSafeArea(edges: .bottom)`).
- `VocabCraftApp`: Isolate the `.countdown` phase from `.drilling` in `ReflexBlitzView` and `MixedReflexDrillView` (zero question bleed-through). Establish strict separation of concerns where `ReflexBlitzCardView` owns all vocabulary and in-place reveal details, while `CraftFeedbackSheet` serves as an ultra-compact, non-duplicative status & thumb-zone CTA dock.
- Localization & Token Compliance: 100% theme token utilization, zero raw styling, 100% bilingual parity in `Localizable.xcstrings` (both `craft.*` and `app.reflex.*` domains).

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit Design System, SF Pro Rounded, CoreHaptics / UIFeedbackGenerator.

**Spec:** `docs/superpowers/specs/2026-08-28-study-modes-ui-redesign.md`

## Global Constraints
- Strictly utilize `CraftUIKit` design tokens (`theme.colors.*`, `theme.typography.*`, `theme.spacing.*`, `theme.radii.*`, `theme.shadows.*`, `theme.depths.*`). No hardcoded colors, fonts, or margins.
- Zero hardcoded strings: all text must use `CraftLocalized` (`craft.*`) or `LocalizedStringKey` (`app.reflex.*`) with 100% EN/VI translations.
- Zero compiler warnings and zero SwiftLint violations.

---

### Task 1: Enhance `CraftCountdownOverlay` in `CraftUIKit`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Countdown/CraftCountdownOverlay.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftCountdownTimerBarTests.swift` (and new `CraftCountdownOverlayTests.swift`)
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftColorTokens`, `CraftTypographyTokens`, `CraftLocalized`.
- Produces: `CraftCountdownOverlay(startNumber:title:subtitle:iconName:tintColor:goText:onFinish:)` with tap-to-skip, 100% opaque canvas backdrop, ambient radial glow, 92pt countdown typography, and spring bounce animation.

- [ ] **Step 1: Write unit tests for enhanced `CraftCountdownOverlay`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftCountdownOverlayTests.swift`:
```swift
import Foundation
@testable import CraftUIKit
import SwiftUI
import Testing

@Suite("CraftCountdownOverlay Tests")
struct CraftCountdownOverlayTests {
    @Test("Countdown overlay initializes with default parameters")
    func testCountdownInitDefaults() {
        let overlay = CraftCountdownOverlay(startNumber: 3, title: "Speed Drill") {}
        #expect(overlay.startNumber == 3)
        #expect(overlay.title == "Speed Drill")
    }

    @Test("Countdown overlay clamps minimum start number to 1")
    func testCountdownClampsStartNumber() {
        let overlay = CraftCountdownOverlay(startNumber: 0) {}
        #expect(overlay.startNumber == 1)
    }
}
```

- [ ] **Step 2: Run CraftUIKit tests to verify baseline**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftCountdownOverlayTests`
Expected: PASS

- [ ] **Step 3: Implement enhanced `CraftCountdownOverlay`**

Update `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/Countdown/CraftCountdownOverlay.swift`:
- Ensure the background is 100% opaque:
  ```swift
  theme.colors.canvasBackground
      .ignoresSafeArea()
  ```
- Add ambient radial glow with `RadialGradient` centered behind the countdown number using the modal tint color.
- Display `iconName` (if provided) using 48pt hierarchical SF Symbol with `.symbolEffect(.pulse, options: .repeating)`.
- Display `title` (`theme.typography.titleLarge.bold()`) and optional `subtitle` (`theme.typography.bodyMedium`).
- Grand countdown number:
  ```swift
  Text(isShowingGo ? goText : "\(currentCount)")
      .font(.system(size: 92, weight: .heavy, design: .rounded))
      .foregroundStyle(
          LinearGradient(
              colors: isShowingGo ? [theme.colors.statusSuccess, theme.colors.statusSuccess.opacity(0.85)] : [theme.colors.brandPrimary, theme.colors.accent],
              startPoint: .top,
              endPoint: .bottom
          )
      )
      .scaleEffect(reduceMotion ? 1.0 : scale)
      .opacity(opacity)
  ```
- Add `.contentShape(Rectangle())` and `.onTapGesture { skipCountdown() }` to allow tap-to-skip.

- [ ] **Step 4: Run CraftUIKit tests to ensure all tests pass**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% PASS

- [ ] **Step 5: Commit changes**

```bash
git add Packages/CraftUIKit/
git commit -m "feat(CraftUIKit): enhance CraftCountdownOverlay with Apple-grade typography and ambient glow"
```

---

### Task 2: Refactor `CraftFeedbackSheet` for Full-Width Edge-to-Edge Docking

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftSurfaceStyle`, `CraftFeedbackStatus`.
- Produces: `CraftFeedbackSheet` with edge-to-edge docking geometry (`maxWidth: .infinity`), top corner radius (24pt), top highlight stroke, and responsive tactile CTA button.

- [ ] **Step 1: Write test for `CraftFeedbackSheet` edge-to-edge layout styling**

Add tests in `Packages/CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`:
```swift
@Test("CraftFeedbackSheet renders valid status titles and action titles")
func testFeedbackSheetTitles() {
    let sheet = CraftFeedbackSheet(
        status: .success,
        title: "Chính xác!",
        actionTitle: "Tiếp tục",
        onContinue: {}
    )
    #expect(sheet.resolvedTitle == "Chính xác!")
    #expect(sheet.resolvedActionTitle == "Tiếp tục")
}
```

- [ ] **Step 2: Update `CraftFeedbackSheet` layout body and shape**

Update `CraftFeedbackSheet.swift`:
- Ensure `UnevenRoundedRectangle(topLeadingRadius: theme.radii.xl, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: theme.radii.xl)` is used for the sheet shape.
- Ensure the sheet container has `.frame(maxWidth: .infinity, alignment: .leading)` and inner horizontal padding for content while the background stretches to screen edges.
- Ensure `CraftFeedbackSheetModifier` applies `.ignoresSafeArea(edges: .bottom)`.

- [ ] **Step 3: Run CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit --filter FeedbackComponentTests`
Expected: PASS

- [ ] **Step 4: Commit changes**

```bash
git add Packages/CraftUIKit/
git commit -m "feat(CraftUIKit): refactor CraftFeedbackSheet for full-width edge-to-edge docking"
```

---

### Task 3: Redesign `ReflexBlitzView` Stage Transitions & Bottom Dock

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzViewModel`, `CraftCountdownOverlay`, `CraftFeedbackSheet`, `ReflexBlitzCardView`.
- Produces: Clean phase-isolated view where countdown completely hides drill content, and reviewed state features zero text duplication.

- [ ] **Step 1: Update `ReflexBlitzView.swift` phase branching**

In `ReflexBlitzView.swift`:
- Separate `.countdown` phase completely from `.drilling`:
  ```swift
  switch viewModel.phase {
  case .modeSelection:
      ...
  case .countdown:
      CraftCountdownOverlay(
          startNumber: 3,
          title: viewModel.selectedMode.title,
          subtitle: viewModel.selectedMode.instructionPrompt,
          iconName: viewModel.selectedMode.iconName,
          tintColor: theme.colors.brandPrimary,
          onFinish: {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                  viewModel.beginSessionDirectly()
              }
          }
      )
      .transition(.opacity)
  case .drilling, .timeoutRevealing:
      drillingView
  case .summary:
      ...
  }
  ```

- [ ] **Step 2: Update `ReflexBlitzView.bottomDockArea` to remove duplicate extra content**

In `ReflexBlitzView.swift`:
- Remove `feedbackExtraContent` from `CraftFeedbackSheet` invocation.
- Present `CraftFeedbackSheet` edge-to-edge without outer horizontal padding:
  ```swift
  case .reviewed(let result):
      CraftFeedbackSheet(
          status: result.isCorrect ? .success : (result.isTimeout ? .warning : .error),
          title: result.isCorrect ? AppStrings.ReflexBlitz.correctTitleText : (result.isTimeout ? AppStrings.ReflexBlitz.timeoutTitleText : AppStrings.ReflexBlitz.incorrectTitleText),
          actionTitle: AppStrings.ReflexBlitz.continueCTAText,
          style: .tactile3D,
          onContinue: {
              typingInput = ""
              viewModel.advanceToNextWord()
          }
      )
      .ignoresSafeArea(edges: .bottom)
      .transition(.move(edge: .bottom).combined(with: .opacity))
  ```

- [ ] **Step 3: Ensure `ReflexBlitzCardReviewedView` retains full vocabulary context**

Verify `ReflexBlitzCardReviewedView.swift` contains the complete review card (lemma, POS badge, audio pronounce button, IPA, definition, in-place cloze reveal with highlighted word, Vietnamese sentence translation, and user's typed/spoken attempt chip).

- [ ] **Step 4: Update `ReflexBlitzMode` metadata for titles, instructions, and icons**

Ensure `ReflexBlitzMode` has localized title, instruction prompt, and SF Symbol icon names.

- [ ] **Step 5: Run Reflex Blitz test suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/ReflexBlitzViewModelTests` (or via XcodeBuildMCP / swift test).

- [ ] **Step 6: Commit changes**

```bash
git add VocabCraftApp/Features/ReflexDrill/
git commit -m "feat(ReflexDrill): isolate countdown stage and streamline full-width feedback dock"
```

---

### Task 4: Align `MixedReflexDrillView` with Unified Study Mode UI

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/MixedReflexDrillView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/Components/MixedDrillSectionViews.swift`

**Interfaces:**
- Consumes: `MixedReflexDrillViewModel`, `CraftCountdownOverlay`, `CraftFeedbackSheet`.
- Produces: Consistent full-width feedback and clean in-place reveal for mixed reflex study sessions.

- [ ] **Step 1: Update `MixedReflexDrillView.swift` review docking**

Update `ReflexBlitzAdvanceDockView` / review presentation in `MixedReflexDrillView.swift` to use the unified edge-to-edge `CraftFeedbackSheet` when `cardPhase` is `.reviewed`.

- [ ] **Step 2: Commit changes**

```bash
git add VocabCraftApp/Features/Vocabulary/
git commit -m "feat(Vocabulary): align MixedReflexDrillView with unified edge-to-edge feedback dock"
```

---

### Task 5: 100% Localization & Quality Gate Verification

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift`

- [ ] **Step 1: Check and update all localization keys (EN & VI)**

Ensure all strings (`craft.countdown.*`, `craft.feedback.*`, `app.reflex.*`) have 100% matching translations in both English and Vietnamese, with exact format specifiers and `state: "translated"`.

- [ ] **Step 2: Run Localization Tests**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: 100% PASS

- [ ] **Step 3: Run SwiftLint**

Run: `swiftlint lint --strict`
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Build and test full project**

Verify 0 compiler warnings and 100% test pass rate.

- [ ] **Step 5: Commit changes**

```bash
git add .
git commit -m "chore: complete study modes UI redesign with 100% bilingual localization and zero warnings"
```
