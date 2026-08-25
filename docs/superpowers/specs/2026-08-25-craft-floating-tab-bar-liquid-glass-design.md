# Design Specification: CraftFloatingTabBar Liquid Glass Upgrade (iOS 26+)

**Date:** 2026-08-25  
**Target:** `CraftUIKit` -> `CraftFloatingTabBar`  
**Status:** Approved by User for Spec Writing  

---

## 1. Overview & Objectives

The goal of this upgrade is to elevate `CraftFloatingTabBar` to Apple's latest **Liquid Glass (iOS 26+)** design standard while providing a rock-solid, high-contrast fallback for **iOS 17 and iOS 18**.

### Key Objectives:
1. **Adopt Native Liquid Glass on iOS 26+**: Leverage `GlassEffectContainer`, `.glassEffect(.regular, in: .capsule)`, and hardware-accelerated fluid morphing transitions (`glassEffectID`).
2. **Graceful Fallback on iOS 17/18**: Maintain a polished frosted-glass (`.ultraThinMaterial`) and multi-surface rendering engine (`.tactile3D`, `.elevated`, `.outlined`, `.flat`).
3. **Harmonious Active Tab Coloring**: Synchronize the selected tab item's text color with the icon color (`theme.colors.brandPrimary` when selected, `theme.colors.textMuted` when unselected).
4. **Icon-Only & Labelled Tab Modes**: Intelligently detect if tab titles are omitted or empty, rendering clean icon-only navigation without layout jitter or blank text views.
5. **Context-Adaptive Center FAB**: Automatically style the center action button with Liquid Glass Prominent styling when the bar is `.glass`, while preserving mechanical 3D extrusion (`CraftTactileFABButtonStyle`) when in `.tactile3D` mode.
6. **Accessibility & VoiceOver Compliance**: Fix the blank `accessibilityLabel` bug when using `LocalizedStringKey`, support `accessibilityReduceMotion` (instant switching), and `accessibilityReduceTransparency` (high-contrast opaque surfaces).

---

## 2. Architecture & Dual-Engine Rendering

```
CraftFloatingTabBar<Item: CraftTabItemProtocol>
├── @Environment(\.craftTheme) theme
├── @Environment(\.accessibilityReduceMotion) reduceMotion
├── @Environment(\.accessibilityReduceTransparency) reduceTransparency
├── @Namespace tabNamespace
│
└── Group {
    ├── if #available(iOS 26, *), style == .glass {
    │     GlassEffectContainer(spacing: 8) {
    │         HStack(spacing: theme.spacing.xs) {
    │             Leading Items (CraftTabButton)
    │             Center Action Button (CraftCenterActionButton) [Optional]
    │             Trailing Items (CraftTabButton)
    │         }
    │         .padding(.horizontal, theme.spacing.xs)
    │         .padding(.vertical, theme.spacing.xs)
    │         .glassEffect(.regular, in: .capsule)
    │     }
    │ }
    └── else {
          HStack(spacing: theme.spacing.xs) {
              Leading Items (CraftTabButton)
              Center Action Button (CraftCenterActionButton) [Optional]
              Trailing Items (CraftTabButton)
          }
          .padding(.horizontal, theme.spacing.xs)
          .padding(.vertical, theme.spacing.xs)
          .background { tabBarLegacyBackground }
          .modifier(TabBarShadowModifier(style: style, theme: theme))
    }
}
.padding(.horizontal, theme.spacing.base)
.padding(.bottom, theme.spacing.xs)
.accessibilityElement(children: .contain)
.sensoryFeedback(.selection, trigger: selectedItem.id)
```

---

## 3. Detailed Component Specifications

### 3.1 `CraftTabButton`
1. **Dynamic Content (Icon-Only vs Icon + Label)**:
   - Check if the item contains a non-empty title or `titleKey`:
     - If `titleKey != nil`: Render `Text(titleKey!)`.
     - Else if `!item.title.isEmpty`: Render `Text(item.title)`.
     - Else: Omit the text view entirely, vertically centering the icon within the 46pt touch target.
2. **Unified Brand Color Styling**:
   - **Icon**: `isSelected ? theme.colors.brandPrimary : theme.colors.textMuted` (renderingMode: `isSelected ? .hierarchical : .monochrome`).
   - **Text**: `isSelected ? theme.colors.brandPrimary : theme.colors.textMuted` (font weight: `isSelected ? .semibold : .regular`).
3. **Active Tab Indicator**:
   - **iOS 26+ (`style == .glass`)**:
     - Uses `glassEffectID("activeTabIndicator", in: namespace)` and `.glassEffectTransition(.matchedGeometry)`.
     - Background: subtle glass tint pill (`.glass(.regular.tint(theme.colors.brandPrimary.opacity(0.15)))` or translucent rounded rectangle `theme.colors.brandPrimary.opacity(0.12)`).
   - **Legacy Fallback / Other Styles**:
     - `style == .glass`: `RoundedRectangle(cornerRadius: 18).fill(reduceTransparency ? theme.colors.surfaceCard : theme.colors.brandPrimary.opacity(0.12))`.
     - `style == .tactile3D` / `.elevated`: `RoundedRectangle(cornerRadius: 18).fill(theme.colors.surfaceElevated.opacity(0.85))`.
4. **Accessibility (VoiceOver)**:
   - Determine label:
     ```swift
     if let titleKey = item.titleKey {
         Text(titleKey)
     } else if !item.title.isEmpty {
         Text(item.title)
     } else {
         Text(item.symbol.replacingOccurrences(of: ".", with: " ").capitalized)
     }
     ```
   - Add `.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])`.
   - If `badgeCount > 0`, append `.accessibilityValue("\(badgeCount) new items")`.

---

### 3.2 `CraftCenterActionButton`
The center action button adapts automatically according to the bar's `style`:
- **`style == .glass` (iOS 26+)**:
  - Circle button with `.buttonStyle(.glassProminent)` or `.buttonStyle(.glass(.regular.tint(theme.colors.brandPrimary)))` providing optical specular highlights and fluid touch interaction.
- **`style == .glass` (iOS 17/18 Fallback)**:
  - Frosted circular glass disc with `theme.gradients.brandHero` fill at high vibrancy and subtle highlight stroke.
- **`style == .tactile3D` / `.elevated` / `.outlined` / `.flat`**:
  - Retains `CraftTactileFABButtonStyle(depth: theme.depths.depthMd)` for the signature physical 3D extrusion bevel.

---

### 3.3 Motion & Accessibility Adaptations
1. **Reduce Motion (`@Environment(\.accessibilityReduceMotion)`)**:
   - Tab switching bypasses `withAnimation(springSnappy)` and updates `selectedItem` instantaneously.
   - Tactile 3D button press avoids spring scaling.
2. **Reduce Transparency (`@Environment(\.accessibilityReduceTransparency)`)**:
   - In pre-iOS 26 fallback mode, replaces `.ultraThinMaterial` with opaque `theme.colors.surfaceCard` to maintain AAA contrast ratios.

---

## 4. Public API Compatibility

No breaking changes to public APIs. All existing initializers and protocols remain 100% compatible:
- `public protocol CraftTabItemProtocol`: Preserves `id`, `title`, `symbol`, `badgeCount`, `titleKey`.
- `public struct CraftTabItem`: Preserves all initializers, allowing empty string `title: ""` for icon-only items.
- `public struct CraftFloatingTabBar<Item>`: Preserves `init(selectedItem:items:style:centerAction:centerSymbol:centerTitle:)` and localized variants.

---

## 5. Verification & Testing Plan

### Automated Unit Tests (`NavigationTests.swift`)
1. **`testFloatingTabBarSelectionAndBinding`**: Verify selection state updates.
2. **`testFloatingTabBarIconOnlyRendering`**: Verify tab items with empty titles render correctly without error.
3. **`testFloatingTabBarActiveColorMatching`**: Verify unified color token assignment for icon and text.
4. **`testFloatingTabBarAccessibilityLocalizedLabel`**: Verify VoiceOver labels for `LocalizedStringKey`, plain `String`, and icon-only tabs.
5. **`testFloatingTabBarAdaptiveCenterFAB`**: Verify FAB rendering in `.glass` vs `.tactile3D` modes.
6. **`testFloatingTabBarReduceMotionAndTransparency`**: Verify behavior under simulated accessibility flags.

### Visual Verification (`CraftCatalogView.swift` & Previews)
- Render `CraftFloatingTabBar` in:
  - Default Glass with text + icons
  - Icon-only configuration
  - With and without center FAB
  - All 5 `CraftSurfaceStyle` variants (`.glass`, `.tactile3D`, `.elevated`, `.outlined`, `.flat`)
  - Dark mode and Light mode.
