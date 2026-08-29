# Reflex Blitz Summary Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor and modernize `ReflexBlitzSummaryView.swift` to eliminate raw localization key bugs, remove icon clutter and color cacophony, and align with CraftUIKit design tokens and 100% bilingual parity.

**Architecture:** MV with Observation pattern. View cleanly consumes `ReflexBlitzSessionSummary` data model, resolves localized strings through `AppStrings.ReflexBlitz`, and renders layout with CraftUIKit Design System tokens (`CraftCard`, `CraftBadge`, `CraftButton`, `CraftSpeakerButton`).

**Tech Stack:** Swift 6.0, SwiftUI, CraftUIKit, Swift Testing (`@Test`, `@Suite`, `#expect`).

**Spec:** `docs/superpowers/specs/2026-08-29-reflex-blitz-summary-redesign.md`

## Global Constraints

- Zero raw string literals or string interpolation inside `String(localized:)` keys.
- All display strings must exist in `Localizable.xcstrings` with both `en` and `vi` translations.
- Zero hardcoded colors; strictly use `CraftTheme` tokens (`theme.colors`, `theme.typography`, `theme.spacing`, `theme.radii`).
- All tests must pass with 0 errors, 0 warnings, and 0 SwiftLint violations.

---

### Task 1: Core Localization & String Accessors

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift:215-250`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzLocalizationTests.swift`

**Interfaces:**
- Consumes: `Localizable.xcstrings` key catalog.
- Produces:
  ```swift
  public static func weakWordsHeader(_ count: Int) -> String
  public static func redrillWeak(_ count: Int) -> String
  public static func localizedRatingTitle(for speedRating: String) -> String
  public static var statusIncorrect: String
  public static func statusSlow(_ time: String) -> String
  ```

- [ ] **Step 1: Write the failing tests for new summary localization keys and accessors**

```swift
// In VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzLocalizationTests.swift
// Add required keys to requiredReflexKeys dictionary:
"app.reflex.summary.weak_words_header": ("Từ cần củng cố (%lld)", "Words to Reinforce (%lld)"),
"app.reflex.summary.status_incorrect": ("Chưa chính xác", "Incorrect"),
"app.reflex.summary.status_slow": ("%@ • Quá chậm", "%@ • Slow"),

// Add accessor assertions in testAppStringsReflexBlitzAccessors():
#expect(AppStrings.ReflexBlitz.weakWordsHeader(2).contains("2"))
#expect(!AppStrings.ReflexBlitz.statusIncorrect.isEmpty)
#expect(AppStrings.ReflexBlitz.statusSlow("4.5s").contains("4.5s"))
#expect(AppStrings.ReflexBlitz.localizedRatingTitle(for: "⚡️ Reflex Master") == String(localized: "app.reflex.summary.rating_master"))
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzLocalizationTests`  
Expected: FAIL (missing methods or dictionary keys)

- [ ] **Step 3: Update `Localizable.xcstrings` and `AppStrings+ReflexBlitz.swift`**

Add keys to `Localizable.xcstrings`:
- `app.reflex.summary.weak_words_header`
- `app.reflex.summary.status_incorrect`
- `app.reflex.summary.status_slow`

Implement helper methods in `AppStrings+ReflexBlitz.swift`:
```swift
public static func weakWordsHeader(_ count: Int) -> String {
    String(format: String(localized: "app.reflex.summary.weak_words_header", defaultValue: "Từ cần củng cố (%lld)", bundle: .module), count)
}

public static var statusIncorrect: String {
    String(localized: "app.reflex.summary.status_incorrect", defaultValue: "Chưa chính xác", bundle: .module)
}

public static func statusSlow(_ time: String) -> String {
    String(format: String(localized: "app.reflex.summary.status_slow", defaultValue: "%@ • Quá chậm", bundle: .module), time)
}

public static func localizedRatingTitle(for speedRating: String) -> String {
    if speedRating.contains("Master") {
        return String(localized: "app.reflex.summary.rating_master", defaultValue: "Bậc thầy phản xạ", bundle: .module)
    } else if speedRating.contains("Swift") {
        return String(localized: "app.reflex.summary.rating_swift", defaultValue: "Phản xạ nhanh nhạy", bundle: .module)
    } else {
        return String(localized: "app.reflex.summary.rating_steady", defaultValue: "Người học kiên trì", bundle: .module)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzLocalizationTests`  
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzLocalizationTests.swift
git commit -m "feat(reflex): add summary localization keys and AppStrings accessors"
```

---

### Task 2: ReflexBlitzSummaryView UI/UX Overhaul & Token Alignment

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`

**Interfaces:**
- Consumes: `AppStrings.ReflexBlitz`, `CraftTheme`, `CraftCard`, `CraftBadge`, `CraftButton`, `CraftSpeakerButton`.
- Produces: Clean, modern, unified `ReflexBlitzSummaryView`.

- [ ] **Step 1: Write/update unit tests in `ReflexBlitzSummaryViewTests.swift`**

```swift
@MainActor
func testSummaryViewLocalizesRatingAndDiagnosesWeakWord() {
    let weakAttemptIncorrect = ReflexBlitzAttempt(
        wordId: 1,
        lemma: "improve",
        pos: "v.",
        ipa: "/ɪmˈpruːv/",
        definitionVi: "Cải thiện",
        responseTimeMs: 2000,
        usedHint: false,
        isCorrect: false
    )
    let weakAttemptSlow = ReflexBlitzAttempt(
        wordId: 2,
        lemma: "focus",
        pos: "v.",
        ipa: "/ˈfoʊ.kəs/",
        definitionVi: "Tập trung",
        responseTimeMs: 4500,
        usedHint: false,
        isCorrect: true
    )
    let summary = ReflexBlitzSessionSummary(
        id: UUID(),
        totalWords: 10,
        correctWords: 8,
        averageResponseTimeMs: 2400,
        maxComboStreak: 5,
        attempts: [weakAttemptIncorrect, weakAttemptSlow],
        weakWordAttempts: [weakAttemptIncorrect, weakAttemptSlow],
        speedRating: "⚡️ Reflex Master"
    )
    let view = ReflexBlitzSummaryView(
        summary: summary,
        onSpeakWord: { _ in },
        onReDrillWeak: {},
        onFinish: {}
    )
    XCTAssertNotNil(view.body)
    XCTAssertEqual(view.summary.weakWordAttempts.count, 2)
}
```

- [ ] **Step 2: Refactor `ReflexBlitzSummaryView.swift`**

Implement:
1. **Hero Header:** Single theme-accented badge squircle, localized title via `AppStrings.ReflexBlitz.localizedRatingTitle(for: summary.speedRating)`, stars + subtitle.
2. **Typography-First Bento Grid:** Clean `CraftCard(style: .outlined)` with large `.font(theme.typography.displaySmall).monospacedDigit()`, removing extra circle icons.
3. **Weak Words Section:** 
   - Header with `AppStrings.ReflexBlitz.weakWordsHeader(summary.weakWordAttempts.count)`.
   - Rows with lemma, `CraftSpeakerButton`, POS + IPA phonetics, Vietnamese definition, and diagnostic `CraftBadge`:
     - If `!weak.isCorrect`: `CraftBadge(AppStrings.ReflexBlitz.statusIncorrect, tone: .danger, size: .sm)`
     - Else: `CraftBadge(AppStrings.ReflexBlitz.statusSlow(timeFormatted), tone: .warning, size: .sm)`
4. **Bottom Action Dock:**
   - Primary: `CraftButton(AppStrings.ReflexBlitz.redrillWeak(summary.weakWordAttempts.count), variant: .tactile, size: .lg, isFullWidth: true, customTint: theme.colors.brandPrimary, action: onReDrillWeak)`
   - Secondary: `CraftButton(AppStrings.ReflexBlitz.finishSaveText, variant: .subtle, size: .md, isFullWidth: true, action: onFinish)`

- [ ] **Step 3: Run tests to verify they pass**

Run: `swift test --filter ReflexBlitzSummaryViewTests`  
Expected: PASS

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift
git commit -m "refactor(reflex): overhaul ReflexBlitzSummaryView with clean typography and token discipline"
```

---

### Task 3: Full Test Suite, SwiftLint & Xcode Build Verification

**Files:**
- Test: All test suites in `VocabCraftAppTests/`

- [ ] **Step 1: Run full test suite**

Run: `swift test`  
Expected: 100% tests pass

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`  
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Final Git status check & verification report**

Ensure working directory is clean and all files follow project guidelines.
