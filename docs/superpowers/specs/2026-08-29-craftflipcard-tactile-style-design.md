# Design Specification: CraftFlipCard First-Class Style Architecture & Reflex Multi-Choice Polish

**Date:** 2026-08-29  
**Status:** Validated Design (Awaiting User Review Gate)  
**Target Packages & Modules:**
1. `CraftUIKit` -> `CraftFlipCard` (`Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Cards/CraftFlipCard.swift`)
2. `VocabCraftApp` -> `ReflexBlitzMultipleChoiceCardView` (`VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzMultipleChoiceCardView.swift`)
3. `VocabCraftApp` -> `ReflexBlitzView` (`VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`)

---

## 1. Overview & Problem Statement

In the previous iteration, attempting to apply a 3D tactile appearance by writing custom, ad-hoc `ZStack` offsets and border overlays directly inside the app-layer view (`ReflexBlitzMultipleChoiceCardView.swift`) led to an anomalous visual defect where a large beige/brown background container leaked outside the rounded card bounds.

### Root Cause Analysis
1. **Lack of Style System in `CraftFlipCard`**: `CraftFlipCard` in `CraftUIKit` was designed solely as a low-level 3D transition modifier without surface container abstractions (`style: CraftCardStyle`).
2. **Ad-hoc App Styling Anti-Pattern**: Forcing the caller in `VocabCraftApp` to construct manual tactile geometry (background offsets, strokes, top highlights) inside the `front` and `back` closures created mismatched bounding boxes between the 3D rotation transform and the underlying base extrusion.
3. **Inconsistent Component Hierarchy**: While `CraftCard` and `CraftChoiceCard` encapsulate `.tactile3D`, `.elevated`, `.outlined`, and `.glass` styling natively, `CraftFlipCard` was missing this capability.

### Objectives
1. **Elevate `CraftFlipCard` in `CraftUIKit`**: Equip `CraftFlipCard` with first-class `style: CraftCardStyle` (supporting `.tactile3D`, `.elevated`, `.outlined`, `.flat`, `.glass`), unifying corner radius, internal padding, depth extrusions, top highlights, and surface backgrounds directly within the component.
2. **Clean Declarative App Implementation**: Refactor `ReflexBlitzMultipleChoiceCardView.swift` to pass pure domain content (text, badges, cloze sentences) into `CraftFlipCard`, completely eliminating manual ZStacks and ad-hoc strokes from the application layer.
3. **Layout & Color Balance**:
   - Front prompt face: Only displays Part-of-Speech (`word.cleanPos`) and hint badge; CEFR level (`word.cleanLevel`) is hidden on front and revealed on back.
   - Choice cards: Keep card face clean with semantic color cues focused on the 3D bottom lip and subtle downward glow/shadow.
   - Vertical rhythm: Maintain zero-shift top-anchored layout with stable bottom clearance.
4. **Cleanup**: Remove temporary tracking file `TODO.md` upon completion.

---

## 2. CraftUIKit: `CraftFlipCard` Architecture & Public API

### 2.1 Updated `CraftFlipCard` Initializers

```swift
public struct CraftFlipCard<Front: View, Back: View>: View {
    @Binding public var isFlipped: Bool
    public let style: CraftCardStyle
    public let axis: Axis
    public let edgeThickness: CGFloat
    public let showSpecularGlare: Bool
    public let showsHighlightBorder: Bool
    public let isTapToFlipEnabled: Bool
    public let cornerRadius: CGFloat?
    public let padding: CGFloat?
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let perspective: CGFloat
    public let animation: Animation?
    public let front: Front
    public let back: Back

    public init(
        isFlipped: Binding<Bool>,
        style: CraftCardStyle = .tactile3D,
        axis: Axis = .horizontal,
        edgeThickness: CGFloat = 0,
        showSpecularGlare: Bool = true,
        showsHighlightBorder: Bool = false,
        isTapToFlipEnabled: Bool = true,
        cornerRadius: CGFloat? = nil,
        padding: CGFloat? = nil,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        perspective: CGFloat = 0.5,
        animation: Animation? = nil,
        @ViewBuilder front: () -> Front,
        @ViewBuilder back: () -> Back
    ) {
        self._isFlipped = isFlipped
        self.style = style
        self.axis = axis
        self.edgeThickness = edgeThickness
        self.showSpecularGlare = showSpecularGlare
        self.showsHighlightBorder = showsHighlightBorder
        self.isTapToFlipEnabled = isTapToFlipEnabled
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.customTint = customTint
        self.customGradient = customGradient
        self.perspective = perspective
        self.animation = animation
        self.front = front()
        self.back = back()
    }
}
```

### 2.2 Native Card Face Surface Rendering

Inside `CraftFlipCard`, a dedicated private `@ViewBuilder` helper `cardFaceContainer(for:radius:contentPadding:depth:)` will wrap each face (`front` and `back`):

```swift
@ViewBuilder
private func cardFaceContainer<V: View>(
    _ content: V,
    radius: CGFloat,
    contentPadding: CGFloat,
    depth: CGFloat
) -> some View {
    let topFace = content
        .padding(contentPadding)
        .frame(maxWidth: .infinity)
        .background(surfaceBackground(radius: radius))
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(surfaceBorderOverlay(radius: radius))
        .modifier(ShadowModifier(style: style, theme: theme))

    if style == .tactile3D {
        ZStack {
            // Native extruded 3D base lip perfectly aligned to face geometry
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(theme.colors.borderDefault)
                .offset(y: depth)

            // Top interactive/rendered card face
            topFace
        }
        .padding(.bottom, depth)
    } else {
        topFace
    }
}
```

This guarantees:
1. Both `front` and `back` faces share identical corner radii, padding, borders, and tactile 3D lip extrusion geometry.
2. The 3D flip animation rotates the complete composite face (card surface + 3D bottom extrusion) with zero edge distortion and zero external container leakage.

---

## 3. App Layer Refactoring: `ReflexBlitzMultipleChoiceCardView`

### 3.1 Pure Declarative View Tree

With `CraftFlipCard` handling surface geometry, `ReflexBlitzMultipleChoiceCardView.swift` becomes 100% clean and declarative:

```swift
@ViewBuilder
private var flipStimulusCard: some View {
    CraftFlipCard(
        isFlipped: Binding(
            get: { isReviewed },
            set: { _ in }
        ),
        style: .tactile3D,
        axis: .horizontal,
        showSpecularGlare: true,
        isTapToFlipEnabled: false,
        cornerRadius: theme.radii.xl,
        padding: theme.spacing.base,
        perspective: 0.5,
        animation: .spring(response: 0.45, dampingFraction: 0.78)
    ) {
        frontPromptContent
    } back: {
        backResultContent
    }
}
```

### 3.2 Content Decomposition
- **`frontPromptContent`**:
  - Definition in Vietnamese (`style: .titleLarge`, center aligned).
  - Badges row: `word.cleanPos` (Subtle Neutral capsule) + `hintBadge` (if active). **CEFR badge is omitted on front**.
  - Cloze sentence area.
  - Sits within a vertical container with `minHeight: 195` to ensure 1:1 dimension parity with the back face.
- **`backResultContent`**:
  - Row 1: Lemma (Serif) + Audio Replay Speaker Button.
  - Row 2: IPA phonetic text.
  - Row 3: Badges row: `word.cleanPos` + `word.cleanLevel` (CEFR Level revealed).
  - Row 4: Vietnamese definition.
  - Row 5: English example sentence + Vietnamese translation.
  - Sits within a vertical container with `minHeight: 195`.

---

## 4. Choice Card & Layout Stability Alignment

1. **`CraftChoiceCard` Tactile Polish**:
   - Top face background: Clean `theme.colors.surfaceCard`.
   - Correct/Wrong selection feedback: 3D bottom lip dynamically tints to `statusSuccess` / `statusDanger` with localized downward shadow (`radius: 8, y: 4, opacity: 0.3`).
   - Perimeter stroke: Thin 1.0pt subtle border (`opacity: 0.6`).
2. **`ReflexBlitzView` Vertical Rhythm**:
   - Header is positioned at the top with `theme.spacing.xs`.
   - Card sits directly below Header with fixed spacing (`theme.spacing.xs`).
   - Bottom feedback clearance is stabilized at `140pt` across drilling and reviewed states in Multiple Choice mode, ensuring **0px vertical layout shift**.

---

## 5. Verification & Testing Plan

### 5.1 Automated Package Tests (`Packages/CraftUIKit`)
- `swift test`: Verify all 626+ tests pass, including:
  - `CraftFlipCardTests`: Validate initialization with `style: .tactile3D`, `.elevated`, `.outlined`, `.glass`, custom corner radii, and padding.
  - `CraftChoiceCardTests`: Validate tactile button style, alignments, and state derivations.
  - `LocalizationTests`: Confirm 100% EN/VI string parity.

### 5.2 Automated App Tests (`VocabCraftAppTests`)
- `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17'`:
  - `ReflexBlitzComponentsTests`: Full component assertions.
  - `ReflexBlitzViewIntegrationTests`: End-to-end user flows and zero-shift layout validation.
  - `ReflexBlitzViewModelTests`: State machine transitions.

### 5.3 Code Quality & Linter
- `swiftlint`: 0 warnings, 0 errors across all codebase files.
- Xcode build diagnostics: 0 compiler warnings.

### 5.4 Cleanup
- Delete `TODO.md` from the project repository.
