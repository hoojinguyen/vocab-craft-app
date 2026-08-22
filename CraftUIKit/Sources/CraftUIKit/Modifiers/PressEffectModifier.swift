import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Press Effect Modifier

/// A view modifier that scales a view down slightly on press with a snappy spring animation
/// and optional tactile haptic feedback.
public struct CraftPressEffectModifier: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @GestureState private var isPressed: Bool = false

    public let scale: CGFloat
    public let hapticFeedback: Bool

    public init(scale: CGFloat = 0.97, hapticFeedback: Bool = false) {
        self.scale = scale
        self.hapticFeedback = hapticFeedback
    }

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(theme.animations.springSnappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        if !state && hapticFeedback {
                            #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            #endif
                        }
                        state = true
                    }
            )
    }
}

// MARK: - View Extension

public extension View {
    /// Applies a tactile press-down spring scaling effect to this view.
    ///
    /// - Parameters:
    ///   - scale: The scale factor applied when pressed (default: 0.97).
    ///   - hapticFeedback: Whether to trigger light haptic feedback on touch down (default: false).
    /// - Returns: A view that animates smoothly on touch press.
    func craftPressEffect(scale: CGFloat = 0.97, hapticFeedback: Bool = false) -> some View {
        modifier(CraftPressEffectModifier(scale: scale, hapticFeedback: hapticFeedback))
    }
}
