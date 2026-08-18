# Design Document: Reflex Blitz UX/UI Refinement & Polish Specification

- **Date:** 2026-08-18
- **Author:** Antigravity & Pair Programming Partner
- **Status:** Proposed (Ready for Review)
- **Target Platform:** iOS 17.0+ (SwiftUI, Observation, Apple HIG)
- **Skill Alignment:** `swiftui-design-skill`, `ios-design-guidelines`

---

## 1. Executive Summary & Root Cause Analysis

Based on real-device Simulator auditing (Screenshots 13:47 & 13:48), the Spoken Reflex Blitz feature has 2 high-impact UX/UI design flaws that diminish the learning experience:

### 1.1. Drill Screen (Screen 1: 13:47)
1. **Active Recall Spoiling & Information Redundancy:**
   - The IPA phonetics (`/mə'tɪk.jə.ləs/`), Part of Speech (`ADJ.`), and initial letter (`m...`) are displayed simultaneously while drilling. Showing IPA before the user speaks reveals the exact pronunciation, defeating the purpose of subconscious recall.
   - `ADJ.` is duplicated in both the top pill and the bottom hint pill.
2. **Awkward Whitespace & Perimeter Timer Artifacts:**
   - The top half has high text density, the center has large dead whitespace, and the bottom speech dock is pushed far down.
   - The perimeter border stroke timer appears like a half-rendered border error on rectangular cards rather than an intentional countdown meter.
3. **Speech Recognition Feedback Quality:**
   - Raw live speech text (`"Hobbies haven't expand fluent..."`) is truncated (`a...`) and unformatted, offering no real-time validation for spoken words.
4. **Ergonomic Control Disconnect:**
   - The bottom action buttons (`Gõ phím` & `Bỏ qua`) are tiny capsules floating detached at the outer corners.

### 1.2. Summary Screen (Screen 2: 13:48)
1. **Critical IPA Text Wrapping Bugs (Craft Quality Failure):**
   - The horizontal stack layout `[Lemma] [POS • IPA]` with a trailing audio button and status badge forces phonetics to wrap across broken line boundaries:
     - `serendipity`: `/,ser.ən` wrapped into `'dɪp.ə.ti/`
     - `ephemeral`: `/ɪ` wrapped into `'fem.ər.əl/`
     - `luminous`: `/` wrapped into `'lu:.mə.nəs/`
2. **Missing Sticky Call to Action (Dead End UX):**
   - The Primary Action buttons ("Củng cố ngay X từ yếu" / "Hoàn thành") are at the bottom of the `ScrollView`. When 6+ words are missed, the screen cuts off without any visible CTA.
3. **Demotivating "Color Carnival" & Negative Tone:**
   - Top metrics use disparate icon colors (Orange ⚡, Mint ✓, Purple 🔥).
   - A vertical column of red `Hết giờ` pills conveys failure rather than constructive reinforcement.
4. **Non-Native Header:**
   - Unstyled emoji `🌱` paired with bold text violates native iOS aesthetic guidelines.

---

## 2. Core Design System & Tokens

To eliminate the "AI-generated / Color Carnival" look, the feature adopts a unified, intentional design token palette adhering to the 8pt grid and Apple HIG:

```swift
public enum ReflexBlitzTheme {
    // Primary & Accent (Forest & Warm Clay)
    public static let primary = Color(hex: "2B825B")         // Sage / Forest green
    public static let accent = Color(hex: "E86A38")          // Warm Clay for timer / high tempo
    public static let accentSubtle = Color(hex: "FDEEE8")    // Light warm peach
    public static let warning = Color(hex: "D97706")         // Amber for hints / review
    
    // Semantic Surfaces & Texts
    public static let canvas = Color(uiColor: .systemGroupedBackground)
    public static let cardSurface = Color(uiColor: .secondarySystemGroupedBackground)
    public static let textPrimary = Color(uiColor: .label)
    public static let textSecondary = Color(uiColor: .secondaryLabel)
    public static let textTertiary = Color(uiColor: .tertiaryLabel)
    public static let borderHairline = Color(uiColor: .separator)
    
    // Spacing (8pt Grid)
    public static let spaceXS: CGFloat = 4
    public static let spaceS: CGFloat = 8
    public static let spaceM: CGFloat = 16
    public static let spaceL: CGFloat = 24
    public static let spaceXL: CGFloat = 32
    
    // Radii
    public static let radiusS: CGFloat = 8
    public static let radiusM: CGFloat = 16
    public static let radiusL: CGFloat = 24
}
```

---

## 3. Screen 1: Reflex Drill View Redesign Specifications

```
┌─────────────────────────────────────────────────────────┐
│ [✕]                   10 / 10                           │
│ ━━━━━━━━━━━━━━━━━ (Top Smooth Timer Bar) ━━━━━━━━━━━━━━ │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │  [ ADJ. ]                                           │ │
│ │                                                     │ │
│ │  Tỉ mỉ, cẩn thận                                    │ │
│ │                                                     │ │
│ │  "She is [ • • • • • • ] about her work."           │ │
│ │                                                     │ │
│ │             [ 💡 Xem gợi ý ký tự ]                  │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│                (((( 🎙️ Đang nghe... ))))                │
│                 "meticulous quality..."                 │
│                                                         │
│ ┌───────────────────────────┬─────────────────────────┐ │
│ │      [⌨️ Gõ bàn phím]      │      [Bỏ qua ⏭️]        │ │
│ └───────────────────────────┴─────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 3.1. Progressive Disclosure for Hints & Scaffolding
- **Initial Challenge State (0.0s – 3.5s):**
  - Displays: **POS Badge** (`ADJ.`), **Vietnamese Meaning** (`Tỉ mỉ, cẩn thận`), and **Cloze Blank Sentence** (`She is ❲ • • • • ❳ about her work quality.`).
  - **IPA is HIDDEN** by default during active recall to prevent spoiling.
  - A small, clean button `💡 Xem gợi ý` allows users to manually reveal the initial letter (`m...`) before the 3.5s auto-scaffold kicks in.
- **Scaffolded State (3.5s – 5.0s / On Tap Hint):**
  - Smoothly expands to show `💡 Gợi ý: m...` and fills the initial letter in the blank: `❲ m • • • • • • • • ❳`.
- **Post-Attempt State (Success or Timeout):**
  - **On Correct Match:** Card turns subtly mint, the blank morphs to full bold green text `meticulous`, and the IPA `/məˈtɪk.jə.ləs/` fades in gracefully with audio confirmation.
  - **On Timeout (6.0s):** Card turns warm amber/coral, reveals `meticulous`, plays TTS pronunciation, and marks the word for post-drill review.

### 3.2. Linear Countdown Progress Header
- Replaces the perimeter border shape with a clean, high-precision linear countdown bar anchored below the header.
- The bar dynamically changes color from `ReflexBlitzTheme.primary` (steady) to `ReflexBlitzTheme.accent` (urgent < 2.0s).

### 3.3. Central Living Audio Waveform & Speech Feedback
- Centered between the challenge card and the bottom actions:
  - Dynamic audio visualizer with animated amplitude bars.
  - Formatted transcript with smooth opacity transitions. If matching keywords are detected, they highlight in real time.

### 3.4. Ergonomic Bottom Actions (Thumb Zone)
- Balanced 2-button layout in the lower safe area:
  - Left: `[⌨️ Gõ bàn phím]` toggle.
  - Right: `[Bỏ qua ⏭️]` skip button with 44×44pt minimum tap target.

---

## 4. Screen 2: Reflex Summary View Redesign Specifications

```
┌─────────────────────────────────────────────────────────┐
│                     🌿 Steady Learner                   │
│               Hoàn thành phiên phản xạ Blitz            │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │     5.5s                1 / 7                 x1    │ │
│ │  Tốc độ TB          Độ chính xác           Max Combo│ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│  Từ cần củng cố (6)                                     │
│ ┌─────────────────────────────────────────────────────┐ │
│ │  serendipity                                [🔊]    │ │
│ │  noun  •  /ˌser.ənˈdɪp.ə.ti/                        │ │
│ │  Sự tình cờ may mắn                                 │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │  ephemeral                                  [🔊]    │ │
│ │  adj.  •  /ɪˈfem.ər.əl/                             │ │
│ │  Phù du, chóng tàn                                  │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ ════════════════ (Sticky Bottom Bar) ══════════════════ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │         🔄 Luyện lại 6 từ chưa phản xạ kịp          │ │
│ └─────────────────────────────────────────────────────┘ │
│                        Hoàn tất                         │
└─────────────────────────────────────────────────────────┘
```

### 4.1. Fixing IPA Phonetics Wrapping (2-Line Vertical Rhythm)
To prevent awkward line wraps (`/,ser.ən \n 'dɪp.ə.ti/`), every vocabulary row is restructured into a 3-tier vertical hierarchy:
- **Tier 1 (Heading):** Word Lemma (`font.headline.bold()`) aligned left with Audio Speaker button on the right.
- **Tier 2 (Metadata):** `\(pos) • \(ipa)` (`font.caption.monospaced()`, `lineLimit(1)`, `minimumScaleFactor(0.85)`).
- **Tier 3 (Definition):** Vietnamese translation in `textSecondary`.

### 4.2. Sticky Bottom Action Bar (Zero Dead End)
- A floating action container using `.background(.ultraThinMaterial)` fixed above the bottom safe area:
  - **Primary CTA:** `🔄 Luyện lại X từ chưa kịp phản xạ` (Prominent `52pt` button in `ReflexBlitzTheme.primary`).
  - **Secondary CTA:** `Hoàn tất & Lưu tiến độ` (`textSecondary` text button).
- The scroll view content uses bottom content insets to ensure the last vocabulary item is never obscured by the floating bar.

### 4.3. Unified Bento Metrics Header
- Eliminates the multi-colored icons (⚡, ✓, 🔥 in different hues).
- Encapsulates all 3 metrics into a single unified card surface with matching typography and subtle monochromatic icons in `ReflexBlitzTheme.primary`.

---

## 5. File Change Specifications & Code Structure

| File | Proposed Modifications |
|---|---|
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift` | Remove `PerimeterCountdownShape`; introduce Progressive Disclosure `showHintToggle`; restructure card layout to 3 balanced sections (Trigger, Cloze, Action Dock); hide IPA until answered. |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift` | Refactor vocabulary row to 3-tier layout (`VocabSummaryItemRow`); add `lineLimit(1)` and `minimumScaleFactor(0.85)` for IPA; embed fixed `StickySummaryBottomBar`; unify metric cards. |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift` | Integrate top linear countdown bar with smooth fractional animation and color stage transitions. |
| `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift` | Bind layout safely with bottom action dock and handle keyboard/voice mode transitions without layout jitter. |

---

## 6. Verification & Quality Assurance Plan

### 6.1. Automated Unit & Snapshot Tests
- **`ReflexBlitzCardViewTests`**: Verify that IPA text view is not present in the view hierarchy when `isCorrect == false && isTimeout == false`.
- **`ReflexBlitzSummaryViewTests`**: Verify that long lemma words (e.g. `serendipity`, `ephemeral`, `meticulous`) render without IPA multi-line wrapping across screen widths (iPhone SE 3rd Gen to iPhone 16 Pro Max).
- **`ReflexBlitzLayoutTests`**: Verify sticky bottom bar visibility when weak words list has 1, 5, or 10+ items.

### 6.2. Visual & HIG Verification
- Execute `testCaptureAllReflexBlitzScreenshots()` on iPhone 16 Pro simulator and inspect:
  - [ ] No wrapped or truncated IPA strings.
  - [ ] No dead whitespace in challenge card.
  - [ ] Bottom action button always visible above the home bar.
  - [ ] Dark Mode and Light Mode contrast ratios meet WCAG AA (≥ 4.5:1).
