# Reflex Blitz Summary Screen Redesign Specification (Refined)

**Date:** 2026-08-29  
**Status:** Approved for Implementation  
**Target View:** `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`  
**Components:** `CraftUIKit` (`CraftCard`, `CraftBadge`, `CraftButton`, `CraftSpeakerButton`)  
**Dependencies:** `Localizable.xcstrings`, `AppStrings+ReflexBlitz.swift`

---

## 1. Core Principles & Refined Design Guidelines

1. **100% Tactile 3D Consistency:**
   - All cards across the summary view (Bento Grid, Weak Words, and Perfect Score) strictly adopt `CraftCard(style: .tactile3D)`.
   - `CraftCard` in `CraftUIKit` is enhanced with `customBorderColor` and `customBottomColor` to support semantic status styling.
2. **Simplified, Distraction-Free Header:**
   - Remove the redundant announcement subtitle `"Reflex Blitz Completed"`.
   - The header focuses cleanly on:
     - Hero Rating Icon Squircle (`theme.colors.brandPrimary`).
     - Localized Tier Title (`Reflex Master` / `Swift Reflex` / `Steady Learner`).
     - Rating Stars (`★ ★ ☆`).
3. **Eliminate Count Repetition ("6" repeated 3 times):**
   - **Bento Grid:** Retains the fractional accuracy e.g. `6/12`.
   - **Section Header:** Clean label without count suffix: `"Words to Reinforce"` / `"Từ cần củng cố"`.
   - **CTA Button:** Concise action without count duplication: `"Re-drill"` / `"Luyện lại từ yếu"`.
4. **Active Recall Word Cards (Vocabulary Vault Alignment):**
   - Word cards follow the Vault item layout:
     - Line 1: `lemma` (bold headline).
     - Line 2: `ipa` phonetics (phonetic font).
     - Line 3: `[POS]` (neutral subtle badge) and `[CEFR Level]` (primary subtle badge).
     - Trailing: `CraftSpeakerButton` for instant audio playback.
   - **No Vietnamese definitions:** Stimulates active recall.
   - **No extra `[❌ Incorrect]` or `[⏱ 4.5s]` badges:** The card itself communicates weak status.
5. **Subtle Red 3D Extrusion for Weak Words (Design Token Conformance):**
   - Card face background remains neutral `theme.colors.surfaceCard`.
   - 3D bottom extrusion / rim uses `theme.colors.statusDanger.opacity(0.8)`.
   - Card stroke border uses `theme.colors.statusDanger.opacity(0.4)`.
6. **Icon-Free, Concise Action Buttons:**
   - Remove icons from CTA buttons (`iconName: nil`).
   - Primary: `"Re-drill"` / `"Luyện lại từ yếu"` (`theme.colors.brandPrimary`, `.tactile`).
   - Secondary: `"Done"` / `"Hoàn tất"` (`variant: .subtle`).

---

## 2. Visual Blueprint

```
┌─────────────────────────────────────────────────────────────┐
│                        11:38                                │
│                                                             │
│                         ✨                                  │
│                   Steady Learner                            │
│                      ★ ☆ ☆                                  │
│                                                             │
│   ┌───────────────┐ ┌───────────────┐ ┌─────────────────┐   │
│   │     1.6s      │ │     6/12      │ │       x2        │   │
│   │   Avg Speed   │ │   Accuracy    │ │   Max Combo     │   │
│   └───────────────┘ └───────────────┘ └─────────────────┘   │
│    [ Tactile 3D ]    [ Tactile 3D ]    [ Tactile 3D ]       │
│                                                             │
│   Words to Reinforce                                        │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ focus                                        [ 🔊 ] │   │
│   │ /ˈfoʊ.kəs/                                          │   │
│   │ [ verb ]  [ B2 ]                                    │   │
│   └─────────────────────────────────────────────────────┘   │
│   ( Tactile 3D - Subtle Red Danger 3D Bottom Lip )          │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ create                                       [ 🔊 ] │   │
│   │ /kriˈeɪt/                                           │   │
│   │ [ verb ]  [ B1 ]                                    │   │
│   └─────────────────────────────────────────────────────┘   │
│   ( Tactile 3D - Subtle Red Danger 3D Bottom Lip )          │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                    Re-drill                         │   │
│   └─────────────────────────────────────────────────────┘   │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                      Done                           │   │
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Localization Keys & Strings

```json
"app.reflex.summary.weak_words_header" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Words to Reinforce" } },
    "vi" : { "stringUnit" : { "state" : "translated", "value" : "Từ cần củng cố" } }
  }
},
"app.reflex.summary.redrill_weak" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Re-drill" } },
    "vi" : { "stringUnit" : { "state" : "translated", "value" : "Luyện lại từ yếu" } }
  }
},
"app.reflex.summary.finish_save" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Done" } },
    "vi" : { "stringUnit" : { "state" : "translated", "value" : "Hoàn tất" } }
  }
}
```

---

## 4. Verification Plan
1. **CraftUIKit Tests:** `swift test --package-path Packages/CraftUIKit`
2. **App Localization & View Tests:** `swift test --filter ReflexBlitzSummaryViewTests`, `swift test --filter ReflexBlitzLocalizationTests`
3. **Full Suite & SwiftLint:** `swift test`, `swiftlint` (0 errors, 0 warnings).
