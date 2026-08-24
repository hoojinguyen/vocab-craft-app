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

// MARK: - CraftFloatingTabBar Component

/// A floating navigation bar featuring animated sliding tab indicators,
/// spring transitions, safe area handling, minimum 44pt touch targets, theme-driven surface styles,
/// and an integrated tactile action button.
public struct CraftFloatingTabBar<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
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
        HStack(spacing: theme.spacing.xs) {
            if let centerAction {
                ForEach(leadingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        namespace: tabNamespace,
                        onSelect: { select(item) }
                    )
                }

                CraftCenterActionButton(
                    symbol: centerSymbol,
                    titleKey: centerTitleKey,
                    title: rawCenterTitle,
                    action: centerAction
                )

                ForEach(trailingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        namespace: tabNamespace,
                        onSelect: { select(item) }
                    )
                }
            } else {
                ForEach(items) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        namespace: tabNamespace,
                        onSelect: { select(item) }
                    )
                }
            }
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xs)
        .background {
            tabBarBackground
        }
        .modifier(TabBarShadowModifier(style: style, theme: theme))
        .padding(.horizontal, theme.spacing.base)
        .padding(.bottom, theme.spacing.sm)
        .accessibilityElement(children: .contain)
        .sensoryFeedback(.selection, trigger: selectedItem.id)
    }

    private func select(_ item: Item) {
        withAnimation(theme.animations.springSnappy) {
            selectedItem = item
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var tabBarBackground: some View {
        switch style {
        case .glass:
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
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

    let item: Item
    let isSelected: Bool
    let namespace: Namespace.ID
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 3) {
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
                        .lineLimit(1)
                } else {
                    Text(item.title)
                        .font(theme.typography.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .lineLimit(1)
                }
            }
            .foregroundColor(isSelected ? theme.colors.textPrimary : theme.colors.textMuted)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .padding(.vertical, 6)
            .padding(.horizontal, theme.spacing.xs)
            .background {
                if isSelected {
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
                        .matchedGeometryEffect(id: "activeTabIndicator", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

// MARK: - Dedicated Center Action Button Subview

/// Isolated tactile action button view located at the center of the tab bar.
private struct CraftCenterActionButton: View {
    @Environment(\.craftTheme) private var theme
    @State private var triggerHapticCount = 0

    let symbol: String
    let titleKey: LocalizedStringKey?
    let title: String?
    let action: () -> Void

    var body: some View {
        Button {
            triggerHapticCount += 1
            action()
        } label: {
            ZStack {
                // Top Surface Disc with Brand Hero Gradient & Top Highlight Stroke
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
                    )
                    .craftShadow(theme.shadows.sm)

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
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(CraftTactileFABButtonStyle(depth: theme.depths.depthMd))
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(title ?? "Action")
        .accessibilityAddTraits(.isButton)
        .sensoryFeedback(.impact(weight: .medium), trigger: triggerHapticCount)
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

#Preview("CraftFloatingTabBar") {
    @Previewable @State var selected = _PreviewTab(id: "home", title: "Home", symbol: "house")

    let tabs = [
        _PreviewTab(id: "home", title: "Home", symbol: "house"),
        _PreviewTab(id: "search", title: "Search", symbol: "magnifyingglass"),
        _PreviewTab(id: "library", title: "Library", symbol: "books.vertical"),
        _PreviewTab(id: "profile", title: "Profile", symbol: "person")
    ]

    ZStack(alignment: .bottom) {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        CraftFloatingTabBar(
            selectedItem: $selected,
            items: tabs,
            style: .glass,
            centerAction: { },
            centerSymbol: "plus"
        )
    }
}
