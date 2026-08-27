import SwiftUI

// MARK: - Tab Item Protocol

/// Contract for navigation tab items used in `CraftFloatingTabBar`.
public protocol CraftTabItemProtocol: Identifiable, Equatable, Sendable where ID: Sendable & Hashable {
    var id: ID { get }
    var title: String { get }
    var symbol: String { get }
    var badgeCount: Int? { get }
    var titleKey: LocalizedStringKey? { get }
    var showsTitle: Bool { get }
    var showsSymbol: Bool { get }
}

public extension CraftTabItemProtocol {
    var badgeCount: Int? { nil }
    var titleKey: LocalizedStringKey? { nil }
    var showsTitle: Bool { true }
    var showsSymbol: Bool { true }
}

// MARK: - Standard Tab Item Model

/// Concrete convenience implementation of `CraftTabItemProtocol`.
public struct CraftTabItem: CraftTabItemProtocol {
    public let id: String
    public let title: String
    public let titleKey: LocalizedStringKey?
    public let symbol: String
    public let badgeCount: Int?
    public let showsTitle: Bool
    public let showsSymbol: Bool

    public init(
        id: String,
        title: String,
        symbol: String,
        badgeCount: Int? = nil,
        showsTitle: Bool = true,
        showsSymbol: Bool = true
    ) {
        self.id = id
        self.title = title
        self.titleKey = nil
        self.symbol = symbol
        self.badgeCount = badgeCount
        self.showsTitle = showsTitle
        self.showsSymbol = showsSymbol
    }

    public init(
        id: String,
        titleKey: LocalizedStringKey,
        symbol: String,
        badgeCount: Int? = nil,
        showsTitle: Bool = true,
        showsSymbol: Bool = true
    ) {
        self.id = id
        self.title = ""
        self.titleKey = titleKey
        self.symbol = symbol
        self.badgeCount = badgeCount
        self.showsTitle = showsTitle
        self.showsSymbol = showsSymbol
    }
}

// MARK: - Tactile FAB Button Style

/// Tactile 3D button style for floating action button in `CraftFloatingTabBar`.
public struct CraftTactileFABButtonStyle: ButtonStyle {
    public let depth: CGFloat
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(depth: CGFloat = 4) {
        self.depth = depth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let depressOffset = isPressed ? depth : 0

        configuration.label
            .offset(y: depressOffset)
            .background {
                Circle()
                    .fill(theme.colors.brandSecondary)
                    .offset(y: depth)
            }
            .padding(.bottom, depth)
            .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1.0)
            .animation(theme.animations.springSnappy, value: isPressed)
    }
}

// MARK: - Center Button Position

/// Placement mode for the optional center action button in `CraftFloatingTabBar`.
public enum CraftCenterButtonPosition: String, Sendable, CaseIterable {
    /// Sits inline aligned with navigation tabs inside the bar capsule.
    case inline
    /// Floats elevated protruding above the top edge of the bar capsule.
    case floating
}

// MARK: - Tab Bar Item Preference Key

/// Coordinate space tracking preference key reporting individual tab button bounds.
public struct CraftTabBarItemPreferenceKey: PreferenceKey {
    public static var defaultValue: [String: CGRect] = [:]
    public static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - CraftFloatingTabBar Component

/// A floating navigation bar featuring animated sliding tab indicators,
/// spring transitions, safe area handling, minimum 44pt touch targets, theme-driven surface styles,
/// and an integrated tactile / liquid glass action button.
public struct CraftFloatingTabBar<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @Binding public var selectedItem: Item
    public let items: [Item]
    public let style: CraftSurfaceStyle
    public let centerPosition: CraftCenterButtonPosition
    public let centerAction: (() -> Void)?
    public let centerSymbol: String
    private let centerTitleKey: LocalizedStringKey?
    private let rawCenterTitle: String?

    @State private var tabFrames: [String: CGRect] = [:]
    @State private var activeTransitionCount = 0

    // Pre-computed item partitions to avoid array allocations on every view body re-evaluation
    private let leadingItems: [Item]
    private let trailingItems: [Item]

    public var centerTitle: String? { rawCenterTitle }

    private var isTransitioning: Bool {
        activeTransitionCount > 0
    }

    private var selectedTabKey: String {
        String(describing: selectedItem.id)
    }

    private var selectedFrame: CGRect? {
        tabFrames[selectedTabKey]
    }

    public init(
        selectedItem: Binding<Item>,
        items: [Item],
        style: CraftSurfaceStyle = .glass,
        centerPosition: CraftCenterButtonPosition = .floating,
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitle: String? = nil
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.style = style
        self.centerPosition = centerPosition
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
        centerPosition: CraftCenterButtonPosition = .floating,
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitleKey: LocalizedStringKey
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.style = style
        self.centerPosition = centerPosition
        self.centerAction = centerAction
        self.centerSymbol = centerSymbol
        self.centerTitleKey = centerTitleKey
        self.rawCenterTitle = nil

        let mid = items.count / 2
        self.leadingItems = Array(items.prefix(mid))
        self.trailingItems = Array(items.suffix(from: mid))
    }

    public var body: some View {
        barContainer
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.xs)
            .accessibilityElement(children: .contain)
            .sensoryFeedback(.selection, trigger: selectedItem.id)
    }

    @ViewBuilder
    private var barContainer: some View {
        ZStack {
            if #available(iOS 26, macOS 26, *), style == .glass {
                GlassEffectContainer(spacing: 8) {
                    barContent
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .glassEffect(.regular, in: .capsule)
                }
            } else {
                barContent
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background {
                        tabBarLegacyBackground
                    }
                    .modifier(TabBarShadowModifier(style: style, theme: theme))
            }

            if let centerAction {
                CraftCenterActionButton(
                    symbol: centerSymbol,
                    titleKey: centerTitleKey,
                    title: rawCenterTitle,
                    style: style,
                    position: centerPosition,
                    action: centerAction
                )
                .zIndex(100)
            }
        }
    }

    @ViewBuilder
    private var barContent: some View {
        tabButtonsStack
            .background(alignment: .topLeading) {
                // Tier 2: Independent Sliding Fluid Glass Pill
                if let frame = selectedFrame {
                    CraftSlidingFluidPill(
                        style: style,
                        isTransitioning: isTransitioning
                    )
                    .frame(width: max(0, frame.width - 6), height: max(0, frame.height - 6), alignment: .center)
                    .offset(x: frame.minX + 3, y: frame.minY + 3)
                }
            }
            .coordinateSpace(name: "CraftTabBarTrack")
            .onPreferenceChange(CraftTabBarItemPreferenceKey.self) { preferences in
                tabFrames = preferences
            }
    }

    @ViewBuilder
    private var tabButtonsStack: some View {
        HStack(spacing: 2) {
            if centerAction != nil {
                ForEach(leadingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }

                Color.clear
                    .frame(width: centerPosition == .floating ? 60 : 46, height: 44)
                    .accessibilityHidden(true)

                ForEach(trailingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }
            } else {
                ForEach(items) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }
            }
        }
    }

    private func select(_ item: Item) {
        guard selectedItem.id != item.id else { return }
        if reduceMotion {
            selectedItem = item
        } else {
            activeTransitionCount += 1
            withAnimation(.spring(response: 0.35, dampingFraction: 0.76)) {
                selectedItem = item
            } completion: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    activeTransitionCount = max(0, activeTransitionCount - 1)
                }
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

// MARK: - Sliding Fluid Glass Pill View

/// Independent sliding fluid pill rendering Tier 2 optical liquid glass with squash/stretch spring kinematics.
public struct CraftSlidingFluidPill: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public let style: CraftSurfaceStyle
    public let isTransitioning: Bool

    public init(style: CraftSurfaceStyle = .glass, isTransitioning: Bool = false) {
        self.style = style
        self.isTransitioning = isTransitioning
    }

    public var body: some View {
        pillBackground
            .scaleEffect(
                x: (isTransitioning && !reduceMotion) ? 1.05 : 1.0,
                y: (isTransitioning && !reduceMotion) ? 0.96 : 1.0
            )
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.76), value: isTransitioning)
    }

    @ViewBuilder
    private var pillBackground: some View {
        switch style {
        case .glass:
            if reduceTransparency {
                Capsule()
                    .fill(theme.colors.surfaceCard)
                    .overlay(
                        Capsule()
                            .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                    )
            } else {
                glassPill
            }
        case .elevated:
            Capsule()
                .fill(theme.colors.surfaceElevated.opacity(0.92))
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        case .outlined:
            Capsule()
                .fill(theme.colors.surfaceCard)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                )
        case .tactile3D:
            Capsule()
                .fill(theme.colors.surfaceCard)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        case .flat:
            Capsule()
                .fill(theme.colors.surfaceCard)
        }
    }

    @ViewBuilder
    private var glassPill: some View {
        Capsule()
            .fill(
                Color.craftDynamic(
                    light: Color.white.opacity(0.85),
                    dark: Color.white.opacity(0.18)
                )
            )
            .overlay(specularRimHighlight)
            .shadow(
                color: Color.craftDynamic(
                    light: Color.black.opacity(0.08),
                    dark: Color.black.opacity(0.30)
                ),
                radius: 4,
                x: 0,
                y: 2
            )
    }

    private var specularRimHighlight: some View {
        Capsule()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.craftDynamic(light: Color.white.opacity(0.95), dark: Color.white.opacity(0.40)),
                        Color.craftDynamic(light: Color.white.opacity(0.30), dark: Color.white.opacity(0.10))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.8
            )
    }
}

// MARK: - Dedicated Tab Item Button Subview

/// Isolated tab button view enabling SwiftUI's Attribute Graph to bypass unaffected tabs during selection changes.
private struct CraftTabButton<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let item: Item
    let isSelected: Bool
    let barStyle: CraftSurfaceStyle
    let onSelect: () -> Void

    private var hasTitle: Bool {
        guard item.showsTitle else { return false }
        if item.titleKey != nil { return true }
        return !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: hasTitle ? 2 : 0) {
                ZStack(alignment: .topTrailing) {
                    if item.showsSymbol {
                        CraftIcon(
                            item.symbol,
                            size: hasTitle ? .md : .lg,
                            color: isSelected ? theme.colors.brandPrimary : theme.colors.textMuted,
                            renderingMode: isSelected ? .hierarchical : .monochrome,
                            weight: isSelected ? .bold : .medium
                        )
                        .scaleEffect(isSelected && !reduceMotion ? 1.08 : 1.0)
                        .symbolEffect(.bounce, value: isSelected)
                    }

                    if let badgeCount = item.badgeCount, badgeCount > 0 {
                        Text(verbatim: "\(min(badgeCount, 99))")
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

                if hasTitle {
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
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: CraftTabBarItemPreferenceKey.self,
                    value: [String(describing: item.id): proxy.frame(in: .named("CraftTabBarTrack"))]
                )
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(accessibilityBadgeValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    private var accessibilityTitle: Text {
        if let titleKey = item.titleKey {
            return Text(titleKey)
        } else if !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Text(item.title)
        } else {
            let readable = item.symbol.replacingOccurrences(of: ".", with: " ").capitalized
            return Text(readable)
        }
    }

    private var accessibilityBadgeValue: String {
        if let count = item.badgeCount, count > 0 {
            return CraftLocalized.format("craft.tab_bar.badge_count_format", count)
        }
        return ""
    }
}

// MARK: - Dedicated Center Action Button Subview

/// Isolated tactile / glass action button view located at the center of the tab bar.
private struct CraftCenterActionButton: View {
    @Environment(\.craftTheme) private var theme
    @State private var triggerHapticCount = 0

    let symbol: String
    let titleKey: LocalizedStringKey?
    let title: String?
    let style: CraftSurfaceStyle
    let position: CraftCenterButtonPosition
    let action: () -> Void

    private var circleDiameter: CGFloat {
        position == .floating ? 56 : 42
    }

    var body: some View {
        Group {
            if style == .glass {
                glassFAB
            } else {
                tactileFAB
            }
        }
        .offset(y: position == .floating ? -18 : 0)
        .zIndex(100)
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
                    .frame(width: circleDiameter, height: circleDiameter)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: position == .floating ? 1.5 : 1.2
                            )
                    )
                    .craftShadow(position == .floating ? theme.shadows.lg : theme.shadows.sm)

                CraftIcon(
                    symbol,
                    size: position == .floating ? .lg : .md,
                    color: theme.colors.textInverse,
                    renderingMode: .monochrome,
                    weight: .bold
                )
            }
            .frame(width: circleDiameter, height: circleDiameter)
            .contentShape(Circle())
        }
        .buttonStyle(.craftPress(scale: 0.93))
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
                    .frame(width: circleDiameter, height: circleDiameter)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.depths.topHighlight, lineWidth: position == .floating ? 1.8 : 1.5)
                    )

                CraftIcon(
                    symbol,
                    size: position == .floating ? .lg : .md,
                    color: theme.colors.textInverse,
                    renderingMode: .monochrome,
                    weight: .bold
                )
            }
            .frame(width: circleDiameter, height: circleDiameter)
            .contentShape(Circle())
        }
        .buttonStyle(CraftTactileFABButtonStyle(depth: position == .floating ? 4 : 3))
    }

    private var accessibilityTitle: Text {
        if let titleKey {
            return Text(titleKey)
        } else if let title, !title.isEmpty {
            return Text(title)
        } else {
            return Text(CraftLocalized.string("craft.tab_bar.center_action_fallback"))
        }
    }
}

private struct TabBarShadowModifier: ViewModifier {
    let style: CraftSurfaceStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        switch style {
        case .glass, .elevated:
            content.craftShadow(theme.shadows.lg)
        case .flat, .outlined, .tactile3D:
            content
        }
    }
}

private struct _PreviewTab: CraftTabItemProtocol {
    let id: String
    let title: String
    let symbol: String
    var showsTitle: Bool = true
}

#Preview("CraftFloatingTabBar - Glass & Icon-Only") {
    @Previewable @State var selected = _PreviewTab(id: "home", title: "Home", symbol: "house")
    @Previewable @State var selectedIconOnly = _PreviewTab(id: "learn", title: "Learn", symbol: "book.fill", showsTitle: false)

    let tabs = [
        _PreviewTab(id: "home", title: "Home", symbol: "house"),
        _PreviewTab(id: "search", title: "Search", symbol: "magnifyingglass"),
        _PreviewTab(id: "library", title: "Library", symbol: "books.vertical"),
        _PreviewTab(id: "profile", title: "Profile", symbol: "person")
    ]

    let iconOnlyTabs = [
        _PreviewTab(id: "learn", title: "Learn", symbol: "book.fill", showsTitle: false),
        _PreviewTab(id: "practice", title: "Practice", symbol: "repeat", showsTitle: false),
        _PreviewTab(id: "rank", title: "Rank", symbol: "trophy.fill", showsTitle: false),
        _PreviewTab(id: "account", title: "Account", symbol: "person.crop.circle", showsTitle: false)
    ]

    ScrollView {
        VStack(spacing: 36) {
            Text("Liquid Glass with Floating Protruding FAB")
                .font(.headline)

            CraftFloatingTabBar(
                selectedItem: $selected,
                items: tabs,
                style: .glass,
                centerPosition: .floating,
                centerAction: { },
                centerSymbol: "plus"
            )

            Text("Liquid Glass with Inline Center FAB")
                .font(.headline)

            CraftFloatingTabBar(
                selectedItem: $selected,
                items: tabs,
                style: .glass,
                centerPosition: .inline,
                centerAction: { },
                centerSymbol: "plus"
            )

            Text("Icon-Only Liquid Glass")
                .font(.headline)

            CraftFloatingTabBar(
                selectedItem: $selectedIconOnly,
                items: iconOnlyTabs,
                style: .glass,
                centerPosition: .floating,
                centerAction: { },
                centerSymbol: "sparkles"
            )

            Text("Tactile 3D Surface Style (Floating)")
                .font(.headline)

            CraftFloatingTabBar(
                selectedItem: $selected,
                items: tabs,
                style: .tactile3D,
                centerPosition: .floating,
                centerAction: { },
                centerSymbol: "plus"
            )
        }
        .padding(.vertical, 40)
    }
    .background(Color.gray.opacity(0.12).ignoresSafeArea())
}
