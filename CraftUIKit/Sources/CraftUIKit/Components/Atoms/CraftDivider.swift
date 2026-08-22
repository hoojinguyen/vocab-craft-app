import SwiftUI

// MARK: - CraftDivider Component

/// A standardized hairline divider component adapting to theme hairline color tokens and display scale.
public struct CraftDivider: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    public let axis: Axis
    public let color: Color?
    public let customThickness: CGFloat?

    public var thickness: CGFloat? {
        customThickness
    }

    public init(
        axis: Axis = .horizontal,
        color: Color? = nil,
        thickness: CGFloat? = nil
    ) {
        self.axis = axis
        self.color = color
        self.customThickness = thickness
    }

    public var body: some View {
        let effectiveThickness = customThickness ?? (1.0 / displayScale)
        Rectangle()
            .fill(color ?? theme.colors.hairline)
            .frame(
                width: axis == .vertical ? effectiveThickness : nil,
                height: axis == .horizontal ? effectiveThickness : nil
            )
    }
}

#Preview("CraftDivider") {
    VStack(spacing: 24) {
        VStack(spacing: 8) {
            Text("Above")
            CraftDivider()
            Text("Below")
        }
        
        HStack(spacing: 16) {
            Text("Left")
            CraftDivider(axis: .vertical)
            Text("Right")
        }
        .frame(height: 50)
    }
    .padding()
}
