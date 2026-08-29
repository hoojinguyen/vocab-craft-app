# Reflex Summary Bottom Dock Styling Design

## Problem Statement
In `ReflexBlitzSummaryView` and `MixedReflexSummaryView`, the sticky bottom action dock currently uses `.fill(.ultraThinMaterial)` with a subtle shadow. This creates a noticeable contrasting gray container over the dark canvas background, making the UI feel heavy and disconnected. Furthermore, the spacing between the two action buttons (`theme.spacing.xs` = 4pt) and the bottom inset to the Home Indicator (`theme.spacing.md` = 12pt) is cramped.

## Goals & Requirements
1. **Seamless Background Integration**: Replace `.ultraThinMaterial` and drop shadow with `theme.colors.canvasBackground` matching the screen body background 100%.
2. **Smooth Scroll Transition**: Add a subtle vertical top gradient fade (`theme.colors.canvasBackground.opacity(0)` to `theme.colors.canvasBackground`) on the dock header so scrollable content glides softly beneath the buttons.
3. **Improved Spacing & Tap Target Comfort**:
   - Spacing between primary and secondary buttons: Increase from `theme.spacing.xs` (4pt) to `theme.spacing.md` (12pt).
   - Bottom padding of dock: Increase from `theme.spacing.md` (12pt) to `theme.spacing.lg` (24pt) above safe area.
   - Top padding of dock: Set to `theme.spacing.md` (12pt).
   - Button size: Standardize both buttons to `size: .lg` (52pt height) for balanced visual weight and ergonomic thumb taps.
4. **Scroll Content Inset Adjustment**: Increase ScrollView bottom padding to `200` (when weak words are present) and `140` (when empty/perfect score) to ensure all content can be scrolled fully above the action dock.

## Impacted Components

### 1. `ReflexBlitzSummaryView.swift`
- Update `bottomActionDock`:
  - VStack spacing: `theme.spacing.md`
  - Finish/Done button size: `.lg`
  - Padding: horizontal `theme.spacing.base`, top `theme.spacing.md`, bottom `theme.spacing.lg`
  - Background: `theme.colors.canvasBackground` with top gradient fade + `.ignoresSafeArea(edges: .bottom)`
- Update `summaryContent` / `ScrollView` bottom padding: `summary.weakWordAttempts.isEmpty ? 140 : 200`.

### 2. `MixedReflexSummaryView.swift`
- Update `stickyBottomActionDock`:
  - VStack spacing: `theme.spacing.md`
  - Finish button size: `.lg`
  - Padding: horizontal `theme.spacing.base`, top `theme.spacing.md`, bottom `theme.spacing.lg`
  - Background: `theme.colors.canvasBackground` with top gradient fade + `.ignoresSafeArea(edges: .bottom)`
- Update `ScrollView` bottom padding: `200`.

## Design Token Compliance
- Spacing: `theme.spacing.md` (12pt), `theme.spacing.lg` (24pt), `theme.spacing.base` (16pt).
- Color: `theme.colors.canvasBackground`, `theme.colors.brandPrimary`.
- No raw color literals or hardcoded magic values.

## Verification Plan
1. **Swift Testing & Unit Tests**: Run `swift test` to ensure zero regressions.
2. **SwiftLint**: Ensure zero lint warnings and violations.
3. **Build Verification**: Run xcodebuild to verify 0 errors and 0 warnings.
