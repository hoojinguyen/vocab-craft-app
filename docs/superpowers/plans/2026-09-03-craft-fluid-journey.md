# `CraftFluidJourney` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a brand-new, airy, ethereal learning path component `CraftFluidJourney` in `CraftUIKit` inspired by Praktika (with scroll-driven pinned unit transitions, zero dotted lines, bold hero active node, and an accordion curriculum drawer) and integrate it seamlessly into `HomepageView`.

**Architecture:** A modular SwiftUI organism in `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/` composed of `CraftFluidJourney` (container with coordinate space and ethereal background), `CraftPinnedUnitHeader` (sticky header observing milestone geometry), `CraftMilestonePill` (unit title capsules), `CraftJourneyNode` (3D floating tactile nodes with breathing animation), and `CraftUnitDrawerSheet` (expandable accordion curriculum).

**Tech Stack:** Swift 6 / SwiftUI (iOS 17+ / 26+), `CraftUIKit` Design Tokens, `Observation`, `@ScaledMetric`, `PhaseAnimator`, `SensoryFeedback`.

**Spec:** `docs/superpowers/specs/2026-09-03-craft-fluid-journey-design.md`

## Global Constraints
- `CraftLearningPath` must remain completely untouched; `CraftFluidJourney` is an independent new component.
- All styling must strictly utilize `CraftUIKit` tokens (`CraftColor`, `CraftFont`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`).
- Zero hardcoded strings: All user-facing text must be defined in `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` (prefixed `craft.fluid_journey.*`) with 100% bilingual parity in English (`en`) and Vietnamese (`vi`).
- Zero compiler warnings on Xcode, 100% test pass rate, and `swiftlint` compliance.

---

### Task 1: Models, Preference Keys & Localization

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourneyModels.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyModelsTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `LessonNodeModel`, `LessonNodeState` from `CraftUIKit`
- Produces: `FluidJourneyMilestonePreferenceKey`, `FluidJourneySectionState`, `FluidJourneyNodeOffset`

- [ ] **Step 1: Write the failing test for models and preference keys**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyModelsTests.swift`:
```swift
import Testing
@testable import CraftUIKit
import SwiftUI

@Suite("CraftFluidJourneyModels Tests")
struct CraftFluidJourneyModelsTests {
    @Test("Test FluidJourneyMilestonePreferenceKey reduction")
    func testPreferenceKeyReduction() {
        var current: [String: CGFloat] = ["section1": 150.0]
        FluidJourneyMilestonePreferenceKey.reduce(value: &current) {
            ["section2": 320.0]
        }
        #expect(current["section1"] == 150.0)
        #expect(current["section2"] == 320.0)
    }

    @Test("Test FluidJourneyNodeOffset sequence")
    func testNodeOffsetSequence() {
        let offsets: [CGFloat] = [-45, 0, 45, 0]
        #expect(FluidJourneyNodeOffset.offset(for: 0) == -45)
        #expect(FluidJourneyNodeOffset.offset(for: 1) == 0)
        #expect(FluidJourneyNodeOffset.offset(for: 2) == 45)
        #expect(FluidJourneyNodeOffset.offset(for: 3) == 0)
        #expect(FluidJourneyNodeOffset.offset(for: 4) == -45)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftFluidJourneyModelsTests`
Expected: FAIL with "cannot find 'FluidJourneyMilestonePreferenceKey' in scope"

- [ ] **Step 3: Implement `CraftFluidJourneyModels.swift` & Localization strings**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourneyModels.swift`:
```swift
import Foundation
import SwiftUI

public enum FluidJourneyNodeOffset {
    private static let sequence: [CGFloat] = [-45, 0, 45, 0]

    public static func offset(for index: Int) -> CGFloat {
        let pos = max(0, index)
        return sequence[pos % sequence.count]
    }
}

public struct FluidJourneyMilestonePreferenceKey: PreferenceKey, Sendable {
    public static var defaultValue: [String: CGFloat] = [:]

    public static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
```

Add strings to `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:
- `craft.fluid_journey.start_lesson`: en: "START LESSON", vi: "BẮT ĐẦU HỌC"
- `craft.fluid_journey.completed_status`: en: "Completed", vi: "Đã xong"
- `craft.fluid_journey.current_status`: en: "Current", vi: "Đang học"
- `craft.fluid_journey.unit_picker_title`: en: "Curriculum & Units", vi: "Lộ trình & Chủ đề"
- `craft.fluid_journey.adjust_plan`: en: "Adjust plan", vi: "Tuỳ chỉnh lộ trình"
- `craft.fluid_journey.select_unit_hint`: en: "Double tap to switch to this unit", vi: "Chạm hai lần để chuyển sang chủ đề này"

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftFluidJourneyModelsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourneyModels.swift \
        Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings \
        Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyModelsTests.swift
git commit -m "feat(CraftUIKit): add models and localization for CraftFluidJourney"
```

---

### Task 2: Floating Journey Node Component (`CraftJourneyNode`)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftJourneyNodeTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `theme.colors.brandPrimary`, `PhaseAnimator`
- Produces: `CraftJourneyNode: View`

- [ ] **Step 1: Write the failing test for `CraftJourneyNode`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftJourneyNodeTests.swift`:
```swift
import Testing
@testable import CraftUIKit
import SwiftUI

@Suite("CraftJourneyNode Tests")
struct CraftJourneyNodeTests {
    @Test("Verify diameters across progression states")
    func testNodeDiameters() {
        let activeNode = LessonNodeModel(id: "1", title: "Active", state: .active)
        let completedNode = LessonNodeModel(id: "2", title: "Completed", state: .completed)
        let lockedNode = LessonNodeModel(id: "3", title: "Locked", state: .locked)

        #expect(CraftJourneyNode.diameter(for: activeNode.state) == 88)
        #expect(CraftJourneyNode.diameter(for: completedNode.state) == 88)
        #expect(CraftJourneyNode.diameter(for: lockedNode.state) == 88)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftJourneyNodeTests`
Expected: FAIL with "cannot find 'CraftJourneyNode' in scope"

- [ ] **Step 3: Implement `CraftJourneyNode.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift`:
- Handle visual states with uniform 88pt continuous squircle nodes across all states, preserving semantic icons and tactile 3D extrusion.
- Support `.sensoryFeedback(.impact(weight: .medium), trigger: tapTrigger)`.
- Support `@Environment(\.accessibilityReduceMotion)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftJourneyNodeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift \
        Packages/CraftUIKit/Tests/CraftUIKitTests/CraftJourneyNodeTests.swift
git commit -m "feat(CraftUIKit): implement CraftJourneyNode with breathing hero orb"
```

---

### Task 3: In-Scroll Milestone Pill Component (`CraftMilestonePill`)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftMilestonePill.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftMilestonePillTests.swift`

**Interfaces:**
- Consumes: `FluidJourneyMilestonePreferenceKey`, `CraftFluidJourney.scrollCoordinateSpaceName`
- Produces: `CraftMilestonePill: View`

- [ ] **Step 1: Write test for `CraftMilestonePill`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftMilestonePillTests.swift`:
```swift
import Testing
@testable import CraftUIKit
import SwiftUI

@Suite("CraftMilestonePill Tests")
struct CraftMilestonePillTests {
    @Test("Verify pill initialization and accessibility text")
    func testPillProperties() {
        let pill = CraftMilestonePill(sectionId: "sec-1", title: "Present Simple for Personal Facts")
        #expect(pill.sectionId == "sec-1")
        #expect(pill.title == "Present Simple for Personal Facts")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftMilestonePillTests`
Expected: FAIL with "cannot find 'CraftMilestonePill' in scope"

- [ ] **Step 3: Implement `CraftMilestonePill.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftMilestonePill.swift`:
- Capsule geometry with `theme.colors.surfaceCard` background and hairline border.
- Embedded `GeometryReader` calculating `geo.frame(in: .named(CraftFluidJourney.scrollCoordinateSpaceName)).minY`.
- Emits coordinate via `.preference(key: FluidJourneyMilestonePreferenceKey.self, value: [sectionId: minY])`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftMilestonePillTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftMilestonePill.swift \
        Packages/CraftUIKit/Tests/CraftUIKitTests/CraftMilestonePillTests.swift
git commit -m "feat(CraftUIKit): implement CraftMilestonePill with geometry preference reporting"
```

---

### Task 4: Pinned Unit Navigation Header Card (`CraftPinnedUnitHeader`)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftPinnedUnitHeader.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftPinnedUnitHeaderTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `onHeaderTap: () -> Void`
- Produces: `CraftPinnedUnitHeader: View`

- [ ] **Step 1: Write test for `CraftPinnedUnitHeader`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftPinnedUnitHeaderTests.swift`:
```swift
import Testing
@testable import CraftUIKit
import SwiftUI

@Suite("CraftPinnedUnitHeader Tests")
struct CraftPinnedUnitHeaderTests {
    @Test("Verify header data binding")
    func testHeaderBinding() {
        let section = LessonSection(id: "sec-1", title: "Everyday Conversations", level: "A2", subtitle: "Habits & Moods", nodes: [])
        let header = CraftPinnedUnitHeader(section: section, onTap: {})
        #expect(header.section.title == "Everyday Conversations")
        #expect(header.section.level == "A2")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftPinnedUnitHeaderTests`
Expected: FAIL with "cannot find 'CraftPinnedUnitHeader' in scope"

- [ ] **Step 3: Implement `CraftPinnedUnitHeader.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftPinnedUnitHeader.swift`:
- Glass card with `RoundedRectangle(cornerRadius: 20)` and subtle drop shadow.
- Level badge, main title, subtitle, and trailing chevron `›`.
- Smooth morphing transition when `section.id` changes:
  `.transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))`.
- Accessible button trait invoking `onTap`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftPinnedUnitHeaderTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftPinnedUnitHeader.swift \
        Packages/CraftUIKit/Tests/CraftUIKitTests/CraftPinnedUnitHeaderTests.swift
git commit -m "feat(CraftUIKit): implement CraftPinnedUnitHeader with smooth morphing transitions"
```

---

### Task 5: Expandable Accordion Curriculum Drawer (`CraftUnitDrawerSheet`)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftUnitDrawerSheet.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftUnitDrawerSheetTests.swift`

**Interfaces:**
- Consumes: `[LessonSection]`, `deckTitle: String`, `deckSubtitle: String`, `activeSectionId: String`, `onSelectLesson: (String, String) -> Void`, `onDismiss: () -> Void`
- Produces: `CraftUnitDrawerSheet: View`

- [ ] **Step 1: Write test for `CraftUnitDrawerSheet`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftUnitDrawerSheetTests.swift`:
```swift
import Testing
@testable import CraftUIKit
import SwiftUI

@Suite("CraftUnitDrawerSheet Tests")
struct CraftUnitDrawerSheetTests {
    @Test("Verify drawer initialization")
    func testDrawerInit() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", level: "A2", nodes: [
                LessonNodeModel(id: "node-1", title: "Lesson 1", state: .completed),
                LessonNodeModel(id: "node-2", title: "Lesson 2", state: .active)
            ])
        ]
        let sheet = CraftUnitDrawerSheet(
            sections: sections,
            deckTitle: "Everyday English",
            deckSubtitle: "A2 Level",
            activeSectionId: "sec-1",
            onSelectLesson: { _, _ in },
            onDismiss: {}
        )
        #expect(sheet.sections.count == 1)
        #expect(sheet.activeSectionId == "sec-1")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftUnitDrawerSheetTests`
Expected: FAIL with "cannot find 'CraftUnitDrawerSheet' in scope"

- [ ] **Step 3: Implement `CraftUnitDrawerSheet.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftUnitDrawerSheet.swift`:
- Top row: Circular `✕` close button, Deck Title, Subtitle, and `[ ☵ Tuỳ chỉnh lộ trình ]` pill button.
- Accordion list: Active unit expanded by default. Collapsed units show status ring + chevron `▼`.
- Tapping a unit toggles expansion with `.spring(response: 0.35, dampingFraction: 0.8)`.
- Tapping any sub-lesson executes `onSelectLesson(sectionId, nodeId)` and closes the sheet.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftUnitDrawerSheetTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftUnitDrawerSheet.swift \
        Packages/CraftUIKit/Tests/CraftUIKitTests/CraftUnitDrawerSheetTests.swift
git commit -m "feat(CraftUIKit): implement CraftUnitDrawerSheet accordion curriculum drawer"
```

---

### Task 6: Main Container Organism (`CraftFluidJourney`)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`

**Interfaces:**
- Consumes: `[LessonSection]`, `onNodeTap: (LessonNodeModel) -> Void`, `onStartLesson: (LessonNodeModel) -> Void`, `onTabBarPresentationChange: (CraftTabBarPresentation) -> Void`
- Produces: `CraftFluidJourney: View`

- [ ] **Step 1: Write test for `CraftFluidJourney`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`:
```swift
import Testing
@testable import CraftUIKit
import SwiftUI

@Suite("CraftFluidJourney Tests")
struct CraftFluidJourneyTests {
    @Test("Verify container initialization with sections")
    func testContainerInit() {
        let sections = [
            LessonSection(id: "sec-1", title: "Unit 1", level: "A2", nodes: [
                LessonNodeModel(id: "n-1", title: "Node 1", state: .completed),
                LessonNodeModel(id: "n-2", title: "Node 2", state: .active)
            ])
        ]
        let journey = CraftFluidJourney(sections: sections)
        #expect(journey.sections.count == 1)
        #expect(journey.sections.first?.nodes.count == 2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftFluidJourneyTests`
Expected: FAIL with "cannot find 'CraftFluidJourney' in scope"

- [ ] **Step 3: Implement `CraftFluidJourney.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift`:
- Encapsulates `ScrollViewReader` and `ScrollView(.vertical, showsIndicators: false)`.
- Named coordinate space `CraftFluidJourney.scrollCoordinateSpaceName`.
- Ethereal ambient background with soft radial gradients (`ZStack` behind content).
- Pinned header positioned at top, updated via `FluidJourneyMilestonePreferenceKey`.
- Floating S-curve nodes positioned with `FluidJourneyNodeOffset.offset(for: index)`.
- Presents `CraftUnitDrawerSheet` on header tap and smoothly scrolls to selected lesson.
- Presents `CraftLessonDetailSheet` on node tap.
- Tracks user scroll to notify `onTabBarPresentationChange`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftFluidJourneyTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift \
        Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift
git commit -m "feat(CraftUIKit): implement main CraftFluidJourney container organism"
```

---

### Task 7: Homepage Integration & Verification

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Test: Xcode Simulator Build & Test Suite

**Interfaces:**
- Consumes: `CraftFluidJourney`
- Produces: Integrated Homepage experience

- [ ] **Step 1: Replace `CraftLearningPath` with `CraftFluidJourney` in `HomepageView.swift`**

Update `HomepageView.swift`:
```swift
CraftFluidJourney(
    sections: viewModel.sections,
    onNodeTap: { node in
        MainActor.assumeIsolated {
            viewModel.handleNodeTap(node)
        }
    },
    onStartLesson: { node in
        MainActor.assumeIsolated {
            startLesson(for: node)
        }
    },
    onTabBarPresentationChange: { presentation in
        MainActor.assumeIsolated {
            if tabBarPresentation != presentation {
                if isReducedMotion {
                    tabBarPresentation = presentation
                } else {
                    withAnimation(.smooth(duration: 0.2)) {
                        tabBarPresentation = presentation
                    }
                }
            }
        }
    }
)
.refreshable {
    await viewModel.loadLearningPath()
}
```

- [ ] **Step 2: Run test suite & verify 100% pass rate**

Run: `swift test`
Expected: 100% test pass rate across CraftUIKit and VocabCraftApp.

- [ ] **Step 3: Run SwiftLint & compile on Xcode Simulator**

Run: `swiftlint`
Build: `XcodeBuildMCP: build_sim({ scheme: "VocabCraftApp" })`
Expected: 0 warnings, 0 errors.

- [ ] **Step 4: Launch on Simulator and capture screenshot**

Run: `XcodeBuildMCP: build_run_sim` then `XcodeBuildMCP: screenshot`
Verify visual layout, pinned header, hero active node, and drawer modal.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift
git commit -m "feat(Homepage): integrate CraftFluidJourney into HomepageView"
```
