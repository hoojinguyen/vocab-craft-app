import Foundation
import SwiftUI

// MARK: - LessonNodeState

/// Visual and progression state for an individual lesson node in the learning path.
public enum LessonNodeState: String, Sendable, Equatable, Hashable, CaseIterable {
    case completed      // Finished — checkmark, statusSuccess
    case active         // Current lesson — large glow ring, brandPrimary, pulsing
    case inProgress     // Started not finished — progress ring overlay
    case upcoming       // Next available — gray, tappable but muted
    case locked         // Not unlocked — padlock, dimmed, not tappable
    case bonus          // Optional/reward — gold accent, star badge
}

// MARK: - LessonNodeKind

/// Semantic type/tier of a lesson node in the tactile learning path.
public enum LessonNodeKind: String, Sendable, Equatable, Hashable, CaseIterable {
    case standard       // Standard circular lesson node
    case checkpoint     // Mid-unit or boss exam node
    case treasureChest  // End-of-unit milestone reward chest
}

// MARK: - LessonNodeModel

/// Presentation DTO representing a single lesson node within a learning path section.
public struct LessonNodeModel: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let iconName: String
    public let state: LessonNodeState
    public let kind: LessonNodeKind
    public let progress: Double?
    public let xpReward: Int?
    public let estimatedMinutes: Int?
    public let stars: Int?
    public let badgeCount: Int?
    public let badgeText: String?

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
        badgeText: String? = nil
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
    case gradient(from: Color, to: Color)   // Gradient fill along path
    case animated                           // Flowing dots animation
}

// MARK: - LessonSection

/// Presentation DTO aggregating a discrete module or unit with its child nodes, winding layout, and connector styling.
public struct LessonSection: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let level: String?
    public let progressText: String?
    public let progressValue: Double?
    public let bannerIcon: String?
    public let nodes: [LessonNodeModel]
    public let winding: SerpentineWinding
    public let connectorStyle: ConnectorStyle

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
        connectorStyle: ConnectorStyle = .dashed
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
    ///
    /// - Parameter nodes: The lesson nodes to partition.
    /// - Returns: An array of tuples containing the row's nodes and the calculated `LessonRowArrangement`.
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
}

// MARK: - LessonRowArrangement

/// Horizontal layout arrangement configuration for a single row in the learning path.
public enum LessonRowArrangement: Sendable, Equatable {
    case single             // 1 node, centered
    case pair               // 2 nodes, spread left-right
    case triple             // 3 nodes, evenly distributed
}

