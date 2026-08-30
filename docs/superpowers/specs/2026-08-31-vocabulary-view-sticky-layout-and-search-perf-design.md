# Vocabulary View: Sticky Layout & Search Performance Fix

## Problem Statement

After the Reusable Header Component (CraftPageHeader) integration in [conversation](conversation://6e16a813-6ee3-4cb0-8fba-dffdcc20d1ad), two critical issues were identified during real-device testing on the "Kho từ" (Vocabulary Vault) screen:

1. **Layout regression**: Scrolling hides the entire UI — header, search bar, segmented tabs, and practice button all scroll away together because everything is wrapped in a single `ScrollView`. The desired behavior is that search bar and category tabs remain sticky/pinned while only the word list scrolls.

2. **Search input severe lag**: Typing in `CraftSearchBar` is extremely laggy, and the cancel button animation stutters. Root causes: no debounce on database queries (every keystroke triggers `loadData()`), overly broad implicit animation scope, and unnecessary SF Symbol effects.

## Scope

- **In scope**: VocabularyView layout restructure, CraftSearchBar performance optimization, search debounce implementation
- **Out of scope**: CraftPageHeader modifications (its scroll-fade behavior is correct), CraftSegmentedControl changes, ViewModel API changes

## Design

### 1. VocabularyView Layout Restructure

#### Current Layout (Broken)

All content lives inside a single `ScrollView`, causing everything to scroll together:

```
NavigationStack > ZStack > ScrollView > VStack {
    CraftPageHeader          ← scrolls away
    CraftSearchBar           ← scrolls away (BUG)
    CraftSegmentedControl    ← scrolls away (BUG)
    CraftButton (Practice)   ← scrolls away
    LazyVStack (word list)   ← scrolls
}
```

#### New Layout

Split into two zones — a pinned zone outside `ScrollView` and a scrollable zone inside:

```
NavigationStack > ZStack > VStack(spacing: 0) {
    // ═══ PINNED ZONE (outside ScrollView) ═══
    CraftSearchBar           ← sticky (conditionally visible via toggle)
    CraftSegmentedControl    ← sticky (always visible)

    // ═══ SCROLLABLE ZONE ═══
    ScrollView {
        VStack {
            CraftPageHeader      ← scroll-fade (Apple Books effect preserved)
            CraftButton          ← scrolls with word list
            LazyVStack           ← word list
        }
    }
    .refreshable { ... }
}
```

#### Behavior Details

| Element | Behavior | Rationale |
|---------|----------|-----------|
| CraftPageHeader | Fades out on scroll via `.scrollTransition(.animated)` | Keeps approved Apple Books-style effect; maximizes content space |
| Search toggle (magnifier icon) | Lives in header trailing slot; fades with header | User accesses search via sticky search bar or scrolls to top to toggle |
| CraftSearchBar | Sticky in pinned zone when visible | Always accessible during search; no need to scroll back |
| CraftSegmentedControl | Always sticky in pinned zone | Category switching always accessible regardless of scroll position |
| Practice button | Scrolls with word list | Prioritizes content space; visible at top of list |

#### Transition & Animation

- Search bar toggle: Keeps existing spring animation (`.spring(response: 0.35, dampingFraction: 0.8)`) with `.transition(.move(edge: .top).combined(with: .opacity))`.
- Pinned zone uses `VStack(spacing: 0)` with appropriate padding from theme tokens.
- Background color extends behind pinned zone via `theme.colors.canvasBackground`.

### 2. Search Performance Optimization

#### 2.1 Debounce Search Queries (VocabularyView)

**Problem**: `setSearchQuery()` calls `Task { await loadData() }` on every keystroke — 10 characters typed = 10 concurrent database queries with race conditions.

**Solution**: Introduce local `@State` for text input, debounce via `.task(id:)`:

```swift
@State private var searchText: String = ""

// Bind CraftSearchBar to local state (instant, zero lag)
CraftSearchBar(text: $searchText, ...)

// Debounce: SwiftUI auto-cancels previous task when searchText changes
.task(id: searchText) {
    if searchText.isEmpty {
        currentVaultVM.setSearchQuery("")
        return
    }
    try? await Task.sleep(for: .milliseconds(300))
    guard !Task.isCancelled else { return }
    currentVaultVM.setSearchQuery(searchText)
}
```

**Why `.task(id:)`**: SwiftUI automatically cancels the previous task when the `id` value changes. This provides built-in debounce without manual `Task` management or cancellation tokens.

**ViewModel API unchanged**: `setSearchQuery()` in `PersonalVaultViewModel` keeps its current behavior (set property + call loadData). The debounce is handled at the View layer. Automation/programmatic callers still work as before.

**Sync considerations**: 
- On cancel: `searchText` is cleared immediately → `.task(id:)` fires with empty string → immediate loadData (no debounce for clear).
- On automation setup: `searchText` is synced from ViewModel's `searchQuery` in the `.task` modifier.

#### 2.2 Scope Animation in CraftSearchBar

**Problem**: `.animation(theme.animations.springSnappy, value: isFocused)` on the outer `HStack` (line 268) causes ALL child views to animate on focus change — text field, icon, clear button, backgrounds, borders all spring-animate simultaneously.

**Solution**: Remove the broad implicit animation. Apply scoped animation only where needed:

```swift
// REMOVE from outer HStack:
// .animation(theme.animations.springSnappy, value: isFocused)

// Cancel button already has its own .transition() — wrap its appearance in withAnimation
// The focus ring (borderOverlay) change is instant (no animation needed — it's a color swap)
```

Specific changes in `CraftSearchBar.body`:
1. **Remove** line 268: `.animation(theme.animations.springSnappy, value: isFocused)`
2. **Add** `withAnimation(theme.animations.springSnappy)` wrapping only the cancel button visibility change via a computed binding or by wrapping the `isFocused` state change.
3. The cancel button's existing `.transition(.asymmetric(...))` will handle its own enter/exit animation when wrapped in the appropriate `withAnimation`.

#### 2.3 Remove Unnecessary symbolEffect

**Problem**: `.symbolEffect(.bounce, value: isFocused)` on the search icon (line 178) triggers an SF Symbol animation every time focus changes. This is unnecessary visual noise and adds rendering overhead.

**Solution**: Remove the `.symbolEffect(.bounce, value: isFocused)` modifier entirely. The focus state is already communicated via the icon color change (muted → focus color) and the border glow.

### 3. Files Changed

#### `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift` [MODIFY]
- Restructure body layout: pinned zone (search + tabs) outside ScrollView, scrollable zone (header + practice + word list) inside ScrollView
- Add `@State private var searchText: String = ""`
- Change CraftSearchBar binding from ViewModel to local state
- Add `.task(id: searchText)` debounce block
- Sync `searchText` with ViewModel on automation setup and cancel

#### `Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift` [MODIFY]
- Remove `.animation(theme.animations.springSnappy, value: isFocused)` from outer HStack
- Remove `.symbolEffect(.bounce, value: isFocused)` from search icon
- Ensure cancel button transition still animates correctly via scoped animation

## Verification Plan

### Automated Tests
- `swift test` — full test suite passes with 0 failures
- Build with `xcodebuild` — 0 errors, 0 warnings

### Manual Verification (Real Device)
1. **Scroll behavior**: Scroll word list → header fades, search bar + tabs remain sticky
2. **Search toggle**: Tap magnifier in header → search bar appears in pinned zone (sticky)
3. **Search typing**: Type rapidly → no lag, text appears instantly, results update after ~300ms pause
4. **Cancel search**: Tap cancel → search bar hides smoothly, results reset immediately
5. **Tab switching**: Switch between Chưa thuộc / Đã thuộc / Đã lưu → tabs always visible during scroll
6. **Pull-to-refresh**: Pull down in scrollable zone → refresh works correctly
7. **Empty states**: Each tab shows appropriate empty state
8. **Practice button**: Visible at top, scrolls away with content
