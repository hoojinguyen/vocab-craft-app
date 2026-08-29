# Reflex Summary Bottom Dock Styling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the sticky bottom action dock in `ReflexBlitzSummaryView` and `MixedReflexSummaryView` with seamless canvas background matching, top gradient transition, improved button spacing, and adjusted bottom safe-area insets.

**Architecture:** SwiftUI View styling adhering strictly to `CraftUIKit` tokens (`CraftSpacingTokens`, `CraftColorTokens`). The sticky bottom action dock replaces `.fill(.ultraThinMaterial)` and `.craftShadow` with `theme.colors.canvasBackground` and a top gradient fade. Button spacing is expanded to `theme.spacing.md`, bottom padding to `theme.spacing.lg`, and button sizes are standardized to `.lg`.

**Tech Stack:** SwiftUI, CraftUIKit, Swift Testing / XCTest.

## Global Constraints
- Strictly adhere to `CraftUIKit` design tokens (`theme.colors.canvasBackground`, `theme.spacing.md`, `theme.spacing.lg`, `theme.spacing.base`).
- Zero hardcoded colors, zero magic spacing numbers.
- Zero compiler warnings and zero SwiftLint errors.

---

### Task 1: Redesign bottom action dock and scroll insets in `ReflexBlitzSummaryView`

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzSummaryView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzSummaryView(summary:onSpeakWord:onReDrillWeak:onFinish:)`, `CraftButton`, `CraftTheme`
- Produces: Updated `ReflexBlitzSummaryView` with refined dock layout, seamless background, and top gradient fade.

- [ ] **Step 1: Update `ReflexBlitzSummaryViewTests.swift` to verify dock and view structure**

Add unit tests verifying `ReflexBlitzSummaryView` instantiates correctly and renders buttons with expected callback interactions.

- [ ] **Step 2: Run tests to verify baseline**

Run: `swift test --filter ReflexBlitzSummaryViewTests`
Expected: PASS

- [ ] **Step 3: Update `ReflexBlitzSummaryView.swift`**

1. In `bottomActionDock`:
   - Change `VStack(spacing: theme.spacing.xs)` to `VStack(spacing: theme.spacing.md)`.
   - Update secondary finish button `size` from `.md` to `.lg`.
   - Update dock padding:
     - `.padding(.horizontal, theme.spacing.base)`
     - `.padding(.top, theme.spacing.md)`
     - `.padding(.bottom, theme.spacing.lg)`
   - Replace the background `.fill(.ultraThinMaterial)` and `.craftShadow(theme.shadows.sm)` with:
     ```swift
     .background(
         VStack(spacing: 0) {
             LinearGradient(
                 colors: [theme.colors.canvasBackground.opacity(0), theme.colors.canvasBackground],
                 startPoint: .top,
                 endPoint: .bottom
             )
             .frame(height: 20)

             theme.colors.canvasBackground
         }
         .ignoresSafeArea(edges: .bottom)
     )
     ```
2. In `body`:
   - Update `ScrollView` bottom padding:
     ```swift
     .padding(.bottom, summary.weakWordAttempts.isEmpty ? 140 : 200)
     ```

- [ ] **Step 4: Run tests to verify implementation**

Run: `swift test --filter ReflexBlitzSummaryViewTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzSummaryView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift
git commit -m "style: update ReflexBlitzSummaryView bottom dock styling and spacing"
```

---

### Task 2: Redesign bottom action dock and scroll insets in `MixedReflexSummaryView`

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexSummaryView.swift`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`

**Interfaces:**
- Consumes: `MixedReflexSummaryView(summary:practicedWords:onSpeakWord:onRetry:onDone:)`, `CraftButton`, `CraftTheme`
- Produces: Updated `MixedReflexSummaryView` with refined dock layout, seamless background, and top gradient fade.

- [ ] **Step 1: Update `MixedReflexDrillViewsTests.swift` if needed**

Verify `testMixedReflexSummaryView` covers the view interactions and callbacks.

- [ ] **Step 2: Run tests to verify baseline**

Run: `swift test --filter testMixedReflexSummaryView`
Expected: PASS

- [ ] **Step 3: Update `MixedReflexSummaryView.swift`**

1. In `stickyBottomActionDock`:
   - Change `VStack(spacing: theme.spacing.xs)` to `VStack(spacing: theme.spacing.md)`.
   - Update dock padding:
     - `.padding(.horizontal, theme.spacing.base)`
     - `.padding(.top, theme.spacing.md)`
     - `.padding(.bottom, theme.spacing.lg)`
   - Replace the background `.fill(.ultraThinMaterial)` and `.craftShadow(theme.shadows.sm)` with:
     ```swift
     .background(
         VStack(spacing: 0) {
             LinearGradient(
                 colors: [theme.colors.canvasBackground.opacity(0), theme.colors.canvasBackground],
                 startPoint: .top,
                 endPoint: .bottom
             )
             .frame(height: 20)

             theme.colors.canvasBackground
         }
         .ignoresSafeArea(edges: .bottom)
     )
     ```
2. In `body`:
   - Update `ScrollView` bottom padding from `110` to `200`.

- [ ] **Step 4: Run tests to verify implementation**

Run: `swift test --filter testMixedReflexSummaryView`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexSummaryView.swift VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift
git commit -m "style: update MixedReflexSummaryView bottom dock styling and spacing"
```

---

### Task 3: Quality Gate Verification & Diagnostics

**Files:**
- None (Verification only)

- [ ] **Step 1: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings

- [ ] **Step 2: Run Full Unit & Localization Test Suite**

Run: `swift test`
Expected: All tests pass

- [ ] **Step 3: Run Xcode Build Verification**

Verify project builds cleanly with 0 errors and 0 warnings.
