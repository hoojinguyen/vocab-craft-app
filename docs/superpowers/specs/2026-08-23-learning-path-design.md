# CraftLearningPath — Design Specification

> Duolingo-style serpentine learning journey path component for CraftUIKit.

## Background

The app needs a visual learning path UI where lesson nodes are arranged in a zigzag serpentine pattern with curved connectors. This is a common pattern in language learning apps (Duolingo, Babbel) that provides a gamified, visually engaging progression experience.

No existing open-source SwiftUI library provides this layout. The existing `CraftStepNode` is a simple vertical linear stepper — completely different. This spec defines a new, independent component system conforming to Apple Human Interface Guidelines (HIG), modern SwiftUI motion patterns, and 120fps performance standards.

## Approach

**Section-Scoped Calculated Grid**:
- **Layout**: `VStack`/`HStack`-based row layout per `LessonSection`.
- **Connectors**: Quadratic Bézier curve overlay drawn via `PreferenceKey` position collection (`.anchorPreference` + `overlayPreferenceValue`).
- **Performance Boundary**: Connector drawing is scoped strictly per `LessonSection` (10–20 nodes per section). This prevents a monolithic coordinate graph across 50+ nodes, eliminates layout recalculation feedback loops, and allows smooth, hit-free 120fps scrolling.
- **Motion Architecture**: Continuous loops (`Active Glow` and `Breathing Path`) use **`PhaseAnimator`** (iOS 17+) with strict `@Environment(\.accessibilityReduceMotion)` guards rather than legacy `.repeatForever()` modifiers.

## File Structure

```
CraftUIKit/Sources/CraftUIKit/
├── Models/
│   └── CraftLearningPathModels.swift       [NEW]
├── Components/Containers/
│   ├── CraftNodeConnector.swift            [NEW]
│   ├── CraftLessonNode.swift               [NEW]
│   ├── CraftLessonRow.swift                [NEW]
│   ├── CraftLessonSectionView.swift        [NEW]
│   ├── CraftLearningPath.swift             [NEW]
│   └── CraftLearningPathAnimations.swift   [NEW]
```

6 new files. Zero modifications to existing files.

---

## 1. Models — `CraftLearningPathModels.swift`

### `LessonNodeState`

6-state enum, fully independent of `CraftStepState`:

```swift
public enum LessonNodeState: String, Sendable, Equatable, Hashable, CaseIterable {
    case completed      // Finished — checkmark, statusSuccess
    case active         // Current lesson — large glow ring, brandPrimary, pulsing
    case inProgress     // Started not finished — progress ring overlay
    case upcoming       // Next available — gray, tappable but muted
    case locked         // Not unlocked — padlock, dimmed, not tappable
    case bonus          // Optional/reward — gold accent, star badge
}
```

Rationale for 6 states:
- `inProgress` distinct from `active`: shows partial progress ring arc
- `bonus` for optional/challenge lessons with gold styling

### `LessonNodeModel`

```swift
public struct LessonNodeModel: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let iconName: String             // SF Symbol name
    public let state: LessonNodeState
    public let progress: Double?            // 0.0–1.0, for .inProgress ring
    public let badgeCount: Int?             // red badge overlay
    public let badgeText: String?           // custom badge label

    public init(
        id: String,
        title: String,
        iconName: String,
        state: LessonNodeState,
        progress: Double? = nil,
        badgeCount: Int? = nil,
        badgeText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.state = state
        self.progress = progress
        self.badgeCount = badgeCount
        self.badgeText = badgeText
    }
}
```

### `ConnectorStyle`

```swift
public enum ConnectorStyle: Sendable, Equatable {
    case dashed                             // Dotted/dashed line (default)
    case solid                              // Continuous solid line
    case gradient(from: Color, to: Color)   // Gradient fill along path
    case animated                           // Flowing dots animation
}
```

### `LessonSection`

```swift
public struct LessonSection: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let level: String?               // e.g. "BEGINNER"
    public let progress: String?            // e.g. "2/48"
    public let nodes: [LessonNodeModel]
    public let connectorStyle: ConnectorStyle

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        level: String? = nil,
        progress: String? = nil,
        nodes: [LessonNodeModel],
        connectorStyle: ConnectorStyle = .dashed
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.level = level
        self.progress = progress
        self.nodes = nodes
        self.connectorStyle = connectorStyle
    }
}
```

### `RowPattern` and `LessonRowArrangement`

```swift
public enum RowPattern: Sendable, Equatable {
    case standard           // [1, 2, 1, 2, ...]
    case wave               // [1, 2, 3, 2, 1, 2, 3, ...]
    case custom([Int])      // User-defined
}

public enum LessonRowArrangement: Sendable, Equatable {
    case single             // 1 node, centered
    case pair               // 2 nodes, spread left-right
    case triple             // 3 nodes, evenly distributed
}
```

---

## 2. Shapes — `CraftNodeConnector.swift`

### `CraftNodeConnector` (Shape)

Custom `Shape` drawing a quadratic Bézier curve between two points:

```swift
public struct CraftNodeConnector: Shape {
    public var from: CGPoint
    public var to: CGPoint

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let midY = (from.y + to.y) / 2
        let control1 = CGPoint(x: from.x, y: midY)
        let control2 = CGPoint(x: to.x, y: midY)
        path.addCurve(to: to, control1: control1, control2: control2)
        return path
    }
}
```

### `CraftStyledConnector` (View)

Renders a `CraftNodeConnector` with one of 4 styles:
- **Dashed**: `StrokeStyle(lineWidth: 2, dash: [4, 4])`, color `borderDefault`.
- **Solid**: `StrokeStyle(lineWidth: 2.5, lineCap: .round)`, color `statusSuccess` (completed) or `borderDefault` (locked/upcoming).
- **Gradient**: `LinearGradient` stroke with custom from/to colors.
- **Animated**: `TimelineView(.animation)` + `Canvas` drawing flowing dots along the Bézier path at ~0.5 cycles/sec.

All connector shapes/views apply `.accessibilityHidden(true)` so they do not pollute the VoiceOver accessibility hierarchy.

### ✨ Signature Detail: "Breathing Path" (via `PhaseAnimator`)

The connector between the active node and the next upcoming node subtly "breathes" using `PhaseAnimator` to oscillate stroke width between 2.0pt and 3.0pt without invalidating the parent layout.

```swift
enum BreathingPhase: CaseIterable {
    case rest, inhale
}

struct BreathingConnectorView: View {
    let from: CGPoint
    let to: CGPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.craftTheme) private var theme

    var body: some View {
        if reduceMotion {
            CraftNodeConnector(from: from, to: to)
                .stroke(theme.colors.brandPrimary.opacity(0.4), lineWidth: 2.5)
        } else {
            PhaseAnimator(BreathingPhase.allCases) { phase in
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        theme.colors.brandPrimary.opacity(phase == .inhale ? 0.6 : 0.35),
                        lineWidth: phase == .inhale ? 3.0 : 2.0
                    )
            } animation: { _ in
                .easeInOut(duration: 1.8)
            }
        }
    }
}
```

---

## 3. Atoms — `CraftLessonNode.swift`

Individual circular node view conforming to `Equatable` for zero unnecessary redraws.

### Visual Spec by State

| State | Base Size | Background | Border/Ring | Icon | Extra Effects |
|-------|-----------|------------|-------------|------|---------------|
| `completed` | 52pt | `statusSuccess` | none | `checkmark`, white, `.symbolEffect(.bounce)` | Elevation shadow |
| `active` | 64pt | `brandPrimary` gradient | Outer glow ring 72pt, `PhaseAnimator` scale 1.0↔1.08, opacity 0.2↔0.45 | Custom icon, white, `.symbolEffect(.pulse.byLayer)` | Glow shadow `brandPrimary.opacity(0.25)` radius 12 |
| `inProgress` | 56pt | `surfaceElevated` | Progress ring arc overlay (lineWidth: 3) | Custom icon, brand color | Shows progress arc |
| `upcoming` | 48pt | `surfaceSubtle` | `borderDefault` 1.5pt stroke | Custom icon, `textMuted` | — |
| `locked` | 48pt | `surfaceSubtle` | `borderDefault` 1.5pt stroke | `lock.fill`, `textMuted` | Opacity 0.6 |
| `bonus` | 56pt | `accent` gold | Shimmer sweep via `ShimmerModifier` | `star.fill` or custom, white | Gold glow |

### Active Node Outer Glow (via `PhaseAnimator`)

```swift
enum GlowPhase: CaseIterable {
    case normal, glowing
}

// In CraftLessonNode for .active state:
if !reduceMotion {
    Circle()
        .stroke(theme.colors.brandPrimary.opacity(0.35), lineWidth: 3)
        .frame(width: scaledSize + 12, height: scaledSize + 12)
        .phaseAnimator(GlowPhase.allCases) { content, phase in
            content
                .scaleEffect(phase == .glowing ? 1.08 : 1.0)
                .opacity(phase == .glowing ? 0.5 : 0.2)
        } animation: { _ in
            .easeInOut(duration: 1.5)
        }
}
```

### SF Symbols Transitions (iOS 17+)

```swift
Image(systemName: model.iconName)
    .contentTransition(.symbolEffect(.replace))
    .symbolEffect(.pulse.byLayer, isActive: model.state == .active && !reduceMotion)
    .symbolEffectsRemoved(reduceMotion)
```

### Badge Count

- 18pt circle at top-trailing, `statusDanger` fill, white bold text.
- Badge text uses `.font(.system(size: 11, weight: .bold, design: .rounded)).monospacedDigit()`.
- Numeric text transition: `.contentTransition(.numericText())` + `.symbolEffect(.bounce, value: model.badgeCount)`.

### Dynamic Type & Touch Target (HIG Compliance)

- **Sizes**: Node diameters scale with `@ScaledMetric(relativeTo: .body)`.
- **Minimum Tap Target**: Minimum `44×44pt` touch target enforced via `.frame(minWidth: 44, minHeight: 44).contentShape(Circle())`.
- **Dynamic Type Safety**: When `@Environment(\.dynamicTypeSize).isAccessibilitySize` is true, node labels reflow without truncation and maximum row spacing adapts cleanly.

### VoiceOver & Accessibility

```swift
.accessibilityElement(children: .ignore)
.accessibilityLabel(accessibilityLabelText)
.accessibilityHint(accessibilityHintText)
.accessibilityAddTraits(model.state == .locked ? .notEnabled : .isButton)
```
- **Completed**: *"Lesson: {title}, Completed. Double tap to review"*
- **Active**: *"Lesson: {title}, Current lesson. {progress}% complete. Double tap to continue"*
- **InProgress**: *"Lesson: {title}, In progress. {progress}% complete. Double tap to continue"*
- **Upcoming**: *"Lesson: {title}, Upcoming lesson. Double tap to start"*
- **Locked**: *"Lesson: {title}, Locked. Complete previous lessons to unlock"*
- **Bonus**: *"Bonus Lesson: {title}. Double tap to start"*

### Haptic Feedback

```swift
.sensoryFeedback(.impact(weight: .light), trigger: tapTrigger)
.sensoryFeedback(.success, trigger: completionTrigger)
.sensoryFeedback(.error, trigger: lockedAttemptTrigger)
.sensoryFeedback(.selection, trigger: model.badgeCount)
```

### API

```swift
public struct CraftLessonNode: View, Equatable {
    public let model: LessonNodeModel
    public let onTap: (() -> Void)?

    public init(model: LessonNodeModel, onTap: (() -> Void)? = nil)
}
```

---

## 4. Molecules — `CraftLessonRow.swift`

A horizontal row containing 1–3 nodes with equatable optimization.

### Layout Arrangements

- **Single**: Node centered (`.frame(maxWidth: .infinity)`)
- **Pair**: 2 nodes placed at ~35–40% offset from center
- **Triple**: 3 nodes distributed evenly

### Dynamic Type Adaptation

When `dynamicTypeSize.isAccessibilitySize` is active:
- Horizontal spacing collapses cleanly; node labels use 2-line clamping with `.lineLimit(2)`.
- Arrangements preserve minimum padding to avoid overlapping touch targets.

### API

```swift
public struct CraftLessonRow: View, Equatable {
    public let nodes: [LessonNodeModel]
    public let arrangement: LessonRowArrangement
    public let onNodeTap: ((LessonNodeModel) -> Void)?

    public init(
        nodes: [LessonNodeModel],
        arrangement: LessonRowArrangement,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil
    )
}
```

---

## 5. Section Component — `CraftLessonSectionView.swift`

Independent layout and connector rendering domain for a single `LessonSection`.

### Internal Architecture

1. **Section Header Card**: `CraftCard` style with rounded corners `theme.radii.lg`, subtle border `theme.colors.borderDefault.opacity(0.5)`, showing level tag (`.smallCaps()`), title (`theme.typography.titleMedium`), and progress (`.monospacedDigit().fontDesign(.rounded)`).
2. **VStack of Rows**: Renders calculated rows from `section.nodes` based on `rowPattern`.
3. **Anchor Preference Collection**: Nodes emit their center points using `.anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center) { [model.id: $0] }`.
4. **Isolated Connector Overlay**: `overlayPreferenceValue(NodeAnchorPreferenceKey.self)` draws curves between sequential nodes within this section only.

```swift
public struct CraftLessonSectionView: View {
    public let section: LessonSection
    public let rowPattern: RowPattern
    public let onNodeTap: ((LessonNodeModel) -> Void)?

    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil
    )
}
```

---

## 6. Organisms — `CraftLearningPath.swift`

Top-level container assembling full scrollable journey.

### Structure

1. **LazyVStack of Sections**: Each section is rendered via `CraftLessonSectionView`, keeping layout calculations and preference keys modular.
2. **ScrollViewReader**: Auto-scrolls to the `.active` node on initial render (0.3s delay with smooth animation).
3. **Atmospheric Background**: Subtle brand gradient wash:
   ```swift
   LinearGradient(
       colors: [theme.colors.canvasBackground, theme.colors.brandPrimary.opacity(0.03)],
       startPoint: .top, endPoint: .bottom
   )
   ```
4. **Empty State**: Displays `ContentUnavailableView` when no sections/nodes exist.
5. **Scroll Transition**:
   ```swift
   .scrollTransition(.animated) { content, phase in
       content
           .opacity(1 - abs(phase.value) * 0.25)
           .scaleEffect(1 - abs(phase.value) * 0.04)
   }
   ```

### API

```swift
public struct CraftLearningPath: View {
    public let sections: [LessonSection]
    public let rowPattern: RowPattern
    public let onNodeTap: ((LessonNodeModel) -> Void)?
    public let scrollToActive: Bool
    public let showCelebration: Bool

    // Single section convenience initializer
    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil,
        scrollToActive: Bool = true,
        showCelebration: Bool = true
    ) {
        self.init(
            sections: [section],
            rowPattern: rowPattern,
            onNodeTap: onNodeTap,
            scrollToActive: scrollToActive,
            showCelebration: showCelebration
        )
    }

    // Multi-section initializer
    public init(
        sections: [LessonSection],
        rowPattern: RowPattern = .standard,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil,
        scrollToActive: Bool = true,
        showCelebration: Bool = true
    ) {
        self.sections = sections
        self.rowPattern = rowPattern
        self.onNodeTap = onNodeTap
        self.scrollToActive = scrollToActive
        self.showCelebration = showCelebration
    }
}
```

---

## 7. Premium Animations — `CraftLearningPathAnimations.swift`

Centralized, reusable animation definitions and PhaseAnimator phases.

| Animation | API / Technique | Trigger | Reduce Motion Fallback |
|-----------|-----------------|---------|----------------------|
| **Active Glow Pulse** | `PhaseAnimator` (2 phases: normal, glowing) | state == `.active` | Static 2pt border highlight |
| **Active Icon Pulse** | `.symbolEffect(.pulse.byLayer)` | state == `.active` | Static icon |
| **Breathing Connector** | `PhaseAnimator` (2 phases: rest, inhale) | active → next connector | Static 2.5pt stroke |
| **Node Appear Stagger** | `.transition(.opacity.combined(with: .scale))` | Scroll entry / appear | Instant appear |
| **Scroll Transition** | `.scrollTransition(.animated)` | Scroll position | No scroll transform |
| **Completion Confetti** | `CraftSparkleView(.confetti)` | active → completed | Static "✓" badge |
| **Completion Bounce** | `.symbolEffect(.bounce)` | active → completed | No effect |
| **Badge Counter** | `.contentTransition(.numericText())` + `.symbolEffect(.bounce)` | badgeCount update | Instant text update |
| **Bonus Shimmer** | `ShimmerModifier` | state == `.bonus` | Static gold border |

---

## 8. Verification & Quality Gates

### Automated Tests
New test suite: `Tests/CraftUIKitTests/CraftLearningPathTests.swift`
- Model creation, equality, and hashable conformance.
- Row splitting algorithm across `.standard`, `.wave`, and `.custom` patterns.
- Bézier control point calculations.
- VoiceOver accessibility label, hint, and trait generation for all 6 states.
- Multi-section handling & empty state validation.

### Verification Matrix
- [ ] **HIG Compliance**: Minimum 44×44pt touch targets verified; VoiceOver reading order tested.
- [ ] **Dynamic Type**: Tested at default (`.large`) up to Accessibility Extra Extra Extra Large (`.accessibility5`).
- [ ] **Reduce Motion**: All `PhaseAnimator` loops and `symbolEffect`s cleanly fall back to static equivalents when enabled.
- [ ] **Dark Mode**: High-contrast borders and atmospheric gradients look crisp across light and dark appearances.
- [ ] **Performance Profile**: 120fps scrolling on 100+ nodes across multiple sections with zero layout churn.
- [ ] **Xcode Previews**: Isolated previews for each atom, molecule, section, and full path.
