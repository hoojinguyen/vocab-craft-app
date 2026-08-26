# Design Specification: Craft Streak Modernization, Liquid Glass iOS 26+, Dynamic Type Safety & Full Surface Style Integration

**Date:** 2026-08-26  
**Status:** Validated Design (Awaiting User Review Gate)  
**Target:** `CraftUIKit` -> `CraftStreakBadge`, `CraftStreakCard`, `CraftActivityTrackerCard`, `CraftStreakCelebrationSheet`, `CraftCelebrationSheet`  
**Skills Applied:** `ios-design-agent-skill`, `swiftui-design-skill`, `swiftui-liquid-glass`

---

## 1. Overview & Problem Statement

The **Craft Streak** ecosystem in `CraftUIKit` encompasses three foundational components:
1. [`CraftStreakBadge`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift): A compact streak indicator used in navigation bars and header views.
2. [`CraftStreakCard`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift) & [`CraftActivityTrackerCard`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift): A 7-day Bento dashboard widget displaying weekly learning consistency, freeze shields, and milestone progression.
3. [`CraftStreakCelebrationSheet`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift) & [`CraftCelebrationSheet`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCelebrationSheet.swift): A celebratory modal sheet presented when users extend streaks or cross milestone thresholds.

### Audit Findings & Pain Points
* **Dynamic Type Sizing Issue in Badge:** `CraftStreakBadgeSize` currently hardcodes fixed heights (`32pt` and `40pt`). Under Accessibility Dynamic Type (`AX1`–`AX5`), numeric text overflows or gets clipped vertically.
* **Whole-Pill Pulsing Jitter:** Pulsing the entire badge pill (`scaleEffect(1.04)`) in the navigation bar creates distracting layout motion. Modern iOS design principles recommend targeted icon animation (`.symbolEffect(.pulse)`) on the flame symbol.
* **Lack of Recessed Tray in Bento Track:** In `CraftActivityTrackerCard`, the 7-day nodes float directly on the card surface. Adding a sunken/recessed track tray (`surfaceSubtle.opacity(0.45)` with subtle border) enhances architectural depth.
* **Non-Interactive 7-Day Nodes:** Users cannot tap individual day nodes to inspect past activity, freeze usage, or completion details.
* **Imperative Counter Animation Loop:** `CraftCelebrationSheet` uses a manual `for-loop Task.sleep` for count-up rather than modern declarative `.contentTransition(.numericText())`.
* **Incomplete `CraftSurfaceStyle` Support:** While `CraftCard` and `CraftBadge` support all 5 surface styles (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`), `CraftStreakBadge` and `CraftStreakCard` rely predominantly on custom backgrounds and do not fully integrate with `CraftSurfaceStyle` or iOS 26+ `glassEffect()`.

### Design Objectives
1. **Dynamic Type & Capsule Fluidity:** Guarantee that `CraftStreakBadge` scales fluidly across all Dynamic Type sizes without clipping, maintaining 44×44pt minimum touch target ergonomics.
2. **SF Symbol Pulse Animation:** Adopt native `.symbolEffect(.pulse.byLayer)` on the flame icon, replacing whole-pill scaling.
3. **Recessed 7-Day Bento Tray & Day Node Inspection (`onDayTap`):** Embed the 7-day track in a recessed visual tray and provide interactive tap callbacks with light tactile haptics (`UIImpactFeedbackGenerator(style: .light)`).
4. **Declarative Counter Transitions & Multi-Layer Luminous Bloom:** Adopt `.contentTransition(.numericText())` and high-contrast multi-stop bloom in `CraftCelebrationSheet`.
5. **Universal `CraftSurfaceStyle` Support & iOS 26 Liquid Glass:** Enable `.flat`, `.elevated`, `.outlined`, `.tactile3D`, and `.glass` (with `#available(iOS 26, *)` `.glassEffect()` and pre-iOS 26 `.ultraThinMaterial` fallback) across all streak components.
6. **100% Backward Compatibility:** Preserve all existing public API signatures with sensible defaults.

---

## 2. Architecture & Public API Specifications

### 2.1 `CraftStreakBadge` (Atom)

```swift
public struct CraftStreakBadge: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public let count: Int
    public let tier: CraftStreakTier
    public let isCompletedToday: Bool
    public let size: CraftStreakBadgeSize
    public let style: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onTap: (() -> Void)?

    public init(
        count: Int,
        tier: CraftStreakTier? = nil,
        isCompletedToday: Bool = false,
        size: CraftStreakBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onTap: (() -> Void)? = nil
    )
}
```

* **Resolved Style:** `style ?? environmentSurfaceStyle`
* **Layout Sizing:** Soft vertical padding (`size == .sm ? 4 : 6`) and `.frame(minHeight: size.height)` to ensure Dynamic Type safety.

---

### 2.2 `CraftStreakCard` & `CraftActivityTrackerCard` (Containers)

#### `CraftActivityTrackerCard`
```swift
public struct CraftActivityTrackerCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let data: CraftActivityTrackerData
    public let cardStyle: CraftCardStyle
    public let surfaceStyle: CraftSurfaceStyle?
    public let icon: CraftNodeIcon
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onShieldTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?
    public let onDayTap: ((CraftActivityDay) -> Void)?

    public init(
        data: CraftActivityTrackerData,
        cardStyle: CraftCardStyle = .outlined,
        surfaceStyle: CraftSurfaceStyle? = nil,
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onShieldTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftActivityDay) -> Void)? = nil
    )

    // Convenience initializer for direct CraftSurfaceStyle
    public init(
        data: CraftActivityTrackerData,
        surfaceStyle: CraftSurfaceStyle,
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onShieldTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftActivityDay) -> Void)? = nil
    )
}
```

#### `CraftStreakCard`
```swift
public struct CraftStreakCard: View {
    public let data: CraftStreakData
    public let cardStyle: CraftCardStyle
    public let surfaceStyle: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onFreezeTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?
    public let onDayTap: ((CraftStreakDay) -> Void)?

    public init(
        data: CraftStreakData,
        cardStyle: CraftCardStyle = .outlined,
        surfaceStyle: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onFreezeTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftStreakDay) -> Void)? = nil
    )

    public init(
        data: CraftStreakData,
        surfaceStyle: CraftSurfaceStyle,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onFreezeTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftStreakDay) -> Void)? = nil
    )
}
```

---

### 2.3 `CraftStreakCelebrationSheet` & `CraftCelebrationSheet` (Feedback)

```swift
public struct CraftCelebrationSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public let currentValue: Int
    public let previousValue: Int
    public let unit: String
    public let unitKey: String?
    public let cycleDays: [CraftActivityDay]
    public let icon: CraftNodeIcon
    public let surfaceStyle: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onContinue: () -> Void

    public init(
        currentValue: Int,
        previousValue: Int,
        unitKey: String? = nil,
        unit: String = "days",
        cycleDays: [CraftActivityDay] = [],
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        surfaceStyle: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onContinue: @escaping () -> Void
    )
}

public struct CraftStreakCelebrationSheet: View {
    public let currentStreak: Int
    public let previousStreak: Int
    public let weekDays: [CraftStreakDay]
    public let surfaceStyle: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onContinue: () -> Void

    public init(
        currentStreak: Int,
        previousStreak: Int,
        weekDays: [CraftStreakDay] = [],
        surfaceStyle: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onContinue: @escaping () -> Void
    )
}
```

---

## 3. Visual & Interaction Specifications

### 3.1 Surface Style Matrix across Streak Components

| Style | `CraftStreakBadge` | `CraftStreakCard` | `CraftCelebrationSheet` |
| :--- | :--- | :--- | :--- |
| **`.flat`** | `surfaceSubtle` fill, no border | `surfaceSubtle` flat card fill | `surfaceSubtle` flat sheet |
| **`.elevated`** | `surfaceElevated` fill, `.shadow(theme.shadows.sm)` | `surfaceElevated` fill, `.shadow(theme.shadows.md)`, specular border | `surfaceElevated` sheet with elevated shadow |
| **`.outlined`** | `surfaceCard` fill, `borderDefault` stroke (dashed if pending) | `surfaceCard` fill, `borderDefault` 1pt stroke | `surfaceCard` sheet with crisp border |
| **`.tactile3D`** | Capsule with bottom bevel extrusion + top highlight | Card with 4pt bottom extrusion + top highlight | Sheet with tactile top rim highlight & depth |
| **`.glass`** | Liquid glass capsule (`.glassEffect()` / `.ultraThinMaterial`), specular border | Liquid glass card background, specular border gradient | Floating frosted glass sheet with background blur |

---

### 3.2 7-Day Recessed Tray & Interactive Day Nodes

```swift
private var weekTrackRow: some View {
    HStack(spacing: theme.spacing.xs) {
        ForEach(data.cycleDays) { day in
            VStack(spacing: theme.spacing.xs) {
                Text(day.weekdaySymbol)
                    .font(theme.typography.caption)
                    .fontWeight(day.isToday ? .bold : .medium)
                    .foregroundStyle(day.isToday ? theme.colors.textPrimary : theme.colors.textMuted)

                if let onDayTap {
                    Button {
                        #if os(iOS)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.prepare()
                        impact.impactOccurred()
                        #endif
                        onDayTap(day)
                    } label: {
                        dayStatusNode(for: day)
                    }
                    .buttonStyle(.craftPress(scale: 0.94))
                    .accessibilityLabel(accessibilityDayLabel(for: day))
                    .accessibilityHint(CraftLocalized.string("craft.streak.dayNodeHint"))
                } else {
                    dayStatusNode(for: day)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
    .padding(.vertical, theme.spacing.sm)
    .padding(.horizontal, theme.spacing.xs)
    .background(theme.colors.surfaceSubtle.opacity(0.45))
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .overlay(
        RoundedRectangle(cornerRadius: theme.radii.md)
            .strokeBorder(theme.colors.borderDefault.opacity(0.35), lineWidth: 0.8)
    )
}
```

---

### 3.3 Motion & Transitions

#### SF Symbol Pulse on Flame
```swift
Image(systemName: CraftSymbol.streak.rawValue)
    .font(.system(size: size.iconSize, weight: .bold))
    .foregroundStyle(tierGradient)
    .symbolEffect(.pulse.byLayer, options: .repeating, isActive: !isCompletedToday && !reduceMotion)
```

#### Declarative Numeric Text Transition in Celebration Sheet
```swift
Text("\(displayedValue)")
    .font(theme.typography.displayHero)
    .monospacedDigit()
    .contentTransition(.numericText(countsDown: false))
    .foregroundStyle(theme.colors.textPrimary)
```

#### Multi-Stop Luminous Halo Bloom
```swift
ZStack {
    // Outer multi-stop ambient bloom
    RadialGradient(
        colors: [
            tierBaseColor.opacity(0.30),
            tierBaseColor.opacity(0.12),
            Color.clear
        ],
        center: .center,
        startRadius: 20,
        endRadius: 70
    )
    .frame(width: 140, height: 140)

    // Inner specular glass disc pedestal
    Circle()
        .fill(
            LinearGradient(
                colors: [
                    tierBaseColor.opacity(0.22),
                    tierBaseColor.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 104, height: 104)
        .overlay(
            Circle()
                .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
        )
        .craftShadow(theme.shadows.md)

    // Hero Flame Icon
    Image(systemName: icon.name)
        .font(.system(size: 56, weight: .bold))
        .foregroundStyle(tierGradient)
}
```

---

### 3.4 Liquid Glass iOS 26 Implementation & Pre-iOS 26 Fallback

```swift
@ViewBuilder
private func badgeGlassBackground(radius: CGFloat) -> some View {
    if #available(iOS 26, macOS 26, *) {
        if reduceTransparency {
            Capsule().fill(theme.colors.surfaceCard)
        } else {
            Capsule()
                .glassEffect(.regular.interactive(onTap != nil), in: Capsule())
                .overlay(
                    Capsule().strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                )
        }
    } else {
        if reduceTransparency {
            Capsule().fill(theme.colors.surfaceCard)
        } else {
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(tierBaseColor.opacity(isCompletedToday ? 0.12 : 0.04))
            }
            .overlay(
                Capsule().strokeBorder(theme.glass.borderGradient, lineWidth: 1)
            )
        }
    }
}
```

---

## 4. Verification Plan

### 4.1 Automated Tests (`swift test --package-path CraftUIKit`)
1. **`CraftStreakBadgeTests`:**
   - Verify all `CraftSurfaceStyle` cases (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`).
   - Validate Dynamic Type scaling properties (flexible vertical padding and minHeight).
   - Test `onTap` interaction and custom accessibility strings.
2. **`CraftStreakCardTests` & `CraftActivityTrackerCardTests`:**
   - Verify initializers accepting `surfaceStyle: CraftSurfaceStyle`.
   - Test `onDayTap` callback invocation and accessibility actions for each day.
   - Verify rendering across all streak tiers (`starter`, `blaze`, `legendary`) and all day statuses (`completed`, `pending`, `saved`, `missed`, `upcoming`).
3. **`CraftCelebrationSheetTests`:**
   - Verify initialization with `surfaceStyle`.
   - Validate milestone detection logic for tiers and numeric milestones.
   - Verify `onContinue` action and VoiceOver accessibility hints.

### 4.2 Manual / Catalog Verification
* Build and inspect `CraftCatalogView.swift` (Section 6: Universal Activity & Streak Tracker) with:
  - Surface Style picker (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`).
  - Interactive Day Node tap action demonstration.
  - Dark Mode and Light Mode appearance verification.
  - Accessibility Reduce Motion & Reduce Transparency verification.
