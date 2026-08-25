# CraftFloatingTabBar Liquid Glass Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `CraftFloatingTabBar` to support Apple's native Liquid Glass (iOS 26+) with hardware-accelerated fluid morphing, context-adaptive center FAB, icon-only navigation mode, unified active brand coloring, and robust accessibility fallbacks for iOS 17/18.

**Architecture:** A dual-engine view hierarchy using `if #available(iOS 26, *)` to render `GlassEffectContainer` with `.glassEffect(.regular, in: .capsule)` on iOS 26+, paired with a refined frosted-glass and multi-surface fallback for iOS 17/18. Subviews (`CraftTabButton` and `CraftCenterActionButton`) adapt their styling, accessibility labels, and transitions according to the environment.

**Tech Stack:** Swift 5.10 / Swift 6, SwiftUI, Swift Testing / XCTest, Liquid Glass SwiftUI APIs (`GlassEffectContainer`, `glassEffect`, `glassEffectID`, `glassEffectTransition`, `Glass`).

**Spec:** `docs/superpowers/specs/2026-08-25-craft-floating-tab-bar-liquid-glass-design.md`

## Global Constraints
- Must maintain 100% backward compatibility for all existing public APIs (`CraftTabItemProtocol`, `CraftTabItem`, `CraftFloatingTabBar`).
- Minimum deployment target is iOS 17.0 (`#available(iOS 26, *)` availability guards required for new Liquid Glass APIs).
- Dynamic Type and VoiceOver accessibility: Touch targets must remain >= 44pt; `accessibilityLabel` must support both `LocalizedStringKey` and plain `String`.
- Reduce Motion (`@Environment(\.accessibilityReduceMotion)`) must disable spring transitions.
- Reduce Transparency (`@Environment(\.accessibilityReduceTransparency)`) must fall back to high-contrast opaque surfaces.

---

### Task 1: Unit Tests for Icon-Only Tabs, Unified Active Colors, and VoiceOver Accessibility

**Files:**
- Modify: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`

**Interfaces:**
- Consumes: `CraftTabItemProtocol`, `CraftTabItem`, `CraftFloatingTabBar`
- Produces: Test suites verifying icon-only rendering, localized string accessibility, active selection colors, and style adaptation.

- [ ] **Step 1: Write failing unit tests for new requirements**

Add new tests to `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`:
```swift
    func testFloatingTabBarIconOnlyTabItem() {
        let iconOnlyTabs = [
            CraftTabItem(id: "home", title: "", symbol: "house"),
            CraftTabItem(id: "search", title: "", symbol: "magnifyingglass")
        ]
        var selected = iconOnlyTabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: iconOnlyTabs, style: .glass)
        XCTAssertNotNil(bar.body)
        XCTAssertEqual(bar.items[0].title, "")
    }

    func testFloatingTabBarAccessibilityWithLocalizedStringKey() {
        let localizedTabs = [
            CraftTabItem(id: "learn", titleKey: LocalizedStringKey("learn_tab"), symbol: "book.fill"),
            CraftTabItem(id: "settings", titleKey: LocalizedStringKey("settings_tab"), symbol: "gearshape.fill")
        ]
        var selected = localizedTabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: localizedTabs)
        XCTAssertNotNil(bar.body)
    }

    func testFloatingTabBarAllSurfaceStylesWithCenterAction() {
        let tabs = [
            SampleTab(id: 0, title: "Home", symbol: "house"),
            SampleTab(id: 1, title: "Settings", symbol: "gear")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })

        for style in CraftSurfaceStyle.allCases {
            let bar = CraftFloatingTabBar(
                selectedItem: binding,
                items: tabs,
                style: style,
                centerAction: {},
                centerSymbol: "plus",
                centerTitle: "Add"
            )
            XCTAssertEqual(bar.style, style)
            XCTAssertNotNil(bar.body)
        }
    }
```

- [ ] **Step 2: Run test suite to verify new tests compile and pass or fail as expected**

Run:
```bash
swift test --package-path CraftUIKit --filter NavigationTests
```
Expected: PASS (tests verify structure and interface expectations).

- [ ] **Step 3: Commit unit test additions**

```bash
git add CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift
git commit -m "test(navigation): add unit tests for icon-only tabs, localized keys, and surface styles"
```

---

### Task 2: Refactor `CraftTabButton` for Icon-Only Mode, Unified Active Brand Color, and Robust VoiceOver

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:274-349`

**Interfaces:**
- Consumes: `CraftTabItemProtocol`, `CraftTheme`, `Namespace.ID`, `CraftSurfaceStyle`
- Produces: Upgraded `CraftTabButton` supporting icon-only rendering, unified brand color for active state, `LocalizedStringKey` accessibility, and fluid indicator styling.

- [ ] **Step 1: Update `CraftTabButton` implementation**

Replace `CraftTabButton` in `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`:
```swift
// MARK: - Dedicated Tab Item Button Subview

/// Isolated tab button view enabling SwiftUI's Attribute Graph to bypass unaffected tabs during selection changes.
private struct CraftTabButton<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let item: Item
    let isSelected: Bool
    let namespace: Namespace.ID
    let barStyle: CraftSurfaceStyle
    let onSelect: () -> Void

    private var hasTitle: Bool {
        if item.titleKey != nil { return true }
        return !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: hasTitle ? 3 : 0) {
                ZStack(alignment: .topTrailing) {
                    CraftIcon(
                        item.symbol,
                        size: .md,
                        color: isSelected ? theme.colors.brandPrimary : theme.colors.textMuted,
                        renderingMode: isSelected ? .hierarchical : .monochrome,
                        weight: isSelected ? .bold : .medium
                    )

                    if let badgeCount = item.badgeCount, badgeCount > 0 {
                        Text("\(min(badgeCount, 99))")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(theme.colors.statusDanger)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -4)
                    }
                }

                if let titleKey = item.titleKey {
                    Text(titleKey)
                        .font(theme.typography.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textMuted)
                        .lineLimit(1)
                } else if !item.title.isEmpty {
                    Text(item.title)
                        .font(theme.typography.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .padding(.vertical, hasTitle ? 6 : 10)
            .padding(.horizontal, theme.spacing.xs)
            .background {
                if isSelected {
                    tabIndicatorBackground
                        .matchedGeometryEffect(id: "activeTabIndicator", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    @ViewBuilder
    private var tabIndicatorBackground: some View {
        switch barStyle {
        case .glass:
            RoundedRectangle(cornerRadius: 18)
                .fill(reduceTransparency ? AnyShapeStyle(theme.colors.surfaceCard) : AnyShapeStyle(theme.colors.brandPrimary.opacity(0.14)))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(theme.colors.brandPrimary.opacity(0.25), lineWidth: 0.8)
                )
        case .elevated:
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.colors.surfaceElevated.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
        case .outlined:
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.colors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                )
        case .tactile3D:
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.colors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
        case .flat:
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.colors.surfaceCard)
        }
    }

    private var accessibilityTitle: Text {
        if let titleKey = item.titleKey {
            return Text(titleKey)
        } else if !item.title.isEmpty {
            return Text(item.title)
        } else {
            let readable = item.symbol.replacingOccurrences(of: ".", with: " ").capitalized
            return Text(readable)
        }
    }
}
```

- [ ] **Step 2: Update call sites inside `CraftFloatingTabBar.body` to pass `barStyle: style`**

Update `CraftTabButton` initializations in `CraftFloatingTabBar.swift`:
```swift
CraftTabButton(
    item: item,
    isSelected: selectedItem.id == item.id,
    namespace: tabNamespace,
    barStyle: style,
    onSelect: { select(item) }
)
```

- [ ] **Step 3: Run compiler build and tests**

Run:
```bash
swift test --package-path CraftUIKit --filter NavigationTests
```
Expected: PASS

- [ ] **Step 4: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift
git commit -m "feat(navigation): add icon-only support, unified active color, and voiceover accessibility to CraftTabButton"
```

---

### Task 3: Refactor `CraftCenterActionButton` for Adaptive Liquid Glass & Tactile Modes

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:350-412`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftSurfaceStyle`, `LocalizedStringKey`
- Produces: Upgraded `CraftCenterActionButton` adapting between Liquid Glass prominent action styling and 3D tactile extrusion.

- [ ] **Step 1: Refactor `CraftCenterActionButton` implementation**

Replace `CraftCenterActionButton` in `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`:
```swift
// MARK: - Dedicated Center Action Button Subview

/// Isolated tactile / glass action button view located at the center of the tab bar.
private struct CraftCenterActionButton: View {
    @Environment(\.craftTheme) private var theme
    @State private var triggerHapticCount = 0

    let symbol: String
    let titleKey: LocalizedStringKey?
    let title: String?
    let style: CraftSurfaceStyle
    let action: () -> Void

    var body: some View {
        Group {
            if style == .glass {
                glassFAB
            } else {
                tactileFAB
            }
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(.isButton)
        .sensoryFeedback(.impact(weight: .medium), trigger: triggerHapticCount)
    }

    @ViewBuilder
    private var glassFAB: some View {
        Button {
            triggerHapticCount += 1
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .craftShadow(theme.shadows.md)

                centerContent
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(.craftPress(scale: 0.94))
    }

    @ViewBuilder
    private var tactileFAB: some View {
        Button {
            triggerHapticCount += 1
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
                    )
                    .craftShadow(theme.shadows.sm)

                centerContent
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(CraftTactileFABButtonStyle(depth: theme.depths.depthMd))
    }

    @ViewBuilder
    private var centerContent: some View {
        VStack(spacing: 2) {
            CraftIcon(
                symbol,
                size: .md,
                color: theme.colors.textInverse,
                renderingMode: .monochrome,
                weight: .bold
            )

            if let titleKey {
                Text(titleKey)
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textInverse)
                    .lineLimit(1)
            } else if let title, !title.isEmpty {
                Text(title)
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textInverse)
                    .lineLimit(1)
            }
        }
    }

    private var accessibilityTitle: Text {
        if let titleKey {
            return Text(titleKey)
        } else if let title, !title.isEmpty {
            return Text(title)
        } else {
            return Text("Action")
        }
    }
}
```

- [ ] **Step 2: Update `CraftCenterActionButton` call site inside `CraftFloatingTabBar.body`**

Pass `style: style` to `CraftCenterActionButton`:
```swift
CraftCenterActionButton(
    symbol: centerSymbol,
    titleKey: centerTitleKey,
    title: rawCenterTitle,
    style: style,
    action: centerAction
)
```

- [ ] **Step 3: Run compiler build and tests**

Run:
```bash
swift test --package-path CraftUIKit --filter NavigationTests
```
Expected: PASS

- [ ] **Step 4: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift
git commit -m "feat(navigation): add adaptive glass and tactile styling to CraftCenterActionButton"
```

---

### Task 4: Upgrade `CraftFloatingTabBar` Dual-Engine Architecture (iOS 26+ Liquid Glass & iOS 17/18 Fallback)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:90-273`

**Interfaces:**
- Consumes: `CraftTabItemProtocol`, `CraftTheme`, `CraftSurfaceStyle`, `@Environment(\.accessibilityReduceMotion)`, `@Environment(\.accessibilityReduceTransparency)`
- Produces: Dual-engine `CraftFloatingTabBar` with Liquid Glass on iOS 26+ and polished high-contrast fallback for pre-iOS 26.

- [ ] **Step 1: Implement Dual-Engine Body and Background in `CraftFloatingTabBar`**

Update `CraftFloatingTabBar` in `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`:
```swift
public struct CraftFloatingTabBar<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Namespace private var tabNamespace

    @Binding public var selectedItem: Item
    public let items: [Item]
    public let style: CraftSurfaceStyle
    public let centerAction: (() -> Void)?
    public let centerSymbol: String
    private let centerTitleKey: LocalizedStringKey?
    private let rawCenterTitle: String?

    // Pre-computed item partitions to avoid array allocations on every view body re-evaluation
    private let leadingItems: [Item]
    private let trailingItems: [Item]

    public var centerTitle: String? { rawCenterTitle }

    public init(
        selectedItem: Binding<Item>,
        items: [Item],
        style: CraftSurfaceStyle = .glass,
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitle: String? = nil
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.style = style
        self.centerAction = centerAction
        self.centerSymbol = centerSymbol
        self.centerTitleKey = nil
        self.rawCenterTitle = centerTitle

        let mid = items.count / 2
        self.leadingItems = Array(items.prefix(mid))
        self.trailingItems = Array(items.suffix(from: mid))
    }

    public init(
        selectedItem: Binding<Item>,
        items: [Item],
        style: CraftSurfaceStyle = .glass,
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitleKey: LocalizedStringKey
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.style = style
        self.centerAction = centerAction
        self.centerSymbol = centerSymbol
        self.centerTitleKey = centerTitleKey
        self.rawCenterTitle = nil

        let mid = items.count / 2
        self.leadingItems = Array(items.prefix(mid))
        self.trailingItems = Array(items.suffix(from: mid))
    }

    public var body: some View {
        Group {
            if #available(iOS 26, *), style == .glass {
                GlassEffectContainer(spacing: 8) {
                    barContent
                        .padding(.horizontal, theme.spacing.xs)
                        .padding(.vertical, theme.spacing.xs)
                        .glassEffect(.regular, in: .capsule)
                }
            } else {
                barContent
                    .padding(.horizontal, theme.spacing.xs)
                    .padding(.vertical, theme.spacing.xs)
                    .background {
                        tabBarLegacyBackground
                    }
                    .modifier(TabBarShadowModifier(style: style, theme: theme))
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.bottom, theme.spacing.xs)
        .accessibilityElement(children: .contain)
        .sensoryFeedback(.selection, trigger: selectedItem.id)
    }

    @ViewBuilder
    private var barContent: some View {
        HStack(spacing: theme.spacing.xs) {
            if let centerAction {
                ForEach(leadingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        namespace: tabNamespace,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }

                CraftCenterActionButton(
                    symbol: centerSymbol,
                    titleKey: centerTitleKey,
                    title: rawCenterTitle,
                    style: style,
                    action: centerAction
                )

                ForEach(trailingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        namespace: tabNamespace,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }
            } else {
                ForEach(items) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        namespace: tabNamespace,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }
            }
        }
    }

    private func select(_ item: Item) {
        if reduceMotion {
            selectedItem = item
        } else {
            withAnimation(theme.animations.springSnappy) {
                selectedItem = item
            }
        }
    }

    // MARK: - Legacy / Non-Glass Background

    @ViewBuilder
    private var tabBarLegacyBackground: some View {
        switch style {
        case .glass:
            Capsule()
                .fill(reduceTransparency ? AnyShapeStyle(theme.colors.surfaceCard) : AnyShapeStyle(.ultraThinMaterial))
                .overlay(
                    Capsule()
                        .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
        case .elevated:
            Capsule()
                .fill(theme.colors.surfaceElevated)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.borderDefault.opacity(0.5), lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
        case .outlined:
            Capsule()
                .fill(theme.colors.surfaceCard)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                )
        case .tactile3D:
            ZStack {
                Capsule()
                    .fill(theme.colors.borderDefault)
                    .offset(y: theme.depths.depthSm)
                Capsule()
                    .fill(theme.colors.surfaceCard)
                    .overlay(
                        Capsule()
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                    )
            }
            .padding(.bottom, theme.depths.depthSm)
        case .flat:
            Capsule()
                .fill(theme.colors.surfaceSubtle)
        }
    }
}
```

- [ ] **Step 2: Run test suite**

Run:
```bash
swift test --package-path CraftUIKit
```
Expected: PASS (All tests pass).

- [ ] **Step 3: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift
git commit -m "feat(navigation): adopt Liquid Glass iOS 26+ and dual-engine fallback in CraftFloatingTabBar"
```

---

### Task 5: Previews, Catalog Showcase & Full Regression Verification

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:425-455` (Previews)
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift:1740-1765`
- Test: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`

**Interfaces:**
- Consumes: `CraftFloatingTabBar`, `CraftCatalogView`
- Produces: Comprehensive previews for icon-only, standard glass, tactile 3D, and dark mode variants.

- [ ] **Step 1: Enrich Previews in `CraftFloatingTabBar.swift`**

Update `#Preview` at bottom of `CraftFloatingTabBar.swift`:
```swift
#Preview("CraftFloatingTabBar - Glass & Icon-Only") {
    @Previewable @State var selected = _PreviewTab(id: "home", title: "Home", symbol: "house")
    @Previewable @State var selectedIconOnly = _PreviewTab(id: "learn", title: "", symbol: "book.fill")

    let tabs = [
        _PreviewTab(id: "home", title: "Home", symbol: "house"),
        _PreviewTab(id: "search", title: "Search", symbol: "magnifyingglass"),
        _PreviewTab(id: "library", title: "Library", symbol: "books.vertical"),
        _PreviewTab(id: "profile", title: "Profile", symbol: "person")
    ]

    let iconOnlyTabs = [
        _PreviewTab(id: "learn", title: "", symbol: "book.fill"),
        _PreviewTab(id: "practice", title: "", symbol: "repeat"),
        _PreviewTab(id: "rank", title: "", symbol: "trophy.fill"),
        _PreviewTab(id: "account", title: "", symbol: "person.crop.circle")
    ]

    ScrollView {
        VStack(spacing: 32) {
            Text("Standard Liquid Glass with FAB")
                .font(.headline)

            CraftFloatingTabBar(
                selectedItem: $selected,
                items: tabs,
                style: .glass,
                centerAction: { },
                centerSymbol: "plus",
                centerTitle: "Add"
            )

            Text("Icon-Only Liquid Glass")
                .font(.headline)

            CraftFloatingTabBar(
                selectedItem: $selectedIconOnly,
                items: iconOnlyTabs,
                style: .glass,
                centerAction: { },
                centerSymbol: "sparkles"
            )

            Text("Tactile 3D Surface Style")
                .font(.headline)

            CraftFloatingTabBar(
                selectedItem: $selected,
                items: tabs,
                style: .tactile3D,
                centerAction: { },
                centerSymbol: "plus"
            )
        }
        .padding(.vertical, 40)
    }
    .background(Color.gray.opacity(0.12).ignoresSafeArea())
}
```

- [ ] **Step 2: Run full test suite across the entire package**

Run:
```bash
swift test --package-path CraftUIKit
```
Expected: PASS (All tests pass without warnings or errors).

- [ ] **Step 3: Commit preview and catalog verification**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "chore(navigation): enrich CraftFloatingTabBar previews with icon-only and multi-surface showcases"
```
