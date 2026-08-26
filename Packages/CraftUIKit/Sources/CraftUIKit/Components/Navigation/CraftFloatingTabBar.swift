import SwiftUI

// MARK: - Tab Item Protocol

/// Contract for navigation tab items used in `CraftFloatingTabBar`.
public protocol CraftTabItemProtocol: Identifiable, Equatable, Sendable where ID: Sendable & Hashable {
    var id: ID { get }
    var title: String { get }
    var symbol: String { get }
    var badgeCount: Int? { get }
    var titleKey: LocalizedStringKey? { get }
}

public extension CraftTabItemProtocol {
    var badgeCount: Int? {
        nil
    }
    var titleKey: LocalizedStringKey? {
        nil
    }
}

// MARK: - Standard Tab Item Model

/// Concrete convenience implementation of `CraftTabItemProtocol`.
public struct CraftTabItem: CraftTabItemProtocol {
    public let id: String
    public let title: String
    public let titleKey: LocalizedStringKey?
    public let symbol: String
    public let badgeCount: Int?

    public init(
        id: String,
        title: String,
        symbol: String,
        badgeCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.titleKey = nil
        self.symbol = symbol
        self.badgeCount = badgeCount
    }

    public init(
        id: String,
        titleKey: LocalizedStringKey,
        symbol: String,
        badgeCount: Int? = nil
    ) {
        self.id = id
        self.title = ""
        self.titleKey = titleKey
        self.symbol = symbol
        self.badgeCount = badgeCount
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

// MARK: - CraftFloatingTabBar Component

/// A floating navigation bar featuring animated sliding tab indicators,
/// spring transitions, safe area handling, minimum 44pt touch targets, theme-driven surface styles,
/// and an integrated tactile / liquid glass action button.
public struct CraftFloatingTabBar<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Namespace private var tabNamespace

    @Binding public var selectedItem: Item
    public let items: [Item]
    public let style: CraftSurfaceStyle
    public let centerPosition: CraftCenterButtonPosition
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
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .glassEffect(.regular, in: .capsule)
                }
            } else {
                barContent
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
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
        HStack(spacing: theme.spacing.xs) {
            if centerAction != nil {
                ForEach(leadingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        namespace: tabNamespace,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }

                Color.clear
                    .frame(width: centerPosition == .floating ? 56 : 42, height: 44)
                    .accessibilityHidden(true)

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
            VStack(spacing: hasTitle ? 2 : 0) {
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
                } else if hasTitle {
                    Text(item.title)
                        .font(theme.typography.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
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
        .accessibilityValue(accessibilityBadgeValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    @ViewBuilder
    private var tabIndicatorBackground: some View {
        switch barStyle {
        case .glass:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(reduceTransparency ? AnyShapeStyle(theme.colors.surfaceCard) : AnyShapeStyle(theme.colors.brandPrimary.opacity(0.14)))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.colors.brandPrimary.opacity(0.25), lineWidth: 0.8)
                )
        case .elevated:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.colors.surfaceElevated.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
        case .outlined:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.colors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                )
        case .tactile3D:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.colors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
        case .flat:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.colors.surfaceCard)
        }
    }

    private var accessibilityTitle: Text {
        if let titleKey = item.titleKey {
            return Text(titleKey)
        } else if hasTitle {
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
}

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
