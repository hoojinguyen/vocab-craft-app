# Multi-Theme Token System & 2026 Design Trends Specification

- **Date:** 2026-08-27
- **Author:** Senior Product Designer & Design System Architect
- **Target Package:** `CraftUIKit` & `VocabCraftApp`
- **Scope:** Architecture & Token Engine for 4 Distinct Theme Presets (Light & Dark Mode Parity)

---

## 1. Executive Summary & Goals

This specification formalizes the **Multi-Theme Token Architecture** for `CraftUIKit` and `VocabCraftApp`. Based on research into 2026 EdTech design trends, tactile mobile ergonomics, and global color forecasting, the system introduces **4 distinct, fully-realized theme presets**.

Every theme guarantees:
1. **100% Light & Dark Mode Parity**: Every semantic token explicitly defines bespoke Light and Dark values using `.craftDynamic(light:dark:)` with zero raw or uncalibrated colors.
2. **Atmospheric Dark Mode**: Banned pure `#000000` pitch black to eliminate eye strain and OLED smearing. Each theme has a themed dark undertone (Obsidian Botanical, Cyber Midnight, Atmospheric Graphite, Slate).
3. **Multi-Axis Typography Scaling**: Coordinated combinations of Serif (New York), SF Pro Rounded, SF Pro Text, and SF Mono (IPA phonetics).
4. **Liquid Glass & Tactile Depth**: Seamless specular edge highlights, multi-layer elevation shadows, and spring motion profiles calibrated per theme.
5. **Runtime Dynamic Switching**: Live theme switching in `CraftCatalogView` and in `VocabCraftApp` via `@Environment(\.craftTheme)` and `ThemeManager`.

---

## 2. 2026 Design Philosophy & The 4 Presets

```
                             ┌───────────────────────────────┐
                             │       CraftThemePreset        │
                             └───────────────┬───────────────┘
           ┌─────────────────────────┬───────┴─────────────────┬─────────────────────────┐
           ▼                         ▼                         ▼                         ▼
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
│   Warm Editorial    │   │     Neo-Arcade      │   │     Nordic Zen      │   │    Classic Slate    │
│  (.editorial)       │   │    (.neoArcade)     │   │    (.nordicZen)     │   │     (.classic)      │
│                     │   │                     │   │                     │   │                     │
│ Light: Linen Paper  │   │ Light: Crisp Ice    │   │ Light: Mist White   │   │ Light: Warm White   │
│ Dark: Obsidian Teal │   │ Dark: Cyber Night   │   │ Dark: Deep Graphite │   │ Dark: Slate Charcoal│
│ Serif + SF Rounded  │   │ All SF Rounded Bold │   │ SF Pro Light/Clean  │   │ SF Pro Rounded/Text │
└─────────────────────┘   └─────────────────────┘   └─────────────────────┘   └─────────────────────┘
```

### 2.1 Theme 1: `CraftEditorialTheme` (`.editorial`) — The Academic Masterclass
- **Concept:** Blends the timeless dignity of vintage dictionary typography with modern iOS 26 Liquid Glass materials.
- **Audience:** Adult learners, IELTS/TOEIC aspirants, serious vocabulary enthusiasts who want calm, distraction-free elegance.
- **Color Palette:**
  - `canvasBackground`: Light `#FAF9F5` (Warm Linen) / Dark `#121615` (Obsidian Botanical)
  - `surfaceCard`: Light `#FFFFFF` (Pristine White) / Dark `#1A2220` (Elevated Forest Slate)
  - `surfaceSubtle`: Light `#F3EFE6` (Linen Tint) / Dark `#161D1B` (Deep Subtle)
  - `brandPrimary`: Light `#0D9488` (Teal 600) / Dark `#14B8A6` (Teal 500)
  - `brandSecondary`: Light `#059669` (Emerald 600) / Dark `#10B981` (Emerald 500)
  - `accent`: Light `#F97316` (Apricot Orange) / Dark `#FB923C` (Bright Apricot)
  - `textPrimary`: Light `#131E1B` (Botanical Charcoal) / Dark `#F4FDF9` (Linen White)
  - `textSecondary`: Light `#4A5E58` / Dark `#9EB3AC`
- **Typography:**
  - `displaySerif`: `.system(.largeTitle, design: .serif, weight: .bold)`
  - `displayHero`: `.system(size: 72, weight: .bold, design: .serif)`
  - `titleLarge`: `.system(.title, design: .serif, weight: .bold)`
  - `phonetic`: `.system(.callout, design: .monospaced, weight: .regular)`
  - `metricRounded`: `.system(.title2, design: .rounded, weight: .bold)`

---

### 2.2 Theme 2: `CraftNeoArcadeTheme` (`.neoArcade`) — The Dopamine Gamifier
- **Concept:** High-octane gamification, hyper-vibrant accents, high-contrast feedback, playful bouncy springs.
- **Audience:** Casual learners, speed reflex drillers, users motivated by streak fires and arcade-style badges.
- **Color Palette:**
  - `canvasBackground`: Light `#F8FAFC` (Ice White) / Dark `#0B0F19` (Cyber Midnight)
  - `surfaceCard`: Light `#FFFFFF` / Dark `#141C2E` (Electric Elevated Navy)
  - `surfaceSubtle`: Light `#F1F5F9` / Dark `#0F172A`
  - `brandPrimary`: Light `#84CC16` (Cyber Lime) / Dark `#A3E635` (Fluorescent Lime)
  - `brandSecondary`: Light `#06B6D4` (Cyan Pulse) / Dark `#22D3EE`
  - `accent`: Light `#6366F1` (Electric Indigo) / Dark `#818CF8`
  - `textPrimary`: Light `#0F172A` (Midnight Slate) / Dark `#F8FAFC`
  - `textSecondary`: Light `#475569` / Dark `#94A3B8`
- **Typography:**
  - 100% SF Pro Rounded across all scales (`displayLarge`, `titleLarge`, `headline`, `bodyLarge`, `label`) for energetic, playful punchiness.
- **Physics & Motion:**
  - `springSnappy`: `.spring(response: 0.18, dampingFraction: 0.60)`
  - `springBouncy`: `.spring(response: 0.38, dampingFraction: 0.50)` (High celebration bounce)

---

### 2.3 Theme 3: `CraftNordicZenTheme` (`.nordicZen`) — The Calm Sanctuary
- **Concept:** Scandinavian minimalism, spacious layout breathing room, subtle monochromatic base with a single ethereal lavender/frost accent.
- **Audience:** Focus-driven learners who experience sensory overload from typical gamified apps.
- **Color Palette:**
  - `canvasBackground`: Light `#F4F4F5` (Mist Gray) / Dark `#18181B` (Atmospheric Graphite)
  - `surfaceCard`: Light `#FFFFFF` / Dark `#27272A` (Graphite Elevated)
  - `surfaceSubtle`: Light `#E4E4E7` / Dark `#202023`
  - `brandPrimary`: Light `#8B5CF6` (Celestial Lavender) / Dark `#A78BFA`
  - `brandSecondary`: Light `#6D28D9` / Dark `#C4B5FD`
  - `accent`: Light `#06B6D4` (Frost Cyan) / Dark `#38BDF8`
  - `textPrimary`: Light `#18181B` (Zinc 900) / Dark `#FAFAFA`
  - `textSecondary`: Light `#71717A` / Dark `#A1A1AA`
- **Typography:**
  - Clean, unadorned SF Pro Default with spacious line spacing and lighter weights.

---

### 2.4 Theme 4: `CraftDefaultTheme` (`.classic`) — The Balanced Modernist
- **Concept:** Warm rust coral `#E06D3B`, vibrant amber `#F59E0B`, balanced slate neutrals.
- **Color Palette:**
  - `canvasBackground`: Light `#FAFAF8` / Dark `#121214`
  - `surfaceCard`: Light `#FFFFFF` / Dark `#1C1C1E`
  - `brandPrimary`: `#E06D3B` (Warm Coral)
  - `accent`: `#F59E0B` (Amber)

---

## 3. Dark Mode Architectural Principles

```
  ┌──────────────────────────────────────────────────────────────┐
  │                 2026 Atmospheric Dark Mode                   │
  ├──────────────────────────────────────────────────────────────┤
  │ 1. Zero Pitch Black (#000000 banned for canvas)              │
  │ 2. Themed Undertones (Obsidian #121615, Midnight #0B0F19)     │
  │ 3. Specular Edge Highlight (white.opacity(0.15-0.20))        │
  │ 4. Luminous Semantic Accents (Higher L-value for Dark)       │
  │ 5. WCAG AA Contrast Compliance (>= 4.5:1 for body text)      │
  └──────────────────────────────────────────────────────────────┘
```

1. **Undertone Harmony**: Dark canvases preserve the identity of the theme. Editorial dark is botanical; Neo-Arcade dark is cyber navy; Nordic Zen dark is neutral graphite.
2. **Elevated Hierarchy**:
   - Level 0 (Canvas): Base background
   - Level 1 (Card / Row): +6% lightness with subtle border (`borderDefault`)
   - Level 2 (Sheet / Popover / Dialog): +12% lightness with drop shadow (`shadows.lg` / `shadows.xl`)
   - Level 3 (Floating Bar / Glass): Ultra-thin material blur + specular gradient rim (`glass.borderGradient`)
3. **Contrast Calibration**: In dark mode, primary accent colors are lightened by ~10–15% luminance to prevent low-contrast vibration against dark surfaces.

---

## 4. CraftUIKit Architecture & Code Structure

### 4.1 Token Structure in `CraftUIKit`

```
Packages/CraftUIKit/Sources/CraftUIKit/Tokens/
├── CraftTheme.swift                      // Root protocol & environment definition
├── CraftThemePreset.swift                // [NEW] Enum registry of all 4 presets
├── CraftColorTokens.swift                // Protocol & Color helper extensions
├── CraftTypographyTokens.swift           // Protocol & multi-axis scale styles
├── CraftSpacingTokens.swift              // 8pt grid & serpentine path spacing
├── CraftRadiusTokens.swift               // Corner radii
├── CraftShadowTokens.swift               // Multi-layer drop shadows
├── CraftGradientTokens.swift             // Linear & angular gradients
├── CraftDepthTokens.swift                // 3D tactile depth & bevel highlights
├── CraftGlassTokens.swift                // Liquid glass refraction & border gradients
├── CraftAnimationTokens.swift            // Spring motion curves
├── CraftOpacityTokens.swift              // Opacity scale
└── Themes/
    ├── CraftDefaultTheme.swift           // Classic Slate (.classic)
    ├── CraftEditorialTheme.swift         // [NEW] Warm Editorial (.editorial)
    ├── CraftNeoArcadeTheme.swift         // [NEW] Neo-Arcade (.neoArcade)
    └── CraftNordicZenTheme.swift          // [NEW] Nordic Zen (.nordicZen)
```

### 4.2 `CraftThemePreset` Registry

```swift
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

---

## 5. Main Application Integration (`VocabCraftApp`)

1. **`UserSettingsStore` / `ThemeManager`**:
   - Store selected `themePreset` (String enum rawValue) in `@AppStorage("app_theme_preset")`.
   - Store appearance preference (`system`, `light`, `dark`) in `@AppStorage("app_color_scheme")`.
2. **App Root Wiring**:
   ```swift
   @main
   struct VocabCraftApp: App {
       @State private var themeManager = AppThemeManager.shared

       var body: some Scene {
           WindowGroup {
               RootAppView()
                   .craftTheme(themeManager.currentPreset.theme)
                   .preferredColorScheme(themeManager.preferredColorScheme)
           }
       }
   }
   ```
3. **Interactive Showcase in `CraftCatalogView`**:
   - Toolbar segment allowing instant switching between `.editorial`, `.neoArcade`, `.nordicZen`, and `.classic`.
   - Side-by-side verification of all UI components (Cards, Buttons, Path, Streak, Audio, Feedback).

---

## 6. Verification & Quality Gates

1. **Unit & Snapshot Tests**:
   - `ThemeTests.swift`: Verify all 4 themes instantiate properly and conform to `CraftTheme`.
   - `ColorTokensTests.swift`: Verify dynamic light/dark resolution for every token in all 4 presets.
   - `LocalizationTests.swift`: Verify zero missing strings across EN & VI.
2. **WCAG AA Accessibility Audit**:
   - Minimum 4.5:1 text-to-background contrast ratio verified for all themes in both Light and Dark mode.
   - Minimum 44x44pt touch targets preserved across all control components.
