# Multi-Theme Token System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 4 distinct 2026 design trend theme presets (Warm Editorial, Neo-Arcade, Nordic Zen, Classic Slate) with 100% Light & Dark mode parity into `CraftUIKit`, and provide live dynamic theme switching across `CraftCatalogView` and `VocabCraftApp`.

**Architecture:** A protocol-oriented design token architecture in `CraftUIKit` where `CraftTheme` coordinates semantic color, typography, spacing, radius, shadow, gradient, depth, glass, animation, and opacity tokens. A new `CraftThemePreset` enum registers all presets, and dynamic SwiftUI environment injection (`@Environment(\.craftTheme)`) powers real-time switching without view reconstruction.

**Tech Stack:** Swift 5.10+, SwiftUI, iOS 17+/macOS 14+, XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-27-multi-theme-tokens-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-27-multi-theme-tokens-design.md)

## Global Constraints

- 100% Light and Dark mode parity across all tokens via `.craftDynamic(light:dark:)`.
- Zero raw hardcoded strings; use `CraftLocalized` / string catalog conventions for any UI text.
- Atmospheric Dark Mode: No pure `#000000` canvas; use themed dark undertones (`#121615`, `#0B0F19`, `#18181B`, `#121214`).
- All tests must pass with 0 warnings or regressions (`swift test`).

---

### Task 1: Core Token Registry & `CraftThemePreset` in `CraftUIKit`

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemePreset.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Produces: `CraftThemePreset` enum (`editorial`, `neoArcade`, `nordicZen`, `classic`) conforming to `String, CaseIterable, Identifiable, Sendable` with `var theme: any CraftTheme`.

- [ ] **Step 1: Write failing test for `CraftThemePreset`**

Add to `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`:
```swift
func testThemePresetEnumCoverageAndInstantiation() {
    for preset in CraftThemePreset.allCases {
        let theme = preset.theme
        XCTAssertNotNil(theme.colors.canvasBackground)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.typography.titleLarge)
        XCTAssertFalse(preset.displayName.isEmpty)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: FAIL with "cannot find 'CraftThemePreset' in scope"

- [ ] **Step 3: Implement `CraftThemePreset.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemePreset.swift`:
```swift
import SwiftUI

/// Standardized theme presets for CraftUIKit and VocabCraftApp.
public enum CraftThemePreset: String, CaseIterable, Identifiable, Sendable {
    case editorial = "editorial"
    case neoArcade = "neo_arcade"
    case nordicZen = "nordic_zen"
    case classic = "classic"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .editorial: return "Warm Editorial"
        case .neoArcade: return "Neo-Arcade"
        case .nordicZen: return "Nordic Zen"
        case .classic: return "Classic Slate"
        }
    }

    public var theme: any CraftTheme {
        switch self {
        case .editorial: return CraftEditorialTheme()
        case .neoArcade: return CraftNeoArcadeTheme()
        case .nordicZen: return CraftNordicZenTheme()
        case .classic: return CraftDefaultTheme()
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes (with placeholder theme structs if needed)**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemePreset.swift Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift
git commit -m "feat(craftuikit): add CraftThemePreset enum and test coverage"
```

---

### Task 2: Implement `CraftEditorialTheme` (Warm Editorial & Tactile Glass)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftEditorialTheme.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Produces: `CraftEditorialTheme: CraftTheme`, `CraftEditorialColorTokens: CraftColorTokens`, `CraftEditorialTypographyTokens: CraftTypographyTokens`, `CraftEditorialGradientTokens: CraftGradientTokens`.

- [ ] **Step 1: Write test for Editorial Theme tokens**

Add to `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`:
```swift
func testEditorialThemeTokens() {
    let theme = CraftEditorialTheme()
    XCTAssertNotNil(theme.colors.canvasBackground)
    XCTAssertNotNil(theme.colors.brandPrimary)
    XCTAssertNotNil(theme.typography.displaySerif)
    XCTAssertNotNil(theme.gradients.brandHero)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: FAIL with "cannot find 'CraftEditorialTheme' in scope"

- [ ] **Step 3: Implement `CraftEditorialTheme.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftEditorialTheme.swift`:
```swift
import SwiftUI

/// Warm Editorial & Tactile Glass Theme.
public struct CraftEditorialTheme: CraftTheme {
    public var colors: CraftColorTokens
    public var typography: CraftTypographyTokens
    public var spacing: CraftSpacingTokens
    public var radii: CraftRadiusTokens
    public var shadows: CraftShadowTokens
    public var gradients: CraftGradientTokens
    public var animations: CraftAnimationTokens
    public var opacities: CraftOpacityTokens
    public var depths: CraftDepthTokens
    public var glass: CraftGlassTokens

    public init(
        colors: CraftColorTokens = CraftEditorialColorTokens(),
        typography: CraftTypographyTokens = CraftEditorialTypographyTokens(),
        spacing: CraftSpacingTokens = CraftDefaultSpacingTokens(),
        radii: CraftRadiusTokens = CraftDefaultRadiusTokens(),
        shadows: CraftShadowTokens = CraftDefaultShadowTokens(),
        gradients: CraftGradientTokens = CraftEditorialGradientTokens(),
        animations: CraftAnimationTokens = CraftDefaultAnimationTokens(),
        opacities: CraftOpacityTokens = CraftDefaultOpacityTokens(),
        depths: CraftDepthTokens = CraftDefaultDepthTokens(),
        glass: CraftGlassTokens = CraftDefaultGlassTokens()
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.radii = radii
        self.shadows = shadows
        self.gradients = gradients
        self.animations = animations
        self.opacities = opacities
        self.depths = depths
        self.glass = glass
    }
}

public struct CraftEditorialColorTokens: CraftColorTokens {
    public var canvasBackground: Color
    public var surfaceCard: Color
    public var surfaceElevated: Color
    public var surfaceSubtle: Color
    public var brandPrimary: Color
    public var brandSecondary: Color
    public var accent: Color
    public var textPrimary: Color
    public var textSecondary: Color
    public var textMuted: Color
    public var textInverse: Color
    public var borderDefault: Color
    public var borderFocus: Color
    public hairline: Color
    public var statusSuccess: Color
    public var statusWarning: Color
    public var statusDanger: Color
    public var statusInfo: Color
    public var streakStarter: Color
    public var streakBlaze: Color
    public var streakLegendary: Color
    public var streakFreeze: Color
    public var streakPending: Color
    public var streakGlow: Color
    public var pathCompleted: Color
    public var pathActive: Color
    public var pathUpcoming: Color
    public var pathLocked: Color
    public var pathHaloGlow: Color

    public init(
        canvasBackground: Color = .craftDynamic(light: Color(hex: 0xFAF9F5), dark: Color(hex: 0x121615)),
        surfaceCard: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1A2220)),
        surfaceElevated: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x242F2C)),
        surfaceSubtle: Color = .craftDynamic(light: Color(hex: 0xF3EFE6), dark: Color(hex: 0x161D1B)),
        brandPrimary: Color = .craftDynamic(light: Color(hex: 0x0D9488), dark: Color(hex: 0x14B8A6)),
        brandSecondary: Color = .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x10B981)),
        accent: Color = .craftDynamic(light: Color(hex: 0xF97316), dark: Color(hex: 0xFB923C)),
        textPrimary: Color = .craftDynamic(light: Color(hex: 0x131E1B), dark: Color(hex: 0xF4FDF9)),
        textSecondary: Color = .craftDynamic(light: Color(hex: 0x4A5E58), dark: Color(hex: 0x9EB3AC)),
        textMuted: Color = .craftDynamic(light: Color(hex: 0x6E857E), dark: Color(hex: 0x6E857E)),
        textInverse: Color = .craftDynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x121615)),
        borderDefault: Color = .craftDynamic(light: Color(hex: 0xE2DDD5), dark: Color(hex: 0x242F2C)),
        borderFocus: Color = Color(hex: 0x0D9488),
        hairline: Color = .craftDynamic(light: Color(hex: 0xE2DDD5).opacity(0.8), dark: Color(hex: 0x242F2C).opacity(0.8)),
        statusSuccess: Color = Color(hex: 0x10B981),
        statusWarning: Color = Color(hex: 0xF59E0B),
        statusDanger: Color = Color(hex: 0xEF4444),
        statusInfo: Color = Color(hex: 0x0EA5E9),
        streakStarter: Color = Color(hex: 0xF97316),
        streakBlaze: Color = Color(hex: 0xEA580C),
        streakLegendary: Color = Color(hex: 0x8B5CF6),
        streakFreeze: Color = Color(hex: 0x38BDF8),
        streakPending: Color = Color(hex: 0x94A3B8),
        streakGlow: Color = Color(hex: 0xF97316).opacity(0.35),
        pathCompleted: Color = Color(hex: 0x10B981),
        pathActive: Color = Color(hex: 0x0D9488),
        pathUpcoming: Color = .craftDynamic(light: Color(hex: 0xCBD5E1), dark: Color(hex: 0x334155)),
        pathLocked: Color = .craftDynamic(light: Color(hex: 0xE2E8F0), dark: Color(hex: 0x1E293B)),
        pathHaloGlow: Color = Color(hex: 0x0D9488).opacity(0.20)
    ) {
        self.canvasBackground = canvasBackground
        self.surfaceCard = surfaceCard
        self.surfaceElevated = surfaceElevated
        self.surfaceSubtle = surfaceSubtle
        self.brandPrimary = brandPrimary
        self.brandSecondary = brandSecondary
        self.accent = accent
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textMuted = textMuted
        self.textInverse = textInverse
        self.borderDefault = borderDefault
        self.borderFocus = borderFocus
        self.hairline = hairline
        self.statusSuccess = statusSuccess
        self.statusWarning = statusWarning
        self.statusDanger = statusDanger
        self.statusInfo = statusInfo
        self.streakStarter = streakStarter
        self.streakBlaze = streakBlaze
        self.streakLegendary = streakLegendary
        self.streakFreeze = streakFreeze
        self.streakPending = streakPending
        self.streakGlow = streakGlow
        self.pathCompleted = pathCompleted
        self.pathActive = pathActive
        self.pathUpcoming = pathUpcoming
        self.pathLocked = pathLocked
        self.pathHaloGlow = pathHaloGlow
    }
}

public struct CraftEditorialTypographyTokens: CraftTypographyTokens {
    public var displayLarge: Font
    public var displayHero: Font
    public var displaySerif: Font
    public var titleLarge: Font
    public var titleMedium: Font
    public var headline: Font
    public var bodyLarge: Font
    public var bodyMedium: Font
    public var bodySerif: Font
    public var phonetic: Font
    public var metricRounded: Font
    public var label: Font
    public var caption: Font

    public init(
        displayLarge: Font = .system(.largeTitle, design: .serif, weight: .bold),
        displayHero: Font = .system(size: 72, weight: .bold, design: .serif),
        displaySerif: Font = .system(.largeTitle, design: .serif, weight: .bold),
        titleLarge: Font = .system(.title, design: .serif, weight: .bold),
        titleMedium: Font = .system(.title2, design: .serif, weight: .semibold),
        headline: Font = .system(.headline, design: .rounded, weight: .semibold),
        bodyLarge: Font = .system(.body, design: .default, weight: .regular),
        bodyMedium: Font = .system(.callout, design: .default, weight: .regular),
        bodySerif: Font = .system(.body, design: .serif, weight: .regular),
        phonetic: Font = .system(.callout, design: .monospaced, weight: .regular),
        metricRounded: Font = .system(.title2, design: .rounded, weight: .bold),
        label: Font = .system(.subheadline, design: .rounded, weight: .medium),
        caption: Font = .system(.caption, design: .default, weight: .regular)
    ) {
        self.displayLarge = displayLarge
        self.displayHero = displayHero
        self.displaySerif = displaySerif
        self.titleLarge = titleLarge
        self.titleMedium = titleMedium
        self.headline = headline
        self.bodyLarge = bodyLarge
        self.bodyMedium = bodyMedium
        self.bodySerif = bodySerif
        self.phonetic = phonetic
        self.metricRounded = metricRounded
        self.label = label
        self.caption = caption
    }
}

public struct CraftEditorialGradientTokens: CraftGradientTokens {
    public var brandHero: LinearGradient
    public var surfaceGlass: LinearGradient
    public var accentShine: LinearGradient
    public var fadeBottom: LinearGradient
    public var streakStarter: LinearGradient
    public var streakBlaze: LinearGradient
    public var streakLegendary: LinearGradient

    public init(
        brandHero: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x0D9488), Color(hex: 0x059669)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        surfaceGlass: LinearGradient = LinearGradient(
            colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        accentShine: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF97316), Color(hex: 0xFBBF24)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        fadeBottom: LinearGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.4)],
            startPoint: .top,
            endPoint: .bottom
        ),
        streakStarter: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xF97316), Color(hex: 0xEA580C)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakBlaze: LinearGradient = LinearGradient(
            colors: [Color(hex: 0xEA580C), Color(hex: 0xDC2626)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        streakLegendary: LinearGradient = LinearGradient(
            colors: [Color(hex: 0x8B5CF6), Color(hex: 0x06B6D4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ) {
        self.brandHero = brandHero
        self.surfaceGlass = surfaceGlass
        self.accentShine = accentShine
        self.fadeBottom = fadeBottom
        self.streakStarter = streakStarter
        self.streakBlaze = streakBlaze
        self.streakLegendary = streakLegendary
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftEditorialTheme.swift Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift
git commit -m "feat(craftuikit): implement CraftEditorialTheme with warm linen & obsidian dark tokens"
```

---

### Task 3: Implement `CraftNeoArcadeTheme` (Neo-Arcade Hyper-Vibrant)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNeoArcadeTheme.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Produces: `CraftNeoArcadeTheme: CraftTheme`, `CraftNeoArcadeColorTokens: CraftColorTokens`, `CraftNeoArcadeTypographyTokens: CraftTypographyTokens`, `CraftNeoArcadeGradientTokens: CraftGradientTokens`.

- [ ] **Step 1: Write test for NeoArcade Theme tokens**

Add to `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`:
```swift
func testNeoArcadeThemeTokens() {
    let theme = CraftNeoArcadeTheme()
    XCTAssertNotNil(theme.colors.canvasBackground)
    XCTAssertNotNil(theme.colors.brandPrimary)
    XCTAssertNotNil(theme.animations.springBouncy)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: FAIL with "cannot find 'CraftNeoArcadeTheme' in scope"

- [ ] **Step 3: Implement `CraftNeoArcadeTheme.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNeoArcadeTheme.swift` with Cyber Lime `#84CC16`, Cyber Midnight `#0B0F19`, Electric Indigo `#6366F1`, and 100% SF Rounded bold typography.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNeoArcadeTheme.swift Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift
git commit -m "feat(craftuikit): implement CraftNeoArcadeTheme with cyber lime & indigo tokens"
```

---

### Task 4: Implement `CraftNordicZenTheme` (Nordic Zen & Dynamic Void)

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNordicZenTheme.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Produces: `CraftNordicZenTheme: CraftTheme`, `CraftNordicZenColorTokens: CraftColorTokens`, `CraftNordicZenTypographyTokens: CraftTypographyTokens`, `CraftNordicZenGradientTokens: CraftGradientTokens`.

- [ ] **Step 1: Write test for NordicZen Theme tokens**

Add to `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`:
```swift
func testNordicZenThemeTokens() {
    let theme = CraftNordicZenTheme()
    XCTAssertNotNil(theme.colors.canvasBackground)
    XCTAssertNotNil(theme.colors.brandPrimary)
    XCTAssertNotNil(theme.colors.accent)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: FAIL with "cannot find 'CraftNordicZenTheme' in scope"

- [ ] **Step 3: Implement `CraftNordicZenTheme.swift`**

Create `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNordicZenTheme.swift` with Mist Gray `#F4F4F5`, Deep Graphite `#18181B`, Celestial Lavender `#8B5CF6`, Frost Cyan `#06B6D4`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNordicZenTheme.swift Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift
git commit -m "feat(craftuikit): implement CraftNordicZenTheme with mist gray & celestial violet tokens"
```

---

### Task 5: Update `CraftCatalogView` with Live Multi-Theme & Dark Mode Switcher

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Consumes: `CraftThemePreset`
- Updates: Catalog toolbar theme picker to present all 4 presets (`Warm Editorial`, `Neo-Arcade`, `Nordic Zen`, `Classic Slate`).

- [ ] **Step 1: Write test for Catalog theme switching**

Add to `Packages/CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`:
```swift
func testCatalogThemePickerRendersAllPresets() {
    let view = CraftCatalogView()
    XCTAssertNotNil(view.body)
}
```

- [ ] **Step 2: Update `CraftCatalogView.swift`**

Refactor `CatalogThemeType` to wrap `CraftThemePreset` directly, removing duplicate definitions.

- [ ] **Step 3: Run catalog view tests**

Run: `swift test --package-path Packages/CraftUIKit --filter CatalogViewTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift
git commit -m "feat(craftuikit): update CraftCatalogView to support all 4 CraftThemePreset options"
```

---

### Task 6: Dynamic Theme Management & App Wiring in `VocabCraftApp`

**Files:**
- Create: `VocabCraftApp/Core/DesignSystem/AppThemeManager.swift`
- Modify: `VocabCraftApp/App/VocabCraftApp.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/Color+VocabCraft.swift`
- Test: `VocabCraftAppTests/DesignSystem/ColorTokensTests.swift`

**Interfaces:**
- Produces: `AppThemeManager` with `@Published` / `@Observable` current preset and color scheme, persisting to `UserDefaults`.

- [ ] **Step 1: Write test for AppThemeManager**

Add to `VocabCraftAppTests/DesignSystem/ColorTokensTests.swift`:
```swift
func testAppThemeManagerPresetSwitching() {
    let manager = AppThemeManager.shared
    manager.setPreset(.editorial)
    XCTAssertEqual(manager.currentPreset, .editorial)
    manager.setPreset(.neoArcade)
    XCTAssertEqual(manager.currentPreset, .neoArcade)
}
```

- [ ] **Step 2: Implement `AppThemeManager.swift`**

Create `VocabCraftApp/Core/DesignSystem/AppThemeManager.swift` with observation and persistence.

- [ ] **Step 3: Wire into `VocabCraftApp.swift`**

Inject `.craftTheme(themeManager.currentPreset.theme)` at root.

- [ ] **Step 4: Run tests**

Run: `swift test --filter ColorTokensTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/DesignSystem/AppThemeManager.swift VocabCraftApp/App/VocabCraftApp.swift VocabCraftAppTests/DesignSystem/ColorTokensTests.swift
git commit -m "feat(app): add AppThemeManager and wire dynamic theme switching to root app"
```

---

### Task 7: Full Test Suite Verification & Quality Gate

**Files:**
- Test: All tests across `CraftUIKit` and `VocabCraftAppTests`

- [ ] **Step 1: Run CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: All tests PASS with 0 failures.

- [ ] **Step 2: Run VocabCraftApp tests**

Run: `swift test`
Expected: All tests PASS with 0 failures.

- [ ] **Step 3: Final Commit & Tag**

```bash
git commit --allow-empty -m "chore: complete 2026 multi-theme token system integration"
```
