# Streak UI Component Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, HIG-compliant, modular Streak UI component suite in `CraftUIKit` (`CraftStreakBadge`, `CraftStreakCard`, `CraftStreakCelebrationSheet`, and Tokens) with an interactive showcase in `CraftCatalogView` and integrate it into `VocabCraftApp`.

**Architecture:** Dumb / Presentational UI architecture where `CraftUIKit` exposes pure view state models (`CraftStreakData`), semantic tokens (`CraftColorTokens`, `CraftGradientTokens`), and accessible SwiftUI components (`CraftStreakBadge`, `CraftStreakCard`, `CraftStreakCelebrationSheet`), completely decoupled from domain/business calculations which are owned by the host app (`VocabCraftApp`).

**Tech Stack:** Swift 6 / SwiftUI (iOS 17+), XCTest / Swift Testing, SF Symbols, CraftUIKit Design System Tokens.

**Spec:** [2026-08-23-streak-ui-craftuikit-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-23-streak-ui-craftuikit-design.md)

## Global Constraints

- Platform: iOS 17.0+
- Spacing: 8pt grid alignment (4, 8, 12, 16, 24, 32)
- Touch Targets: Minimum 44×44pt for all interactive surfaces
- Typography: Dynamic Type support, `.monospacedDigit()` for counters, SF Pro / New York pairing
- Icons: SF Symbols only (no functional emojis)
- Motion: `@Environment(\.accessibilityReduceMotion)` respected across all animations and particle systems
- Testing: Pure unit tests for models and component instantiation in `CraftUIKitTests`

---

### Task 1: Extend CraftUIKit Design Tokens for Streak System

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftGradientTokens.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftDefaultTheme.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftEmeraldTheme.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/TokenTests.swift`

**Interfaces:**
- Produces:
  - `CraftColorTokens.streakFreeze: Color`
  - `CraftColorTokens.streakPending: Color`
  - `CraftColorTokens.streakGlow: Color`
  - `CraftGradientTokens.streakStarter: LinearGradient`
  - `CraftGradientTokens.streakBlaze: LinearGradient`
  - `CraftGradientTokens.streakLegendary: LinearGradient`

- [ ] **Step 1: Write the failing test in `TokenTests.swift`**

```swift
func testStreakColorAndGradientTokens() {
    let theme = CraftDefaultTheme()
    XCTAssertNotNil(theme.colors.streakFreeze)
    XCTAssertNotNil(theme.colors.streakPending)
    XCTAssertNotNil(theme.colors.streakGlow)
    XCTAssertNotNil(theme.gradients.streakStarter)
    XCTAssertNotNil(theme.gradients.streakBlaze)
    XCTAssertNotNil(theme.gradients.streakLegendary)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter TokenTests`
Expected: FAIL due to missing properties on `CraftColorTokens` and `CraftGradientTokens`.

- [ ] **Step 3: Update `CraftColorTokens.swift`, `CraftGradientTokens.swift`, and theme definitions**

Add protocol properties and default implementations:
- In `CraftColorTokens`:
  ```swift
  var streakFreeze: Color { get }
  var streakPending: Color { get }
  var streakGlow: Color { get }
  ```
- In `CraftGradientTokens`:
  ```swift
  var streakStarter: LinearGradient { get }
  var streakBlaze: LinearGradient { get }
  var streakLegendary: LinearGradient { get }
  ```
- Supply default colors:
  - `streakFreeze`: `Color(hex: 0x38BDF8)`
  - `streakPending`: `Color(hex: 0x94A3B8)`
  - `streakGlow`: `Color(hex: 0xF59E0B).opacity(0.35)`
  - `streakStarter`: `[Color(hex: 0xE06D3B), Color(hex: 0xEA580C)]`
  - `streakBlaze`: `[Color(hex: 0xF59E0B), Color(hex: 0xEA580C)]`
  - `streakLegendary`: `[Color(hex: 0x8B5CF6), Color(hex: 0x06B6D4)]`

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter TokenTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Tokens/ CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(tokens): add streak colors and gradient tokens to CraftUIKit"
```

---

### Task 2: Create Streak Presentation Models (`CraftStreakModels.swift`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Models/CraftStreakModels.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakModelTests.swift`

**Interfaces:**
- Consumes: Foundation, SwiftUI
- Produces:
  - `CraftStreakTier`: `.starter`, `.blaze`, `.legendary`, `tier(for days: Int) -> CraftStreakTier`
  - `CraftStreakDayStatus`: `.completed`, `.pending`, `.frozen`, `.missed`, `.upcoming`
  - `CraftStreakDay`: `Identifiable`, `Sendable`, `Equatable`
  - `CraftStreakData`: `Sendable`, `Equatable`, `milestoneProgress: Double`, `tier: CraftStreakTier`

- [ ] **Step 1: Write the failing tests in `CraftStreakModelTests.swift`**

```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftStreakModelTests: XCTestCase {
    func testStreakTierThresholds() {
        XCTAssertEqual(CraftStreakTier.tier(for: 0), .starter)
        XCTAssertEqual(CraftStreakTier.tier(for: 5), .starter)
        XCTAssertEqual(CraftStreakTier.tier(for: 7), .blaze)
        XCTAssertEqual(CraftStreakTier.tier(for: 29), .blaze)
        XCTAssertEqual(CraftStreakTier.tier(for: 30), .legendary)
        XCTAssertEqual(CraftStreakTier.tier(for: 100), .legendary)
    }

    func testMilestoneProgressCalculation() {
        let streakData = CraftStreakData(
            currentStreak: 14,
            bestStreak: 20,
            nextMilestoneDays: 20
        )
        XCTAssertEqual(streakData.milestoneProgress, 0.7, accuracy: 0.001)
        XCTAssertEqual(streakData.tier, .blaze)
    }

    func testStreakDayInitialization() {
        let day = CraftStreakDay(id: "2026-08-23", weekdaySymbol: "T2", status: .completed, isToday: true)
        XCTAssertEqual(day.weekdaySymbol, "T2")
        XCTAssertEqual(day.status, .completed)
        XCTAssertTrue(day.isToday)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftStreakModelTests`
Expected: FAIL due to missing types.

- [ ] **Step 3: Implement `CraftStreakModels.swift`**

Create `CraftUIKit/Sources/CraftUIKit/Models/CraftStreakModels.swift` with `CraftStreakTier`, `CraftStreakDayStatus`, `CraftStreakDay`, and `CraftStreakData`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftStreakModelTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Models/CraftStreakModels.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakModelTests.swift
git commit -m "feat(models): add CraftStreakModels and tier evaluation"
```

---

### Task 3: Build Compact Streak Badge (`CraftStreakBadge`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftStreakTier`, `CraftSymbol`
- Produces:
  - `CraftStreakBadge`: Size `.sm` / `.md`, flame gradient, `.monospacedDigit()`, touch target >= 44pt, tap handler.

- [ ] **Step 1: Write the failing test for `CraftStreakBadge` in `CraftStreakComponentTests.swift`**

```swift
func testCraftStreakBadgeInitialization() {
    let badge = CraftStreakBadge(
        count: 14,
        tier: .blaze,
        isCompletedToday: true,
        size: .sm
    )
    XCTAssertNotNil(badge.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftStreakComponentTests`
Expected: FAIL due to missing `CraftStreakBadge`.

- [ ] **Step 3: Implement `CraftStreakBadge.swift`**

Implement `CraftStreakBadge`:
- Support `.sm` (32pt height) and `.md` (40pt height).
- Show `Image(systemName: "flame.fill")` colored with theme's gradient corresponding to `tier`.
- Display count with `.monospacedDigit()` and `.system(.caption / .callout, design: .rounded, weight: .bold)`.
- If `!isCompletedToday`, show subtle breathing pulse (unless `reduceMotion`) and dashed/subtle border.
- Include `.frame(minWidth: 44, minHeight: 44)` tap target container.
- Add VoiceOver accessibility label and hint.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftStreakComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "feat(ui): implement CraftStreakBadge component with HIG tap targets and accessibility"
```

---

### Task 4: Build Bento Streak Card (`CraftStreakCard`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Consumes: `CraftCard`, `CraftBadge`, `CraftProgressBar`, `CraftStreakData`, `CraftTheme`
- Produces:
  - `CraftStreakCard(data: CraftStreakData, onFreezeTap: (() -> Void)?, onMilestoneTap: (() -> Void)?)`

- [ ] **Step 1: Write the failing test for `CraftStreakCard`**

```swift
func testCraftStreakCardRendering() {
    let mockDays: [CraftStreakDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .completed),
        .init(id: "3", weekdaySymbol: "T4", status: .frozen),
        .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
        .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
        .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
        .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
    ]
    let streakData = CraftStreakData(
        currentStreak: 14,
        bestStreak: 30,
        freezeTokens: 2,
        maxFreezeTokens: 3,
        nextMilestoneDays: 21,
        isCompletedToday: false,
        weekDays: mockDays
    )
    let card = CraftStreakCard(data: streakData)
    XCTAssertNotNil(card.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftStreakComponentTests`
Expected: FAIL due to missing `CraftStreakCard`.

- [ ] **Step 3: Implement `CraftStreakCard.swift`**

Implement `CraftStreakCard`:
- Build on top of `CraftCard`.
- **Header**: Large flame icon with tier gradient + current streak count + best streak pill.
- **7-Day Track**: `HStack(spacing: 8)` with 7 equal day columns. Map status:
  - `completed`: Filled flame/checkmark in tier gradient.
  - `pending`: Glowing animated border.
  - `frozen`: Snowflake icon in `streakFreeze` ice color.
  - `missed`: Muted dot.
  - `upcoming`: Subdued circle.
- **Footer**: Freeze Shield Counter (`CraftBadge` with snowflake) + `CraftProgressBar` with milestone description text.
- Full VoiceOver container element & labels.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftStreakComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "feat(ui): implement CraftStreakCard 7-day bento widget"
```

---

### Task 5: Build Streak Celebration Sheet (`CraftStreakCelebrationSheet`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Consumes: `CraftSparkleView`, `CraftButton`, `CraftStreakTier`, `CraftStreakDay`, `CraftTheme`
- Produces:
  - `CraftStreakCelebrationSheet(currentStreak: Int, previousStreak: Int, weekDays: [CraftStreakDay], onContinue: @escaping () -> Void)`

- [ ] **Step 1: Write the failing test for `CraftStreakCelebrationSheet`**

```swift
func testCraftStreakCelebrationSheetRendering() {
    let sheet = CraftStreakCelebrationSheet(
        currentStreak: 14,
        previousStreak: 13,
        weekDays: [],
        onContinue: {}
    )
    XCTAssertNotNil(sheet.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftStreakComponentTests`
Expected: FAIL due to missing `CraftStreakCelebrationSheet`.

- [ ] **Step 3: Implement `CraftStreakCelebrationSheet.swift`**

Implement `CraftStreakCelebrationSheet`:
- Large flame hero with Spring pop-in transition (`scaleEffect` + `opacity`).
- Integrated `CraftSparkleView(isTriggered: .constant(true))` for particles.
- Animated number transition from `previousStreak` to `currentStreak`.
- Motivational message based on streak milestone.
- Mini 7-day track showcasing today's day turning completed.
- Haptics on appear: `UIImpactFeedbackGenerator(style: .medium)`.
- Primary `CraftButton` for "Tiếp tục học" / "Continue".
- Check `@Environment(\.accessibilityReduceMotion)` to suppress animations when enabled.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftStreakComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "feat(ui): implement CraftStreakCelebrationSheet celebratory overlay"
```

---

### Task 6: Add Interactive Streak Showcase to `CraftCatalogView`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`

**Interfaces:**
- Consumes: `CraftStreakBadge`, `CraftStreakCard`, `CraftStreakCelebrationSheet`, `CraftStreakData`

- [ ] **Step 1: Add Streak Showcase Section in `CraftCatalogView`**

Add an interactive section with:
- Streak Tier selector (Starter: 3 days, Blaze: 14 days, Legendary: 45 days).
- Toggle for `isCompletedToday`.
- Live preview of `CraftStreakBadge` (.sm and .md).
- Live preview of `CraftStreakCard`.
- Button to trigger and preview `CraftStreakCelebrationSheet` in a `.sheet` presentation.

- [ ] **Step 2: Verify `CraftCatalogView` compiles without errors**

Run: `swift test --package-path CraftUIKit`
Expected: All tests pass and package builds cleanly.

- [ ] **Step 3: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "feat(catalog): add interactive Streak Components gallery section"
```

---

### Task 7: Integrate `CraftStreakBadge` into `VocabCraftApp`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HeaderView.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HeaderViewTests.swift`

**Interfaces:**
- Consumes: `CraftUIKit.CraftStreakBadge`, `CraftUIKit.CraftStreakTier`

- [ ] **Step 1: Update `HeaderView.swift` to use `CraftStreakBadge`**

Replace the custom raw flame badge in `HeaderView` with `CraftStreakBadge`:
```swift
CraftStreakBadge(
    count: streakDays,
    tier: CraftStreakTier.tier(for: streakDays),
    isCompletedToday: dailyGoalProgress >= 1.0,
    size: .sm,
    onTap: onStreakTap
)
```

- [ ] **Step 2: Run VocabCraftApp unit tests**

Run tests via Xcode / xcodebuild to verify HeaderView and Homepage tests pass cleanly.

- [ ] **Step 3: Commit changes**

```bash
git add VocabCraftApp/Features/Homepage/Views/HeaderView.swift VocabCraftAppTests/
git commit -m "feat(app): integrate CraftStreakBadge into Homepage HeaderView"
```
