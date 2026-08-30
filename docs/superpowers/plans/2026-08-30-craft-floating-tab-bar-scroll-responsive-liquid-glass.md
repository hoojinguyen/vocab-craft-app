# CraftFloatingTabBar Scroll-Responsive Liquid Glass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `CraftFloatingTabBar` native iOS 26 Liquid Glass composition and an accessibility-safe, scroll-direction-driven compact state for the Homepage Learning Path.

**Architecture:** `CraftFloatingTabBar` receives a backward-compatible `CraftTabBarPresentation` value and resolves compact metrics internally. `CraftLearningPath` retains ownership of its `ScrollView`, converts iOS 18+ scroll geometry into presentation events through a small reducer, and Homepage owns the resulting state. iOS 17 keeps the expanded material fallback rather than installing a competing drag gesture.

**Tech Stack:** SwiftUI, Swift Package Manager, iOS 17 deployment target, iOS 18 `onScrollGeometryChange` / `onScrollPhaseChange`, iOS 26 `GlassEffectContainer` / `glassEffect` / `glassEffectID`, XCTest, XcodeBuildMCP.

**Spec:** `docs/superpowers/specs/2026-08-30-craft-floating-tab-bar-scroll-responsive-liquid-glass-design.md`

## Global Constraints

- Preserve every existing public `CraftFloatingTabBar` initializer by defaulting `presentation` to `.expanded`.
- Use CraftUIKit theme tokens only; introduce no raw color, font, spacing, radius, or display/accessibility string.
- Keep every tab and center action hit target at or above `CraftTabBarSize.sm.barHeight`.
- Apply native Liquid Glass only inside `#available(iOS 26, macOS 26, *)`; preserve themed material/opaque fallbacks elsewhere.
- Reduce Motion removes spring/scale motion; Reduce Transparency selects opaque visual fallbacks.
- Keep scroll ownership inside `CraftLearningPath`; do not add a `DragGesture`, global scroll state, or UIKit scroll bridge.
- Do not stage Xcode-generated or unrelated files. Inspect `git status --short` and `git diff --check` before every commit.

---

### Task 1: Define and test the presentation reducer and motion policy

**Files:**

- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:190-218`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFloatingTabBarTests.swift:8-20`

**Interfaces:**

- Produces `public enum CraftTabBarPresentation: String, Sendable, Equatable, CaseIterable { case expanded, compact }`.
- Produces internal `CraftTabBarScrollPresentationReducer` with `mutating func receive(contentOffset: CGFloat, threshold: CGFloat) -> CraftTabBarPresentation?` and `mutating func reset(at: CGFloat = 0)`.
- Produces `CraftTabBarAnimationPolicy.presentationAnimation(reduceMotion:animations:) -> Animation?`.

- [ ] **Step 1: Write the failing reducer and motion-policy tests**

  Append these XCTest cases to `CraftFloatingTabBarTests`:

  ```swift
  func testScrollPresentationReducerCompactsAfterDeliberateDownwardTravel() {
      var reducer = CraftTabBarScrollPresentationReducer()

      XCTAssertNil(reducer.receive(contentOffset: 0, threshold: 24))
      XCTAssertNil(reducer.receive(contentOffset: 12, threshold: 24))
      XCTAssertEqual(reducer.receive(contentOffset: 24, threshold: 24), .compact)
      XCTAssertEqual(reducer.presentation, .compact)
  }

  func testScrollPresentationReducerExpandsAfterDeliberateUpwardTravel() {
      var reducer = CraftTabBarScrollPresentationReducer(presentation: .compact)

      XCTAssertNil(reducer.receive(contentOffset: 96, threshold: 24))
      XCTAssertNil(reducer.receive(contentOffset: 84, threshold: 24))
      XCTAssertEqual(reducer.receive(contentOffset: 72, threshold: 24), .expanded)
      XCTAssertEqual(reducer.presentation, .expanded)
  }

  func testScrollPresentationReducerIgnoresTopBounceAndNonFiniteOffsets() {
      var reducer = CraftTabBarScrollPresentationReducer()

      XCTAssertNil(reducer.receive(contentOffset: 0, threshold: 24))
      XCTAssertNil(reducer.receive(contentOffset: -32, threshold: 24))
      XCTAssertNil(reducer.receive(contentOffset: .infinity, threshold: 24))
      XCTAssertEqual(reducer.presentation, .expanded)
  }

  func testPresentationAnimationRespectsReduceMotion() {
      let animations = CraftDefaultAnimationTokens()

      XCTAssertNotNil(
          CraftTabBarAnimationPolicy.presentationAnimation(
              reduceMotion: false,
              animations: animations
          )
      )
      XCTAssertNil(
          CraftTabBarAnimationPolicy.presentationAnimation(
              reduceMotion: true,
              animations: animations
          )
      )
  }
  ```

- [ ] **Step 2: Run the focused test target and verify RED**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit --filter CraftFloatingTabBarTests
  ```

  Expected: compilation fails because `CraftTabBarPresentation`, `CraftTabBarScrollPresentationReducer`, and `presentationAnimation` do not exist.

- [ ] **Step 3: Implement the smallest reducer and motion policy**

  Add the public enum immediately after `CraftCenterButtonPosition`. Add this internal reducer next to `CraftTabBarAnimationPolicy`:

  ```swift
  struct CraftTabBarScrollPresentationReducer: Equatable {
      private(set) var presentation: CraftTabBarPresentation
      private var lastOffset: CGFloat?
      private var directionalTravel: CGFloat = 0

      init(presentation: CraftTabBarPresentation = .expanded) {
          self.presentation = presentation
      }

      mutating func reset(at contentOffset: CGFloat = 0) {
          lastOffset = normalized(contentOffset)
          directionalTravel = 0
      }

      mutating func receive(
          contentOffset: CGFloat,
          threshold: CGFloat
      ) -> CraftTabBarPresentation? {
          guard contentOffset.isFinite, threshold > 0 else { return nil }

          let offset = normalized(contentOffset)
          guard let lastOffset else {
              self.lastOffset = offset
              return nil
          }

          let delta = offset - lastOffset
          self.lastOffset = offset

          switch presentation {
          case .expanded:
              directionalTravel = delta > 0 ? directionalTravel + delta : 0
              guard directionalTravel >= threshold else { return nil }
              presentation = .compact
          case .compact:
              directionalTravel = delta < 0 ? directionalTravel - delta : 0
              guard directionalTravel >= threshold else { return nil }
              presentation = .expanded
          }

          directionalTravel = 0
          return presentation
      }

      private func normalized(_ contentOffset: CGFloat) -> CGFloat {
          max(0, contentOffset)
      }
  }
  ```

  Add `presentationAnimation` beside `selectionAnimation` and return `nil` for Reduce Motion or `animations.springGentle` otherwise. Do not change selection animation in this task.

- [ ] **Step 4: Run the focused target and verify GREEN**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit --filter CraftFloatingTabBarTests
  ```

  Expected: all reducer and animation-policy tests pass with no warnings.

- [ ] **Step 5: Refactor only names or duplicated setup while keeping tests green**

  Keep `presentation`, `lastOffset`, and `directionalTravel` private. Keep `reset(at:)` as the only baseline-reset API so `CraftLearningPath` never writes reducer state directly. Re-run the focused test command from Step 4.

- [ ] **Step 6: Commit the isolated core behavior**

  Run `git status --short` and `git diff --check`. If only the two task files are intended changes, commit them:

  ```bash
  git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFloatingTabBarTests.swift
  git commit -m "feat(navigation): add tab bar scroll presentation state"
  ```

### Task 2: Make the tab bar’s compact state and native glass composition real

**Files:**

- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:225-820`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift:20-470`

**Interfaces:**

- Extends both `CraftFloatingTabBar` initializers with `presentation: CraftTabBarPresentation = .expanded`.
- Exposes `public let presentation: CraftTabBarPresentation`.
- Uses an internal `resolvedSize` that is `.sm` for `.compact` and otherwise respects the caller’s `size`.
- Keeps a center button’s hit frame at `max(CraftTabBarSize.sm.barHeight, circleDiameter)`.

- [ ] **Step 1: Write failing construction and compact-metric tests**

  Add these cases to `NavigationTests`:

  ```swift
  func testFloatingTabBarDefaultsToExpandedPresentation() {
      let binding = Binding(get: { SampleTab.home }, set: { _ in })
      let bar = CraftFloatingTabBar(selectedItem: binding, items: SampleTab.allCases)

      XCTAssertEqual(bar.presentation, .expanded)
      XCTAssertEqual(bar.resolvedSize, .md)
  }

  func testFloatingTabBarUsesCompactPresentationMetrics() {
      let binding = Binding(get: { SampleTab.home }, set: { _ in })
      let bar = CraftFloatingTabBar(
          selectedItem: binding,
          items: SampleTab.allCases,
          size: .lg,
          presentation: .compact,
          centerAction: {},
          centerSymbol: CraftSymbol.add.rawValue
      )

      XCTAssertEqual(bar.presentation, .compact)
      XCTAssertEqual(bar.resolvedSize, .sm)
      XCTAssertGreaterThanOrEqual(
          bar.centerActionHitTargetDiameter,
          CraftTabBarSize.sm.barHeight
      )
      XCTAssertNotNil(bar.body)
  }
  ```

- [ ] **Step 2: Run the focused navigation suite and verify RED**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit --filter NavigationTests
  ```

  Expected: compilation fails because `presentation`, `resolvedSize`, and `centerActionHitTargetDiameter` are missing.

- [ ] **Step 3: Add the backward-compatible presentation API and safe compact metrics**

  Add `presentation` immediately after `size` in both initializers, store it, and define these properties in `CraftFloatingTabBar`:

  ```swift
  public let presentation: CraftTabBarPresentation

  var resolvedSize: CraftTabBarSize {
      presentation == .compact ? .sm : size
  }

  var centerActionHitTargetDiameter: CGFloat {
      max(
          CraftTabBarSize.sm.barHeight,
          resolvedSize.centerButtonDiameter(position: centerPosition)
      )
  }
  ```

  Replace all visual metric reads in `barContainer`, `tabButtonsStack`, `CraftTabButton`, and `CraftCenterActionButton` with `resolvedSize`. Keep `size` as the configured public preference so existing clients’ reads do not change. Pass the hit-target diameter into `CraftCenterActionButton`; its outer button frame uses the hit target while its visual circle retains the resolved diameter.

- [ ] **Step 4: Group all iOS 26 glass surfaces and scope presentation animation**

  Restructure the iOS 26 / `.glass` branch so one `GlassEffectContainer` owns the capsule plus optional center action. Keep the non-glass branch on the existing legacy background path. Follow this structure, using existing theme tokens for every visual value:

  ```swift
  if #available(iOS 26, macOS 26, *), style == .glass {
      GlassEffectContainer(spacing: theme.spacing.xs) {
          ZStack {
              barContent
                  .padding(.horizontal, resolvedSize.horizontalPadding)
                  .padding(.vertical, resolvedSize.verticalPadding)
                  .background {
                      Capsule()
                          .fill(theme.colors.surfaceCard.opacity(theme.opacities.subtle))
                          .glassEffect(
                              .regular.tint(
                                  theme.colors.brandPrimary.opacity(theme.glass.tintOpacity)
                              ),
                              in: .capsule
                          )
                          .glassEffectID("craft.tab_bar.surface", in: glassNamespace)
              }

              if let centerAction {
                  CraftCenterActionButton(
                      symbol: centerSymbol,
                      titleKey: centerTitleKey,
                      title: rawCenterTitle,
                      style: style,
                      size: resolvedSize,
                      position: centerPosition,
                      hitTargetDiameter: centerActionHitTargetDiameter,
                      glassNamespace: glassNamespace,
                      action: centerAction
                  )
              }
          }
      }
  }
  ```

  Add `@Namespace private var glassNamespace`. In the glass center-action branch, apply `.glassEffect(.regular.tint(theme.colors.brandPrimary.opacity(theme.glass.tintOpacity)).interactive(), in: .circle)` after its circle frame and then `.glassEffectID("craft.tab_bar.center_action", in: glassNamespace)`. The center action is the only interactive glass surface.

  Apply presentation motion only to geometry-changing modifiers:

  ```swift
  .animation(
      CraftTabBarAnimationPolicy.presentationAnimation(
          reduceMotion: reduceMotion,
          animations: theme.animations
      ),
      value: presentation
  )
  ```

  Keep the existing selection animation bound only to `selectedItem.id`. Do not apply a bare `.animation(_:)` to the full `ZStack`.

- [ ] **Step 5: Complete the native selection lens without weakening the fallback**

  In `CraftSlidingFluidPill`, gate the `.glass` presentation by availability. For iOS 26 non-reduced-transparency rendering, use a native capsule glass effect tinted from `theme.colors.brandPrimary` and attach the existing matched-geometry lens to the shared glass namespace in `CraftTabButton`. Keep the current layered `glassPill` as the pre-iOS-26 fallback and keep all other `CraftSurfaceStyle` branches unchanged.

  Preserve the current Reduce Motion path by leaving squash/stretch at identity. Do not add a new custom color, shadow, font, or radius.

- [ ] **Step 6: Run navigation tests and inspect the diff**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit --filter NavigationTests
  git diff --check
  ```

  Expected: NavigationTests pass and the diff contains no whitespace errors or hardcoded visual tokens.

- [ ] **Step 7: Commit the visual component change**

  Run `git status --short`. If no unrelated or Xcode-generated files are present, commit:

  ```bash
  git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift
  git commit -m "feat(navigation): compact floating tab bar with native glass"
  ```

### Task 3: Let CraftLearningPath publish deliberate user-scroll presentation changes

**Files:**

- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift:20-360,392-502`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift:3435-3586`

**Interfaces:**

- Adds optional `onTabBarPresentationChange: (@Sendable (CraftTabBarPresentation) -> Void)? = nil` to the primary multi-section initializer.
- Adds internal `handleTabBarScrollOffset(_:)` and `handleScrollPhaseChange(_:context:)` helpers.
- Uses `onScrollGeometryChange(for: CGFloat.self, of:action:)` and `onScrollPhaseChange` only under `#available(iOS 18, macOS 15, *)`.

- [ ] **Step 1: Write failing Learning Path construction tests**

  Add this test to `CraftLearningPathTests`, using the nearby existing `LessonSection` fixture pattern:

  ```swift
  func testLearningPathAcceptsOptionalTabBarPresentationCallback() {
      let section = LessonSection(
          id: "tab_bar_scroll",
          title: "",
          nodes: []
      )
      let path = CraftLearningPath(
          sections: [section],
          onTabBarPresentationChange: { _ in }
      )

      XCTAssertNotNil(path.body)
      XCTAssertNotNil(path.onTabBarPresentationChange)
  }
  ```

- [ ] **Step 2: Run the targeted test and verify RED**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests
  ```

  Expected: compilation fails because the new initializer argument is absent.

- [ ] **Step 3: Add callback storage and local scroll tracking**

  Add the optional closure property, plus these local states to `CraftLearningPath`:

  ```swift
  @State private var tabBarScrollReducer = CraftTabBarScrollPresentationReducer()
  @State private var tracksUserTabBarScroll = false
  ```

  Accept and store `onTabBarPresentationChange` in the primary multi-section initializer. Convenience initializers continue calling that initializer without the new argument so every existing call site retains its behavior.

  In the existing `ScrollView` chain, add the following only on iOS 18 / macOS 15 and later:

  ```swift
  .onScrollPhaseChange { _, newPhase, context in
      handleScrollPhaseChange(newPhase, context: context)
  }
  .onScrollGeometryChange(for: CGFloat.self) { geometry in
      geometry.contentOffset.y + geometry.contentInsets.top
  } action: { _, contentOffset in
      handleTabBarScrollOffset(contentOffset)
  }
  ```

  Implement the helpers as follows:

  ```swift
  private func handleScrollPhaseChange(
      _ phase: ScrollPhase,
      context: ScrollPhaseChangeContext
  ) {
      let contentOffset = context.geometry.contentOffset.y + context.geometry.contentInsets.top

      switch phase {
      case .tracking:
          tracksUserTabBarScroll = true
          tabBarScrollReducer.reset(at: contentOffset)
      case .interacting, .decelerating:
          tracksUserTabBarScroll = true
      case .idle, .animating:
          tracksUserTabBarScroll = false
          tabBarScrollReducer.reset(at: contentOffset)
      }
  }

  private func handleTabBarScrollOffset(_ contentOffset: CGFloat) {
      guard tracksUserTabBarScroll,
            let presentation = tabBarScrollReducer.receive(
                contentOffset: contentOffset,
                threshold: theme.spacing.lg
            )
      else {
          return
      }

      onTabBarPresentationChange?(presentation)
  }
  ```

  Keep the iOS 17 path unchanged: it has no scroll callback and therefore remains expanded. This deliberately excludes programmatic `.animating` scrolls such as `scrollToActive`.

- [ ] **Step 4: Run Learning Path and reducer regression tests**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests
  swift test --package-path Packages/CraftUIKit --filter CraftFloatingTabBarTests
  ```

  Expected: both focused suites pass. The callback construction test proves the extension is opt-in and requires no state until a user scroll reaches the reducer.

- [ ] **Step 5: Commit the opt-in scroll pipeline**

  Run `git status --short` and `git diff --check`. If only the Learning Path source and test changed, commit:

  ```bash
  git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
  git commit -m "feat(learning-path): publish tab bar scroll presentation"
  ```

### Task 4: Wire Homepage, document both states in the catalog, and test the app boundary

**Files:**

- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:8-145`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift:29-92`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift:2270-2305`

**Interfaces:**

- Homepage owns `@State private var tabBarPresentation: CraftTabBarPresentation = .expanded`.
- Adds internal `HomepageTabBarPresentationPolicy.presentation(for:current:) -> CraftTabBarPresentation` to reset state for all non-Home tabs.
- Homepage passes `tabBarPresentation` to `CraftFloatingTabBar` and receives Learning Path changes through `MainActor.assumeIsolated`.

- [ ] **Step 1: Write the failing Homepage state-policy and construction tests**

  Add these cases to `HomepageViewTests`:

  ```swift
  func testTabBarPresentationPolicyPreservesHomePresentation() {
      XCTAssertEqual(
          HomepageTabBarPresentationPolicy.presentation(
              for: .home,
              current: .compact
          ),
          .compact
      )
  }

  func testTabBarPresentationPolicyResetsOutsideHome() {
      XCTAssertEqual(
          HomepageTabBarPresentationPolicy.presentation(
              for: .vocabulary,
              current: .compact
          ),
          .expanded
      )
  }

  func testCraftFloatingTabBarInitializationSupportsCompactPresentation() {
      let tabBar = CraftFloatingTabBar(
          selectedItem: .constant(TabItem.home),
          items: TabItem.navigationTabs,
          style: .glass,
          presentation: .compact,
          centerPosition: .floating,
          centerAction: {},
          centerSymbol: CraftSymbol.practice.rawValue,
          centerTitleKey: AppStrings.Tabs.reflex
      )

      XCTAssertEqual(tabBar.presentation, .compact)
      XCTAssertNotNil(tabBar.body)
  }
  ```

- [ ] **Step 2: Run the app test target and verify RED**

  First call XcodeBuildMCP `session_show_defaults`. If it reports missing project, scheme, or simulator, call `discover_projs` once, select `VocabCraftApp.xcodeproj` and the `VocabCraftApp` scheme, then call `session_show_defaults` again. Run the test target with XcodeBuildMCP `test_sim`.

  Expected: compilation fails because `HomepageTabBarPresentationPolicy` and the compact initializer parameter do not exist in the app target.

- [ ] **Step 3: Implement the Homepage state boundary**

  Add this focused policy above `HomepageView`:

  ```swift
  enum HomepageTabBarPresentationPolicy {
      static func presentation(
          for tab: TabItem,
          current: CraftTabBarPresentation
      ) -> CraftTabBarPresentation {
          tab == .home ? current : .expanded
      }
  }
  ```

  Add `@State private var tabBarPresentation: CraftTabBarPresentation = .expanded` to `HomepageView`. In the Home `CraftLearningPath` initializer, add:

  ```swift
  onTabBarPresentationChange: { presentation in
      MainActor.assumeIsolated {
          tabBarPresentation = presentation
      }
  }
  ```

  Pass `presentation: tabBarPresentation` to `CraftFloatingTabBar`. In the existing selected-tab `onChange`, set:

  ```swift
  tabBarPresentation = HomepageTabBarPresentationPolicy.presentation(
      for: newTab,
      current: tabBarPresentation
  )
  ```

  Keep the existing Reflex view and its tab-bar transition unchanged.

- [ ] **Step 4: Add deterministic catalog coverage**

  In the existing CraftFloatingTabBar catalog section, render a second instance with the same `selectedTab`, items, center configuration, and `.glass` style but `presentation: .compact`. Reuse the existing catalog tab data and UI copy; do not add a new display string.

- [ ] **Step 5: Run the app target and review the diff**

  Call XcodeBuildMCP `test_sim` again after checking session defaults. Then run:

  ```bash
  git diff --check
  ```

  Expected: app tests pass, the Homepage compiles with the new callback, and the diff has no whitespace errors.

- [ ] **Step 6: Commit the application integration**

  Run `git status --short`. If no unrelated or generated project files exist, commit:

  ```bash
  git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
  git commit -m "feat(home): compact tab bar while learning path scrolls"
  ```

### Task 5: Run the complete quality gate and verify the interaction in Simulator

**Files:**

- Verify: files changed in Tasks 1 through 4

- [ ] **Step 1: Run CraftUIKit localization verification**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit --filter LocalizationTests
  ```

  Expected: all localization tests pass; no catalog changes were necessary because the feature adds no user-facing copy.

- [ ] **Step 2: Run all CraftUIKit tests**

  Run:

  ```bash
  swift test --package-path Packages/CraftUIKit
  ```

  Expected: all CraftUIKit tests pass with no compilation warnings.

- [ ] **Step 3: Run SwiftLint with warnings treated as failures**

  Run:

  ```bash
  swiftlint lint --config .swiftlint.yml --strict
  ```

  Expected: zero lint violations and zero warnings.

- [ ] **Step 4: Build and test the app with XcodeBuildMCP**

  Call XcodeBuildMCP `session_show_defaults`, then `test_sim` with `progress: true`, then `build_run_sim`. Expected: the app target and test target build with zero warnings, tests pass, and the app launches on the configured Simulator.

- [ ] **Step 5: Perform focused runtime interaction verification**

  Use XcodeBuildMCP `snapshot_ui` to locate the Home scroll view. Use `swipe` with `direction: "up"` and `distance: 0.7` inside that current scroll-view reference, wait for the UI to settle, and take a screenshot. Verify the glass capsule and FAB are compact while tab targets remain visible. Use `swipe` with `direction: "down"` and the same distance, wait for settlement, and take a second screenshot. Verify the full capsule and FAB restore once with no flicker. Also tap a tab before and after the two swipes to verify selection, haptic trigger path, and navigation remain operational.

- [ ] **Step 6: Inspect final repository state before reporting completion**

  Run:

  ```bash
  git status --short
  git diff --check
  git log --oneline -4
  ```

  Expected: the four intentional feature commits from Tasks 1 through 4 appear after the pre-existing documentation commits, with no Xcode-generated state files. If project metadata changed unexpectedly, do not stage it; report its path and reason before requesting a decision.
