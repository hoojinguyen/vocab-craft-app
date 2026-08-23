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

// MARK: - LessonNodeModel

/// Presentation DTO representing a single lesson node within a learning path section.
public struct LessonNodeModel: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let iconName: String
    public let state: LessonNodeState
    public let progress: Double?
    public let badgeCount: Int?
    public let badgeText: String?

    public init(
        id: String,
        title: String,
        iconName: String,
        state: LessonNodeState,
        progress: Double? = nil,
        badgeCount: Int? = nil,
        badgeText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.state = state
        self.progress = progress
        self.badgeCount = badgeCount
        self.badgeText = badgeText
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

/// Presentation DTO aggregating a discrete module or unit with its child nodes and connector styling.
public struct LessonSection: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let level: String?
    public let progress: String?
    public let nodes: [LessonNodeModel]
    public let connectorStyle: ConnectorStyle

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        level: String? = nil,
        progress: String? = nil,
        nodes: [LessonNodeModel],
        connectorStyle: ConnectorStyle = .dashed
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.level = level
        self.progress = progress
        self.nodes = nodes
        self.connectorStyle = connectorStyle
    }
}

// MARK: - RowPattern

/// Layout pattern determining how sequential lesson nodes are grouped across rows.
public enum RowPattern: Sendable, Equatable {
    case standard           // [1, 2, 1, 2, ...]
    case wave               // [1, 2, 3, 2, 1, 2, 3, ...]
    case custom([Int])      // User-defined row counts
}

// MARK: - LessonRowArrangement

/// Horizontal layout arrangement configuration for a single row in the learning path.
public enum LessonRowArrangement: Sendable, Equatable {
    case single             // 1 node, centered
    case pair               // 2 nodes, spread left-right
    case triple             // 3 nodes, evenly distributed
}
