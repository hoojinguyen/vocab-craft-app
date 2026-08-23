import SwiftUI

// MARK: - SnakePathSegmentType

/// Defines the path geometry shape connecting two consecutive nodes in a snake hybrid layout.
public enum SnakePathSegmentType: String, Sendable, Equatable, Hashable {
    case horizontal
    case rightHairpin
    case leftHairpin
}

// MARK: - SnakePathSegmentGeometry

/// Encapsulates calculated coordinates, turning arc parameters, and path construction for a segment.
public struct SnakePathSegmentGeometry: Sendable, Equatable {
    public let from: CGPoint
    public let to: CGPoint
    public let type: SnakePathSegmentType
    public let turnRadius: CGFloat
    public let turnX: CGFloat

    public init(
        from: CGPoint,
        to: CGPoint,
        type: SnakePathSegmentType,
        turnRadius: CGFloat,
        turnX: CGFloat
    ) {
        self.from = from
        self.to = to
        self.type = type
        self.turnRadius = turnRadius
        self.turnX = turnX
    }

    /// Builds a SwiftUI `Path` with smooth circular fillet arcs for hairpin turns.
    public func buildPath() -> Path {
        var path = Path()
        path.move(to: from)
        let r = max(4, turnRadius)

        switch type {
        case .horizontal:
            path.addLine(to: to)
        case .rightHairpin:
            let topTurnX = max(from.x, turnX - r)
            path.addLine(to: CGPoint(x: topTurnX, y: from.y))
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: from.y),
                tangent2End: CGPoint(x: turnX, y: from.y + r),
                radius: r
            )
            path.addLine(to: CGPoint(x: turnX, y: to.y - r))
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: to.y),
                tangent2End: CGPoint(x: turnX - r, y: to.y),
                radius: r
            )
            path.addLine(to: to)
        case .leftHairpin:
            let topTurnX = min(from.x, turnX + r)
            path.addLine(to: CGPoint(x: topTurnX, y: from.y))
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: from.y),
                tangent2End: CGPoint(x: turnX, y: from.y + r),
                radius: r
            )
            path.addLine(to: CGPoint(x: turnX, y: to.y - r))
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: to.y),
                tangent2End: CGPoint(x: turnX + r, y: to.y),
                radius: r
            )
            path.addLine(to: to)
        }
        return path
    }
}

// MARK: - SnakePathGeometry

/// Geometry routing helper calculating exact connector geometry between node anchor coordinates.
public struct SnakePathGeometry {
    public static func createSegment(
        from: CGPoint,
        to: CGPoint,
        containerWidth: CGFloat,
        turnRadius: CGFloat = 32.0,
        edgeInset: CGFloat = 28.0
    ) -> SnakePathSegmentGeometry {
        if abs(from.y - to.y) < 15 {
            return SnakePathSegmentGeometry(
                from: from,
                to: to,
                type: .horizontal,
                turnRadius: turnRadius,
                turnX: from.x
            )
        }

        if to.x >= from.x || from.x <= containerWidth * 0.55 {
            let rightTurnX = containerWidth - edgeInset
            return SnakePathSegmentGeometry(
                from: from,
                to: to,
                type: .rightHairpin,
                turnRadius: turnRadius,
                turnX: rightTurnX
            )
        } else {
            let leftTurnX = edgeInset
            return SnakePathSegmentGeometry(
                from: from,
                to: to,
                type: .leftHairpin,
                turnRadius: turnRadius,
                turnX: leftTurnX
            )
        }
    }
}
