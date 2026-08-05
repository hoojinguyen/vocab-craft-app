# Design Spec: Homepage Bento & Dark Mode Redesign

**Date**: 2026-08-05  
**Author**: Antigravity UX/UI Lead  
**Status**: Approved  
**Target View**: `HomepageView.swift` & subcomponents (`HeaderView`, `MobileSearchView`, `SRSMemoryHeroCard`, `ActionCardsGrid`, `CEFRDistributionCard`, `LiquidGlassTabBar`)

---

## 1. Overview & Goals

Redesign the primary landing experience of **VocabCraft** (`HomepageView`) from a visually cluttered multi-color layout into a **Modern Neumorphic Bento Grid**. 

### Primary Objectives:
1. **Visual Hierarchy & Focus**: Establish `SRSMemoryHeroCard` as the single dominant visual anchor. Move secondary actions to clean white/dark-slate Bento cards.
2. **Localization & Microcopy**: Eliminate English/Vietnamese language mixing (e.g., replace `"14 NGÀY CONTINUOUS"` with `"🔥 14 ngày liên tiếp"`). Standardize all badges and descriptions to professional UX copy.
3. **Apple HIG & Touch Targets**: Expand all interactive touch boundaries (Notification Bell, Search Clear Button, Voice Search Button, Tab Bar Items) to a minimum of **44x44 pt**.
4. **Complete Light & Dark Mode Support**: Implement semantic design tokens (`Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabInk`, etc.) supporting seamless automatic light/dark appearance switching.
5. **Micro-interactions**: Add tactile spring press feedback (`.scaleEffect(0.97)`) on action cards and liquid transitions on tab bar buttons.

---

## 2. Component Specifications & Layout Structure

```
┌──────────────────────────────────────────────────────────┐
│ [Avatar 44pt]  Chào Hooji,        [🔥 14 ngày]  [🔔 44pt]│  Header Section
│  (Progress Ring) Mục tiêu: 75%                           │
├──────────────────────────────────────────────────────────┤
│ 🔍 [ Tra cứu từ vựng hoặc thẻ bài... ]          [🎙️ 44pt]│  Mobile Search Bar
├──────────────────────────────────────────────────────────┤
│ 🌟 SRS HERO CARD (Primary Visual Anchor)                 │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ TRÍ NHỚ DÀI HẠN (SRS)                       ( 85% )  │ │  Hero Teal Card
│ │ 1.420 từ đã vào trí nhớ bền vững                     │ │
│ └──────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│ BENTO ACTION GRID (Clean Surface Cards)                  │
│ ┌─────────────────────────┐  ┌─────────────────────────┐ │
│ │ ⚡ THỬ THÁCH             │  │ 📚 24 THẺ BÀI           │ │  Dual Bento Action
│ │ Luyện Phản Xạ           │  │ Hàng Đợi SRS            │ │  Cards
│ │ Rèn phản xạ tốc độ      │  │ Cần hoàn thành hôm nay  │ │
│ └─────────────────────────┘  └─────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│ 📊 CEFR DISTRIBUTION CARD                                │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Segmented Progress Bar + A1/A2, B1/B2, C1/C2 Legend  │ │  CEFR Analytics Card
│ └──────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│         [ 🏠 Trang chủ  |  📖 Từ vựng  |  ⚡ Phản xạ ]    │  Floating Glass TabBar
└──────────────────────────────────────────────────────────┘
```

### 2.1 HeaderView
* **Ultra-Clean Header**: Removed duplicate Avatar progress ring for maximum horizontal spacing and clean layout.
* **Greeting & Goal Subtitle**: Title `"Chào Hooji 👋"` (20pt Bold, `vocabInk`). Subtitle `"Mục tiêu hôm nay: 75%"` (13pt Medium, `vocabMuted`).
* **Minimalist Streak Badge**: Capsule pill container (`vocabCoral.opacity(0.12)` fill). Icon `flame.fill` + Number `"14"` (13pt Bold, `vocabCoral`).
* **Notification Bell Button**: 44x44 pt touch boundary. Background `vocabSurfaceSoft`, icon `bell.fill` (16pt, `vocabInk`). Red indicator dot (9x9 pt, `vocabCoral`) aligned top-right.

### 2.2 MobileSearchView
* **Container**: `RoundedRectangle(cornerRadius: 20, style: .continuous)` filled with `vocabSurfaceCard`, stroke overlay `vocabHairline` (1.5pt), shadow `vocabHeroTeal.opacity(0.05)` (radius 6).
* **Magnifying Glass Icon**: 16pt semibold, `vocabHeroTeal`.
* **Placeholder**: `"Tra cứu từ vựng hoặc thẻ bài..."` (15pt Medium, `vocabInk`).
* **Clear Button (`xmark.circle.fill`)**: Padded frame with minimum 44x44 pt hit area.
* **Voice Search Button (`mic.fill`)**: 14pt semibold icon inside a 32x32 pt circle container (`vocabHeroTeal.opacity(0.08)` fill) within a 44x44 pt touch container.

### 2.3 SRSMemoryHeroCard
* **Background**: `vocabHeroTeal` fill with 24pt corner radius.
* **Section Tag**: `"TRÍ NHỚ DÀI HẠN (SRS)"` (11pt Bold, `vocabMint`, tracking 0.5).
* **Main Stat**: `"1.420 từ"` (28pt Bold, `.white`).
* **Description**: `"85% từ đã đi vào bộ nhớ bền vững"` (13pt Medium, `vocabMint.opacity(0.9)`).
* **Progress Ring**: 60x60 pt gauge. Outer track `white.opacity(0.15)` (5pt stroke). Progress arc `vocabMint` with round line cap. Center percentage text `"85%"` (13pt Bold, `vocabMint`).

### 2.4 ActionCardsGrid (Bento Action Cards)
* **Left Card (Luyện Phản Xạ)**:
  * Surface: `vocabSurfaceCard` with 20pt corner radius, 1.5pt `vocabHairline` stroke, subtle drop shadow.
  * Badge: `"⚡ THỬ THÁCH"` (9pt Bold, `vocabPeach.opacity(0.20)` fill, `vocabInk` text).
  * Icon: `timer` (18pt, `vocabHeroTeal`).
  * Title: `"Luyện Phản Xạ"` (16pt Bold, `vocabInk`).
  * Subtitle: `"Rèn phản xạ tốc độ"` (12pt Medium, `vocabMuted`).
* **Right Card (Hàng Đợi SRS)**:
  * Surface: `vocabSurfaceCard` with 20pt corner radius, 1.5pt `vocabHairline` stroke, subtle drop shadow.
  * Badge: `"📚 24 THẺ BÀI"` (9pt Bold, `vocabLavender.opacity(0.20)` fill, `vocabInk` text).
  * Icon: `rectangle.stack.fill` (18pt, `vocabHeroTeal`).
  * Title: `"Hàng Đợi SRS"` (16pt Bold, `vocabInk`).
  * Subtitle: `"Cần hoàn thành hôm nay"` (12pt Medium, `vocabMuted`).
* **Tactile Feedback**: Button style applying `.scaleEffect(isPressed ? 0.97 : 1.0)` with `.animation(.spring(response: 0.2, dampingFraction: 0.6))`.

### 2.5 CEFRDistributionCard
* **Header**: `"PHÂN BỔ TRÌNH ĐỘ CEFR"` (10pt Bold, `vocabMuted`, tracking 0.5) + `"Tiến trình năng lực từ vựng"` (16pt Bold, `vocabInk`). Detail button `"Chi tiết"` + `chevron.right` (12pt Semibold, `vocabCoral`).
* **Segmented Bar**: Height 10pt. Capsule clipping containing 3 rounded rectangle segments (`vocabMint` for A1-A2, `vocabPeach` for B1-B2, `vocabLavender` for C1-C2) separated by 3pt gap.
* **Legend Items**:
  * A1-A2: `vocabMint` dot (8pt), label `"A1-A2"` (11pt Medium, `vocabMuted`), count `"450 từ"` (12pt Bold, `vocabInk`).
  * B1-B2: `vocabPeach` dot (8pt), label `"B1-B2"` (11pt Medium, `vocabMuted`), count `"620 từ"` (12pt Bold, `vocabInk`).
  * C1-C2: `vocabLavender` dot (8pt), label `"C1-C2"` (11pt Medium, `vocabMuted`), count `"350 từ"` (12pt Bold, `vocabInk`).

### 2.6 LiquidGlassTabBar
* **Background**: `.ultraThinMaterial` overlay on `vocabSurfaceCard.opacity(0.85)` with 28pt corner radius and 16pt blur shadow (`black.opacity(0.12)` in Light, `black.opacity(0.40)` in Dark).
* **Navigation Items**:
  * Home (`house.fill`), Vocabulary (`book.fill`), Reflex (`bolt.fill`), Settings (`gearshape.fill`).
  * Active state: Capsule background `vocabInk.opacity(0.08)` (Light) / `white.opacity(0.12)` (Dark), bold text, full opacity icon.
  * Hit target: Min 48x48 pt touch area per tab item.

---

## 3. Light & Dark Mode Color Token Matrix

| Token Name | Light Mode Hex / Asset | Dark Mode Hex / Asset | Semantic Purpose |
| :--- | :--- | :--- | :--- |
| `Color.vocabCanvas` | `#FFFAF0` (Warm Cream) | `#0A1A1A` (Deep Forest Night) | Main page background |
| `Color.vocabSurfaceSoft` | `#FAF5E8` | `#142424` | Secondary surface background |
| `Color.vocabSurfaceCard` | `#FFFFFF` (Pure White) | `#1A2A2A` (Elevated Slate) | Bento cards & Search bar |
| `Color.vocabHeroTeal` | `#1A3A3A` (Forest Teal) | `#0F2B2B` (Dark Teal) | SRS Hero card background |
| `Color.vocabInk` | `#0A0A0A` (Off-black) | `#F0F6FC` (Soft Off-white) | Primary body & heading text |
| `Color.vocabMuted` | `#6A6A6A` (Neutral Gray) | `#A0AEC0` (Light Slate Gray) | Secondary captions & subtitles |
| `Color.vocabHairline` | `#E5E5E5` | `White.opacity(0.12)` | Card borders & stroke overlays |
| `Color.vocabCoral` | `#FF6B5A` | `#FF7A6B` (+8% luminance) | Primary CTA & Streak flame |
| `Color.vocabMint` | `#A4D4C5` | `#B5E5D6` (+8% luminance) | A1-A2 accent & SRS gauge |
| `Color.vocabPeach` | `#FFB084` | `#FFC09C` (+8% luminance) | B1-B2 accent & Reflex badge |
| `Color.vocabLavender` | `#B8A4ED` | `#C8B8F2` (+8% luminance) | C1-C2 accent & Queue badge |

---

## 4. Accessibility & Quality Verification Checklist

1. **Touch Target Size**: All interactive elements (bell button, voice button, clear button, tab bar items) verified at >= 44x44 pt.
2. **Color Contrast (WCAG AA)**: Body text (`vocabInk`) on `vocabSurfaceCard` maintains > 7.0:1 contrast in both Light and Dark modes. Secondary text (`vocabMuted`) maintains > 4.5:1.
3. **VoiceOver Support**: Accessibility labels and hints added to all cards (`SRSMemoryHeroCard`, `ActionCardsGrid`, `CEFRDistributionCard`).
4. **Dynamic Type Support**: Fonts use relative SwiftUI text styles or scaled size modifiers to respect accessibility font size settings.

---

## 5. Implementation Steps & Acceptance Criteria

1. **Tokens Update**: Update `Color+VocabCraft.swift` asset catalog / color extensions to include semantic Light & Dark definitions.
2. **HeaderView Refactor**: Update touch targets, streak capsule microcopy, and goal text layout.
3. **MobileSearchView Refactor**: Increase button hit areas to 44x44 pt and update border overlay.
4. **SRSMemoryHeroCard Refactor**: Standardize microcopy and progress ring styling.
5. **ActionCardsGrid Refactor**: Replace background colors with `vocabSurfaceCard` + hairline border + accent badges, add spring press button style.
6. **CEFRDistributionCard Refactor**: Update segment gaps, legend formatting, and detail chevron button.
7. **LiquidGlassTabBar Refactor**: Ensure dark mode ultraThinMaterial compatibility and min hit target size.
8. **Verification**: Build & run preview in both Light and Dark modes. Verify touch targets and layout responsiveness.
