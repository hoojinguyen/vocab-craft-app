import SwiftUI

// MARK: - Animation Token Protocol

/// Tactile spring and timing animation tokens.
public protocol CraftAnimationTokens: Sendable {
    /// Snappy spring for quick taps, button presses, chips, and toggles (0.22s, damping: 0.68)
    var springSnappy: Animation { get }
    /// Smooth spring for sheets, modals, cards, and transitions (0.35s, damping: 0.85)
    var springSmooth: Animation { get }
    /// Bouncy spring for celebrations, milestones, and playful feedback (0.42s, damping: 0.58)
    var springBouncy: Animation { get }
    /// Gentle spring for auto-scroll, camera panning, and layout re-arrangement (0.55s, damping: 0.90)
    var springGentle: Animation { get }
    /// Interactive spring tracking real-time finger gestures and drags (0.15s, damping: 0.82)
    var springInteractive: Animation { get }
}

public extension CraftAnimationTokens {
    var springGentle: Animation {
        .spring(response: 0.55, dampingFraction: 0.90)
    }
    var springInteractive: Animation {
        .spring(response: 0.15, dampingFraction: 0.82)
    }
}

// MARK: - Default Implementation

/// Default spring animation tokens.
public struct CraftDefaultAnimationTokens: CraftAnimationTokens {
    public var springSnappy: Animation
    public var springSmooth: Animation
    public var springBouncy: Animation
    public var springGentle: Animation
    public var springInteractive: Animation

    public init(
        springSnappy: Animation = .spring(response: 0.22, dampingFraction: 0.68),
        springSmooth: Animation = .spring(response: 0.35, dampingFraction: 0.85),
        springBouncy: Animation = .spring(response: 0.42, dampingFraction: 0.58),
        springGentle: Animation = .spring(response: 0.55, dampingFraction: 0.90),
        springInteractive: Animation = .spring(response: 0.15, dampingFraction: 0.82)
    ) {
        self.springSnappy = springSnappy
        self.springSmooth = springSmooth
        self.springBouncy = springBouncy
        self.springGentle = springGentle
        self.springInteractive = springInteractive
    }
}
