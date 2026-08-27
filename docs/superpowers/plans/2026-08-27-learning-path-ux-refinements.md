# Learning Path UX Refinements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement full-view detail sheet modal presentation and configurable sticky unit section headers in `CraftUIKit` and integrate into `VocabCraftApp`.

**Architecture:** 
1. `CraftLessonDetailSheet` vertical rhythm optimization + `CraftLearningPath` presentation detents update (`.fraction(0.62)`).
2. Modular `CraftLessonSectionHeaderView` + `CraftLearningPath` configurable `pinSectionHeaders: Bool = true` utilizing `LazyVStack(pinnedViews: [.sectionHeaders])`.
3. `HomepageView` integration and zero-regression QA validation across `CraftUIKit` and `VocabCraftApp`.

**Tech Stack:** Swift 6, SwiftUI, Swift Package Manager, XCTest, CraftUIKit Design System Tokens.

**Spec:** [`docs/superpowers/specs/2026-08-27-learning-path-ux-refinements-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-27-learning-path-ux-refinements-design.md)

## Global Constraints

- **Zero Hardcoded Strings**: All text and a11y labels must use `CraftLocalized` (`craft.*`) or `AppStrings` (`app.home.*`).
- **Design System Encapsulation**: Component changes must live in `CraftUIKit` so they are fully reusable across other features.
- **Swift 6 Concurrency**: MainActor annotations on UI components; Sendable closures for callbacks.
- **Verification Gate**: 0 SwiftLint violations, 100% test pass on `swift test` and `xcodebuild test`.

---

### Task 1: `CraftLessonDetailSheet` Spacing Optimization & Full-View Presentation Detents

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonDetailSheet.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/Components/CraftLessonDetailSheetTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `CraftTheme`, `CraftButton`, `CraftBadge`, `CraftCard`.
- Produces: `CraftLessonDetailSheet`, updated `CraftLearningPath` `.presentationDetents([.fraction(0.62), .large])`.

- [ ] **Step 1: Write unit tests for `CraftLessonDetailSheet`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/Components/CraftLessonDetailSheetTests.swift`:
```swift
import SwiftUI
import XCTest
@testable import CraftUIKit

final class CraftLessonDetailSheetTests: XCTestCase {
    func testDetailSheetComputedPropertiesForActiveNode() {
        let node = LessonNodeModel(
            id: "node_1",
            title: "Daily Habits",
            subtitle: "10 words • 3 min",
            iconName: "heart.fill",
            state: .active,
            xpReward: 25,
            estimatedMinutes: 3,
            objectives: ["Master 10 words", "Practice recall"]
        )

        let sheet = CraftLessonDetailSheet(node: node)
        XCTAssertEqual(sheet.formattedXPReward, "+25 XP")
        XCTAssertEqual(sheet.formattedDuration, "3 min")
        XCTAssertEqual(sheet.statusBadgeTitle, "Active")
        XCTAssertEqual(sheet.statusBadgeTone, .primary)
        XCTAssertFalse(sheet.isCtaDisabled)
    }

    func testDetailSheetComputedPropertiesForLockedNode() {
        let node = LessonNodeModel(
            id: "node_locked",
            title: "Advanced Grammar",
            subtitle: "15 words • 5 min",
            iconName: "lock.fill",
            state: .locked
        )

        let sheet = CraftLessonDetailSheet(node: node)
        XCTAssertTrue(sheet.isCtaDisabled)
        XCTAssertEqual(sheet.statusBadgeTone, .neutral)
    }
}
```

- [ ] **Step 2: Run test to verify initial status**

Run: `swift test --filter CraftLessonDetailSheetTests`

- [ ] **Step 3: Optimize vertical rhythm in `CraftLessonDetailSheet.swift` & update detents in `CraftLearningPath.swift`**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonDetailSheet.swift`:
- Set `tactileDiameter` to `54 * baseScale`.
- Adjust spacing between header items, metrics chips, and objectives card.
- In `CraftLearningPath.swift`, change `.presentationDetents([.fraction(0.48), .medium, .large])` to `.presentationDetents([.fraction(0.62), .large])`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLessonDetailSheetTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/ Packages/CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(craftuikit): optimize CraftLessonDetailSheet layout and update full-view presentation detents"
```

---

### Task 2: Configurable Sticky Unit Headers in `CraftLearningPath` & `CraftLessonSectionView`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/Components/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `SnakeRowLayout`, `RowPattern`, `CraftSnakeConnectorLayer`.
- Produces: `CraftLearningPath.init(..., pinSectionHeaders: Bool = true)`, `CraftLessonSectionHeaderView`, `CraftLessonSectionBodyView`.

- [ ] **Step 1: Write unit tests for `CraftLearningPath` with `pinSectionHeaders`**

Create or update `Packages/CraftUIKit/Tests/CraftUIKitTests/Components/CraftLearningPathTests.swift`:
```swift
import SwiftUI
import XCTest
@testable import CraftUIKit

final class CraftLearningPathTests: XCTestCase {
    func testLearningPathDefaultPinSectionHeaders() {
        let section = LessonSection(
            id: "sec_1",
            title: "Unit 1",
            nodes: [
                LessonNodeModel(id: "n1", title: "Lesson 1", state: .active)
            ]
        )
        let path = CraftLearningPath(sections: [section])
        XCTAssertTrue(path.pinSectionHeaders)
    }

    func testLearningPathExplicitPinSectionHeadersFalse() {
        let section = LessonSection(
            id: "sec_1",
            title: "Unit 1",
            nodes: [
                LessonNodeModel(id: "n1", title: "Lesson 1", state: .active)
            ]
        )
        let path = CraftLearningPath(sections: [section], pinSectionHeaders: false)
        XCTAssertFalse(path.pinSectionHeaders)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter CraftLearningPathTests`
Expected: FAIL (missing `pinSectionHeaders` property)

- [ ] **Step 3: Implement modular section header and `pinSectionHeaders` in `CraftUIKit`**

1. In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift`:
   - Split and expose `CraftLessonSectionHeaderView` and `CraftLessonSectionBodyView`.
   - Add solid/material backdrop to `CraftLessonSectionHeaderView` when rendered as a pinned header.
2. In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`:
   - Add `public let pinSectionHeaders: Bool` to all `init`s (default `true`).
   - In `scrollableView`:
     ```swift
     LazyVStack(spacing: theme.spacing.xxl, pinnedViews: pinSectionHeaders ? [.sectionHeaders] : []) {
         ForEach(sections) { section in
             if pinSectionHeaders {
                 Section {
                     CraftLessonSectionBodyView(
                         section: section,
                         rowPattern: rowPattern != .standard ? rowPattern : section.rowPattern,
                         onNodeTap: onNodeTap
                     )
                 } header: {
                     CraftLessonSectionHeaderView(section: section)
                         .padding(.horizontal, theme.spacing.base)
                         .padding(.vertical, theme.spacing.xs)
                         .background(theme.colors.canvasBackground)
                 }
             } else {
                 CraftLessonSectionView(
                     section: section,
                     rowPattern: rowPattern != .standard ? rowPattern : section.rowPattern,
                     onNodeTap: onNodeTap
                 )
             }
         }
     }
     ```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/ Packages/CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(craftuikit): add configurable sticky unit headers to CraftLearningPath"
```

---

### Task 3: Integration in `HomepageView` & Full Verification Gate

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `CraftLearningPath(..., pinSectionHeaders: true)`.
- Produces: Integrated Homepage UI with full-view detail sheet and sticky unit section headers.

- [ ] **Step 1: Update `HomepageView.swift` to explicitly pass `pinSectionHeaders: true`**

In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
```swift
CraftLearningPath(
    sections: viewModel.sections,
    winding: .standard,
    rowPattern: .standard,
    pinSectionHeaders: true,
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
    showDetailModal: true,
    scrollToActive: true,
    showCelebration: false
)
```

- [ ] **Step 2: Run Homepage tests to verify integration**

Run: `swift test --filter HomepageViewTests`
Expected: PASS

- [ ] **Step 3: Run full QA gate**

1. Run: `swiftlint lint` (Must report 0 violations).
2. Run: `swift test` (All tests pass).
3. Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/xcodebuild` (All simulator tests pass).

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/
git commit -m "feat(home): integrate sticky unit headers with CraftLearningPath in HomepageView"
```
