import SwiftUI

// MARK: - Craft Theme Manager

/// Manages application-wide theme selection, persistence, and appearance modes.
@Observable
public final class CraftThemeManager: @unchecked Sendable {
    public static let shared = CraftThemeManager()

    public var currentPreset: CraftThemePreset {
        didSet {
            UserDefaults.standard.set(currentPreset.rawValue, forKey: "app_theme_preset")
        }
    }

    public var appearanceMode: CraftAppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "app_appearance_mode")
        }
    }

    public var preferredColorScheme: ColorScheme? {
        appearanceMode.colorScheme
    }

    public init() {
        let savedPreset = UserDefaults.standard.string(forKey: "app_theme_preset") ?? CraftThemePreset.editorial.rawValue
        self.currentPreset = CraftThemePreset(rawValue: savedPreset) ?? .editorial

        let savedAppearance = UserDefaults.standard.string(forKey: "app_appearance_mode")
            ?? UserDefaults.standard.string(forKey: "app_theme")
            ?? UserDefaults.standard.string(forKey: "app_color_scheme")
            ?? CraftAppearanceMode.system.rawValue
        self.appearanceMode = CraftAppearanceMode(rawValue: savedAppearance) ?? .system
    }

    public func setPreset(_ preset: CraftThemePreset) {
        self.currentPreset = preset
    }

    public func setAppearanceMode(_ mode: CraftAppearanceMode) {
        self.appearanceMode = mode
    }

    public func setColorScheme(_ scheme: ColorScheme?) {
        switch scheme {
        case .none:
            self.appearanceMode = .system
        case .some(.light):
            self.appearanceMode = .light
        case .some(.dark):
            self.appearanceMode = .dark
        @unknown default:
            self.appearanceMode = .system
        }
    }
}

/// Convenience type alias for application-level theme manager.
public typealias AppThemeManager = CraftThemeManager
