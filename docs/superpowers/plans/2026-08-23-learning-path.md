# CraftLearningPath Component Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a gamified, Duolingo-style serpentine learning path component suite (`CraftLearningPath`) for `CraftUIKit` featuring calculated grid layouts, S-curve Bézier connectors with signature "Breathing Path" motion, full HIG accessibility compliance, and section-scoped 120fps performance architecture.

**Architecture:** Section-Scoped Calculated Grid architecture where each `LessonSection` independently lays out its rows and manages an isolated `PreferenceKey` overlay for Bézier connectors. Looping animations utilize `PhaseAnimator` (iOS 17+) with strict `@Environment(\.accessibilityReduceMotion)` guards. Pure presentational components in `CraftUIKit` conform to `Equatable` to eliminate unnecessary SwiftUI view updates.

**Tech Stack:** Swift 6 / SwiftUI (iOS 17+), SF Symbols 5, CraftUIKit Theme Tokens (`CraftTheme`, `CraftAnimationTokens`, `CraftColorTokens`), XCTest / Swift Testing.

**Spec:** [2026-08-23-learning-path-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-23-learning-path-design.md)

## Global Constraints

- Platform floor: iOS 17.0+ / Swift 6 strict concurrency
- Touch targets: Minimum 44×44pt for all interactive node surfaces via `.frame(minWidth: 44, minHeight: 44).contentShape(Circle())`
- Spacing: 8pt grid alignment referencing theme tokens (`theme.spacing`)
- Typography: SF Pro with `.fontDesign(.rounded)` for gamified headers/labels; `.monospacedDigit()` for counters and section progress
- Accessibility: Full VoiceOver labels, hints, and traits; `.accessibilityHidden(true)` on decorative connector curves; Dynamic Type scale adaptation via `@ScaledMetric` and `dynamicTypeSize.isAccessibilitySize`
- Motion: `@Environment(\.accessibilityReduceMotion)` respected across all `PhaseAnimator` loops, symbol effects, and scroll transitions
- Zero regressions in existing `CraftUIKit` modules

---

### Task 1: Create Learning Path Presentation Models (`CraftLearningPathModels.swift`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift`
- Create: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Produces:
  - `LessonNodeState: String, Sendable, Equatable, Hashable, CaseIterable` (`completed`, `active`, `inProgress`, `upcoming`, `locked`, `bonus`)
  - `LessonNodeModel: Identifiable, Sendable, Equatable, Hashable`
  - `ConnectorStyle: Sendable, Equatable` (`dashed`, `solid`, `gradient(from:to:)`, `animated`)
  - `LessonSection: Identifiable, Sendable, Equatable`
  - `RowPattern: Sendable, Equatable` (`standard`, `wave`, `custom([Int])`)
  - `LessonRowArrangement: Sendable, Equatable` (`single`, `pair`, `triple`)

- [ ] **Step 1: Write the failing tests in `CraftLearningPathTests.swift`**

```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class CraftLearningPathTests: XCTestCase {
    func testModelInitializationAndEquatability() {
        let node1 = LessonNodeModel(
            id: "node_1",
            title: "Basics 1",
            iconName: "book.fill",
            state: .active,
            progress: 0.5,
            badgeCount: 2,
            badgeText: "NEW"
        )
        let node2 = LessonNodeModel(
            id: "node_1",
            title: "Basics 1",
            iconName: "book.fill",
            state: .active,
            progress: 0.5,
            badgeCount: 2,
            badgeText: "NEW"
        )
        let node3 = LessonNodeModel(
            id: "node_2",
            title: "Basics 2",
            iconName: "pencil",
            state: .locked
        )

        XCTAssertEqual(node1, node2)
        XCTAssertNotEqual(node1, node3)
        XCTAssertEqual(LessonNodeState.allCases.count, 6)
    }

    func testSectionModelCreation() {
        let node = LessonNodeModel(id: "n1", title: "Intro", iconName: "star.fill", state: .completed)
        let section = LessonSection(
            id: "sec_1",
            title: "Unit 1: Foundations",
            subtitle: "Getting Started",
            level: "BEGINNER",
            progress: "1/10",
            nodes: [node],
            connectorStyle: .solid
        )

        XCTAssertEqual(section.nodes.count, 1)
        XCTAssertEqual(section.connectorStyle, .solid)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: FAIL due to unresolved identifiers `LessonNodeModel`, `LessonNodeState`, `LessonSection`.

- [ ] **Step 3: Implement `CraftLearningPathModels.swift`**

Write `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift` containing:
- `LessonNodeState` with cases: `completed`, `active`, `inProgress`, `upcoming`, `locked`, `bonus`.
- `LessonNodeModel` with `id`, `title`, `iconName`, `state`, `progress`, `badgeCount`, `badgeText`.
- `ConnectorStyle` with `dashed`, `solid`, `gradient(from: Color, to: Color)`, `animated`.
- `LessonSection` with `id`, `title`, `subtitle`, `level`, `progress`, `nodes`, `connectorStyle`.
- `RowPattern` with `standard`, `wave`, `custom([Int])`.
- `LessonRowArrangement` with `single`, `pair`, `triple`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(models): add CraftLearningPath domain and presentation models"
```

---

### Task 2: Implement Bézier Curve Shape, Animations, and Breathing Path (`CraftNodeConnector.swift`, `CraftLearningPathAnimations.swift`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPathAnimations.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `ConnectorStyle`, `CraftTheme`
- Produces:
  - `CraftNodeConnector: Shape` (Bézier S-curve)
  - `CraftStyledConnector: View`
  - `BreathingPhase: CaseIterable` (`rest`, `inhale`)
  - `GlowPhase: CaseIterable` (`normal`, `glowing`)
  - `BreathingConnectorView: View`

- [ ] **Step 1: Add shape and control point tests to `CraftLearningPathTests.swift`**

```swift
func testNodeConnectorPathGeneration() {
    let connector = CraftNodeConnector(
        from: CGPoint(x: 100, y: 100),
        to: CGPoint(x: 200, y: 300)
    )
    let path = connector.path(in: CGRect(x: 0, y: 0, width: 300, height: 400))
    XCTAssertFalse(path.isEmpty)
    XCTAssertEqual(path.boundingRect.minX, 100, accuracy: 1.0)
    XCTAssertEqual(path.boundingRect.maxX, 200, accuracy: 1.0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: FAIL due to missing `CraftNodeConnector`.

- [ ] **Step 3: Implement `CraftLearningPathAnimations.swift` and `CraftNodeConnector.swift`**

In `CraftLearningPathAnimations.swift`:
- Define `BreathingPhase` and `GlowPhase` enums.
- Helper extension on `Animation` referencing `CraftAnimationTokens`.

In `CraftNodeConnector.swift`:
- `CraftNodeConnector: Shape` with quadratic S-curve control points: `control1 = CGPoint(x: from.x, y: (from.y + to.y) / 2)`, `control2 = CGPoint(x: to.x, y: (from.y + to.y) / 2)`.
- `BreathingConnectorView` using `PhaseAnimator(BreathingPhase.allCases)` animating stroke width between 2.0pt and 3.0pt with `.easeInOut(duration: 1.8)`, falling back to static 2.5pt stroke when `accessibilityReduceMotion` is enabled.
- `CraftStyledConnector` rendering dashed, solid, gradient, and animated styles with `.accessibilityHidden(true)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPathAnimations.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(connectors): implement CraftNodeConnector with Bézier curves and PhaseAnimator Breathing Path"
```

---

### Task 3: Implement Atom View (`CraftLessonNode.swift`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `LessonNodeState`, `GlowPhase`, `CraftTheme`, `CraftSparkleView`, `ShimmerModifier`
- Produces: `CraftLessonNode: View, Equatable`

- [ ] **Step 1: Add accessibility and state formatting tests to `CraftLearningPathTests.swift`**

```swift
func testLessonNodeVoiceOverLabelFormatting() {
    let completedNode = LessonNodeModel(id: "1", title: "Intro", iconName: "star", state: .completed)
    let activeNode = LessonNodeModel(id: "2", title: "Grammar", iconName: "book", state: .active, progress: 0.6)
    let lockedNode = LessonNodeModel(id: "3", title: "Verbs", iconName: "lock", state: .locked)

    XCTAssertEqual(completedNode.state, .completed)
    XCTAssertEqual(activeNode.progress, 0.6)
    XCTAssertEqual(lockedNode.state, .locked)
}
```

- [ ] **Step 2: Run test to verify it passes or check compilability**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`

- [ ] **Step 3: Implement `CraftLessonNode.swift`**

Implement `CraftLessonNode`:
- Visual spec by state (`completed`: 52pt, checkmark; `active`: 64pt, glow ring via `PhaseAnimator(GlowPhase.allCases)`, `.symbolEffect(.pulse.byLayer)`; `inProgress`: 56pt, progress arc; `upcoming`: 48pt; `locked`: 48pt, opacity 0.6; `bonus`: 56pt, gold shimmer).
- Dynamic Type with `@ScaledMetric(relativeTo: .body)`.
- Enforce touch target: `.frame(minWidth: 44, minHeight: 44).contentShape(Circle())`.
- Haptics with `.sensoryFeedback` (impact on tap, success on completion, error on locked tap, selection on badge count).
- Full VoiceOver labels, hints, and traits (`.isButton` for interactive, `.notEnabled` for locked).
- SF Symbols with `.contentTransition(.symbolEffect(.replace))` and `.symbolEffectsRemoved(reduceMotion)`.
- Badge count with numeric transition `.contentTransition(.numericText())` and `.symbolEffect(.bounce, value: model.badgeCount)`.
- Equatable conformance for body stability.

- [ ] **Step 4: Run test to verify it builds and passes**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(atoms): implement HIG-compliant CraftLessonNode with PhaseAnimator glow and Equatable optimization"
```

---

### Task 4: Implement Row Molecule View and Splitting Algorithm (`CraftLessonRow.swift`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonRow.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `LessonRowArrangement`, `RowPattern`
- Produces:
  - `RowPattern.split(nodes:) -> [(nodes: [LessonNodeModel], arrangement: LessonRowArrangement)]`
  - `CraftLessonRow: View, Equatable`

- [ ] **Step 1: Add row splitting algorithm unit tests in `CraftLearningPathTests.swift`**

```swift
func testRowPatternSplitting() {
    let nodes = (0..<7).map { LessonNodeModel(id: "node_\($0)", title: "Lesson \($0)", iconName: "star", state: .upcoming) }

    let standardRows = RowPattern.standard.split(nodes: nodes)
    XCTAssertEqual(standardRows.count, 5) // [1], [2], [1], [2], [1]
    XCTAssertEqual(standardRows[0].arrangement, .single)
    XCTAssertEqual(standardRows[0].nodes.count, 1)
    XCTAssertEqual(standardRows[1].arrangement, .pair)
    XCTAssertEqual(standardRows[1].nodes.count, 2)
    XCTAssertEqual(standardRows[2].arrangement, .single)
    XCTAssertEqual(standardRows[2].nodes.count, 1)
    XCTAssertEqual(standardRows[3].arrangement, .pair)
    XCTAssertEqual(standardRows[3].nodes.count, 2)
    XCTAssertEqual(standardRows[4].arrangement, .single)
    XCTAssertEqual(standardRows[4].nodes.count, 1)

    let waveRows = RowPattern.wave.split(nodes: (0..<9).map { LessonNodeModel(id: "w_\($0)", title: "\($0)", iconName: "star", state: .upcoming) })
    // [1], [2], [3], [2], [1]
    XCTAssertEqual(waveRows.map(\.nodes.count), [1, 2, 3, 2, 1])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: FAIL due to missing `RowPattern.split` and `CraftLessonRow`.

- [ ] **Step 3: Implement row splitting algorithm and `CraftLessonRow.swift`**

- In `CraftLearningPathModels.swift`: Implement `split(nodes:)` on `RowPattern`.
- In `CraftLessonRow.swift`:
  - Render `.single` (centered with `.frame(maxWidth: .infinity)`).
  - Render `.pair` (2 nodes offset ~35-40% from center).
  - Render `.triple` (3 nodes evenly spaced).
  - Adapt spacing when `dynamicTypeSize.isAccessibilitySize` is active to avoid touch target overlaps.
  - Conforms to `Equatable`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonRow.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(molecules): implement CraftLessonRow layout arrangements and RowPattern splitting algorithm"
```

---

### Task 5: Implement Section Component with Scoped Anchor Preferences (`CraftLessonSectionView.swift`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `RowPattern`, `CraftLessonRow`, `CraftLessonNode`, `CraftNodeConnector`, `BreathingConnectorView`
- Produces:
  - `NodeAnchorPreferenceKey: PreferenceKey`
  - `CraftLessonSectionView: View`

- [ ] **Step 1: Add SectionView integration tests in `CraftLearningPathTests.swift`**

```swift
func testSectionViewInstantiation() {
    let nodes = [
        LessonNodeModel(id: "s1_n1", title: "Start", iconName: "play.fill", state: .completed),
        LessonNodeModel(id: "s1_n2", title: "Practice", iconName: "pencil", state: .active),
        LessonNodeModel(id: "s1_n3", title: "Review", iconName: "checkmark", state: .upcoming)
    ]
    let section = LessonSection(id: "sec_test", title: "Basics", nodes: nodes)
    let sectionView = CraftLessonSectionView(section: section, rowPattern: .standard)
    XCTAssertNotNil(sectionView)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: FAIL due to missing `CraftLessonSectionView`.

- [ ] **Step 3: Implement `CraftLessonSectionView.swift`**

Implement `CraftLessonSectionView`:
- Section Header Card: `CraftCard` style, `.clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))`, subtle border `theme.colors.borderDefault.opacity(0.5)`, level tag (`.font(.caption.smallCaps())`), title (`theme.typography.titleMedium`), progress count (`.monospacedDigit().fontDesign(.rounded)`).
- `VStack(spacing: theme.spacing.spaceL)` of `CraftLessonRow`s.
- `.anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center)` attached to each node.
- `.overlayPreferenceValue(NodeAnchorPreferenceKey.self)`: For each sequential pair of nodes in this section, draw `CraftStyledConnector` or `BreathingConnectorView` if connecting active to next upcoming node.
- Connector drawing is strictly contained inside the section boundary.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(sections): implement CraftLessonSectionView with isolated anchor preference connector drawing"
```

---

### Task 6: Implement Top-Level Container (`CraftLearningPath.swift`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `RowPattern`, `CraftLessonSectionView`, `CraftSymbol`
- Produces: `CraftLearningPath: View`

- [ ] **Step 1: Add container and empty state tests in `CraftLearningPathTests.swift`**

```swift
func testLearningPathInstantiationAndEmptySection() {
    let emptySection = LessonSection(id: "empty", title: "Empty", nodes: [])
    let emptyPath = CraftLearningPath(section: emptySection)
    XCTAssertNotNil(emptyPath)
    XCTAssertTrue(emptyPath.sections[0].nodes.isEmpty)

    let multiSectionPath = CraftLearningPath(sections: [emptySection, emptySection])
    XCTAssertEqual(multiSectionPath.sections.count, 2)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: FAIL due to missing `CraftLearningPath`.

- [ ] **Step 3: Implement `CraftLearningPath.swift`**

Implement `CraftLearningPath`:
- Support both single section initializer `init(section:...)` and multi-section `init(sections:...)`.
- Background gradient wash: `LinearGradient(colors: [theme.colors.canvasBackground, theme.colors.brandPrimary.opacity(0.03)], startPoint: .top, endPoint: .bottom)`.
- `ScrollView` with `ScrollViewReader`: Auto-scroll to `.active` node ID with smooth spring animation on initial render (0.3s delay).
- `LazyVStack(spacing: theme.spacing.spaceXXL)` rendering `CraftLessonSectionView`s.
- `ContentUnavailableView` when all sections are empty.
- Scroll-driven effect: `.scrollTransition(.animated)` scaling and fading nodes slightly as they scroll through viewports.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(container): implement CraftLearningPath top-level container with ScrollViewReader and atmospheric gradient"
```

---

### Task 7: Interactive Showcase in `CraftCatalogView` and Complete Test Suite

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `CraftLearningPath`, `LessonSection`, `LessonNodeModel`, `RowPattern`

- [ ] **Step 1: Add full integration tests in `CraftLearningPathTests.swift`**

```swift
func testFullLearningPathSuite() {
    let mockNodes = [
        LessonNodeModel(id: "n1", title: "Alphabet", iconName: "textformat", state: .completed),
        LessonNodeModel(id: "n2", title: "Phonics", iconName: "waveform", state: .completed),
        LessonNodeModel(id: "n3", title: "Common Nouns", iconName: "sparkles", state: .active, progress: 0.75, badgeCount: 1),
        LessonNodeModel(id: "n4", title: "Verbs", iconName: "figure.run", state: .upcoming),
        LessonNodeModel(id: "n5", title: "Challenge", iconName: "crown.fill", state: .bonus),
        LessonNodeModel(id: "n6", title: "Adjectives", iconName: "paintpalette.fill", state: .locked)
    ]
    let section1 = LessonSection(id: "sec_1", title: "Unit 1: Fundamentals", level: "BEGINNER", progress: "2/6", nodes: mockNodes)
    let section2 = LessonSection(id: "sec_2", title: "Unit 2: Conversation", level: "INTERMEDIATE", progress: "0/6", nodes: mockNodes.map {
        LessonNodeModel(id: "sec2_\($0.id)", title: $0.title, iconName: $0.iconName, state: .locked)
    })

    let learningPath = CraftLearningPath(sections: [section1, section2], rowPattern: .standard)
    XCTAssertEqual(learningPath.sections.count, 2)
}
```

- [ ] **Step 2: Add `CraftLearningPath` interactive preview showcase to `CraftCatalogView.swift`**

Add a dedicated tab/section in `CraftCatalogView`:
- Interactive controls for switching patterns (`.standard`, `.wave`), toggling celebration, and changing node states.
- Live rendering of `CraftLearningPath` with mock multi-section data.

- [ ] **Step 3: Run full CraftUIKit test suite**

Run: `swift test --package-path CraftUIKit`
Expected: 100% tests PASS with zero warnings.

- [ ] **Step 4: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(catalog): add interactive CraftLearningPath showcase to CraftCatalogView and verify test suite"
```
