import SwiftUI

// MARK: - CraftDivider Component

/// A standardized hairline divider component adapting to theme hairline color tokens.
public struct CraftDivider: View {
    @Environment(\.craftTheme) private var theme

    public let axis: Axis
    public let color: Color?
    public let thickness: CGFloat

    public init(
        axis: Axis = .horizontal,
        color: Color? = nil,
        thickness: CGFloat = 1
    ) {
        self.axis = axis
        self.color = color
        self.thickness = thickness
    }

    public var body: some View {
        Rectangle()
            .fill(color ?? theme.colors.hairline)
            .frame(
                width: axis == .vertical ? thickness : nil,
                height: axis == .horizontal ? thickness : nil
            )
    }
}
