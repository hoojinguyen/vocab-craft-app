# Home Screen Minimal Zen Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the "Minimal Zen Flow" redesign for the VocabCraft Home Screen, featuring an Apple Books-inspired in-scroll Large Title header, smooth scroll-away transition, sticky Liquid Glass Unit HUD, and complete legacy Bento views cleanup.

**Architecture:** 
- In-scroll `HomeTopHeaderView` (Large Title + Streak + Daily Goal Ring + Avatar) nested within `CraftLearningPath` scroll view.
- `CraftLearningPath` configured with `pinSectionHeaders: true` and a Liquid Glass sticky HUD docked at the top.
- Refactored `HomepageViewModel` with pure Swift Observation (`@Observable`) and removal of obsolete Bento state bridges.
- Clean Architecture adherence and 100% bilingual string localization (`Localizable.xcstrings`).

**Tech Stack:** Swift 6, SwiftUI (iOS 18+ / iOS 26 Liquid Glass), Observation framework, CraftUIKit design tokens, Swift Testing / XCTest.

## Global Constraints

- Platform requirements: iOS 18.0+
- Theme & Tokens: Strictly use `CraftUIKit` tokens (`theme.colors`, `theme.typography`, `theme.spacing`, `theme.shadows`, `theme.depths`).
- Zero Hardcoded Strings Policy: All display strings and accessibility labels must reside in `VocabCraftApp/Resources/Localizable.xcstrings` under `app.home.*` with complete EN and VI translations.
- Quality Gate: 0 compiler warnings, 0 lint warnings, 100% test pass rate.

---

### Task 1: Localization & AppStrings for Home Minimal Zen Flow

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift:367-440`
- Modify: `VocabCraftAppTests/Features/Homepage/HomeLocalizationTests.swift:6-124`

**Interfaces:**
- Consumes: `AppStrings.Home`
- Produces: 
  - `AppStrings.Home.title`: `LocalizedStringKey`
  - `AppStrings.Home.titleText`: `String`
  - `AppStrings.Home.dailyGoalCount(completed: Int, goal: Int)`: `String`
  - `AppStrings.Home.dailyGoalA11y(completed: Int, goal: Int)`: `String`

- [ ] **Step 1: Write the failing test for new Home localization accessors**

Update `VocabCraftAppTests/Features/Homepage/HomeLocalizationTests.swift` to assert the new header string accessors and required keys in `Localizable.xcstrings`:
```swift
func testAppStringsHomeZenHeaderAccessors() {
    XCTAssertEqual(AppStrings.Home.titleText, "Home")
    XCTAssertEqual(AppStrings.Home.dailyGoalCount(completed: 8, goal: 10), "8/10")
    XCTAssertEqual(AppStrings.Home.dailyGoalA11y(completed: 8, goal: 10), "Daily Goal: 8 of 10 words completed")
    XCTAssertNotNil(AppStrings.Home.title)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HomeLocalizationTests`
Expected: FAIL with missing members `titleText`, `dailyGoalCount`, `dailyGoalA11y`.

- [ ] **Step 3: Update `Localizable.xcstrings` and `AppStrings.swift`**

Add the keys `app.home.title`, `app.home.header.daily_goal_count_format`, and `app.home.header.daily_goal_a11y_format` in `VocabCraftApp/Resources/Localizable.xcstrings` with English and Vietnamese translations.
Add the helper methods in `VocabCraftApp/Core/Localization/AppStrings.swift` under `AppStrings.Home`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HomeLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftAppTests/Features/Homepage/HomeLocalizationTests.swift
git commit -m "feat(home): add minimal zen flow localization strings and tests"
```

---

### Task 2: Build `HomeTopHeaderView` Component

**Files:**
- Create: `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`
- Create: `VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift`

**Interfaces:**
- Consumes: `CraftUIKit` (`CraftStreakBadge`, `CraftProgressRing`, `CraftTheme`), `AppStrings.Home`
- Produces: `HomeTopHeaderView: View`
  ```swift
  public struct HomeTopHeaderView: View {
      public let userName: String
      public let streakDays: Int
      public let dailyWordsLearned: Int
      public let dailyWordsGoal: Int
      public var onAvatarTap: (() -> Void)?
      public var onStreakTap: (() -> Void)?
  }
  ```

- [ ] **Step 1: Write the failing test for `HomeTopHeaderView`**

Create `VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift`:
```swift
import SwiftUI
import XCTest
@testable import VocabCraftApp

@MainActor
final class HomeTopHeaderViewTests: XCTestCase {
    func testHeaderViewInitialization() {
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )
        XCTAssertEqual(view.userName, "Hooji N.")
        XCTAssertEqual(view.streakDays, 14)
        XCTAssertEqual(view.dailyWordsLearned, 8)
        XCTAssertEqual(view.dailyWordsGoal, 10)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HomeTopHeaderViewTests`
Expected: FAIL with `HomeTopHeaderView` not found.

- [ ] **Step 3: Implement `HomeTopHeaderView`**

Create `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`:
- Uses Large Title typography (`theme.typography.display` or `.system(size: 34, weight: .bold, design: .default)`) with "Home" / `AppStrings.Home.title`.
- Trailing `HStack` with:
  1. `CraftStreakBadge` (sm size, showing streak days).
  2. `CraftProgressRing` (36pt size, hairline width, displaying `8/10` words inside).
  3. Avatar Button (36pt circle with user initials, tapping triggers `onAvatarTap`).
- Uses `theme.spacing`, `theme.colors`, and full VoiceOver accessibility traits.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HomeTopHeaderViewTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift
git commit -m "feat(home): implement HomeTopHeaderView component"
```

---

### Task 3: Refactor `HomepageViewModel` (Observation & Goal Progress)

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift`

**Interfaces:**
- Consumes: `FetchLearningPathUseCaseProtocol`
- Produces: 
  - `HomepageViewModel.dailyWordsLearned: Int`
  - `HomepageViewModel.dailyWordsGoal: Int`
  - `HomepageViewModel.dailyGoalProgress: Double` (calculated as `dailyWordsLearned / dailyWordsGoal`)
  - Cleaned properties (removed legacy Bento `dueCardsCount`, `suggestedWords`, etc.)

- [ ] **Step 1: Write the failing test for updated ViewModel**

Update `VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift`:
```swift
func testViewModelDailyGoalCalculation() {
    let vm = HomepageViewModel(
        userName: "Hooji N.",
        streakDays: 14,
        dailyWordsLearned: 8,
        dailyWordsGoal: 10
    )
    XCTAssertEqual(vm.dailyWordsLearned, 8)
    XCTAssertEqual(vm.dailyWordsGoal, 10)
    XCTAssertEqual(vm.dailyGoalProgress, 0.8, accuracy: 0.001)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HomepageViewModelTests`
Expected: FAIL with missing parameters `dailyWordsLearned` / `dailyWordsGoal`.

- [ ] **Step 3: Update `HomepageViewModel.swift`**

- Add `dailyWordsLearned: Int` and `dailyWordsGoal: Int`.
- Compute `dailyGoalProgress` derived from `dailyWordsLearned` and `dailyWordsGoal`.
- Remove legacy Bento properties (`suggestedWords`, `currentSuggestedWordIndex`, `dueCardsCount`, `totalWords`, `retentionPercentage`, `StateBridge`, `speakSuggestedWord`, `toggleBookmarkSuggestedWord`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HomepageViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift
git commit -m "refactor(home): clean up HomepageViewModel and add daily word metrics"
```

---

### Task 4: Integrate In-Scroll Header & Sticky Liquid Glass Unit HUD in `HomepageView`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `HomeTopHeaderView`, `CraftLearningPath`, `HomepageViewModel`
- Produces: `HomepageView: View` with seamless scroll-away header and sticky docked Liquid Glass Unit HUD.

- [ ] **Step 1: Write view test for `HomepageView` in-scroll structure**

Update `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift` to verify `HomepageView` mounts `HomeTopHeaderView` and passes `pinSectionHeaders: true` or custom HUD configuration to `CraftLearningPath`.

- [ ] **Step 2: Run test to verify it fails or needs updates**

Run: `swift test --filter HomepageViewTests`

- [ ] **Step 3: Update `HomepageView.swift`**

- Embed `HomeTopHeaderView` at the top of the learning path flow inside `CraftLearningPath` header or in a coordinated `ScrollView`.
- Enable `pinSectionHeaders: true` (or custom sticky HUD) in `CraftLearningPath`.
- Remove the old fixed `HeaderView` from the top of `VStack`.
- Apply smooth Liquid Glass styling to the sticky unit HUD (`GlassEffectContainer` / `.ultraThinMaterial`, `topHighlight`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HomepageViewTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "feat(home): integrate in-scroll header and sticky liquid glass unit HUD"
```

---

### Task 5: Legacy Bento Views & PBXProj Cleanup

**Files:**
- Delete: `VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift`
- Delete: `VocabCraftApp/Features/Homepage/Views/CEFRDistributionCard.swift`
- Delete: `VocabCraftApp/Features/Homepage/Views/SRSMemoryHeroCard.swift`
- Delete: `VocabCraftApp/Features/Homepage/Views/SuggestedWordsCardView.swift`
- Delete: `VocabCraftApp/Features/Homepage/Views/HeaderView.swift` (superseded by `HomeTopHeaderView.swift`)
- Delete: `VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` (if referenced)

- [ ] **Step 1: Remove deprecated Bento files and obsolete test file**

Delete files using `rm` or git rm.

- [ ] **Step 2: Clean and verify build**

Run: `swift test`
Verify that no missing symbol errors occur across the entire test suite.

- [ ] **Step 3: Commit**

```bash
git rm VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift VocabCraftApp/Features/Homepage/Views/CEFRDistributionCard.swift VocabCraftApp/Features/Homepage/Views/SRSMemoryHeroCard.swift VocabCraftApp/Features/Homepage/Views/SuggestedWordsCardView.swift VocabCraftApp/Features/Homepage/Views/HeaderView.swift VocabCraftAppTests/Features/Homepage/BentoCardsTests.swift
git commit -m "chore(home): remove legacy bento card views and unused tests"
```

---

### Task 6: Full Verification & Quality Gate

**Files:**
- All touched files in `VocabCraftApp` and `VocabCraftAppTests`

- [ ] **Step 1: Run full test suite**

Run: `swift test`
Expected: 100% tests passing.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Final check of git status**

Ensure working directory is clean.

- [ ] **Step 4: Commit and tag**

```bash
git commit --allow-empty -m "chore(home): complete home screen minimal zen flow verification"
```
