# Vocabulary View Header & Sticky Search Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Correct the visual hierarchy and UX of `VocabularyView` so that `CraftPageHeader` is at the top of the page, followed by an expandable/sticky `CraftSearchBar` and `CraftSegmentedControl`, a full-width Practice button, and the vocabulary word list, with smooth pinning on scroll down.

**Architecture:** Restructure `VocabularyView` inside a `ScrollView` using `LazyVStack(pinnedViews: [.sectionHeaders])`. The top item is `CraftPageHeader` (with title `"Vocabulary"` and trailing search toggle button). The `Section(header:)` pins `CraftSearchBar` (when expanded or scrolled past header) and `CraftSegmentedControl` at the top of the viewport during scrolling.

**Tech Stack:** Swift 5.10 / Swift 6, SwiftUI (iOS 17+), CraftUIKit design tokens & components (`CraftPageHeader`, `CraftSearchBar`, `CraftSegmentedControl`, `CraftButton`, `CraftIconButton`), Swift Testing / XCTest.

## Global Constraints
- Target platform: iOS 17.0+
- Zero raw colors, fonts, or hardcoded spacing — all styles must use `CraftTheme` tokens.
- Zero hardcoded English or Vietnamese strings in UI code — all strings in `Localizable.xcstrings` and `AppStrings+Vault.swift`.
- 100% bilingual parity between `en` and `vi` in `Localizable.xcstrings`.
- Zero compiler errors, zero warnings, and clean SwiftLint.

---

### Task 1: Update Localization for Vocabulary Title

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings+Vault.swift:6-9`
- Test: `VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift:10-12,99-102`

**Interfaces:**
- Consumes: `AppStrings.Vault.title`, `AppStrings.Vault.titleText`
- Produces: Updated localized title `"Vocabulary"` for English and `"Kho từ vựng"` for Vietnamese.

- [ ] **Step 1: Write failing test in `PersonalVaultLocalizationTests.swift`**

Update `PersonalVaultLocalizationTests.swift`:
```swift
    private let requiredVaultKeys: [String: (vi: String, en: String)] = [
        "app.vault.title": ("Kho từ vựng", "Vocabulary"),
        // ...
    ]

    @Test("Kiểm tra typed accessors trong AppStrings.Vault")
    func testAppStringsVaultAccessors() {
        #expect(AppStrings.Vault.titleText == "Vocabulary")
        // ...
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter PersonalVaultLocalizationTests`
Expected: FAIL due to `"Vocabulary Vault"` mismatch with expected `"Vocabulary"`.

- [ ] **Step 3: Update `Localizable.xcstrings` and `AppStrings+Vault.swift`**

In `VocabCraftApp/Resources/Localizable.xcstrings`:
Change `app.vault.title` English `value` from `"Vocabulary Vault"` to `"Vocabulary"`.

In `VocabCraftApp/Core/Localization/AppStrings+Vault.swift`:
```swift
        public static var title: LocalizedStringKey { "app.vault.title" }
        public static var titleText: String {
            String(localized: "app.vault.title", defaultValue: "Vocabulary", bundle: .module)
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter PersonalVaultLocalizationTests`
Expected: PASS with 3/3 tests passing.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings+Vault.swift VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift
git commit -m "fix(localization): update vocabulary title from 'Vocabulary Vault' to 'Vocabulary'"
```

---

### Task 2: Restructure `VocabularyView` View Hierarchy & Pinned Section Header

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift`

**Interfaces:**
- Consumes: `CraftPageHeader`, `CraftSearchBar`, `CraftSegmentedControl`, `CraftButton`, `VaultWordRowView`
- Produces: Correct visual hierarchy where `CraftPageHeader` is at the top inside `ScrollView`, followed by a pinned `Section` header containing `CraftSearchBar` and `CraftSegmentedControl`.

- [ ] **Step 1: Write integration tests in `PersonalVaultViewsTests.swift`**

Add tests to verify `VocabularyView` renders properly with search toggle initial states:
```swift
    func test_vocabularyView_initializationWithSearchVisible() {
        let vm = PersonalVaultViewModel(mockWords: [mockVaultWord])
        let view = VocabularyView(vaultViewModel: vm, isSearchVisible: true)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }
```

- [ ] **Step 2: Restructure `VocabularyView.swift` body**

Update `VocabularyView.swift`:
1. Move `CraftPageHeader` inside `ScrollView` within a `LazyVStack(pinnedViews: [.sectionHeaders])`.
2. Move `CraftSearchBar` and `CraftSegmentedControl` into a `Section(header: ...)` of the `LazyVStack`.
3. Wrap sticky header content in a background container with `theme.colors.canvasBackground` so content scrolling underneath is cleanly masked.
4. Place the Practice `CraftButton` and word list / empty state inside the Section body.

```swift
ScrollView(.vertical, showsIndicators: false) {
    LazyVStack(pinnedViews: [.sectionHeaders], spacing: theme.spacing.md) {
        // 1. Top Page Header (Scrolls with content)
        CraftPageHeader(
            AppStrings.Vault.title,
            alignment: .leading,
            enableScrollFade: true
        ) {
            CraftIconButton(
                iconName: isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass",
                size: .md,
                shape: .circle,
                variant: isSearchVisible ? .filled : .subtle,
                accessibilityLabel: AppStrings.Vault.searchToggleA11y,
                action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isSearchVisible.toggle()
                    }
                }
            )
        }

        // 2. Sticky Search & Segmented Filter Section
        Section {
            VStack(spacing: theme.spacing.md) {
                // Practice button — scrolls with content
                CraftButton(
                    verbatim: AppStrings.Vault.actionPracticeText,
                    variant: .tactile,
                    size: .lg,
                    isFullWidth: true,
                    action: {
                        let words = currentVaultVM.prepareReviewWords()
                        guard !words.isEmpty else { return }
                        activeDrillViewModel = appContainer.makeMixedReflexDrillViewModel(selectedWords: words)
                    }
                )
                .disabled(currentVaultVM.vaultWords.isEmpty)
                .padding(.horizontal, theme.spacing.base)

                // Main Word List / Empty State
                wordListContent(vaultVM: currentVaultVM)
            }
            .padding(.top, theme.spacing.xs)
            .padding(.bottom, theme.spacing.xxl + 40)
        } header: {
            stickyHeaderView(currentVaultVM: currentVaultVM, bindableVaultVM: bindableVaultVM)
        }
    }
}
```

- [ ] **Step 3: Run unit and view tests**

Run: `swift test --filter PersonalVaultViewsTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift
git commit -m "fix(VocabularyView): correct hierarchy with page header on top and pinned search & filter section"
```

---

### Task 3: Implement Scroll Offset Tracking & Automatic Sticky Search Expansion

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift`

**Interfaces:**
- Consumes: Coordinate space `"vocabScroll"`, `GeometryReader` or `onScrollGeometryChange`
- Produces: `isScrolledPastHeader: Bool` state triggering auto-reveal of `CraftSearchBar` in the sticky header when scrolled down.

- [ ] **Step 1: Add scroll tracking preference key and state in `VocabularyView.swift`**

```swift
private struct HeaderOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

Add `@State private var isScrolledPastHeader: Bool = false` to `VocabularyView`.
Attach geometry reader to `CraftPageHeader` to report `minY` relative to `.named("vocabScroll")`.
When `minY < -50`, set `isScrolledPastHeader = true` with smooth animation; otherwise `false`.

- [ ] **Step 2: Update sticky header view rendering**

In `stickyHeaderView`:
```swift
@ViewBuilder
private func stickyHeaderView(
    currentVaultVM: PersonalVaultViewModel,
    bindableVaultVM: PersonalVaultViewModel
) -> some View {
    VStack(spacing: theme.spacing.xs) {
        if isSearchVisible || isScrolledPastHeader {
            CraftSearchBar(
                text: $searchText,
                placeholder: AppStrings.Vault.searchPlaceholder,
                size: .md,
                style: .flat,
                onCancel: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        searchText = ""
                        currentVaultVM.setSearchQuery("")
                        isSearchVisible = false
                    }
                }
            )
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.xs)
            .transition(.move(edge: .top).combined(with: .opacity))
        }

        CraftSegmentedControl(
            selection: Binding(
                get: { bindableVaultVM.vaultTabFilter },
                set: { bindableVaultVM.setVaultFilter($0) }
            ),
            options: vaultSegmentOptions(metrics: currentVaultVM.metrics),
            style: .tactile3D
        )
        .padding(.horizontal, theme.spacing.base)
        .padding(.bottom, theme.spacing.xs)
    }
    .background(
        theme.colors.canvasBackground
            .craftShadow(isScrolledPastHeader ? theme.shadows.sm : CraftShadow(color: .clear, radius: 0))
    )
}
```

- [ ] **Step 3: Run tests to verify build & behavior**

Run: `swift test --filter PersonalVaultViewsTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift
git commit -m "feat(VocabularyView): add scroll offset detection for sticky search bar and tabs"
```

---

### Task 4: Full Quality Gate Verification

**Files:**
- None (verification across entire workspace)

- [ ] **Step 1: Run full test suite**

Run: `swift test`
Expected: 100% tests passing.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint` (if installed) or check Swift styling guidelines.
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Verify Xcode project build**

Run build or test via XcodeBuildMCP / xcodebuild.
Expected: Build succeeds with 0 errors and 0 warnings.
