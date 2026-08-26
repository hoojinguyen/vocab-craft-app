import SwiftUI

// MARK: - Symbol Effect Modifiers

private struct CraftSymbolBounceModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: V

    func body(content: Content) -> some View {
        content
            .symbolEffect(.bounce, value: value)
            .symbolEffectsRemoved(reduceMotion)
    }
}

private struct CraftSymbolPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .symbolEffect(.pulse, isActive: isActive)
            .symbolEffectsRemoved(reduceMotion)
    }
}

private struct CraftSymbolVariableColorModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .symbolEffect(
                .variableColor.iterative.reversing.dimInactiveLayers,
                options: .repeating,
                isActive: isActive
            )
            .symbolEffectsRemoved(reduceMotion)
    }
}

private struct CraftSymbolReplaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .contentTransition(.symbolEffect(.replace.downUp))
            .symbolEffectsRemoved(reduceMotion)
    }
}

// MARK: - View Extension

public extension View {
    /// Applies a bounce symbol effect triggered whenever the provided value changes.
    ///
    /// Automatically disables the effect when `accessibilityReduceMotion` is active.
    ///
    /// - Parameter value: An equatable value whose modification triggers the bounce effect.
    /// - Returns: A view that bounces its SF Symbol contents when `value` changes.
    func craftSymbolBounce<V: Equatable>(value: V) -> some View {
        modifier(CraftSymbolBounceModifier(value: value))
    }

    /// Applies a continuous pulsing symbol effect while active.
    ///
    /// Automatically disables the effect when `accessibilityReduceMotion` is active.
    ///
    /// - Parameter isActive: Whether the pulse animation is running (default: `true`).
    /// - Returns: A view that pulses its SF Symbol contents.
    func craftSymbolPulse(isActive: Bool = true) -> some View {
        modifier(CraftSymbolPulseModifier(isActive: isActive))
    }

    /// Applies an iterative reversing variable color symbol effect while active.
    ///
    /// Useful for microphone recording, audio levels, speaker waves, and connectivity indicators.
    /// Automatically disables the effect when `accessibilityReduceMotion` is active.
    ///
    /// - Parameter isActive: Whether the variable color animation is running (default: `true`).
    /// - Returns: A view with animated variable color layers.
    func craftSymbolVariableColor(isActive: Bool = true) -> some View {
        modifier(CraftSymbolVariableColorModifier(isActive: isActive))
    }

    /// Configures a down-up SF Symbol replacement transition for dynamic symbol changes.
    ///
    /// Automatically disables the transition effect when `accessibilityReduceMotion` is active.
    ///
    /// - Returns: A view configured with a down-up symbol replacement transition.
    func craftSymbolReplace() -> some View {
        modifier(CraftSymbolReplaceModifier())
    }
}
