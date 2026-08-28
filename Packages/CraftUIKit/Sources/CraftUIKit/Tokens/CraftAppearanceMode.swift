import SwiftUI

/// Standardized appearance modes for CraftUIKit and VocabCraftApp.
public enum CraftAppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    /// Maps to SwiftUI `ColorScheme?` (nil for system default).
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
