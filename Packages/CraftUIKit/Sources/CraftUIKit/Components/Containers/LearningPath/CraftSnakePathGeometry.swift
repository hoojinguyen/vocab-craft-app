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
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: from.y),
                tangent2End: CGPoint(x: turnX, y: to.y),
                radius: r
            )
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: to.y),
                tangent2End: CGPoint(x: to.x, y: to.y),
                radius: r
            )
            path.addLine(to: to)
        case .leftHairpin:
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: from.y),
                tangent2End: CGPoint(x: turnX, y: to.y),
                radius: r
            )
            path.addArc(
                tangent1End: CGPoint(x: turnX, y: to.y),
                tangent2End: CGPoint(x: to.x, y: to.y),
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
    private static var segmentCache: [String: SnakePathSegmentGeometry] = [:]
    private static let maxCacheSize = 128

    private static func cacheKey(from: CGPoint, to: CGPoint, containerWidth: CGFloat, turnRadius: CGFloat, edgeInset: CGFloat) -> String {
        // Quantize to 0.5pt to avoid floating point noise
        let fx = (from.x * 2).rounded() / 2
        let fy = (from.y * 2).rounded() / 2
        let tx = (to.x * 2).rounded() / 2
        let ty = (to.y * 2).rounded() / 2
        return "\(fx),\(fy)-\(tx),\(ty)-\(containerWidth.rounded())-\(turnRadius.rounded())-\(edgeInset.rounded())"
    }

    public static func createSegment(
        from: CGPoint,
        to: CGPoint,
        containerWidth: CGFloat,
        turnRadius: CGFloat = 32.0,
        edgeInset: CGFloat = 28.0
    ) -> SnakePathSegmentGeometry {
        let key = cacheKey(from: from, to: to, containerWidth: containerWidth, turnRadius: turnRadius, edgeInset: edgeInset)
        if let cached = segmentCache[key] {
            return cached
        }

        let result: SnakePathSegmentGeometry
        if abs(from.y - to.y) < 15 {
            result = SnakePathSegmentGeometry(
                from: from,
                to: to,
                type: .horizontal,
                turnRadius: turnRadius,
                turnX: from.x
            )
        } else {
            let isLeftTurn: Bool
            if from.x < containerWidth * 0.40 {
                isLeftTurn = true
            } else if from.x > containerWidth * 0.60 {
                isLeftTurn = false
            } else {
                // Starting from Center node
                isLeftTurn = (to.x < from.x)
            }

            if isLeftTurn {
                let leftTurnX = edgeInset
                result = SnakePathSegmentGeometry(
                    from: from,
                    to: to,
                    type: .leftHairpin,
                    turnRadius: turnRadius,
                    turnX: leftTurnX
                )
            } else {
                let rightTurnX = containerWidth - edgeInset
                result = SnakePathSegmentGeometry(
                    from: from,
                    to: to,
                    type: .rightHairpin,
                    turnRadius: turnRadius,
                    turnX: rightTurnX
                )
            }
        }

        if segmentCache.count > maxCacheSize {
            // Evict arbitrary first entry (LRU approx)
            if let firstKey = segmentCache.keys.first {
                segmentCache.removeValue(forKey: firstKey)
            }
        }
        segmentCache[key] = result
        return result
    }
}
