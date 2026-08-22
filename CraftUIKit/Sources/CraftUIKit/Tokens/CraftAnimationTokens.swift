import SwiftUI

// MARK: - Animation Token Protocol

/// Tactile spring and timing animation tokens.
public protocol CraftAnimationTokens: Sendable {
    /// Snappy spring for quick taps, button presses, chips, and toggles (response: 0.22, dampingFraction: 0.65)
    var springSnappy: Animation { get }
    /// Smooth spring for sheets, modals, cards, and transitions (response: 0.35, dampingFraction: 0.85)
    var springSmooth: Animation { get }
    /// Bouncy spring for celebrations, milestones, and playful feedback (response: 0.45, dampingFraction: 0.55)
    var springBouncy: Animation { get }
}

// MARK: - Default Implementation

/// Default spring animation tokens.
public struct CraftDefaultAnimationTokens: CraftAnimationTokens {
    public var springSnappy: Animation
    public var springSmooth: Animation
    public var springBouncy: Animation

    public init(
        springSnappy: Animation = .spring(response: 0.22, dampingFraction: 0.65),
        springSmooth: Animation = .spring(response: 0.35, dampingFraction: 0.85),
        springBouncy: Animation = .spring(response: 0.45, dampingFraction: 0.55)
    ) {
        self.springSnappy = springSnappy
        self.springSmooth = springSmooth
        self.springBouncy = springBouncy
    }
}
