# CraftUIKit Localization Standardization & Component Text Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate all hardcoded English/Vietnamese text across all 34 `CraftUIKit` components, standardize `Localizable.xcstrings` into a clean bilingual catalog with hierarchical snake_case keys, and add support for dynamic lesson objectives.

**Architecture:** A centralized `Localizable.xcstrings` String Catalog provides 100% paired English (`en`) and Vietnamese (`vi`) localizations. `CraftLocalized` wraps runtime resolution with `Bundle.module` fallback. All SwiftUI components across Atoms, Controls, Containers, Feedback, Navigation, and Overlays resolve their default labels, placeholders, VoiceOver descriptions, and format strings through standardized `craft.*` keys.

**Tech Stack:** Swift 6, SwiftUI, Swift Package Manager (SPM), String Catalogs (`.xcstrings`), XCTest.

**Spec:** [2026-08-26-craftuikit-localization-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-26-craftuikit-localization-design.md)

## Global Constraints

- Root namespace: `craft.<scope>.<element>.<role/state/a11y>`
- All key segments must use lowercase snake_case (e.g. `craft.common.unit.days_format`)
- Format strings must use standard format specifiers (`%lld`, `%@`, `%%`)
- Both `en` and `vi` translations must be completely filled with 0 empty translations and 0 cross-language mixups
- Package builds and tests must run cleanly with `swift test` in `CraftUIKit`

---

### Task 1: Rewrite String Catalog (`Localizable.xcstrings`) & Update Tests

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`

**Interfaces:**
- Produces: Complete set of 70+ bilingual keys under `craft.common.*`, `craft.button.*`, `craft.choice.*`, `craft.search.*`, `craft.stepper.*`, `craft.textfield.*`, `craft.flipcard.*`, `craft.progress.*`, `craft.segmented_bar.*`, `craft.step_node.*`, `craft.streak.*`, `craft.learning_path.*`, `craft.tab_bar.*`, `craft.waveform.*`, `craft.countdown.*`, `craft.sparkle.*`.

- [ ] **Step 1: Write comprehensive tests in `LocalizationTests.swift` for all new keys**

```swift
import XCTest
@testable import CraftUIKit

final class LocalizationTests: XCTestCase {
    
    // MARK: - Common Actions & States
    func testCommonStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.common.action.confirm"), "Confirm")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.confirm", language: "vi"), "Xác nhận")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.cancel"), "Cancel")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.cancel", language: "vi"), "Hủy")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.close"), "Close")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.close", language: "vi"), "Đóng")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.dismiss"), "Dismiss")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.dismiss", language: "vi"), "Đóng")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.continue"), "Continue")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.continue", language: "vi"), "Tiếp tục")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.retry"), "Retry")
        XCTAssertEqual(CraftLocalized.string("craft.common.action.retry", language: "vi"), "Thử lại")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.loading"), "Loading")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.loading", language: "vi"), "Đang tải")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.on"), "On")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.on", language: "vi"), "Bật")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.off"), "Off")
        XCTAssertEqual(CraftLocalized.string("craft.common.state.off", language: "vi"), "Tắt")
    }

    // MARK: - Formatted Units
    func testUnitFormatting() {
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.days_format", 5), "5 days")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.days_format", language: "vi", 5), "5 ngày")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.minutes_format", 10), "10 min")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.minutes_format", language: "vi", 10), "10 phút")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.words_format", 15), "15 new words")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.words_format", language: "vi", 15), "15 từ vựng mới")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.percent_word_format", 75), "75 percent")
        XCTAssertEqual(CraftLocalized.format("craft.common.unit.percent_word_format", language: "vi", 75), "75 phần trăm")
    }

    // MARK: - Controls
    func testControlsStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder"), "Search...")
        XCTAssertEqual(CraftLocalized.string("craft.search.placeholder", language: "vi"), "Tìm kiếm...")
        XCTAssertEqual(CraftLocalized.string("craft.search.clear_a11y"), "Clear search")
        XCTAssertEqual(CraftLocalized.string("craft.search.clear_a11y", language: "vi"), "Xóa tìm kiếm")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decrease_a11y"), "Decrease")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.decrease_a11y", language: "vi"), "Giảm")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increase_a11y"), "Increase")
        XCTAssertEqual(CraftLocalized.string("craft.stepper.increase_a11y", language: "vi"), "Tăng")
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct_a11y"), "Correct Answer")
        XCTAssertEqual(CraftLocalized.string("craft.choice.correct_a11y", language: "vi"), "Đáp án đúng")
    }

    // MARK: - Learning Path & Journey
    func testLearningPathStrings() {
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.start_lesson"), "START LESSON")
        XCTAssertEqual(CraftLocalized.string("craft.learning_path.start_lesson", language: "vi"), "BẮT ĐẦU HỌC")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.continue_lesson_format", 40), "CONTINUE (40%)")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.continue_lesson_format", language: "vi", 40), "TIẾP TỤC HỌC (40%)")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_completed_a11y", "Basics"), "Lesson: Basics, Completed")
        XCTAssertEqual(CraftLocalized.format("craft.learning_path.node_completed_a11y", language: "vi", "Cơ bản"), "Bài học: Cơ bản, Đã hoàn thành")
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter LocalizationTests`
Expected: FAIL (missing new keys)

- [ ] **Step 3: Update `Localizable.xcstrings` with the complete 70+ key dictionary**

Write the updated JSON catalog into `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` with all keys from the design spec (Section 4).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift
git commit -m "feat: standardize Localizable.xcstrings catalog and add comprehensive localization tests"
```

---

### Task 2: Refactor Models for Dynamic Objectives & Localization

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Models/CraftStreakModels.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Models/CraftActivityModels.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakModelTests.swift`

**Interfaces:**
- `CraftStreakData.asActivityTrackerData`: resolves default `unit` dynamically using `CraftLocalized.string("craft.common.unit.days_single")` and `unitKey: "craft.common.unit.days_single"`.
- `LessonNodeModel`: adds optional `objectives: [String]? = nil` and `objectiveKeys: [String]? = nil`.

- [ ] **Step 1: Write test in `CraftStreakModelTests.swift` for localized default unit**

```swift
func testStreakDataAsActivityTrackerDataLocalization() {
    let streakData = CraftStreakData(
        currentStreak: 5,
        bestStreak: 10,
        freezeTokens: 1,
        maxFreezeTokens: 2,
        nextMilestoneDays: 7,
        isCompletedToday: true,
        weekDays: []
    )
    let activity = streakData.asActivityTrackerData
    XCTAssertEqual(activity.unitKey, "craft.common.unit.days_single")
    XCTAssertEqual(activity.unit, CraftLocalized.string("craft.common.unit.days_single"))
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter CraftStreakModelTests`
Expected: FAIL (`unit` is still `"ngày"`)

- [ ] **Step 3: Update `CraftStreakModels.swift`, `CraftLearningPathModels.swift`, and `CraftActivityModels.swift`**

Update `CraftStreakModels.swift`:
```swift
public var asActivityTrackerData: CraftActivityTrackerData {
    CraftActivityTrackerData(
        currentValue: currentStreak,
        bestValue: bestStreak,
        unitKey: "craft.common.unit.days_single",
        unit: CraftLocalized.string("craft.common.unit.days_single"),
        shieldTokens: freezeTokens,
        maxShieldTokens: maxFreezeTokens,
        nextMilestoneValue: nextMilestoneDays,
        isCompletedToday: isCompletedToday,
        cycleDays: weekDays.map(\.asActivityDay)
    )
}
```

Update `CraftLearningPathModels.swift` `LessonNodeModel` initializer and properties:
```swift
public let objectives: [String]?
public let objectiveKeys: [String]?

public init(
    id: String,
    title: String,
    titleKey: LocalizedStringKey? = nil,
    subtitle: String? = nil,
    subtitleKey: LocalizedStringKey? = nil,
    objectives: [String]? = nil,
    objectiveKeys: [String]? = nil,
    ...
) {
    ...
    self.objectives = objectives
    self.objectiveKeys = objectiveKeys
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter CraftStreakModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Models/CraftStreakModels.swift CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift CraftUIKit/Sources/CraftUIKit/Models/CraftActivityModels.swift CraftUIKit/Tests/CraftUIKitTests/CraftStreakModelTests.swift
git commit -m "feat: remove hardcoded units from streak models and add custom objectives support to LessonNodeModel"
```

---

### Task 3: Refactor Atoms & Controls

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftTextField.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftStepper.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftToggle.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`

**Interfaces:**
- `CraftButton`: `accessibilityValue` uses `CraftLocalized.string("craft.button.loading_a11y")`.
- `CraftSearchBar`: default placeholder uses `CraftLocalized.string("craft.search.placeholder")`, clear a11y uses `craft.search.clear_a11y`, trailing action a11y uses `craft.search.trailing_action_a11y`.
- `CraftTextField`: password visibility a11y uses `craft.textfield.show_password_a11y` and `craft.textfield.hide_password_a11y`.
- `CraftStepper`: a11y label uses `craft.stepper.default_label`, decrease uses `craft.stepper.decrease_a11y`, increase uses `craft.stepper.increase_a11y`.
- `CraftToggle`: `accessibilityValue` uses `craft.common.state.on` / `craft.common.state.off`.
- `CraftChoiceCard`: `accessibilityValueDescription` uses `craft.choice.*`.

- [ ] **Step 1: Write test in `ControlComponentTests.swift` and `AtomComponentTests.swift`**

Verify localized strings used in accessibility values of controls.

- [ ] **Step 2: Update all 7 Control & Atom component files**

Update the implementation of `CraftStreakBadge`, `CraftButton`, `CraftSearchBar`, `CraftTextField`, `CraftStepper`, `CraftToggle`, `CraftChoiceCard` replacing hardcoded strings with `CraftLocalized` calls.

- [ ] **Step 3: Run control and atom test suites**

Run: `swift test --filter ControlComponentTests` and `swift test --filter AtomComponentTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift CraftUIKit/Sources/CraftUIKit/Components/Controls/ CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift
git commit -m "feat: eliminate hardcoded strings in Atoms and Controls"
```

---

### Task 4: Refactor Containers, Progress & Roadmap Components

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonDetailSheet.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftPathNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftProgressBar.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftProgressRing.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftSegmentedBar.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/MetricsProgressionTests.swift`

**Interfaces:**
- `CraftLessonDetailSheet`: formatted minutes/words, custom objectives, standard CTA button labels.
- `CraftLessonNode` & `CraftPathNode`: callout bubbles, a11y labels and hints.
- `CraftStepNode`: state descriptions and step format.
- `CraftLearningPath`: empty state view.
- `CraftProgressBar` & `CraftProgressRing`: a11y label and percentage format.
- `CraftSegmentedBar`: segmented metric bar a11y and empty summary.
- `CraftActivityTrackerCard`: day inspection hint.

- [ ] **Step 1: Update `CraftLessonDetailSheet.swift`**

- Refactor `formattedDuration`: `CraftLocalized.format("craft.common.unit.minutes_format", node.estimatedMinutes ?? 5)`
- Refactor `formattedVocabularyCount`: `CraftLocalized.format("craft.common.unit.words_format", 15)`
- Refactor objectives: If `node.objectives` exists, render them. Else render `craft.learning_path.default_objective_1`, `craft.learning_path.default_objective_2`, and `craft.learning_path.default_objective_3_format`.
- Refactor CTA button titles and all accessibility hints.

- [ ] **Step 2: Update `CraftLessonNode.swift`, `CraftPathNode.swift`, `CraftStepNode.swift`, `CraftLearningPath.swift`, `CraftLessonSectionView.swift`**

- Update callout text default to `CraftLocalized.string("craft.learning_path.continue_callout")`.
- Update all VoiceOver label text and hint text to use `craft.learning_path.*` and `craft.step_node.*`.
- Update `CraftLearningPath` empty state to use `craft.learning_path.empty_title` and `craft.learning_path.empty_desc`.
- Update `CraftLessonSectionView` unit fallback to `CraftLocalized.string("craft.learning_path.default_unit_label")`.

- [ ] **Step 3: Update `CraftProgressBar.swift`, `CraftProgressRing.swift`, `CraftSegmentedBar.swift`, `CraftActivityTrackerCard.swift`**

- Update progress accessibility label and value to `craft.progress.label` and `craft.common.unit.percent_word_format`.
- Update segmented bar accessibility label to `craft.segmented_bar.label_a11y` and empty summary to `craft.common.state.empty`.
- Update activity tracker card day inspection hint to `craft.streak.day_inspect_hint`.

- [ ] **Step 4: Run test suites**

Run: `swift test --filter CraftLearningPathTests` and `swift test --filter ContainerOverlayTests` and `swift test --filter MetricsProgressionTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/ CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift CraftUIKit/Tests/CraftUIKitTests/MetricsProgressionTests.swift
git commit -m "feat: eliminate hardcoded strings in Container and Roadmap components"
```

---

### Task 5: Refactor Feedback & Navigation Components

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftWaveformView.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCountdownOverlay.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftSparkleView.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`

**Interfaces:**
- `CraftWaveformView`: uses `craft.waveform.recording_active_a11y`, `craft.waveform.visualizer_a11y`, `craft.waveform.audio_level_format`.
- `CraftCountdownOverlay`: uses `craft.countdown.label_format`, default `goText` from `craft.countdown.go_text`.
- `CraftSparkleView`: uses `craft.sparkle.sparkle_label`, `craft.sparkle.celebration_label`.
- `CraftStreakCelebrationSheet`: uses `unitKey: "craft.common.unit.days_single"`.
- `CraftFloatingTabBar`: uses `craft.tab_bar.badge_count_format`, `craft.tab_bar.center_action_fallback`.

- [ ] **Step 1: Update `CraftWaveformView.swift`, `CraftCountdownOverlay.swift`, `CraftSparkleView.swift`, `CraftStreakCelebrationSheet.swift`**

Replace all hardcoded strings with the corresponding `craft.*` keys.

- [ ] **Step 2: Update `CraftFloatingTabBar.swift`**

Replace `"%lld new items"` with `CraftLocalized.format("craft.tab_bar.badge_count_format", count)` and `"Action"` with `CraftLocalized.string("craft.tab_bar.center_action_fallback")`.

- [ ] **Step 3: Run feedback and navigation tests**

Run: `swift test --filter FeedbackFXTests` and `swift test --filter NavigationTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Feedback/ CraftUIKit/Sources/CraftUIKit/Components/Navigation/ CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift
git commit -m "feat: eliminate hardcoded strings in Feedback and Navigation components"
```

---

### Task 6: Update Catalog Gallery & Run Full Test Suite

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- `CraftCatalogView`: Interactive preview gallery updated to use the new standardized keys.

- [ ] **Step 1: Update `CraftCatalogView.swift` dialog action titles and preview helper keys**

Update references to `craft.action.confirm` $\rightarrow$ `craft.common.action.confirm`, `craft.action.cancel` $\rightarrow$ `craft.common.action.cancel`, `craft.action.close` $\rightarrow$ `craft.common.action.close`.

- [ ] **Step 2: Run all tests across the package**

Run: `swift test`
Expected: 463+ tests pass with 0 failures and 0 warnings.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift
git commit -m "refactor: update CraftCatalogView and verify all test suites pass"
```
