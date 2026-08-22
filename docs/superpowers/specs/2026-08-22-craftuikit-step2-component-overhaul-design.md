# CraftUIKit Step 2: Component Overhaul & Anti-Slop Standardization Design

## 1. Executive Summary & Problem Statement

This design document establishes the visual, structural, and behavioral specifications for **Step 2** of the `CraftUIKit` UI standardization. The purpose is to eradicate remaining AI-slop patterns (generic single-circle sparkles, floating purple-gradient FABs, unreadable badge text on amber backgrounds, low-contrast dark mode selections) and implement native Apple-grade UI patterns tailored for `VocabCraft` and extensible to future iOS apps.

---

## 2. Component Design & Architectural Specifications

### 2.1. `CraftEmptyState` (3-Tier Layered Squircle & Domain Defaults)

#### Problem Being Solved
- Generic 72×72 single-circle containing `"sparkles"`. Sparkles in an empty state conveys "AI generation / magic" rather than purposeful guidance or empty-deck status.
- Lacks depth, feeling flat and template-like.

#### Visual Architecture
- **Layer 1 (Outer Base)**: 88×88pt squircle (`RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)`), background fill `theme.colors.surfaceSubtle`, stroke border `theme.colors.borderDefault.opacity(0.6)` at 1pt width.
- **Layer 2 (Inner Accent Pill)**: 56×56pt squircle (`RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)`), background fill `theme.colors.brandPrimary.opacity(0.12)`.
- **Layer 3 (Focal Icon)**: 24pt (`size: .lg`) SF Symbol rendered via `CraftIcon` in `.hierarchical` mode and `.bold` weight, foreground color `theme.colors.brandPrimary`.
- **Shadow**: Ambient subtle elevation via `theme.shadows.sm`.

#### Semantic Domain Defaults
- Default symbol: `CraftSymbol.study` (`character.book.closed`).
- Contextual variants supported: `.search` (empty search), `.bookmark` (empty bookmarks), `.list` (empty word lists).

#### Public API Interface
```swift
public struct CraftDefaultEmptyStateIllustration: View {
    public init(symbol: CraftSymbol = .study)
    public init(iconName: String = "character.book.closed")
}

public struct CraftEmptyState<Illustration: View>: View {
    // Generic with custom illustration
    public init(title: String, message: String?, buttonTitle: String?, buttonIcon: String?, buttonAction: (() -> Void)?, illustration: () -> Illustration)
    public init(title: LocalizedStringKey, message: LocalizedStringKey?, buttonTitle: LocalizedStringKey?, buttonIcon: String?, buttonAction: (() -> Void)?, illustration: () -> Illustration)
}

public extension CraftEmptyState where Illustration == CraftDefaultEmptyStateIllustration {
    // Concrete convenience inits
    public init(symbol: CraftSymbol = .study, title: String, message: String?, buttonTitle: String?, buttonSymbol: CraftSymbol?, buttonAction: (() -> Void)?)
    public init(iconName: String = "character.book.closed", title: String, message: String?, buttonTitle: String?, buttonIcon: String?, buttonAction: (() -> Void)?)
    public init(symbol: CraftSymbol = .study, title: LocalizedStringKey, message: LocalizedStringKey?, buttonTitle: LocalizedStringKey?, buttonSymbol: CraftSymbol?, buttonAction: (() -> Void)?)
    public init(iconName: String = "character.book.closed", title: LocalizedStringKey, message: LocalizedStringKey?, buttonTitle: LocalizedStringKey?, buttonIcon: String?, buttonAction: (() -> Void)?)
}
```

---

### 2.2. `CraftBadge` (WCAG 2.1 AAA Contrast & Hierarchical Depth)

#### Problem Being Solved
- In `.solid` variant, foreground text and icon color is hardcoded to `.white`. When `tone == .warning` (amber `#F59E0B`), white text on amber has a contrast ratio of **~1.8:1**, violating WCAG 2.1 minimum contrast requirements (4.5:1 for normal text).
- In `.subtle` variant, lack of stroke border causes the badge to blend indistinctly into surrounding cards.

#### Visual Architecture & Contrast Rules
- **Contrast Logic**:
  - When `variant == .solid` AND `tone == .warning`: foreground color switches dynamically to Dark Ink (`Color(hex: 0x18181B)`), achieving **> 9.5:1** contrast ratio (WCAG AAA).
  - When `variant == .solid` AND `tone != .warning`: foreground color remains `.white` (contrast > 5.2:1).
  - When `variant == .subtle` OR `variant == .outline`: foreground color matches `toneColor`.
- **Border Refinement**:
  - `.subtle` variant: Capsule fill `toneColor.opacity(0.14)` + stroke border `toneColor.opacity(0.24)` at 1pt width.
  - `.outline` variant: Capsule stroke `toneColor` at 1pt width.
- **Icon Slot**: Rendered using `CraftIcon` with `.hierarchical` mode in subtle/outline variants and `.bold` font weight.

#### Public API Interface
```swift
public struct CraftBadge: View {
    public init(_ title: String, symbol: CraftSymbol, variant: CraftBadgeVariant = .subtle, tone: CraftBadgeTone = .primary, size: CraftBadgeSize = .md)
    public init(_ title: String, iconName: String? = nil, variant: CraftBadgeVariant = .subtle, tone: CraftBadgeTone = .primary, size: CraftBadgeSize = .md)
    public init(_ titleKey: LocalizedStringKey, symbol: CraftSymbol? = nil, variant: CraftBadgeVariant = .subtle, tone: CraftBadgeTone = .primary, size: CraftBadgeSize = .md)
    public init(_ titleKey: LocalizedStringKey, iconName: String? = nil, variant: CraftBadgeVariant = .subtle, tone: CraftBadgeTone = .primary, size: CraftBadgeSize = .md)
    public init(verbatim title: String, symbol: CraftSymbol? = nil, variant: CraftBadgeVariant = .subtle, tone: CraftBadgeTone = .primary, size: CraftBadgeSize = .md)
    public init(verbatim title: String, iconName: String? = nil, variant: CraftBadgeVariant = .subtle, tone: CraftBadgeTone = .primary, size: CraftBadgeSize = .md)
}
```

---

### 2.3. `CraftChoiceCard` (Dark Mode Contrast & Dual-Tone Indicators)

#### Problem Being Solved
- In Dark Mode on elevated card surfaces (`#1C1C1E`), the `.selected` state background opacity is `0.08`, making it nearly indistinguishable from unselected cards.
- Status checkmark and crossmark icons are monochrome without depth.

#### Visual Architecture & States
- **Background & Border Tuning**:
  - `.idle` / `.disabled`: Background `theme.colors.surfaceCard`, border `theme.colors.borderDefault` 1pt.
  - `.selected`: Background `theme.colors.brandPrimary.opacity(0.16)` (both Light and Dark modes), border `theme.colors.brandPrimary` 2pt.
  - `.correct`: Background `theme.colors.statusSuccess.opacity(0.16)`, border `theme.colors.statusSuccess` 2pt.
  - `.wrong`: Background `theme.colors.statusDanger.opacity(0.16)`, border `theme.colors.statusDanger` 2pt.
- **Hierarchical Indicators**:
  - Correct state: `CraftIcon(.checkmarkCircle, size: .lg, color: theme.colors.statusSuccess, renderingMode: .hierarchical, weight: .bold)`.
  - Wrong state: `CraftIcon(.wrongCircle, size: .lg, color: theme.colors.statusDanger, renderingMode: .hierarchical, weight: .bold)`.
- **Haptics & Motion**: Spring snappy animation on tap (`theme.animations.springSnappy`), minimum 44pt touch area.

---

### 2.4. `CraftFloatingTabBar` (Liquid Glass & Integrated Action Button)

#### Problem Being Solved
- Center action slot is currently an elevated floating FAB with a heavy purple gradient (`0x6366F1` $\rightarrow$ `0x8B5CF6`). This template pattern looks unnatural on native iOS.

#### Visual Architecture
- **Bar Container**: Capsule shape with `.ultraThinMaterial` background, `theme.colors.hairline` 1pt stroke border, elevated with `theme.shadows.lg`.
- **Sliding Indicator**: Smooth capsule highlight `theme.colors.brandPrimary.opacity(0.12)` sliding beneath active tabs via `matchedGeometryEffect(id: "activeTabIndicator", in: tabNamespace)`.
- **Active Tab Item**: Title in `theme.typography.caption` (semibold), icon rendered via `CraftIcon` with `.hierarchical` rendering and `.bold` weight in `brandPrimary`.
- **Integrated Center Action Button**:
  - Seamlessly integrated 44×44pt circle inside the bar aligned with adjacent tabs.
  - Solid background in `theme.colors.brandPrimary` with ambient elevation shadow.
  - Icon in `theme.colors.textInverse` with `.bold` weight.

---

### 2.5. `CraftCatalogView` (Design Gallery Synchronization)

#### Visual Architecture
- Updated sections demonstrating:
  1. **Typography & Symbols Scale**: Complete matrix of `CraftSymbol` categories.
  2. **Layered Empty States**: Interactive switcher showcasing `.study`, `.search`, `.bookmark` empty states.
  3. **WCAG AAA Badges**: Full grid of tones (`primary`, `success`, `warning`, `danger`, `neutral`) across all 3 variants (`solid`, `subtle`, `outline`).
  4. **Interactive Quiz Cards**: Dynamic quiz testing `.idle`, `.selected`, `.correct`, `.wrong` with haptics and dark mode toggle.
  5. **Liquid Glass Navigation**: Fully functional floating tab bar.

---

## 3. Accessibility & HIG Standards

1. **Touch Target Guarantee**: Every interactive control maintains a minimum bounding box of 44×44pt.
2. **Dynamic Type**: All text labels use typography tokens scaling with system Dynamic Type.
3. **VoiceOver**: All components declare accessibility labels, values, and traits (`.isButton`, `.isSelected`).
4. **Reduce Motion**: Animations respect `@Environment(\.accessibilityReduceMotion)`.

---

## 4. Testing & Verification Strategy

1. **Automated Unit Tests**:
   - `AtomComponentTests.swift`: Test badge contrast logic, symbol inits, and rendering modes.
   - `ContainerOverlayTests.swift`: Test layered empty state illustration rendering and symbol convenience inits.
   - `InteractiveCardTests.swift`: Test choice card dark mode contrast and state indicators.
   - `NavigationTests.swift`: Test floating tab bar selection and center action tap.
   - `CatalogViewTests.swift`: Test catalog body rendering.
2. **Build Verification**:
   - `swift test` across the entire test suite (138+ tests).
   - `swift build` for clean module emission.
