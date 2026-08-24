import Foundation
import SwiftUI

// MARK: - CraftNodeState

/// Visual and progression state for an individual node in the journey path.
public enum CraftNodeState: String, Sendable, CaseIterable, Equatable, Hashable {
    case completed      // Finished — checkmark / statusSuccess
    case active         // Current step — pulsating glow ring, brandPrimary
    case inProgress     // Started not finished — progress ring / arc overlay
    case upcoming       // Next available — muted, tappable
    case locked         // Not unlocked — padlock, dimmed, not tappable
    case bonus          // Optional / reward — accent shine, star badge
}

// MARK: - CraftNodeShape

/// Geometric shape styles supported by journey path nodes.
public enum CraftNodeShape: String, Sendable, CaseIterable, Equatable, Hashable {
    case circle
    case hexagon
    case diamond
    case squircle
    case star
}

// MARK: - CraftNodeIcon

/// Representation of an icon rendered within a journey node or tracker widget.
public struct CraftNodeIcon: Sendable, Equatable, Hashable, ExpressibleByStringLiteral {
    public let name: String
    public let isSystem: Bool

    public init(name: String, isSystem: Bool = true) {
        self.name = name
        self.isSystem = isSystem
    }

    public init(stringLiteral value: String) {
        self.init(name: value, isSystem: true)
    }

    public static func system(_ name: String) -> CraftNodeIcon {
        CraftNodeIcon(name: name, isSystem: true)
    }

    public static func asset(_ name: String) -> CraftNodeIcon {
        CraftNodeIcon(name: name, isSystem: false)
    }
}

// MARK: - StarShape

/// 5-point Star polygon shape for bonus or special milestone nodes.
public struct StarShape: Shape, InsettableShape {
    private let points: Int
    private let innerRatio: CGFloat
    private let insetAmount: CGFloat

    public init(points: Int = 5, innerRatio: CGFloat = 0.45, insetAmount: CGFloat = 0) {
        self.points = points
        self.innerRatio = innerRatio
        self.insetAmount = insetAmount
    }

    public func inset(by amount: CGFloat) -> StarShape {
        StarShape(points: points, innerRatio: innerRatio, insetAmount: insetAmount + amount)
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard insetRect.width > 0 && insetRect.height > 0 else { return Path() }
        let center = CGPoint(x: insetRect.midX, y: insetRect.midY)
        let outerRadius = min(insetRect.width, insetRect.height) / 2.0
        let innerRadius = outerRadius * innerRatio
        var path = Path()
        let angleStep = .pi / CGFloat(points)
        var angle: CGFloat = -.pi / 2.0

        for i in 0..<(points * 2) {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += angleStep
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - SquircleShape

/// Smooth continuous-corner rounded rectangle (squircle).
public struct SquircleShape: Shape, InsettableShape {
    private let cornerRadius: CGFloat
    private let insetAmount: CGFloat

    public init(cornerRadius: CGFloat = 16, insetAmount: CGFloat = 0) {
        self.cornerRadius = cornerRadius
        self.insetAmount = insetAmount
    }

    public func inset(by amount: CGFloat) -> SquircleShape {
        SquircleShape(cornerRadius: cornerRadius, insetAmount: insetAmount + amount)
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return RoundedRectangle(cornerRadius: max(0, cornerRadius - insetAmount), style: .continuous).path(in: insetRect)
    }
}

// MARK: - CraftPathNodeModel

/// Generic presentation model representing a single node within a journey path.
public struct CraftPathNodeModel<CustomPayload: Sendable>: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let titleKey: String?
    public let subtitle: String?
    public let subtitleKey: String?
    public let state: CraftNodeState
    public let shape: CraftNodeShape
    public let surfaceStyle: CraftSurfaceStyle
    public let icon: CraftNodeIcon
    public let progress: Double?
    public let badgeText: String?
    public let badgeCount: Int?
    public let stars: Int?
    public let metricText: String?
    public let customPayload: CustomPayload?

    public init(
        id: String,
        title: String,
        titleKey: String? = nil,
        subtitle: String? = nil,
        subtitleKey: String? = nil,
        state: CraftNodeState = .upcoming,
        shape: CraftNodeShape = .circle,
        surfaceStyle: CraftSurfaceStyle = .tactile3D,
        icon: CraftNodeIcon = .system("book.fill"),
        progress: Double? = nil,
        badgeText: String? = nil,
        badgeCount: Int? = nil,
        stars: Int? = nil,
        metricText: String? = nil,
        customPayload: CustomPayload? = nil
    ) {
        self.id = id
        self.title = title
        self.titleKey = titleKey
        self.subtitle = subtitle
        self.subtitleKey = subtitleKey
        self.state = state
        self.shape = shape
        self.surfaceStyle = surfaceStyle
        self.icon = icon
        self.progress = progress
        self.badgeText = badgeText
        self.badgeCount = badgeCount
        self.stars = stars
        self.metricText = metricText
        self.customPayload = customPayload
    }
}

extension CraftPathNodeModel: Equatable where CustomPayload: Equatable {
    public static func == (lhs: CraftPathNodeModel<CustomPayload>, rhs: CraftPathNodeModel<CustomPayload>) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.titleKey == rhs.titleKey &&
        lhs.subtitle == rhs.subtitle &&
        lhs.subtitleKey == rhs.subtitleKey &&
        lhs.state == rhs.state &&
        lhs.shape == rhs.shape &&
        lhs.surfaceStyle == rhs.surfaceStyle &&
        lhs.icon == rhs.icon &&
        lhs.progress == rhs.progress &&
        lhs.badgeText == rhs.badgeText &&
        lhs.badgeCount == rhs.badgeCount &&
        lhs.stars == rhs.stars &&
        lhs.metricText == rhs.metricText &&
        lhs.customPayload == rhs.customPayload
    }
}

extension CraftPathNodeModel: Hashable where CustomPayload: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(titleKey)
        hasher.combine(subtitle)
        hasher.combine(subtitleKey)
        hasher.combine(state)
        hasher.combine(shape)
        hasher.combine(surfaceStyle)
        hasher.combine(icon)
        hasher.combine(progress)
        hasher.combine(badgeText)
        hasher.combine(badgeCount)
        hasher.combine(stars)
        hasher.combine(metricText)
        hasher.combine(customPayload)
    }
}

/// Empty default payload for generic journey models when no custom domain payload is needed.
public struct CraftEmptyPayload: Sendable, Equatable, Hashable {
    public init() {}
}

extension CraftPathNodeModel where CustomPayload == CraftEmptyPayload {
    public init(
        id: String,
        title: String,
        titleKey: String? = nil,
        subtitle: String? = nil,
        subtitleKey: String? = nil,
        state: CraftNodeState = .upcoming,
        shape: CraftNodeShape = .circle,
        surfaceStyle: CraftSurfaceStyle = .tactile3D,
        icon: CraftNodeIcon = .system("book.fill"),
        progress: Double? = nil,
        badgeText: String? = nil,
        badgeCount: Int? = nil,
        stars: Int? = nil,
        metricText: String? = nil
    ) {
        self.init(
            id: id,
            title: title,
            titleKey: titleKey,
            subtitle: subtitle,
            subtitleKey: subtitleKey,
            state: state,
            shape: shape,
            surfaceStyle: surfaceStyle,
            icon: icon,
            progress: progress,
            badgeText: badgeText,
            badgeCount: badgeCount,
            stars: stars,
            metricText: metricText,
            customPayload: CraftEmptyPayload()
        )
    }
}

// MARK: - CraftJourneySection

/// Generic presentation model aggregating a module or section with its child journey nodes.
public struct CraftJourneySection<NodePayload: Sendable>: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let titleKey: String?
    public let subtitle: String?
    public let subtitleKey: String?
    public let levelText: String?
    public let levelKey: String?
    public let progressText: String?
    public let progressValue: Double?
    public let bannerIcon: CraftNodeIcon?
    public let nodes: [CraftPathNodeModel<NodePayload>]
    public let winding: SerpentineWinding
    public let connectorStyle: ConnectorStyle
    public let rowPattern: RowPattern

    public init(
        id: String,
        title: String,
        titleKey: String? = nil,
        subtitle: String? = nil,
        subtitleKey: String? = nil,
        levelText: String? = nil,
        levelKey: String? = nil,
        progressText: String? = nil,
        progressValue: Double? = nil,
        bannerIcon: CraftNodeIcon? = nil,
        nodes: [CraftPathNodeModel<NodePayload>],
        winding: SerpentineWinding = .standard,
        connectorStyle: ConnectorStyle = .dashed,
        rowPattern: RowPattern = .standard
    ) {
        self.id = id
        self.title = title
        self.titleKey = titleKey
        self.subtitle = subtitle
        self.subtitleKey = subtitleKey
        self.levelText = levelText
        self.levelKey = levelKey
        self.progressText = progressText
        self.progressValue = progressValue
        self.bannerIcon = bannerIcon
        self.nodes = nodes
        self.winding = winding
        self.connectorStyle = connectorStyle
        self.rowPattern = rowPattern
    }
}

extension CraftJourneySection: Equatable where NodePayload: Equatable {
    public static func == (lhs: CraftJourneySection<NodePayload>, rhs: CraftJourneySection<NodePayload>) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.titleKey == rhs.titleKey &&
        lhs.subtitle == rhs.subtitle &&
        lhs.subtitleKey == rhs.subtitleKey &&
        lhs.levelText == rhs.levelText &&
        lhs.levelKey == rhs.levelKey &&
        lhs.progressText == rhs.progressText &&
        lhs.progressValue == rhs.progressValue &&
        lhs.bannerIcon == rhs.bannerIcon &&
        lhs.nodes == rhs.nodes &&
        lhs.winding == rhs.winding &&
        lhs.connectorStyle == rhs.connectorStyle &&
        lhs.rowPattern == rhs.rowPattern
    }
}

// MARK: - PositionedJourneyNode & JourneyRowLayout

/// A journey node mapped to a specific slot position and global traversal order.
public struct PositionedJourneyNode<NodePayload: Sendable>: Identifiable, Sendable {
    public let node: CraftPathNodeModel<NodePayload>
    public let slot: NodeSlot
    public let traversalIndex: Int

    public var id: String { node.id }

    public init(node: CraftPathNodeModel<NodePayload>, slot: NodeSlot, traversalIndex: Int) {
        self.node = node
        self.slot = slot
        self.traversalIndex = traversalIndex
    }
}

extension PositionedJourneyNode: Equatable where NodePayload: Equatable {
    public static func == (lhs: PositionedJourneyNode<NodePayload>, rhs: PositionedJourneyNode<NodePayload>) -> Bool {
        lhs.node == rhs.node && lhs.slot == rhs.slot && lhs.traversalIndex == rhs.traversalIndex
    }
}

extension PositionedJourneyNode: Hashable where NodePayload: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(node)
        hasher.combine(slot)
        hasher.combine(traversalIndex)
    }
}

/// Layout structure representing a single horizontal row on the journey map.
public struct JourneyRowLayout<NodePayload: Sendable>: Identifiable, Sendable {
    public let id: String
    public let rowIndex: Int
    public let nodes: [PositionedJourneyNode<NodePayload>]

    public init(id: String, rowIndex: Int, nodes: [PositionedJourneyNode<NodePayload>]) {
        self.id = id
        self.rowIndex = rowIndex
        self.nodes = nodes
    }
}

extension JourneyRowLayout: Equatable where NodePayload: Equatable {
    public static func == (lhs: JourneyRowLayout<NodePayload>, rhs: JourneyRowLayout<NodePayload>) -> Bool {
        lhs.id == rhs.id && lhs.rowIndex == rhs.rowIndex && lhs.nodes == rhs.nodes
    }
}

extension JourneyRowLayout: Hashable where NodePayload: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(rowIndex)
        hasher.combine(nodes)
    }
}

// MARK: - RowPattern Journey Layout Extension

extension RowPattern {
    /// Lays out an ordered array of generic journey nodes into snake grid rows with slot assignments and traversal indices.
    public func layoutJourneyRows<Payload: Sendable>(nodes: [CraftPathNodeModel<Payload>]) -> [JourneyRowLayout<Payload>] {
        guard !nodes.isEmpty else { return [] }

        let counts: [Int] = switch self {
        case .standard:
            [1, 2]
        case .wave:
            [1, 2, 3, 2]
        case .custom(let customCounts):
            customCounts.filter { $0 > 0 }.isEmpty ? [1] : customCounts.filter { $0 > 0 }
        }

        var layouts: [JourneyRowLayout<Payload>] = []
        var currentIndex = 0
        var patternIndex = 0
        var rowIndex = 0

        while currentIndex < nodes.count {
            let targetCount = counts[patternIndex % counts.count]
            let endIndex = min(currentIndex + targetCount, nodes.count)
            let rowNodes = Array(nodes[currentIndex..<endIndex])

            let positionedNodes: [PositionedJourneyNode<Payload>]
            switch rowNodes.count {
            case 1:
                positionedNodes = [
                    PositionedJourneyNode(
                        node: rowNodes[0],
                        slot: .center,
                        traversalIndex: currentIndex
                    )
                ]
            case 2:
                let rightNode = PositionedJourneyNode(
                    node: rowNodes[0],
                    slot: .right,
                    traversalIndex: currentIndex
                )
                let leftNode = PositionedJourneyNode(
                    node: rowNodes[1],
                    slot: .left,
                    traversalIndex: currentIndex + 1
                )
                positionedNodes = [leftNode, rightNode]
            case 3:
                let leftNode = PositionedJourneyNode(
                    node: rowNodes[0],
                    slot: .left,
                    traversalIndex: currentIndex
                )
                let centerNode = PositionedJourneyNode(
                    node: rowNodes[1],
                    slot: .center,
                    traversalIndex: currentIndex + 1
                )
                let rightNode = PositionedJourneyNode(
                    node: rowNodes[2],
                    slot: .right,
                    traversalIndex: currentIndex + 2
                )
                positionedNodes = [leftNode, centerNode, rightNode]
            default:
                positionedNodes = rowNodes.enumerated().map { idx, node in
                    let slot: NodeSlot = if idx == 0 { .left } else if idx == rowNodes.count - 1 { .right } else { .center }
                    return PositionedJourneyNode(node: node, slot: slot, traversalIndex: currentIndex + idx)
                }
            }

            layouts.append(JourneyRowLayout(id: "journey_row_\(rowIndex)", rowIndex: rowIndex, nodes: positionedNodes))
            currentIndex = endIndex
            patternIndex += 1
            rowIndex += 1
        }

        return layouts
    }
}
