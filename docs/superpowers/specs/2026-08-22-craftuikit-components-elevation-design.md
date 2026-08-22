# CraftUIKit Core Components Visual Elevation Specification

**Date:** 2026-08-22  
**Scope:** `CraftButton`, `CraftSearchBar`, `CraftFloatingTabBar`  
**Status:** Approved for Implementation Planning  

---

## 1. Overview & Objectives

This specification outlines the visual, tactile, and functional enhancements to three foundational `CraftUIKit` components based on modern dark-mode aesthetic principles (dark slate atmospheric depth, vibrant violet/indigo accents, and tactile 3D physical cues).

### Goals
- **CraftButton**: Introduce tactile 3D bevel/lip depth, uppercase tracking support, and haptic feedback while preserving all existing variants (`.primary`, `.secondary`, `.outline`, `.ghost`, `.danger`).
- **CraftSearchBar**: Introduce dark recessed glass styling, optional rounded squircle vs capsule shapes, luminous focus glow, and trailing action slots.
- **CraftFloatingTabBar**: Upgrade active tab indicator to an elevated pill-bubble container enclosing both icon and label, with smooth `matchedGeometryEffect` spring transitions, hairline specular borders, and optional badge support on `CraftTabItemProtocol`.

---

## 2. Component Specifications

### 2.1 CraftButton (Tactile 3D Push & Typography)

#### Enhancements
1. **New Variant**: `CraftButtonVariant.tactile`
   - Rendered with a solid bottom lip offset (`3-4pt`) beneath the primary surface.
   - When pressed (`configuration.isPressed`), the button face translates down (`offset(y: 3)`), and the bottom shadow compresses, creating an authentic arcade/physical button push feeling.
   - Integrated with haptic feedback on press.
2. **Typography & Styling Parameters**:
   - `isUppercase: Bool = false`: Renders text in uppercase when true.
   - `tracking: CGFloat? = nil`: Custom letter-spacing (e.g. `1.2pt` for punchy CTA action buttons like "PRACTICE").
   - `isFullWidth: Bool = false`: Expands button to fill parent horizontal width.
3. **Compatibility**:
   - Existing standard variants (`.primary`, `.secondary`, `.outline`, `.ghost`, `.danger`) and sizes (`.sm`, `.md`, `.lg`) remain 100% compatible.

---

### 2.2 CraftSearchBar (Recessed Glass & Trailing Actions)

#### Enhancements
1. **New Visual Styles (`CraftSearchBarStyle`)**:
   - `.standard`: Default clean surface subtle background.
   - `.recessed`: Dark translucent glass / inset surface with subtle top-inner depth and crisp hairline border.
2. **Shape Options (`CraftSearchBarShape`)**:
   - `.capsule`: Classic pill shape.
   - `.roundedRectangle(radius: CGFloat)`: Rounded squircle shape (default `14pt`).
3. **Focus State & Glow**:
   - Smooth animated transition for the focus ring with subtle ambient brand glow (`theme.colors.borderFocus.opacity(0.2)`).
4. **Trailing Action Slot**:
   - Optional `trailingAction: AnyView?` slot to support custom filter buttons, voice search icons, or quick actions.

---

### 2.3 CraftFloatingTabBar (Pill-Bubble Active Indicator)

#### Enhancements
1. **Pill-Bubble Active Tab Highlight**:
   - The selected tab is wrapped in an elevated pill/capsule background (`theme.colors.surfaceElevated` with subtle translucent tint and hairline border) that cleanly encapsulates both the icon and title.
   - Uses SwiftUI `matchedGeometryEffect` with `springSnappy` physics for smooth sliding between tabs.
2. **Tab Protocol Extension**:
   - `CraftTabItemProtocol` extended with optional `var badgeCount: Int? { get }` (defaulting to `nil` via extension) to support notification badges or indicator dots.
3. **Floating Glass Container**:
   - Outer capsule with `.ultraThinMaterial` / dark glass tint, specular hairline border (`hairline`), and multi-layer floating drop shadow (`craftShadow(.lg)`).
4. **Haptic Interactions**:
   - Integrated selection haptics on iOS when switching tabs.

---

## 3. Catalog Showcase & Verification

### 3.1 Catalog Updates (`CraftCatalogView.swift`)
- **Buttons Section**: Showcase `.tactile` variant with 3D push down, uppercase tracking ("PRACTICE"), and compare with existing variants.
- **TextFields & Search Section**: Showcase `.recessed` search bar style with focus glow and trailing filter actions.
- **Navigation Section**: Showcase the new Pill-Bubble floating tab bar with and without badges.

### 3.2 Unit Test Verification (`ControlComponentTests.swift` & `NavigationTests.swift`)
- Test `.tactile` button initialization, height, and action firing.
- Test `CraftSearchBar` new style and shape parameters.
- Test `CraftFloatingTabBar` with updated `CraftTabItemProtocol` and badge support.
- Verify full test suite passes with `swift test`.
