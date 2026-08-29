import Foundation

/// Immutable pre-generated session plan containing sequential drill blueprints.
public struct ReflexDrillSessionPlan: Equatable, Sendable {
    public let id: UUID
    public let mode: ReflexMode
    public let items: [ReflexDrillPlanItem]

    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }

    public init(
        id: UUID = UUID(),
        mode: ReflexMode,
        items: [ReflexDrillPlanItem]
    ) {
        self.id = id
        self.mode = mode
        self.items = items
    }
}
