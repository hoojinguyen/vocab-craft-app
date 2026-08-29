# Reflex Blitz Summary Screen Redesign Implementation Plan (Refined)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `ReflexBlitzSummaryView.swift` to 100% Tactile3D style, remove header subtitle, eliminate count repetition, simplify word cards to Active Recall layout (with subtle red bottom extrusion token), and remove button icons with concise labels.

**Architecture:** MV with Observation. Reusable CraftUIKit components (`CraftCard`, `CraftBadge`, `CraftButton`, `CraftSpeakerButton`) with full Design Token compliance.

**Tech Stack:** Swift 6.0, SwiftUI, CraftUIKit, Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-29-reflex-blitz-summary-redesign.md`

## Global Constraints

- 100% Tactile3D style across cards.
- Zero raw strings, zero hardcoded colors; use `theme.colors` (`statusDanger.opacity(0.8)` for bottom extrusion, `statusDanger.opacity(0.4)` for border).
- All tests pass with 0 errors, 0 warnings, and 0 SwiftLint violations.

---

### Task 1: CraftUIKit CraftCard Tactile Color Extension

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Cards/CraftCard.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftCardTests.swift` (or relevant test suite in CraftUIKit)

- [ ] **Step 1: Update `CraftCard.swift` to accept `customBorderColor` and `customBottomColor`**
- [ ] **Step 2: Verify `swift test --package-path Packages/CraftUIKit` passes**
- [ ] **Step 3: Commit changes**

---

### Task 2: Core Localization & Concise Action Strings

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzLocalizationTests.swift`

- [ ] **Step 1: Update localization strings for concise labels without count repetition**
  - `app.reflex.summary.weak_words_header`: EN "Words to Reinforce", VI "Từ cần củng cố"
  - `app.reflex.summary.redrill_weak`: EN "Re-drill", VI "Luyện lại từ yếu"
  - `app.reflex.summary.finish_save`: EN "Done", VI "Hoàn tất"
- [ ] **Step 2: Update AppStrings+ReflexBlitz.swift helper accessors**
- [ ] **Step 3: Update and run `swift test --filter ReflexBlitzLocalizationTests`**
- [ ] **Step 4: Commit changes**

---

### Task 3: ReflexBlitzSummaryView UI/UX Overhaul to Active Recall & Tactile3D

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`

- [ ] **Step 1: Refactor ReflexBlitzSummaryView.swift**
  - Header: Remove subtitle "Reflex Blitz Completed". Keep hero badge + localized title + stars.
  - Bento Grid: 3 `CraftCard(style: .tactile3D)` cards.
  - Weak Words: `CraftCard(style: .tactile3D, padding: theme.spacing.md, customBorderColor: theme.colors.statusDanger.opacity(0.4), customBottomColor: theme.colors.statusDanger.opacity(0.8))`
    - Structure: Lemma, IPA phonetics, POS badge (`[verb]`) & CEFR Level badge (`[B2]`), Speaker audio button (`CraftSpeakerButton`).
    - Remove Vietnamese definition (`definitionVi`).
    - Remove `[❌ Incorrect]` / `[⏱ 4.5s]` badges.
  - Action Dock:
    - Primary: `CraftButton(AppStrings.ReflexBlitz.redrillWeak, variant: .tactile, size: .lg, isFullWidth: true, customTint: theme.colors.brandPrimary, action: onReDrillWeak)` (No icon).
    - Secondary: `CraftButton(AppStrings.ReflexBlitz.finishSaveText, variant: .subtle, size: .md, isFullWidth: true, action: onFinish)` (No icon).
- [ ] **Step 2: Update unit tests in `ReflexBlitzSummaryViewTests.swift`**
- [ ] **Step 3: Run `swift test --filter ReflexBlitzSummaryViewTests`**
- [ ] **Step 4: Commit changes**

---

### Task 4: Full Test Suite, SwiftLint & Xcode Build Verification

- [ ] **Step 1: Run full test suite `swift test`**
- [ ] **Step 2: Run SwiftLint `swiftlint`**
- [ ] **Step 3: Final verification report**
