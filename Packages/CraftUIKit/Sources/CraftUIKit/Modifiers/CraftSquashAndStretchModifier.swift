import SwiftUI

// MARK: - Squash & Stretch Keyframe Physics Values

/// Animatable physics values for squash-and-stretch micro-interactions.
public struct SquashValues: Equatable, Sendable {
    public var scaleX: Double = 1.0
    public var scaleY: Double = 1.0
    public var yOffset: Double = 0.0

    public init(scaleX: Double = 1.0, scaleY: Double = 1.0, yOffset: Double = 0.0) {
        self.scaleX = scaleX
        self.scaleY = scaleY
        self.yOffset = yOffset
    }
}

// MARK: - Craft Squash & Stretch ViewModifier

/// A ViewModifier that applies physics-based keyframe squash-and-stretch feedback when triggered.
///
/// Automatically bypasses keyframe motion when `accessibilityReduceMotion` is active.
public struct CraftSquashAndStretchModifier<T: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public let trigger: T

    public init(trigger: T) {
        self.trigger = trigger
    }

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .keyframeAnimator(
                    initialValue: SquashValues(),
                    trigger: trigger
                ) { view, value in
                    view
                        .scaleEffect(x: value.scaleX, y: value.scaleY)
                        .offset(y: value.yOffset)
                } keyframes: { _ in
                    KeyframeTrack(\.scaleX) {
                        SpringKeyframe(1.08, duration: 0.12)
                        SpringKeyframe(0.95, duration: 0.15)
                        CubicKeyframe(1.0, duration: 0.10)
                    }
                    KeyframeTrack(\.scaleY) {
                        SpringKeyframe(0.92, duration: 0.12)
                        SpringKeyframe(1.06, duration: 0.15)
                        CubicKeyframe(1.0, duration: 0.10)
                    }
                    KeyframeTrack(\.yOffset) {
                        SpringKeyframe(3.0, duration: 0.12)
                        SpringKeyframe(-2.0, duration: 0.15)
                        CubicKeyframe(0.0, duration: 0.10)
                    }
                }
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Applies playful keyframe-based squash and stretch physics whenever the trigger changes.
    ///
    /// Respects the `accessibilityReduceMotion` environment property.
    ///
    /// - Parameter trigger: An equatable value that triggers the squash-and-stretch cycle upon modification.
    /// - Returns: A modified view that performs squash-and-stretch keyframe animations.
    func craftSquashAndStretch<T: Equatable>(trigger: T) -> some View {
        modifier(CraftSquashAndStretchModifier(trigger: trigger))
    }
}
