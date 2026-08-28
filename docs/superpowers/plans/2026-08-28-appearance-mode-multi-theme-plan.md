# Appearance Mode & Multi-Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild and fix the Appearance Mode (System, Light, Dark) feature across `CraftUIKit` and `VocabCraftApp`, centralizing state in `CraftThemeManager` and guaranteeing 100% Light/Dark mode dynamic token support across all 9 theme presets.

**Architecture:** Centralize theme preset and appearance mode state into `CraftThemeManager.shared` (`CraftUIKit`). Introduce `CraftAppearanceMode` enum. Refactor `UserSettingsStore` to delegate directly to `CraftThemeManager.shared`. Apply root `.craftTheme(...)` and `.preferredColorScheme(...)` exclusively at `WindowGroup` in `VocabCraftApp.swift` to ensure seamless propagation across all screens, modals, and sheets. Audit and guarantee dynamic color token parity across all 9 theme presets.

**Tech Stack:** Swift 6.0, SwiftUI, SwiftData, `@Observable`, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-28-appearance-mode-multi-theme-design.md`

## Global Constraints

- Strict adherence to `AGENTS.md` (CraftUIKit-First, zero raw colors, zero hardcoded strings, 100% bilingual parity, zero compiler warnings, 100% test pass).
- No duplicate appearance keys; persist presets to `"app_theme_preset"` and appearance modes to `"app_appearance_mode"` with backward-compatibility fallbacks.
- Single source of truth for color scheme at the root `WindowGroup`.

---

### Task 1: Add `CraftAppearanceMode` and Upgrade `CraftThemeManager` in `CraftUIKit`

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftAppearanceMode.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemeManager.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Produces: `CraftAppearanceMode` (`.system`, `.light`, `.dark`), `CraftThemeManager.appearanceMode: CraftAppearanceMode`, `CraftThemeManager.preferredColorScheme: ColorScheme?`, `CraftThemeManager.setAppearanceMode(_ mode: CraftAppearanceMode)`.

- [ ] **Step 1: Write the failing test for `CraftAppearanceMode` and `CraftThemeManager`**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`:
```swift
    func testCraftAppearanceModeMapping() {
        XCTAssertNil(CraftAppearanceMode.system.colorScheme)
        XCTAssertEqual(CraftAppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(CraftAppearanceMode.dark.colorScheme, .dark)
    }

    func testCraftThemeManagerAppearanceModePersistence() {
        let manager = CraftThemeManager()
        manager.setAppearanceMode(.dark)
        XCTAssertEqual(manager.appearanceMode, .dark)
        XCTAssertEqual(manager.preferredColorScheme, .dark)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_appearance_mode"), "dark")

        manager.setAppearanceMode(.light)
        XCTAssertEqual(manager.appearanceMode, .light)
        XCTAssertEqual(manager.preferredColorScheme, .light)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_appearance_mode"), "light")

        manager.setAppearanceMode(.system)
        XCTAssertEqual(manager.appearanceMode, .system)
        XCTAssertNil(manager.preferredColorScheme)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "app_appearance_mode"), "system")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: FAIL (cannot find type `CraftAppearanceMode` or member `appearanceMode` in scope)

- [ ] **Step 3: Implement `CraftAppearanceMode.swift` and update `CraftThemeManager.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftAppearanceMode.swift`:
```swift
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
```

Modify `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemeManager.swift`:
```swift
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftAppearanceMode.swift Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemeManager.swift Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift
git commit -m "feat(craftuikit): introduce CraftAppearanceMode and upgrade CraftThemeManager"
```

---

### Task 2: Audit and Complete Dynamic Tokens for `CraftDefaultColorTokens` & 9 Theme Presets

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Consumes: `CraftColorTokens`, `CraftThemePreset`.
- Produces: 100% dynamic colors in `CraftDefaultColorTokens` and all 9 theme presets.

- [ ] **Step 1: Write the failing test checking dynamic colors and completeness across all 9 presets**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`:
```swift
    func testAllNineThemePresetsHaveFullDynamicTokens() {
        for preset in CraftThemePreset.allCases {
            let theme = preset.theme
            let colors = theme.colors

            XCTAssertNotNil(colors.canvasBackground)
            XCTAssertNotNil(colors.surfaceCard)
            XCTAssertNotNil(colors.surfaceElevated)
            XCTAssertNotNil(colors.surfaceSubtle)
            XCTAssertNotNil(colors.brandPrimary)
            XCTAssertNotNil(colors.brandSecondary)
            XCTAssertNotNil(colors.accent)
            XCTAssertNotNil(colors.textPrimary)
            XCTAssertNotNil(colors.textSecondary)
            XCTAssertNotNil(colors.textMuted)
            XCTAssertNotNil(colors.textInverse)
            XCTAssertNotNil(colors.borderDefault)
            XCTAssertNotNil(colors.borderFocus)
            XCTAssertNotNil(colors.hairline)
            XCTAssertNotNil(colors.statusSuccess)
            XCTAssertNotNil(colors.statusWarning)
            XCTAssertNotNil(colors.statusDanger)
            XCTAssertNotNil(colors.statusInfo)
            XCTAssertNotNil(colors.streakStarter)
            XCTAssertNotNil(colors.streakBlaze)
            XCTAssertNotNil(colors.streakLegendary)
            XCTAssertNotNil(colors.streakFreeze)
            XCTAssertNotNil(colors.streakPending)
            XCTAssertNotNil(colors.streakGlow)
            XCTAssertNotNil(colors.pathCompleted)
            XCTAssertNotNil(colors.pathActive)
            XCTAssertNotNil(colors.pathUpcoming)
            XCTAssertNotNil(colors.pathLocked)
            XCTAssertNotNil(colors.pathHaloGlow)
        }
    }
```

- [ ] **Step 2: Run test to verify status**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`

- [ ] **Step 3: Update `CraftDefaultColorTokens` in `CraftColorTokens.swift` to use `.craftDynamic`**

Modify `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift`:
```swift
    public init(
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFAFAF8), dark: Color(hex: 0x121214)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1C1C1E)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x2C2C2E)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF4F4F0), dark: Color(hex: 0x242426)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0xE06D3B), dark: Color(hex: 0xF97316)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0xD97706), dark: Color(hex: 0xFBBF24)),
        accent: Color = .craftDynamic(light: Color(hex: 0xF59E0B), dark: Color(hex: 0xFCD34D)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x18181B), dark: Color(hex: 0xF4F4F5)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x52525B), dark: Color(hex: 0xA1A1AA)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x71717A), dark: Color(hex: 0x71717A)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x121214)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE4E4E7), dark: Color(hex: 0x27272A)),
        borderFocus: Color = Color(hex: 0xE06D3B),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE4E4E7).opacity(0.8), dark: Color(hex: 0x27272A).opacity(0.8)),
        statusSuccess: Color = Color(hex: 0x10B981),
        statusWarning: Color = Color(hex: 0xF59E0B),
        statusDanger: Color = Color(hex: 0xEF4444),
        statusInfo: Color = Color(hex: 0x0284C7),
        streakStarter: Color = Color(hex: 0xE06D3B),
        streakBlaze: Color = Color(hex: 0xF59E0B),
        streakLegendary: Color = Color(hex: 0x8B5CF6),
        streakFreeze: Color = Color(hex: 0x38BDF8),
        streakPending: Color = Color(hex: 0x94A3B8),
        streakGlow: Color = Color(hex: 0xF59E0B).opacity(0.35),
        pathCompleted: Color = Color(hex: 0x10B981),
        pathActive: Color = Color(hex: 0xE06D3B),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x475569)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x27272A)),
        pathHaloGlow: Color = Color(hex: 0xE06D3B).opacity(0.20)
    )
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift
git commit -m "feat(craftuikit): standardize CraftDefaultColorTokens with dynamic light and dark tokens"
```

---

### Task 3: Refactor `UserSettingsStore` in `VocabCraftApp` to Delegate to `CraftThemeManager`

**Files:**
- Modify: `VocabCraftApp/Core/Database/UserSettingsStore.swift`
- Test: `VocabCraftAppTests/UserSettingsStoreTests.swift`

**Interfaces:**
- Consumes: `CraftThemeManager.shared`, `CraftAppearanceMode`, `CraftThemePreset`.
- Produces: `UserSettingsStore.themePreset`, `UserSettingsStore.appearanceMode`, `UserSettingsStore.appTheme`, `UserSettingsStore.colorScheme`.

- [ ] **Step 1: Write the failing test for `UserSettingsStore` appearance delegation**

In `VocabCraftAppTests/UserSettingsStoreTests.swift`:
```swift
    func testAppearanceModeDelegatesToCraftThemeManager() {
        let store = UserSettingsStore()

        store.appTheme = "dark"
        XCTAssertEqual(CraftThemeManager.shared.appearanceMode, .dark)
        XCTAssertEqual(store.colorScheme, .dark)

        store.appTheme = "light"
        XCTAssertEqual(CraftThemeManager.shared.appearanceMode, .light)
        XCTAssertEqual(store.colorScheme, .light)

        store.appTheme = "system"
        XCTAssertEqual(CraftThemeManager.shared.appearanceMode, .system)
        XCTAssertNil(store.colorScheme)

        store.themePreset = .kyotoMatcha
        XCTAssertEqual(CraftThemeManager.shared.currentPreset, .kyotoMatcha)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test` via `test_sim` on scheme `VocabCraftAppTests` / `VocabCraftApp`.
Expected: FAIL (store.appTheme doesn't update CraftThemeManager.shared.appearanceMode).

- [ ] **Step 3: Refactor `UserSettingsStore.swift`**

Modify `VocabCraftApp/Core/Database/UserSettingsStore.swift`:
```swift
import CraftUIKit
import Foundation
import SwiftUI

@MainActor
@Observable
public final class UserSettingsStore {
    public var themePreset: CraftThemePreset {
        get { CraftThemeManager.shared.currentPreset }
        set { CraftThemeManager.shared.setPreset(newValue) }
    }

    public var dailyGoalCount: Int {
        didSet {
            UserDefaults.standard.set(dailyGoalCount, forKey: "daily_goal_count")
        }
    }

    public var isNotificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isNotificationEnabled, forKey: "is_notification_enabled")
        }
    }

    public var notificationTimeInterval: Double {
        didSet {
            UserDefaults.standard.set(notificationTimeInterval, forKey: "notification_time_interval")
        }
    }

    public var notificationTime: Date {
        get {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            return startOfDay.addingTimeInterval(notificationTimeInterval)
        }
        set {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: newValue)
            notificationTimeInterval = newValue.timeIntervalSince(startOfDay)
        }
    }

    public var ttsVoiceGender: String {
        didSet {
            UserDefaults.standard.set(ttsVoiceGender, forKey: "tts_voice_gender")
        }
    }

    public var ttsSpeed: Double {
        didSet {
            UserDefaults.standard.set(ttsSpeed, forKey: "tts_speed")
        }
    }

    public var appearanceMode: CraftAppearanceMode {
        get { CraftThemeManager.shared.appearanceMode }
        set { CraftThemeManager.shared.setAppearanceMode(newValue) }
    }

    public var appTheme: String {
        get { CraftThemeManager.shared.appearanceMode.rawValue }
        set {
            if let mode = CraftAppearanceMode(rawValue: newValue) {
                CraftThemeManager.shared.setAppearanceMode(mode)
            }
        }
    }

    public var isHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "is_haptics_enabled")
        }
    }

    public var isSoundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEffectsEnabled, forKey: "is_sound_effects_enabled")
        }
    }

    public var appLanguage: String {
        didSet {
            UserDefaults.standard.set(appLanguage, forKey: "app_language")
        }
    }

    public var appLocale: Locale? {
        switch appLanguage {
        case "vi": return Locale(identifier: "vi")
        case "en": return Locale(identifier: "en")
        default: return nil
        }
    }

    public var colorScheme: ColorScheme? {
        CraftThemeManager.shared.preferredColorScheme
    }

    public init() {
        let defaults = UserDefaults.standard
        self.dailyGoalCount = defaults.object(forKey: "daily_goal_count") != nil ? defaults.integer(forKey: "daily_goal_count") : 15
        self.isNotificationEnabled = defaults.object(forKey: "is_notification_enabled") != nil ? defaults.bool(forKey: "is_notification_enabled") : true
        self.notificationTimeInterval = defaults.object(forKey: "notification_time_interval") != nil ? defaults.double(forKey: "notification_time_interval") : 72000
        self.ttsVoiceGender = defaults.string(forKey: "tts_voice_gender") ?? "US"
        self.ttsSpeed = defaults.object(forKey: "tts_speed") != nil ? defaults.double(forKey: "tts_speed") : 1.0
        self.appLanguage = defaults.string(forKey: "app_language") ?? "system"
        self.isHapticsEnabled = defaults.object(forKey: "is_haptics_enabled") != nil ? defaults.bool(forKey: "is_haptics_enabled") : true
        self.isSoundEffectsEnabled = defaults.object(forKey: "is_sound_effects_enabled") != nil ? defaults.bool(forKey: "is_sound_effects_enabled") : true
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run `test_sim` on scheme `VocabCraftApp`.
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/UserSettingsStore.swift VocabCraftAppTests/UserSettingsStoreTests.swift
git commit -m "refactor(settings): delegate UserSettingsStore theme and appearance state to CraftThemeManager"
```

---

### Task 4: Clean up App Root Hierarchy & Settings View Modifiers

**Files:**
- Modify: `VocabCraftApp/App/VocabCraftApp.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Test: `VocabCraftAppTests/SettingsViewTests.swift`

**Interfaces:**
- Consumes: `CraftThemeManager.shared.preferredColorScheme`, `CraftThemeManager.shared.currentPreset`.
- Produces: Clean root window appearance injection without view-level overrides.

- [ ] **Step 1: Update `VocabCraftApp.swift` and `HomepageView.swift`**

In `VocabCraftApp/App/VocabCraftApp.swift`:
Ensure:
```swift
        WindowGroup {
            Group {
                if NSClassFromString("XCTestCase") != nil {
                    Text("Testing...")
                } else {
                    HomepageView(viewModel: appContainer.makeHomepageViewModel())
                        .environment(\.appContainer, appContainer)
                        .environment(\.appRouter, appContainer.appRouter)
                        .environment(\.ttsService, appContainer.ttsService)
                        .environment(\.speechAssessmentService, appContainer.speechAssessmentService)
                        .onOpenURL { url in
                            appContainer.appRouter.handleDeepLink(url: url)
                        }
                }
            }
            .craftTheme(themeManager.currentPreset.theme)
            .preferredColorScheme(themeManager.preferredColorScheme)
        }
```

In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
Remove `.preferredColorScheme(appContainer.userSettingsStore.colorScheme)` at line 127, keeping `.environment(\.locale, appContainer.userSettingsStore.appLocale ?? .autoupdatingCurrent)`.

- [ ] **Step 2: Verify `SettingsView.swift` Appearance Segmented Control**

In `VocabCraftApp/Features/Settings/Views/SettingsView.swift`:
Verify `SettingsAppearanceCard` binds cleanly to `$store.appTheme`:
```swift
CraftSegmentedControl(
    selection: $store.appTheme,
    options: [
        CraftSegmentOption("dark", title: AppStrings.Settings.themeDarkText),
        CraftSegmentOption("light", title: AppStrings.Settings.themeLightText),
        CraftSegmentOption("system", title: AppStrings.Settings.themeSystemText)
    ],
    style: .flat
)
```

- [ ] **Step 3: Run full tests to verify all pass**

Run `test_sim` on scheme `VocabCraftApp`.
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/App/VocabCraftApp.swift VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftApp/Features/Settings/Views/SettingsView.swift
git commit -m "refactor(app): unify root preferredColorScheme and clean up redundant view-level modifiers"
```

---

### Task 5: Comprehensive Verification Suite & Quality Gate

**Files:**
- Test: All unit and integration test files.

- [ ] **Step 1: Run CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% tests pass, 0 failures.

- [ ] **Step 2: Run VocabCraftApp full test suite**

Run: `test_sim` with scheme `VocabCraftApp` on iPhone 17.
Expected: 100% tests pass, 0 failures.

- [ ] **Step 3: SwiftLint Compliance**

Run: `swiftlint` (or check for zero lint errors/warnings).
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Commit any final test improvements**

```bash
git add -A
git commit -m "test: verify complete appearance mode and multi-theme test coverage"
```
