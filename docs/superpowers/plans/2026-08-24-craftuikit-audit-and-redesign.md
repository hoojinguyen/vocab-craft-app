# CraftUIKit 3D Tactile & Modern Typography Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize all core vocabulary learning components and design tokens in `CraftUIKit` to provide a tangible, dopamine-rich 3D tactile experience with a friendly, modern typography scale (SF Pro Rounded + Grotesque + SF Mono) and strict anti-AI-slop compliance.

**Architecture:** Introduce `CraftDepthTokens` for standardized 3-layer physical extrusions (`depthSm`, `depthMd`, `depthLg`, top rim highlight bevels, and bottom lips) integrated into `CraftTheme`. Update typography away from classical serifs to modern SF Pro Rounded. Elevate core components (`CraftButton`, `CraftChoiceCard`, `CraftLessonNode`, `CraftFlipCard`, `CraftCard`, `CraftStreakCard`, `CraftFloatingTabBar`) with tactile press dynamics, spring physics, and sensory feedback.

**Tech Stack:** Swift 5.10+, SwiftUI (iOS 17+ / macOS 14+), SF Symbols, CoreHaptics / `sensoryFeedback`.

**Spec:** [`docs/superpowers/specs/2026-08-24-craftuikit-audit-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-24-craftuikit-audit-design.md)

## Global Constraints

- Platform targets: iOS 17.0+, macOS 14.0+.
- All readable text must scale with Dynamic Type (`@ScaledMetric` / standard dynamic text styles).
- Strict minimum 44×44pt touch target bounding box for all interactive controls.
- Anti-AI-slop compliance: No generic purple-blue gradients, no emoji as functional icons, no random spacing.
- Accessibility reduce motion: Fallback to opacity and subtle scaling when `accessibilityReduceMotion` is enabled.
- WCAG AAA contrast ratio across Light and Dark appearances.

---

### Task 1: Tokens & Depth Engine Modernization

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftDepthTokens.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTypographyTokens.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftDefaultTheme.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Environment/CraftThemeEnvironment.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/TokenTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftColorTokens`
- Produces:
  - `CraftDepthTokens` protocol (`depthSm: CGFloat`, `depthMd: CGFloat`, `depthLg: CGFloat`, `topHighlightLinearGradient: LinearGradient`)
  - Updated `CraftDefaultTypographyTokens` using SF Pro Rounded for display/headings/metrics, SF Pro Default for body/labels, and SF Mono for phonetics.
  - `CraftTheme.depths: CraftDepthTokens`

- [ ] **Step 1: Write unit tests for `CraftDepthTokens` and modernized `CraftTypographyTokens`**

Add tests in `CraftUIKit/Tests/CraftUIKitTests/TokenTests.swift` checking `depthSm == 2`, `depthMd == 4`, `depthLg == 6`, and verifying that `CraftDefaultTypographyTokens` initializes without error and provides valid fonts for all styles.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TokenTests`
Expected: FAIL (missing `depths` property on `CraftTheme` and missing `CraftDepthTokens`).

- [ ] **Step 3: Implement `CraftDepthTokens.swift` and update `CraftTheme.swift`, `CraftDefaultTheme.swift`, `CraftTypographyTokens.swift`**

Create `CraftDepthTokens.swift`:
```swift
import SwiftUI

public protocol CraftDepthTokens: Sendable {
    var depthSm: CGFloat { get }
    var depthMd: CGFloat { get }
    var depthLg: CGFloat { get }
    var topHighlight: LinearGradient { get }
}

public struct CraftDefaultDepthTokens: CraftDepthTokens {
    public var depthSm: CGFloat
    public var depthMd: CGFloat
    public var depthLg: CGFloat
    public var topHighlight: LinearGradient

    public init(
        depthSm: CGFloat = 2,
        depthMd: CGFloat = 4,
        depthLg: CGFloat = 6,
        topHighlight: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.35), Color.white.opacity(0.08), Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
    ) {
        self.depthSm = depthSm
        self.depthMd = depthMd
        self.depthLg = depthLg
        self.topHighlight = topHighlight
    }
}
```

Update `CraftTypographyTokens.swift` default implementations to use `.system(..., design: .rounded)` for `displayLarge`, `displayHero`, `titleLarge`, `titleMedium`, `headline`, `metricRounded`, and `label`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TokenTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Tokens/ CraftUIKit/Sources/CraftUIKit/Environment/ CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(tokens): add CraftDepthTokens and modernize CraftTypographyTokens with rounded hierarchy"
```

---

### Task 2: Tactile 3D Controls & Interactive Quiz Card

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftDepthTokens`, `CraftTypographyTokens`
- Produces:
  - `CraftButtonStyle` with enhanced `.tactile` 3D extrusion, top rim highlight, and mechanical depress offset.
  - `CraftChoiceCard` with 3D bottom bevel, embossed A/B/C/D badges, 1.02x correct bounce, and horizontal shake.

- [ ] **Step 1: Write tests for 3D tactile button style and choice card 3D states**

In `ControlComponentTests.swift` and `InteractiveCardTests.swift`, verify `CraftButtonVariant.tactile` rendering, touch target size ≥ 44pt, and `CraftChoiceCard` state transitions (`idle`, `selected`, `correct`, `wrong`).

- [ ] **Step 2: Run test to verify it passes/fails**

Run: `swift test --filter ControlComponentTests`

- [ ] **Step 3: Refine `CraftButton.swift` and `CraftChoiceCard.swift`**

Enhance `CraftButtonStyle` to use `theme.depths.depthMd` for the tactile bottom lip offset, and add a top highlight stroke.
Update `CraftChoiceCard.swift` to incorporate a 3D bottom lip in `.idle` / `.selected` / `.correct` / `.wrong` states, with mechanical offset on press.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ControlComponentTests`
Run: `swift test --filter InteractiveCardTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/ CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(controls): enhance tactile 3D button and choice card physics"
```

---

### Task 3: Learning Journey & 3D Tactile Lesson Nodes

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/MetricsProgressionTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `LessonNodeModel`, `CraftDepthTokens`
- Produces:
  - 3D extruded cylindrical / hexagonal lesson nodes with top highlight bevel and pulsing halo aura.
  - Serpentine snake path with smooth anchor resolution.

- [ ] **Step 1: Write/update tests for 3D lesson node rendering and accessibility**

In `CraftLearningPathTests.swift`, verify node diameter calculations, accessibility labels, star ratings (1-3 gold stars), and state transitions (`active`, `completed`, `locked`, `checkpoint`, `treasureChest`).

- [ ] **Step 2: Run test to verify current status**

Run: `swift test --filter CraftLearningPathTests`

- [ ] **Step 3: Refine `CraftLessonNode.swift` & `CraftStepNode.swift`**

Enhance `CraftLessonNode` to utilize `theme.depths` for bottom rim offsets, highlight strokes, SF Pro Rounded labels, and haptic triggers (`sensoryFeedback`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Run: `swift test --filter MetricsProgressionTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/ CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(learning-path): elevate lesson nodes with 3D pedestal extrusions and modern rounded labels"
```

---

### Task 4: 3D Vocabulary Flip Card & Bento Containers

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftDepthTokens`
- Produces:
  - `CraftFlipCard` with simulated card edge thickness and specular glare animation.
  - `CraftCardStyle.tactile3D` container with 4pt extruded base and interactive press mechanics.

- [ ] **Step 1: Write tests for `CraftCardStyle.tactile3D` and `CraftFlipCard`**

In `ContainerOverlayTests.swift`, add test verifying `CraftCardStyle.tactile3D` applies appropriate background, 3D bottom bevel, and press button style.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ContainerOverlayTests`
Expected: FAIL (missing `.tactile3D` case in `CraftCardStyle`).

- [ ] **Step 3: Implement `.tactile3D` in `CraftCard.swift` and specular glare in `CraftFlipCard.swift`**

Add `.tactile3D` to `CraftCardStyle`. Render a 3D bottom bevel and top highlight stroke when `.tactile3D` is selected.
Enhance `CraftFlipCard` with simulated edge stroke and a passing specular sheen gradient on rotation.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ContainerOverlayTests`
Run: `swift test --filter InteractiveCardTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/ CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(containers): add tactile3D card style and specular glare to 3D flip card"
```

---

### Task 5: Gamification, Streak Bento & Feedback Systems

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftStreakBadge.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift`

**Interfaces:**
- Consumes: `CraftStreakData`, `CraftTheme`, `CraftTabItemProtocol`
- Produces:
  - `CraftStreakCard` 7-day Bento widget with embossed 3D day nodes and `metricRounded` counters.
  - `CraftFloatingTabBar` with liquid glass material, sliding indicator, and 3D center FAB.
  - `CraftStreakCelebrationSheet` with confetti and 3D CTA.

- [ ] **Step 1: Write/update tests for streak bento and navigation bar**

In `CraftStreakComponentTests.swift` and `NavigationTests.swift`, verify 7-day node statuses, freeze badge interactions, and center action FAB behavior.

- [ ] **Step 2: Run tests to verify status**

Run: `swift test --filter CraftStreakComponentTests`
Run: `swift test --filter NavigationTests`

- [ ] **Step 3: Refine `CraftStreakCard.swift`, `CraftStreakCelebrationSheet.swift`, and `CraftFloatingTabBar.swift`**

Update `CraftStreakCard` to use modern rounded typography (`.metricRounded`), 3D embossed nodes, and ensure all buttons meet 44pt touch targets.
Update `CraftFloatingTabBar` center action button with 3D tactile bevel.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter CraftStreakComponentTests`
Run: `swift test --filter NavigationTests`
Run: `swift test --filter FeedbackFXTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/ CraftUIKit/Tests/CraftUIKitTests/
git commit -m "feat(gamification): elevate streak bento dashboard and floating tab bar with 3D tactile accents"
```

---

### Task 6: Interactive Showcase Catalog & Full Regression Testing

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Consumes: All `CraftUIKit` components and tokens
- Produces: Complete, interactive 14-section design system gallery showcasing 3D tactile buttons, flip cards, quiz cards, streak bento, and learning paths.

- [ ] **Step 1: Update `CraftCatalogView.swift`**

Ensure all showcase sections demonstrate the new 3D tactile variants, typography styles, flip card interactions, and streak tier presets.

- [ ] **Step 2: Run full test suite**

Run: `swift test`
Expected: 280+ tests PASS with 0 failures.

- [ ] **Step 3: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/ CraftUIKit/Tests/CraftUIKitTests/
git commit -m "chore(catalog): update interactive gallery for 3D tactile design system"
```
