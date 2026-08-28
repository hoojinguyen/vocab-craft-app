# Reflex Blitz Hub UI Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor and polish the Reflex Blitz Hub / Mode Selection screen to eliminate visual clutter, remove redundant icons (from 18 down to 6), fix language inconsistencies, reorder visual hierarchy (Mode Cards first, Stats below), and soften card border styling using CraftUIKit tokens.

**Architecture:** SwiftUI View refactoring in `ReflexBlitzModeSelectionView.swift` and localization fixes in `Localizable.xcstrings`, adhering to CraftUIKit Design System and iOS HIG aesthetics.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit Design Tokens.

**Spec / Audit:** Visual review of `ReflexBlitzModeSelectionView`.

## Global Constraints
- Zero hardcoded strings, 100% Vietnamese localization parity in `Localizable.xcstrings`.
- Icon count reduced: remove 4x `stopwatch.fill` icons, remove 4x `chevron.right` arrows, clean up stats icons.
- Visual hierarchy: 4 Bento Mode Cards placed immediately below Header, Stats Dashboard placed below Mode Cards.
- Soften border strokes using subtle `CraftCard` / `CraftActionCard` surface styling and theme tokens.

---

### Task 1: Fix Localization Catalog & AppStrings for Quick Stats

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzLocalizationTests.swift`

- [ ] **Step 1: Update localization strings in Localizable.xcstrings**
Ensure `app.reflex.stats.weekly_words` and `app.reflex.stats.weak_words` have correct Vietnamese translations (`%lld từ đã luyện`, `%lld từ cần ôn`).

- [ ] **Step 2: Run localization tests**
Run: `swift test --filter ReflexBlitzLocalizationTests`
Expected: PASS.

- [ ] **Step 3: Commit**
```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzLocalizationTests.swift
git commit -m "fix(reflex): fix Vietnamese translations for Reflex stats"
```

---

### Task 2: Refactor Layout Hierarchy, De-clutter Icons & Soften Styling in `ReflexBlitzModeSelectionView`

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

- [ ] **Step 1: Update Mode Selection View layout and icons**
- Reorder: Header $\rightarrow$ 4 Bento Mode Cards $\rightarrow$ Quick Stats Summary $\rightarrow$ Footer Hint.
- Remove `badgeIcon: "stopwatch.fill"` from `CraftActionCard` (show clean text badge `6.0s`).
- Remove `showChevron: true` (set `showChevron: false`) on `CraftActionCard`.
- Clean up Quick Stats Dashboard: display clean metric numbers with `.fontDesign(.rounded).monospacedDigit()` and clear labels without cluttered mini icons.
- Polish Dismiss (X) button with clean glass style.

- [ ] **Step 2: Run component tests**
Run: `swift test --filter ReflexBlitzComponentsTests`
Expected: PASS.

- [ ] **Step 3: Verify with full test suite, SwiftLint and Xcode build**
Run: `swift test && swiftlint lint --strict`
Expected: 100% tests passing, 0 lint warnings.

- [ ] **Step 4: Commit**
```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzModeSelectionView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "style(reflex): polish Reflex Blitz Hub layout, reduce icon clutter and refine hierarchy"
```
