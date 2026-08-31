# Vocabulary View Header & Sticky Search Layout Design Spec

- **Date**: 2026-08-31
- **Status**: Approved
- **Scope**: `VocabCraftApp` (`VocabularyView`, `AppStrings+Vault`, `Localizable.xcstrings`)

---

## 1. Context & Problem Statement

In the Vocabulary screen (`VocabularyView`), the visual hierarchy was inverted because the search bar and 3-tab segmented control were placed outside the `ScrollView` above the `CraftPageHeader`. As a result, the segmented tabs appeared at the top edge of the screen, above the screen's main page header ("Vocabulary"), breaking iOS HIG standards and visual hierarchy.

Additionally, the English title localized string currently displays `"Vocabulary Vault"`, which needs to be updated to `"Vocabulary"`.

---

## 2. Requirements & Goals

1. **Initial Screen Hierarchy (Top to Bottom)**:
   - **Header**: `CraftPageHeader` with title `"Vocabulary"` (left-aligned) and search toggle button (`CraftIconButton` with `magnifyingglass` icon) on the trailing side.
   - **Search Input Bar**: `CraftSearchBar`, hidden by default at the top of the page; reveals/collapses with a smooth spring animation when the header search button is tapped.
   - **Segmented Filter Control**: `CraftSegmentedControl` with 3 category tabs (Learning / Mastered / Saved with count badges).
   - **Practice Action Button**: `CraftButton` (full width "PRACTICE" button).
   - **Word List / Empty State**: Lazy list of vocabulary cards (`VaultWordRowView`) or contextual `CraftEmptyState`.

2. **Scroll & Pinning Behavior (Sticky Search & Tabs)**:
   - When scrolling down past the header:
     - `CraftPageHeader` smoothly fades and scrolls out of view.
     - The section header containing `CraftSearchBar` and `CraftSegmentedControl` sticks to the top (under the safe area) using native `LazyVStack(pinnedViews: [.sectionHeaders])`.
     - When pinned, the search bar automatically becomes visible alongside the segmented filter tabs so the user can easily search or filter while exploring deep down in the word list.
   - When scrolling back up to the top:
     - The header smoothly re-appears.
     - The search bar visibility reverts to its user-toggled state (`isSearchVisible`).

3. **Localization Updates**:
   - `app.vault.title`:
     - `en`: `"Vocabulary"`
     - `vi`: `"Kho từ vựng"`
   - Keep 100% parity across `Localizable.xcstrings` and `AppStrings+Vault.swift`.

4. **Zero Hardcoded Strings & CraftUIKit Token Discipline**:
   - All text rendered via `Localizable.xcstrings` and `AppStrings`.
   - All colors, spacing, and typography styled exclusively through `CraftTheme` tokens.

---

## 3. View Architecture & Component Structure

```
NavigationStack
└── ZStack
    ├── theme.colors.canvasBackground (ignoresSafeArea)
    └── ScrollView(.vertical, showsIndicators: false)
        .coordinateSpace(name: "vocabScroll")
        └── LazyVStack(pinnedViews: [.sectionHeaders], spacing: theme.spacing.md)
            ├── [Top Header Item]
            │   └── CraftPageHeader("app.vault.title", alignment: .leading, enableScrollFade: true) {
            │           CraftIconButton(
            │               iconName: isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass",
            │               size: .md,
            │               shape: .circle,
            │               variant: isSearchVisible ? .filled : .subtle,
            │               accessibilityLabel: AppStrings.Vault.searchToggleA11y,
            │               action: { toggleSearch() }
            │           )
            │       }
            │       .background(GeometryReader tracking minY for isScrolledPastHeader)
            │
            └── Section(header: stickyHeaderView)
                ├── [Sticky Header View]
                │   ├── if isSearchVisible || isScrolledPastHeader {
                │   │       CraftSearchBar(...)
                │   │           .transition(.move(edge: .top).combined(with: .opacity))
                │   │   }
                │   └── CraftSegmentedControl(...)
                │   └── .background(theme.colors.canvasBackground)
                │   └── (Optional subtle bottom divider/shadow when isScrolledPastHeader is true)
                │
                └── [Section Content]
                    ├── CraftButton(verbatim: AppStrings.Vault.actionPracticeText, ...)
                    └── wordListContent(vaultVM: currentVaultVM)
```

---

## 4. State Management & Interaction Logic

| State Variable | Type | Purpose |
| :--- | :--- | :--- |
| `isSearchVisible` | `Bool` | User-driven toggle state when tapping the search button on the header |
| `isScrolledPastHeader` | `Bool` | Computed/tracked state indicating if the user has scrolled past the page header |
| `searchText` | `String` | Search input text bound to `CraftSearchBar` with 300ms debounce |
| `vaultVM` / `bindableVaultVM` | `PersonalVaultViewModel` | Manages word data, active filter tab, word count metrics, and selection |

### Interaction Details:
- **Search Button Tap**: Toggles `withAnimation(.spring(response: 0.35, dampingFraction: 0.8))` on `isSearchVisible`.
- **Search Cancel Button**: Clears search text, resets query in `vaultVM`, and collapses search bar if at top.
- **Scroll Tracking**: `GeometryReader` on scroll anchor reads `minY` relative to `"vocabScroll"` coordinate space. When `minY < -50`, `isScrolledPastHeader = true`; otherwise `false`.

---

## 5. File Modifications & Affected Areas

1. `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`:
   - Restructure view tree: put `CraftPageHeader` inside `ScrollView` within `LazyVStack`.
   - Embed `CraftSearchBar` and `CraftSegmentedControl` inside the `Section` header with sticky pinning (`pinnedViews: [.sectionHeaders]`).
   - Add scroll tracking logic for automatic sticky search visibility.

2. `VocabCraftApp/Core/Localization/AppStrings+Vault.swift`:
   - Update `titleText` default value from `"Vocabulary Vault"` to `"Vocabulary"`.

3. `VocabCraftApp/Resources/Localizable.xcstrings`:
   - Update `app.vault.title` English translation from `"Vocabulary Vault"` to `"Vocabulary"`.

4. `VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift` & `PersonalVaultViewsTests.swift`:
   - Update test expectations for `app.vault.title` string and hierarchy tests.

---

## 6. Verification & Quality Gates

- **Unit & Localization Tests**: `swift test --filter PersonalVaultLocalizationTests` and full test suite.
- **Compiler Checks**: Zero errors, zero warnings on Xcode build.
- **SwiftLint**: Ensure 0 lint violations.
