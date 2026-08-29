import SwiftUI

// MARK: - Craft Theme Preset Enum

/// Standardized theme presets for CraftUIKit and VocabCraftApp.
///
/// Encapsulates the 4 design trend themes with light and dark mode parity.
public enum CraftThemePreset: String, CaseIterable, Identifiable, Sendable {
    case kyotoMatcha = "kyoto_matcha"
    case aiAcoustic = "ai_acoustic"
    case oxfordHeritage = "oxford_heritage"
    case solarMomentum = "solar_momentum"
    case tactileClay = "tactile_clay"
    case editorial = "editorial"
    case neoArcade = "neo_arcade"
    case nordicZen = "nordic_zen"
    case playfulOwl = "playful_owl"
    case smartCoach = "smart_coach"
    case classic = "classic"

    public var id: String { rawValue }

    /// Human-readable title for UI selectors and settings menus.
    public var displayName: String {
        switch self {
        case .kyotoMatcha: return "Kyoto Matcha Zen"
        case .aiAcoustic: return "AI Acoustic Obsidian"
        case .oxfordHeritage: return "Oxford Heritage"
        case .solarMomentum: return "Solar Momentum"
        case .tactileClay: return "Tactile Clay Mochi"
        case .editorial: return "Warm Editorial"
        case .neoArcade: return "Neo-Arcade"
        case .nordicZen: return "Nordic Zen"
        case .playfulOwl: return "Playful Owl"
        case .smartCoach: return "Smart Coach"
        case .classic: return "Classic Slate"
        }
    }

    /// Subtitle describing the design vibe and typography pairing.
    public var subtitle: String {
        switch self {
        case .kyotoMatcha: return "Oatmeal Milk & Hinoki • Matcha Sage • Yuzu Gold"
        case .aiAcoustic: return "Obsidian & Cyber Glow • Sonic Cobalt • Waveforms"
        case .oxfordHeritage: return "Ivory & Midnight • Oxford Navy • Wax Seal Gold"
        case .solarMomentum: return "Solar Sand & Midnight • Coral Fire • Sunset Amber"
        case .tactileClay: return "Sesame & Truffle • Terracotta Clay • Pistachio"
        case .editorial: return "Linen & Obsidian • New York Serif • Deep Teal"
        case .neoArcade: return "Ice & Cyber Night • SF Rounded • Lime & Indigo"
        case .nordicZen: return "Mist & Graphite • Minimalist • Lavender & Frost"
        case .playfulOwl: return "Snow & Warm Gray • Rounded • Feather Green & Macaw"
        case .smartCoach: return "Pure & Deep Dark • Geometric Sans • ELSA Blue & Teal"
        case .classic: return "Modern Slate • Rounded • Coral & Amber"
        }
    }

    /// Returns the instantiated `CraftTheme` conforming instance.
    public var theme: any CraftTheme {
        switch self {
        case .kyotoMatcha:
            return CraftKyotoMatchaTheme()
        case .aiAcoustic:
            return CraftAIAcousticTheme()
        case .oxfordHeritage:
            return CraftOxfordHeritageTheme()
        case .solarMomentum:
            return CraftSolarMomentumTheme()
        case .tactileClay:
            return CraftTactileClayTheme()
        case .editorial:
            return CraftEditorialTheme()
        case .neoArcade:
            return CraftNeoArcadeTheme()
        case .nordicZen:
            return CraftNordicZenTheme()
        case .playfulOwl:
            return CraftPlayfulOwlTheme()
        case .smartCoach:
            return CraftSmartCoachTheme()
        case .classic:
            return CraftDefaultTheme()
        }
    }
}
