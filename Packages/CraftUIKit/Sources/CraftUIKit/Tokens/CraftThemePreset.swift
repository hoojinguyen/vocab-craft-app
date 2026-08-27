import SwiftUI

// MARK: - Craft Theme Preset Enum

/// Standardized theme presets for CraftUIKit and VocabCraftApp.
///
/// Encapsulates the 4 design trend themes with light and dark mode parity.
public enum CraftThemePreset: String, CaseIterable, Identifiable, Sendable {
    case editorial = "editorial"
    case neoArcade = "neo_arcade"
    case nordicZen = "nordic_zen"
    case classic = "classic"

    public var id: String { rawValue }

    /// Human-readable title for UI selectors and settings menus.
    public var displayName: String {
        switch self {
        case .editorial: return "Warm Editorial"
        case .neoArcade: return "Neo-Arcade"
        case .nordicZen: return "Nordic Zen"
        case .classic: return "Classic Slate"
        }
    }

    /// Subtitle describing the design vibe and typography pairing.
    public var subtitle: String {
        switch self {
        case .editorial: return "Linen & Obsidian • New York Serif • Emerald & Apricot"
        case .neoArcade: return "Ice & Cyber Night • SF Rounded • Lime & Indigo"
        case .nordicZen: return "Mist & Graphite • Minimalist • Lavender & Frost"
        case .classic: return "Modern Slate • Rounded • Coral & Amber"
        }
    }

    /// Returns the instantiated `CraftTheme` conforming instance.
    public var theme: any CraftTheme {
        switch self {
        case .editorial:
            return CraftEditorialTheme()
        case .neoArcade:
            return CraftNeoArcadeTheme()
        case .nordicZen:
            return CraftNordicZenTheme()
        case .classic:
            return CraftDefaultTheme()
        }
    }
}
