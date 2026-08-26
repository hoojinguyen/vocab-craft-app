# CraftStepProgressIndicator & CraftCountdownTimerBar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize and implement `CraftStepProgressIndicator` and `CraftCountdownTimerBar` in `CraftUIKit`, and integrate them into `VocabCraftApp`'s Reflex Blitz feature.

**Architecture:** Add two reusable design system components in `CraftUIKit` adhering to Apple HIG and SwiftUI performance guidelines: discrete interval step progression with monospaced counter, and high-frequency 60/120Hz linear countdown timer bar with dynamic stage transitions and glowing aura. Then refactor `ReflexBlitzHeaderView` to consume these components.

**Tech Stack:** Swift 6, SwiftUI, Swift Package Manager, XCTest / Swift Testing, Xcode String Catalogs (`.xcstrings`), Apple HIG / VoiceOver A11y.

**Spec:** [docs/superpowers/specs/2026-08-26-craft-progress-and-countdown-components-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-26-craft-progress-and-countdown-components-design.md)

## Global Constraints

- Strict No-Hardcode Rule: All text and accessibility strings must use localized keys (`craft.*` in CraftUIKit, `app.*` in VocabCraftApp).
- 100% Bilingual Parity: All keys must have complete `en` and `vi` translations with identical format specifiers (`%lld`).
- Performance: `TimelineView` must pause when inactive, 0 unnecessary state mutations in parent views, zero layout feedback loops.
- Theme Integration: All colors, typography, spacing, and animations must be sourced via `@Environment(\.craftTheme)`.

---

### Task 1: Localization Catalog Setup in CraftUIKit

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Test: `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`

**Interfaces:**
- Consumes: `CraftLocalized` string engine
- Produces: Keys `"craft.step_progress.a11y_value_format"` and `"craft.countdown.time_remaining_label"`

- [ ] **Step 1: Write the failing test for new keys**

Add test assertions in `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift` to verify the presence and translation parity of `craft.step_progress.a11y_value_format` and `craft.countdown.time_remaining_label`.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter LocalizationTests`
Expected: FAIL due to missing keys.

- [ ] **Step 3: Add localized keys to Localizable.xcstrings**

Add the keys to `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:
```json
"craft.step_progress.a11y_value_format": {
  "comment": "Step indicator voiceover value format",
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Step %lld of %lld"
      }
    },
    "vi": {
      "stringUnit": {
        "state": "translated",
        "value": "Bước %lld trên %lld"
      }
    }
  }
},
"craft.countdown.time_remaining_label": {
  "comment": "Countdown timer bar accessibility label",
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Time remaining"
      }
    },
    "vi": {
      "stringUnit": {
        "state": "translated",
        "value": "Thời gian còn lại"
      }
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter LocalizationTests`
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift
git commit -m "feat(craftuikit): add localization keys for step progress and countdown bar"
```

---

### Task 2: Implement `CraftStepProgressIndicator` in CraftUIKit

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepProgressIndicator.swift`
- Create: `CraftUIKit/Tests/CraftUIKitTests/CraftStepProgressIndicatorTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftLocalized`, `CraftColorTokens`
- Produces: `CraftStepStatus`, `CraftStepCounterStyle`, `CraftStepProgressIndicator` View

- [ ] **Step 1: Write the failing unit tests**

Create `CraftUIKit/Tests/CraftUIKitTests/CraftStepProgressIndicatorTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftStepProgressIndicatorTests: XCTestCase {
    func testStepStatusInitialization() {
        let statuses: [CraftStepStatus] = [
            .completed(isCorrect: true),
            .completed(isCorrect: false),
            .active,
            .unreached,
            .custom(.blue)
        ]
        XCTAssertEqual(statuses.count, 5)
    }

    func testIndicatorWithTotalSteps() {
        let indicator = CraftStepProgressIndicator(totalSteps: 10, currentStep: 2)
        XCTAssertEqual(indicator.totalSteps, 10)
        XCTAssertEqual(indicator.currentStep, 2)
    }

    func testIndicatorBoundsHandling() {
        let indicatorZero = CraftStepProgressIndicator(totalSteps: 0, currentStep: -1)
        XCTAssertEqual(indicatorZero.totalSteps, 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftStepProgressIndicatorTests`
Expected: FAIL due to missing `CraftStepProgressIndicator`.

- [ ] **Step 3: Implement CraftStepProgressIndicator**

Create `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepProgressIndicator.swift`:
- Define `CraftStepStatus` enum (`unreached`, `active`, `completed(isCorrect: Bool)`, `custom(Color)`).
- Define `CraftStepCounterStyle` enum (`ratio`, `phrase`, `hidden`).
- Build `CraftStepProgressIndicator: View`:
  - Render `HStack(spacing: spacing)` of `Capsule()` views.
  - Compute colors dynamically from `CraftTheme.colors`.
  - Render monospaced caption text below if `showCounter` is enabled.
  - Add VoiceOver accessibility element with `craft.progress.label` and `craft.step_progress.a11y_value_format`.
  - Handle `reduceMotion` environment.
  - Include SwiftUI Preview.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftStepProgressIndicatorTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepProgressIndicator.swift CraftUIKit/Tests/CraftUIKitTests/CraftStepProgressIndicatorTests.swift
git commit -m "feat(craftuikit): implement CraftStepProgressIndicator component"
```

---

### Task 3: Implement `CraftCountdownTimerBar` in CraftUIKit

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCountdownTimerBar.swift`
- Create: `CraftUIKit/Tests/CraftUIKitTests/CraftCountdownTimerBarTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftLocalized`, `CraftColorTokens`
- Produces: `CraftCountdownStage`, `CraftCountdownColorConfig`, `CraftCountdownTimerBar` View

- [ ] **Step 1: Write the failing unit tests**

Create `CraftUIKit/Tests/CraftUIKitTests/CraftCountdownTimerBarTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftCountdownTimerBarTests: XCTestCase {
    func testStageDerivation() {
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.8), .steady)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.3), .warning)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.1), .urgent)
        XCTAssertEqual(CraftCountdownTimerBar.deriveStage(for: 0.0), .urgent)
    }

    func testColorConfigDefaults() {
        let config = CraftCountdownColorConfig()
        XCTAssertTrue(config.showGlow)
        XCTAssertNil(config.steady)
    }

    func testProgressClamping() {
        let bar = CraftCountdownTimerBar(progress: 1.5)
        XCTAssertEqual(bar.clampedProgress, 1.0)

        let negativeBar = CraftCountdownTimerBar(progress: -0.2)
        XCTAssertEqual(negativeBar.clampedProgress, 0.0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftCountdownTimerBarTests`
Expected: FAIL due to missing `CraftCountdownTimerBar`.

- [ ] **Step 3: Implement CraftCountdownTimerBar**

Create `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCountdownTimerBar.swift`:
- Define `CraftCountdownStage` enum (`steady`, `warning`, `urgent`).
- Define `CraftCountdownColorConfig` struct.
- Build `CraftCountdownTimerBar: View`:
  - Support Initializer 1: Time-Driven (`startDate`, `timeLimit`, `isActive`, `onTimeout`).
  - Support Initializer 2: Fraction-Driven (`progress`, `stage`).
  - Use `TimelineView(.animation(paused: !isActive))` for time-driven mode.
  - Dynamic color interpolation & glow effect `.shadow(...)`.
  - Accessible label & value with `craft.countdown.time_remaining_label`.
  - Reduce motion adaptation.
  - Include SwiftUI Preview.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftCountdownTimerBarTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCountdownTimerBar.swift CraftUIKit/Tests/CraftUIKitTests/CraftCountdownTimerBarTests.swift
git commit -m "feat(craftuikit): implement CraftCountdownTimerBar component"
```

---

### Task 4: Integrate Components into `ReflexBlitzHeaderView` in VocabCraftApp

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`
- Import: `CraftUIKit`

**Interfaces:**
- Consumes: `CraftStepProgressIndicator`, `CraftStepStatus`, `CraftCountdownTimerBar`, `CraftCountdownColorConfig`
- Produces: Clean refactored `ReflexBlitzHeaderView` adhering to design system.

- [ ] **Step 1: Update ReflexBlitzHeaderView to consume CraftUIKit components**

In `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`:
- Ensure `import CraftUIKit` is present.
- Replace center segmented progress bar & step counter with `CraftStepProgressIndicator`:
```swift
CraftStepProgressIndicator(
    steps: (0..<totalCount).map { index in
        if index < attempts.count {
            return .completed(isCorrect: attempts[index].isCorrect)
        } else if index == currentIndex {
            return .active
        } else {
            return .unreached
        }
    },
    currentStep: currentIndex,
    height: 4,
    spacing: 4,
    showCounter: true,
    counterStyle: .ratio
)
.frame(maxWidth: 160)
```
- Replace bottom countdown bar with `CraftCountdownTimerBar`:
```swift
CraftCountdownTimerBar(
    startDate: wordStartTime,
    timeLimit: timeLimitSeconds,
    isActive: isTimerActive,
    height: 4.5,
    colorConfig: CraftCountdownColorConfig(
        steady: .vocabHeroAccent,
        warning: .vocabPeach,
        urgent: .vocabCoral,
        track: Color.vocabHairline.opacity(0.3),
        showGlow: true
    )
)
```

- [ ] **Step 2: Build and verify compilation of VocabCraftApp**

Build `VocabCraftApp` target to ensure zero compilation errors and clean integration.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift
git commit -m "refactor(reflex): integrate CraftStepProgressIndicator and CraftCountdownTimerBar in ReflexBlitzHeaderView"
```

---

### Task 5: Full Test Suite & Verification

**Files:**
- Test all components across `CraftUIKit` and `VocabCraftApp`.

- [ ] **Step 1: Run CraftUIKit tests**

Run: `swift test --package-path CraftUIKit`
Expected: 100% tests passing.

- [ ] **Step 2: Run Localization Tests**

Run: `swift test --package-path CraftUIKit --filter LocalizationTests`
Expected: 100% parity verified.

- [ ] **Step 3: Build VocabCraftApp in Simulator**

Use `build_sim` or `xcodebuild` on simulator to verify clean build.

- [ ] **Step 4: Final commit and cleanup**

```bash
git status
```
