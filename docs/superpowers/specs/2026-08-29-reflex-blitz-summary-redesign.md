# Reflex Blitz Summary Screen Redesign Specification

**Date:** 2026-08-29  
**Status:** Approved for Implementation Planning  
**Target View:** `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`  
**Dependencies:** `CraftUIKit`, `Localizable.xcstrings`, `AppStrings+ReflexBlitz.swift`

---

## 1. Problem Statement & Audit Findings

The current `ReflexBlitzSummaryView` has several critical visual, architectural, and localization flaws:
1. **Critical Localization Bug:** Raw keys like `app.reflex.summary.weak_words_header 8` and `app.reflex.summary.redrill_weak 8` are rendered on screen due to invalid string interpolation into `String(localized:)`.
2. **Language Inconsistency:** Mixing untranslated English header ratings, English metric titles (`Avg Speed`, `Accuracy`, `Max Combo`), and Vietnamese word definitions.
3. **Color Cacophony (Rainbow Effect):** 7+ clashing color tones on one screen (pale green, purple stars, coral, mint, yellow-orange, salmon, blood-red primary button, muddy brown secondary button).
4. **Icon Clutter & Visual Noise:** Unnecessary large icon circles inside every bento box and list item when the typography and numeric values already convey 100% of the meaning.
5. **Anti-pattern Button Semantics:** The primary CTA ("Re-drill weak words") uses `statusDanger` (destructive red) which psychologically indicates data loss or error, rather than positive reinforcement.
6. **Violations of CraftUIKit Standards:** Custom ad-hoc card containers with arbitrary padding, hand-crafted `.opacity()` calculations, and failure to leverage reusable design tokens and components.

---

## 2. Redesign Architecture & Design System Alignment

```
┌─────────────────────────────────────────────────────────────┐
│                    StatusBar / Top Spacing                  │
│                                                             │
│                    🏆 Hero Rating Badge                     │
│               [ Bậc thầy phản xạ / Reflex Master ]           │
│             ★ ★ ☆  •  8/12 từ chuẩn xác (67%)               │
│                                                             │
│   ┌───────────────┐ ┌───────────────┐ ┌─────────────────┐   │
│   │     3.3s      │ │      67%      │ │       x3        │   │
│   │   Tốc độ TB   │ │  Độ chính xác │ │   Combo max     │   │
│   └───────────────┘ └───────────────┘ └─────────────────┘   │
│                                                             │
│   TỪ CẦN CỦNG CỐ (2 TỪ)                                     │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ improve                 [ 🔊 ]  [ ⏱ 4.5s • Quá chậm ]│   │
│   │ v. • /ɪm'pru:v/                                     │   │
│   │ Cải thiện, nâng cao                                 │   │
│   └─────────────────────────────────────────────────────┘   │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ focus                   [ 🔊 ]  [ ❌ Chưa đúng ]     │   │
│   │ v. • /'foʊ.kəs/                                     │   │
│   │ Tập trung                                           │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  ⚡️ Luyện lại 2 từ chưa vững (Primary - Brand Orange) │   │
│   └─────────────────────────────────────────────────────┘   │
│   [ Hoàn thành & Lưu tiến độ (Neutral Secondary Button) ]   │
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Visual Hierarchy & Spatial Composition
1. **Hero Header (Celebration / Performance Tier):**
   - Single cohesive focal point representing the session's overall achievement tier (`ReflexSpeedRating`: `master`, `swift`, `steady`).
   - Compact hero icon container utilizing `CraftBadge` or themed squircle with unified brand styling.
   - Title in `theme.typography.titleLarge` (`.fontDesign(.rounded)`), localized via `AppStrings.ReflexBlitz`.
   - Sub-headline combining star rating + summary fraction text.
2. **Bento Metrics Grid (Typography-First, Zero Icon Clutter):**
   - Clean 3-column `CraftCard` grid.
   - **No pastel circle icons**: Focus purely on large, crisp numbers using `theme.typography.displaySmall` with `.monospacedDigit()` and subtle semantic labeling.
   - Values:
     - Metric 1: Average Reaction Time (`Double / 1000.0` formatted with `s`).
     - Metric 2: Accuracy Percentage (e.g. `67%` or `8/12`).
     - Metric 3: Max Streak Combo (e.g. `x3`).
3. **Weak Words Section (Contextual Feedback):**
   - Section header with count: `AppStrings.ReflexBlitz.weakWordsHeader(count)` (localized, e.g., "Từ cần củng cố (2)").
   - Card rows formatted with 3 clear tiers:
     - Tier 1: English lemma + audio speaker button (`CraftSpeakerButton`).
     - Tier 2: POS and IPA phonetics in `theme.typography.phonetic`.
     - Tier 3: Vietnamese definition + diagnostic status badge (`CraftBadge`):
       - If incorrect: `tone: .danger`, label: `Chưa đúng` / `Incorrect`.
       - If timeout (>6s): `tone: .warning`, label: `Hết giờ` / `Time out`.
       - If slow reaction: `tone: .warning`, label: `4.5s • Quá chậm` / `4.5s • Slow`.
4. **Bottom CTA Action Dock:**
   - **Primary Action (if weak words exist):** `CraftButton` with `variant: .tactile` or `.primary`, tinted with `theme.colors.brandPrimary` (warm brand color, NOT red danger).
   - **Secondary Action:** `CraftButton` with `variant: .subtle` or `.ghost`, tinted with `theme.colors.textPrimary` for high contrast and clean hierarchy.

---

## 3. Localization Architecture & Key Taxonomy

### 3.1 `Localizable.xcstrings` Additions & Updates
Ensure exact matching format strings with 100% bilingual parity (both `en` and `vi`):

```json
"app.reflex.summary.weak_words_header" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Words to Reinforce (%lld)"
      }
    },
    "vi" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Từ cần củng cố (%lld)"
      }
    }
  }
},
"app.reflex.summary.redrill_weak" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Re-drill %lld weak words"
      }
    },
    "vi" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Luyện lại %lld từ chưa thuộc"
      }
    }
  }
},
"app.reflex.summary.status_incorrect" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Incorrect" } },
    "vi" : { "stringUnit" : { "state" : "translated", "value" : "Chưa chính xác" } }
  }
},
"app.reflex.summary.status_slow" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "%@ • Slow" } },
    "vi" : { "stringUnit" : { "state" : "translated", "value" : "%@ • Quá chậm" } }
  }
}
```

### 3.2 `AppStrings+ReflexBlitz.swift` Helper Methods
Add type-safe, compiled localization accessors:
- `AppStrings.ReflexBlitz.weakWordsHeader(_ count: Int) -> String`
- `AppStrings.ReflexBlitz.redrillWeak(_ count: Int) -> String`
- `AppStrings.ReflexBlitz.ratingTitle(for rating: String) -> String`
- `AppStrings.ReflexBlitz.statusIncorrect: String`
- `AppStrings.ReflexBlitz.statusSlow(_ time: String) -> String`

---

## 4. Accessibility & Polish
1. **Dynamic Type:** All labels scale with Dynamic Type up to Accessibility XXL.
2. **Reduced Motion:** Particle animations and transitions gracefully fallback when `accessibilityReduceMotion` is active.
3. **Screen Reader:** All composite cards use `.accessibilityElement(children: .combine)` with descriptive summary labels.
4. **Dark Mode & Contrast:** Zero hardcoded colors; all backgrounds and text strictly reference `theme.colors` and pass WCAG AAA/AA standards.

---

## 5. Verification & Testing Strategy
1. **Unit & Localization Tests:**
   - Update `ReflexBlitzLocalizationTests.swift` to verify all new/updated summary keys.
   - Run `swift test --filter ReflexBlitzLocalizationTests`.
2. **View & Interaction Tests:**
   - Update `ReflexBlitzSummaryViewTests.swift` to assert all view states (perfect score, weak words present, varying ratings, button actions).
   - Run full test suite: `swift test --filter ReflexBlitzSummaryViewTests`.
3. **Compiler & Linter Verification:**
   - Xcode build: 0 errors, 0 warnings.
   - SwiftLint: 0 violations.
