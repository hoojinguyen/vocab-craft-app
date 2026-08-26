# CraftStreakCard & CraftActivityTrackerCard Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and modernize `CraftStreakCard` (and underlying `CraftActivityTrackerCard`) in `CraftUIKit` to fix the critical milestone string formatting memory corruption bug, support both Modern Apple Liquid Bento and Gamified Tactile 3D across all 6 surface styles, display milestone percentage progress, and enable card-level tap interactions.

**Architecture:** Maintain clean separation between the user-facing `CraftStreakCard` API and the underlying `CraftActivityTrackerCard` container engine. Implement declarative SwiftUI design tokens, fix C-varargs formatting in localization, refine the 7-day recessed tray, and integrate seamless child vs card-level hit-testing.

**Tech Stack:** Swift 6, SwiftUI, Swift Package Manager, XCTest, iOS 17+ (with iOS 26 Liquid Glass compatibility).

**Spec:** [`docs/superpowers/specs/2026-08-26-craftstreakcard-redesign-spec.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-26-craftstreakcard-redesign-spec.md)

## Global Constraints
- Target Framework: `CraftUIKit` (iOS 17.0+ / macOS 14.0+).
- Must preserve backward compatibility for existing `CraftStreakCard` and `CraftActivityTrackerCard` initializers.
- Zero third-party dependencies outside standard Apple frameworks (SwiftUI, Foundation).
- Accessibility: All interactive elements must maintain minimum 44×44pt tap areas and VoiceOver custom actions.
- Anti-Slop: Follow 8pt spacing grid, eliminate visual noise (borders-in-borders), and use semantic theme tokens.

---

### Task 1: Fix Milestone Formatting & Add Percentage Progress Strings

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift:435-446`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Consumes: `CraftLocalized.format(_:_:...)`
- Produces: Correctly formatted milestone string with percentage: `Mốc %lld ngày • %lld%%` / `Milestone %lldd • %lld%%` and `Đạt mốc %lld ngày • 100%` / `Reached %lldd milestone • 100%`.

- [ ] **Step 1: Write the failing unit test**

In `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`:
```swift
func testMilestonePercentageFormatting() {
    let data = CraftActivityTrackerData(
        currentValue: 14,
        bestRecord: 30,
        nextMilestone: 21
    )
    let card = CraftActivityTrackerCard(data: data)
    XCTAssertNotNil(card.body)
    XCTAssertEqual(data.milestoneProgress, 14.0 / 21.0, accuracy: 0.001)
}
```

- [ ] **Step 2: Run test to verify current state**

Run: `swift test --package-path CraftUIKit --filter testMilestonePercentageFormatting`
Expected: PASS (or compilation check)

- [ ] **Step 3: Update `Localizable.xcstrings` and `CraftActivityTrackerCard.swift`**

Add keys `craft.streak.milestoneProgressPercent` and `craft.streak.milestoneReachedPercent` in `Localizable.xcstrings`.
In `CraftActivityTrackerCard.swift`:
```swift
private var milestoneDescriptionText: String {
    if let subtitle = data.subtitle, !subtitle.isEmpty {
        return subtitle
    }
    let remaining = max(0, data.nextMilestone - data.currentValue)
    let percent = Int(round(data.milestoneProgress * 100.0))
    if remaining == 0 {
        return CraftLocalized.format("craft.streak.milestoneReachedPercent", data.nextMilestone)
    } else {
        return CraftLocalized.format("craft.streak.milestoneProgressPercent", data.nextMilestone, percent)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter testMilestonePercentageFormatting`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "fix: resolve milestone string formatting corruption and add percentage progress"
```

---

### Task 2: Refine Visual Styling for Liquid Bento & Tactile 3D

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift:142-266`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift:340-403`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Refines:
  - Header Best Record trophy badge using gold/neutral styling.
  - 7-Day Recessed Tray: softer borderless fill `theme.colors.surfaceSubtle.opacity(0.35)`.
  - Pending Day Node: Ambient ember pulse glow on today's pending node.
  - Footer alignment: vertically centered `HStack` with balanced spacing.

- [ ] **Step 1: Write the failing unit test for visual properties & all tiers**

In `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`:
```swift
func testCraftActivityTrackerCardVisualHierarchyAndTiers() {
    let mockDays: [CraftActivityDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .pending, isToday: true)
    ]
    let data = CraftActivityTrackerData(
        currentValue: 14,
        bestRecord: 30,
        cycleDays: mockDays
    )
    let card = CraftActivityTrackerCard(data: data, cardStyle: .elevated)
    XCTAssertNotNil(card.body)
}
```

- [ ] **Step 2: Update `CraftActivityTrackerCard.swift`**

1. Update `headerRow` trophy badge:
```swift
if data.bestRecord > 0 {
    CraftBadge(
        CraftLocalized.format("craft.streak.bestRecord", data.bestRecord),
        symbol: .trophy,
        variant: .subtle,
        tone: .neutral,
        size: .sm,
        customTint: Color(hex: "F59E0B") // Warm Amber Gold
    )
}
```
2. Update `weekTrackRow` to remove harsh 0.8pt border stroke:
```swift
.background(theme.colors.surfaceSubtle.opacity(0.35))
.clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
```
3. Update `dayStatusNode(for:)` for `.pending`:
```swift
case .pending:
    Circle()
        .fill(day.isToday ? tierBaseColor.opacity(0.12) : theme.colors.surfaceSubtle.opacity(0.5))
        .frame(width: nodeSize, height: nodeSize)
        .overlay(
            Circle()
                .stroke(
                    day.isToday ? tierBaseColor : theme.colors.borderDefault,
                    style: StrokeStyle(lineWidth: 1.5, dash: day.isToday ? [4, 3] : [3, 3])
                )
        )
        .overlay {
            if day.isToday && !reduceMotion {
                Circle()
                    .stroke(tierBaseColor.opacity(isPulsing ? 0.6 : 0.0), lineWidth: 2.5)
                    .scaleEffect(isPulsing ? 1.25 : 1.0)
                    .opacity(isPulsing ? 0.0 : 1.0)
            }
        }
```
4. Align footer row vertically with balanced padding.

- [ ] **Step 3: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter testCraftActivityTrackerCardVisualHierarchyAndTiers`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "style: enhance visual hierarchy, gold trophy, soft recessed tray, and ember glow"
```

---

### Task 3: Implement Card-Level Tap with Nested Child Interactions

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- `CraftStreakCard.init(..., onTap: (() -> Void)? = nil, ...)`
- `CraftActivityTrackerCard.init(..., onCardTap: (() -> Void)? = nil, ...)`

- [ ] **Step 1: Write the failing unit test for card-level tap & nested actions**

In `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`:
```swift
func testCraftStreakCardCardLevelTapAndChildTaps() {
    var cardTapped = false
    var dayTapped = false
    var freezeTapped = false

    let day = CraftStreakDay(id: "1", weekdaySymbol: "T2", status: .completed)
    let data = CraftStreakData(currentStreak: 14, bestStreak: 30, weekDays: [day])

    let card = CraftStreakCard(
        data: data,
        onTap: { cardTapped = true },
        onFreezeTap: { freezeTapped = true },
        onDayTap: { _ in dayTapped = true }
    )

    XCTAssertNotNil(card.body)
    XCTAssertNotNil(card.onTap)
    XCTAssertNotNil(card.onFreezeTap)
    XCTAssertNotNil(card.onDayTap)

    card.onTap?()
    XCTAssertTrue(cardTapped)

    card.onFreezeTap?()
    XCTAssertTrue(freezeTapped)

    card.onDayTap?(day)
    XCTAssertTrue(dayTapped)
}
```

- [ ] **Step 2: Run test to verify it fails (missing `onTap` parameter)**

Run: `swift test --package-path CraftUIKit --filter testCraftStreakCardCardLevelTapAndChildTaps`
Expected: FAIL (argument 'onTap' does not exist)

- [ ] **Step 3: Update `CraftStreakCard.swift` & `CraftActivityTrackerCard.swift`**

In `CraftStreakCard.swift`:
- Add `public let onTap: (() -> Void)?`
- Pass `onCardTap: onTap` into `CraftActivityTrackerCard`.

In `CraftActivityTrackerCard.swift`:
- Add `public let onCardTap: (() -> Void)?`
- Pass `action: onCardTap` and `isPressable: onCardTap != nil` to `CraftCard`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter testCraftStreakCardCardLevelTapAndChildTaps`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "feat: add card-level tap to CraftStreakCard with nested child action preservation"
```

---

### Task 4: Full Surface Styles Verification & Previews

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Validates all 6 styles: `.flat`, `.elevated`, `.outlined`, `.gradient`, `.tactile3D`, `.glass` across both Light and Dark mode.

- [ ] **Step 1: Write test verifying all 6 styles with card tap and day callbacks**

In `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`:
```swift
func testCraftStreakCardAllSixStylesWithTap() {
    let streakData = CraftStreakData(currentStreak: 14, bestStreak: 30)
    for style in CraftCardStyle.allCases {
        let card = CraftStreakCard(
            data: streakData,
            cardStyle: style,
            onTap: {}
        )
        XCTAssertEqual(card.cardStyle, style)
        XCTAssertNotNil(card.body)
    }
}
```

- [ ] **Step 2: Run test suite**

Run: `swift test --package-path CraftUIKit`
Expected: PASS (All tests pass)

- [ ] **Step 3: Update Previews in `CraftStreakCard.swift` and `CraftCatalogView.swift`**

Include previews demonstrating all 6 surface styles (`.flat`, `.elevated`, `.outlined`, `.gradient`, `.tactile3D`, `.glass`) and interactive tap callbacks.

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "test: verify all six surface styles and update CraftStreakCard previews"
```
