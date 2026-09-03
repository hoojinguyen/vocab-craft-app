import Foundation
import SwiftUI

/// Horizontal offset sequence helper for arranging nodes along a gentle S-curve in the fluid journey.
public enum FluidJourneyNodeOffset {
    private static let sequence: [CGFloat] = [0, -48, 0, 48]

    /// Calculates the horizontal offset (in points) for a node at the given index.
    /// Clamps negative indices to 0.
    public static func offset(for index: Int) -> CGFloat {
        let pos = max(0, index)
        return sequence[pos % sequence.count]
    }
}

/// Preference key reporting the vertical scroll coordinate (`minY`) of unit milestone pills
/// back to the parent `CraftFluidJourney` container.
public struct FluidJourneyMilestonePreferenceKey: PreferenceKey, Sendable {
    public static var defaultValue: [String: CGFloat] = [:]

    public static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// Progression state for an entire lesson section/unit in the fluid journey curriculum.
public enum FluidJourneySectionState: String, Sendable, CaseIterable, Equatable, Hashable {
    case completed
    case current
    case upcoming

    /// Infers the section progression state based on the states of its child nodes.
    public static func state(for section: LessonSection) -> FluidJourneySectionState {
        if !section.nodes.isEmpty && section.nodes.allSatisfy({ $0.state == .completed }) {
            return .completed
        } else if section.nodes.contains(where: { $0.state == .active || $0.state == .inProgress }) {
            return .current
        } else {
            return .upcoming
        }
    }
}
