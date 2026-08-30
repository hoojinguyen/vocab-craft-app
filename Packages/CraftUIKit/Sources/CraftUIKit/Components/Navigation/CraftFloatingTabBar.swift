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
public struct CraftTabItem: @unchecked Sendable, CraftTabItemProtocol {
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

// MARK: - Tab Bar Size Tier

/// Sizing tiers for `CraftFloatingTabBar`.
public enum CraftTabBarSize: String, Sendable, CaseIterable {
    /// Compact mode for minimal footprint (bar height: 44pt, FAB: 50pt).
    case sm
    /// Standard regular mode (bar height: 52pt, FAB: 58pt).
    case md
    /// Prominent spacious mode (bar height: 60pt, FAB: 66pt).
    case lg

    /// Total height of each tab touch button.
    public var barHeight: CGFloat {
        switch self {
        case .sm: return 44
        case .md: return 52
        case .lg: return 60
        }
    }

    /// Icon point size for tab buttons.
    public var iconSize: CraftIconSize {
        switch self {
        case .sm: return .md
        case .md: return .lg
        case .lg: return .lg
        }
    }

    /// Outer container horizontal padding.
    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 6
        case .md: return 8
        case .lg: return 10
        }
    }

    /// Outer container vertical padding.
    public var verticalPadding: CGFloat {
        switch self {
        case .sm: return 4
        case .md: return 5
        case .lg: return 6
        }
    }

    /// Inset applied to sliding fluid pill (`dx`, `dy`).
    public var pillInset: CGFloat {
        switch self {
        case .sm: return 3
        case .md: return 4
        case .lg: return 5
        }
    }

    /// Diameter of center floating action button.
    public func centerButtonDiameter(position: CraftCenterButtonPosition) -> CGFloat {
        switch (self, position) {
        case (.sm, .floating): return 50
        case (.sm, .inline): return 38
        case (.md, .floating): return 58
        case (.md, .inline): return 44
        case (.lg, .floating): return 66
        case (.lg, .inline): return 50
        }
    }

    /// Reserved spacer width between leading and trailing items.
    public func centerSpacerWidth(position: CraftCenterButtonPosition) -> CGFloat {
        switch (self, position) {
        case (.sm, .floating): return 56
        case (.sm, .inline): return 42
        case (.md, .floating): return 66
        case (.md, .inline): return 50
        case (.lg, .floating): return 76
        case (.lg, .inline): return 58
        }
    }

    /// Vertical protrusion offset for floating center button.
    public func centerFloatingOffset(position: CraftCenterButtonPosition) -> CGFloat {
        guard position == .floating else { return 0 }
        switch self {
        case .sm: return -16
        case .md: return -20
        case .lg: return -24
        }
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

/// Presentation states for scroll-responsive tab bar content.
public enum CraftTabBarPresentation: String, Sendable, Equatable, CaseIterable {
    case expanded
    case compact
}

// MARK: - Tab Bar Item Preference Key

/// Legacy preference key retained for source compatibility with clients that inspect tab bounds.
public struct CraftTabBarItemPreferenceKey: PreferenceKey {
    public static var defaultValue: [String: CGRect] = [:]
    public static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Keeps selection motion local to the tab bar and honors the system Reduce Motion setting.
enum CraftTabBarAnimationPolicy {
    static func selectionAnimation(
        reduceMotion: Bool,
        animations: CraftAnimationTokens
    ) -> Animation? {
        reduceMotion ? nil : animations.springSmooth
    }

    static func presentationAnimation(
        reduceMotion: Bool,
        animations: CraftAnimationTokens
    ) -> Animation? {
        reduceMotion ? nil : animations.springGentle
    }
}

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

// MARK: - CraftFloatingTabBar Component

/// A floating navigation bar featuring animated sliding tab indicators,
/// spring transitions, safe area handling, minimum 44pt touch targets, theme-driven surface styles,
/// configurable size tiers (`.sm`, `.md`, `.lg`), and an integrated tactile / liquid glass action button.
public struct CraftFloatingTabBar<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @Binding public var selectedItem: Item
    public let items: [Item]
    public let style: CraftSurfaceStyle
    public let size: CraftTabBarSize
    public let presentation: CraftTabBarPresentation
    public let centerPosition: CraftCenterButtonPosition
    public let centerAction: (() -> Void)?
    public let centerSymbol: String
    private let centerTitleKey: LocalizedStringKey?
    private let rawCenterTitle: String?

    @Namespace private var selectionNamespace
    @Namespace private var glassNamespace

    // Pre-computed item partitions to avoid array allocations on every view body re-evaluation
    private let leadingItems: [Item]
    private let trailingItems: [Item]

    public var centerTitle: String? { rawCenterTitle }

    static func usesNativeGlass(
        style: CraftSurfaceStyle,
        reduceTransparency: Bool
    ) -> Bool {
        style == .glass && !reduceTransparency
    }

    var resolvedSize: CraftTabBarSize {
        presentation == .compact ? .sm : size
    }

    var centerActionHitTargetDiameter: CGFloat {
        max(
            CraftTabBarSize.sm.barHeight,
            resolvedSize.centerButtonDiameter(position: centerPosition)
        )
    }

    public init(
        selectedItem: Binding<Item>,
        items: [Item],
        style: CraftSurfaceStyle = .glass,
        size: CraftTabBarSize = .md,
        presentation: CraftTabBarPresentation = .expanded,
        centerPosition: CraftCenterButtonPosition = .floating,
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitle: String? = nil
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.style = style
        self.size = size
        self.presentation = presentation
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
        size: CraftTabBarSize = .md,
        presentation: CraftTabBarPresentation = .expanded,
        centerPosition: CraftCenterButtonPosition = .floating,
        centerAction: (() -> Void)? = nil,
        centerSymbol: String = "plus",
        centerTitleKey: LocalizedStringKey
    ) {
        self._selectedItem = selectedItem
        self.items = items
        self.style = style
        self.size = size
        self.presentation = presentation
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
        if #available(iOS 26, macOS 26, *), Self.usesNativeGlass(
            style: style,
            reduceTransparency: reduceTransparency
        ) {
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
                        .animation(
                            CraftTabBarAnimationPolicy.presentationAnimation(
                                reduceMotion: reduceMotion,
                                animations: theme.animations
                            ),
                            value: presentation
                        )

                    if let centerAction {
                        CraftCenterActionButton(
                            symbol: centerSymbol,
                            titleKey: centerTitleKey,
                            title: rawCenterTitle,
                            style: style,
                            resolvedSize: resolvedSize,
                            position: centerPosition,
                            hitTargetDiameter: centerActionHitTargetDiameter,
                            glassNamespace: glassNamespace,
                            action: centerAction
                        )
                        .zIndex(100)
                        .animation(
                            CraftTabBarAnimationPolicy.presentationAnimation(
                                reduceMotion: reduceMotion,
                                animations: theme.animations
                            ),
                            value: presentation
                        )
                    }
                }
            }
        } else {
            ZStack {
                barContent
                    .padding(.horizontal, resolvedSize.horizontalPadding)
                    .padding(.vertical, resolvedSize.verticalPadding)
                    .background {
                        tabBarLegacyBackground
                    }
                    .modifier(TabBarShadowModifier(style: style, theme: theme))
                    .animation(
                        CraftTabBarAnimationPolicy.presentationAnimation(
                            reduceMotion: reduceMotion,
                            animations: theme.animations
                        ),
                        value: presentation
                    )

                if let centerAction {
                    CraftCenterActionButton(
                        symbol: centerSymbol,
                        titleKey: centerTitleKey,
                        title: rawCenterTitle,
                        style: style,
                        resolvedSize: resolvedSize,
                        position: centerPosition,
                        hitTargetDiameter: centerActionHitTargetDiameter,
                        glassNamespace: glassNamespace,
                        action: centerAction
                    )
                    .zIndex(100)
                    .animation(
                        CraftTabBarAnimationPolicy.presentationAnimation(
                            reduceMotion: reduceMotion,
                            animations: theme.animations
                        ),
                        value: presentation
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var barContent: some View {
        tabButtonsStack
            .animation(
                CraftTabBarAnimationPolicy.selectionAnimation(
                    reduceMotion: reduceMotion,
                    animations: theme.animations
                ),
                value: selectedItem.id
            )
    }

    @ViewBuilder
    private var tabButtonsStack: some View {
        HStack(spacing: theme.spacing.xs) {
            if centerAction != nil {
                ForEach(leadingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        resolvedSize: resolvedSize,
                        selectionNamespace: selectionNamespace,
                        glassNamespace: glassNamespace,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }

                Color.clear
                    .frame(
                        width: resolvedSize.centerSpacerWidth(position: centerPosition),
                        height: resolvedSize.barHeight
                    )
                    .accessibilityHidden(true)

                ForEach(trailingItems) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        resolvedSize: resolvedSize,
                        selectionNamespace: selectionNamespace,
                        glassNamespace: glassNamespace,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }
            } else {
                ForEach(items) { item in
                    CraftTabButton(
                        item: item,
                        isSelected: selectedItem.id == item.id,
                        resolvedSize: resolvedSize,
                        selectionNamespace: selectionNamespace,
                        glassNamespace: glassNamespace,
                        barStyle: style,
                        onSelect: { select(item) }
                    )
                }
            }
        }
    }

    private func select(_ item: Item) {
        guard selectedItem.id != item.id else { return }
        // The scoped animation on `barContent` animates only the indicator and tab visuals.
        // Keeping the binding mutation non-animated prevents the host screen from inheriting
        // the tab bar's spring transaction during a potentially expensive tab switch.
        selectedItem = item
    }

    // MARK: - Legacy / Non-Glass Background

    @ViewBuilder
    private var tabBarLegacyBackground: some View {
        switch style {
        case .glass:
            Capsule()
                .fill(reduceTransparency ? AnyShapeStyle(theme.colors.surfaceElevated) : AnyShapeStyle(.ultraThinMaterial))
                .overlay {
                    Capsule()
                        .fill(theme.colors.surfaceCard.opacity(theme.opacities.subtle))
                }
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
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
                        .strokeBorder(theme.colors.borderDefault.opacity(theme.opacities.medium), lineWidth: 1)
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
                    .fill(theme.colors.surfaceElevated)
                    .overlay(
                        Capsule()
                            .strokeBorder(theme.colors.borderFocus, lineWidth: 1)
                    )
            } else if #available(iOS 26, macOS 26, *) {
                Capsule()
                    .fill(theme.colors.surfaceElevated)
                    .glassEffect(
                        .regular.tint(theme.colors.brandPrimary.opacity(theme.glass.tintOpacity)),
                        in: .capsule
                    )
            } else {
                glassPill
            }
        case .elevated:
            Capsule()
                .fill(theme.colors.surfaceElevated)
                .overlay {
                    Capsule()
                        .fill(theme.colors.brandPrimary.opacity(theme.opacities.subtle))
                }
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
                .craftShadow(theme.shadows.sm)
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
                .overlay {
                    Capsule()
                        .fill(theme.colors.brandPrimary.opacity(theme.opacities.subtle))
                }
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                )
                .craftShadow(theme.shadows.sm)
        case .flat:
            Capsule()
                .fill(theme.colors.surfaceCard)
        }
    }

    @ViewBuilder
    private var glassPill: some View {
        Capsule()
            .fill(theme.colors.surfaceElevated)
            .overlay {
                Capsule()
                    .fill(theme.colors.brandPrimary.opacity(theme.opacities.muted))
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        theme.colors.brandPrimary.opacity(theme.opacities.medium),
                        lineWidth: 1
                    )
            }
            .craftShadow(theme.shadows.sm)
    }
}

// MARK: - Dedicated Tab Item Button Subview

/// Isolated tab button view enabling SwiftUI's Attribute Graph to bypass unaffected tabs during selection changes.
private struct CraftTabButton<Item: CraftTabItemProtocol>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let item: Item
    let isSelected: Bool
    let resolvedSize: CraftTabBarSize
    let selectionNamespace: Namespace.ID
    let glassNamespace: Namespace.ID
    let barStyle: CraftSurfaceStyle
    let onSelect: () -> Void

    private var hasTitle: Bool {
        guard item.showsTitle else { return false }
        if item.titleKey != nil { return true }
        return !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var iconSize: CraftIconSize {
        if hasTitle {
            return resolvedSize == .lg ? .md : .sm
        } else {
            return resolvedSize.iconSize
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: hasTitle ? 2 : 0) {
                ZStack(alignment: .topTrailing) {
                    if item.showsSymbol {
                        CraftIcon(
                            item.symbol,
                            size: iconSize,
                            color: isSelected ? theme.colors.brandPrimary : theme.colors.textSecondary,
                            renderingMode: isSelected ? .hierarchical : .monochrome,
                            weight: isSelected ? .bold : .medium
                        )
                        .scaleEffect(isSelected && !reduceMotion ? 1.08 : 1.0)
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
                            .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textSecondary)
                            .lineLimit(1)
                    } else if !item.title.isEmpty {
                        Text(item.title)
                            .font(theme.typography.caption)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: resolvedSize.barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: 0.95))
        .background {
            if isSelected {
                selectionLens
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(accessibilityBadgeValue)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    @ViewBuilder
    private var selectionLens: some View {
        if #available(iOS 26, macOS 26, *), barStyle == .glass, !reduceTransparency {
            CraftSlidingFluidPill(style: barStyle)
                .matchedGeometryEffect(
                    id: "CraftFloatingTabBar.selectedPill",
                    in: selectionNamespace
                )
                .padding(resolvedSize.pillInset)
                .glassEffectID("craft.tab_bar.selection_lens", in: glassNamespace)
        } else {
            CraftSlidingFluidPill(style: barStyle)
                .matchedGeometryEffect(
                    id: "CraftFloatingTabBar.selectedPill",
                    in: selectionNamespace
                )
                .padding(resolvedSize.pillInset)
        }
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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var triggerHapticCount = 0

    let symbol: String
    let titleKey: LocalizedStringKey?
    let title: String?
    let style: CraftSurfaceStyle
    let resolvedSize: CraftTabBarSize
    let position: CraftCenterButtonPosition
    let hitTargetDiameter: CGFloat
    let glassNamespace: Namespace.ID
    let action: () -> Void

    private var circleDiameter: CGFloat {
        resolvedSize.centerButtonDiameter(position: position)
    }

    private var iconSize: CraftIconSize {
        switch (resolvedSize, position) {
        case (.sm, .floating): return .md
        case (.sm, .inline): return .sm
        case (.md, .floating): return .lg
        case (.md, .inline): return .md
        case (.lg, .floating): return .xl
        case (.lg, .inline): return .lg
        }
    }

    var body: some View {
        Group {
            if style == .glass {
                glassFAB
            } else {
                tactileFAB
            }
        }
        .offset(y: resolvedSize.centerFloatingOffset(position: position))
        .zIndex(100)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(.isButton)
        .sensoryFeedback(.impact(weight: .medium), trigger: triggerHapticCount)
    }

    @ViewBuilder
    private var glassFAB: some View {
        if #available(iOS 26, macOS 26, *), !reduceTransparency {
            Button {
                triggerHapticCount += 1
                action()
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.gradients.brandHero)

                    CraftIcon(
                        symbol,
                        size: iconSize,
                        color: theme.colors.textInverse,
                        renderingMode: .monochrome,
                        weight: .bold
                    )
                }
                .frame(width: circleDiameter, height: circleDiameter)
                .glassEffect(
                    .regular.tint(
                        theme.colors.brandPrimary.opacity(theme.glass.tintOpacity)
                    ).interactive(),
                    in: .circle
                )
                .glassEffectID("craft.tab_bar.center_action", in: glassNamespace)
                .frame(width: hitTargetDiameter, height: hitTargetDiameter)
                .contentShape(Circle())
            }
            .buttonStyle(.craftPress(scale: 0.93))
        } else {
            legacyGlassFAB
        }
    }

    private var legacyGlassFAB: some View {
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
                            .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                    )
                    .craftShadow(position == .floating ? theme.shadows.lg : theme.shadows.sm)

                CraftIcon(
                    symbol,
                    size: iconSize,
                    color: theme.colors.textInverse,
                    renderingMode: .monochrome,
                    weight: .bold
                )
            }
            .frame(width: hitTargetDiameter, height: hitTargetDiameter)
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
                    size: iconSize,
                    color: theme.colors.textInverse,
                    renderingMode: .monochrome,
                    weight: .bold
                )
            }
            .frame(width: hitTargetDiameter, height: hitTargetDiameter)
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

#if canImport(PreviewsMacros)
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
#endif
