# CraftFeedbackSheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and integrate `CraftFeedbackSheet`, an assessment feedback dock component in `CraftUIKit` supporting semantic validation states (`.success`, `.error`, `.warning`, `.info`), full `CraftSurfaceStyle` compatibility, tactile action buttons, customizable accessory slots, and sensory haptic feedback.

**Architecture:** A lightweight docked overlay component adhering to SRP, decoupling assessment feedback from generic modal sheets (`CraftBottomSheet`). Utilizes `CraftTheme` color tokens for dynamic light/dark semantic tinting, integrates `CraftButton` tactile press mechanics, and offers a flexible `@ViewBuilder` extension slot.

**Tech Stack:** Swift 5.9+, SwiftUI, XCTest, CraftUIKit Design Tokens.

**Spec:** `docs/superpowers/specs/2026-08-26-craft-feedback-sheet-design.md`

## Global Constraints

- Target platforms: iOS 17.0+, macOS 14.0+.
- No third-party dependencies outside standard SwiftUI/Foundation/UIKit.
- Must fully integrate with `CraftTheme`, `CraftColorTokens`, `CraftSurfaceStyle`, and `CraftButton`.
- Must pass all existing tests (501+ tests) with zero regressions.

---

### Task 1: Localization Keys for Feedback Sheet

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Test: `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`

**Interfaces:**
- Produces: Localization entries for `craft.feedback.success_title`, `craft.feedback.error_title`, `craft.feedback.warning_title`, `craft.feedback.info_title`, `craft.feedback.continue_action`.

- [ ] **Step 1: Write the failing test for feedback localization keys**

Add test method to `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`:

```swift
func testFeedbackSheetLocalizationKeys() {
    let successEn = CraftLocalized.string("craft.feedback.success_title", language: "en")
    let successVi = CraftLocalized.string("craft.feedback.success_title", language: "vi")
    let errorEn = CraftLocalized.string("craft.feedback.error_title", language: "en")
    let errorVi = CraftLocalized.string("craft.feedback.error_title", language: "vi")
    let continueEn = CraftLocalized.string("craft.feedback.continue_action", language: "en")
    let continueVi = CraftLocalized.string("craft.feedback.continue_action", language: "vi")

    XCTAssertEqual(successEn, "Nice work!")
    XCTAssertEqual(successVi, "Chính xác!")
    XCTAssertEqual(errorEn, "Incorrect")
    XCTAssertEqual(errorVi, "Chưa chính xác")
    XCTAssertEqual(continueEn, "CONTINUE")
    XCTAssertEqual(continueVi, "TIẾP TỤC")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LocalizationTests/testFeedbackSheetLocalizationKeys`  
Expected: FAIL (returns raw keys because entries are missing).

- [ ] **Step 3: Update `Localizable.xcstrings` with feedback keys**

Add entries to `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:
- `"craft.feedback.success_title"`: en -> "Nice work!", vi -> "Chính xác!"
- `"craft.feedback.error_title"`: en -> "Incorrect", vi -> "Chưa chính xác"
- `"craft.feedback.warning_title"`: en -> "Almost!", vi -> "Gần đúng!"
- `"craft.feedback.info_title"`: en -> "Explanation", vi -> "Giải thích"
- `"craft.feedback.continue_action"`: en -> "CONTINUE", vi -> "TIẾP TỤC"

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LocalizationTests/testFeedbackSheetLocalizationKeys`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift
git commit -m "feat(craftuikit): add localization keys for CraftFeedbackSheet"
```

---

### Task 2: `CraftFeedbackStatus` Enum & Semantic Token Resolution

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift`
- Create: `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`

**Interfaces:**
- Produces: `CraftFeedbackStatus` enum (`.success`, `.error`, `.warning`, `.info`), with `.iconName`, default titles, and semantic color resolution helpers.

- [ ] **Step 1: Write failing test for `CraftFeedbackStatus`**

Create `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class FeedbackComponentTests: XCTestCase {
    func testCraftFeedbackStatusProperties() {
        XCTAssertEqual(CraftFeedbackStatus.success.iconName, "checkmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.error.iconName, "xmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.warning.iconName, "exclamationmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.info.iconName, "info.circle.fill")

        XCTAssertEqual(CraftFeedbackStatus.allCases.count, 4)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter FeedbackComponentTests/testCraftFeedbackStatusProperties`  
Expected: FAIL (Cannot find `CraftFeedbackStatus` in scope).

- [ ] **Step 3: Implement `CraftFeedbackStatus` in `CraftFeedbackSheet.swift`**

Create `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift` with `CraftFeedbackStatus`:

```swift
import SwiftUI

// MARK: - CraftFeedbackStatus

/// Semantic status for assessment feedback sheets.
public enum CraftFeedbackStatus: String, Sendable, CaseIterable {
    case success
    case error
    case warning
    case info

    /// SF Symbol icon representation for the feedback state.
    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter FeedbackComponentTests/testCraftFeedbackStatusProperties`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift
git commit -m "feat(craftuikit): add CraftFeedbackStatus enum and test suite"
```

---

### Task 3: Implement `CraftFeedbackSheet` Component

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftSurfaceStyle`, `CraftButton`, `CraftIcon`, `CraftLocalized`, `CraftFeedbackStatus`.
- Produces: `CraftFeedbackSheet<ExtraContent: View>` view component with tactile buttons, dynamic surface styles, and optional extra content.

- [ ] **Step 1: Write failing tests for `CraftFeedbackSheet` initialization and rendering**

Add to `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`:

```swift
func testCraftFeedbackSheetInitialization() {
    var continueTriggered = false
    let sheet = CraftFeedbackSheet(
        status: .success,
        title: "Nice work!",
        message: "You got it right!",
        actionTitle: "CONTINUE",
        onContinue: {
            continueTriggered = true
        }
    )

    XCTAssertEqual(sheet.status, .success)
    XCTAssertEqual(sheet.title, "Nice work!")
    XCTAssertEqual(sheet.message, "You got it right!")
    XCTAssertEqual(sheet.actionTitle, "CONTINUE")
    XCTAssertNil(sheet.surfaceStyle)

    sheet.onContinue()
    XCTAssertTrue(continueTriggered)
    XCTAssertNotNil(sheet.body)
}

func testCraftFeedbackSheetWithExtraContent() {
    var secondaryTriggered = false
    let sheet = CraftFeedbackSheet(
        status: .error,
        title: "Incorrect",
        message: "Correct: Apple",
        secondaryActionTitle: "Explain",
        onSecondaryAction: {
            secondaryTriggered = true
        },
        onContinue: {}
    ) {
        Text("Extra Hint")
    }

    XCTAssertEqual(sheet.status, .error)
    XCTAssertEqual(sheet.secondaryActionTitle, "Explain")
    sheet.onSecondaryAction?()
    XCTAssertTrue(secondaryTriggered)
    XCTAssertNotNil(sheet.extraContent)
    XCTAssertNotNil(sheet.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter FeedbackComponentTests/testCraftFeedbackSheetInitialization`  
Expected: FAIL (`CraftFeedbackSheet` type not declared).

- [ ] **Step 3: Implement `CraftFeedbackSheet`**

Implement full `CraftFeedbackSheet` in `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift`:
- Properties: `status`, `title`, `message`, `actionTitle`, `surfaceStyle`, `onContinue`, `onSecondaryAction`, `secondaryActionTitle`, `extraContent`.
- Convenience inits: with and without `@ViewBuilder extraContent`.
- Layout:
  - Top header row: Status Icon (`CraftIcon(status.iconName, size: .lg)`) + Title (`CraftText(title, style: .title3)` with status tint) + Optional secondary action trailing button.
  - Subtitle message row: `message` with corrective text styling.
  - Optional `extraContent` row.
  - Full-width tactile `CraftButton` (`variant: .tactile`, `size: .lg`, `isFullWidth: true`, `customTint: statusColor`).
- Surface rendering: Top uneven rounded rectangle (`theme.radii.xl`), bottom attached to safe area, styling adapted for `.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`.
- Sensory haptic trigger on appear (`#if os(iOS)`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter FeedbackComponentTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift
git commit -m "feat(craftuikit): implement CraftFeedbackSheet component"
```

---

### Task 4: ViewModifier Extension (`.craftFeedbackSheet`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`

**Interfaces:**
- Produces: `CraftFeedbackSheetModifier` and `.craftFeedbackSheet(...)` view extension with slide-up transition.

- [ ] **Step 1: Write failing test for `.craftFeedbackSheet` modifier**

Add test to `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`:

```swift
func testCraftFeedbackSheetModifier() {
    let dummyView = Text("Question Content")
        .craftFeedbackSheet(
            isPresented: .constant(true),
            status: .success,
            title: "Nice work!",
            onContinue: {}
        )
    XCTAssertNotNil(dummyView)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter FeedbackComponentTests/testCraftFeedbackSheetModifier`  
Expected: FAIL (Cannot find `craftFeedbackSheet` in scope).

- [ ] **Step 3: Implement `CraftFeedbackSheetModifier` and View Extension**

Add `CraftFeedbackSheetModifier` and `View.craftFeedbackSheet` to `CraftFeedbackSheet.swift`:
- Handles presentation transition (`.move(edge: .bottom).combined(with: .opacity)`).
- Z-Index ordering (above page content, ignores bottom safe area).
- Smooth spring animation based on `theme.animations.springSmooth`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter FeedbackComponentTests/testCraftFeedbackSheetModifier`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift
git commit -m "feat(craftuikit): add craftFeedbackSheet view modifier extension"
```

---

### Task 5: Surface Styles & Comprehensive Unit Tests

**Files:**
- Modify: `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift`

**Interfaces:**
- Consumes: All `CraftSurfaceStyle` variants, `CraftFeedbackStatus`.
- Produces: Full coverage test cases for all surface styles, dark mode colors, and accessibility descriptions.

- [ ] **Step 1: Add tests for all surface styles and dark mode accessibility**

Add test cases in `FeedbackComponentTests.swift`:
- `testAllSurfaceStylesForFeedbackSheet()`
- `testFeedbackSheetAccessibilityTree()`
- `testFeedbackSheetAllStatusColors()`

- [ ] **Step 2: Run tests**

Run: `swift test --filter FeedbackComponentTests`  
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift
git commit -m "test(craftuikit): add comprehensive unit tests for CraftFeedbackSheet"
```

---

### Task 6: Design System Catalog & Previews

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Consumes: `CraftFeedbackSheet`, `CraftCatalogView`.
- Produces: Interactive preview showcase in `CraftCatalogView` displaying `.success`, `.error` with correction message, `.warning`, and Liquid Glass styling.

- [ ] **Step 1: Add Feedback Sheet section to `CraftCatalogView.swift`**

Add interactive section in `CraftCatalogView.swift` showcasing:
1. Success state (`Nice work!`, continue button)
2. Error state (`Incorrect`, `Correct: It's a stressful job.`)
3. Warning state (`Almost!`, `Review the pronunciation of the last word.`)
4. Liquid Glass styled feedback sheet.

- [ ] **Step 2: Run catalog test**

Run: `swift test --filter CatalogViewTests`  
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "feat(craftuikit): add CraftFeedbackSheet interactive section to catalog"
```

---

### Task 7: Full Test Suite Verification

**Files:**
- Test: Run entire test suite across `CraftUIKitTests`.

- [ ] **Step 1: Run complete `swift test` suite**

Run: `swift test` in `CraftUIKit` directory.  
Expected: 500+ tests pass with 0 failures.

- [ ] **Step 2: Commit final changes if any**

```bash
git status
```
