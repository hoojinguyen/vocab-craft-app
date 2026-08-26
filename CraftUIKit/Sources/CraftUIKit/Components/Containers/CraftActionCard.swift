import SwiftUI

// MARK: - CraftActionCard Component

/// A versatile, theme-driven Bento Action Card component designed for mode selection,
/// practice launchers, and dashboard navigation.
///
/// Supports all 5 `CraftSurfaceStyle` variants (`.outlined`, `.tactile3D`, `.glass`, `.elevated`, `.flat`),
/// tactile 3D physical extrusion, Apple Liquid Glass (iOS 26), dynamic accent color tinting,
/// badges, icons, accessibility, and haptic feedback.
public struct CraftActionCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var envSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let subtitleKey: LocalizedStringKey?
    private let rawSubtitle: String?

    public let iconName: String?
    public let symbol: CraftSymbol?
    public let badgeText: String?
    public let badgeKey: LocalizedStringKey?
    public let badgeIcon: String?
    public let accentColor: Color?
    public let explicitStyle: CraftSurfaceStyle?
    public let showChevron: Bool
    public let cornerRadius: CGFloat?
    public let action: () -> Void

    public var title: String { rawTitle ?? "" }
    public var subtitle: String? { rawSubtitle }

    public var resolvedStyle: CraftSurfaceStyle {
        explicitStyle ?? (envSurfaceStyle != .flat ? envSurfaceStyle : .outlined)
    }

    private var effectiveAccent: Color {
        accentColor ?? theme.colors.brandPrimary
    }

    private var effectiveRadius: CGFloat {
        cornerRadius ?? theme.radii.xl
    }

    // MARK: - Initializers

    /// 1. Standard String-based Initializer
    public init(
        title: String,
        subtitle: String? = nil,
        iconName: String? = nil,
        badgeText: String? = nil,
        badgeKey: LocalizedStringKey? = nil,
        badgeIcon: String? = "stopwatch.fill",
        accentColor: Color? = nil,
        style: CraftSurfaceStyle? = nil,
        showChevron: Bool = true,
        cornerRadius: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.iconName = iconName
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.badgeText = badgeText
        self.badgeKey = badgeKey
        self.badgeIcon = badgeIcon
        self.accentColor = accentColor
        self.explicitStyle = style
        self.showChevron = showChevron
        self.cornerRadius = cornerRadius
        self.action = action
    }

    /// 2. LocalizedStringKey-based Initializer
    public init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        iconName: String? = nil,
        badgeText: String? = nil,
        badgeKey: LocalizedStringKey? = nil,
        badgeIcon: String? = "stopwatch.fill",
        accentColor: Color? = nil,
        style: CraftSurfaceStyle? = nil,
        showChevron: Bool = true,
        cornerRadius: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.iconName = iconName
        self.symbol = iconName.flatMap { CraftSymbol(rawValue: $0) }
        self.badgeText = badgeText
        self.badgeKey = badgeKey
        self.badgeIcon = badgeIcon
        self.accentColor = accentColor
        self.explicitStyle = style
        self.showChevron = showChevron
        self.cornerRadius = cornerRadius
        self.action = action
    }

    /// 3. CraftSymbol-based Initializer
    public init(
        title: String,
        subtitle: String? = nil,
        symbol: CraftSymbol,
        badgeText: String? = nil,
        badgeKey: LocalizedStringKey? = nil,
        badgeIcon: String? = "stopwatch.fill",
        accentColor: Color? = nil,
        style: CraftSurfaceStyle? = nil,
        showChevron: Bool = true,
        cornerRadius: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.iconName = symbol.rawValue
        self.symbol = symbol
        self.badgeText = badgeText
        self.badgeKey = badgeKey
        self.badgeIcon = badgeIcon
        self.accentColor = accentColor
        self.explicitStyle = style
        self.showChevron = showChevron
        self.cornerRadius = cornerRadius
        self.action = action
    }

    /// 4. LocalizedStringKey + CraftSymbol Initializer
    public init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        symbol: CraftSymbol,
        badgeText: String? = nil,
        badgeKey: LocalizedStringKey? = nil,
        badgeIcon: String? = "stopwatch.fill",
        accentColor: Color? = nil,
        style: CraftSurfaceStyle? = nil,
        showChevron: Bool = true,
        cornerRadius: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.iconName = symbol.rawValue
        self.symbol = symbol
        self.badgeText = badgeText
        self.badgeKey = badgeKey
        self.badgeIcon = badgeIcon
        self.accentColor = accentColor
        self.explicitStyle = style
        self.showChevron = showChevron
        self.cornerRadius = cornerRadius
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            cardSurface
        }
        .buttonStyle(
            CraftActionCardButtonStyle(
                style: resolvedStyle,
                depth: theme.depths.depthMd,
                cornerRadius: effectiveRadius,
                accentColor: effectiveAccent
            )
        )
        .accessibilityElement(children: .combine)
        .modifier(ActionCardAccessibilityModifier(label: accessibilityLabelString))
        .accessibilityHint(CraftLocalized.string("craft.common.action.action"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Card Surface & Layout

    @ViewBuilder
    private var cardSurface: some View {
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
        if #available(iOS 26, macOS 26, *), resolvedStyle == .glass, !reduceTransparency {
            cardContent
                .glassEffect(.regular.interactive(), in: shape)
                .overlay(cardBorderOverlay)
                .modifier(ActionCardShadowModifier(style: resolvedStyle, theme: theme))
                .contentShape(Rectangle())
        } else {
            cardContent
                .background(cardBackground)
                .clipShape(shape)
                .overlay(cardBorderOverlay)
                .overlay(topHighlightOverlay)
                .modifier(ActionCardShadowModifier(style: resolvedStyle, theme: theme))
                .contentShape(Rectangle())
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row (Icon + Badge)
            headerRow

            // Body (Title + Subtitle)
            bodyContent

            Spacer(minLength: 0)

            // Footer (Chevron)
            if showChevron {
                footerRow
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
    }

    // MARK: - Header Slot

    private var headerRow: some View {
        HStack(alignment: .center) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 26, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconForegroundColor)
            }

            Spacer(minLength: 4)

            if let badgeKey {
                HStack(spacing: 4) {
                    if let badgeIcon {
                        Image(systemName: badgeIcon)
                            .font(.system(size: 10, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text(badgeKey)
                        .font(.caption2.monospacedDigit().bold())
                }
                .foregroundColor(badgeForegroundColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeBackground)
                .clipShape(Capsule())
                .overlay(badgeBorder)
            } else if let badgeText {
                HStack(spacing: 4) {
                    if let badgeIcon {
                        Image(systemName: badgeIcon)
                            .font(.system(size: 10, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text(badgeText)
                        .font(.caption2.monospacedDigit().bold())
                }
                .foregroundColor(badgeForegroundColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeBackground)
                .clipShape(Capsule())
                .overlay(badgeBorder)
            }
        }
    }

    @ViewBuilder
    private var badgeBackground: some View {
        if resolvedStyle == .glass && !reduceTransparency {
            Capsule().fill(.ultraThinMaterial)
        } else {
            Capsule().fill(badgeBackgroundColor)
        }
    }

    @ViewBuilder
    private var badgeBorder: some View {
        if resolvedStyle == .glass && !reduceTransparency {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.65), effectiveAccent.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        } else {
            Capsule().strokeBorder(badgeStrokeColor, lineWidth: 0.8)
        }
    }

    // MARK: - Body Slot

    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let titleKey {
                Text(titleKey)
                    .font(theme.typography.headline.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(titleColor)
                    .lineLimit(1)
            } else if let rawTitle {
                Text(rawTitle)
                    .font(theme.typography.headline.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(titleColor)
                    .lineLimit(1)
            }

            if let subtitleKey {
                Text(subtitleKey)
                    .font(theme.typography.caption)
                    .foregroundColor(subtitleColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let rawSubtitle, !rawSubtitle.isEmpty {
                Text(rawSubtitle)
                    .font(theme.typography.caption)
                    .foregroundColor(subtitleColor)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Footer Slot

    private var footerRow: some View {
        HStack {
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(chevronColor)
        }
    }

    // MARK: - Backgrounds & Overlays

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
        switch resolvedStyle {
        case .glass:
            if reduceTransparency {
                shape.fill(theme.colors.surfaceCard)
            } else {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    // Clean frosted glass ambient specular gradient with a subtle accent light reflection
                    shape.fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.35), location: 0.0),
                                .init(color: Color.white.opacity(0.06), location: 0.35),
                                .init(color: effectiveAccent.opacity(0.04), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
        case .outlined:
            shape
                .fill(theme.colors.surfaceCard)
                .overlay(
                    shape.fill(
                        LinearGradient(
                            colors: [effectiveAccent.opacity(0.06), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        case .tactile3D:
            shape
                .fill(theme.colors.surfaceCard)
                .overlay(
                    shape.fill(
                        LinearGradient(
                            colors: [effectiveAccent.opacity(0.04), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
        case .elevated:
            shape
                .fill(theme.colors.surfaceElevated)
                .overlay(
                    shape.fill(effectiveAccent.opacity(0.04))
                )
        case .flat:
            shape
                .fill(theme.colors.surfaceSubtle)
                .overlay(
                    shape.fill(effectiveAccent.opacity(0.03))
                )
        }
    }

    @ViewBuilder
    private var cardBorderOverlay: some View {
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
        switch resolvedStyle {
        case .outlined:
            shape.stroke(
                LinearGradient(
                    colors: [
                        effectiveAccent.opacity(0.35),
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        case .tactile3D:
            shape.stroke(effectiveAccent.opacity(0.35), lineWidth: 1)
        case .elevated:
            shape.stroke(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                        .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        case .glass:
            ZStack {
                shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1.0)
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.65), location: 0.0),
                            .init(color: effectiveAccent.opacity(0.30), location: 0.35),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
            }
        case .flat:
            EmptyView()
        }
    }

    @ViewBuilder
    private var topHighlightOverlay: some View {
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)
        if resolvedStyle == .tactile3D {
            shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
        } else if resolvedStyle == .glass && !reduceTransparency {
            if #unavailable(iOS 26, macOS 26) {
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
            }
        }
    }

    // MARK: - Semantic Colors

    private var iconForegroundColor: Color {
        effectiveAccent
    }

    private var badgeForegroundColor: Color {
        effectiveAccent
    }

    private var badgeBackgroundColor: Color {
        effectiveAccent.opacity(0.12)
    }

    private var badgeStrokeColor: Color {
        effectiveAccent.opacity(0.25)
    }

    private var titleColor: Color {
        theme.colors.textPrimary
    }

    private var subtitleColor: Color {
        theme.colors.textSecondary
    }

    private var chevronColor: Color {
        effectiveAccent.opacity(0.8)
    }

    private var accessibilityLabelString: String {
        var parts: [String] = []
        if !title.isEmpty {
            parts.append(title)
        }
        if let badgeText, !badgeText.isEmpty {
            parts.append(badgeText)
        }
        if let subtitle, !subtitle.isEmpty {
            parts.append(subtitle)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Shadow Modifier

private struct ActionCardShadowModifier: ViewModifier {
    let style: CraftSurfaceStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content.craftShadow(theme.shadows.md)
        case .glass, .outlined:
            content.craftShadow(theme.shadows.sm)
        case .flat, .tactile3D:
            content
        }
    }
}

// MARK: - Accessibility Modifier

private struct ActionCardAccessibilityModifier: ViewModifier {
    let label: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if !label.isEmpty {
            content.accessibilityLabel(label)
        } else {
            content
        }
    }
}

// MARK: - Button Style

/// Button style providing tactile 3D mechanical press depression with bottom extrusion base.
public struct CraftActionCardButtonStyle: ButtonStyle {
    public let style: CraftSurfaceStyle
    public let depth: CGFloat
    public let cornerRadius: CGFloat
    public let accentColor: Color?
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        style: CraftSurfaceStyle = .outlined,
        depth: CGFloat = 4,
        cornerRadius: CGFloat = 22,
        accentColor: Color? = nil
    ) {
        self.style = style
        self.depth = depth
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let isTactile = style == .tactile3D
        let effectiveDepth = isTactile ? depth : 0
        let depressOffset = (isPressed && isTactile) ? depth : 0

        ZStack(alignment: .top) {
            // Seamless extruded 3D base layer matching exact corner curvature
            if isTactile {
                extrudedBaseLayer
            }

            // Top interactive card face
            configuration.label
                .offset(y: depressOffset)
        }
        .padding(.bottom, isTactile ? effectiveDepth : 0)
        .scaleEffect(isPressed && !reduceMotion ? (isTactile ? 0.99 : 0.98) : 1.0)
        .animation(theme.animations.springSnappy, value: isPressed)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in
            pressed
        }
    }

    private var extrudedBaseLayer: some View {
        let baseLip = Color.craftDynamic(light: Color(hex: 0xD1D5DB), dark: Color(hex: 0x374151))
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(baseLip.opacity(0.85))
            .overlay {
                if let accentColor {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(accentColor.opacity(0.20))
                }
            }
            .offset(y: depth)
    }
}

#Preview("CraftActionCard - All Variants") {
    ScrollView {
        VStack(spacing: 16) {
            CraftActionCard(
                title: "Luyện phản xạ",
                subtitle: "SRS Speed Drills & Quick recall",
                iconName: "bolt.fill",
                badgeText: "6.0s",
                badgeIcon: "stopwatch.fill",
                accentColor: .orange,
                style: .outlined
            ) {}

            CraftActionCard(
                title: "Luyện nói & Phát âm",
                subtitle: "Nhận diện giọng nói với AI",
                symbol: .mic,
                badgeText: "AI EVAL",
                badgeIcon: "sparkles",
                accentColor: .cyan,
                style: .tactile3D
            ) {}

            CraftActionCard(
                title: "Thẻ ghi nhớ Glass",
                subtitle: "Translucent frosted material",
                symbol: .study,
                badgeText: "PRO",
                badgeIcon: "star.fill",
                accentColor: .purple,
                style: .glass
            ) {}
        }
        .padding()
    }
}
