import SwiftUI

// MARK: - Typography Modifier

/// A view modifier that applies standardized typography font styling based on the active `CraftTheme`.
public struct CraftTypographyModifier: ViewModifier {
    @Environment(\.craftTheme) private var theme

    public let style: CraftTypographyStyle

    public init(_ style: CraftTypographyStyle) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .font(theme.typography.font(for: style))
    }
}

// MARK: - View Extension

public extension View {
    /// Applies a standard `CraftTypographyStyle` font defined in the current `CraftTheme`.
    ///
    /// - Parameter style: The typography style to apply (e.g. `.displayLarge`, `.bodyMedium`, `.caption`).
    /// - Returns: A view rendered with the designated font style.
    func craftTypography(_ style: CraftTypographyStyle) -> some View {
        modifier(CraftTypographyModifier(style))
    }
}
