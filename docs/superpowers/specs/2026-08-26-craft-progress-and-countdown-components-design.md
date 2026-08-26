# Design Spec: CraftStepProgressIndicator & CraftCountdownTimerBar

- **Author**: Antigravity & Hoo Ji Nguyen
- **Date**: 2026-08-26
- **Status**: Validated Design
- **Target Package**: `CraftUIKit` (Design System) & `VocabCraftApp`

---

## 1. Overview & Problem Statement

In the `Reflex Blitz` feature of `VocabCraftApp`, two critical UI components are currently implemented inline inside [ReflexBlitzHeaderView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift):
1. **Top Component**: A discrete interval/step progress indicator displaying capsules for each question/attempt with dynamic status colors, accompanied by a monospaced question step counter (`"1 / 12"`).
2. **Bottom Component**: A linear countdown timer bar powered by `TimelineView`, featuring dynamic color stage shifts (Steady $\rightarrow$ Warning $\rightarrow$ Urgent) and glowing aura effects.

Neither component currently exists in `CraftUIKit`. To enable consistent reuse across quizzes, SRS reflex drills, and onboarding stages while adhering to strict Apple Human Interface Guidelines and SwiftUI performance best practices, we are standardizing and extracting both components into `CraftUIKit`.

---

## 2. Component Architecture & Public APIs

### 2.1 Component 1: `CraftStepProgressIndicator`

Located at: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepProgressIndicator.swift`

#### Status Modeling
```swift
public enum CraftStepStatus: Equatable, Sendable {
    case unreached
    case active
    case completed(isCorrect: Bool)
    case custom(Color)
}
```

#### Counter Format Styles
```swift
public enum CraftStepCounterStyle: Equatable, Sendable {
    case ratio     // "1 / 12"
    case phrase    // "Step 1 of 12" (localized)
    case hidden    // No counter text rendered
}
```

#### Public Initializers
```swift
public struct CraftStepProgressIndicator: View {
    public init(
        steps: [CraftStepStatus],
        currentStep: Int,
        height: CGFloat = 4,
        spacing: CGFloat = 4,
        showCounter: Bool = true,
        counterStyle: CraftStepCounterStyle = .ratio
    )

    public init(
        totalSteps: Int,
        currentStep: Int,
        height: CGFloat = 4,
        spacing: CGFloat = 4,
        showCounter: Bool = true,
        counterStyle: CraftStepCounterStyle = .ratio
    )
}
```

#### Visual & A11y Behavior
- **Geometry**: Array of `Capsule` shapes with equal widths, evenly spaced.
- **Monospaced Digits**: The step counter uses `theme.typography.caption2` with `.monospacedDigit().weight(.bold)` to avoid visual jitter when number digits transition (e.g. 9 to 10).
- **Animation**: Dynamic color and state changes animate with `theme.animations.springSmooth`. When `@Environment(\.accessibilityReduceMotion)` is active, animations fall back to instant transitions.
- **VoiceOver**: Combined element with label `"craft.progress.label"` and formatted value `"craft.step_progress.a11y_value_format"`.

---

### 2.2 Component 2: `CraftCountdownTimerBar`

Located at: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCountdownTimerBar.swift`

#### Warning Stages & Color Configuration
```swift
public enum CraftCountdownStage: Equatable, Sendable {
    case steady   // > 40% time remaining
    case warning  // 15% - 40% time remaining
    case urgent   // < 15% time remaining
}

public struct CraftCountdownColorConfig: Sendable {
    public let steady: Color?
    public let warning: Color?
    public let urgent: Color?
    public let track: Color?
    public let showGlow: Bool

    public init(
        steady: Color? = nil,
        warning: Color? = nil,
        urgent: Color? = nil,
        track: Color? = nil,
        showGlow: Bool = true
    )
}
```

#### Public Initializers (Hybrid Approach)
```swift
public struct CraftCountdownTimerBar: View {
    // Mode A: Time-Driven (High-performance TimelineView animation)
    public init(
        startDate: Date?,
        timeLimit: TimeInterval,
        isActive: Bool = true,
        height: CGFloat = 4.5,
        colorConfig: CraftCountdownColorConfig = .init(),
        onTimeout: (() -> Void)? = nil
    )

    // Mode B: Fraction-Driven / Manual Progress
    public init(
        progress: Double,
        stage: CraftCountdownStage? = nil,
        height: CGFloat = 4.5,
        colorConfig: CraftCountdownColorConfig = .init()
    )
}
```

#### Performance & Energy Optimizations
1. **Zero State-Churn**: Uses `TimelineView(.animation(paused: !isActive))` to compute the fractional progress directly from elapsed time (`timeline.date.timeIntervalSince(startDate)`) without publishing state mutations to the parent SwiftUI hierarchy.
2. **Battery Preservation**: Pauses timeline updates immediately when `isActive == false` or when the app enters the background (`scenePhase != .active`).
3. **GPU-Accelerated Rendering**: Uses scale transforms with `.leading` anchor and `.drawingGroup()` / hardware-accelerated shapes to eliminate layout passes.
4. **Glow Aura**: Applied via `.shadow(color: barColor.opacity(isUrgent ? 0.6 : 0.25), radius: 5)` with smooth color transitions.

---

## 3. Two-Layer Localization Architecture

### 3.1 Layer 1: `CraftUIKit` (`Localizable.xcstrings`)

All keys added with `extractionState: "manual"`, `state: "translated"`, and 100% EN/VI format specifier parity:

| Key | English (`en`) | Vietnamese (`vi`) | Scope |
| :--- | :--- | :--- | :--- |
| `craft.step_progress.a11y_value_format` | `Step %lld of %lld` | `Bước %lld trên %lld` | Step indicator a11y value |
| `craft.countdown.time_remaining_label` | `Time remaining` | `Thời gian còn lại` | Countdown bar a11y label |

---

## 4. Integration into `VocabCraftApp`

Refactor [ReflexBlitzHeaderView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift):
- Replace inline step capsules with `CraftStepProgressIndicator`.
- Replace inline countdown timeline bar with `CraftCountdownTimerBar`.
- Retain existing layout ergonomics (Apple Glass close button, combo streak flame badge, skip action).

---

## 5. Verification & Testing Plan

### Automated Tests
1. **Unit Tests in `CraftUIKitTests`**:
   - `CraftStepProgressIndicatorTests`: Test bounds safety (0 steps, negative indices, overflow indices), status color mapping, counter formatting.
   - `CraftCountdownTimerBarTests`: Test fraction clamping (0.0 to 1.0), stage derivation (`steady`, `warning`, `urgent`), time elapsed calculations, custom color configuration fallbacks.
   - `LocalizationTests`: Run `swift test --filter LocalizationTests` to verify catalog integrity.
2. **Full Package Build**:
   - Run `swift test` on `CraftUIKit`.

### Manual & Visual Verification
- Build and run `VocabCraftApp` in simulator.
- Launch `Reflex Blitz` drill mode:
  - Verify discrete green/coral step progression on answered questions.
  - Verify smooth countdown timer bar animation with color transitions and glow aura.
  - Test pause and resume behavior.
