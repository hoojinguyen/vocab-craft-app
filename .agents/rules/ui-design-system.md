---
trigger: always_on
---

# Antigravity Rule: UI Design System & Component Guidelines

> **Scope**: Applicable to all Swift / SwiftUI views, color tokens, layout components, and UI interactions across `VocabCraftApp`.
> **Enforcement**: Mandatory for all feature development, refactoring, and UI code reviews.

---

## 1. Aesthetic Philosophy: Neumorphic-Bento System

All user interfaces in `VocabCraftApp` must follow the **Modern Neumorphic-Bento Layout**:
- **Canvas**: Warm Cream canvas in Light Mode (`#FFFAF0`), Deep Slate Night canvas in Dark Mode (`#0B1317`).
- **Surface Cards**: Pure White cards in Light Mode, Dark Slate cards in Dark Mode, bounded by 1.5pt hairline borders (`vocabHairline`) and subtle 6pt drop shadows.
- **Visual Dominance**: Single dominant Hero Card (`vocabHeroTeal`) for primary focus (SRS Memory), flanked by modular Bento action cards for secondary interactions.
- **Language & Microcopy**: Clean, natural Vietnamese microcopy. Avoid verbose strings; prefer active titles (e.g., `"Mục tiêu hôm nay: 75%"`, `"TRÍ NHỚ DÀI HẠN (SRS)"`).

---

## 2. Dynamic Color System (Mandatory Semantic Tokens)

**Rule**: NEVER hardcode hex colors or raw `Color(red:green:blue:)` inside SwiftUI views. ALWAYS use the dynamic semantic tokens defined in `Color+VocabCraft.swift`:

| Token | Light Mode | Dark Mode | Primary Usage |
| :--- | :--- | :--- | :--- |
| `Color.vocabCanvas` | `#FFFAF0` (Warm Cream) | `#0B1317` (Slate Night) | App background fill |
| `Color.vocabSurfaceCard` | `#FFFFFF` (Pure White) | `#1A2A2A` (Dark Slate) | Surface cards, search bar background |
| `Color.vocabHeroTeal` | `#1A3A3A` (Deep Teal) | `#0F2B2B` (Dark Teal Container) | Hero Card background container fill |
| `Color.vocabHeroAccent` | `#1A3A3A` (Deep Teal) | `#B5E5D6` (Bright Mint Accent) | Card icons, search icons, secondary accents (high contrast) |
| `Color.vocabInk` | `#0A0A0A` (Off-Black) | `#F0F6FC` (Soft Off-White) | Primary titles, main body text |
| `Color.vocabMuted` | `#666666` (Muted Slate) | `#8B949E` (Cool Muted Gray) | Subtitles, labels, secondary microcopy |
| `Color.vocabHairline` | `#EBEBEB` (Soft Hairline) | `#2D3748` (Subtle Dark Hairline)| Card border stroke (1.5pt) |
| `Color.vocabCoral` | `#FF6B5B` (Warm Coral) | `#FF7A6B` (Vibrant Coral) | Streak badges, notification indicators, primary accents |
| `Color.vocabMint` | `#A4D4C5` (Soft Mint) | `#B5E5D6` (Bright Mint) | Progress gauges, level 1 CEFR bar, status badges |
| `Color.vocabPeach` | `#F7C59F` (Soft Peach) | `#FFD1AD` (Bright Peach) | Challenge badges, level 2 CEFR bar |
| `Color.vocabLavender` | `#C3BEF0` (Soft Lavender)| `#D2CCFF` (Bright Lavender)| Queue badges, level 3 CEFR bar |

> ⚠️ **CRITICAL DARK MODE RULE**: Never use `vocabHeroTeal` for icons or text on surface cards (`vocabSurfaceCard`), as `#0F2B2B` becomes invisible against dark backgrounds in Dark Mode. Always use `Color.vocabHeroAccent` for icons.

---

## 3. Touch Targets & Accessibility (A11y)

- **Minimum Hit Target**: All interactive elements (buttons, clear icons, voice search, detail links) MUST have a **minimum touch target frame of 44x44 pt**.
- **Tab Bar Items**: Floating tab bar buttons MUST have a **minimum touch target frame of 48x48 pt**.
- **Non-clipping Touch Bounds**: Always attach `.contentShape(Rectangle())` or `.frame(minWidth: 44, minHeight: 44)` to interactive elements to eliminate unclickable margins.
- **Button Styling**: Always explicitly set `.buttonStyle(.plain)` or custom spring styles (`BentoCardButtonStyle()`) to prevent unwanted default iOS tap flash overlays.

---

## 4. Component Design Standards

### 4.1 Header Bar (`HeaderView`)
- **Ultra-Clean Layout**: No redundant avatar circles or progress rings in the header.
- **Title**: `"Chào [userName] 👋"` — 20pt Bold, `vocabInk`.
- **Subtitle**: `"Mục tiêu hôm nay: [X]%"` — 13pt Medium, `vocabMuted`.
- **Streak Badge**: Minimalist capsule pill (`vocabCoral.opacity(0.12)` fill). Icon `flame.fill` + Number `[streakDays]` in 13pt Bold `vocabCoral`.
- **Notification Bell**: 44x44 pt circle (`vocabSurfaceSoft` fill) with `bell.fill` icon (16pt, `vocabInk`) and a 9x9 pt red dot (`vocabCoral`) at `.topTrailing`.

### 4.2 Search Component (`MobileSearchView`)
- Container: `RoundedRectangle(cornerRadius: 20, style: .continuous)` filled with `vocabSurfaceCard`, stroke overlay `vocabHairline` (1.5pt), shadow `vocabHeroTeal.opacity(0.05)` (radius 6).
- Search icon & Mic icon: MUST use `Color.vocabHeroAccent`.
- Voice search button: 32x32 pt circle fill (`Color.vocabHeroAccent.opacity(0.12)`), wrapped inside a 44x44 pt hit target.

### 4.3 Hero Card (`SRSMemoryHeroCard`)
- Container: 24pt continuous corner radius, filled with `vocabHeroTeal`.
- Title tag: `"TRÍ NHỚ DÀI HẠN (SRS)"` — 11pt Bold, `vocabMint`, letter spacing +0.5.
- Main stat: `"[X] từ"` — 28pt Bold, `.white`.
- Progress gauge: 60x60 pt conic progress ring (`vocabMint` active stroke, 5pt thickness).

### 4.4 Bento Action Cards (`ActionCardsGrid`)
- Tactile feedback: Every card MUST use `BentoCardButtonStyle` (`.scaleEffect(0.97)` on press, animated with `.spring(response: 0.2, dampingFraction: 0.6)`).
- Card surface: 20pt corner radius, `vocabSurfaceCard` background, 1.5pt `vocabHairline` stroke.
- Header badges: 10pt corner radius, 20% opacity pill background (`vocabPeach` or `vocabLavender`), title 9pt Bold `vocabInk`.

### 4.5 Progress Distributions (`CEFRDistributionCard`)
- Tri-color progress bar: Height 10pt with 3pt gaps between segments (`vocabMint`, `vocabPeach`, `vocabLavender`).
- Detail button link: Touch target 44x44 pt aligned `.trailing` with `.buttonStyle(.plain)`.

### 4.6 Floating Tab Bar (`LiquidGlassTabBar`)
- Floating glass container: `.ultraThinMaterial` background, 28pt corner radius, 16pt blur shadow.
- Active tab capsule: `Color.vocabInk.opacity(0.08)` background fill.
- Tab hit target: 48x48 pt frame per tab button.

---

## 5. Verification & TDD Workflow

1. **Unit Testing**: Every UI component must have a corresponding test suite under `VocabCraftAppTests/` validating properties, bounds, and binding updates.
2. **Suite Verification**: Run `swift test` before committing any UI changes. Zero test failures tolerated.
3. **Simulator Inspection**: Build (`xcodebuild`) and test live on iOS Simulator in BOTH **Light Mode** and **Dark Mode** (`xcrun simctl ui [device_id] appearance dark`) to visually verify contrast and aesthetics before declaring completion.
