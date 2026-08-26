import SwiftUI

// MARK: - Motion Guard Modifier

/// A ViewModifier that guards animations against accessibility reduce motion settings.
///
/// When `accessibilityReduceMotion` is enabled, animations are disabled (`.none`),
/// ensuring accessible experiences for users sensitive to motion.
public struct CraftMotionGuardModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public let animation: Animation
    public let value: V

    public init(animation: Animation, value: V) {
        self.animation = animation
        self.value = value
    }

    public func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : animation, value: value)
    }
}

// MARK: - View Extension

public extension View {
    /// Applies an animation to this view that automatically respects the system's `accessibilityReduceMotion` setting.
    ///
    /// - Parameters:
    ///   - animation: The animation to apply when reduce motion is disabled.
    ///   - value: A value to monitor for changes.
    /// - Returns: A view that animates changes to `value` only when reduce motion is disabled.
    func craftAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(CraftMotionGuardModifier(animation: animation, value: value))
    }
}
