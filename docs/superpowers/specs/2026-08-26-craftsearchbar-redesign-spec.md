# CraftSearchBar UI/UX, Performance & Full-Spectrum Styles Design Spec

**Author:** Senior iOS & SwiftUI Design / Performance Agent  
**Date:** 2026-08-26  
**Target:** CraftUIKit Component Evolution — `CraftSearchBar`  
**Platforms:** iOS 17.0+ (SwiftUI, Xcode 16+)

---

## 1. Overview & Problem Statement

`CraftSearchBar` is a fundamental navigation and discovery control within CraftUIKit. A comprehensive audit across `ios-design-agent-skill`, `swiftui-design-skill`, and `swiftui-performance` revealed:
1. **Performance Hitching on Tap:** Double spring animation modifiers (`.animation(springSnappy, value: isFocused)` on both inner and outer `HStack`), continuous GPU offscreen passes from dynamic shadow blur recalculation, and simultaneous layout width shrink during iOS keyboard presentation create noticeable frame drops and perceived responsiveness lag.
2. **Hit-Testing Dead Zones:** Tapping on padding, icons, or spacing outside the core `TextField` bounds does not activate focus smoothly.
3. **Limited Style Spectrum:** `CraftSearchBarStyle` currently supports only `.standard`, `.recessed`, `.glass`, missing CraftUIKit's standardized surface styles (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`).
4. **Missing Size Scalability:** Fixed 44pt height with no compact (`sm` 36pt) or hero (`lg` 52pt) options.
5. **Lack of Sensory Feedback & SF Symbol Motion:** Clear and Cancel actions lack haptic confirmation, and the search symbol is static without state-driven bounce or loading transitions.

---

## 2. Design Goals & Anti-Slop Principles

- **Zero Lag Focus & Dismiss:** Single container-scoped animation, stable shadow rendering, tap hit-testing across the entire pill/container, and asynchronous keyboard layout accommodation.
- **Full-Spectrum Surface Styles:** Full parity with `CraftSurfaceStyle` (`flat`, `elevated`, `outlined`, `recessed`, `tactile3D`, `glass`) + support for `customTint` and `customGradient`.
- **Three Ergonomic Sizes:**
  - `.sm` (36pt height, 14pt typography, `.sm` icons, 8pt horizontal padding): Ideal for dense filter bars and navigation toolbars.
  - `.md` (44pt height, 16pt typography, `.md` icons, 12pt horizontal padding): Standard search input for lists and sheets.
  - `.lg` (52pt height, 17pt typography, `.md`/`.lg` icons, 16pt horizontal padding): Hero search on Explore & Home tabs.
- **Sensory & Visual Polish:**
  - SF Symbol `.bounce` effect on focus activation and query submit.
  - Haptic `.sensoryFeedback(.impact(weight: .light))` on Clear and Cancel.
  - Smooth asymmetric scale/opacity transitions for Clear button.
  - Optional `isLoading` state displaying a themed `CraftSpinner`.
  - Apple HIG compliant 44x44pt minimum touch target bounds for action buttons.

---

## 3. Architecture & API Design

### 3.1 Style & Size Enums

```swift
public enum CraftSearchBarStyle: String, Sendable, CaseIterable {
    case standard
    case flat
    case elevated
    case outlined
    case recessed
    case tactile3D
    case glass
    
    public var surfaceStyle: CraftSurfaceStyle {
        switch self {
        case .standard, .flat: return .flat
        case .elevated: return .elevated
        case .outlined: return .outlined
        case .recessed: return .flat
        case .tactile3D: return .tactile3D
        case .glass: return .glass
        }
    }
}

public enum CraftSearchBarSize: String, Sendable, CaseIterable {
    case sm
    case md
    case lg
    
    public var height: CGFloat {
        switch self {
        case .sm: return 36
        case .md: return 44
        case .lg: return 52
        }
    }
    
    public var iconSize: CraftIconSize {
        switch self {
        case .sm: return .sm
        case .md: return .md
        case .lg: return .md
        }
    }
}
```

### 3.2 Performance & Gesture Hardening

1. **Root Tap Interception:**
   ```swift
   .contentShape(Rectangle())
   .onTapGesture {
       if !isFocused {
           isFocused = true
       }
   }
   ```
2. **Unified Animation Modifier:**
   Remove inner `HStack` `.animation`, apply single:
   ```swift
   .animation(theme.animations.springSnappy, value: isFocused)
   ```
   with `.contentTransition(.opacity)` on action buttons.
3. **Optimized Text Configuration:**
   ```swift
   .autocorrectionDisabled()
   .textInputAutocapitalization(.never)
   .submitLabel(.search)
   ```

---

## 4. Verification & Testing

- Unit tests in `ControlComponentTests.swift` verifying all 7 style cases (`standard`, `flat`, `elevated`, `outlined`, `recessed`, `tactile3D`, `glass`), 3 size cases (`sm`, `md`, `lg`), `isLoading` state, custom tints/gradients, and localization.
- Catalog tests in `CatalogViewTests.swift` ensuring seamless rendering in `CraftCatalogView`.
