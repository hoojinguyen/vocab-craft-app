import SwiftUI

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

    /// Corner radius for the card surface. Defaults to 20pt.
    public let cornerRadius: CGFloat

    /// Action closure triggered when the user taps the header card.
    public let onTap: (@Sendable () -> Void)?

    /// Backward-compatible alias for `onTap`.
    public var onHeaderTap: (@Sendable () -> Void)? {
        onTap
    }

    // MARK: - Environment

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializers

    /// Creates a pinned unit header card.
    ///
    /// - Parameters:
    ///   - section: The current lesson section DTO.
    ///   - cornerRadius: Custom corner radius. Defaults to 20pt.
    ///   - onTap: Callback closure invoked when tapped.
    public init(
        section: LessonSection,
        cornerRadius: CGFloat = CraftPinnedUnitHeader.defaultCornerRadius,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.section = section
        self.cornerRadius = cornerRadius
        self.onTap = onTap
    }

    /// Convenience initializer supporting `onHeaderTap` parameter naming.
    ///
    /// - Parameters:
    ///   - section: The current lesson section DTO.
    ///   - cornerRadius: Custom corner radius. Defaults to 20pt.
    ///   - onHeaderTap: Callback closure invoked when tapped.
    public init(
        section: LessonSection,
        cornerRadius: CGFloat = CraftPinnedUnitHeader.defaultCornerRadius,
        onHeaderTap: (@Sendable () -> Void)?
    ) {
        self.init(section: section, cornerRadius: cornerRadius, onTap: onHeaderTap)
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftPinnedUnitHeader, rhs: CraftPinnedUnitHeader) -> Bool {
        lhs.section == rhs.section &&
        lhs.cornerRadius == rhs.cornerRadius
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
        Button {
            onTap?()
        } label: {
            cardBody
        }
        .buttonStyle(.craftPress(scale: 0.98))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Card Content & Styling

    private var cardBody: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return HStack(spacing: theme.spacing.md) {
            ZStack(alignment: .leading) {
                sectionInfoBlock
            }

            Spacer(minLength: 0)

            chevronIcon
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.md)
        .background(
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        )
        .overlay(
            shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1)
        )
        .clipShape(shape)
        .craftShadow(theme.shadows.sm)
        .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: section.id)
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
