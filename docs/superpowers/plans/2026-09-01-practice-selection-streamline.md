# Practice Selection UI Streamline, Smart Practice Relocation & Fullscreen Countdown Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Streamline the Vocabulary Vault Practice Selection sheet UI, relocate and wire instant Smart Practice CTA to the bottom bar, change drill presentation to full-screen cover, and correct the mixed drill countdown overlay.

**Architecture:** Refactor SwiftUI views (`PracticeSelectionView`, `PracticeSelectionRow`, `VocabularyView`, `ReflexCountdownOverlayView`, `MixedReflexDrillView`) within the MVVM + Clean Architecture flow. Cleanly decouple selection from redundant tab filters, elevate the bottom action bar with dual CTAs, provide full-screen presentation, and enforce 100% localized string taxonomy and zero warnings.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit design tokens, Swift Testing framework (`@Suite`, `@Test`, `#expect`), Xcodebuild.

**Spec:** [`docs/superpowers/specs/2026-09-01-practice-selection-streamline-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-01-practice-selection-streamline-design.md)

## Global Constraints

- Touch targets for all interactive controls must be $\ge 44\times 44\text{pt}$ (Apple HIG compliance).
- Zero raw colors, fonts, or hardcoded paddings — strictly use `craftTheme` tokens (`theme.colors`, `theme.typography`, `theme.spacing`, `theme.radii`, `theme.shadows`, `theme.animations`).
- Zero hardcoded user-facing strings — strictly use `app.practice.*` keys in `Localizable.xcstrings` and `AppStrings.Practice.*` typed accessors.
- Mandatory 100% bilingual parity (EN & VI) with extraction state `manual` and state `translated`.
- Zero compiler warnings, zero SwiftLint violations, 100% test pass rate.

---

### Task 1: Localization & AppStrings for Practice Selection Streamline & Mixed Countdown

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings+Practice.swift`
- Test: `VocabCraftAppTests/Features/PracticeSelectionLocalizationTests.swift`

**Interfaces:**
- Consumes: `AppStrings.Practice`
- Produces:
  - `AppStrings.Practice.titleText`: `"Chọn từ luyện tập"` (VI) / `"Select Words"` (EN)
  - `AppStrings.Practice.startButton(_ count: Int) -> String`: `"BẮT ĐẦU (%lld TỪ)"` (VI) / `"START PRACTICE (%lld WORDS)"` (EN)
  - `AppStrings.Practice.emptyPromptText`: `"CHỌN TỪ ĐỂ BẮT ĐẦU"` (VI) / `"SELECT WORDS TO START"` (EN)
  - `AppStrings.Practice.smartPickText`: `"⚡️ Luyện tập thông minh"` (VI) / `"⚡️ Smart Practice"` (EN)
  - `AppStrings.Practice.mixedDrillTitleText`: `"Luyện tập tổng hợp"` (VI) / `"Mixed Reflex Drill"` (EN)
  - `AppStrings.Practice.mixedDrillSubtitleText`: `"Phản xạ 4 kỹ năng: Trắc nghiệm, Gõ, Nghe & Nói"` (VI) / `"Multi-sensory reflex: Quiz, Typing, Listening & Speaking"` (EN)

- [ ] **Step 1: Write the failing localization tests**

Update `VocabCraftAppTests/Features/PracticeSelectionLocalizationTests.swift` to assert the required keys:
```swift
    private let requiredPracticeKeys: [String: (vi: String, en: String)] = [
        "app.practice.selection.title": ("Chọn từ luyện tập", "Select Words"),
        "app.practice.selection.back": ("Quay lại", "Back"),
        "app.practice.selection.close": ("Đóng", "Close"),
        "app.practice.selection.selected_count": ("%lld đã chọn", "%lld selected"),
        "app.practice.selection.select_all": ("Chọn tất cả", "Select All"),
        "app.practice.selection.deselect_all": ("Bỏ chọn tất cả", "Deselect All"),
        "app.practice.selection.smart_pick": ("⚡️ Luyện tập thông minh", "⚡️ Smart Practice"),
        "app.practice.selection.start_button": ("BẮT ĐẦU (%lld TỪ)", "START PRACTICE (%lld WORDS)"),
        "app.practice.selection.empty_prompt": ("CHỌN TỪ ĐỂ BẮT ĐẦU", "SELECT WORDS TO START"),
        "app.practice.selection.empty_title": ("Chưa có từ vựng", "No vocabulary"),
        "app.practice.selection.empty_message": ("Không tìm thấy từ vựng nào trong mục này.", "No vocabulary found in this section."),
        "app.practice.drill.cant_speak_now": ("Không thể nói lúc này", "Can't speak now"),
        "app.practice.countdown.mixed_title": ("Luyện tập tổng hợp", "Mixed Reflex Drill"),
        "app.practice.countdown.mixed_subtitle": ("Phản xạ 4 kỹ năng: Trắc nghiệm, Gõ, Nghe & Nói", "Multi-sensory reflex: Quiz, Typing, Listening & Speaking"),
        "app.practice.selection.toggle_a11y": ("Chọn từ %@", "Select word %@")
    ]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PracticeSelectionLocalizationTests`
Expected: FAIL due to missing or mismatched keys in `Localizable.xcstrings` and `AppStrings+Practice.swift`.

- [ ] **Step 3: Update `Localizable.xcstrings` and `AppStrings+Practice.swift`**

Add all standardized keys and typed accessors with exact EN/VI translations, extractionState: `manual`, and state: `translated`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PracticeSelectionLocalizationTests`
Expected: PASS with all localization assertions satisfied.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings+Practice.swift VocabCraftAppTests/Features/PracticeSelectionLocalizationTests.swift
git commit -m "feat(practice): standardize localization keys and typed accessors for practice selection"
```

---

### Task 2: Minimalist `PracticeSelectionRow` Component

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/Components/PracticeSelectionRow.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/PracticeSelectionViewsTests.swift`

**Interfaces:**
- Consumes: `VaultWordItem`, `theme.typography`, `theme.colors`, `theme.radii`, `theme.shadows`, `theme.animations`
- Produces: `PracticeSelectionRow(word: VaultWordItem, isSelected: Bool, onToggle: @escaping () -> Void)`

- [ ] **Step 1: Write the failing tests for `PracticeSelectionRow`**

In `VocabCraftAppTests/Features/Vocabulary/PracticeSelectionViewsTests.swift`:
```swift
    @Test("PracticeSelectionRow kích hoạt onToggle callback khi nhấn toàn bộ row")
    @MainActor
    func testPracticeSelectionRowCallbacks() {
        var toggleTriggered = false

        let row = PracticeSelectionRow(
            word: mockWords[0],
            isSelected: false,
            onToggle: {
                toggleTriggered = true
            }
        )

        #if canImport(UIKit)
        let host = UIHostingController(rootView: row)
        #expect(host.view != nil)
        #endif

        row.onToggle()
        #expect(toggleTriggered == true)
    }
```

- [ ] **Step 2: Run test to verify failure / compilation state**

Run: `swift test --filter PracticeSelectionViewsTests`
Expected: FAIL or compile error if init signature changes.

- [ ] **Step 3: Refactor `PracticeSelectionRow.swift`**

Strip out IPA, audio playback button, CEFR badge, POS badge, Vietnamese definition, and 4 mini sensory icons. Keep only `word.lemma` and the selection checkbox (`checkmark.circle.fill` / `circle`) with $\ge 56\text{pt}$ touch target, selection haptics, and accessible traits.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PracticeSelectionViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/Components/PracticeSelectionRow.swift VocabCraftAppTests/Features/Vocabulary/PracticeSelectionViewsTests.swift
git commit -m "refactor(practice): streamline PracticeSelectionRow to word lemma and checkbox"
```

---

### Task 3: Streamlined `PracticeSelectionView` with Bottom Sticky Bar & Immediate Smart Practice

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/PracticeSelectionView.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/PracticeSelectionViewsTests.swift`

**Interfaces:**
- Consumes: `PersonalVaultViewModel`, `PracticeSelectionRow`, `AppStrings.Practice`
- Produces: `PracticeSelectionView(vaultViewModel: PersonalVaultViewModel, onStartPractice: @escaping ([VaultWordItem]) -> Void, onClose: (() -> Void)?)`

- [ ] **Step 1: Write the failing tests for `PracticeSelectionView`**

In `VocabCraftAppTests/Features/Vocabulary/PracticeSelectionViewsTests.swift`:
- Test instant Smart Practice: tapping Smart Practice triggers `onStartPractice(pickedWords)` immediately.
- Test manual selection: selecting words and tapping `BẮT ĐẦU (%lld TỪ)` triggers `onStartPractice(selectedWords)`.
- Test Select All / Deselect All toggle.
- Verify `PracticeSelectionView` renders directly without `segmentedFilterBar`.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PracticeSelectionViewsTests`
Expected: FAIL.

- [ ] **Step 3: Refactor `PracticeSelectionView.swift`**

- Remove `segmentedFilterBar` (`CraftSegmentedControl`).
- Remove redundant count text in action toolbar.
- Keep clean navigationHeader with Back button ("Quay lại") and selected count badge (`CraftBadge("%lld đã chọn")`).
- Place Select All / Deselect All button in a compact sub-header.
- Construct `stickyBottomBar` with:
  1. Top CTA: `CraftButton(verbatim: AppStrings.Practice.smartPickText, iconName: "bolt.fill", variant: .tactile, size: .md, isFullWidth: true)` -> runs `smartPickWords()` and calls `onStartPractice(picked)`.
  2. Bottom CTA: `CraftButton(verbatim: selectedWordsCount > 0 ? AppStrings.Practice.startButton(selectedWordsCount) : AppStrings.Practice.emptyPromptText, iconName: "play.fill", variant: .tactile, size: .lg, isFullWidth: true)` -> calls `onStartPractice(selectedWords)`. Disabled when `selectedWordsCount == 0`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PracticeSelectionViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/PracticeSelectionView.swift VocabCraftAppTests/Features/Vocabulary/PracticeSelectionViewsTests.swift
git commit -m "feat(practice): relocate Smart Practice CTA to sticky bottom bar with instant launch"
```

---

### Task 4: Mixed Countdown Overlay & Fullscreen Drill Transition

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexCountdownOverlayView.swift`
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`

**Interfaces:**
- Consumes: `CraftCountdownOverlay`, `AppStrings.Practice`, `MixedReflexDrillViewModel`
- Produces:
  - `ReflexCountdownOverlayView` with flexible configuration (single-mode or mixed drill).
  - `MixedReflexDrillView` presenting mixed countdown with `AppStrings.Practice.mixedDrillTitleText` and `AppStrings.Practice.mixedDrillSubtitleText`.
  - `VocabularyView` presenting `MixedReflexDrillView` via `.fullScreenCover`.

- [ ] **Step 1: Write the failing tests for countdown and drill presentation**

In `VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift`:
- Test `ReflexCountdownOverlayView` configured for Mixed Drill displays correct title, subtitle, and icon.
- Test `MixedReflexDrillView` countdown displays mixed mode metadata rather than single-mode speaking text.

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter MixedReflexDrillViewsTests`
Expected: FAIL.

- [ ] **Step 3: Update `ReflexCountdownOverlayView.swift`, `MixedReflexDrillView.swift`, and `VocabularyView.swift`**

- In `ReflexCountdownOverlayView.swift`: Add support for mixed drill initializer (`count: Int, title: String?, subtitle: String?, iconName: String?, tintColor: Color?, onFinish: () -> Void`).
- In `MixedReflexDrillView.swift`: Pass `AppStrings.Practice.mixedDrillTitleText`, `AppStrings.Practice.mixedDrillSubtitleText`, icon `"bolt.fill"`, tint `theme.colors.brandPrimary` to countdown overlay.
- In `VocabularyView.swift`: Change `.sheet(item: $activeDrillViewModel)` to `.fullScreenCover(item: $activeDrillViewModel)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter MixedReflexDrillViewsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/Views/ReflexCountdownOverlayView.swift VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/MixedReflexDrillViewsTests.swift
git commit -m "fix(practice): correct mixed reflex drill countdown overlay and transition to fullScreenCover"
```

---

### Task 5: End-to-End Test Suite Verification & Clean Build Quality Gate

**Files:**
- Test all affected modules

- [ ] **Step 1: Run complete test suite**

Run: `swift test`
Expected: 100% tests pass.

- [ ] **Step 2: Run SwiftLint check**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Verify Xcode Build**

Run: `xcodebuild -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' clean build`
Expected: BUILD SUCCEEDED with 0 warnings.

- [ ] **Step 4: Final commit & tag if needed**

```bash
git status
```
