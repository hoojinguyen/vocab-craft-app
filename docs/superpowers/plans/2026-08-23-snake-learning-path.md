# Snake Hybrid Learning Path & Dotted Connectors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the CraftUIKit learning path into a modern Snake Hybrid journey map with rhythmic multi-node rows (`[1, 2, 1, 2]`), vector dotted line connectors (`● ● ●`) with $90^\circ$ circular hairpin turns ($R = 32\text{pt}$), tokenized progressive coloring, and refined node aesthetics.

**Architecture:** 
- **Tokens Layer:** Semantic colors (`pathCompleted`, `pathActive`, `pathUpcoming`, `pathLocked`, `pathHaloGlow`) and dimension tokens (`pathDotDiameter`, `pathDotSpacing`, `pathTurnRadius`, `pathEdgeInset`, `pathRowSpacing`) in `CraftTokens`.
- **Layout & Routing Engine:** `RowPattern.layoutRows` decomposes lessons into `SnakeRowLayout` with slot placement (`.center`, `.left`, `.right`). The geometry engine calculates exact horizontal links and left/right hairpin fillet arcs.
- **Connector Layer:** `CraftSnakeConnectorLayer` renders styled vector dotted paths between node anchor centers behind the node layer.
- **Node & Row Views:** `CraftLessonRow` and `CraftLessonNode` provide clean pastel glow styling, bottom-anchored text labels with zero path collision, and tactile feedback.

**Tech Stack:** Swift 6.0, SwiftUI, XCTest, SPM (Swift Package Manager).

**Spec:** [`docs/superpowers/specs/2026-08-23-snake-learning-path-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-23-snake-learning-path-design.md)

## Global Constraints
- Target iOS 17+, macOS 14+.
- Swift 6 strict concurrency compliance (`Sendable`, `@Sendable` closures).
- Zero external package dependencies outside of Foundation and SwiftUI.
- Fully compatible with Light Mode, Dark Mode, and Dynamic Type accessibility scaling.
- All existing public APIs must remain backward compatible.

---

### Task 1: Semantic Design Tokens for Learning Path

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftSpacingTokens.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/TokenTests.swift`

**Interfaces:**
- Produces:
  - `CraftColorTokens.pathCompleted: Color`
  - `CraftColorTokens.pathActive: Color`
  - `CraftColorTokens.pathUpcoming: Color`
  - `CraftColorTokens.pathLocked: Color`
  - `CraftColorTokens.pathHaloGlow: Color`
  - `CraftSpacingTokens.pathDotDiameter: CGFloat` (default: 5.0)
  - `CraftSpacingTokens.pathDotSpacing: CGFloat` (default: 7.0)
  - `CraftSpacingTokens.pathTurnRadius: CGFloat` (default: 32.0)
  - `CraftSpacingTokens.pathEdgeInset: CGFloat` (default: 28.0)
  - `CraftSpacingTokens.pathRowSpacing: CGFloat` (default: 60.0)

- [ ] **Step 1: Write the failing unit tests for new path tokens**

In `CraftUIKit/Tests/CraftUIKitTests/TokenTests.swift`, add:
```swift
func testLearningPathColorTokens() {
    let tokens = CraftDefaultColorTokens()
    XCTAssertNotNil(tokens.pathCompleted)
    XCTAssertNotNil(tokens.pathActive)
    XCTAssertNotNil(tokens.pathUpcoming)
    XCTAssertNotNil(tokens.pathLocked)
    XCTAssertNotNil(tokens.pathHaloGlow)
}

func testLearningPathSpacingAndDimensionTokens() {
    let spacing = CraftDefaultSpacingTokens()
    XCTAssertEqual(spacing.pathDotDiameter, 5.0)
    XCTAssertEqual(spacing.pathDotSpacing, 7.0)
    XCTAssertEqual(spacing.pathTurnRadius, 32.0)
    XCTAssertEqual(spacing.pathEdgeInset, 28.0)
    XCTAssertEqual(spacing.pathRowSpacing, 60.0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TokenTests`
Expected: Compile failure / missing members `pathCompleted`, `pathDotDiameter`, etc.

- [ ] **Step 3: Implement path color and spacing tokens**

In `CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift`:
```swift
public protocol CraftColorTokens: Sendable {
    // ...
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
Update `CraftDefaultColorTokens` struct with stored properties and defaults.

In `CraftUIKit/Sources/CraftUIKit/Tokens/CraftSpacingTokens.swift`:
```swift
public protocol CraftSpacingTokens: Sendable {
    // ...
    var pathDotDiameter: CGFloat { get }
    var pathDotSpacing: CGFloat { get }
    var pathTurnRadius: CGFloat { get }
    var pathEdgeInset: CGFloat { get }
    var pathRowSpacing: CGFloat { get }
}

public extension CraftSpacingTokens {
    var pathDotDiameter: CGFloat { 5.0 }
    var pathDotSpacing: CGFloat { 7.0 }
    var pathTurnRadius: CGFloat { 32.0 }
    var pathEdgeInset: CGFloat { 28.0 }
    var pathRowSpacing: CGFloat { 60.0 }
}
```
Update `CraftDefaultSpacingTokens` struct with stored properties and defaults.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TokenTests`
Expected: All tests pass.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift CraftUIKit/Sources/CraftUIKit/Tokens/CraftSpacingTokens.swift CraftUIKit/Tests/CraftUIKitTests/TokenTests.swift
git commit -m "feat(tokens): add semantic tokens for learning path and connectors"
```

---

### Task 2: Snake Path Data Models & Partitioning Algorithm

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Produces:
  - `enum NodeSlot: String, Sendable, Equatable, Hashable { case center, left, right }`
  - `struct PositionedLessonNode: Identifiable, Sendable, Equatable`
  - `struct SnakeRowLayout: Identifiable, Sendable, Equatable`
  - `RowPattern.layoutRows(nodes: [LessonNodeModel]) -> [SnakeRowLayout]`

- [ ] **Step 1: Write failing unit tests for `NodeSlot` and `RowPattern.layoutRows`**

In `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`, add:
```swift
func testSnakeRowLayoutStandardPattern() {
    let nodes = (0..<6).map {
        LessonNodeModel(id: "node_\($0)", title: "Lesson \($0)")
    }
    let rows = RowPattern.standard.layoutRows(nodes: nodes)
    
    // Row 0 (Count 1): Center
    XCTAssertEqual(rows.count, 4)
    XCTAssertEqual(rows[0].nodes.count, 1)
    XCTAssertEqual(rows[0].nodes[0].slot, .center)
    XCTAssertEqual(rows[0].nodes[0].traversalIndex, 0)
    
    // Row 1 (Count 2): Right then Left (traversal: Right first, then Left)
    XCTAssertEqual(rows[1].nodes.count, 2)
    XCTAssertEqual(rows[1].nodes[0].slot, .left)
    XCTAssertEqual(rows[1].nodes[1].slot, .right)
    XCTAssertEqual(rows[1].nodes[1].traversalIndex, 1) // First visited in row 1
    XCTAssertEqual(rows[1].nodes[0].traversalIndex, 2) // Second visited in row 1
    
    // Row 2 (Count 1): Center
    XCTAssertEqual(rows[2].nodes.count, 1)
    XCTAssertEqual(rows[2].nodes[0].slot, .center)
    XCTAssertEqual(rows[2].nodes[0].traversalIndex, 3)
    
    // Row 3 (Count 2): Left then Right (traversal: Right first, then Left)
    XCTAssertEqual(rows[3].nodes.count, 2)
    XCTAssertEqual(rows[3].nodes[1].traversalIndex, 4)
    XCTAssertEqual(rows[3].nodes[0].traversalIndex, 5)
}

func testSnakeRowLayoutSingleNodeAndEmpty() {
    let emptyRows = RowPattern.standard.layoutRows(nodes: [])
    XCTAssertTrue(emptyRows.isEmpty)
    
    let singleNode = [LessonNodeModel(id: "n0", title: "Intro")]
    let singleRows = RowPattern.standard.layoutRows(nodes: singleNode)
    XCTAssertEqual(singleRows.count, 1)
    XCTAssertEqual(singleRows[0].nodes.count, 1)
    XCTAssertEqual(singleRows[0].nodes[0].slot, .center)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter CraftLearningPathTests`
Expected: Compile failure / `NodeSlot` and `layoutRows` not defined.

- [ ] **Step 3: Implement `NodeSlot`, `PositionedLessonNode`, `SnakeRowLayout`, and `layoutRows`**

In `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift`:
```swift
// MARK: - NodeSlot

public enum NodeSlot: String, Sendable, Equatable, Hashable {
    case center
    case left
    case right

    public var xRatio: CGFloat {
        switch self {
        case .left: 0.26
        case .center: 0.50
        case .right: 0.74
        }
    }
}

// MARK: - PositionedLessonNode

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

// MARK: - SnakeRowLayout

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
Implement `RowPattern.layoutRows(nodes:)` to partition nodes into `[SnakeRowLayout]` according to the row counts and assign appropriate `.center`, `.left`, `.right` slots with traversal ordering.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: All tests pass.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(models): implement snake row layout and node slot mapping"
```

---

### Task 3: Hairpin Arcs Geometry & Snake Dotted Path Renderer

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftSnakePathGeometry.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Produces:
  - `enum SnakePathSegmentType: Sendable, Equatable { case horizontal, rightHairpin, leftHairpin }`
  - `struct SnakePathSegmentGeometry: Sendable, Equatable`
  - `struct CraftSnakeDottedSegmentView: View`
  - `struct CraftSnakeConnectorLayer: View`

- [ ] **Step 1: Write failing unit tests for geometry generation and path shapes**

In `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`, add:
```swift
func testSnakePathGeometrySegmentCalculations() {
    let p1 = CGPoint(x: 280, y: 100) // Right node
    let p2 = CGPoint(x: 100, y: 100) // Left node
    let horizontalSeg = SnakePathGeometry.createSegment(from: p1, to: p2, containerWidth: 380, turnRadius: 32, edgeInset: 28)
    XCTAssertEqual(horizontalSeg.type, .horizontal)
    
    let pCenter = CGPoint(x: 190, y: 50)
    let rightHairpinSeg = SnakePathGeometry.createSegment(from: pCenter, to: p1, containerWidth: 380, turnRadius: 32, edgeInset: 28)
    XCTAssertEqual(rightHairpinSeg.type, .rightHairpin)
    
    let pBottomCenter = CGPoint(x: 190, y: 200)
    let leftHairpinSeg = SnakePathGeometry.createSegment(from: p2, to: pBottomCenter, containerWidth: 380, turnRadius: 32, edgeInset: 28)
    XCTAssertEqual(leftHairpinSeg.type, .leftHairpin)
}

func testSnakePathDrawingProducesNonEmptyPath() {
    let seg = SnakePathSegmentGeometry(
        from: CGPoint(x: 190, y: 50),
        to: CGPoint(x: 280, y: 150),
        type: .rightHairpin,
        turnRadius: 32,
        turnX: 352
    )
    let path = seg.buildPath()
    XCTAssertFalse(path.isEmpty)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter CraftLearningPathTests`
Expected: Compile failure / `SnakePathGeometry` not found.

- [ ] **Step 3: Implement `CraftSnakePathGeometry.swift` and `CraftSnakeConnectorLayer`**

Create `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftSnakePathGeometry.swift`:
```swift
import SwiftUI

public enum SnakePathSegmentType: Sendable, Equatable {
    case horizontal
    case rightHairpin
    case leftHairpin
}

public struct SnakePathSegmentGeometry: Sendable, Equatable {
    public let from: CGPoint
    public let to: CGPoint
    public let type: SnakePathSegmentType
    public let turnRadius: CGFloat
    public let turnX: CGFloat

    public init(from: CGPoint, to: CGPoint, type: SnakePathSegmentType, turnRadius: CGFloat, turnX: CGFloat) {
        self.from = from
        self.to = to
        self.type = type
        self.turnRadius = turnRadius
        self.turnX = turnX
    }

    public func buildPath() -> Path {
        var path = Path()
        path.move(to: from)
        let r = max(4, turnRadius)

        switch type {
        case .horizontal:
            path.addLine(to: to)
        case .rightHairpin:
            let topTurnX = max(from.x, turnX - r)
            path.addLine(to: CGPoint(x: topTurnX, y: from.y))
            path.addArc(
                tangent1: CGPoint(x: turnX, y: from.y),
                tangent2: CGPoint(x: turnX, y: from.y + r),
                radius: r
            )
            path.addLine(to: CGPoint(x: turnX, y: to.y - r))
            path.addArc(
                tangent1: CGPoint(x: turnX, y: to.y),
                tangent2: CGPoint(x: turnX - r, y: to.y),
                radius: r
            )
            path.addLine(to: to)
        case .leftHairpin:
            let topTurnX = min(from.x, turnX + r)
            path.addLine(to: CGPoint(x: topTurnX, y: from.y))
            path.addArc(
                tangent1: CGPoint(x: turnX, y: from.y),
                tangent2: CGPoint(x: turnX, y: from.y + r),
                radius: r
            )
            path.addLine(to: CGPoint(x: turnX, y: to.y - r))
            path.addArc(
                tangent1: CGPoint(x: turnX, y: to.y),
                tangent2: CGPoint(x: turnX + r, y: to.y),
                radius: r
            )
            path.addLine(to: to)
        }
        return path
    }
}

public struct SnakePathGeometry {
    public static func createSegment(
        from: CGPoint,
        to: CGPoint,
        containerWidth: CGFloat,
        turnRadius: CGFloat,
        edgeInset: CGFloat
    ) -> SnakePathSegmentGeometry {
        if abs(from.y - to.y) < 15 {
            return SnakePathSegmentGeometry(
                from: from,
                to: to,
                type: .horizontal,
                turnRadius: turnRadius,
                turnX: from.x
            )
        }

        if to.x >= from.x || from.x <= containerWidth * 0.55 {
            let rightTurnX = containerWidth - edgeInset
            return SnakePathSegmentGeometry(
                from: from,
                to: to,
                type: .rightHairpin,
                turnRadius: turnRadius,
                turnX: rightTurnX
            )
        } else {
            let leftTurnX = edgeInset
            return SnakePathSegmentGeometry(
                from: from,
                to: to,
                type: .leftHairpin,
                turnRadius: turnRadius,
                turnX: leftTurnX
            )
        }
    }
}
```

In `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift`, add `CraftSnakeConnectorLayer` rendering with `StrokeStyle(lineWidth: dotDiameter, lineCap: .round, dash: [0, dotDiameter + dotSpacing])` and token progressive colors.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: All tests pass.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftSnakePathGeometry.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(connectors): implement hairpin arcs geometry and vector dotted path renderer"
```

---

### Task 4: Upgrade `CraftLessonRow` and `CraftLessonNode` Aesthetics

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonRow.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Produces:
  - `CraftLessonRow(rowLayout: SnakeRowLayout, onNodeTap: ...)`
  - Refined `CraftLessonNode` with soft aura glow, bottom-anchored typography labels with no connector collisions.

- [ ] **Step 1: Write failing unit test for `CraftLessonRow` with `SnakeRowLayout`**

In `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`, add:
```swift
func testCraftLessonRowWithSnakeRowLayout() {
    let pNode1 = PositionedLessonNode(
        node: LessonNodeModel(id: "n1", title: "Left Node"),
        slot: .left,
        traversalIndex: 1
    )
    let pNode2 = PositionedLessonNode(
        node: LessonNodeModel(id: "n2", title: "Right Node"),
        slot: .right,
        traversalIndex: 0
    )
    let layout = SnakeRowLayout(id: "row_1", rowIndex: 1, nodes: [pNode1, pNode2])
    let row = CraftLessonRow(rowLayout: layout)
    XCTAssertEqual(row.nodes.count, 2)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter CraftLearningPathTests`
Expected: Compile failure / `CraftLessonRow(rowLayout:)` not found.

- [ ] **Step 3: Update `CraftLessonRow.swift` and `CraftLessonNode.swift`**

In `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonRow.swift`:
- Add `public init(rowLayout: SnakeRowLayout, onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil)`.
- Use a flexible `HStack` / relative geometry placement where:
  - Single center node is aligned at 50% width.
  - Pair nodes are aligned at $26\%$ and $74\%$ width.
  - Apply `theme.spacing.pathRowSpacing` (60pt) vertical padding.
  - Set `NodeAnchorPreferenceKey` for each node's center.

In `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift`:
- Update active glow halo with `theme.colors.pathHaloGlow` and soft pastel radial gradient.
- Ensure node label stack has `maxWidth: 120` and `padding(.top, 6)` beneath the button atom.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: All tests pass.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonRow.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(ui): update CraftLessonRow for snake grid and refine node aesthetics"
```

---

### Task 5: Integrate Snake Hybrid Engine into `CraftLessonSectionView` and `CraftLearningPath`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

- [ ] **Step 1: Write integration tests for section and learning path rendering**

In `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`, add:
```swift
func testCraftLessonSectionViewSnakeRendering() {
    let nodes = [
        LessonNodeModel(id: "n1", title: "Greetings", state: .completed),
        LessonNodeModel(id: "n2", title: "Introductions", state: .completed),
        LessonNodeModel(id: "n3", title: "Numbers", state: .active),
        LessonNodeModel(id: "n4", title: "Verbs", state: .upcoming),
        LessonNodeModel(id: "n5", title: "Food", state: .locked)
    ]
    let section = LessonSection(id: "sec_1", title: "Unit 1", nodes: nodes)
    let sectionView = CraftLessonSectionView(section: section)
    XCTAssertNotNil(sectionView)
}
```

- [ ] **Step 2: Implement full integration in `CraftLessonSectionView.swift` and `CraftLearningPath.swift`**

- In `CraftLessonSectionView.swift`:
  - Calculate `let rowLayouts = section.rowPattern.layoutRows(nodes: section.nodes)`
  - Render rows in `VStack(spacing: theme.spacing.pathRowSpacing)`
  - Place `CraftSnakeConnectorLayer` in `.backgroundPreferenceValue(NodeAnchorPreferenceKey.self)`
- In `CraftCatalogView.swift`:
  - Update preview with the realistic multi-unit snake journey matching Screenshot 2.

- [ ] **Step 3: Run all unit tests across the entire package**

Run: `swift test`
Expected: 250+ tests pass with 0 failures.

- [ ] **Step 4: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(journey): integrate full snake hybrid learning path and update catalog previews"
```

---

### Task 6: Final Verification & Cleanup

**Files:**
- Test: Full package build and test run.

- [ ] **Step 1: Run complete test suite in release & debug modes**

Run: `swift test`
Expected: All tests pass.

- [ ] **Step 2: Build demo / package targets**

Run: `swift build`
Expected: Build complete with zero warnings and zero errors.

- [ ] **Step 3: Final git status check & commit if necessary**

```bash
git status
```
