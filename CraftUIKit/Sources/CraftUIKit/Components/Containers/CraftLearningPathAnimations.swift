import SwiftUI

// MARK: - Breathing Phase

/// Phase states for continuous breathing path animation on connectors.
public enum BreathingPhase: String, CaseIterable, Sendable, Equatable, Hashable {
    case rest
    case inhale
}

// MARK: - Glow Phase

/// Phase states for continuous pulsing glow animation on active lesson nodes.
public enum GlowPhase: String, CaseIterable, Sendable, Equatable, Hashable {
    case normal
    case glowing
}

// MARK: - Animation Extensions

public extension Animation {
    /// Easing animation used for continuous breathing path oscillation on active connectors.
    static var craftBreathing: Animation {
        .easeInOut(duration: 1.8)
    }

    /// Easing animation used for continuous glowing pulse on active lesson nodes.
    static var craftGlow: Animation {
        .easeInOut(duration: 1.5)
    }
}
