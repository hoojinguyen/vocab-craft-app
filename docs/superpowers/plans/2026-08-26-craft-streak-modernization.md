# Craft Streak Modernization & Surface Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize the Craft Streak ecosystem in `CraftUIKit` (`CraftStreakBadge`, `CraftStreakCard`, `CraftActivityTrackerCard`, `CraftStreakCelebrationSheet`, `CraftCelebrationSheet`) with Dynamic Type safety, SF Symbol pulse animations, iOS 26+ Liquid Glass & full `CraftSurfaceStyle` support, 7-day recessed tray with interactive day node inspection (`onDayTap`), and declarative counter transitions.

**Architecture:** Extend existing components with `CraftSurfaceStyle` environment and explicit parameters while preserving 100% backward compatibility. Adopt native iOS 17–26 SwiftUI modifiers (`.symbolEffect()`, `.contentTransition(.numericText())`, `.glassEffect()`, `.craftSurface()`).

**Tech Stack:** Swift 6, SwiftUI, iOS 17.0+ (with iOS 26+ Liquid Glass availability gates), XCTest.

**Spec:** [docs/superpowers/specs/2026-08-26-craft-streak-modernization-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-26-craft-streak-modernization-design.md)

## Global Constraints

- **System fonts only**: Use SF Pro Rounded and design axes (`.monospacedDigit()`).
- **iOS 17+ APIs with iOS 26 gates**: All `#available(iOS 26, *)` APIs must provide graceful pre-iOS 26 fallbacks (`.ultraThinMaterial` / `surfaceCard`).
- **Dynamic Type Safety**: No fixed vertical clipping frames on text capsules; minimum 44×44pt tap targets.
- **Accessibility**: Respect `accessibilityReduceMotion` and `accessibilityReduceTransparency`.
- **100% Backward Compatibility**: All existing constructors must remain valid with default parameter values.

---

### Task 1: `CraftStreakBadge` Modernization & Dynamic Type

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle`, `CraftTheme`, `CraftStreakTier`, `CraftStreakBadgeSize`
- Produces: `CraftStreakBadge(count:tier:isCompletedToday:size:style:accessibilityLabel:accessibilityHint:onTap:)`

- [ ] **Step 1: Write the failing tests in `CraftStreakComponentTests.swift`**

```swift
func testCraftStreakBadgeSurfaceStyles() {
    for style in CraftSurfaceStyle.allCases {
        let badge = CraftStreakBadge(
            count: 7,
            tier: .blaze,
            isCompletedToday: true,
            size: .md,
            style: style
        )
        XCTAssertEqual(badge.style, style)
        XCTAssertNotNil(badge.body)
    }
}

func testCraftStreakBadgeDynamicTypeVerticalPadding() {
    let smBadge = CraftStreakBadge(count: 3, size: .sm)
    let mdBadge = CraftStreakBadge(count: 14, size: .md)
    XCTAssertEqual(smBadge.size.height, 32)
    XCTAssertEqual(mdBadge.size.height, 40)
    XCTAssertNotNil(smBadge.body)
    XCTAssertNotNil(mdBadge.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter testCraftStreakBadgeSurfaceStyles`
Expected: FAIL (member `style` not found on `CraftStreakBadge`)

- [ ] **Step 3: Implement minimal code in `CraftStreakBadge.swift`**

Update `CraftStreakBadge.swift`:
1. Add `@Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle` and `@Environment(\.accessibilityReduceTransparency) private var reduceTransparency`.
2. Add `public let style: CraftSurfaceStyle?`.
3. Add `style: CraftSurfaceStyle? = nil` parameter to `init`.
4. Update `badgePill` layout: replace fixed `.frame(height: size.height)` with `.padding(.vertical, size == .sm ? 4 : 6)` and `.frame(minHeight: size.height)`.
5. Update flame icon to use SF Symbol effect pulse on the icon itself (`.symbolEffect(.pulse.byLayer, options: .repeating, isActive: !isCompletedToday && !reduceMotion)`).
6. Update background & border to use `craftSurface(style: resolvedStyle, shape: Capsule(), ...)` when `resolvedStyle` is specified or when `style == .glass`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter testCraftStreakBadge`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "feat(CraftStreakBadge): add CraftSurfaceStyle support, dynamic type scaling, and SF symbol pulse"
```

---

### Task 2: `CraftActivityTrackerCard` & `CraftStreakCard` Recessed Tray, Interactive Day Nodes & `CraftSurfaceStyle`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Consumes: `CraftActivityTrackerData`, `CraftStreakData`, `CraftSurfaceStyle`, `CraftCardStyle`
- Produces: 
  - `CraftActivityTrackerCard(data:cardStyle:surfaceStyle:icon:accessibilityLabel:accessibilityHint:onShieldTap:onMilestoneTap:onDayTap:)`
  - `CraftStreakCard(data:cardStyle:surfaceStyle:accessibilityLabel:accessibilityHint:onFreezeTap:onMilestoneTap:onDayTap:)`

- [ ] **Step 1: Write the failing tests in `CraftStreakComponentTests.swift`**

```swift
func testCraftStreakCardWithDayTapAndSurfaceStyle() {
    var tappedDay: CraftStreakDay? = nil
    let mockDays: [CraftStreakDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .frozen),
        .init(id: "3", weekdaySymbol: "T4", status: .pending, isToday: true)
    ]
    let streakData = CraftStreakData(
        currentStreak: 10,
        bestStreak: 20,
        weekDays: mockDays
    )
    let card = CraftStreakCard(
        data: streakData,
        surfaceStyle: .glass,
        onDayTap: { day in
            tappedDay = day
        }
    )
    XCTAssertEqual(card.surfaceStyle, .glass)
    XCTAssertNotNil(card.onDayTap)
    card.onDayTap?(mockDays[1])
    XCTAssertEqual(tappedDay?.status, .frozen)
}

func testCraftActivityTrackerCardWithDayTap() {
    var tappedActivityDay: CraftActivityDay? = nil
    let mockDays: [CraftActivityDay] = [
        .init(id: "1", weekdaySymbol: "Mon", status: .completed),
        .init(id: "2", weekdaySymbol: "Tue", status: .saved)
    ]
    let data = CraftActivityTrackerData(
        currentValue: 5,
        bestRecord: 10,
        cycleDays: mockDays
    )
    let card = CraftActivityTrackerCard(
        data: data,
        surfaceStyle: .tactile3D,
        onDayTap: { day in
            tappedActivityDay = day
        }
    )
    XCTAssertEqual(card.surfaceStyle, .tactile3D)
    XCTAssertNotNil(card.onDayTap)
    card.onDayTap?(mockDays[0])
    XCTAssertEqual(tappedActivityDay?.id, "1")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter testCraftStreakCardWithDayTapAndSurfaceStyle`
Expected: FAIL (initializer with `surfaceStyle` and `onDayTap` not found)

- [ ] **Step 3: Implement minimal code in `CraftActivityTrackerCard.swift` & `CraftStreakCard.swift`**

1. In `CraftActivityTrackerCard.swift`:
   - Add `public let surfaceStyle: CraftSurfaceStyle?`.
   - Add `public let onDayTap: ((CraftActivityDay) -> Void)?`.
   - Add initializers accepting `surfaceStyle` and `onDayTap`.
   - In `weekTrackRow`: wrap the `HStack` of days in a recessed tray container (`background(theme.colors.surfaceSubtle.opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: theme.radii.md)).overlay(RoundedRectangle(cornerRadius: theme.radii.md).strokeBorder(theme.colors.borderDefault.opacity(0.35), lineWidth: 0.8))`).
   - In `weekTrackRow`: when `onDayTap != nil`, wrap `dayStatusNode(for: day)` in a `Button` with light impact haptic and accessibility action.
   - Adjust `milestoneProgressSection` layout for flexible responsiveness.
2. In `CraftStreakCard.swift`:
   - Add `public let surfaceStyle: CraftSurfaceStyle?`.
   - Add `public let onDayTap: ((CraftStreakDay) -> Void)?`.
   - Add initializers accepting `surfaceStyle` and `onDayTap`.
   - Forward `surfaceStyle` and `onDayTap` (mapping `CraftActivityDay` to `CraftStreakDay`) to `CraftActivityTrackerCard`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter testCraftStreakCard`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "feat(CraftStreakCard): add recessed 7-day tray, interactive onDayTap, and CraftSurfaceStyle support"
```

---

### Task 3: `CraftCelebrationSheet` & `CraftStreakCelebrationSheet` Declarative Transitions, Multi-Layer Luminous Bloom & `CraftSurfaceStyle`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCelebrationSheet.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle`, `CraftTheme`, `CraftActivityTier`
- Produces:
  - `CraftCelebrationSheet(currentValue:previousValue:unitKey:unit:cycleDays:icon:surfaceStyle:accessibilityLabel:accessibilityHint:onContinue:)`
  - `CraftStreakCelebrationSheet(currentStreak:previousStreak:weekDays:surfaceStyle:accessibilityLabel:accessibilityHint:onContinue:)`

- [ ] **Step 1: Write the failing tests in `CraftStreakComponentTests.swift`**

```swift
func testCraftCelebrationSheetSurfaceStyles() {
    for style in CraftSurfaceStyle.allCases {
        let sheet = CraftCelebrationSheet(
            currentValue: 14,
            previousValue: 13,
            surfaceStyle: style,
            onContinue: {}
        )
        XCTAssertEqual(sheet.surfaceStyle, style)
        XCTAssertNotNil(sheet.body)
    }
}

func testCraftStreakCelebrationSheetWithSurfaceStyle() {
    let streakSheet = CraftStreakCelebrationSheet(
        currentStreak: 21,
        previousStreak: 20,
        surfaceStyle: .glass,
        onContinue: {}
    )
    XCTAssertEqual(streakSheet.surfaceStyle, .glass)
    XCTAssertNotNil(streakSheet.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter testCraftCelebrationSheetSurfaceStyles`
Expected: FAIL (member `surfaceStyle` not found on `CraftCelebrationSheet`)

- [ ] **Step 3: Implement minimal code in `CraftCelebrationSheet.swift` & `CraftStreakCelebrationSheet.swift`**

1. In `CraftCelebrationSheet.swift`:
   - Add `@Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle` and `@Environment(\.accessibilityReduceTransparency) private var reduceTransparency`.
   - Add `public let surfaceStyle: CraftSurfaceStyle?`.
   - Add `surfaceStyle: CraftSurfaceStyle? = nil` parameter to `init`.
   - On `displayedValue` text: add `.contentTransition(.numericText(countsDown: false))` and `.monospacedDigit()`.
   - In `heroFlameSection`: upgrade the glow halo with a multi-stop `RadialGradient` (`[tierBaseColor.opacity(0.30), tierBaseColor.opacity(0.12), Color.clear]`) for high-contrast luminous bloom.
   - In sheet container background: apply `craftSurface(style: surfaceStyle ?? environmentSurfaceStyle, shape: RoundedRectangle(cornerRadius: theme.radii.xl))` with specular highlight overlay.
2. In `CraftStreakCelebrationSheet.swift`:
   - Add `public let surfaceStyle: CraftSurfaceStyle?`.
   - Add `surfaceStyle: CraftSurfaceStyle? = nil` parameter to `init`.
   - Forward `surfaceStyle` to `CraftCelebrationSheet`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter testCraftCelebrationSheet`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCelebrationSheet.swift CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "feat(CraftCelebrationSheet): add numeric text transition, multi-stop luminous halo, and CraftSurfaceStyle support"
```

---

### Task 4: `CraftCatalogView` Showcase & Full Package Test Verification

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`

- [ ] **Step 1: Update `CraftCatalogView.swift` Section 6**

Update `CatalogActivityStreakSection`:
- Add a Surface Style picker (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`) bound to `selectedSurfaceStyle`.
- Render `CraftStreakBadge` across both sizes and all surface styles.
- Add interactive `onDayTap` toast or alert in preview when tapping 7-day track nodes.
- Test celebration sheet modal presentation with selected surface style.

- [ ] **Step 2: Run full test suite**

Run: `swift test --package-path CraftUIKit`
Expected: PASS all 455+ tests with 0 failures and 0 warnings.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift
git commit -m "chore(CraftCatalogView): update Section 6 with streak surface styles showcase and interactive day inspection"
```

---

## Plan Self-Review Checklist

- [x] **Spec coverage**: Covers all requirements from `2026-08-26-craft-streak-modernization-design.md`.
- [x] **No Placeholders**: All code snippets, file paths, commands, and expected outputs are explicit.
- [x] **Type consistency**: Verified `CraftSurfaceStyle`, `CraftStreakBadgeSize`, `CraftStreakDay`, `CraftActivityDay`.
