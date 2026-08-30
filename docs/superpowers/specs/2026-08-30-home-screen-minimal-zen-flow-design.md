# Feature Spec: Home Screen "Minimal Zen Flow" with Apple Books-Inspired Liquid Glass Header

- **Date:** 2026-08-30
- **Status:** Approved / Ready for Implementation Planning
- **Design School:** Minimal Zen Flow (Quiet Elegance & iOS 18/26 Liquid Glass)

---

## 1. Executive Summary

This specification defines the redesign and architectural refinement of the **VocabCraft Home Screen**. 

Inspired by **Apple Books** ("Quiet Elegance" philosophy) and **iOS Liquid Glass**, the Home Screen eliminates cognitive clutter, redundant greetings, and hardcoded styling in favor of:
1. An **Apple Books-style Large Title Header** (`Home` + Streak Flame + Daily Goal Ring + Avatar) that sits naturally in the scroll stream.
2. A **Scroll-driven Dynamic Transition**: As the user scrolls down into the Serpentine Learning Path, the primary header smoothly scrolls away and fades out.
3. A **Sticky Liquid Glass Unit Header (HUD)**: When scrolling deep into a Unit, the section header docks gracefully at the top of the viewport inside an ultra-thin translucent glass capsule, acting as a clear orientation compass without occluding content.
4. **Performance & Codebase Hygiene**: 120fps ProMotion fluidity, full Swift Observation optimization, removal of legacy Bento view files, and 100% bilingual localization (`en` / `vi`).

---

## 2. User Experience & Information Architecture

### 2.1 Screen States & Flow

```
STATE 1: AT TOP OF SCROLL (Apple Books Style)
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  Home                                            [ 🔥 14 ]   ( 8 )   (👤)   │
│                                                               10            │
│                                                                             │
│  UNIT 1: Daily Conversation ──────────────────────── 3/4 chặng              │
│                                                                             │
│                       ◯ (Node 1: Greetings - ⭐⭐⭐)                         │
│                      ╱                                                      │
│           (Node 2) ◯ (Introductions - ⭐⭐⭐)                                │
│                     ╲                                                       │
│                      ◯ (Node 3: Common Verbs - ⏳ Đang học)                 │
└─────────────────────────────────────────────────────────────────────────────┘

                                   ▼ (SCROLLING DOWN)

STATE 2: DEEP SCROLLING (Sticky Liquid Glass Unit HUD)
┌─────────────────────────────────────────────────────────────────────────────┐
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  ✨ UNIT 1: Daily Conversation                          3/4 chặng   │   │  <-- Liquid Glass Sticky HUD
│   └─────────────────────────────────────────────────────────────────────┘   │      (.ultraThinMaterial / Liquid Glass)
│                                                                             │
│                     ◯ (Node 3: Common Verbs - ⏳ Đang học)                 │
│                    ╱                                                        │
│         (Node 4) ⬡ (Checkpoint Boss Exam - 🔒)                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Header Elements & Interaction Details

| Element | Position | Visual Treatment | Interaction |
| :--- | :--- | :--- | :--- |
| **Title ("Home")** | Leading Top | Large Title (Apple Serif / Rounded bold typography, 34pt, `theme.colors.textPrimary`) | Non-interactive anchor. |
| **Streak Badge (`🔥 14`)** | Trailing Group (1) | `CraftStreakBadge` (Compact pill, glowing flame tier, monospaced digits) | Tapping presents Streak Celebration / History Modal. |
| **Daily Goal Ring (`CraftProgressRing`)** | Trailing Group (2) | Circular progress ring (36pt, `vocabMint` tint, hairline width, `8/10` words text in center) | Visual progress indicator for closure. |
| **Profile Avatar** | Trailing Group (3) | 36pt circular avatar with user initials / photo | Tapping opens Profile & Settings. |

---

## 3. Technical Architecture & Component Structure

### 3.1 Component Hierarchy

```
HomepageView (Top-level feature container)
 ├── Background: Color.vocabCanvas (or atmospheric wash)
 └── ScrollView (CoordinateSpace: "CraftLearningPathScrollView")
      └── VStack (spacing: 0)
           ├── HomeTopHeaderView (In-scroll: Title + Streak + Goal Ring + Avatar)
           └── CraftLearningPath (Serpentine path with pinned Section Headers & Sticky HUD)
                ├── CraftLessonSectionHeaderView
                └── CraftLessonSectionBodyView (Nodes & Snake Connectors)
```

### 3.2 Scroll-driven Sticky HUD Integration
- `CraftLearningPath` is configured with `pinSectionHeaders: true` and custom `stickyHUDBuilder`.
- When the user scrolls past `HomeTopHeaderView`, the active `LessonSection` automatically mounts into the sticky HUD slot with `GlassEffectContainer` / `.ultraThinMaterial`, `theme.depths.topHighlight`, and sensory haptic feedback on dock changes.

### 3.3 Design Tokens & Styling Compliance
- **Typography**: Strictly use `theme.typography.display`, `theme.typography.headline`, `theme.typography.label`, and `theme.typography.caption`. Zero hardcoded `.font(.system(...))` calls.
- **Colors & Surfaces**: Semantic colors (`theme.colors.textPrimary`, `theme.colors.brandPrimary`, `theme.colors.surfaceElevated`, `Color.vocabCanvas`).
- **Glass & Materials**: `CraftGlassTokens`, `CraftSurfaceStyle.glass`, and iOS 26 `GlassEffectContainer` with graceful fallback to `.ultraThinMaterial`.

---

## 4. Localization Specification (100% Bilingual EN & VI)

All user-facing strings are strictly maintained in `VocabCraftApp/Resources/Localizable.xcstrings` under the `app.home.*` namespace.

| Key | English (`en`) | Vietnamese (`vi`) | Description |
| :--- | :--- | :--- | :--- |
| `app.home.title` | `Home` | `Học tập` | Top Large Title |
| `app.home.header.daily_goal_count_format` | `%lld/%lld` | `%lld/%lld` | Inner text of Daily Goal Ring |
| `app.home.header.streak_format` | `%lld days` | `%lld ngày` | Accessibility value for streak badge |
| `app.home.header.daily_goal_a11y_format` | `Daily Goal: %lld of %lld words completed` | `Mục tiêu ngày: Hoàn thành %lld trên %lld từ` | Accessibility label for goal ring |

---

## 5. Performance, Cleanliness & Legacy Code Cleanup

### 5.1 Swift Observation Optimization
- `HomepageViewModel` is marked `@Observable` and `@MainActor`.
- Remove legacy Bento state bridges (`dueCardsCount`, `totalWords`, `retentionPercentage`, `suggestedWords`) from `HomepageViewModel.swift`.

### 5.2 Legacy Views Cleanup
Remove deprecated Bento files from `VocabCraftApp/Features/Homepage/Views/`:
- `ActionCardsGrid.swift`
- `CEFRDistributionCard.swift`
- `SRSMemoryHeroCard.swift`
- `SuggestedWordsCardView.swift`

Ensure corresponding test files (`BentoCardsTests.swift`) are updated or replaced with comprehensive `HomeTopHeaderViewTests.swift`.

---

## 6. Verification & Quality Gates

1. **Unit & View Tests**:
   - `HomepageViewModelTests`: Verify section loading, node selection, and streak data propagation.
   - `HomeLocalizationTests`: 100% parity for `en` and `vi` translations.
2. **SwiftLint & Compiler Verification**:
   - Zero errors, zero warnings.
3. **Interactive & Visual Quality**:
   - Verify smooth 120fps scrolling on Simulator/Device.
   - Verify smooth scroll-away of Large Title and seamless docking of the Sticky Liquid Glass Unit HUD.
