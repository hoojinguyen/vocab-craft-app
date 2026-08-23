# CraftLearningPath — Apple Tactile Serpentine Journey Spec

> **Version**: 2.0 (Tactile Redesign)  
> **Status**: Approved  
> **Target SDK**: iOS 17.0+ / macOS 14.0+ (Swift 5.9+)  
> **Design Philosophy**: Direction A (Apple Tactile Journey) — Rich 3D extrusion, physical depress mechanics, continuous sinusoidal serpentine winding, smart state-driven connectors, floating active callout bubbles, and interactive lesson sheets.

---

## 1. Executive Summary & Goals

The `CraftLearningPath` component provides a gamified, tactile learning journey for language acquisition in VocabCraft. Following a comprehensive design review under `ios-design-agent-skill` and `swiftui-design-skill`, this specification updates the component from a flat, rigid 2-node grid to a tactile, continuous 1-node serpentine winding path.

### Core Objectives
1. **True Serpentine Spatial Composition**: Replace symmetric multi-node grid rows with a continuous 1-node-per-step sinusoidal wave path ($X$-offset oscillating smoothly between $-45\%$ and $+45\%$).
2. **Tactile 3D Physicality**: Implement 3-layer 3D buttons (extrusion base, gradient top face, inner highlight reflection) with physical 4pt mechanical depression on tap and sensory haptic feedback.
3. **Typographic Information Hierarchy**: Render clear, visible lesson titles (`.system(.subheadline, design: .rounded, weight: .bold)`) and reward metadata (`+20 XP • 4 mins`) directly beneath each node.
4. **Active Callout Tooltip**: Provide a floating, bobbing speech bubble (`"TIẾP TỤC"` / `"START"`) above the active lesson node.
5. **Smart Dynamic Connectors**: Automatically determine connector style based on adjacent node states (`completed → completed`: Solid success line; `completed → active`: Breathing glow stroke; `active → upcoming`: Dashed brand stroke; `upcoming → locked`: Muted dashed line).
6. **Unit Portal Gateway Banner**: Transform the plain section header into a themed milestone portal card with level badges, descriptive subtitle, and progress metrics.
7. **Interactive Lesson Detail Sheet**: Display a rich bottom sheet modal upon node tap showing XP rewards, duration, vocabulary targets, and context-sensitive CTA buttons (`"BẮT ĐẦU HỌC"`, `"TIẾP TỤC"`, `"ÔN TẬP"`).
8. **Milestone & Treasure Chest Nodes**: Support special checkpoint nodes and end-of-unit treasure chests with shimmer and particle celebration.

---

## 2. Architecture & File Structure

```
CraftUIKit/Sources/CraftUIKit/
├── Models/
│   └── CraftLearningPathModels.swift         [UPDATED] Model definitions & Serpentine algorithms
├── Components/Containers/
│   ├── CraftLessonNode.swift                 [UPDATED] Tactile 3D node atom + label + callout bubble
│   ├── CraftNodeConnector.swift              [UPDATED] Bézier curve with smart state pair styling
│   ├── CraftLessonRow.swift                  [UPDATED] 1-node serpentine offset row molecule
│   ├── CraftLessonSectionView.swift          [UPDATED] Unit Portal Header + preference connector canvas
│   ├── CraftLessonDetailSheet.swift          [NEW]     Interactive bottom sheet for lesson info & CTAs
│   ├── CraftLearningPath.swift               [UPDATED] Root scrollable container with auto-scroll & sheet wiring
│   └── CraftLearningPathAnimations.swift     [UPDATED] PhaseAnimator tokens for breathing & bobbing
├── Previews/
│   └── CraftCatalogView.swift                [UPDATED] Interactive showcase with new tactile inspector
└── Tests/CraftUIKitTests/
    └── CraftLearningPathTests.swift          [UPDATED] Comprehensive unit test suite
```

---

## 3. Data Models (`CraftLearningPathModels.swift`)

### 3.1 `LessonNodeState`
```swift
public enum LessonNodeState: String, Sendable, Equatable, Hashable, CaseIterable {
    case completed      // Finished — statusSuccess 3D button + checkmark + stars
    case active         // Current lesson — brandPrimary 3D button + glowing ring + floating callout
    case inProgress     // Started not finished — surfaceElevated + progress arc rim
    case upcoming       // Next available — light surface + brand outline + ready to tap
    case locked         // Not unlocked — stone/matte surface + lock.fill + non-depressing
    case bonus          // Optional/challenge — gold radiant gradient + shimmer + star badge
}
```

### 3.2 `LessonNodeKind`
```swift
public enum LessonNodeKind: String, Sendable, Equatable, Hashable, CaseIterable {
    case standard       // Standard circular lesson node (56-64pt)
    case checkpoint     // Mid-unit or boss exam node (diamond or star hexagon shape)
    case treasureChest  // End-of-unit milestone reward chest with gold particles
}
```

### 3.3 `LessonNodeModel`
```swift
public struct LessonNodeModel: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?             // e.g. "15 từ mới • 4 phút"
    public let iconName: String             // SF Symbol name
    public let state: LessonNodeState
    public let kind: LessonNodeKind
    public let progress: Double?            // 0.0–1.0 for .inProgress
    public let xpReward: Int?               // e.g. 20 (XP)
    public let estimatedMinutes: Int?       // e.g. 5 (mins)
    public let stars: Int?                  // 0...3 mastery rating for completed
    public let badgeCount: Int?             // Badge counter
    public let badgeText: String?           // Custom badge (e.g. "HOT", "BOSS")

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        iconName: String = "book.fill",
        state: LessonNodeState = .upcoming,
        kind: LessonNodeKind = .standard,
        progress: Double? = nil,
        xpReward: Int? = nil,
        estimatedMinutes: Int? = nil,
        stars: Int? = nil,
        badgeCount: Int? = nil,
        badgeText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.state = state
        self.kind = kind
        self.progress = progress
        self.xpReward = xpReward
        self.estimatedMinutes = estimatedMinutes
        self.stars = stars
        self.badgeCount = badgeCount
        self.badgeText = badgeText
    }
}
```

### 3.4 `SerpentineWinding` & Layout Models
```swift
public enum SerpentineWinding: Sendable, Equatable {
    case standard           // Sequence: [0.0, -0.40, -0.55, -0.25, 0.0, 0.25, 0.55, 0.40]
    case gentle             // Sequence: [0.0, -0.25, -0.35, -0.15, 0.0, 0.15, 0.35, 0.25]
    case linear             // Sequence: [0.0]
    case custom([CGFloat])  // User-defined offset ratios (-1.0 to 1.0)

    public func offsetRatio(for index: Int) -> CGFloat {
        let sequence: [CGFloat] = switch self {
        case .standard:
            [0.0, -0.40, -0.55, -0.25, 0.0, 0.25, 0.55, 0.40]
        case .gentle:
            [0.0, -0.25, -0.35, -0.15, 0.0, 0.15, 0.35, 0.25]
        case .linear:
            [0.0]
        case .custom(let customSeq):
            customSeq.isEmpty ? [0.0] : customSeq
        }
        return sequence[index % sequence.count]
    }
}
```

### 3.5 `LessonSection`
```swift
public struct LessonSection: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let level: String?               // e.g. "LEVEL 1 • BEGINNER"
    public let progressText: String?        // e.g. "3/8 Bài học"
    public let progressValue: Double?       // 0.0–1.0 for unit progress bar
    public let bannerIcon: String?          // Header category icon
    public let nodes: [LessonNodeModel]
    public let winding: SerpentineWinding

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        level: String? = nil,
        progressText: String? = nil,
        progressValue: Double? = nil,
        bannerIcon: String? = nil,
        nodes: [LessonNodeModel],
        winding: SerpentineWinding = .standard
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.level = level
        self.progressText = progressText
        self.progressValue = progressValue
        self.bannerIcon = bannerIcon
        self.nodes = nodes
        self.winding = winding
    }
}
```

---

## 4. Tactile 3D Lesson Node Atom (`CraftLessonNode.swift`)

### 4.1 Tactile 3D Mechanics
- **Base Extrusion (`bottomRim`)**: A colored darker offset shadow ring (`depth: 5pt` unpressed, `1pt` pressed) rendered with matching hue + 25% black tint.
- **Top Face (`faceSurface`)**: A gradient circle overlaid with a 1.5pt white top inner highlight (`Color.white.opacity(0.35)`).
- **Physical Depress**: When pressed via a custom `ButtonStyle`, the top face moves down by `4pt`, aligning with the base rim.
- **Sensory Haptics**: Triggers `.sensoryFeedback(.impact(weight: .medium))` on press, `.sensoryFeedback(.error)` on locked tap.

### 4.2 Floating Active Callout Bubble
- Hovering 10pt above the `.active` node.
- Capsule shape with small downward-pointing caret triangle.
- Content: `"TIẾP TỤC"` with font `.caption.bold()`.
- PhaseAnimator bobbing loop: Vertical oscillation `y: -2pt ↔ +2pt` with `.easeInOut(duration: 1.2)`.

### 4.3 Visible Typography Labels
- Directly below the 3D node (spacing: 8pt):
  - **Title**: `Text(model.title)` with font `.system(.subheadline, design: .rounded, weight: .bold)`, lineLimit 2, aligned center.
  - **Subtitle / XP**: `Text(model.subtitle ?? "\(model.xpReward ?? 10) XP")` with font `.caption2`, foreground `theme.colors.textSecondary`.

---

## 5. Smart Dynamic Connectors (`CraftNodeConnector.swift`)

### 5.1 Smart State Determination
For any consecutive node pair $(Node_i, Node_{i+1})$:
- **`completed` → `completed`**: `SolidConnector(color: theme.colors.statusSuccess, lineWidth: 3.5)`
- **`completed` → `active` / `inProgress`**: `BreathingConnector(color: theme.colors.brandPrimary, lineWidth: 3.0)`
- **`active` → `upcoming` / `bonus`**: `DashedConnector(color: theme.colors.brandPrimary.opacity(0.6), lineWidth: 2.5)`
- **`upcoming` / `locked` → `locked`**: `MutedDashedConnector(color: theme.colors.borderDefault, lineWidth: 2.0)`

### 5.2 Bézier Geometry
- Uses cubic Bézier curve between $P_1(x_1, y_1)$ and $P_2(x_2, y_2)$:
  - $Control_1 = (x_1, y_1 + \Delta y \times 0.5)$
  - $Control_2 = (x_2, y_2 - \Delta y \times 0.5)$
- Curve clips cleanly under the tactile 3D nodes via `ZStack` layering (`connectors` rendered behind `nodes`).

---

## 6. Unit Portal Gateway Banner (`CraftLessonSectionView.swift`)

### 6.1 Visual Appearance
- **Container**: `VStack` with rounded corners `theme.radii.xl` (20pt) and 1pt hairline border.
- **Top Row**: Level badge (`Capsule` fill `brandPrimary.opacity(0.12)` + `.caption.smallCaps()`) and Unit Progress pill (`"3/8 HOÀN THÀNH"`).
- **Center Row**: Unit Title (`theme.typography.titleMedium`) and Unit Subtitle (`theme.typography.bodyMedium`).
- **Bottom Row**: Slim `CraftProgressBar` displaying `progressValue` with smooth gradient fill.
- **Trailing Icon**: Large decorative theme icon with 15% opacity watermark.

---

## 7. Interactive Lesson Detail Sheet (`CraftLessonDetailSheet.swift`)

### 7.1 Layout & Content
- Presentation via `.sheet(item: $selectedNode)` with `.presentationDetents([.fraction(0.42), .medium])`.
- **Icon Header**: Large 64pt tactile 3D icon matching node state.
- **Title & Badges**: Lesson title, state badge, XP pill (`+20 XP`), duration pill (`⏱ 4 phút`).
- **Description**: Target vocabulary summary and learning objectives.
- **Action Button (`CraftButton`)**:
  - `active` / `upcoming`: `"BẮT ĐẦU HỌC"` (`variant: .primary`, `size: .lg`)
  - `inProgress`: `"TIẾP TỤC HỌC (60%)"` (`variant: .primary`, `size: .lg`)
  - `completed`: `"ÔN TẬP LẠI (+5 XP)"` (`variant: .secondary`, `size: .lg`)
  - `locked`: `"BÀI HỌC ĐANG KHÓA"` (`isDisabled: true`)

---

## 8. Root Container & Integration (`CraftLearningPath.swift`)

### 8.1 Responsibilities
1. Holds `sections: [LessonSection]`.
2. Calculates overall active node ID and handles initial `ScrollViewReader` animated scroll with 300ms layout stabilization.
3. Manages `selectedNodeForDetail: LessonNodeModel?` state and presents `CraftLessonDetailSheet`.
4. Dispatches `onNodeTap: (LessonNodeModel) -> Void` and `onStartLesson: (LessonNodeModel) -> Void`.
5. Controls `showCelebration: Bool` confetti triggers on completion.

---

## 9. Accessibility, Dynamic Type & Performance

- **Tap Targets**: Minimum 44×44pt bounding box enforced via `.contentShape(Rectangle())`.
- **Dynamic Type**: Text labels reflow to 2 lines without clipping under `.accessibility1` through `.accessibility5`.
- **Reduce Motion**: All `PhaseAnimator` breathing loops and bobbing callout animations revert to clean static positions when `@Environment(\.accessibilityReduceMotion)` is true.
- **VoiceOver**: Complete accessibility labels (`"Bài học: \(title), Trạng thái: Đang học, 60% hoàn thành"`, Hint: `"Chạm hai lần để xem chi tiết bài học"`).
- **Performance (120fps)**: Section-scoped preference keys and lightweight geometry math ensure zero frame drops across 50+ nodes.

---

## 10. Verification Plan & Test Matrix

- **Unit Tests (`CraftLearningPathTests.swift`)**:
  - Model initialization, copy, and equality.
  - Serpentine offset calculation across `.standard`, `.gentle`, and `.linear` modes.
  - Smart connector state inference logic across all 6 states.
  - VoiceOver accessibility strings generation.
- **Interactive Catalog (`CraftCatalogView.swift`)**:
  - Live interactive node inspector testing all states, 3D button press, callout bubble, and detail sheet presentation.
- **Xcode Build & Tests**:
  - `swift test` execution ensuring 100% test pass rate.
