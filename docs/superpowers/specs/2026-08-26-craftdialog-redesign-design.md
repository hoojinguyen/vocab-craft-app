# CraftDialog Redesign & iOS HIG Modernization Design Spec

**Document:** `docs/superpowers/specs/2026-08-26-craftdialog-redesign-design.md`  
**Date:** 2026-08-26  
**Status:** In Review  
**Target:** `CraftUIKit` (iOS 17.0+, macOS 14.0+)  

---

## 1. Executive Overview & Problem Statement

`CraftDialog` is the core modal component in `CraftUIKit` used for alerts, confirmations, and destructive decisions. An in-depth UI/UX design audit revealed critical areas requiring enhancement:

1. **Backdrop Tap Vulnerability:** Tapping the dimmed backdrop unconditionally dismissed the modal without invoking `cancelAction` callback, posing data loss risks on destructive actions (`.danger`).
2. **Rigid Vertical Button Hierarchy:** Buttons were hardcoded to a vertical stack (`VStack`), creating unnecessarily tall dialogs for simple two-button confirmations ("Huỷ" / "Đồng ý").
3. **Typography Scale & Visual Anchor:** The dialog title was styled with `.headline` (16–17pt), lacking the visual dominance appropriate for a 340pt modal surface.
4. **Limited Semantic Badge Coloring:** Icon badge tint only differentiated `.danger` from `brandPrimary`, lacking dedicated semantics for `.warning`, `.info`, or custom brand accents.
5. **Missing Motion & Tactile Feedback:** Absence of native `.sensoryFeedback` and SF Symbol entry micro-animations (`.symbolEffect`).
6. **Accessibility & Dynamic Type Safeguards:** Missing `isModal` accessibility traits and scrollable height containment when containing long custom content or large accessibility text sizes.

---

## 2. Architecture & Public API Changes

### 2.1. Button Layout Strategy (`CraftDialogButtonLayout`)

A new layout enumeration controls how action buttons are arranged:

```swift
public enum CraftDialogButtonLayout: Sendable, CaseIterable {
    /// Automatically selects layout: attempts horizontal HStack first;
    /// if text wraps or accessibility sizes require space, flows into vertical VStack.
    case automatic
    /// Forces horizontal side-by-side arrangement (Cancel on leading, Primary on trailing).
    case horizontal
    /// Forces vertical stacked arrangement (Primary on top, Cancel on bottom).
    case vertical
}
```

#### Button Arrangement Mechanics:
- **`automatic` Mode:** Uses SwiftUI `ViewThatFits` to evaluate `HStack` first. If horizontal constraints or label lengths cause wrapping, it seamlessly falls back to `VStack`.
- **Styling Synergy:**
  - In `HStack`: Cancel button uses `.outline` variant to match the physical bounding box and height (44pt) of the Primary button.
  - In `VStack`: Cancel button uses `.ghost` variant to maintain clear primary vs. secondary visual hierarchy.

---

### 2.2. Smart Backdrop Tap Safety & Callback Guarantee

```swift
public struct CraftDialogModifier<DialogBody: View>: ViewModifier {
    @Binding public var isPresented: Bool
    public let backdrop: CraftDialogBackdrop
    public let dismissOnBackdropTap: Bool?
    public let onBackdropDismiss: (() -> Void)?
    public let dialogContent: DialogBody
}
```

#### Dismissal Rules:
1. **Resolved Dismissal:**
   ```swift
   var resolvedDismissOnBackdropTap: Bool {
       dismissOnBackdropTap ?? (primaryButtonVariant != .danger)
   }
   ```
   - For `.danger` dialogs: default is `false` (user must deliberately tap an explicit button).
   - For standard dialogs: default is `true` (tap outside dismisses smoothly).
2. **Callback Integrity:**
   - Tapping backdrop to dismiss invokes `cancelAction?()` before setting `isPresented = false`.

---

### 2.3. Enhanced Typography & Surface Layering

1. **Title Typography:** Upgraded to `style: .title3` (with `.fontDesign(.rounded)` and `.bold()`), creating an immediate visual anchor.
2. **Container Boundaries:** Max width set to `340pt` with an adaptive vertical containment (`maxHeight: 480pt`) and `ScrollView` integration for custom content when Dynamic Type is enlarged.
3. **Badge Tinting:** Allows explicit `iconColor: Color?` injection, defaulting to `.statusDanger` for `.danger` variants and `.brandPrimary` otherwise.

---

### 2.4. Sensory Feedback (Haptics) & Motion Physics

1. **Presentation Haptics (iOS 17+):**
   - `.sensoryFeedback(.warning, trigger: isPresented)` activated when `primaryButtonVariant == .danger`.
2. **Button Tap Haptics:**
   - Primary action: `.sensoryFeedback(.impact(weight: .medium), trigger: actionTrigger)`.
   - Cancel action: `.sensoryFeedback(.impact(weight: .light), trigger: actionTrigger)`.
3. **Micro-Motion:**
   - Icon Badge uses `.symbolEffect(.bounce.byLayer, value: isPresented)` (respecting `@Environment(\.accessibilityReduceMotion)`).
   - Card entry animation uses `theme.animations.springSmooth` (`scale(0.92) + opacity`).

---

### 2.5. Accessibility (a11y) Conformance

- Entire dialog container tagged with `.accessibilityElement(children: .contain)`.
- Container tagged with `.accessibilityAddTraits(.isModal)`.
- VoiceOver reading order guaranteed: **Icon Badge $\rightarrow$ Title $\rightarrow$ Message $\rightarrow$ Custom Content $\rightarrow$ Primary Action $\rightarrow$ Cancel Action**.

---

## 3. Detailed Component Specification

```swift
public struct CraftDialog<CustomContent: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Content Identifiers
    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let messageKey: LocalizedStringKey?
    private let rawMessage: String?
    private let primaryButtonTitleKey: LocalizedStringKey?
    private let rawPrimaryButtonTitle: String?
    private let cancelButtonTitleKey: LocalizedStringKey?
    private let rawCancelButtonTitle: String?

    // Appearance & Configuration
    public let iconName: String?
    public let iconColor: Color?
    public let primaryButtonVariant: CraftButtonVariant
    public let primaryAction: () -> Void
    public let cancelButtonVariant: CraftButtonVariant?
    public let cancelAction: (() -> Void)?
    public let style: CraftSurfaceStyle
    public let buttonLayout: CraftDialogButtonLayout
    public let customContent: CustomContent
}
```

---

## 4. Testing & Verification Strategy

1. **Unit Tests (`ContainerOverlayTests.swift`):**
   - Verify `CraftDialogButtonLayout` cases (`.automatic`, `.horizontal`, `.vertical`).
   - Verify `dismissOnBackdropTap` resolution for `.danger` (defaults to `false`) vs. `.primary` (defaults to `true`).
   - Verify `cancelAction` execution on backdrop tap dismissal.
   - Verify custom `iconColor` override behavior.
   - Verify `LocalizedStringKey` initializers and convenience initializers.
2. **Test Suite Verification:**
   - Run `swift test` across all targets to guarantee 0 regressions across existing 417 tests.
3. **Interactive Catalog Verification:**
   - Update `CraftCatalogView.swift` dialog previews showcasing `.automatic` layout, `.danger` guardrails, and Liquid Glass dialog styling.

---

## 5. Implementation Boundaries

| File | Action | Scope |
| :--- | :--- | :--- |
| `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift` | Modify | Implement `CraftDialogButtonLayout`, smart backdrop dismiss, `ViewThatFits`, haptics, title typography, and a11y traits. |
| `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift` | Modify | Add comprehensive unit tests covering button layout, smart backdrop tap, and callbacks. |
| `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift` | Modify | Update preview demo cases in the Design System catalog. |
