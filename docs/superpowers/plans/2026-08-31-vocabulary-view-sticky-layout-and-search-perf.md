# Vocabulary View Sticky Layout & Search Performance Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix VocabularyView so search bar + tabs stay pinned while scrolling, and eliminate CraftSearchBar typing lag.

**Architecture:** Split VocabularyView into a pinned zone (search + tabs outside ScrollView) and a scrollable zone (header + practice button + word list inside ScrollView). Add debounce via local `@State` + `.task(id:)`. Scope CraftSearchBar animations to eliminate broad implicit animation overhead.

**Tech Stack:** SwiftUI, CraftUIKit, Swift Observation (`@Observable`)

## Global Constraints

- iOS deployment target: current project minimum (iOS 17+)
- All styling via CraftUIKit design tokens — zero hardcoded colors/fonts/spacing
- All user-facing strings via localization (Localizable.xcstrings)
- Zero compiler warnings, zero lint warnings
- CraftSearchBar changes must not break other consumers (HomeTopHeaderView, any other screen using CraftSearchBar)

---

### Task 1: CraftSearchBar Performance Fix

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift:165-268`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftSearchBarTests.swift` (existing or new)

**Interfaces:**
- Consumes: `CraftTheme`, `CraftAnimationTokens`, `CraftIcon`, `CraftSpinner`
- Produces: Performance-optimized `CraftSearchBar` with same public API (no breaking changes)

- [ ] **Step 1: Remove broad implicit animation from CraftSearchBar body**

In `CraftSearchBar.swift`, locate the outer `HStack` closing and remove the `.animation()` modifier. Then wrap only the cancel button visibility condition in an explicit animation.

```swift
// FILE: Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift

// In the `body` computed property, the outer HStack currently ends with:
//     .animation(theme.animations.springSnappy, value: isFocused)
//
// REMOVE that line entirely.
//
// The cancel button block already has .transition(.asymmetric(...)) which will
// animate correctly when the isFocused change is wrapped in withAnimation.
// The cancel button's parent condition `if isFocused && onCancel != nil` will
// naturally animate via the transition modifier.

// Replace the final animation line:
// BEFORE (line 268):
//     .animation(theme.animations.springSnappy, value: isFocused)
// AFTER:
//     .animation(.none, value: isFocused)
```

Wait — we can't just remove the animation because the cancel button transition needs _some_ animation context to trigger. The correct approach:

```swift
// In CraftSearchBar body, REPLACE:
        .animation(theme.animations.springSnappy, value: isFocused)
// WITH nothing — remove the line entirely.

// Then modify the cancel button section to use explicit animation:
// Wrap the `if isFocused && onCancel != nil` block content is already
// using .transition(), which requires an animation context.
// Add .animation() ONLY to the cancel button, not the entire HStack.
```

The actual edit: In `CraftSearchBar.swift`:

1. **Remove line 268**: `.animation(theme.animations.springSnappy, value: isFocused)`
2. **Add scoped animation** on the cancel button `if` block:

```swift
            // Cancel Button — REPLACE the existing if block (lines 247-266):
            if isFocused && onCancel != nil {
                Button(action: {
                    isFocused = false
                    cancelHapticTrigger.toggle()
                    onCancel?()
                }) {
                    Text(CraftLocalized.string("craft.common.action.cancel"))
                        .font(cancelButtonFont)
                        .foregroundStyle(customTint ?? theme.colors.brandPrimary)
                        .padding(.horizontal, 4)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                .sensoryFeedback(.selection, trigger: cancelHapticTrigger)
            }
        }
        // ADD scoped animation ONLY for cancel button appearance:
        .animation(theme.animations.springSnappy, value: isFocused && onCancel != nil)
```

Wait, this still applies to the whole HStack. The key insight: we need the animation to trigger the cancel button's transition, but NOT animate the text field, icon, background, etc. The cleanest approach:

```swift
// Final approach — in CraftSearchBar body:
// 1. Remove the broad .animation() from the outer HStack
// 2. Wrap cancel button in a Group with its own .animation()

        // After the search input field container (the inner HStack with .clipShape),
        // add the cancel button wrapped with scoped animation:

        Group {
            if isFocused && onCancel != nil {
                Button(action: {
                    isFocused = false
                    cancelHapticTrigger.toggle()
                    onCancel?()
                }) {
                    Text(CraftLocalized.string("craft.common.action.cancel"))
                        .font(cancelButtonFont)
                        .foregroundStyle(customTint ?? theme.colors.brandPrimary)
                        .padding(.horizontal, 4)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                .sensoryFeedback(.selection, trigger: cancelHapticTrigger)
            }
        }
        .animation(theme.animations.springSnappy, value: isFocused)
    }
    // NO .animation() here on the outer HStack
```

- [ ] **Step 2: Remove symbolEffect bounce from search icon**

```swift
// FILE: Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift

// REMOVE line 178:
//     .symbolEffect(.bounce, value: isFocused)
//
// The icon already communicates focus state via color change
// (textMuted → borderFocus). The bounce is unnecessary overhead.
```

- [ ] **Step 3: Build CraftUIKit package to verify no compilation errors**

Run:
```bash
cd /Users/hoojinguyen/My-Workspace/vocab-craft-app
xcodebuild build -scheme CraftUIKit -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED, 0 errors, 0 warnings.

- [ ] **Step 4: Run existing CraftUIKit tests**

Run:
```bash
cd /Users/hoojinguyen/My-Workspace/vocab-craft-app/Packages/CraftUIKit
swift test 2>&1 | tail -20
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift
git commit -m "perf(CraftSearchBar): scope animation to cancel button only, remove symbolEffect bounce

- Remove broad .animation(springSnappy, value: isFocused) from outer HStack
- Wrap cancel button in Group with scoped .animation() 
- Remove .symbolEffect(.bounce) from search icon to reduce render overhead
- No public API changes — all existing consumers unaffected"
```

---

### Task 2: VocabularyView Layout Restructure & Search Debounce

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift:37-131`
- Test: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift` (existing)

**Interfaces:**
- Consumes: `CraftPageHeader`, `CraftSearchBar` (from Task 1), `CraftSegmentedControl`, `CraftButton`, `PersonalVaultViewModel`
- Produces: Restructured VocabularyView with sticky search/tabs and debounced search

- [ ] **Step 1: Add local search state property**

```swift
// FILE: VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift

// ADD after line 13 (after isSearchVisible declaration):
    @State private var searchText: String = ""
```

- [ ] **Step 2: Restructure body layout — pinned zone + scrollable zone**

Replace the `else` branch inside the `ZStack` (lines 53-131) with the new layout structure:

```swift
// FILE: VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift

// REPLACE the content inside the `else` block (lines 53-131):
                } else {
                    VStack(spacing: 0) {
                        // ═══ PINNED ZONE (outside ScrollView) ═══

                        // Expandable Search Bar — sticky when visible
                        if isSearchVisible {
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
                            .padding(.vertical, theme.spacing.xs)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 3-Tab Segmented Filter — always sticky
                        CraftSegmentedControl(
                            selection: Binding(
                                get: { bindableVaultVM.vaultTabFilter },
                                set: { bindableVaultVM.setVaultFilter($0) }
                            ),
                            options: vaultSegmentOptions(metrics: currentVaultVM.metrics),
                            style: .tactile3D
                        )
                        .padding(.horizontal, theme.spacing.base)
                        .padding(.vertical, theme.spacing.xs)

                        // ═══ SCROLLABLE ZONE ═══
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: theme.spacing.md) {
                                // Header with scroll-fade effect
                                CraftPageHeader(
                                    AppStrings.Vault.title,
                                    alignment: .leading,
                                    enableScrollFade: true
                                ) {
                                    CraftIconButton(
                                        iconName: isSearchVisible
                                            ? "magnifyingglass.circle.fill"
                                            : "magnifyingglass",
                                        size: .md,
                                        shape: .circle,
                                        variant: isSearchVisible ? .filled : .subtle,
                                        accessibilityLabel: AppStrings.Vault.searchToggleA11y,
                                        action: {
                                            withAnimation(.spring(
                                                response: 0.35,
                                                dampingFraction: 0.8
                                            )) {
                                                isSearchVisible.toggle()
                                            }
                                        }
                                    )
                                }

                                // Practice button — scrolls with content
                                CraftButton(
                                    verbatim: AppStrings.Vault.actionPracticeText,
                                    variant: .tactile,
                                    size: .lg,
                                    isFullWidth: true,
                                    action: {
                                        let words = currentVaultVM.prepareReviewWords()
                                        guard !words.isEmpty else { return }
                                        activeDrillViewModel = appContainer
                                            .makeMixedReflexDrillViewModel(
                                                selectedWords: words
                                            )
                                    }
                                )
                                .disabled(currentVaultVM.vaultWords.isEmpty)
                                .padding(.horizontal, theme.spacing.base)

                                // Word List / Empty State
                                wordListContent(vaultVM: currentVaultVM)
                            }
                            .padding(.top, theme.spacing.xs)
                            .padding(.bottom, theme.spacing.xxl + 40)
                        }
                        .refreshable {
                            await currentVaultVM.loadData()
                        }
                    }
                }
```

- [ ] **Step 3: Add debounce via .task(id:) on the VStack**

Add the debounce modifier on the outer `VStack(spacing: 0)` right after the closing brace, before the `}` that closes the `else` block:

```swift
// FILE: VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift

// ADD .task(id:) modifier on the VStack(spacing: 0) for debounce:
                    VStack(spacing: 0) {
                        // ... pinned zone + scrollable zone ...
                    }
                    .task(id: searchText) {
                        if searchText.isEmpty {
                            return
                        }
                        try? await Task.sleep(for: .milliseconds(300))
                        guard !Task.isCancelled else { return }
                        currentVaultVM.setSearchQuery(searchText)
                    }
```

- [ ] **Step 4: Sync searchText with automation state**

In the `applyAutomationFilterAndSearch` method, also set `searchText` when setting search query programmatically:

```swift
// FILE: VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift

// In applyAutomationFilterAndSearch, update both searchText and VM:
    private func applyAutomationFilterAndSearch(state: String) {
        guard let vm = vaultVM else { return }
        switch state {
        case "personal-filter-needs-review", "filter-not-mastered":
            vm.setVaultFilter(.notMastered)
        case "personal-filter-mastered":
            vm.setVaultFilter(.mastered)
        case "personal-filter-bookmarked":
            vm.setVaultFilter(.bookmarked)
        case "personal-search-match":
            searchText = "resilience"
            vm.setSearchQuery("resilience")
            isSearchVisible = true
        case "personal-search-empty":
            searchText = "không_tìm_thấy_từ"
            vm.setSearchQuery("không_tìm_thấy_từ")
            isSearchVisible = true
        default:
            break
        }
    }
```

- [ ] **Step 5: Build the full app to verify no compilation errors**

Run:
```bash
cd /Users/hoojinguyen/My-Workspace/vocab-craft-app
xcodebuild build -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -10
```
Expected: BUILD SUCCEEDED, 0 errors, 0 warnings.

- [ ] **Step 6: Run existing VocabularyView tests**

Run:
```bash
cd /Users/hoojinguyen/My-Workspace/vocab-craft-app
xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/VocabularyViewTests -quiet 2>&1 | tail -20
```
Expected: All existing tests pass. If any tests reference the old binding pattern (`bindableVaultVM.searchQuery` in binding), they need to be updated to work with the new local state pattern.

- [ ] **Step 7: Run full test suite**

Run:
```bash
cd /Users/hoojinguyen/My-Workspace/vocab-craft-app
xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -20
```
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift
git commit -m "fix(VocabularyView): sticky search bar + tabs, debounced search input

Layout restructure:
- Move CraftSearchBar and CraftSegmentedControl to pinned zone outside ScrollView
- Keep CraftPageHeader scroll-fade inside ScrollView (Apple Books effect preserved)
- Practice button scrolls with word list content

Performance:
- Add local @State searchText with 300ms debounce via .task(id:)
- CraftSearchBar binds to local state for instant typing response
- Database query only fires after user stops typing for 300ms
- Immediate clear on cancel (no debounce for empty query)"
```
