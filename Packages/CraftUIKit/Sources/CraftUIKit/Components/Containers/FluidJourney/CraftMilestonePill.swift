import SwiftUI

/// An in-scroll floating capsule representing unit/section milestone boundaries in the fluid journey.
///
/// `CraftMilestonePill` renders a sleek pill/capsule containing the unit milestone title,
/// styled with the active design system surface colors and a hairline stroke.
///
/// It embeds a `GeometryReader` that observes its vertical scroll position (`minY`) in the designated
/// coordinate space (defaulting to `"CraftFluidJourneySpace"`) and posts the coordinate via
/// `FluidJourneyMilestonePreferenceKey` so parent containers can track section docking.
public struct CraftMilestonePill: View, Equatable {
    // MARK: - Constants

    /// Default coordinate space name used for scroll offset tracking across fluid journey components.
    public static let coordinateSpaceName = "CraftFluidJourneySpace"

    /// Alias for default coordinate space name for consistency across component APIs.
    public static let defaultCoordinateSpaceName = coordinateSpaceName

    // MARK: - Properties

    /// Unique identifier of the lesson section this milestone represents.
    public let sectionId: String

    /// Localized or display title of the unit/section milestone.
    public let title: String

    /// Named coordinate space to track vertical position in.
    public let coordinateSpaceName: String

    // MARK: - Environment

    @Environment(\.craftTheme) private var theme

    // MARK: - Initializer

    /// Creates a milestone pill with the given section identifier and title.
    ///
    /// - Parameters:
    ///   - sectionId: Unique identifier of the section.
    ///   - title: Title text displayed inside the capsule.
    ///   - coordinateSpaceName: Named coordinate space for geometry tracking. Defaults to `"CraftFluidJourneySpace"`.
    public init(
        sectionId: String,
        title: String,
        coordinateSpaceName: String = CraftMilestonePill.coordinateSpaceName
    ) {
        self.sectionId = sectionId
        self.title = title
        self.coordinateSpaceName = coordinateSpaceName
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftMilestonePill, rhs: CraftMilestonePill) -> Bool {
        lhs.sectionId == rhs.sectionId &&
        lhs.title == rhs.title &&
        lhs.coordinateSpaceName == rhs.coordinateSpaceName
    }

    // MARK: - Accessibility Helpers

    /// Accessibility label describing the milestone pill heading.
    public var accessibilityLabelText: String {
        title
    }

    /// Accessibility traits declaring this milestone as a structural heading.
    public var accessibilityTraits: AccessibilityTraits {
        .isHeader
    }

    // MARK: - Body

    public var body: some View {
        Text(title)
            .font(theme.typography.label)
            .fontWeight(.semibold)
            .foregroundColor(theme.colors.textSecondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.sm)
            .background(
                Capsule()
                    .fill(theme.colors.surfaceCard)
            )
            .overlay(
                Capsule()
                    .strokeBorder(theme.colors.hairline, lineWidth: 1)
            )
            .craftShadow(theme.shadows.sm)
            .background(
                GeometryReader { geo in
                    let minY = geo.frame(in: .named(coordinateSpaceName)).minY
                    Color.clear
                        .preference(
                            key: FluidJourneyMilestonePreferenceKey.self,
                            value: [sectionId: minY]
                        )
                }
            )
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(accessibilityTraits)
            .accessibilityLabel(Text(accessibilityLabelText))
    }
}
