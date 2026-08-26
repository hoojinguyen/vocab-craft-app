# Design Specification: CraftStreakCard & CraftActivityTrackerCard Redesign, Full Surface Styles, Percentage Milestones & Card-Level Interactions

**Date:** 2026-08-26  
**Status:** Validated Design (Awaiting User Review Gate)  
**Target:** `CraftUIKit` -> `CraftStreakCard`, `CraftActivityTrackerCard`, `Localizable.xcstrings`, `CraftStreakComponentTests`  
**Skills Applied:** `ios-design-agent-skill`, `swiftui-design-skill`, `swiftui-liquid-glass`

---

## 1. Overview & Problem Statement

[`CraftStreakCard`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift) (powered by [`CraftActivityTrackerCard`](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift)) is the flagship 7-day Bento dashboard widget in `CraftUIKit`. It summarizes the user's daily learning consistency, visual tier flame, weekly progress cycle, freeze shields, and milestone progression.

### 1.1 Audit Findings & Pain Points

1. **Critical Memory Corruption in Milestone Formatting:**
   - *Issue*: In `CraftActivityTrackerCard.swift` line 444, `CraftLocalized.format("craft.streak.milestoneRemaining", remaining, resolvedUnit, data.nextMilestone)` passes 3 arguments (`Int`, `String`, `Int`) into a format string with only 2 `%lld` specifiers (`"%lld days until milestone %lld"`).
   - *Impact*: In C-varargs, the String pointer is read as a 64-bit integer, resulting in garbage text like `"-591561852356939..."` and completely breaking the footer layout.
2. **Visual Clutter & Color Dominance in Header:**
   - The Best Record trophy badge (`🏆 Best: 30 days`) uses a `.warning` orange background on top of an already orange flame and orange numbers, creating a mono-orange clutter that diminishes the hierarchy of the record achievement.
3. **Borders-Within-Borders in the 7-Day Cycle Tray:**
   - In Light Mode, the nested rounded rectangle tray has an explicit stroke border (`0.8pt`) inside a card that also has an explicit stroke border. This creates visual noise ("AI-slop box-in-a-box").
4. **Weak "Today Pending" Focal State:**
   - The pending today circle is a faint dashed stroke that blends into the background, lacking an enticing call-to-action glow ("ambient ember pulse") to motivate the user to practice today.
5. **Footer Vertical Alignment & Missing Percentage:**
   - The Freeze Shield badge on the left and the Milestone Progress section on the right are vertically misaligned. The milestone text lacks an intuitive percentage indicator (`%`).
6. **Card-Level Tap Navigation:**
   - The card currently only supports tapping individual day nodes or the shield badge. Users cannot tap the card itself to open a full streak details / celebration history modal.

---

## 2. Design Objectives & Architecture

1. **Dual Design Direction Synthesis:**
   - **Modern Apple Liquid Bento**: For `.glass`, `.elevated`, `.outlined`, and `.flat` styles. Features a borderless soft recessed tray (`surfaceSubtle.opacity(0.35)`), Liquid Glass refraction (iOS 26+ `glassEffect` and pre-iOS 26 `ultraThinMaterial`), ambient ember glow on pending nodes, and fluid numeric text transitions.
   - **Gamified Tactile 3D**: For `.tactile3D` style. Features physical bottom extrusion bevels (`theme.depths.depthMd`), 3D coin drop rims on completed days and shields, and mechanical spring depression with tactile haptics on press.
2. **Percentage-Driven Milestone Footer:**
   - Display compact, elegant milestone progress: `Mốc 21 ngày • 67%` (or `Đạt mốc 21 ngày • 100%`) with a sleek 6pt progress bar directly beneath it, perfectly centered against the freeze shield pill.
3. **Card-Level Tap with Nested Interactive Seams:**
   - Add `onTap: (() -> Void)?` to `CraftStreakCard` and `onCardTap: (() -> Void)?` to `CraftActivityTrackerCard`.
   - Tapping anywhere on the card triggers the card action, while tapping individual days (`onDayTap`) or the shield badge (`onShieldTap` / `onFreezeTap`) executes their dedicated callbacks with nested hit-testing.
4. **Gold-Accented Trophy Badge:**
   - Elevate the Best Record badge to use a refined gold/neutral styling to contrast beautifully against the tier flame.
5. **Universal Surface Style Support:**
   - Support all 6 surface/card variants: `.flat`, `.elevated`, `.outlined`, `.gradient`, `.tactile3D`, `.glass`.

---

## 3. Public API Specifications

### 3.1 `CraftStreakCard`

```swift
public struct CraftStreakCard: View {
    public let data: CraftStreakData
    public let cardStyle: CraftCardStyle
    public let surfaceStyle: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onTap: (() -> Void)?
    public let onFreezeTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?
    public let onDayTap: ((CraftStreakDay) -> Void)?

    public init(
        data: CraftStreakData,
        cardStyle: CraftCardStyle = .outlined,
        surfaceStyle: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onTap: (() -> Void)? = nil,
        onFreezeTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftStreakDay) -> Void)? = nil
    )

    public init(
        data: CraftStreakData,
        surfaceStyle: CraftSurfaceStyle,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onTap: (() -> Void)? = nil,
        onFreezeTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftStreakDay) -> Void)? = nil
    )
}
```

### 3.2 `CraftActivityTrackerCard`

```swift
public struct CraftActivityTrackerCard: View {
    public let data: CraftActivityTrackerData
    public let cardStyle: CraftCardStyle
    public let surfaceStyle: CraftSurfaceStyle?
    public let icon: CraftNodeIcon
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onCardTap: (() -> Void)?
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
        onCardTap: (() -> Void)? = nil,
        onShieldTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftActivityDay) -> Void)? = nil
    )

    public init(
        data: CraftActivityTrackerData,
        surfaceStyle: CraftSurfaceStyle,
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onCardTap: (() -> Void)? = nil,
        onShieldTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftActivityDay) -> Void)? = nil
    )
}
```

---

## 4. Visual & Interaction Specifications

### 4.1 Surface Style Matrix

| Surface Style | Background Fill | Border Treatment | Depth & Shadow |
| :--- | :--- | :--- | :--- |
| **`.flat`** | `surfaceSubtle` | None | None |
| **`.elevated`** | `surfaceElevated` | Specular Light Gradient | `shadows.md` |
| **`.outlined`** | `surfaceCard` | `borderDefault` 1pt stroke | None |
| **`.gradient`** | `theme.gradients.streakBlaze` (or tier gradient) | None | White high-contrast text |
| **`.tactile3D`** | `surfaceCard` with 4pt bottom extrusion | Top specular highlight + bottom rim | Mechanical depression on press |
| **`.glass`** | iOS 26+ `.glassEffect()` / iOS 17 `.ultraThinMaterial` | `theme.glass.borderGradient` | `shadows.sm` + Light refraction |

### 4.2 Milestone Progress Formatting

In `Localizable.xcstrings`:
* Key: `"craft.streak.milestoneProgressPercent"`
  * `vi`: `"Mốc %lld ngày • %lld%%"` (hoặc `"Còn %lld ngày • %lld%%"`)
  * `en`: `"Milestone %lldd • %lld%%"` (hoặc `"%lld days left • %lld%%"`)
* Key: `"craft.streak.milestoneReachedPercent"`
  * `vi`: `"Đạt mốc %lld ngày • 100%"`
  * `en`: `"Reached %lldd milestone • 100%"`

Implementation in `CraftActivityTrackerCard`:
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

### 4.3 Ambient Ember Glow for Today's Pending Node

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
                    .stroke(tierBaseColor.opacity(isPulsing ? 0.6 : 0.0), lineWidth: 3)
                    .scaleEffect(isPulsing ? 1.25 : 1.0)
                    .opacity(isPulsing ? 0.0 : 1.0)
            }
        }
```

### 4.4 Clean 7-Day Tray (Eliminating Borders-in-Borders)

```swift
private var weekTrackRow: some View {
    HStack(spacing: theme.spacing.xs) {
        ForEach(data.cycleDays) { day in
            VStack(spacing: theme.spacing.xs) {
                Text(day.weekdaySymbol)
                    .font(theme.typography.caption)
                    .fontWeight(day.isToday ? .bold : .medium)
                    .foregroundStyle(day.isToday ? theme.colors.textPrimary : theme.colors.textMuted)

                dayNodeView(for: day)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
    .padding(.horizontal, theme.spacing.xs)
    .padding(.vertical, theme.spacing.sm)
    .background(theme.colors.surfaceSubtle.opacity(0.35))
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
}
```

---

## 5. Verification Plan

### 5.1 Automated Unit Tests (`swift test --package-path CraftUIKit`)
* `testCraftStreakCardCardLevelTap()`: Verify `onTap` callback is triggered when card is pressed.
* `testCraftStreakCardMilestonePercentageFormatting()`: Verify `%lld%%` format string output without pointer memory corruption.
* `testCraftStreakCardAllSurfaceStyles()`: Verify `.flat`, `.elevated`, `.outlined`, `.gradient`, `.tactile3D`, `.glass`.
* `testCraftStreakCardNestedTaps()`: Verify `onDayTap` and `onFreezeTap` operate independently without blocking or being blocked by card tap.

### 5.2 Visual & Catalog Verification
* Inspect `CraftCatalogView` streak section across all 6 surface styles in both Light and Dark mode.
* Verify Dynamic Type scaling and VoiceOver accessibility labels.
