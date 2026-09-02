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

// MARK: - SnakePathGeometryCache

/// Thread-safe LRU-ish cache for snake segment geometry (Swift 6 Sendable safe).
private final class SnakePathGeometryCache: @unchecked Sendable {
    private var storage: [String: SnakePathSegmentGeometry] = [:]
    private let lock = NSLock()
    private let maxSize: Int = 128

    func get(_ key: String) -> SnakePathSegmentGeometry? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }

    func set(_ key: String, value: SnakePathSegmentGeometry) {
        lock.lock()
        defer { lock.unlock() }
        if storage.count >= maxSize, let firstKey = storage.keys.first {
            storage.removeValue(forKey: firstKey)
        }
        storage[key] = value
    }
}

// MARK: - SnakePathGeometry

/// Geometry routing helper calculating exact connector geometry between node anchor coordinates.
public struct SnakePathGeometry {
    private static let cache = SnakePathGeometryCache()

    private static func cacheKey(from: CGPoint, to: CGPoint, containerWidth: CGFloat, turnRadius: CGFloat, edgeInset: CGFloat) -> String {
        // Quantize endpoints to 0.5pt and store quantized points in the cached geometry
        // to avoid stale raw positions when keys collide. Lossless alternative would be
        // to use raw values, but quantization reduces cache misses from floating noise.
        let fx = (from.x * 2).rounded() / 2
        let fy = (from.y * 2).rounded() / 2
        let tx = (to.x * 2).rounded() / 2
        let ty = (to.y * 2).rounded() / 2
        let cw = (containerWidth * 2).rounded() / 2
        let tr = (turnRadius * 2).rounded() / 2
        let ei = (edgeInset * 2).rounded() / 2
        return "\(fx),\(fy)-\(tx),\(ty)-\(cw)-\(tr)-\(ei)"
    }

    private static func quantized(_ point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x * 2).rounded() / 2, y: (point.y * 2).rounded() / 2)
    }

    public static func createSegment(
        from: CGPoint,
        to: CGPoint,
        containerWidth: CGFloat,
        turnRadius: CGFloat = 40.0,
        edgeInset: CGFloat = 24.0
    ) -> SnakePathSegmentGeometry {
        let key = cacheKey(from: from, to: to, containerWidth: containerWidth, turnRadius: turnRadius, edgeInset: edgeInset)
        if let cached = cache.get(key) {
            return cached
        }

        // Use quantized points for the cached geometry so key and value stay consistent
        let qFrom = quantized(from)
        let qTo = quantized(to)
        let qContainerWidth = (containerWidth * 2).rounded() / 2
        let qTurnRadius = (turnRadius * 2).rounded() / 2
        let qEdgeInset = (edgeInset * 2).rounded() / 2

        let result: SnakePathSegmentGeometry
        if abs(qFrom.y - qTo.y) < 15 {
            result = SnakePathSegmentGeometry(
                from: qFrom,
                to: qTo,
                type: .horizontal,
                turnRadius: qTurnRadius,
                turnX: qFrom.x
            )
        } else {
            let isLeftTurn: Bool
            if qFrom.x < qContainerWidth * 0.40 {
                isLeftTurn = true
            } else if qFrom.x > qContainerWidth * 0.60 {
                isLeftTurn = false
            } else {
                // Starting from Center node
                isLeftTurn = (qTo.x < qFrom.x)
            }

            if isLeftTurn {
                let leftTurnX = qEdgeInset
                result = SnakePathSegmentGeometry(
                    from: qFrom,
                    to: qTo,
                    type: .leftHairpin,
                    turnRadius: qTurnRadius,
                    turnX: leftTurnX
                )
            } else {
                let rightTurnX = qContainerWidth - qEdgeInset
                result = SnakePathSegmentGeometry(
                    from: qFrom,
                    to: qTo,
                    type: .rightHairpin,
                    turnRadius: qTurnRadius,
                    turnX: rightTurnX
                )
            }
        }

        cache.set(key, value: result)
        return result
    }
}
