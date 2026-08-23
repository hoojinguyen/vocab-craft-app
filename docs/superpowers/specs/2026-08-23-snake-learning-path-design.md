# Design Specification: CraftUIKit Snake Hybrid Learning Path & Dotted Connectors

- **Date**: 2026-08-23
- **Author**: Antigravity & Team
- **Component**: `CraftUIKit` (Learning Path & Tactile Journey System)
- **Status**: Validated & Ready for Planning

---

## 1. Overview & Problem Statement

### 1.1 Current State
In the current `CraftUIKit` implementation, learning path lesson nodes are rendered vertically in a single column or with minimal horizontal offsets (`SerpentineWinding`). Connectors are drawn as straight lines or crude Bézier curves that pass directly behind or over text labels and badges. This results in a rigid, crowded list feel rather than a playful, engaging gamified journey map.

### 1.2 Target Design & Inspiration
Inspired by modern gamified learning paths (e.g. Duolingo, Busuu, Memrise), the new system introduces a **Snake Hybrid Path Architecture**:
1. **Rhythmic Multi-Node Rows**: Alternating rows of 1 centered node and 2 horizontally spaced nodes in a continuous serpentine pattern `[1, 2, 1, 2, ...]`.
2. **Smooth Dotted Connectors with Hairpin Arcs**: Dotted line tracks (`● ● ● ●`) using vector rounded caps with consistent spacing, connected via straight horizontal links between adjacent nodes on the same row, and graceful $90^\circ$ circular fillet arcs ($R = 32\text{pt}$) at screen edges for row-to-row transitions.
3. **Design Tokens Integration**: Full color tokenization (`pathCompleted`, `pathActive`, `pathUpcoming`, `pathLocked`, `pathHaloGlow`) and dimension tokenization (`pathDotDiameter`, `pathDotSpacing`, `pathTurnRadius`) in `CraftColorTokens` and `CraftSpacingTokens`.
4. **Spacious Node Aesthetics**: Clear vertical separation ensuring text labels never collide with connectors, coupled with soft pastel halo glow cushions on active nodes.

---

## 2. Design Tokens Architecture

### 2.1 Color Tokens (`CraftColorTokens`)
Add the following properties to the `CraftColorTokens` protocol and its default implementation `CraftDefaultColorTokens`:

```swift
public protocol CraftColorTokens: Sendable {
    // ... Existing tokens ...

    // MARK: - Learning Path & Journey Tokens
    var pathCompleted: Color { get }
    var pathActive: Color { get }
    var pathUpcoming: Color { get }
    var pathLocked: Color { get }
    var pathHaloGlow: Color { get }
}

public extension CraftColorTokens {
    var pathCompleted: Color { statusSuccess }
    var pathActive: Color { brandPrimary }
    var pathUpcoming: Color { .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x475569)) }
    var pathLocked: Color { .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x27272A)) }
    var pathHaloGlow: Color { brandPrimary.opacity(0.20) }
}
```

### 2.2 Dimension & Spacing Tokens (`CraftSpacingTokens` / `CraftDimensionTokens`)
Add standard dimensions for learning path drawing:
- `pathDotDiameter`: `5.0 pt` (circular dot stroke width)
- `pathDotSpacing`: `7.0 pt` (inter-dot spacing)
- `pathTurnRadius`: `32.0 pt` (fillet corner arc radius for U-turns)
- `pathEdgeInset`: `28.0 pt` (outer margin from container bounds for turn apex)
- `pathRowSpacing`: `60.0 pt` (vertical spacing between successive rows to provide label clearance)

---

## 3. Data Models & Layout Engine

### 3.1 Node Slots and Row Models
```swift
/// Semantic slot position of a lesson node within a row.
public enum NodeSlot: String, Sendable, Equatable, Hashable {
    case center  // X ≈ 50%
    case left    // X ≈ 26%
    case right   // X ≈ 74%
}

/// A lesson node mapped to a specific slot and traversal order.
public struct PositionedLessonNode: Identifiable, Sendable, Equatable {
    public let node: LessonNodeModel
    public let slot: NodeSlot
    public let traversalIndex: Int

    public var id: String { node.id }

    public init(node: LessonNodeModel, slot: NodeSlot, traversalIndex: Int) {
        self.node = node
        self.slot = slot
        self.traversalIndex = traversalIndex
    }
}

/// Layout structure representing a single horizontal row on the snake map.
public struct SnakeRowLayout: Identifiable, Sendable, Equatable {
    public let id: String
    public let rowIndex: Int
    public let nodes: [PositionedLessonNode]

    public init(id: String, rowIndex: Int, nodes: [PositionedLessonNode]) {
        self.id = id
        self.rowIndex = rowIndex
        self.nodes = nodes
    }
}
```

### 3.2 Row Pattern Partitioning Algorithm
The default `RowPattern.standard` partitions nodes using a repeating `[1, 2]` rhythm with continuous serpentine routing:

```
Row 0: [Node 0 @ Center]
       ──(Right U-turn)──>
Row 1: [Node 2 @ Left] <──(Horizontal)── [Node 1 @ Right]
       <──(Left U-turn)──
Row 2: [Node 3 @ Center]
       ──(Right U-turn)──>
Row 3: [Node 5 @ Left] <──(Horizontal)── [Node 4 @ Right]
       ...
```

For any custom pattern `[c_0, c_1, ...]`:
- 1-node rows are placed at `.center`.
- 2-node rows are traversed in the natural snake direction (Right $\to$ Left if coming from right, Left $\to$ Right if coming from left).

---

## 4. Geometry & Routing Engine

### 4.1 Coordinate Normalization
Given a container width $W$ and measured node anchor points $(x_i, y_i)$:
- $X_{\text{center}} = W / 2$
- $X_{\text{left}} = W \times 0.26$
- $X_{\text{right}} = W \times 0.74$
- $X_{\text{turn\_right}} = W - \text{edgeInset}$
- $X_{\text{turn\_left}} = \text{edgeInset}$

### 4.2 Segment Path Types
For two sequential nodes $Node_A(x_1, y_1)$ and $Node_B(x_2, y_2)$:

1. **Horizontal Link (Same Row)**:
   - Line from $(x_1, y_1)$ to $(x_2, y_2)$.
2. **Right Hairpin Arc (Downwards right-side transition)**:
   - Line from $(x_1, y_1)$ horizontally right to $(X_{\text{turn\_right}} - R, y_1)$
   - $90^\circ$ Arc tangent to $(X_{\text{turn\_right}}, y_1)$ and $(X_{\text{turn\_right}}, y_1 + R)$ with radius $R$
   - Line vertically down to $(X_{\text{turn\_right}}, y_2 - R)$
   - $90^\circ$ Arc tangent to $(X_{\text{turn\_right}}, y_2)$ and $(X_{\text{turn\_right}} - R, y_2)$ with radius $R$
   - Line horizontally left to $(x_2, y_2)$.
3. **Left Hairpin Arc (Downwards left-side transition)**:
   - Line from $(x_1, y_1)$ horizontally left to $(X_{\text{turn\_left}} + R, y_1)$
   - $90^\circ$ Arc tangent to $(X_{\text{turn\_left}}, y_1)$ and $(X_{\text{turn\_left}}, y_1 + R)$ with radius $R$
   - Line vertically down to $(X_{\text{turn\_left}}, y_2 - R)$
   - $90^\circ$ Arc tangent to $(X_{\text{turn\_left}}, y_2)$ and $(X_{\text{turn\_left}} + R, y_2)$ with radius $R$
   - Line horizontally right to $(x_2, y_2)$.

### 4.3 Dotted Stroke Rendering
Vector path stroked with:
```swift
StrokeStyle(
    lineWidth: dotDiameter,
    lineCap: .round,
    lineJoin: .round,
    dash: [0, dotDiameter + dotSpacing]
)
```
This guarantees crisp, uniform circular dots across straight segments and curved arcs without distortion.

---

## 5. UI Components Hierarchy & Specifications

### 5.1 Component Structure
1. **`CraftLearningPath`**: Top-level scroll container with `ScrollViewReader`, background wash, celebration triggers, and auto-scroll to active node.
2. **`CraftLessonSectionView`**: Unit portal card header with title, subtitle, level capsule, progress metrics, and the underlying snake journey grid.
3. **`CraftSnakeConnectorLayer`**: Background layer tracking node anchor centers via `NodeAnchorPreferenceKey` and rendering styled dotted segments with progressive coloring.
4. **`CraftLessonRow`**: Horizontal layout container positioning 1 or 2 nodes at standardized slot fractions ($26\%, 50\%, 74\%$) with `pathRowSpacing`.
5. **`CraftLessonNode`**: Tactile 3D button atom with soft pastel glow halo, mechanical depress effect, status icons, and bottom-anchored text labels.

---

## 6. Verification & Test Plan

### 6.1 Unit Tests
1. **`RowPatternTests`**:
   - Verify `RowPattern.standard.layoutRows(nodes:)` handles empty, 1, 2, 3, 6, and 10 nodes correctly.
   - Verify traversal indices and assigned slots (`.center`, `.left`, `.right`).
2. **`SnakePathGeometryTests`**:
   - Verify calculation of horizontal, left hairpin, and right hairpin segments.
   - Verify arc tangents and edge boundary clamping.
3. **`TokenTests`**:
   - Verify dynamic light/dark values for `pathCompleted`, `pathActive`, `pathUpcoming`, and `pathLocked`.

### 6.2 Visual & Interactive Verification
1. **`CraftCatalogView`**:
   - Add a dedicated Snake Learning Path showcase with mixed completed, active, and locked nodes.
   - Test light & dark mode appearance.
   - Test accessibility Dynamic Type scaling.
