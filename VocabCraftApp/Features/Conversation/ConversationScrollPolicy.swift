public struct ConversationScrollPolicy: Sendable {
    private var followsCurrent = true

    public init() {}

    public mutating func markManualScroll() { followsCurrent = false }
    public mutating func returnToCurrent() { followsCurrent = true }
    public func target(for activeTurnID: String?) -> String? {
        followsCurrent ? activeTurnID : nil
    }
}
