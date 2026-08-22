# CraftUIKit Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and integrate `CraftUIKit` (Phase 2) — specialized, interactive, and motion-heavy components including multi-segment ratio bars (`CraftSegmentedBar`), 3D flip containers (`CraftFlipCard`), quiz option choice cards (`CraftChoiceCard`), progression roadmap milestone nodes (`CraftStepNode`), liquid glass floating tab bar (`CraftFloatingTabBar`), audio waveform visualizers (`CraftWaveformView`), celebration sparkle/confetti particle FX (`CraftSparkleView`), 3-2-1 countdown overlays (`CraftCountdownOverlay`), catalog showcase updates, and app feature migrations.

**Architecture:** Extends the standalone `CraftUIKit` package with advanced SwiftUI components and modifiers conforming to `@Environment(\.craftTheme)`, strict `Sendable` value types, Apple HIG accessibility compliance, and zero domain coupling.

**Tech Stack:** Swift 5.10+, iOS 17+, macOS 14+, SwiftUI, SPM, XCTest.

**Spec:** [docs/superpowers/specs/2026-08-22-craftuikit-design-system-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-22-craftuikit-design-system-design.md)

## Global Constraints

- **Zero Domain Coupling:** No references to vocabulary, decks, flashcards, or app business logic inside `CraftUIKit`.
- **Pure SwiftUI & Standard Library:** Zero external third-party dependencies in `CraftUIKit`.
- **Theme Swappability:** All components MUST read colors, typography, radii, shadows, and animations from `@Environment(\.craftTheme)`.
- **Platform Support:** iOS 17.0+, macOS 14.0+.
- **Touch Target:** All interactive controls must satisfy Apple HIG 44pt minimum touch target.
- **Accessibility & Motion:** Particle and 3D animations must respect `@Environment(\.accessibilityReduceMotion)`.

---

### Task 1: Metrics & Progression (CraftSegmentedBar & CraftStepNode)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftSegmentedBar.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepNode.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/MetricsProgressionTests.swift`

**Interfaces:**
- Produces:
  - `CraftSegmentItem(id: String, label: String, value: Double, color: Color)`
  - `CraftSegmentedBar(items: [CraftSegmentItem], height: CGFloat, cornerRadius: CGFloat, showLegend: Bool, showPercentages: Bool)`
  - `CraftStepState`: `.completed`, `.active`, `.locked`, `.upcoming`
  - `CraftStepNode(title: String, subtitle: String?, state: CraftStepState, stepNumber: Int?, isLast: Bool, onTap: (() -> Void)?)`

- [ ] **Step 1: Write failing unit tests for Metrics & Progression**

Create `CraftUIKit/Tests/CraftUIKitTests/MetricsProgressionTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class MetricsProgressionTests: XCTestCase {
    func testSegmentedBarTotalAndRatios() {
        let items = [
            CraftSegmentItem(id: "1", label: "A", value: 30, color: .red),
            CraftSegmentItem(id: "2", label: "B", value: 70, color: .blue)
        ]
        let bar = CraftSegmentedBar(items: items)
        XCTAssertEqual(bar.totalValue, 100)
        XCTAssertEqual(bar.ratio(for: items[0]), 0.3)
        XCTAssertEqual(bar.ratio(for: items[1]), 0.7)
    }

    func testStepNodeStates() {
        let completed = CraftStepNode(title: "Stage 1", state: .completed, stepNumber: 1)
        XCTAssertEqual(completed.state, .completed)
        XCTAssertEqual(completed.stepNumber, 1)
        XCTAssertFalse(completed.isLast)
    }
}
```

- [ ] **Step 2: Run test to verify it fails (Red)**

Run: `swift test --package-path CraftUIKit --filter MetricsProgressionTests`
Expected: FAIL with compilation errors.

- [ ] **Step 3: Implement `CraftSegmentedBar.swift` and `CraftStepNode.swift`**

Implement:
- `CraftSegmentedBar.swift`: Proportional multi-color segmented progress bar with animated widths, safe zero-division fallbacks, optional legend chips with formatted percentages, and accessible value descriptors.
- `CraftStepNode.swift`: Vertical/horizontal roadmap milestone node with circle badges (checkmark for `.completed`, glowing ripple ring for `.active`, padlock for `.locked`, number badge for `.upcoming`), connector stroke lines (solid for completed/active, dashed for locked), title/subtitle slots, and 44pt touch target.

- [ ] **Step 4: Run test and verify it passes (Green)**

Run: `swift test --package-path CraftUIKit --filter MetricsProgressionTests`
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): implement CraftSegmentedBar and CraftStepNode"
```

---

### Task 2: Interactive 3D & Quiz Cards (CraftFlipCard & CraftChoiceCard)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Produces:
  - `CraftFlipCard(isFlipped: Binding<Bool>, axis: Axis, front: () -> Front, back: () -> Back)`
  - `CraftChoiceState`: `.idle`, `.selected`, `.correct`, `.wrong`, `.disabled`
  - `CraftChoiceCard(prefix: String?, title: String, subtitle: String?, state: CraftChoiceState, action: () -> Void)`

- [ ] **Step 1: Write failing unit tests for Interactive & Quiz Cards**

Create `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class InteractiveCardTests: XCTestCase {
    func testChoiceCardInitializersAndStates() {
        var tapped = false
        let card = CraftChoiceCard(prefix: "A", title: "Option 1", state: .correct) {
            tapped = true
        }
        XCTAssertEqual(card.prefix, "A")
        XCTAssertEqual(card.title, "Option 1")
        XCTAssertEqual(card.state, .correct)
        card.action()
        XCTAssertTrue(tapped)
    }

    func testFlipCardBinding() {
        var flipped = false
        let binding = Binding(get: { flipped }, set: { flipped = $0 })
        let flipCard = CraftFlipCard(isFlipped: binding) {
            Text("Front")
        } back: {
            Text("Back")
        }
        XCTAssertFalse(flipCard.isFlipped)
    }
}
```

- [ ] **Step 2: Run test to verify it fails (Red)**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`
Expected: FAIL.

- [ ] **Step 3: Implement `CraftFlipCard.swift` and `CraftChoiceCard.swift`**

Implement:
- `CraftFlipCard.swift`: Composable 3D rotation container using `.rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: ...)` with spring animation, double-sided render, back-face culling opacity, and tactile haptics.
- `CraftChoiceCard.swift`: Quiz option card supporting `A/B/C/D` prefix squircle, title, subtitle, status icon indicator, spring scale pop on `.correct`, horizontal shake animation modifier on `.wrong`, and `.disabled` opacity.

- [ ] **Step 4: Run test and verify it passes (Green)**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): implement CraftFlipCard and CraftChoiceCard"
```

---

### Task 3: Navigation & Liquid Glass (CraftFloatingTabBar)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`

**Interfaces:**
- Produces:
  - `CraftTabItemProtocol: Identifiable, Equatable`
  - `CraftFloatingTabBar(selectedItem: Binding<Item>, items: [Item], centerAction: (() -> Void)?)`

- [ ] **Step 1: Write failing unit tests for Navigation**

Create `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

struct SampleTab: CraftTabItemProtocol {
    let id: Int
    let title: String
    let symbol: String
}

final class NavigationTests: XCTestCase {
    func testFloatingTabBarItemSelection() {
        let tabs = [
            SampleTab(id: 0, title: "Home", symbol: "house.fill"),
            SampleTab(id: 1, title: "Settings", symbol: "gear.fill")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: tabs)
        XCTAssertEqual(bar.selectedItem.id, 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails (Red)**

Run: `swift test --package-path CraftUIKit --filter NavigationTests`
Expected: FAIL.

- [ ] **Step 3: Implement `CraftFloatingTabBar.swift`**

Implement:
- `CraftFloatingTabBar.swift`: Floating capsule navigation bar with background material blur, sliding indicator pill using `matchedGeometryEffect`, spring bounce on tab selection, optional center Floating Action Button (FAB) slot, safe area padding, and 44pt+ touch targets.

- [ ] **Step 4: Run test and verify it passes (Green)**

Run: `swift test --package-path CraftUIKit --filter NavigationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): implement CraftFloatingTabBar"
```

---

### Task 4: Audio Visualizer & Motion FX (CraftWaveformView, CraftSparkleView, CraftCountdownOverlay)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftWaveformView.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftSparkleView.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCountdownOverlay.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift`

**Interfaces:**
- Produces:
  - `CraftWaveformView(audioLevels: [CGFloat], barCount: Int, spacing: CGFloat, isRecording: Bool)`
  - `.craftSparkle(isTriggered: Binding<Bool>)`, `.craftConfetti(isTriggered: Binding<Bool>, particleCount: Int)`
  - `CraftCountdownOverlay(startNumber: Int, onFinish: @escaping () -> Void)`

- [ ] **Step 1: Write failing unit tests for Feedback FX**

Create `CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class FeedbackFXTests: XCTestCase {
    func testWaveformClampingAndCount() {
        let view = CraftWaveformView(audioLevels: [-0.5, 0.5, 1.5], barCount: 16)
        XCTAssertEqual(view.barCount, 16)
        XCTAssertEqual(view.normalizedLevels.count, 16)
        XCTAssertEqual(view.normalizedLevels[0], 0.0)
        XCTAssertEqual(view.normalizedLevels[1], 0.5)
        XCTAssertEqual(view.normalizedLevels[2], 1.0)
    }

    func testCountdownInit() {
        var finished = false
        let countdown = CraftCountdownOverlay(startNumber: 3) {
            finished = true
        }
        XCTAssertEqual(countdown.startNumber, 3)
    }
}
```

- [ ] **Step 2: Run test to verify it fails (Red)**

Run: `swift test --package-path CraftUIKit --filter FeedbackFXTests`
Expected: FAIL.

- [ ] **Step 3: Implement Waveform, Sparkle/Confetti, and Countdown**

Implement:
- `CraftWaveformView.swift`: Animated audio frequency bars with level normalization (0.0 to 1.0), dynamic spacing, and breathing pulse glow during active recording.
- `CraftSparkleView.swift`: Particle sparkle and confetti burst overlay using SwiftUI Canvas/TimelineView with physics decay, auto-dismiss, and `Reduce Motion` fallback.
- `CraftCountdownOverlay.swift`: 3-2-1 Go! overlay modal with spring scale bounce, haptic ticks on count, and `onFinish` callback.

- [ ] **Step 4: Run test and verify it passes (Green)**

Run: `swift test --package-path CraftUIKit --filter FeedbackFXTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): implement CraftWaveformView, CraftSparkleView, and CraftCountdownOverlay"
```

---

### Task 5: Showcase Integration in CraftCatalogView

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: Full package test suite via `swift test --package-path CraftUIKit`

- [ ] **Step 1: Add Phase 2 sections to `CraftCatalogView.swift`**

Add interactive sections:
- Section 10: Segmented Distribution Bar & Step Roadmap Nodes.
- Section 11: 3D Flip Card & Multiple-Choice Quiz Cards.
- Section 12: Floating Liquid Glass TabBar.
- Section 13: Real-Time Audio Waveform, Particle Sparkle/Confetti triggers, and 3-2-1 Countdown demo.

- [ ] **Step 2: Run full package test suite**

Run: `swift test --package-path CraftUIKit`
Expected: All tests PASS with 0 failures.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "feat(CraftUIKit): showcase Phase 2 components in CraftCatalogView"
```

---

### Task 6: App Feature Migrations (CEFR Distribution & Topic Roadmap)

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/CEFRDistributionCard.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/TopicDecks/Views/TopicRoadmapView.swift`
- Test: `swift test` at workspace root

- [ ] **Step 1: Refactor `CEFRDistributionCard.swift` with `CraftSegmentedBar`**

Replace manual GeometryReader / HStack ratio bars with `CraftSegmentedBar` from `CraftUIKit`.

- [ ] **Step 2: Refactor `TopicRoadmapView.swift` with `CraftStepNode`**

Replace custom timeline circles, padlock icons, and connector paths with `CraftStepNode`.

- [ ] **Step 3: Run root tests to verify everything builds and passes**

Run: `swift test`
Expected: All app tests pass cleanly.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp
git commit -m "refactor: migrate CEFRDistributionCard and TopicRoadmapView to CraftUIKit"
```

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-22-craftuikit-phase-2.md`. Two execution options:

1. **Subagent-Driven (recommended)** - Dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - Execute tasks in this session using executing-plans.

**Which approach?**
