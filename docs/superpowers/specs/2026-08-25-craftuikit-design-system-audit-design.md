# CraftUIKit Design System Evolution Specification

**Document:** `docs/superpowers/specs/2026-08-25-craftuikit-design-system-audit-design.md`  
**Date:** 2026-08-25  
**Author:** AI Pair Programmer & Antigravity  
**Status:** Approved by User (Ready for Implementation Planning)

---

## 1. Overview & Vision

`CraftUIKit` is evolved from an app-specific UI component set into a **comprehensive, standalone, zero-hardcoded, and multi-style iOS/SwiftUI Design System**.

### Core Pillars
1. **Universal Reusability & Domain Decoupling**: Components are built as generic UI primitives (e.g. `CraftPathNode`, `CraftActivityTrackerCard`, `CraftCelebrationSheet`) that can be used across any iOS app (habit tracking, e-learning, fitness, onboarding, gaming), while maintaining 100% backward-compatible typed presets (`CraftLessonNode`, `CraftStreakCard`, `CraftLessonDetailSheet`).
2. **Zero-Hardcoding & Native Localization**: Complete elimination of hardcoded strings, placeholders, and VoiceOver texts. Built-in Xcode String Catalog (`Localizable.xcstrings`) with English (`en`) and Vietnamese (`vi`) out-of-the-box, supporting dual initializers (`LocalizedStringKey` & `String`) and effortless app-level override.
3. **Unified Multi-Style Architecture (`CraftSurfaceStyle`)**: Every control and container seamlessly adopts one of 5 distinct visual styles: `.flat`, `.elevated`, `.outlined`, `.tactile3D`, or `.glass` (Liquid Glass / Material), either explicitly or inherited via `EnvironmentValues`.
4. **Theme Extensibility & Zero Color Hardcoding**: Complete removal of inline hexadecimal colors. All tier, badge, highlight, and surface colors are tokenized via `CraftTheme` protocol.
5. **Apple HIG & Accessibility Compliance**: Dynamic Type scaling via `@ScaledMetric`, minimum 44pt touch targets, WCAG AAA contrast assurance, sensory haptic feedback, and Reduce Motion fallbacks.

---

## 2. Architecture & Design Tokens

### 2.1. Unified Surface Style System (`CraftSurfaceStyle`)

```swift
public enum CraftSurfaceStyle: String, Sendable, CaseIterable {
    case flat        // Subtle flat plane (surfaceSubtle), zero shadow
    case elevated    // Subtle elevation shadow (shadows.md), hairline top border
    case outlined    // Crisp border stroke (borderDefault), card/transparent surface
    case tactile3D   // Physical 3D extrusion with bottom rim lip and inner top highlight
    case glass       // Liquid Glass / .ultraThinMaterial with specular reflection border
}

public struct CraftSurfaceStyleKey: EnvironmentKey {
    public static let defaultValue: CraftSurfaceStyle = .flat
}

public extension EnvironmentValues {
    var craftSurfaceStyle: CraftSurfaceStyle {
        get { self[CraftSurfaceStyleKey.self] }
        set { self[CraftSurfaceStyleKey.self] = newValue }
    }
}

public extension View {
    func craftSurfaceStyle(_ style: CraftSurfaceStyle) -> some View {
        environment(\.craftSurfaceStyle, style)
    }
}
```

### 2.2. Surface Modifier (`CraftSurfaceModifier`)

A single reusable modifier standardizes backgrounds, borders, shadows, and 3D depth extrusion across all containers and interactive controls:

```swift
public struct CraftSurfaceModifier<S: Shape>: ViewModifier {
    public let style: CraftSurfaceStyle
    public let shape: S
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let isPressed: Bool
    public let depth: CGFloat
    // Handles background fill, stroke border, shadow, and 3D extrusion depress
}
```

### 2.3. Theme Protocol Extensions (`CraftTheme`)

Add missing tokens to `CraftTheme`:
- **`CraftGlassTokens`**: Material type (`.ultraThinMaterial`, `.thinMaterial`), tint opacities, and specular border gradient.
- **`CraftDepthTokens`**: Parameterized default lip colors (`defaultLipColor`), offsets (`depthSm`, `depthMd`, `depthLg`), and inner highlight gradients.
- **Semantic Tier Tokens**: Tier gradients (`streakStarter`, `streakBlaze`, `streakLegendary`) and base colors fully tokenized into `theme.colors` and `theme.gradients`.

---

## 3. Zero-Hardcoding & Localization System

### 3.1. Package String Catalog (`Sources/CraftUIKit/Resources/Localizable.xcstrings`)

Includes structured string keys for all UI components:
- `craft.action.confirm`: "Confirm" / "Xác nhận"
- `craft.action.cancel`: "Cancel" / "Hủy"
- `craft.action.dismiss`: "Dismiss" / "Đóng"
- `craft.action.continue`: "Continue" / "Tiếp tục"
- `craft.action.close`: "Close" / "Đóng"
- `craft.search.placeholder`: "Search..." / "Tìm kiếm..."
- `craft.search.clearA11y`: "Clear search" / "Xóa tìm kiếm"
- `craft.stepper.increaseA11y`: "Increase" / "Tăng"
- `craft.stepper.decreaseA11y`: "Decrease" / "Giảm"
- `craft.choice.correct`: "Correct Answer" / "Đáp án đúng"
- `craft.choice.wrong`: "Incorrect Answer" / "Đáp án chưa đúng"
- `craft.choice.selected`: "Selected" / "Đã chọn"
- `craft.streak.daysUnit`: "days" / "ngày"
- `craft.streak.bestRecord`: "Best: %lld days" / "Kỷ lục: %lld ngày"
- `craft.streak.freezeShield`: "%lld/%lld Shields" / "%lld/%lld Khiên"
- `craft.streak.tierStarter`: "Starter Streak" / "Chuỗi khởi đầu"
- `craft.streak.tierBlaze`: "Blaze Streak" / "Chuỗi rực lửa"
- `craft.streak.tierLegendary`: "Legendary Streak" / "Chuỗi huyền thoại"
- `craft.journey.continueCallout`: "CONTINUE" / "TIẾP TỤC"
- `craft.journey.completedA11y`: "Completed" / "Đã hoàn thành"
- `craft.journey.lockedA11y`: "Locked" / "Đang khóa"
- `craft.journey.currentA11y`: "Current step" / "Bước hiện tại"

### 3.2. Internal Helper (`CraftLocalized`)

```swift
internal enum CraftLocalized {
    static func string(_ key: String, comment: String = "") -> String {
        Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }
    
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        let format = Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, locale: Locale.current, arguments: arguments)
    }
}
```

### 3.3. Dual Initializer Pattern on 100% Text-bearing Components
Every component provides:
1. `init(_ titleKey: LocalizedStringKey, ...)`
2. `init(_ title: String, ...)`
3. `init(verbatim title: String, ...)`
4. Default accessibility labels resolved from `CraftLocalized`.

---

## 4. Component Upgrade Details

### 4.1. Atoms
- **`CraftText`**: Adds `AttributedString` markdown rendering support, tracking/kerning modifier, custom line spacing, and dynamic semantic color fallback.
- **`CraftBadge`**: Full `CraftSurfaceStyle` support (`flat`, `elevated`, `outlined`, `tactile3D`, `glass`), shape options (`capsule`, `roundedRectangle(radius:)`), custom tint override.
- **`CraftIconButton`**: Full `CraftSurfaceStyle` support (`flat`, `elevated`, `outlined`, `tactile3D`, `glass`), shape options (`circle`, `roundedRectangle(radius:)`), custom tint.
- **`CraftDivider`**: Supports `solid`, `dashed(dash:gap:)`, and `gradient(LinearGradient)` divider styles.
- **`CraftSpinner`**: Parameterized stroke thickness, sizes, and color tint.

### 4.2. Controls
- **`CraftButton`**: Fully integrated with `CraftSurfaceStyle`, custom tint and gradient overrides, localized loading VoiceOver announcements.
- **`CraftChoiceCard`**: 5 surface styles (`flat`, `elevated`, `outlined`, `tactile3D`, `glass`), zero hardcoded hex colors, localized status VoiceOver descriptions.
- **`CraftTextField`**: Visual styles (`.standard`, `.recessed`, `.underlined`, `.glass`), modifier forwarding for keyboard, submit labels, content types, and localized error/helper copy.
- **`CraftToggle` & `CraftSwitch`**: Custom on/off tint colors (`activeTint`, `inactiveTint`), styles (`standard`, `tactile3D`, `glass`).
- **`CraftSearchBar`**: Localized placeholder & cancel action, styles (`standard`, `recessed`, `glass`), shapes (`capsule`, `roundedRectangle`).
- **`CraftPill` / `CraftFilterChip`**: 5 surface styles, parameterized count badge colors.
- **`CraftStepper`**: Localized accessibility VoiceOver, styles (`surfaceSubtle`, `outlined`, `tactile3D`, `glass`).

### 4.3. Containers & Overlays
- **`CraftCard`**: Unified with `CraftSurfaceStyle` including `.glass` (Liquid Glass / UltraThinMaterial with specular reflection) and custom solid/gradient backgrounds.
- **`CraftFlipCard`**: Configurable 3D perspective and spring physics tuning.
- **`CraftDialog`**: Localized confirm/cancel defaults with `LocalizedStringKey`, backdrop blur options (`.ultraThinMaterial` or dimmed color), `.elevated` or `.glass` container styles.
- **`CraftBottomSheet`**: `LocalizedStringKey` headers, localized dismiss button, configurable backdrop material and corner radii.
- **`CraftToast`**: `LocalizedStringKey` support, localized dismiss button, `.glass` style support for crisp HUD over complex backgrounds.
- **`CraftFloatingTabBar`**: Multi-style navigation bar (`.glass`, `.elevated`, `.tactile3D`, `.flat`), localized center FAB and tab titles.

---

## 5. Generic Journey & Activity Tracker Primitives

### 5.1. Universal Journey Path (`CraftPathNode` & `CraftJourneySection`)
- **`CraftPathNodeModel<CustomPayload>`**: Generic node DTO supporting 6 states (`completed`, `active`, `inProgress`, `upcoming`, `locked`, `bonus`), 5 shapes (`circle`, `hexagon`, `diamond`, `squircle`, `star`), custom icons, badges, progress arcs, and metric chips.
- **`CraftPathNode`**: Atom view rendering nodes in any `CraftSurfaceStyle`, with pulsating glow halo, mechanical depress physics, and localized speech bubble callout.
- **`CraftJourneySection` & `CraftSnakeConnectorLayer`**: Continuous vector Bézier connectors with dynamic snake row layouts and multi-metric header gateway.
- **Backward Compatibility**: `LessonNodeModel`, `LessonSection`, `CraftLessonNode`, `CraftLessonRow`, `CraftLessonSectionView`, `CraftLearningPath` remain as typed aliases/adapters.

### 5.2. Universal Activity & Streak Dashboard (`CraftActivityTrackerCard` & `CraftCelebrationSheet`)
- **`CraftActivityTrackerData`**: Generic 7-day metric tracking model with customizable unit (days, habits, steps, workouts), tokens (shields/lives), tier mapping, and action slots. Zero hardcoded colors or strings.
- **`CraftCelebrationSheet`**: Multi-purpose milestone celebration modal with confetti/sparkles particle burst (`CraftSparkleView`), animated number count-up, 7-day mini track, and dynamic motivational tiers.
- **Backward Compatibility**: `CraftStreakCard`, `CraftStreakCelebrationSheet`, and `CraftStreakData` map cleanly into generic primitives.

---

## 6. Implementation Strategy & Next Steps
Following approval of this design specification, we will invoke the `writing-plans` skill to generate a structured implementation plan with step-by-step test-driven development (TDD) milestones:
1. **Milestone 1**: String Catalog (`Localizable.xcstrings`) & Localization Infrastructure setup in `Package.swift`.
2. **Milestone 2**: Surface Style tokens & `CraftSurfaceModifier` implementation.
3. **Milestone 3**: Atoms, Controls, and Overlays upgrades with Zero Hardcoding.
4. **Milestone 4**: Generic Journey Path & Activity Tracker primitives and backward-compatibility adapters.
5. **Milestone 5**: Comprehensive Component Showcase Catalog & Unit Tests verification.
