import SwiftUI

// MARK: - Surface Style

/// Visual style variants for surfaces across CraftUIKit components.
public enum CraftSurfaceStyle: String, Sendable, CaseIterable {
    /// Minimal flat surface with subtle background color and no elevation.
    case flat
    /// Elevated surface with layered depth shadow and subtle border gradient.
    case elevated
    /// Outlined surface with a crisp border stroke.
    case outlined
    /// Tactile 3D physical surface with extrusion bevel, top specular highlight, and mechanical press depression.
    case tactile3D
    /// Liquid translucent frosted glass surface with material blur, specular border, and light refraction tint.
    case glass
}

// MARK: - Environment Key

/// Environment key for propagating `CraftSurfaceStyle` down the view hierarchy.
public struct CraftSurfaceStyleKey: EnvironmentKey {
    public static let defaultValue: CraftSurfaceStyle = .flat
}

// MARK: - EnvironmentValues Extension

public extension EnvironmentValues {
    /// The surface style applied to views in this environment.
    var craftSurfaceStyle: CraftSurfaceStyle {
        get { self[CraftSurfaceStyleKey.self] }
        set { self[CraftSurfaceStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Sets the surface style for Craft components within this view hierarchy.
    ///
    /// - Parameter style: The `CraftSurfaceStyle` to apply.
    /// - Returns: A view with the modified environment.
    func craftSurfaceStyle(_ style: CraftSurfaceStyle) -> some View {
        environment(\.craftSurfaceStyle, style)
    }
}
