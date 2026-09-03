# Design Specification: `CraftFluidJourney` Visual Refinements & Surface Style Architecture

- **Author**: Antigravity & Pair Programming Partner
- **Date**: 2026-09-03
- **Status**: Validated Design Spec (Awaiting User Review Gate)
- **Branch**: `feature/craft-fluid-journey`
- **Target Components**: 
  - `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`
  - `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/`
  - `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/`
- **Host Feature**: `VocabCraftApp/Features/Homepage/`

---

## 1. Executive Summary & Real-Device Testing Feedback

Interactive testing on real iOS device ("Hooji") with `feature/craft-fluid-journey` revealed four key visual and architectural friction points:

1. **Header & Milestone Stacking Redundancy**: When opening the home screen at the top, the pinned card (`CraftPinnedUnitHeader`) already presents Unit 1. Immediately below, the in-scroll milestone pill (`CraftMilestonePill`) redundantly duplicates "Unit 1", creating awkward double-labeling.
2. **Node Visual Monotony & Sizing Disparity**: The nodes were simple, rigid 100% circles. Completed (68pt), locked (60pt), and active (82pt) nodes had divergent sizes, breaking visual rhythm. In the inspiration app, all nodes maintain a consistent base size with an organic, "slightly rounded" squircle contour.
3. **Overuse of Generic Padlock Icons**: Inactive/locked lesson nodes replaced the curriculum icon with a repetitive `lock.fill` icon everywhere, concealing what skill or topic was coming next. All lessons must display their distinct topic icon.
4. **Absence of `CraftSurfaceStyle` Theme Support**: `CraftJourneyNode` hardcoded flat/tint colors and lacked support for the 5 design system surface styles (`elevated`, `flat`, `outlined`, `tactile3D`, `glass`), preventing themes like `CraftTactileClayTheme` or `CraftAIAcousticTheme` from expressing their unique visual DNA on the learning path.

---

## 2. Architecture & Design Specification

### 2.1 Pinned Deck Header vs. In-Scroll Milestone Hierarchy
- **Top Pinned Header (`CraftPinnedUnitHeader`)**:
  - Serves as the overarching Curriculum/Deck Portal.
  - Displays: Course level (e.g. `A2`), Deck Name (e.g. `Introducing Yourself and Others`), and Goal/Active Lesson subtitle.
- **In-Scroll Milestone Pills (`CraftMilestonePill`)**:
  - Represent specific grammar/thematic sub-topic boundaries along the path (e.g. `Present Simple for Personal Facts`, `Reading Professional Bios`).
  - The first milestone pill below the pinned header displays the first sub-topic, eliminating the redundant "Unit 1" text duplication.

### 2.2 Uniform Smooth Continuous Squircle Nodes
- **Uniform Dimensions**:
  - All progression states (`active`, `inProgress`, `completed`, `upcoming`, `locked`, `bonus`) share the identical base size: **88x88pt** (scaled dynamically with `@ScaledMetric`).
- **Organic Geometry**:
  - Replaces rigid `Circle()` with iOS continuous superellipse:
    `RoundedRectangle(cornerRadius: 30 * baseScale, style: .continuous)`.
- **Active State Distinction (No Size Ballooning)**:
  - Does NOT mechanically expand to a massive circle.
  - Retains the 88x88pt squircle footprint.
  - Stands out prominently via:
    1. Rich solid brand primary fill (`theme.gradients.brandHero` or `theme.colors.brandPrimary`).
    2. Pure white icon (`theme.colors.textInverse`) in bold weight.
    3. Soft breathing glow aura (`PhaseAnimator` with `.craftGlow`) pulsing gently in the ambient background.
    4. Optional compact "START LESSON" capsule tag positioned below the squircle.
- **Completed State**:
  - Translucent soft brand tint fill (`theme.colors.brandPrimary.opacity(0.14)`).
  - Lesson icon in `theme.colors.brandPrimary`.
  - Green status badge (`theme.colors.statusSuccess`) with white checkmark (`✓`) positioned at the bottom-right corner (offset `x: 4, y: 4`).
- **Inactive / Locked State**:
  - Subtle surface background (`theme.colors.surfaceSubtle`).
  - Always displays the lesson's actual topic icon (`node.iconName`) in muted tone (`theme.colors.textMuted` at 0.70 opacity).
  - **Zero Padlock Icons**: No replacement of the icon with `lock.fill`. The muted tone, subtle surface, and disabled tap physics communicate the locked state cleanly.

### 2.3 `CraftTheme` Surface Style Architecture & 5-Variant Support

#### A. Protocol Expansion
Add `journeySurfaceStyle` to `CraftTheme` with a default implementation:
```swift
public protocol CraftTheme: Sendable {
    // ... existing tokens ...
    var journeySurfaceStyle: CraftSurfaceStyle { get }
}

public extension CraftTheme {
    var journeySurfaceStyle: CraftSurfaceStyle {
        .elevated
    }
}
```

#### B. Theme Presets Customization
Each theme implements its signature surface aesthetic:
- `CraftDefaultTheme`: `.elevated` (delicate multi-layer drop shadows `theme.shadows.sm`, modern clean)
- `CraftTactileClayTheme` & `CraftNeoArcadeTheme`: `.tactile3D` (mechanical 3D bottom bevel extrusion `depthMd`, top specular highlight, spring depress physics on tap)
- `CraftAIAcousticTheme`: `.glass` (frosted liquid glass with `.ultraThinMaterial`, `theme.glass.borderGradient` refraction border)
- `CraftNordicZenTheme`: `.flat` (minimalist Scandinavian flat color planes, zero shadows, pure serenity)
- `CraftOxfordHeritageTheme`: `.outlined` (academic crisp 1.5pt border strokes, subtle fills)
- `CraftSolarMomentumTheme`: `.elevated`
- `CraftKyotoMatchaTheme`: `.elevated`
- `CraftPlayfulOwlTheme`: `.tactile3D`

#### C. Cascading Priority Resolution in `CraftJourneyNode`
Surface style is resolved in order:
1. Explicit parameter passed to `CraftJourneyNode(node:surfaceStyle:)` (if non-nil).
2. Environment value `@Environment(\.craftSurfaceStyle)` (if overridden by parent view modifier).
3. Theme default `@Environment(\.craftTheme).journeySurfaceStyle`.

#### D. Visual Implementation of the 5 Surface Styles on Squircle
1. **`.elevated`**:
   - Background: `SquircleShape` filled with state color/tint.
   - Border: Hairline border `theme.colors.hairline`.
   - Depth: Multi-layer soft shadow `.craftShadow(theme.shadows.sm)` (completed/inactive) or `.craftShadow(theme.shadows.md)` (active).
2. **`.flat`**:
   - Background: `SquircleShape` filled with flat state color/tint.
   - Border: None.
   - Depth: None (flat 2D plane).
3. **`.outlined`**:
   - Background: `SquircleShape` filled with `surfaceCard` or subtle tint.
   - Border: Crisp 1.5pt stroke `theme.colors.borderDefault` (muted for locked, `brandPrimary` for completed/active).
   - Depth: None.
4. **`.tactile3D`**:
   - Bottom Rim: 3D bevel extrusion offset by `theme.depths.depthMd` (4pt).
   - Top Highlight: Specular hairline on top rim `theme.depths.topHighlight`.
   - Interaction: Button style with spring mechanical press translating top face down by `depthMd`.
5. **`.glass`**:
   - Background: `.ultraThinMaterial` frosted glass blur combined with state tint overlay.
   - Border: Glass gradient specular stroke `theme.glass.borderGradient`.
   - Depth: Subtle glass glow reflection.

---

## 3. Impacted Files & Component Responsibilities

| Layer | File Path | Scope of Modification |
| :--- | :--- | :--- |
| **Tokens** | `CraftUIKit/Tokens/CraftTheme.swift` | Add `journeySurfaceStyle: CraftSurfaceStyle` token to protocol + default extension. |
| **Themes** | `CraftUIKit/Tokens/Themes/*.swift` | Configure `journeySurfaceStyle` across all preset themes (`TactileClay`, `AIAcoustic`, `NordicZen`, `OxfordHeritage`, etc.). |
| **Component** | `CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift` | Refactor to 72x72pt continuous squircle, preserve topic icons (no lock.fill), implement all 5 `CraftSurfaceStyle` variants. |
| **Component** | `CraftUIKit/Components/Containers/FluidJourney/CraftMilestonePill.swift` | Align surface styling with `journeySurfaceStyle` tokens. |
| **Component** | `CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift` | Pass `surfaceStyle` downstream, refine milestone docking offset to prevent duplicate Unit 1 pill at top. |
| **App / Host**| `VocabCraftApp/Features/Homepage/Views/HomepageView.swift` & `ViewModels/` | Ensure learning path sections supply distinct sub-topic milestone titles for pills. |
| **Tests** | `CraftUIKitTests/CraftFluidJourneyTests.swift` | Comprehensive unit tests for 72pt squircle sizing, icon preservation on locked nodes, and 5 surface style rendering paths. |

---

## 4. Design System, Localization & Quality Compliance

- **Zero Hardcoded Strings**: All accessibility labels and hints strictly use `CraftLocalized.format(...)` and `CraftLocalized.string(...)` from `Localizable.xcstrings`.
- **Zero Raw Colors**: Strictly utilize semantic tokens (`theme.colors.brandPrimary`, `theme.colors.surfaceSubtle`, `theme.colors.textMuted`, etc.).
- **Strict Quality Gate**: 100% passing tests, 0 compiler warnings, 0 SwiftLint violations.
