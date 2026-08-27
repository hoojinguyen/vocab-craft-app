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

    public var preferredColorScheme: ColorScheme? {
        didSet {
            if let preferredColorScheme {
                UserDefaults.standard.set(preferredColorScheme == .dark ? "dark" : "light", forKey: "app_color_scheme")
            } else {
                UserDefaults.standard.removeObject(forKey: "app_color_scheme")
            }
        }
    }

    public init() {
        let savedPreset = UserDefaults.standard.string(forKey: "app_theme_preset") ?? CraftThemePreset.editorial.rawValue
        self.currentPreset = CraftThemePreset(rawValue: savedPreset) ?? .editorial

        if let savedScheme = UserDefaults.standard.string(forKey: "app_color_scheme") {
            self.preferredColorScheme = savedScheme == "dark" ? .dark : (savedScheme == "light" ? .light : nil)
        } else {
            self.preferredColorScheme = nil
        }
    }

    public func setPreset(_ preset: CraftThemePreset) {
        self.currentPreset = preset
    }

    public func setColorScheme(_ scheme: ColorScheme?) {
        self.preferredColorScheme = scheme
    }
}

/// Convenience type alias for application-level theme manager.
public typealias AppThemeManager = CraftThemeManager
