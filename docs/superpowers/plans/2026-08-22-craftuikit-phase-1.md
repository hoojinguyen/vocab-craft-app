# CraftUIKit Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and integrate `CraftUIKit` (Phase 1) — a standalone, domain-agnostic, token-driven SwiftUI Design System library with full theme swappability, core primitives, interactive catalog preview, and app root integration.

**Architecture:** A standalone Local Swift Package (`CraftUIKit`) with a 3-tier design token protocol architecture (`CraftTheme`), SwiftUI `@Environment(\.craftTheme)` injection, accessibility/Dynamic Type support, and standardized atomic components. `VocabCraftApp` links `CraftUIKit` via local dependency and defines `VocabTheme` matching existing brand colors.

**Tech Stack:** Swift 5.10+, iOS 17+, macOS 14+, SwiftUI, Swift Package Manager, XCTest / Swift Testing.

**Spec:** [docs/superpowers/specs/2026-08-22-craftuikit-design-system-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-22-craftuikit-design-system-design.md)

## Global Constraints

- **Zero Domain Coupling:** No references to vocabulary, decks, flashcards, or app business logic inside `CraftUIKit`.
- **Pure SwiftUI & Standard Library:** Zero external third-party dependencies in `CraftUIKit`.
- **Theme Swappability:** All components MUST read colors, typography, radii, shadows, and animations from `@Environment(\.craftTheme)`.
- **Platform Support:** iOS 17.0+, macOS 14.0+.
- **Touch Target:** All interactive controls must satisfy Apple HIG 44pt minimum touch target.
- **Dynamic Type & Dark Mode:** All typography and color tokens must dynamically support Light/Dark mode and Apple Dynamic Type.

---

### Task 1: Package Scaffolding & Theme Engine (Tokens & Protocols)

**Files:**
- Create: `CraftUIKit/Package.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftColorTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTypographyTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftSpacingTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftRadiusTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftShadowTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftGradientTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftAnimationTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftDefaultTheme.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Environment/CraftThemeEnvironment.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Produces: `CraftTheme`, `CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`, `CraftGradientTokens`, `CraftAnimationTokens`, `CraftDefaultTheme`, `.craftTheme(_ theme: any CraftTheme)`, `@Environment(\.craftTheme)`.

- [ ] **Step 1: Create `CraftUIKit/Package.swift` and directory structure**

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CraftUIKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CraftUIKit",
            targets: ["CraftUIKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CraftUIKit",
            dependencies: [],
            path: "Sources/CraftUIKit"
        ),
        .testTarget(
            name: "CraftUIKitTests",
            dependencies: ["CraftUIKit"],
            path: "Tests/CraftUIKitTests"
        )
    ]
)
```

- [ ] **Step 2: Write failing unit test for Theme Engine**

Create `CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class ThemeTests: XCTestCase {
    func testDefaultThemeTokens() {
        let theme = CraftDefaultTheme()
        XCTAssertEqual(theme.spacing.base, 16)
        XCTAssertEqual(theme.radii.md, 12)
        XCTAssertNotNil(theme.colors.brandPrimary)
        XCTAssertNotNil(theme.colors.canvasBackground)
    }

    func testCustomThemeOverrides() {
        struct CustomColors: CraftColorTokens {
            var canvasBackground: Color = .black
            var surfaceCard: Color = .gray
            var surfaceElevated: Color = .gray
            var surfaceSubtle: Color = .gray
            var brandPrimary: Color = .purple
            var brandSecondary: Color = .pink
            var accent: Color = .yellow
            var textPrimary: Color = .white
            var textSecondary: Color = .gray
            var textMuted: Color = .gray
            var textInverse: Color = .black
            var borderDefault: Color = .gray
            var borderFocus: Color = .purple
            var hairline: Color = .gray
            var statusSuccess: Color = .green
            var statusWarning: Color = .orange
            var statusDanger: Color = .red
            var statusInfo: Color = .blue
        }

        struct CustomTheme: CraftTheme {
            var colors: CraftColorTokens = CustomColors()
            var typography: CraftTypographyTokens = CraftDefaultTypographyTokens()
            var spacing: CraftSpacingTokens = CraftDefaultSpacingTokens()
            var radii: CraftRadiusTokens = CraftDefaultRadiusTokens()
            var shadows: CraftShadowTokens = CraftDefaultShadowTokens()
            var gradients: CraftGradientTokens = CraftDefaultGradientTokens()
            var animations: CraftAnimationTokens = CraftDefaultAnimationTokens()
        }

        let customTheme = CustomTheme()
        XCTAssertEqual(customTheme.colors.brandPrimary, Color.purple)
    }
}
```

- [ ] **Step 3: Run test to verify it fails (missing types)**

Run: `swift test --package-path CraftUIKit --filter ThemeTests`
Expected: FAIL with compilation errors.

- [ ] **Step 4: Implement Token Protocols, Defaults, and Environment**

Create `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`:
```swift
import SwiftUI

public protocol CraftTheme: Sendable {
    var colors: CraftColorTokens { get }
    var typography: CraftTypographyTokens { get }
    var spacing: CraftSpacingTokens { get }
    var radii: CraftRadiusTokens { get }
    var shadows: CraftShadowTokens { get }
    var gradients: CraftGradientTokens { get }
    var animations: CraftAnimationTokens { get }
}
```

Create token protocols: `CraftColorTokens.swift`, `CraftTypographyTokens.swift`, `CraftSpacingTokens.swift`, `CraftRadiusTokens.swift`, `CraftShadowTokens.swift`, `CraftGradientTokens.swift`, `CraftAnimationTokens.swift`, `CraftDefaultTheme.swift`, and `CraftThemeEnvironment.swift`.

- [ ] **Step 5: Run tests and verify they pass**

Run: `swift test --package-path CraftUIKit --filter ThemeTests`
Expected: PASS with 0 failures.

- [ ] **Step 6: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): scaffold package and theme token engine"
```

---

### Task 2: Modifiers & Atoms (Typography, Press Effect, Badges, Icons, Spinners, Dividers)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Modifiers/PressEffectModifier.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Modifiers/ShimmerModifier.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Modifiers/TypographyModifier.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftText.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIcon.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftDivider.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftSpinner.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `@Environment(\.craftTheme)` from Task 1.
- Produces: `CraftText`, `CraftBadge`, `CraftIcon`, `CraftIconButton`, `CraftDivider`, `CraftSpinner`, `.craftPressEffect()`, `.craftShimmer()`, `.craftTypography()`.

- [ ] **Step 1: Write failing unit test for Atoms & Modifiers**

Create `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class AtomComponentTests: XCTestCase {
    func testBadgeInit() {
        let badge = CraftBadge("PRO", variant: .solid, tone: .primary, size: .sm)
        XCTAssertEqual(badge.title, "PRO")
        XCTAssertEqual(badge.variant, .solid)
    }

    func testIconSizeTokens() {
        XCTAssertEqual(CraftIconSize.sm.pointSize, 14)
        XCTAssertEqual(CraftIconSize.md.pointSize, 18)
        XCTAssertEqual(CraftIconSize.lg.pointSize, 24)
        XCTAssertEqual(CraftIconSize.xl.pointSize, 32)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests`
Expected: FAIL with "cannot find type CraftBadge".

- [ ] **Step 3: Implement Atoms and Modifiers**

Implement:
- `PressEffectModifier.swift`: Spring scale 0.97 + optional haptic on press.
- `ShimmerModifier.swift`: Linear gradient sweep animation for loading states.
- `TypographyModifier.swift` & `CraftText.swift`: Dynamic type typography rendering.
- `CraftBadge.swift`: Variants (`.solid`, `.subtle`, `.outline`), tones (`.primary`, `.success`, `.warning`, `.danger`, `.neutral`), sizes (`.sm`, `.md`).
- `CraftIcon.swift` & `CraftIconButton.swift`: Standardized SF Symbol view and tactile circle/square button with 44pt tap target.
- `CraftDivider.swift` & `CraftSpinner.swift`: Hairline separator and smooth spinning animation.

- [ ] **Step 4: Run test and verify it passes**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): implement atom components and visual modifiers"
```

---

### Task 3: Controls & Inputs (Button, TextField, SearchBar, Toggle, Stepper, Pill)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftTextField.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftToggle.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftStepper.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftPill.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftSpinner`, `CraftIcon`, `.craftPressEffect()` from Tasks 1-2.
- Produces: `CraftButton`, `CraftTextField`, `CraftSearchBar`, `CraftToggle`, `CraftStepper`, `CraftPill`, `.buttonStyle(.craftPrimary())`, `.buttonStyle(.craftSecondary())`, `.buttonStyle(.craftOutline())`, `.buttonStyle(.craftGhost())`, `.buttonStyle(.craftDanger())`.

- [ ] **Step 1: Write failing unit test for Controls**

Create `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class ControlComponentTests: XCTestCase {
    func testButtonVariantsAndSizes() {
        let button = CraftButton("Submit", variant: .primary, size: .lg, isLoading: false) {}
        XCTAssertEqual(button.title, "Submit")
        XCTAssertEqual(button.variant, .primary)
        XCTAssertEqual(button.size, .lg)
        XCTAssertEqual(button.size.height, 54)
    }

    func testStepperBounds() {
        var value = 10
        let stepper = CraftStepper(value: Binding(get: { value }, set: { value = $0 }), range: 5...50, step: 5, unit: "words")
        XCTAssertEqual(stepper.range, 5...50)
        XCTAssertEqual(stepper.step, 5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter ControlComponentTests`
Expected: FAIL.

- [ ] **Step 3: Implement Control Components**

Implement:
- `CraftButton.swift`: Composable view + native `ButtonStyle` conformances, `isLoading` spinner state, disabled opacity, spring tap animation.
- `CraftTextField.swift`: Focus state animation, error helper message, leading icon slot, trailing clear action slot.
- `CraftSearchBar.swift`: Pill shape, clear button, focus highlight stroke.
- `CraftToggle.swift`: Theme-tinted accessible toggle.
- `CraftStepper.swift`: `[-] [Value + Unit] [+]` with minimum/maximum bound checks.
- `CraftPill.swift`: Tap-to-select filter chip with active/inactive fill and stroke.

- [ ] **Step 4: Run tests and verify they pass**

Run: `swift test --package-path CraftUIKit --filter ControlComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): implement controls, buttons, textfields, and steppers"
```

---

### Task 4: Containers, Feedback & Overlays (Cards, Progress, ListRow, EmptyState, Toasts, Sheets, Dialogs)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftCard.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftProgressBar.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftProgressRing.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftListRow.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftEmptyState.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftToast.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftBottomSheet.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftButton`, `CraftIcon`, `CraftText` from Tasks 1-3.
- Produces: `CraftCard`, `CraftProgressBar`, `CraftProgressRing`, `CraftListRow`, `CraftEmptyState`, `CraftToast`, `CraftBottomSheet`, `CraftDialog`, `.craftToast(...)`, `.craftDialog(...)`.

- [ ] **Step 1: Write failing unit test for Containers & Overlays**

Create `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class ContainerOverlayTests: XCTestCase {
    func testCardStyles() {
        let card = CraftCard(style: .elevated, isPressable: true) { Text("Content") }
        XCTAssertEqual(card.style, .elevated)
        XCTAssertTrue(card.isPressable)
    }

    func testProgressBarClamping() {
        let bar = CraftProgressBar(progress: 1.5)
        XCTAssertEqual(bar.clampedProgress, 1.0)
        let negativeBar = CraftProgressBar(progress: -0.2)
        XCTAssertEqual(negativeBar.clampedProgress, 0.0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter ContainerOverlayTests`
Expected: FAIL.

- [ ] **Step 3: Implement Containers and Overlay Components**

Implement:
- `CraftCard.swift`: `.flat`, `.elevated`, `.outlined`, `.gradient`, pressable spring effect.
- `CraftProgressBar.swift` & `CraftProgressRing.swift`: Animated progress surfaces with ratio clamping.
- `CraftListRow.swift`: Leading icon container, Title, Subtitle, Trailing control slot.
- `CraftEmptyState.swift`: Illustration/Icon, title, message, primary action button.
- `CraftToast.swift`: Top/Bottom HUD toast with spring presentation and auto-timer dismiss.
- `CraftBottomSheet.swift` & `CraftDialog.swift`: Modal sheets and confirmation alerts.

- [ ] **Step 4: Run tests and verify they pass**

Run: `swift test --package-path CraftUIKit --filter ContainerOverlayTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): implement containers, progress indicators, and overlay components"
```

---

### Task 5: Interactive Catalog Gallery (`CraftCatalogView`)

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`

**Interfaces:**
- Consumes: All `CraftUIKit` components and themes from Tasks 1-4.
- Produces: `CraftCatalogView` (Interactive showcase view with live theme switching).

- [ ] **Step 1: Implement `CraftCatalogView` showcasing all components**

Create sections in `CraftCatalogView`:
- Header with Theme Switcher Picker (`Default Slate Theme` vs `Custom Brand Theme` vs `Dark/Light Mode`).
- Section 1: Typography & Icons.
- Section 2: Badges & Tags.
- Section 3: Buttons (All variants, sizes, loading states).
- Section 4: TextFields & SearchBar (Normal, Focused, Error).
- Section 5: Stepper & Toggles.
- Section 6: Cards & Bento Grid.
- Section 7: Progress Bars & Rings.
- Section 8: Toasts, Sheets & Dialog triggers.

- [ ] **Step 2: Run test suite across whole `CraftUIKit` package**

Run: `swift test --package-path CraftUIKit`
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit
git commit -m "feat(CraftUIKit): add interactive CraftCatalogView gallery preview"
```

---

### Task 6: App Integration (Linking CraftUIKit & Defining VocabTheme)

**Files:**
- Modify: `Package.swift` (Root)
- Create: `VocabCraftApp/Core/DesignSystem/VocabTheme.swift`
- Modify: `VocabCraftApp/App/VocabCraftApp.swift`
- Test: Root unit tests via `swift test`

**Interfaces:**
- Consumes: `CraftUIKit` module.
- Produces: `VocabTheme: CraftTheme`, root `.craftTheme(VocabTheme())` application.

- [ ] **Step 1: Update root `Package.swift` to declare local dependency**

Modify `Package.swift`:
```swift
dependencies: [
    .package(path: "CraftUIKit")
],
targets: [
    .target(
        name: "VocabCraftApp",
        dependencies: [
            .product(name: "CraftUIKit", package: "CraftUIKit")
        ],
        path: "VocabCraftApp",
        ...
```

- [ ] **Step 2: Create `VocabTheme.swift` conforming to `CraftTheme`**

Map existing brand colors (`vocabHeroTeal`, `vocabHeroAccent`, `vocabCoral`, `vocabMint`, `vocabPeach`, `vocabLavender`) to `CraftColorTokens` inside `VocabCraftApp/Core/DesignSystem/VocabTheme.swift`.

- [ ] **Step 3: Inject `.craftTheme(VocabTheme())` into `VocabCraftApp.swift`**

Modify `VocabCraftApp/App/VocabCraftApp.swift`:
```swift
import CraftUIKit

@main
struct VocabCraftApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .craftTheme(VocabTheme())
        }
    }
}
```

- [ ] **Step 4: Run root tests to verify everything builds and passes**

Run: `swift test`
Expected: Root package and target dependencies build cleanly and all unit tests pass.

- [ ] **Step 5: Commit**

```bash
git add Package.swift VocabCraftApp
git commit -m "feat: link CraftUIKit dependency and inject VocabTheme at app root"
```

---

### Task 7: Migration Pilot - Refactoring Settings Screen with CraftUIKit

**Files:**
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Test: Verify Settings screen builds and unit tests pass.

- [ ] **Step 1: Replace ad-hoc rows, steppers, and toggles in `SettingsView.swift`**

Use `CraftListRow`, `CraftStepper`, `CraftToggle`, and `CraftText` to replace manual layout and hardcoded padding.

- [ ] **Step 2: Verify build and run tests**

Run: `swift test`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Settings/Views/SettingsView.swift
git commit -m "refactor(Settings): migrate SettingsView to use CraftUIKit components"
```

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-22-craftuikit-phase-1.md`. Two execution options:

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints.

**Which approach?**
