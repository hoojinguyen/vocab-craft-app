import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Native ButtonStyle for Smooth Press Scaling

/// A clean, native `ButtonStyle` that handles press down scaling without capturing parent `ScrollView` drag gestures.
public struct CraftInteractiveButtonStyle: ButtonStyle {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let scale: CGFloat
    public let opacity: Double

    public init(scale: CGFloat = 0.97, opacity: Double = 1.0) {
        self.scale = scale
        self.opacity = opacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(theme.animations.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - ButtonStyle Extension

public extension ButtonStyle where Self == CraftInteractiveButtonStyle {
    /// Convenience helper for applying the native Craft interactive press button style.
    static func craftPress(scale: CGFloat = 0.97, opacity: Double = 1.0) -> CraftInteractiveButtonStyle {
        CraftInteractiveButtonStyle(scale: scale, opacity: opacity)
    }
}

// MARK: - Press Effect Modifier (Backward Compatibility)

/// A view modifier that applies press scaling, respecting reduceMotion and avoiding gesture conflicts.
public struct CraftPressEffectModifier: ViewModifier {
    public let scale: CGFloat
    public let opacity: Double
    public let hapticFeedback: Bool

    public init(scale: CGFloat = 0.97, opacity: Double = 1.0, hapticFeedback: Bool = false) {
        self.scale = scale
        self.opacity = opacity
        self.hapticFeedback = hapticFeedback
    }

    public func body(content: Content) -> some View {
        Button(action: {}) {
            content
        }
        .buttonStyle(CraftInteractiveButtonStyle(scale: scale, opacity: opacity))
    }
}

// MARK: - View Extension

public extension View {
    /// Applies a tactile press-down spring scaling effect to this view using a native ButtonStyle.
    ///
    /// - Parameters:
    ///   - scale: The scale factor applied when pressed (default: 0.97).
    ///   - opacity: The opacity applied when pressed (default: 1.0).
    ///   - hapticFeedback: Retained for backward compatibility (default: false).
    /// - Returns: A view that animates smoothly on touch press without blocking scroll gestures.
    func craftPressEffect(
        scale: CGFloat = 0.97,
        opacity: Double = 1.0,
        hapticFeedback: Bool = false
    ) -> some View {
        Button(action: {}) {
            self
        }
        .buttonStyle(.craftPress(scale: scale, opacity: opacity))
    }
}

#if canImport(PreviewsMacros)
#Preview("PressEffectModifier") {
    VStack(spacing: 32) {
        Button { } label: {
            Text(verbatim: "Default Press Effect")
        }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .craftPressEffect()
            
        Button { } label: {
            Text(verbatim: "Heavy Scale Press Effect")
        }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .craftPressEffect(scale: 0.85, opacity: 0.8)
    }
    .padding()
}
#endif
