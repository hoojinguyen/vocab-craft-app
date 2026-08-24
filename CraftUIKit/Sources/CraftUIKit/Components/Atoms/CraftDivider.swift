import SwiftUI

// MARK: - Divider Style

public enum CraftDividerStyle: Sendable, Equatable {
    case solid
    case dashed(dash: CGFloat, gap: CGFloat)
    case gradient(LinearGradient)

    public static func == (lhs: CraftDividerStyle, rhs: CraftDividerStyle) -> Bool {
        switch (lhs, rhs) {
        case (.solid, .solid):
            return true
        case let (.dashed(dash1, gap1), .dashed(dash2, gap2)):
            return dash1 == dash2 && gap1 == gap2
        case let (.gradient(g1), .gradient(g2)):
            return String(describing: g1) == String(describing: g2)
        default:
            return false
        }
    }
}

// MARK: - Dashed Line Shape

private struct DashedLineShape: Shape {
    let axis: Axis
    let effectiveThickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if axis == .horizontal {
            let y = effectiveThickness / 2
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        } else {
            let x = effectiveThickness / 2
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        return path
    }
}

// MARK: - CraftDivider Component

/// A standardized hairline divider component adapting to theme hairline color tokens,
/// display scale, and multiple visual styles (solid, dashed, gradient).
public struct CraftDivider: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    public let axis: Axis
    public let color: Color?
    public let customThickness: CGFloat?
    public let style: CraftDividerStyle

    public var thickness: CGFloat? {
        customThickness
    }

    public init(
        axis: Axis = .horizontal,
        color: Color? = nil,
        thickness: CGFloat? = nil,
        style: CraftDividerStyle = .solid
    ) {
        self.axis = axis
        self.color = color
        self.customThickness = thickness
        self.style = style
    }

    public var body: some View {
        let effectiveThickness = customThickness ?? (1.0 / displayScale)
        let effectiveColor = color ?? theme.colors.hairline

        switch style {
        case .solid:
            Rectangle()
                .fill(effectiveColor)
                .frame(
                    width: axis == .vertical ? effectiveThickness : nil,
                    height: axis == .horizontal ? effectiveThickness : nil
                )
        case .dashed(let dash, let gap):
            DashedLineShape(axis: axis, effectiveThickness: effectiveThickness)
                .stroke(
                    effectiveColor,
                    style: StrokeStyle(lineWidth: effectiveThickness, dash: [dash, gap])
                )
                .frame(
                    width: axis == .vertical ? effectiveThickness : nil,
                    height: axis == .horizontal ? effectiveThickness : nil
                )
        case .gradient(let linearGradient):
            Rectangle()
                .fill(linearGradient)
                .frame(
                    width: axis == .vertical ? effectiveThickness : nil,
                    height: axis == .horizontal ? effectiveThickness : nil
                )
        }
    }
}

#Preview("CraftDivider") {
    VStack(spacing: 24) {
        VStack(spacing: 8) {
            Text("Solid")
            CraftDivider()
            Text("Dashed")
            CraftDivider(style: .dashed(dash: 6, gap: 4))
            Text("Gradient")
            CraftDivider(style: .gradient(LinearGradient(colors: [.clear, .blue, .clear], startPoint: .leading, endPoint: .trailing)))
        }

        HStack(spacing: 16) {
            Text("Left")
            CraftDivider(axis: .vertical)
            Text("Middle")
            CraftDivider(axis: .vertical, style: .dashed(dash: 4, gap: 2))
            Text("Right")
        }
        .frame(height: 50)
    }
    .padding()
}

