import SwiftUI

// MARK: - Tactile Button Style

/// Button style providing mechanical tactile press feedback with vertical translation depression.
public struct TactileButtonStyle: ButtonStyle {
    public let depth: CGFloat

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(depth: CGFloat = 4) {
        self.depth = depth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        configuration.label
            .offset(y: (isPressed && !reduceMotion) ? depth : 0)
            .scaleEffect((isPressed && !reduceMotion) ? 0.99 : 1.0)
            .animation(theme.animations.springSnappy, value: isPressed)
    }
}

public extension ButtonStyle where Self == TactileButtonStyle {
    /// Convenience helper for applying the tactile 3D press button style.
    static func tactile(depth: CGFloat = 4) -> TactileButtonStyle {
        TactileButtonStyle(depth: depth)
    }
}

// MARK: - CraftPinnedUnitHeader Component

/// A sticky floating navigation card representing the current unit/section in `CraftFluidJourney`.
///
/// `CraftPinnedUnitHeader` renders a translucent glass card featuring:
/// - A level badge (e.g. "A2") with numeric content transition
/// - The active section title and subtitle
/// - A trailing chevron indicating that tapping opens the curriculum drawer
/// - A smooth asymmetric morphing transition (`.move(edge: .bottom)` / `.move(edge: .top)`)
///   when the active unit changes during scrolling, layered inside a `ZStack` to prevent squishing
/// - Tactile spring-based depress feedback and full VoiceOver accessibility
public struct CraftPinnedUnitHeader: View, Equatable {
    // MARK: - Constants

    /// Default corner radius matching the fluid journey design specifications (20pt).
    public static let defaultCornerRadius: CGFloat = 20

    // MARK: - Properties

    /// Lesson section DTO representing the currently pinned unit.
    public let section: LessonSection

    /// Surface style applied to the header card, or `nil` to resolve dynamically from theme/environment.
    public let surfaceStyle: CraftSurfaceStyle?

    /// Corner radius for the card surface. Defaults to nil (resolving to theme.radii.xl).
    public let cornerRadius: CGFloat?

    /// Action closure triggered when the user taps the header card.
    public let onTap: (@Sendable () -> Void)?

    /// Backward-compatible alias for `onTap`.
    public var onHeaderTap: (@Sendable () -> Void)? {
        onTap
    }

    // MARK: - Environment

    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Surface Style Resolution

    public var effectiveSurfaceStyle: CraftSurfaceStyle {
        surfaceStyle ?? (environmentSurfaceStyle != .flat ? environmentSurfaceStyle : theme.surfaceStyle)
    }

    // MARK: - Initializers

    /// Creates a pinned unit header card.
    ///
    /// - Parameters:
    ///   - section: The current lesson section DTO.
    ///   - surfaceStyle: Surface style applied to the header card, or `nil` to resolve dynamically.
    ///   - cornerRadius: Custom corner radius, or `nil` to resolve using `theme.radii.xl`.
    ///   - onTap: Callback closure invoked when tapped.
    public init(
        section: LessonSection,
        surfaceStyle: CraftSurfaceStyle? = nil,
        cornerRadius: CGFloat? = nil,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.section = section
        self.surfaceStyle = surfaceStyle
        self.cornerRadius = cornerRadius
        self.onTap = onTap
    }

    /// Convenience initializer supporting `onHeaderTap` parameter naming.
    ///
    /// - Parameters:
    ///   - section: The current lesson section DTO.
    ///   - surfaceStyle: Surface style applied to the header card, or `nil` to resolve dynamically.
    ///   - cornerRadius: Custom corner radius, or `nil` to resolve using `theme.radii.xl`.
    ///   - onHeaderTap: Callback closure invoked when tapped.
    public init(
        section: LessonSection,
        surfaceStyle: CraftSurfaceStyle? = nil,
        cornerRadius: CGFloat? = nil,
        onHeaderTap: (@Sendable () -> Void)?
    ) {
        self.init(section: section, surfaceStyle: surfaceStyle, cornerRadius: cornerRadius, onTap: onHeaderTap)
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftPinnedUnitHeader, rhs: CraftPinnedUnitHeader) -> Bool {
        lhs.section == rhs.section &&
        lhs.cornerRadius == rhs.cornerRadius &&
        lhs.surfaceStyle == rhs.surfaceStyle
    }

    // MARK: - Accessibility Helpers

    /// Consolidated VoiceOver label combining level, title, and subtitle.
    public var accessibilityLabelText: String {
        [section.level, section.title, section.subtitle]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    /// Accessibility hint informing the user that tapping opens the unit curriculum drawer.
    public var accessibilityHintText: String {
        CraftLocalized.string("craft.fluid_journey.select_unit_hint")
    }

    /// Accessibility traits declaring this interactive header card as a button.
    public var accessibilityTraits: AccessibilityTraits {
        .isButton
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if effectiveSurfaceStyle == .tactile3D {
                Button {
                    onTap?()
                } label: {
                    cardBody
                }
                .buttonStyle(TactileButtonStyle(depth: theme.depths.depthMd))
            } else {
                Button {
                    onTap?()
                } label: {
                    cardBody
                }
                .buttonStyle(.craftPress(scale: 0.98))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Card Content & Styling

    private var cardBody: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack(alignment: .leading) {
                sectionInfoBlock
            }

            Spacer(minLength: 0)

            chevronIcon
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.md)
        .background(cardBackground)
        .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: section.id)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let effectiveRadius = cornerRadius ?? theme.radii.xl
        let shape = RoundedRectangle(cornerRadius: effectiveRadius, style: .continuous)

        switch effectiveSurfaceStyle {
        case .tactile3D:
            ZStack {
                // 3D bottom rim bevel extrusion layer
                shape
                    .fill(theme.colors.borderDefault)
                    .offset(y: theme.depths.depthMd)

                // Top surface face
                shape
                    .fill(theme.colors.surfaceCard)
                    .overlay(
                        shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
                    )
            }
            .craftShadow(theme.shadows.sm)

        case .glass:
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
            .overlay(
                shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1)
            )
            .clipShape(shape)
            .craftShadow(theme.shadows.sm)

        case .elevated:
            shape
                .fill(theme.colors.surfaceCard)
                .overlay(
                    shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                )
                .clipShape(shape)
                .craftShadow(theme.shadows.md)

        case .outlined:
            shape
                .fill(theme.colors.surfaceCard)
                .overlay(
                    shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                )
                .clipShape(shape)

        case .flat:
            shape
                .fill(theme.colors.surfaceSubtle)
                .clipShape(shape)
        }
    }

    // MARK: - Subviews

    private var sectionInfoBlock: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            if let level = section.level, !level.isEmpty {
                CraftBadge(level, variant: .subtle, tone: .primary, size: .sm)
                    .contentTransition(.numericText())
            }

            Text(section.title)
                .font(theme.typography.titleMedium.weight(.bold))
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            if let subtitle = section.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(section.id)
        .transition(morphingTransition)
    }

    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .font(theme.typography.bodyMedium.weight(.semibold))
            .foregroundStyle(theme.colors.textSecondary)
            .accessibilityHidden(true)
    }

    private var morphingTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
        }
    }
}

// MARK: - Preview

#Preview("CraftPinnedUnitHeader") {
    let section = LessonSection(
        id: "sec-1",
        title: "Everyday Conversations",
        subtitle: "Habits & Moods",
        level: "A2",
        nodes: []
    )
    CraftPinnedUnitHeader(section: section, onTap: {})
        .padding()
}
