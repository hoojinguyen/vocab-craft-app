# CraftLearningPath — Design Specification

> Duolingo-style serpentine learning journey path component for CraftUIKit.

## Background

The app needs a visual learning path UI where lesson nodes are arranged in a zigzag serpentine pattern with curved connectors. This is a common pattern in language learning apps (Duolingo, Babbel) that provides a gamified, visually engaging progression experience.

No existing open-source SwiftUI library provides this layout. The existing `CraftStepNode` is a simple vertical linear stepper — completely different. This spec defines a new, independent component system.

## Approach

**Calculated Grid** (Approach A): VStack/HStack-based layout with connector curves drawn as an overlay via `PreferenceKey` position collection. Chosen over Custom Layout Protocol (too complex) and Full Canvas Drawing (loses SwiftUI benefits and accessibility).

## File Structure

```
CraftUIKit/Sources/CraftUIKit/
├── Models/
│   └── CraftLearningPathModels.swift       [NEW]
├── Components/Containers/
│   ├── CraftNodeConnector.swift            [NEW]
│   ├── CraftLessonNode.swift               [NEW]
│   ├── CraftLessonRow.swift                [NEW]
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
- `inProgress` distinct from `active`: shows partial progress ring
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
    public let from: CGPoint
    public let to: CGPoint

    public func path(in rect: CGRect) -> Path
}
```

Control point calculation for natural S-curve:
```
control1 = CGPoint(x: from.x, y: (from.y + to.y) / 2)
control2 = CGPoint(x: to.x,   y: (from.y + to.y) / 2)
```

### `CraftStyledConnector` (View)

Renders a `CraftNodeConnector` with one of 4 styles:

- **Dashed**: `StrokeStyle(lineWidth: 2, dash: [4, 4])`, color `borderDefault`
- **Solid**: `StrokeStyle(lineWidth: 2.5, lineCap: .round)`, color varies by state (`statusSuccess` for completed, `borderDefault` for locked/upcoming)
- **Gradient**: `LinearGradient` stroke with custom from/to colors
- **Animated**: `TimelineView(.animation)` + `Canvas` drawing 3 dots flowing along the Bézier path at ~0.5 cycles/sec. Guarded by environment flag `prefersReducedConnectorAnimation` for performance on older devices.

---

## 3. Atoms — `CraftLessonNode.swift`

Individual circular node view.

### Visual Spec by State

| State | Size | Background | Border/Ring | Icon | Extra |
|-------|------|-----------|-------------|------|-------|
| `completed` | 52pt | `statusSuccess` | none | `checkmark` white | — |
| `active` | 64pt | `brandPrimary` | Outer glow ring 72pt, pulsing scale 1.0↔1.08, opacity 0.2↔0.45 | Custom icon, white | Glow shadow |
| `inProgress` | 56pt | `surfaceElevated` | Progress ring arc overlay (lineWidth: 3) | Custom icon, brand color | Shows progress |
| `upcoming` | 48pt | `surfaceSubtle` | `borderDefault` 1.5pt stroke | Custom icon, `textMuted` | — |
| `locked` | 48pt | `surfaceSubtle` | `borderDefault` 1.5pt stroke | `lock.fill`, `textMuted` | Opacity 0.6 |
| `bonus` | 56pt | `accent` gold | Shimmer sweep via `ShimmerModifier` | `star.fill` or custom, white | Gold glow |

### Badge Count

When `badgeCount != nil`: 18pt circle at top-trailing, `statusDanger` fill, white bold text.

### Label

`theme.typography.bodyMedium` text below node, `textPrimary` for most states, `textMuted` for locked.

### Interaction

- Tappable states: completed, active, inProgress, upcoming, bonus → calls `onTap`
- Locked: button disabled, shows lock icon
- Press effect: `.buttonStyle(.craftPress(scale: 0.93))`
- Sizes: `@ScaledMetric(relativeTo: .body)` for Dynamic Type

### API

```swift
public struct CraftLessonNode: View {
    public let model: LessonNodeModel
    public let onTap: (() -> Void)?

    public init(model: LessonNodeModel, onTap: (() -> Void)? = nil)
}
```

---

## 4. Molecules — `CraftLessonRow.swift`

A horizontal row containing 1–3 nodes.

### Layout

- **Single**: Node centered
- **Pair**: 2 nodes at ~40% offset from center on each side
- **Triple**: 3 nodes evenly distributed

### Row Splitting Algorithm

`CraftLearningPath` splits flat `[LessonNodeModel]` into rows using `RowPattern`:

```
.standard:  7 nodes → [1], [2], [1], [2], [1]
.wave:      9 nodes → [1], [2], [3], [2], [1]
.custom([1,2,1,3]): repeats the pattern as needed
```

### API

```swift
public struct CraftLessonRow: View {
    public let nodes: [LessonNodeModel]
    public let arrangement: LessonRowArrangement
    public let onNodeTap: ((LessonNodeModel) -> Void)?
}
```

---

## 5. Organisms — `CraftLearningPath.swift`

Top-level container assembling the full scrollable journey.

### Internal Structure

1. **Section header** — CraftCard-style card showing level, title, progress
2. **VStack** of `CraftLessonRow` views
3. **Connector overlay** — `PreferenceKey` collects node center positions via `.anchorPreference`; parent reads these in `overlayPreferenceValue` to draw `CraftStyledConnector` between consecutive nodes
4. **ScrollViewReader** — Auto-scrolls to first `.active` node on appear (0.3s delay)

### PreferenceKey for Node Positions

```swift
struct NodeAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGPoint>] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}
```

### API

```swift
public struct CraftLearningPath: View {
    public let section: LessonSection
    public let rowPattern: RowPattern
    public let onNodeTap: ((LessonNodeModel) -> Void)?
    public let scrollToActive: Bool
    public let showCelebration: Bool

    public init(
        section: LessonSection,
        rowPattern: RowPattern = .standard,
        onNodeTap: ((LessonNodeModel) -> Void)? = nil,
        scrollToActive: Bool = true,
        showCelebration: Bool = true
    )
}
```

---

## 6. Premium Animations — `CraftLearningPathAnimations.swift`

Extracted animation helpers for maintainability.

| Animation | Trigger | Detail | Reduce Motion Fallback |
|-----------|---------|--------|----------------------|
| Active Glow Pulse | state == `.active` | Ring scale 1.0↔1.08, opacity 0.2↔0.45, `springBouncy` repeating | Static highlighted border |
| Node Appear Stagger | ScrollView entry | Scale 0.3→1.0 + fade, delay = index × 0.08s, `springSmooth` | Instant appear |
| Completion Confetti | active→completed | Reuse `CraftSparkleView(.confetti)` overlay on completed node | Static "✓" text badge |
| Path Fill Sweep | Node completes | Connector animates dashed→solid with gradient sweep | Instant style change |
| Badge Bounce | badgeCount changes | Scale 1.0→1.3→1.0, `springBouncy` | No animation |
| Bonus Shimmer | state == `.bonus` | Reuse existing `ShimmerModifier`, gold sweep | Static gold border |

All animations respect `accessibilityReduceMotion`.

---

## Accessibility

| Feature | Implementation |
|---------|---------------|
| VoiceOver labels | "Lesson: {title}, {state}. {progress}% complete" |
| VoiceOver hints | Tappable: "Double tap to start this lesson" / Locked: "Lesson locked" |
| Reduce Motion | All animations disabled; static visual indicators |
| Dynamic Type | Node sizes via `@ScaledMetric`; labels use theme typography |
| Min touch target | All tappable nodes: 44×44pt content shape minimum |

---

## Verification

### Build
```bash
cd /Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit && swift build
```

### Tests
New file: `Tests/CraftUIKitTests/CraftLearningPathTests.swift`
- Model creation and equatable conformance
- Row splitting algorithm for all patterns
- Connector control point calculation
- Accessibility label generation
- Edge cases: empty section, single node, all locked

### Manual
- Xcode Preview for each component in isolation
- Full path preview with mixed states
- Scroll performance with 50+ nodes
- Dark mode
- Dynamic Type at accessibility sizes
- Reduce Motion behavior
