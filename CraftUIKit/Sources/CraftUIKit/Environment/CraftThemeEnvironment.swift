import SwiftUI

// MARK: - Environment Key

private struct CraftThemeKey: EnvironmentKey {
    static let defaultValue: any CraftTheme = CraftDefaultTheme()
}

// MARK: - Environment Values Extension

public extension EnvironmentValues {
    /// The current theme in the environment.
    var craftTheme: any CraftTheme {
        get { self[CraftThemeKey.self] }
        set { self[CraftThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Injects a `CraftTheme` into the SwiftUI environment for this view hierarchy.
    ///
    /// - Parameter theme: A theme conforming to `CraftTheme`.
    /// - Returns: A view configured with the provided theme.
    func craftTheme(_ theme: any CraftTheme) -> some View {
        environment(\.craftTheme, theme)
    }
}
