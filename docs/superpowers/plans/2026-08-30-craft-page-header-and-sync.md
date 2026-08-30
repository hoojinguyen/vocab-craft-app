# CraftPageHeader & Cross-Screen Header Synchronization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a reusable, slot-based `CraftPageHeader` in `CraftUIKit` with Apple Books-inspired scroll-driven fading animations, fix the Home tab auto-scroll bug to preserve scroll position across tab switches, and modernize the Vocabulary Vault (Kho từ) header with a toggleable search bar.

**Architecture:** 
- **`CraftUIKit` Layer**: New organism `CraftPageHeader` supporting `.leading` (Large Title) and `.center` (Inline Title) layouts, `@ViewBuilder` slots for `leading` and `trailing`, and declarative Apple Books `.scrollTransition(.animated)` fading mechanics.
- **Scroll Stabilization**: Introduce `hasPerformedInitialScroll` in `CraftLearningPath` to execute auto-scroll to active node only once on initial launch, preserving scroll position during tab navigation.
- **Feature Layer**: Refactor `HomeTopHeaderView` to adopt `CraftPageHeader`, and update `VocabularyView` to replace the default navigation bar with `CraftPageHeader` and a spring-animated collapsible `CraftSearchBar`.

**Tech Stack:** Swift 6, SwiftUI (iOS 17+), CraftUIKit design tokens, Swift Testing / XCTest, `Localizable.xcstrings`.

## Global Constraints

- 100% CraftUIKit token conformance (`CraftTypographyTokens`, `CraftColorTokens`, `CraftSpacingTokens`). Zero raw colors or hardcoded fonts.
- Zero hardcoded strings: all strings declared in `Localizable.xcstrings` (`craft.*` in CraftUIKit, `app.*` in VocabCraftApp) with 100% EN & VI bilingual parity.
- 0 compiler warnings, 0 SwiftLint warnings, 100% test pass rate.

---

### Task 1: Create `CraftPageHeader` Component in `CraftUIKit` with TDD

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Header/CraftPageHeader.swift`
- Create: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftPageHeaderTests.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`

**Interfaces:**
- Produces:
  ```swift
  public enum CraftHeaderAlignment: Sendable, Equatable {
      case leading
      case center
  }

  public struct CraftPageHeader<Leading: View, Trailing: View>: View {
      public init(
          _ title: LocalizedStringKey,
          subtitle: LocalizedStringKey? = nil,
          alignment: CraftHeaderAlignment = .leading,
          enableScrollFade: Bool = true,
          @ViewBuilder leading: () -> Leading = { EmptyView() },
          @ViewBuilder trailing: () -> Trailing = { EmptyView() }
      )
  }
  ```

- [ ] **Step 1: Write the failing test for `CraftPageHeader`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftPageHeaderTests.swift`:

```swift
#if canImport(XCTest)
import XCTest
#endif
import SwiftUI
@testable import CraftUIKit

final class CraftPageHeaderTests: XCTestCase {
    func testCraftHeaderAlignmentEnum() {
        XCTAssertEqual(CraftHeaderAlignment.leading, .leading)
        XCTAssertEqual(CraftHeaderAlignment.center, .center)
        XCTAssertNotEqual(CraftHeaderAlignment.leading, .center)
    }

    func testCraftPageHeaderLeadingInitialization() {
        let header = CraftPageHeader(
            "Test Title",
            subtitle: "Test Subtitle",
            alignment: .leading,
            enableScrollFade: true,
            leading: { Text("Back") },
            trailing: { Text("Action") }
        )
        XCTAssertEqual(header.title, "Test Title")
        XCTAssertEqual(header.subtitle, "Test Subtitle")
        XCTAssertEqual(header.alignment, .leading)
        XCTAssertTrue(header.enableScrollFade)
        XCTAssertNotNil(header.body)
    }

    func testCraftPageHeaderCenterInitializationWithDefaults() {
        let header = CraftPageHeader(
            "Center Title",
            alignment: .center
        )
        XCTAssertEqual(header.title, "Center Title")
        XCTAssertNil(header.subtitle)
        XCTAssertEqual(header.alignment, .center)
        XCTAssertTrue(header.enableScrollFade)
        XCTAssertNotNil(header.body)
    }

    func testCraftPageHeaderStringInitializers() {
        let header = CraftPageHeader(
            verbatim: "Verbatim Title",
            subtitleVerbatim: "Verbatim Subtitle",
            alignment: .leading
        )
        XCTAssertEqual(header.alignment, .leading)
        XCTAssertNotNil(header.body)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftPageHeaderTests`
Expected: Compilation failure because `CraftPageHeader` and `CraftHeaderAlignment` do not exist yet.

- [ ] **Step 3: Implement `CraftPageHeader.swift` and update `Localizable.xcstrings`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Header/CraftPageHeader.swift`:

```swift
import SwiftUI

/// Layout alignment variant for `CraftPageHeader`.
public enum CraftHeaderAlignment: Sendable, Equatable {
    /// Large Title style (Leading-aligned title with `displayLarge` typography, Apple Books style).
    case leading
    /// Inline Title style (Centered title with `headline`/`titleLarge` typography).
    case center
}

/// A unified, slot-based navigation and page header organism in CraftUIKit with Apple Books scroll transition.
public struct CraftPageHeader<Leading: View, Trailing: View>: View {
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?
    public let alignment: CraftHeaderAlignment
    public let enableScrollFade: Bool

    private let leadingContent: Leading
    private let trailingContent: Trailing

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
        self.enableScrollFade = enableScrollFade
        self.leadingContent = leading()
        self.trailingContent = trailing()
    }

    public init(
        verbatim titleText: String,
        subtitleVerbatim: String? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = LocalizedStringKey(titleText)
        self.subtitle = subtitleVerbatim.map { LocalizedStringKey($0) }
        self.alignment = alignment
        self.enableScrollFade = enableScrollFade
        self.leadingContent = leading()
        self.trailingContent = trailing()
    }

    public var body: some View {
        applyScrollTransition(
            headerLayout
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.xs)
                .accessibilityElement(children: .contain)
                .accessibilityAddTraits(.isHeader)
        )
    }

    @ViewBuilder
    private var headerLayout: some View {
        switch alignment {
        case .leading:
            leadingLayout
        case .center:
            centerLayout
        }
    }

    private var leadingLayout: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            leadingContent

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title, bundle: .module)
                    .font(theme.typography.displayLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let subtitle {
                    Text(subtitle, bundle: .module)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: theme.spacing.xs)

            trailingContent
        }
    }

    private var centerLayout: some View {
        ZStack(alignment: .center) {
            HStack {
                leadingContent
                Spacer()
                trailingContent
            }

            VStack(alignment: .center, spacing: theme.spacing.xxs) {
                Text(title, bundle: .module)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let subtitle {
                    Text(subtitle, bundle: .module)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 48)
        }
    }

    @ViewBuilder
    private func applyScrollTransition<Content: View>(_ content: Content) -> some View {
        if enableScrollFade {
            content.scrollTransition(.animated) { view, phase in
                view
                    .opacity(reduceMotion ? (phase.isIdentity ? 1.0 : 0.0) : max(0.0, 1.0 - abs(phase.value) * 1.25))
                    .scaleEffect(reduceMotion ? 1.0 : (1.0 - abs(phase.value) * 0.04))
                    .offset(y: reduceMotion ? 0 : phase.value * -8)
            }
        } else {
            content
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("CraftPageHeader - Leading") {
    CraftPageHeader(
        "Home",
        subtitle: "Daily Learning Path",
        alignment: .leading
    ) {
        CraftBadge(label: "🔥 14", variant: .success, size: .sm)
    }
    .background(Color.vocabCanvas)
}

#Preview("CraftPageHeader - Center") {
    CraftPageHeader(
        "AI Tutor",
        subtitle: "Active Conversation",
        alignment: .center
    )
    .background(Color.vocabCanvas)
}
#endif
```

Add localization entries in `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:
- `"craft.header.a11y.title"`: EN `"Page Header"`, VI `"Tiêu đề trang"`.
- `"craft.header.a11y.search_toggle"`: EN `"Toggle Search"`, VI `"Bật tắt tìm kiếm"`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftPageHeaderTests`
Expected: PASS with all tests succeeding.

- [ ] **Step 5: Run LocalizationTests in CraftUIKit**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: PASS with 100% string coverage and valid bilingual pairs.

- [ ] **Step 6: Commit**

```bash
git add Packages/CraftUIKit/
git commit -m "feat(CraftUIKit): add CraftPageHeader with Apple Books scroll fade transition"
```

---

### Task 2: Stabilize Scroll Preservation & Auto-Scroll in `CraftLearningPath`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift:55-65, 484-500`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `CraftLearningPath` state management.
- Produces: Initial auto-scroll triggers only on first launch session; tab switching preserves scroll position without reset.

- [ ] **Step 1: Write a test verifying `CraftLearningPath` scroll stabilization state**

Update `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift` with a test case checking that `hasScrolledToActive` prevents redundant scroll triggers on repeat view evaluations.

- [ ] **Step 2: Update `CraftLearningPath.swift` auto-scroll lifecycle**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`:
Ensure `hasScrolledToActive` is maintained so that `.onAppear` only triggers `performScroll` once when `!hasScrolledToActive`. Add a slight 300ms layout stabilization before scrolling on initial launch so the large header is initially visible before gliding smoothly to the active node.

```swift
.onAppear {
    if scrollToActive, !hasScrolledToActive, let targetID = activeNodeID {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            performScroll(proxy, to: targetID, reducedMotion: isReducedMotion)
            hasScrolledToActive = true
        }
    }
}
```

- [ ] **Step 3: Run CraftLearningPathTests**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "fix(CraftLearningPath): stabilize auto-scroll to preserve scroll position across tab switches"
```

---

### Task 3: Refactor Home Screen Header to Adopt `CraftPageHeader`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `CraftPageHeader` from `CraftUIKit`.
- Produces: `HomeTopHeaderView` delegates layout, typography, and scroll transition to `CraftPageHeader`.

- [ ] **Step 1: Update `HomeTopHeaderViewTests.swift`**

Verify that `HomeTopHeaderView` initializes with user metrics, provides streak/avatar callbacks, and embeds inside `CraftPageHeader`.

- [ ] **Step 2: Refactor `HomeTopHeaderView.swift`**

Replace custom `HStack` title layout with `CraftPageHeader`:

```swift
import CraftUIKit
import SwiftUI

public struct HomeTopHeaderView: View {
    @Environment(\.craftTheme) private var theme

    public let userName: String
    public let streakDays: Int
    public let dailyWordsLearned: Int
    public let dailyWordsGoal: Int
    public var onAvatarTap: (() -> Void)?
    public var onStreakTap: (() -> Void)?

    public init(
        userName: String,
        streakDays: Int,
        dailyWordsLearned: Int,
        dailyWordsGoal: Int,
        onAvatarTap: (() -> Void)? = nil,
        onStreakTap: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyWordsLearned = dailyWordsLearned
        self.dailyWordsGoal = dailyWordsGoal
        self.onAvatarTap = onAvatarTap
        self.onStreakTap = onStreakTap
    }

    private var userInitials: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        if components.count >= 2, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let firstChar = trimmed.first {
            return "\(firstChar)".uppercased()
        }
        return "U"
    }

    private var dailyGoalProgress: Double {
        guard dailyWordsGoal > 0 else { return 0.0 }
        return Double(dailyWordsLearned) / Double(dailyWordsGoal)
    }

    private var isGoalCompletedToday: Bool {
        dailyWordsGoal > 0 && dailyWordsLearned >= dailyWordsGoal
    }

    public var body: some View {
        CraftPageHeader(
            AppStrings.Home.title,
            alignment: .leading,
            enableScrollFade: true
        ) {
            trailingActionsGroup
        }
    }

    private var trailingActionsGroup: some View {
        HStack(spacing: theme.spacing.sm) {
            // 1. Streak Flame Badge
            CraftStreakBadge(
                count: streakDays,
                tier: CraftStreakTier.tier(for: streakDays),
                isCompletedToday: isGoalCompletedToday,
                size: .sm,
                onTap: onStreakTap
            )

            // 2. Daily Goal Progress Ring (36pt)
            CraftProgressRing(
                progress: dailyGoalProgress,
                lineWidth: 2.5,
                size: 36,
                tintColor: theme.colors.brandPrimary,
                trackColor: theme.colors.surfaceSubtle,
                animated: true,
                accessibilityLabel: AppStrings.Home.dailyGoalA11y(completed: dailyWordsLearned, goal: dailyWordsGoal)
            ) {
                Text(AppStrings.Home.dailyGoalCount(completed: dailyWordsLearned, goal: dailyWordsGoal))
                    .font(theme.typography.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // 3. User Avatar Button
            avatarButton
        }
    }

    private var avatarButton: some View {
        Button(action: { onAvatarTap?() }) {
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                    )
                    .craftShadow(theme.shadows.sm)

                Text(userInitials)
                    .font(theme.typography.caption.weight(.bold))
                    .foregroundStyle(theme.colors.textInverse)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(userName)
        .accessibilityHint(AppStrings.Settings.profileActionViewText)
    }
}
```

- [ ] **Step 3: Run app tests for Homepage**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/HomeTopHeaderViewTests -only-testing:VocabCraftAppTests/HomepageViewTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Homepage/ VocabCraftAppTests/Features/Homepage/
git commit -m "feat(Home): adopt CraftPageHeader with Apple Books scroll fade in HomeTopHeaderView"
```

---

### Task 4: Modernize Vocabulary Vault (Kho từ) Header & Collapsible Search

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`

**Interfaces:**
- Consumes: `CraftPageHeader`, `CraftIconButton`, `CraftSearchBar`.
- Produces: Synchronized header in `VocabularyView` with toggleable search bar (default hidden).

- [ ] **Step 1: Write test for VocabularyView header and search toggle**

In `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`, add tests verifying header rendering and search toggle behavior.

- [ ] **Step 2: Update `VocabularyView.swift`**

Integrate `CraftPageHeader` and collapsible `CraftSearchBar`:

```swift
// Inside VocabularyView body:
@State private var isSearchVisible: Bool = false

// In body content:
VStack(spacing: theme.spacing.md) {
    // Top Synchronized Header
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
            accessibilityLabel: String(localized: "craft.header.a11y.search_toggle", bundle: .module),
            action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isSearchVisible.toggle()
                }
            }
        )
    }

    // Expandable Search Bar
    if isSearchVisible {
        CraftSearchBar(
            text: Binding(
                get: { bindableVaultVM.searchQuery },
                set: { bindableVaultVM.setSearchQuery($0) }
            ),
            placeholder: AppStrings.Vault.searchPlaceholder,
            size: .md,
            style: .flat,
            onCancel: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    bindableVaultVM.setSearchQuery("")
                    isSearchVisible = false
                }
            }
        )
        .padding(.horizontal, theme.spacing.base)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // 3-Tab Segmented Filter
    CraftSegmentedControl(...)
    ...
```

- [ ] **Step 3: Run VocabularyView tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/VocabularyViewTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/ VocabCraftAppTests/Features/Vocabulary/
git commit -m "feat(Vocabulary): integrate CraftPageHeader and toggleable search bar in VocabularyView"
```

---

### Task 5: Full Verification Suite & Quality Gate

**Files:**
- Test all components, linter, compiler warnings.

- [ ] **Step 1: Run CraftUIKit Package Tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% passing tests.

- [ ] **Step 2: Run Full App Test Suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: 100% passing tests.

- [ ] **Step 3: SwiftLint Compliance Check**

Run: `swiftlint`
Expected: 0 lint errors, 0 lint warnings.

- [ ] **Step 4: Commit and finalize**

```bash
git status
git commit -am "chore: complete CraftPageHeader integration and verification"
```
