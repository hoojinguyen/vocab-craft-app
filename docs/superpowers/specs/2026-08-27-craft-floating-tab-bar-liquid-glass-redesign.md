# CraftFloatingTabBar Architecture & Liquid Glass Fluid Motion Design

**Date:** 2026-08-27  
**Status:** Approved by User  
**Target:** `Packages/CraftUIKit` and `VocabCraftApp`

---

## 1. Overview & Objectives

In previous iterations, `CraftFloatingTabBar` was integrated into the main application. However, several UX, animation, and architectural shortcomings were identified:
1. **Liquid Glass Optical & Fluid Motion Deficiencies**: The active selection indicator was a flat, semi-transparent colored rectangle shifting linearly via `matchedGeometryEffect`, lacking the optical refraction, specular rim reflections, and fluid squash/stretch kinetics characteristic of Apple's Liquid Glass philosophy (iOS 26+ / HIG).
2. **Animation Conflict (Button Press vs Geometry Matching)**: `CraftTabButton` applied `.buttonStyle(.craftPress(scale: 0.95))` to the entire button view while simultaneously hosting `matchedGeometryEffect` inside its background, causing coordinate-space distortion, jumps, and jitter during tab transitions.
3. **Coupled Presentation Control**: `showsTitles` was dictated globally by the parent `CraftFloatingTabBar` rather than being encapsulated within individual tab item models (`CraftTabItemProtocol`), limiting flexibility and muddying component responsibilities.

This specification details the architectural decoupling into a 3-tier coordinate-tracked rendering hierarchy, a fluid optical glass lens engine with squash/stretch spring kinematics, and the encapsulation of item-level presentation properties into `CraftTabItemProtocol`.

---

## 2. Architectural Design & Layer Decoupling

### 2.1 3-Tier Layered Rendering Engine

The tab bar is reorganized into three isolated, independently-responsible visual tiers:

```
┌──────────────────────────────────────────────────────────────┐
│  Tier 3: Foreground Interactive Tab Strip                    │
│  - 44x44pt minimum touch targets                             │
│  - SF Symbol hierarchical micro-bounce & label rendering     │
│  - Notification Badge relative anchoring                     │
│  - Reports exact frame bounds via TabBarItemPreferenceKey    │
├──────────────────────────────────────────────────────────────┤
│  Tier 2: Sliding Fluid Glass Lens Layer                      │
│  - Independent sliding glass pill on a coordinate track      │
│  - Optical specular rim light, gradient refraction, glow     │
│  - Squash & Stretch kinetic scaling during translation       │
│  - Decoupled from tab button press-down gestures             │
├──────────────────────────────────────────────────────────────┤
│  Tier 1: Background Glass Capsule Container                  │
│  - GlassEffectContainer & .glassEffect() on iOS 26+          │
│  - UltraThinMaterial + dual hairline top highlight fallback  │
│  - Surface styles: .glass, .elevated, .tactile3D, etc.       │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Coordinate Space Tracking (`TabBarItemPreferenceKey`)

Instead of embedding `matchedGeometryEffect` within individual button backgrounds, each tab button reports its local frame within the named coordinate space `"CraftTabBarTrack"`:

```swift
public struct TabBarItemFrameData: Equatable, Sendable {
    public let id: String
    public let frame: CGRect
}

public struct TabBarItemPreferenceKey: PreferenceKey {
    public static var defaultValue: [String: CGRect] = [:]
    public static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
```

The sliding glass pill reads the frame of the selected tab item and animates its `offset` and `frame(width:height:)` using a fluid spring.

---

## 3. Liquid Glass Optics & Fluid Motion Kinematics

### 3.1 Squash & Stretch Kinetics

During tab transitions, the active glass indicator undergoes natural fluid deformation:
- **Travel Phase**: When navigating between distant or adjacent tabs, the pill stretches along the horizontal axis (`scaleEffect(x: isTransitioning ? 1.08 : 1.0, y: isTransitioning ? 0.94 : 1.0)`) simulating fluid momentum and liquid surface tension.
- **Settle Phase**: Upon reaching the target frame, the pill snaps back to `1.0x` with a micro-overshoot dampening curve (`Spring(duration: 0.36, bounce: 0.18)` or `theme.animations.springSnappy`).
- **Rapid-Tap Immunity**: Because the animation is driven by continuous spring coordinate interpolation, rapid multi-tab tapping glides seamlessly without jarring layout resets.

### 3.2 Optical Material Layers (Glass Lens)

For `style == .glass`:
1. **Specular Glass Base**:
   - **iOS 26+**: `.glassEffect(.regular.tint(theme.colors.brandPrimary).interactive(), in: .capsule)` inside `GlassEffectContainer`.
   - **Pre-iOS 26 (Fallback)**: Multi-stop linear gradient (`brandPrimary.opacity(0.16)` to `brandPrimary.opacity(0.08)`) with subtle material translucency.
2. **Specular Rim Light (Refraction Ring)**:
   - `0.8pt` continuous capsule stroke with an asymmetric white-to-brand gradient (`white.opacity(0.40)` at top to `brandPrimary.opacity(0.12)` at bottom).
3. **Ambient Glow**:
   - Subtle diffuse shadow (`brandPrimary.opacity(0.20)`, radius `6`, y `2`) providing optical depth.

### 3.3 SF Symbol Micro-Interactions

- **Active Tab Icon**: Scales up to `1.08x` with `.symbolEffect(.bounce, value: isSelected)` and `.hierarchical` rendering mode.
- **Inactive Tab Icon**: Rests at `1.0x` with `.monochrome` rendering mode and `textMuted` color.

---

## 4. Tab Item Presentation Encapsulation (`CraftTabItemProtocol`)

### 4.1 Protocol Expansion

Presentation attributes are moved to the tab item model, ensuring each item dictates its visual composition while retaining full metadata for VoiceOver:

```swift
public protocol CraftTabItemProtocol: Identifiable, Equatable, Sendable where ID: Sendable & Hashable {
    var id: ID { get }
    var title: String { get }
    var symbol: String { get }
    var badgeCount: Int? { get }
    var titleKey: LocalizedStringKey? { get }
    
    /// Whether this tab item visibly displays its label text (default: `true`).
    var showsTitle: Bool { get }
    
    /// Whether this tab item visibly displays its symbol icon (default: `true`).
    var showsSymbol: Bool { get }
}

public extension CraftTabItemProtocol {
    var badgeCount: Int? { nil }
    var titleKey: LocalizedStringKey? { nil }
    var showsTitle: Bool { true }
    var showsSymbol: Bool { true }
}
```

### 4.2 Streamlined `CraftFloatingTabBar` Initializers

The `showsTitles: Bool` parameter is removed from `CraftFloatingTabBar` initializers. The component inspects `item.showsTitle` and `item.showsSymbol` directly per button.

### 4.3 VoiceOver & Accessibility Accessibility Guarantee

Regardless of whether `showsTitle` is `true` or `false`, the accessibility tree always receives the localized string key or raw title:
```swift
.accessibilityLabel(accessibilityTitle)
.accessibilityValue(accessibilityBadgeValue)
.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
```

---

## 5. Center Action Button & Gap Geometry

When `centerAction != nil`:
- `CraftFloatingTabBar` splits tabs into leading and trailing partitions.
- A center spacer frame (`width: centerPosition == .floating ? 56 : 42, height: 44`) maintains layout equilibrium without registering in `TabBarItemPreferenceKey`.
- The sliding indicator glides cleanly across the center gap when moving from a leading tab to a trailing tab.

---

## 6. Accessibility & Compliance

- **Reduce Motion (`@Environment(\.accessibilityReduceMotion)`)**:
  - Disables squash/stretch deformation and spring bounce. Transitions execute via instant state update or a gentle, non-bouncing linear fade.
- **Reduce Transparency (`@Environment(\.accessibilityReduceTransparency)`)**:
  - Replaces translucent glass materials with high-contrast opaque `surfaceCard` backgrounds with solid `borderDefault` strokes.
- **Zero Hardcoded Strings**:
  - All accessibility labels, badge count formats (`craft.tab_bar.badge_count_format`), and center fallback titles adhere strictly to `CraftLocalized` and `Localizable.xcstrings`.

---

## 7. Migration & Testing Strategy

### 7.1 Files Affected
1. `Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`
   - Update `CraftTabItemProtocol`, `CraftTabItem`.
   - Implement 3-tier coordinate tracking with `TabBarItemPreferenceKey`.
   - Add fluid squash/stretch kinematics and specular optical glass styling.
   - Remove `showsTitles` parameter.
2. `Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
   - Update catalog previews to adopt item-level `showsTitle`.
3. `Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`
   - Update unit tests for `showsTitle` / `showsSymbol` protocol properties and initializer signatures.
4. `VocabCraftApp/App/Navigation/TabItem.swift`
   - Declare `showsTitle = false` on `TabItem`.
5. `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
   - Update `CraftFloatingTabBar` call site (removing redundant `showsTitles: false`).
6. `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`
   - Update test fixtures to match updated initializer signatures.

### 7.2 Verification Gates
- `swift test` in `Packages/CraftUIKit` (0 errors, 100% pass).
- Full app test suite via `xcodebuild test` or `HomepageViewTests`.
- Simulator visual verification of liquid glass morphing, spring squash/stretch, and rapid tab switching.
