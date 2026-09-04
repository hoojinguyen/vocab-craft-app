import Foundation
import SwiftUI

// MARK: - LessonNodeState

/// Visual and progression state for an individual lesson node in the learning path.
public typealias LessonNodeState = CraftNodeState

// MARK: - LessonNodeKind

/// Semantic type/tier of a lesson node in the tactile learning path.
public enum LessonNodeKind: String, Sendable, Equatable, Hashable, CaseIterable {
    case standard       // Standard circular lesson node
    case checkpoint     // Mid-unit or boss exam node
    case treasureChest  // End-of-unit milestone reward chest
}

// MARK: - LessonNodePayload

/// Payload carried by lesson nodes when mapped onto generic journey models.
public struct LessonNodePayload: Sendable, Equatable, Hashable {
    public let xpReward: Int?
    public let estimatedMinutes: Int?
    public let kind: LessonNodeKind

    public init(xpReward: Int? = nil, estimatedMinutes: Int? = nil, kind: LessonNodeKind = .standard) {
        self.xpReward = xpReward
        self.estimatedMinutes = estimatedMinutes
        self.kind = kind
    }
}

// MARK: - LessonNodeModel

/// Presentation DTO representing a single lesson node within a learning path section.
public struct LessonNodeModel: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let iconName: String
    public var state: LessonNodeState
    public let kind: LessonNodeKind
    public let progress: Double?
    public let xpReward: Int?
    public let estimatedMinutes: Int?
    public var stars: Int?
    public let badgeCount: Int?
    public var badgeText: String?
    public let objectives: [String]?
    public let objectiveKeys: [String]?

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        iconName: String = "book.fill",
        state: LessonNodeState = .upcoming,
        kind: LessonNodeKind = .standard,
        progress: Double? = nil,
        xpReward: Int? = nil,
        estimatedMinutes: Int? = nil,
        stars: Int? = nil,
        badgeCount: Int? = nil,
        badgeText: String? = nil,
        objectives: [String]? = nil,
        objectiveKeys: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.state = state
        self.kind = kind
        self.progress = progress
        self.xpReward = xpReward
        self.estimatedMinutes = estimatedMinutes
        self.stars = stars
        self.badgeCount = badgeCount
        self.badgeText = badgeText
        self.objectives = objectives
        self.objectiveKeys = objectiveKeys
    }

    /// Converts to generic `CraftPathNodeModel`.
    public var asPathNode: CraftPathNodeModel<LessonNodePayload> {
        let shape: CraftNodeShape = switch kind {
        case .checkpoint: .hexagon
        case .standard, .treasureChest: .circle
        }
        let metricText: String? = if let xp = xpReward {
            "Reward: \(xp) XP"
        } else {
            nil
        }
        return CraftPathNodeModel(
            id: id,
            title: title,
            subtitle: subtitle,
            state: state,
            shape: shape,
            surfaceStyle: .tactile3D,
            icon: CraftNodeIcon(name: iconName, isSystem: true),
            progress: progress,
            badgeText: badgeText,
            badgeCount: badgeCount,
            stars: stars,
            metricText: metricText,
            customPayload: LessonNodePayload(xpReward: xpReward, estimatedMinutes: estimatedMinutes, kind: kind)
        )
    }
}

// MARK: - SerpentineWinding

/// Continuous horizontal winding layout algorithm for serpentine path node positioning.
public enum SerpentineWinding: Sendable, Equatable, Hashable {
    case standard           // Sequence: [0.0, -0.40, -0.55, -0.25, 0.0, 0.25, 0.55, 0.40]
    case gentle             // Sequence: [0.0, -0.25, -0.35, -0.15, 0.0, 0.15, 0.35, 0.25]
    case linear             // Sequence: [0.0]
    case custom([CGFloat])  // User-defined offset ratios (-1.0 to 1.0)

    /// Calculates the horizontal offset ratio (-1.0 to 1.0) relative to column center for a node at a given index.
    public func offsetRatio(for index: Int) -> CGFloat {
        let sequence: [CGFloat] = switch self {
        case .standard:
            [0.0, -0.40, -0.55, -0.25, 0.0, 0.25, 0.55, 0.40]
        case .gentle:
            [0.0, -0.25, -0.35, -0.15, 0.0, 0.15, 0.35, 0.25]
        case .linear:
            [0.0]
        case .custom(let customSeq):
            customSeq.isEmpty ? [0.0] : customSeq
        }
        let positiveIndex = max(0, index)
        return sequence[positiveIndex % sequence.count]
    }
}

// MARK: - SmartConnectorStyle

/// Contextual connection style inferred dynamically between adjacent nodes on the learning path.
public enum SmartConnectorStyle: String, Sendable, Equatable, Hashable, CaseIterable {
    case solid
    case breathing
    case dashed
    case muted

    /// Automatically infers the connector style linking two sequential lesson nodes based on their states.
    public static func infer(from fromState: LessonNodeState, to toState: LessonNodeState) -> SmartConnectorStyle {
        switch (fromState, toState) {
        case (.completed, .completed):
            return .solid
        case (.completed, .active), (.completed, .inProgress):
            return .breathing
        case (.active, .upcoming), (.active, .bonus), (.inProgress, .upcoming), (.inProgress, .bonus):
            return .dashed
        default:
            return .muted
        }
    }
}

// MARK: - ConnectorStyle

/// Visual styling applied to the Bézier connectors linking lesson nodes.
public enum ConnectorStyle: Sendable, Equatable {
    case dashed                             // Dotted/dashed line (default)
    case solid                              // Continuous solid line
    // swiftlint:disable:next identifier_name
    case gradient(from: Color, to: Color)   // Gradient fill along path
    case animated                           // Flowing dots animation
}

// MARK: - LessonSection

/// Presentation DTO aggregating a discrete module or unit with its child nodes, winding layout, connector styling, and snake row pattern.
public struct LessonSection: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let level: String?
    public var progressText: String?
    public var progressValue: Double?
    public let bannerIcon: String?
    public var nodes: [LessonNodeModel]
    public let winding: SerpentineWinding
    public let connectorStyle: ConnectorStyle
    public let rowPattern: RowPattern

    /// Backward-compatibility accessor for `progressText`.
    public var progress: String? {
        progressText
    }

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        level: String? = nil,
        progress: String? = nil,
        progressText: String? = nil,
        progressValue: Double? = nil,
        bannerIcon: String? = nil,
        nodes: [LessonNodeModel],
        winding: SerpentineWinding = .standard,
        connectorStyle: ConnectorStyle = .dashed,
        rowPattern: RowPattern = .standard
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.level = level
        self.progressText = progressText ?? progress
        self.progressValue = progressValue
        self.bannerIcon = bannerIcon
        self.nodes = nodes
        self.winding = winding
        self.connectorStyle = connectorStyle
        self.rowPattern = rowPattern
    }

    /// Converts to generic `CraftJourneySection`.
    public var asJourneySection: CraftJourneySection<LessonNodePayload> {
        CraftJourneySection(
            id: id,
            title: title,
            subtitle: subtitle,
            levelText: level,
            progressText: progressText,
            progressValue: progressValue,
            bannerIcon: bannerIcon.map { CraftNodeIcon(name: $0, isSystem: true) },
            nodes: nodes.map(\.asPathNode),
            winding: winding,
            connectorStyle: connectorStyle,
            rowPattern: rowPattern
        )
    }
}

// MARK: - RowPattern

/// Layout pattern determining how sequential lesson nodes are grouped across rows.
public enum RowPattern: Sendable, Equatable {
    case standard           // [1, 2, 1, 2, ...]
    case wave               // [1, 2, 3, 2, 1, 2, 3, ...]
    case custom([Int])      // User-defined row counts

    /// Splits an ordered array of lesson nodes into discrete rows, pairing each row slice
    /// with its corresponding horizontal layout arrangement.
    public func split(nodes: [LessonNodeModel]) -> [(nodes: [LessonNodeModel], arrangement: LessonRowArrangement)] {
        guard !nodes.isEmpty else { return [] }

        let counts: [Int] = switch self {
        case .standard:
            [1, 2]
        case .wave:
            [1, 2, 3, 2]
        case .custom(let customCounts):
            customCounts.filter { $0 > 0 }.isEmpty ? [1] : customCounts.filter { $0 > 0 }
        }

        var result: [(nodes: [LessonNodeModel], arrangement: LessonRowArrangement)] = []
        var currentIndex = 0
        var patternIndex = 0

        while currentIndex < nodes.count {
            let targetCount = counts[patternIndex % counts.count]
            let endIndex = min(currentIndex + targetCount, nodes.count)
            let rowNodes = Array(nodes[currentIndex..<endIndex])

            let arrangement: LessonRowArrangement = switch rowNodes.count {
            case 1: .single
            case 2: .pair
            default: .triple
            }

            result.append((nodes: rowNodes, arrangement: arrangement))
            currentIndex = endIndex
            patternIndex += 1
        }

        return result
    }

    /// Lays out an ordered array of lesson nodes into snake grid rows with slot assignments and traversal indices.
    public func layoutRows(nodes: [LessonNodeModel]) -> [SnakeRowLayout] {
        guard !nodes.isEmpty else { return [] }

        let counts: [Int] = switch self {
        case .standard:
            [1, 2]
        case .wave:
            [1, 2, 3, 2]
        case .custom(let customCounts):
            customCounts.filter { $0 > 0 }.isEmpty ? [1] : customCounts.filter { $0 > 0 }
        }

        var layouts: [SnakeRowLayout] = []
        var currentIndex = 0
        var patternIndex = 0
        var rowIndex = 0

        while currentIndex < nodes.count {
            let targetCount = counts[patternIndex % counts.count]
            let endIndex = min(currentIndex + targetCount, nodes.count)
            let rowNodes = Array(nodes[currentIndex..<endIndex])

            let positionedNodes: [PositionedLessonNode]
            switch rowNodes.count {
            case 1:
                positionedNodes = [
                    PositionedLessonNode(
                        node: rowNodes[0],
                        slot: .center,
                        traversalIndex: currentIndex
                    )
                ]
            case 2:
                let rightNode = PositionedLessonNode(
                    node: rowNodes[0],
                    slot: .right,
                    traversalIndex: currentIndex
                )
                let leftNode = PositionedLessonNode(
                    node: rowNodes[1],
                    slot: .left,
                    traversalIndex: currentIndex + 1
                )
                positionedNodes = [leftNode, rightNode]
            case 3:
                let leftNode = PositionedLessonNode(
                    node: rowNodes[0],
                    slot: .left,
                    traversalIndex: currentIndex
                )
                let centerNode = PositionedLessonNode(
                    node: rowNodes[1],
                    slot: .center,
                    traversalIndex: currentIndex + 1
                )
                let rightNode = PositionedLessonNode(
                    node: rowNodes[2],
                    slot: .right,
                    traversalIndex: currentIndex + 2
                )
                positionedNodes = [leftNode, centerNode, rightNode]
            default:
                positionedNodes = rowNodes.enumerated().map { idx, node in
                    let slot: NodeSlot = if idx == 0 { .left } else if idx == rowNodes.count - 1 { .right } else { .center }
                    return PositionedLessonNode(node: node, slot: slot, traversalIndex: currentIndex + idx)
                }
            }

            layouts.append(SnakeRowLayout(id: "row_\(rowIndex)", rowIndex: rowIndex, nodes: positionedNodes))
            currentIndex = endIndex
            patternIndex += 1
            rowIndex += 1
        }

        return layouts
    }
}

// MARK: - LessonRowArrangement

/// Horizontal layout arrangement configuration for a single row in the learning path.
public enum LessonRowArrangement: Sendable, Equatable {
    case single             // 1 node, centered
    case pair               // 2 nodes, spread left-right
    case triple             // 3 nodes, evenly distributed
}

// MARK: - NodeSlot

/// Semantic horizontal slot position of a lesson node within a snake learning path row.
public enum NodeSlot: String, Sendable, Equatable, Hashable, CaseIterable {
    case center
    case left
    case right

    /// Horizontal anchor ratio (0.0 to 1.0) relative to container width.
    public var xRatio: CGFloat {
        switch self {
        case .left: 0.26
        case .center: 0.50
        case .right: 0.74
        }
    }
}

// MARK: - PositionedLessonNode

/// A lesson node mapped to a specific slot position and global traversal order.
public struct PositionedLessonNode: Identifiable, Sendable, Equatable, Hashable {
    public let node: LessonNodeModel
    public let slot: NodeSlot
    public let traversalIndex: Int

    public var id: String { node.id }

    public init(node: LessonNodeModel, slot: NodeSlot, traversalIndex: Int) {
        self.node = node
        self.slot = slot
        self.traversalIndex = traversalIndex
    }
}

// MARK: - SnakeRowLayout

/// Layout structure representing a single horizontal row on the snake journey map.
public struct SnakeRowLayout: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let rowIndex: Int
    public let nodes: [PositionedLessonNode]

    public init(id: String, rowIndex: Int, nodes: [PositionedLessonNode]) {
        self.id = id
        self.rowIndex = rowIndex
        self.nodes = nodes
    }
}
