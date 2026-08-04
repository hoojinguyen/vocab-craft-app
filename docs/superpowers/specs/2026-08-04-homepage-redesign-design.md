# Design Specification: VocabCraft Homepage Redesign & Design System Adaptation

**Date:** 2026-08-04  
**Status:** Approved  
**Target Platform:** iOS App (SwiftUI, iOS 17+)  
**Design Spec Path:** `docs/superpowers/specs/2026-08-04-homepage-redesign-design.md`

---

## 1. Executive Summary & Goals

This specification defines the complete redesign of the **VocabCraft Homepage Screen** and adapts the existing brand design system (`DESIGN.md`) into a cohesive native iOS design language.

### Core Objectives
1. **Adaptive Learning & SRS Analytics Dashboard:** Position SRS Memory Retention and Reflex Speed at the center of the user experience.
2. **Editorial Precision meets Gamified Focus:** Combine Cohere-style dictionary precision with warm, motivating gamification (Continuous Streak 🔥, Goal Progress Rings, High-contrast Feature Cards).
3. **Dual Theme System (Light & Dark Mode):** Full color-token parity with `DESIGN.md` (Warm Cream `#FFFAF0` for Light Mode, Teal-tinted Dark `#0A1A1A` for Dark Mode).
4. **iOS Native UX Alignment:** Replace web-centric patterns (e.g. desktop `⌘K`) with native mobile paradigms (Voice Input, SF Symbols, Liquid Glass floating tab bar).

---

## 2. Design System & Token Specification (Inherited from `DESIGN.md`)

VocabCraft adapts `DESIGN.md` for a mobile context using generous corner radii, saturated single-color feature cards, and warm canvas surfaces.

### 2.1 Color Tokens Table

| Token Name | Light Mode Hex | Dark Mode Hex | Usage |
|---|---|---|---|
| `{colors.canvas}` / `{colors.surface-dark}` | `#FFFAF0` (Warm Cream) | `#0A1A1A` (Teal Dark) | App page background |
| `{colors.surface-soft}` / `{colors.surface-dark-elevated}` | `#FAF5E8` | `#1A2A2A` | Search bar, Header badges, Sub-surfaces |
| `{colors.surface-card}` | `#F5F0E0` | `#1A2A2A` | Secondary content cards (CEFR breakdown) |
| `{colors.brand-teal}` | `#1A3A3A` | `#1A3A3A` | Primary Hero Card background (SRS Memory) |
| `{colors.brand-mint}` | `#A4D4C5` | `#A4D4C5` | High retention status, 85% Memory Ring |
| `{colors.brand-peach}` / `{colors.brand-coral}` | `#FFB084` / `#FF7759` | `#FFB084` / `#FF7759` | Quick Reflex Drill card & Streak Flame 🔥 |
| `{colors.brand-lavender}` | `#B8A4ED` | `#B8A4ED` | SRS Queue Card background |
| `{colors.brand-pink}` | `#FF4D8B` | `#FF4D8B` | CEFR B1-B2 indicator bar |
| `{colors.brand-ochre}` | `#E8B94A` | `#E8B94A` | CEFR C1-C2 indicator bar |
| `{colors.ink}` / `{colors.on-dark}` | `#0A0A0A` | `#FFFFFF` | Primary headlines & body text |
| `{colors.muted}` / `{colors.on-dark-soft}` | `#6A6A6A` | `#A0A0A0` | Subtitles, caption text, tab icons |

### 2.2 Typography Scale
- **Display / Headings:** Space Grotesk (Fallback: Inter / SF Pro Display with `-0.03em` tracking).
- **Body & Interface:** SF Pro Text / Inter (`14px`–`16px` Medium/SemiBold).
- **Data & Badges:** JetBrains Mono (`10px`–`12px` Mono Bold for CEFR levels, time in ms, retention % numbers).

### 2.3 Radius & Spacing Scale
- **Bento Feature Cards:** `{rounded.xl}` (`24px`).
- **Search Input & Secondary Cards:** `{rounded.md}` (`12px` - `16px`).
- **Badges & Streak Pills:** `{rounded.pill}` (`9999px`).
- **Liquid Glass Floating Bottom Bar:** `28px` corner radius.

---

## 3. Detailed Homepage Screen Architecture

The homepage is structured into three main vertical sections:

```
+-------------------------------------------------------+
|  [Avatar + 75% Goal Ring]  [🔥 14 DAYS]      [🔔 Bell]|  <- Header
|  [ 🔍 Search vocabulary or cards...          🎙️ Mic ]|  <- Mobile Search
+-------------------------------------------------------+
|  +-------------------------------------------------+  |
|  | HERO SRS MEMORY CARD (#1A3A3A)                  |  |  <- Bento 1
|  | 1,420 words (85% Retention)    [ (85%) Ring ]   |  |
|  +-------------------------------------------------+  |
|                                                       |
|  +-----------------------+ +-----------------------+  |
|  | ⚡ QUICK DRILL        | | 📅 SRS QUEUE          |  |  <- Bento 2 & 3
|  | Reflex Practice       | | 24 Cards Due Today    |  |
|  +-----------------------+ +-----------------------+  |
|                                                       |
|  +-------------------------------------------------+  |
|  | CEFR DISTRIBUTION CARD                          |  |  <- Bento 4
|  | [===A1-A2===|======B1-B2======|====C1-C2====]    |  |
|  +-------------------------------------------------+  |
+-------------------------------------------------------+
|  ( 🏠 Trang chủ  |  📚 Từ vựng  |  ⚡ Phản xạ  |  ⚙️ Cài đặt ) | <- Liquid Glass Tab Bar
+-------------------------------------------------------+
```

### 3.1 Top Header & Profile Progress
- **Left:** User Profile Avatar framed within a **Conic Progress Ring** (`#FF7759`) representing Daily Goal completion (e.g. 75%).
- **Middle-Left Label:** `🔥 14 NGÀY CONTINUOUS` Streak Flame Pill + Today's Goal percentage readout.
- **Right:** Native Notification Bell (`bell.fill`) with unread status indicator. Settings button is removed from the header and placed cleanly in the bottom navigation bar.

### 3.2 Mobile Quick Search Bar
- Native rounded input field (`#FAF5E8` in Light, `#1A2A2A` in Dark).
- **Search Icon:** `magnifyingglass` SF Symbol.
- **Voice Action:** Native Microphone icon (`microphone.fill`) for voice lookup (replacing web `⌘K`).

### 3.3 Bento Grid Dashboard Body
1. **SRS Memory Hero Card (`#1A3A3A` Deep Teal):**
   - High-contrast display: Total SRS words in long-term memory (1,420 words).
   - **Dynamic Retention Gauge Ring:** 60px Circular progress ring using `#A4D4C5` (Mint Memory) to display the 85% retention status.
2. **Reflex Quick Drill Card (`#FFB084` Brand Peach):**
   - Accent card launching 10-question / 60-second reflex practice (`bolt.fill`).
3. **SRS Due Queue Card (`#B8A4ED` Brand Lavender):**
   - Action card displaying cards due for review today (`calendar` / `cards.fill`).
4. **CEFR Vocabulary Distribution Card (`#F5F0E0` / `#1A2A2A`):**
   - Tri-color segmented progress bar mapping A1-A2 (Teal `#1A3A3A` / Mint `#A4D4C5`), B1-B2 (Pink `#FF4D8B`), C1-C2 (Ochre `#E8B94A`).

### 3.4 iOS Liquid Glass Floating Bottom Navigation Bar
- **Styling:** Floating card (`margin: 12px`, `border-radius: 28px`) rendered with translucency and real-time blur (`backdrop-filter: blur(20px)`).
  - Light Mode: `rgba(255, 250, 240, 0.85)` with `1px solid rgba(255, 255, 255, 0.8)`.
  - Dark Mode: `rgba(26, 42, 42, 0.85)` with `1px solid rgba(255, 255, 255, 0.15)`.
- **Tabs (SF Symbols):**
  1. `house.fill` — **Trang chủ** (Active with background pill highlight)
  2. `book.fill` — **Từ vựng**
  3. `bolt.fill` — **Phản xạ**
  4. `gearshape.fill` — **Cài đặt**

---

## 4. Technical Integration & Data Models

The Homepage UI consumes state from existing Core engines:
- **`SRSEngine`**: Fetches total long-term memory count, due cards queue size, and overall retention percentage.
- **`ReflexDrillRecord`**: Provides quick drill session targets and average response latency.
- **`StreakManager`**: Calculates continuous daily activity streak count and daily goal progress.

---

## 5. Verification & Acceptance Criteria
- [x] Design System Tokens mapped 100% to `DESIGN.md` for both Light and Dark modes.
- [x] Desktop shortcuts removed in favor of Mobile Voice Input.
- [x] Dynamic multi-color SRS progress ring rendered.
- [x] Native iOS SF Symbols icons specified.
- [x] Liquid Glass Floating Tab Bar specified with translucency and blur filters.
