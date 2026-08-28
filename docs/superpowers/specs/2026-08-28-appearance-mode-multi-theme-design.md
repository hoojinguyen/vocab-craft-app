# Appearance Mode & Multi-Theme Architecture Specification

**Date**: 2026-08-28  
**Status**: Approved / Draft Spec  
**Target Subsystems**: `CraftUIKit` (Tokens, ThemeManager, Dynamic Colors, Modifiers), `VocabCraftApp` (UserSettingsStore, App Root Hierarchy, SettingsView)

---

## 1. Overview & Problem Statement

### 1.1 Current Issues
1. **Broken Appearance Mode Switching**:
   - In `SettingsView.swift`, toggling Dark / Light / System updates `UserSettingsStore.appTheme` (persisted under `"app_theme"` key).
   - `UserSettingsStore.appTheme` does not notify or call `CraftThemeManager.shared.setColorScheme(...)` or update `CraftThemeManager.shared.preferredColorScheme`.
   - `VocabCraftApp.swift` binds `WindowGroup`'s `.preferredColorScheme` to `CraftThemeManager.shared.preferredColorScheme` (persisted under `"app_color_scheme"` key).
   - Because `CraftThemeManager` is never updated when changing settings, the root app window remains stuck in the system scheme.
2. **Fragmented Scheme Modifiers**:
   - `HomepageView.swift` has a redundant `.preferredColorScheme(appContainer.userSettingsStore.colorScheme)` modifier, causing potential trait hierarchy conflicts with the root `WindowGroup` and nested modal sheets (`SettingsView`, `CraftCatalogView`, `ProfileStatsSheet`, etc.).
3. **Theme Consistency & Light/Dark Parity**:
   - `CraftDefaultTheme` / `CraftDefaultColorTokens` has several static non-dynamic colors (e.g. `brandPrimary`, `brandSecondary`, `accent`), whereas the other 8 themes have full `.craftDynamic(light:dark:)` setups.
   - All 9 themes need strict verification of color contrast, surface luminance, and token completeness in both Light and Dark modes.

---

## 2. Architectural Design

```
┌──────────────────────────────────────────────────────────┐
│                      CraftUIKit                          │
│                                                          │
│   ┌──────────────────────────────────────────────────┐   │
│   │               CraftAppearanceMode                │   │
│   │      .system / .light / .dark -> ColorScheme?    │   │
│   └────────────────────────┬─────────────────────────┘   │
│                            │                             │
│   ┌────────────────────────▼─────────────────────────┐   │
│   │           CraftThemeManager (Singleton)          │   │
│   │  - currentPreset: CraftThemePreset               │   │
│   │  - appearanceMode: CraftAppearanceMode           │   │
│   │  - preferredColorScheme: ColorScheme? (computed) │   │
│   │  - UserDefaults persistence & migration          │   │
│   └────────────────────────┬─────────────────────────┘   │
└────────────────────────────┼─────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────┐
│                    VocabCraftApp                         │
│                                                          │
│   ┌──────────────────────────────────────────────────┐   │
│   │                UserSettingsStore                 │   │
│   │  Delegates themePreset & appearanceMode          │   │
│   │  directly to CraftThemeManager.shared            │   │
│   └────────────────────────┬─────────────────────────┘   │
│                            │                             │
│   ┌────────────────────────▼─────────────────────────┐   │
│   │               VocabCraftApp (App Root)           │   │
│   │  WindowGroup {                                   │   │
│   │     RootView()                                   │   │
│   │       .craftTheme(themeManager.currentPreset)    │   │
│   │       .preferredColorScheme(                     │   │
│   │          themeManager.preferredColorScheme)      │   │
│   │  }                                               │   │
│   └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

### 2.1 Single Source of Truth
- `CraftThemeManager` in `CraftUIKit` serves as the centralized singleton for theme selection and appearance mode.
- `CraftAppearanceMode` enum encapsulates `.system`, `.light`, and `.dark`, converting cleanly to SwiftUI's `ColorScheme?`.
- `UserSettingsStore` in `VocabCraftApp` delegates its theme-related properties (`themePreset`, `appearanceMode`, `appTheme`, `colorScheme`) directly to `CraftThemeManager.shared`.

### 2.2 Persistence Strategy
- Preset key: `"app_theme_preset"` (raw value of `CraftThemePreset`).
- Appearance mode key: `"app_appearance_mode"` (raw value of `CraftAppearanceMode`: `"system"`, `"light"`, `"dark"`).
- Backward compatibility: In `CraftThemeManager.init()`, check `"app_appearance_mode"`, falling back to legacy `"app_theme"` or `"app_color_scheme"` if present.

---

## 3. Detailed Component & Token Specifications

### 3.1 `CraftAppearanceMode` (`Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftAppearanceMode.swift`)
```swift
import SwiftUI

/// Standardized appearance modes for CraftUIKit and VocabCraftApp.
public enum CraftAppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    /// Maps to SwiftUI `ColorScheme?` (nil for system).
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
```

### 3.2 `CraftThemeManager` (`Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemeManager.swift`)
- Holds `@Observable` properties:
  - `public var currentPreset: CraftThemePreset`
  - `public var appearanceMode: CraftAppearanceMode`
  - `public var preferredColorScheme: ColorScheme? { appearanceMode.colorScheme }`
- Mutating methods:
  - `func setPreset(_ preset: CraftThemePreset)`
  - `func setAppearanceMode(_ mode: CraftAppearanceMode)`
  - `func setColorScheme(_ scheme: ColorScheme?)` (maps `nil -> .system`, `.light -> .light`, `.dark -> .dark`)

### 3.3 `UserSettingsStore` (`VocabCraftApp/Core/Database/UserSettingsStore.swift`)
- Delegates `themePreset` to `CraftThemeManager.shared.currentPreset`.
- Delegates `appearanceMode` to `CraftThemeManager.shared.appearanceMode`.
- Bridges `appTheme: String` (get: `appearanceMode.rawValue`, set: `CraftAppearanceMode(rawValue: newValue)`).
- Bridges `colorScheme: ColorScheme?` directly to `CraftThemeManager.shared.preferredColorScheme`.

### 3.4 Root View Hierarchy (`VocabCraftApp/App/VocabCraftApp.swift` & `HomepageView.swift`)
- In `VocabCraftApp.swift`:
  ```swift
  WindowGroup {
      Group {
          ...
      }
      .craftTheme(themeManager.currentPreset.theme)
      .preferredColorScheme(themeManager.preferredColorScheme)
  }
  ```
- In `HomepageView.swift`:
  - Remove `.preferredColorScheme(appContainer.userSettingsStore.colorScheme)` so the root window modifier controls the entire tree uniformly.

### 3.5 9 Theme Presets Color Audit & Dynamic Parity
All 9 themes must have 100% `.craftDynamic(light:dark:)` coverage for all 28 semantic tokens:
1. **Warm Editorial** (`CraftEditorialTheme`): Default theme with Linen `#FAF9F5` (Light) / Obsidian `#121615` (Dark), Deep Teal `#0D9488` / `#14B8A6`.
2. **Kyoto Matcha Zen** (`CraftKyotoMatchaTheme`): Oatmeal `#F9F6F0` / Hinoki `#111A16`, Matcha `#3D6B52` / `#52B788`.
3. **AI Acoustic Obsidian** (`CraftAIAcousticTheme`): Ice `#F4F6FB` / Obsidian `#090D16`, Cobalt `#1D4ED8` / `#3B82F6`.
4. **Oxford Heritage** (`CraftOxfordHeritageTheme`): Parchment `#FBF8F2` / Midnight `#0C121D`, Navy `#0A2540` / Royal Blue `#60A5FA`.
5. **Solar Momentum** (`CraftSolarMomentumTheme`): Solar Sand `#FFFDF9` / Deep Cosmos `#120E16`, Coral Fire `#FF5A36` / `#FF6B4A`.
6. **Tactile Clay Mochi** (`CraftTactileClayTheme`): Sesame `#F6F3EE` / Truffle `#171412`, Clay `#D96B43` / `#F97316`.
7. **Neo-Arcade** (`CraftNeoArcadeTheme`): Ice `#F8FAFC` / Cyber Night `#0B0F19`, Neon Lime `#84CC16` / `#A3E635`.
8. **Nordic Zen** (`CraftNordicZenTheme`): Mist `#F4F4F5` / Polar `#18181B`, Lavender `#8B5CF6` / `#A78BFA`.
9. **Classic Slate** (`CraftDefaultTheme`): Modern Slate `#FAFAF8` / `#121214`, Brand Coral `.craftDynamic(light: Color(hex: 0xE06D3B), dark: Color(hex: 0xF97316))`.

---

## 4. Testing & Verification Plan

### 4.1 Unit Tests in `CraftUIKitTests`
1. `CraftAppearanceModeTests`:
   - Verify `.system` returns `nil` `colorScheme`.
   - Verify `.light` returns `.light`.
   - Verify `.dark` returns `.dark`.
2. `CraftThemeManagerTests`:
   - Verify setting `appearanceMode` updates `preferredColorScheme` and persists to `UserDefaults`.
   - Verify setting `currentPreset` updates and persists.
   - Verify legacy migration from `"app_theme"` / `"app_color_scheme"`.
3. `ThemeCompletenessTests`:
   - Loop over all 9 `CraftThemePreset.allCases` and assert that all colors, fonts, shadows, and radii are non-nil and valid in both light and dark traits.

### 4.2 Unit Tests in `VocabCraftAppTests`
1. `UserSettingsStoreTests`:
   - Verify modifying `store.appTheme` updates `CraftThemeManager.shared.appearanceMode`.
   - Verify modifying `store.themePreset` updates `CraftThemeManager.shared.currentPreset`.
   - Verify `store.colorScheme` matches `CraftThemeManager.shared.preferredColorScheme`.
2. `SettingsViewTests`:
   - Verify `SettingsView` renders with Appearance segmented control (`dark`, `light`, `system`) and correctly updates store state.

### 4.3 Simulator & UI Verification
- Build and run on iPhone 17 Simulator (`test_sim` / `build_run_sim`).
- Verify switching between Light, Dark, and System across all 9 presets in SettingsView.
- Verify modals, sheets, and dialogs (`ProfileStatsSheet`, `CraftCatalogView`, `CraftDialog`, `CraftBottomSheet`) correctly adapt their background and text in both modes.
