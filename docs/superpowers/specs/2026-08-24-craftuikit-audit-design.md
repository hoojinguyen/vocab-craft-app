# CraftUIKit 3D Tactile & Modern Typography Design Specification

- **Date**: 2026-08-24
- **Scope**: Core Vocabulary Learning Experience Components & System-wide Design Tokens in `CraftUIKit`
- **Architectural Philosophy**: Tactile 3D Depth ("Digital Craft Toy") with Modern Rounded-Grotesque Typography

---

## 1. Overview & Objectives

`CraftUIKit` is the dedicated design system and component library powering **VocabCraft** — an iOS application for vocabulary mastery and language acquisition. 

This design specification establishes the architectural and visual standards for modernizing `CraftUIKit` based on:
1. **`swiftui-design-skill`**: Strict adherence to the 6 Anti-AI-Slop rules, 8pt spatial grid system, semantic token architecture, and the 5-Dimension Review criteria.
2. **`ios-design-agent-skill`**: Deep optimization across the 5 Pillars (Typography axes, Color & Theme depth, Spatial Composition, Motion & Feedback choreography, Atmospheric 3D Depth).
3. **Tactile 3D Visual Language**: Providing physical extrusion depth (bevels, bottom lips, mechanical press translation, dynamic highlights, and specular glare) to make learning tangible, playful, and dopamine-inducing.
4. **Modernized Typography**: Shifting away from stiff classical serifs toward a friendly, approachable hierarchy built on SF Pro Rounded (Display/Headings/Metrics), SF Pro Grotesque (Body text/Meanings), and SF Mono (IPA phonetics/Counters).

---

## 2. Design Tokens & Depth Architecture

### 2.1 Typography System (`CraftTypographyTokens`)

The typography system is structured around semantic roles and specialized domain axes:

```swift
public protocol CraftTypographyTokens: Sendable {
    var displayHero: Font { get }      // 64-72pt, .heavy, .rounded (Milestones, Big Streaks)
    var displayLarge: Font { get }     // .largeTitle, .bold, .rounded (Screen headers)
    var titleLarge: Font { get }       // .title, .bold, .rounded (Card headers, units)
    var titleMedium: Font { get }      // .title2, .semibold, .rounded (Sub-headers)
    var headline: Font { get }         // .headline, .bold, .rounded (Buttons, questions)
    var bodyLarge: Font { get }        // .body, .regular, .default (Word definitions)
    var bodyMedium: Font { get }       // .callout, .regular, .default (Secondary details)
    var label: Font { get }            // .subheadline, .semibold, .rounded (Badges, tags)
    var phonetic: Font { get }         // .callout, .medium, .monospaced (IPA transcriptions)
    var metricRounded: Font { get }    // .title2, .bold, .rounded (Counters, numbers)
    var caption: Font { get }          // .caption, .medium, .default (Timestamps, hints)
}
```

### 2.2 Color & Surface Palette (`CraftColorTokens`)

The color system uses warm, natural tones avoiding generic saturated AI-slop gradients:

* **Canvas Background**:
  * Light: Warm Off-White (`#FAFAF8`)
  * Dark: Deep Charcoal (`#121214`)
* **Surfaces**:
  * `surfaceCard`: Pure White (`#FFFFFF`) / Dark Zinc (`#1C1C1E`)
  * `surfaceElevated`: Elevated White (`#FFFFFF`) / Medium Zinc (`#2C2C2E`)
  * `surfaceSubtle`: Soft Warm Ivory (`#F4F4F0`) / Muted Zinc (`#242426`)
* **Brand & Action**:
  * `brandPrimary`: Warm Terracotta (`#E06D3B`)
  * `brandSecondary` (3D Lip): Deep Terracotta/Amber (`#C2410C`)
  * `accent`: Amber Glow (`#F59E0B`)
* **Status & Feedback**:
  * `statusSuccess`: Emerald Leaf (`#10B981`)
  * `statusWarning`: Warm Amber (`#F59E0B`)
  * `statusDanger`: Coral Crimson (`#EF4444`)
  * `statusInfo`: Sky Azure (`#0284C7`)
  * `streakFreeze`: Glacial Ice (`#38BDF8`)

### 2.3 Physical 3D Depth Engine (`CraftDepthTokens`)

All tactile components utilize a standardized 3-layer extrusion model:

```
┌────────────────────────────────────────────────────────┐  ◄── Top Rim Highlight (White 35% -> Clear)
│                   TOP FACE SURFACE                     │
│  (Slight gradient fill, interactive icons & typography)│
└────────────────────────────────────────────────────────┘
│                 EXTRUDED 3D BOTTOM LIP                 │  ◄── Bevel depth (2pt, 4pt, 6pt in dark tone)
└────────────────────────────────────────────────────────┘
 ░░░░░░░░░░░░░░░░░░ Multi-layer Ambient Shadow ░░░░░░░░░░░   ◄── Soft diffused contact shadow
```

* **Extrusion Scales**:
  * `depthSm` = `2pt` (Chips, Badges, Small Controls)
  * `depthMd` = `4pt` (Buttons, Choice Cards, Lesson Nodes)
  * `depthLg` = `6pt` (Hero Cards, Milestone Nodes, Celebration Containers)
* **Mechanical Translation**:
  * On touch down: Top face shifts down by `+depth` along the Y-axis.
  * Haptic trigger: `.impact(weight: .medium)` upon depression.
  * Accessibility: When `accessibilityReduceMotion` is active, Y-translation is replaced by smooth opacity/scale adjustments.

---

## 3. Component Architecture: Core Learning Experience

### 3.1 Learning Path & Journey Nodes (`CraftLessonNode`, `CraftStepNode`, `CraftLearningPath`)

* **3D Pedestal Geometry**:
  * Standard Lesson: Circular 3D cylinder with top highlight stroke and bottom rim extrusion.
  * Checkpoint (Boss): Hexagonal 3D polygon with beveled multifaceted borders.
  * Treasure Chest: Embossed golden reward chest with ambient shimmer animation.
* **State Behavior**:
  * `active`: Pulsing soft halo cushion disc (`pathHaloGlow`) + oscillating speech bubble ("TIẾP TỤC").
  * `completed`: Emerald 3D base + checkmark symbol + spring bounce + 1 to 3 gold reward stars.
  * `inProgress`: Circular or hexagonal progress trimming arc with rounded endpoints.
  * `locked`: Muted gray pedestal with tactile lock icon and error-haptic shake on interaction attempts.
* **Snake Path Geometry (`CraftSnakePathGeometry`)**:
  * Adaptive bezier curve interpolation connecting node center anchors dynamically across serpentine winding patterns (`standard`, `gentle`, `linear`).

### 3.2 3D Vocabulary Flashcard (`CraftFlipCard`)

* **3D Flip Mechanics**:
  * Double-sided 180° rotation on the Y-axis (or X-axis) with true perspective projection (`perspective: 0.5`).
  * Simulated card depth with rounded edges and multi-stop borders.
  * **Specular Glare Effect**: Subtle linear gradient highlight traversing across the surface during mid-flip.
* **Card Faces**:
  * *Front Face*: Vocabulary keyword (`.displayLarge` / `.titleLarge` Rounded), IPA phonetic transcription tag in SF Mono, audio pronunciation button with tactile press.
  * *Back Face*: Vietnamese meaning (`.headline`), contextual example sentence (`.bodyMedium`), mnemonic/image container, word category chip.
* **Sensory Feedback**: Automatic `.impact(weight: .medium)` trigger on rotation completion.

### 3.3 Tactile Quiz Choice Card (`CraftChoiceCard`)

* **3D Choice Architecture**:
  * Raised card surface with 3pt bottom 3D bevel and 1.5pt border stroke.
  * Embossed prefix badge (A, B, C, D) with high contrast background and rounded corners.
* **Validation Choreography**:
  * *Selected*: 1.5pt Terracotta border + 16% tinted background fill + subtle press depression.
  * *Correct*: Emerald green surface + hierarchical checkmark icon + 1.02x spring scale bounce + `.sensoryFeedback(.success)`.
  * *Wrong*: Coral red surface + hierarchical X icon + horizontal 3D shake animation + `.sensoryFeedback(.error)`.

---

## 4. Gamification, Containers & Navigation

### 4.1 7-Day Streak Bento Dashboard (`CraftStreakCard` & `CraftStreakBadge`)

* **Header**: Dynamic tier flame icon (Starter / Blaze / Legendary gradient) + `metricRounded` day counter + best streak trophy pill badge.
* **Week Track**: 7 tactile circular day nodes (T2 to CN):
  * *Completed*: Glowing 3D flame button.
  * *Today Pending*: Breathing dashed border with soft amber background cushion.
  * *Frozen*: Ice blue translucent 3D shield with snowflake icon.
  * *Missed*: Subtle recessed node.
* **Footer**: Interactive freeze shield counter button + animated milestone progress bar.
* **Celebration Sheet (`CraftStreakCelebrationSheet`)**: Modal presentation with confetti burst (`CraftConfetti`), sparkle particles (`CraftSparkleView`), and prominent tactile 3D CTA.

### 4.2 Bento Card Containers (`CraftCard`)

* Style variants:
  * `.tactile3D`: 4pt extruded base, top highlight bevel, multi-layer elevation shadow, interactive tactile press physics.
  * `.flat`, `.elevated`, `.outlined`, `.gradient`.
* Full support for Bento grid layouts with dynamic padding and customizable corner radii.

### 4.3 Floating Navigation Bar (`CraftFloatingTabBar`)

* Floating pill shape rendered with `.ultraThinMaterial` and gradient edge lighting.
* Sliding tab selection indicator with `matchedGeometryEffect` and `springSnappy` physics.
* **Integrated 3D Center FAB**: Circular extruded tactile action button with 44×44pt touch target and haptic impact on tap.
* Auto-sizing numeric badge counters with `.numericText()` transition animations.

### 4.4 Overlays & Feedback Systems

* **`CraftBottomSheet`**: Drag-dismissible modal container with customizable detents, top radius 24pt, drag indicator, and ambient dimmed backdrop.
* **`CraftDialog`**: Structured modal dialog with hierarchical icon header, clear typography, and 3D primary/danger/cancel action buttons.
* **`CraftToast`**: Auto-dismissing pill toast notifications with 4 semantic styles (`success`, `warning`, `danger`, `info`).
* **`CraftWaveformView`**: Interactive speech waveform visualizer for real-time pronunciation drills.
* **`CraftCountdownOverlay`**: 3-2-1-GO! countdown overlay with spring scaling and haptic clock ticks for reflex drills.

---

## 5. Accessibility & Platform Standards

1. **Dynamic Type Compatibility**: All text elements use scalable system font scales (`@ScaledMetric` and standard text styles).
2. **WCAG AAA Contrast**: Dark text on bright/amber badges (`.warning` tone uses dark ink); dark mode provides high-contrast luminance separation.
3. **Accessibility Reduce Motion**: All translation animations, pulsating auras, continuous shakes, and 3D rotations fall back to static or opacity-based transitions when `accessibilityReduceMotion` is enabled.
4. **Touch Target Size**: Strict minimum 44×44pt bounding box for all interactive controls, buttons, nodes, and tabs.
5. **Dark Mode Fidelity**: Dynamic semantic color adaptation via `.craftDynamic(light:dark:)` across all tokens and gradients.

---

## 6. Verification & Testing Strategy

1. **Unit Test Suite (`CraftUIKitTests`)**:
   * Verify token resolutions, dynamic traits, accessibility labels, and theme overrides.
   * Test state mutations for `CraftChoiceCard`, `CraftLessonNode`, `CraftStreakCard`, and `CraftFlipCard`.
2. **Interactive Catalog (`CraftCatalogView`)**:
   * Visual and interactive regression testing across all 14 showcase sections.
   * Dynamic switching between Default Slate and Emerald Teal themes, plus Light/Dark modes.
