# CraftUIKit Design System Evolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform CraftUIKit into a zero-hardcoded, fully localized, multi-style (Flat, Elevated, Outlined, Tactile 3D, Liquid Glass), domain-decoupled SwiftUI Design System.

**Architecture:** Implement unified surface styles via `CraftSurfaceStyle` & `CraftSurfaceModifier`, integrate package-level String Catalogs (`Localizable.xcstrings`) with dual initializers (`LocalizedStringKey` & `String`), remove all inline hex colors, and establish generic journey & activity tracker primitives with 100% backward-compatible typed presets.

**Tech Stack:** Swift 5.10+, SwiftUI (iOS 17+, macOS 14+), Swift Package Manager with Xcode String Catalogs (`.xcstrings`), XCTest.

**Spec:** `docs/superpowers/specs/2026-08-25-craftuikit-design-system-audit-design.md`

## Global Constraints
- Target Platforms: iOS 17.0+, macOS 14.0+
- Pure SwiftUI Native (no UIKit dependencies except conditional OS haptic generators inside `#if os(iOS)`)
- Zero inline hexadecimal color values in components (all via `theme.colors` / `theme.gradients`)
- Zero hardcoded English or Vietnamese text strings in components (all via `LocalizedStringKey` / `CraftLocalized` string catalog)
- 100% backward compatibility for existing vocabulary screen components (`LessonNodeModel`, `CraftLessonNode`, `CraftStreakCard`, `CraftStreakData`, etc.)
- All interactive controls must satisfy Apple HIG minimum 44pt touch targets
- All animatable components must respect `@Environment(\.accessibilityReduceMotion)`

---

### Task 1: Package Configuration & String Catalog Localization Infrastructure

**Files:**
- Modify: `CraftUIKit/Package.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Create: `CraftUIKit/Sources/CraftUIKit/Environment/CraftLocalized.swift`
- Create: `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`

**Interfaces:**
- Consumes: SPM Resource bundle (`Bundle.module`).
- Produces: `CraftLocalized.string(_:comment:)` -> `String`, `CraftLocalized.format(_:_:...)` -> `String`.

- [ ] **Step 1: Write the failing localization test**

Create `CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`:
```swift
import XCTest
@testable import CraftUIKit

final class LocalizationTests: XCTestCase {
    func testCommonActionKeysExist() {
        let confirm = CraftLocalized.string("craft.action.confirm")
        XCTAssertFalse(confirm.isEmpty)
        XCTAssertNotEqual(confirm, "craft.action.confirm")
        
        let cancel = CraftLocalized.string("craft.action.cancel")
        XCTAssertFalse(cancel.isEmpty)
        
        let dismiss = CraftLocalized.string("craft.action.dismiss")
        XCTAssertFalse(dismiss.isEmpty)
    }

    func testFormattedStringLocalization() {
        let formatted = CraftLocalized.format("craft.streak.bestRecord", 14)
        XCTAssertTrue(formatted.contains("14"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LocalizationTests`
Expected: FAIL (types and resources not found).

- [ ] **Step 3: Implement Package.swift resource configuration and Localizable.xcstrings**

Update `CraftUIKit/Package.swift`:
```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CraftUIKit",
    defaultLocalization: "en",
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
            path: "Sources/CraftUIKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CraftUIKitTests",
            dependencies: ["CraftUIKit"],
            path: "Tests/CraftUIKitTests"
        )
    ]
)
```

Create `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:
```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "craft.action.cancel" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Hủy" } }
      }
    },
    "craft.action.close" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Close" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đóng" } }
      }
    },
    "craft.action.confirm" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Confirm" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Xác nhận" } }
      }
    },
    "craft.action.continue" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Continue" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tiếp tục" } }
      }
    },
    "craft.action.dismiss" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Dismiss" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đóng" } }
      }
    },
    "craft.action.retry" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Retry" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Thử lại" } }
      }
    },
    "craft.choice.correct" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Correct Answer" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đáp án đúng" } }
      }
    },
    "craft.choice.selected" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Selected" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đã chọn" } }
      }
    },
    "craft.choice.wrong" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Incorrect Answer" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đáp án chưa đúng" } }
      }
    },
    "craft.journey.completedA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Completed" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đã hoàn thành" } }
      }
    },
    "craft.journey.continueCallout" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "CONTINUE" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "TIẾP TỤC" } }
      }
    },
    "craft.journey.currentA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Current step" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Bước hiện tại" } }
      }
    },
    "craft.journey.lockedA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Locked" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đang khóa" } }
      }
    },
    "craft.search.clearA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Clear search" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Xóa tìm kiếm" } }
      }
    },
    "craft.search.placeholder" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Search..." } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tìm kiếm..." } }
      }
    },
    "craft.stepper.decreaseA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Decrease" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Giảm" } }
      }
    },
    "craft.stepper.increaseA11y" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Increase" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tăng" } }
      }
    },
    "craft.streak.bestRecord" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Best: %lld days" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Kỷ lục: %lld ngày" } }
      }
    },
    "craft.streak.daysUnit" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "days" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "ngày" } }
      }
    },
    "craft.streak.freezeShield" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "%lld/%lld Shields" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "%lld/%lld Khiên" } }
      }
    },
    "craft.streak.tierBlaze" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Blaze Streak" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Chuỗi rực lửa" } }
      }
    },
    "craft.streak.tierLegendary" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Legendary Streak" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Chuỗi huyền thoại" } }
      }
    },
    "craft.streak.tierStarter" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Starter Streak" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Chuỗi khởi đầu" } }
      }
    }
  },
  "version" : "1.0"
}
```

Create `CraftUIKit/Sources/CraftUIKit/Environment/CraftLocalized.swift`:
```swift
import Foundation
import SwiftUI

/// Internal localization helper resolving strings from CraftUIKit's module bundle.
public enum CraftLocalized {
    public static func string(_ key: String, comment: String = "") -> String {
        Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }

    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        let format = Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, locale: Locale.current, arguments: arguments)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Package.swift CraftUIKit/Sources/CraftUIKit/Resources CraftUIKit/Sources/CraftUIKit/Environment/CraftLocalized.swift CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift
git commit -m "feat: add Package String Catalog and CraftLocalized infrastructure"
```

---

### Task 2: Unified Surface Style Tokens & Environment Integration

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftSurfaceStyle.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftGlassTokens.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftDefaultTheme.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Modifiers/CraftSurfaceModifier.swift`
- Create: `CraftUIKit/Tests/CraftUIKitTests/SurfaceStyleTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftDepthTokens`, `CraftShadowTokens`.
- Produces: `CraftSurfaceStyle`, `CraftGlassTokens`, `View.craftSurfaceStyle(_:)`, `CraftSurfaceModifier`.

- [ ] **Step 1: Write failing test for CraftSurfaceStyle & GlassTokens**

Create `CraftUIKit/Tests/CraftUIKitTests/SurfaceStyleTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import CraftUIKit

final class SurfaceStyleTests: XCTestCase {
    func testAllSurfaceStylesExist() {
        XCTAssertEqual(CraftSurfaceStyle.allCases.count, 5)
        XCTAssertTrue(CraftSurfaceStyle.allCases.contains(.flat))
        XCTAssertTrue(CraftSurfaceStyle.allCases.contains(.elevated))
        XCTAssertTrue(CraftSurfaceStyle.allCases.contains(.outlined))
        XCTAssertTrue(CraftSurfaceStyle.allCases.contains(.tactile3D))
        XCTAssertTrue(CraftSurfaceStyle.allCases.contains(.glass))
    }

    func testGlassTokensInTheme() {
        let theme = CraftDefaultTheme()
        XCTAssertNotNil(theme.glass)
        XCTAssertEqual(theme.glass.tintOpacity, 0.12)
    }

    func testSurfaceModifierRenders() {
        let view = Text("Surface Test")
            .modifier(CraftSurfaceModifier(style: .glass, shape: RoundedRectangle(cornerRadius: 12)))
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SurfaceStyleTests`
Expected: FAIL (types not defined).

- [ ] **Step 3: Implement Surface Style tokens and modifier**

Create `CraftUIKit/Sources/CraftUIKit/Tokens/CraftSurfaceStyle.swift`:
```swift
import SwiftUI

/// Unified surface styling modes for all CraftUIKit containers and controls.
public enum CraftSurfaceStyle: String, Sendable, CaseIterable {
    case flat
    case elevated
    case outlined
    case tactile3D
    case glass
}

public struct CraftSurfaceStyleKey: EnvironmentKey {
    public static let defaultValue: CraftSurfaceStyle = .flat
}

public extension EnvironmentValues {
    var craftSurfaceStyle: CraftSurfaceStyle {
        get { self[CraftSurfaceStyleKey.self] }
        set { self[CraftSurfaceStyleKey.self] = newValue }
    }
}

public extension View {
    /// Applies a surface style to this view and its descendants.
    func craftSurfaceStyle(_ style: CraftSurfaceStyle) -> some View {
        environment(\.craftSurfaceStyle, style)
    }
}
```

Create `CraftUIKit/Sources/CraftUIKit/Tokens/CraftGlassTokens.swift`:
```swift
import SwiftUI

/// Material blur, tint opacities, and specular highlight tokens for Liquid Glass surfaces.
public protocol CraftGlassTokens: Sendable {
    var tintOpacity: Double { get }
    var borderGradient: LinearGradient { get }
}

public extension CraftGlassTokens {
    var tintOpacity: Double { 0.12 }
    var borderGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .craftDynamic(light: Color.white.opacity(0.8), dark: Color.white.opacity(0.24)), location: 0.0),
                .init(color: .craftDynamic(light: Color.white.opacity(0.3), dark: Color.white.opacity(0.08)), location: 0.5),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct CraftDefaultGlassTokens: CraftGlassTokens {
    public var tintOpacity: Double
    public var borderGradient: LinearGradient

    public init(
        tintOpacity: Double = 0.12,
        borderGradient: LinearGradient = LinearGradient(
            stops: [
                .init(color: .craftDynamic(light: Color.white.opacity(0.8), dark: Color.white.opacity(0.24)), location: 0.0),
                .init(color: .craftDynamic(light: Color.white.opacity(0.3), dark: Color.white.opacity(0.08)), location: 0.5),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ) {
        self.tintOpacity = tintOpacity
        self.borderGradient = borderGradient
    }
}
```

Update `CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`:
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
    var opacities: CraftOpacityTokens { get }
    var depths: CraftDepthTokens { get }
    var glass: CraftGlassTokens { get }
}

public extension CraftTheme {
    var depths: CraftDepthTokens {
        CraftDefaultDepthTokens()
    }
    var glass: CraftGlassTokens {
        CraftDefaultGlassTokens()
    }
}
```

Create `CraftUIKit/Sources/CraftUIKit/Modifiers/CraftSurfaceModifier.swift`:
```swift
import SwiftUI

/// Standardized surface background, border, shadow, and 3D extrusion modifier.
public struct CraftSurfaceModifier<S: Shape>: ViewModifier {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let style: CraftSurfaceStyle
    public let shape: S
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let isPressed: Bool
    public let depth: CGFloat

    public init(
        style: CraftSurfaceStyle = .flat,
        shape: S,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        isPressed: Bool = false,
        depth: CGFloat? = nil
    ) {
        self.style = style
        self.shape = shape
        self.customTint = customTint
        self.customGradient = customGradient
        self.isPressed = isPressed
        self.depth = depth ?? 4
    }

    public func body(content: Content) -> some View {
        let depressOffset = (style == .tactile3D && isPressed) ? depth : 0

        ZStack {
            if style == .tactile3D {
                shape
                    .fill(customTint ?? theme.colors.borderDefault)
                    .offset(y: depth)
            }

            content
                .background(backgroundSurface)
                .clipShape(shape)
                .overlay(borderOverlay)
                .modifier(ShadowModifier(style: style, theme: theme))
                .offset(y: depressOffset)
        }
        .padding(.bottom, style == .tactile3D ? depth : 0)
    }

    @ViewBuilder
    private var backgroundSurface: some View {
        if let customGradient {
            customGradient
        } else if let customTint {
            customTint
        } else {
            switch style {
            case .flat:
                theme.colors.surfaceSubtle
            case .elevated:
                theme.colors.surfaceElevated
            case .outlined:
                theme.colors.surfaceCard
            case .tactile3D:
                theme.colors.surfaceCard
            case .glass:
                .ultraThinMaterial
            }
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .flat:
            EmptyView()
        case .outlined:
            shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        case .elevated:
            shape.strokeBorder(
                LinearGradient(
                    stops: [
                        .init(color: .craftDynamic(light: Color.white.opacity(0.8), dark: Color.white.opacity(0.2)), location: 0.0),
                        .init(color: theme.colors.hairline, location: 0.5),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        case .tactile3D:
            ZStack {
                shape.strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                shape.strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            }
        case .glass:
            shape.strokeBorder(theme.glass.borderGradient, lineWidth: 1)
        }
    }
}

private struct ShadowModifier: ViewModifier {
    let style: CraftSurfaceStyle
    let theme: CraftTheme

    func body(content: Content) -> some View {
        if style == .elevated {
            content.craftShadow(theme.shadows.md)
        } else if style == .glass {
            content.craftShadow(theme.shadows.sm)
        } else {
            content
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SurfaceStyleTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Tokens/CraftSurfaceStyle.swift CraftUIKit/Sources/CraftUIKit/Tokens/CraftGlassTokens.swift CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift CraftUIKit/Sources/CraftUIKit/Modifiers/CraftSurfaceModifier.swift CraftUIKit/Tests/CraftUIKitTests/SurfaceStyleTests.swift
git commit -m "feat: add CraftSurfaceStyle, CraftGlassTokens, and CraftSurfaceModifier"
```

---

### Task 3: Upgrading Atoms (CraftText, CraftBadge, CraftIconButton, CraftDivider, CraftSpinner)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftText.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftDivider.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftSpinner.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle`, `CraftTheme`, `CraftLocalized`.
- Produces: Enhanced `CraftText` with markdown `AttributedString`, `CraftBadge` with 5 surface styles & shapes, `CraftIconButton` with surface styles, `CraftDivider` with dashed/gradient styles.

- [ ] **Step 1: Write failing test in AtomComponentTests**

Add to `CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift`:
```swift
func testCraftTextAttributedString() {
    let attrString = try? AttributedString(markdown: "Hello **World**")
    XCTAssertNotNil(attrString)
    let text = CraftText(attrString ?? AttributedString("Hello World"))
    XCTAssertNotNil(text)
}

func testCraftBadgeSurfaceStyles() {
    let badge = CraftBadge("VIP", variant: .solid, style: .glass, size: .md)
    XCTAssertNotNil(badge)
}

func testCraftIconButtonSurfaceStyles() {
    let btn = CraftIconButton(iconName: "star.fill", style: .tactile3D, accessibilityLabel: "Star", action: {})
    XCTAssertNotNil(btn)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AtomComponentTests`
Expected: FAIL.

- [ ] **Step 3: Implement Atom upgrades**

Update `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftText.swift` to support `AttributedString` and typography parameters (`tracking`, `lineSpacing`).
Update `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift` to accept `style: CraftSurfaceStyle = .flat`, `shape: CraftBadgeShape = .capsule`, `customTint: Color? = nil`.
Update `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift` to accept `style: CraftSurfaceStyle = .flat`, `shape: CraftIconButtonShape = .circle`, `customTint: Color? = nil`.
Update `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftDivider.swift` to support `CraftDividerStyle` (`solid`, `dashed`, `gradient`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AtomComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift
git commit -m "feat: upgrade atoms with surface styles, markdown, and custom shapes"
```

---

### Task 4: Upgrading Controls (CraftButton, CraftChoiceCard, CraftTextField, CraftToggle, CraftSearchBar, CraftPill, CraftStepper)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftTextField.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftToggle.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftPill.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftStepper.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle`, `CraftSurfaceModifier`, `CraftLocalized`.
- Produces: Multi-style controls with zero hardcoding.

- [ ] **Step 1: Write failing tests in ControlComponentTests**

Add to `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`:
```swift
func testCraftButtonSurfaceStyles() {
    let glassBtn = CraftButton("Glass Action", style: .glass, action: {})
    XCTAssertNotNil(glassBtn)
}

func testCraftChoiceCardSurfaceStyles() {
    let choice = CraftChoiceCard(prefix: "A", title: "Choice 1", style: .glass, state: .selected, action: {})
    XCTAssertNotNil(choice)
}

func testCraftStepperZeroHardcodingVoiceOver() {
    let stepper = CraftStepper(value: .constant(5))
    XCTAssertNotNil(stepper)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ControlComponentTests`
Expected: FAIL.

- [ ] **Step 3: Implement Control upgrades**

- `CraftButton`: Add `style: CraftSurfaceStyle? = nil`, custom tint / gradient support, localized loading announcement.
- `CraftChoiceCard`: Replace hardcoded hex colors with `theme.colors`, add `style: CraftSurfaceStyle = .tactile3D`, utilize `CraftLocalized.string("craft.choice.selected")`, etc.
- `CraftTextField`: Add styles (`standard`, `recessed`, `underlined`, `glass`), forwarded modifiers.
- `CraftToggle`: Add custom `activeTint: Color?`, `inactiveTint: Color?`, and styles.
- `CraftSearchBar`: Replace hardcoded `"Cancel"` and `"Clear search"` with `CraftLocalized.string("craft.action.cancel")` and `CraftLocalized.string("craft.search.clearA11y")`.
- `CraftPill`: Support 5 `CraftSurfaceStyle` variants.
- `CraftStepper`: Use `CraftLocalized.string("craft.stepper.increaseA11y")` and `"craft.stepper.decreaseA11y"`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ControlComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
git commit -m "feat: upgrade controls with surface styles and zero hardcoding"
```

---

### Task 5: Upgrading Containers, Overlays & Navigation (CraftCard, CraftDialog, CraftBottomSheet, CraftToast, CraftFloatingTabBar, CraftFlipCard)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftBottomSheet.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftToast.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftFlipCard.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle`, `CraftLocalized`, `CraftTheme`.
- Produces: Generic multi-style overlays and navigation bar.

- [ ] **Step 1: Write failing tests for Overlays & Navigation**

Add to `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`:
```swift
func testCraftCardGlassStyle() {
    let card = CraftCard(style: .glass) { Text("Glass Card") }
    XCTAssertNotNil(card)
}

func testCraftDialogLocalizationKeyDefaults() {
    let dialog = CraftDialog(
        titleKey: "dialog.title",
        primaryAction: {}
    )
    XCTAssertNotNil(dialog)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ContainerOverlayTests`
Expected: FAIL.

- [ ] **Step 3: Implement Container, Overlay & Navigation upgrades**

- `CraftCard`: Merge `CraftCardStyle` with `CraftSurfaceStyle` (add `.glass`), using `CraftSurfaceModifier`.
- `CraftDialog`: Replace string defaults with `CraftLocalized.string("craft.action.confirm")` and `CraftLocalized.string("craft.action.cancel")`, add `LocalizedStringKey` inits and glass background.
- `CraftBottomSheet`: Add `LocalizedStringKey` inits, localized close button.
- `CraftToast`: Add `LocalizedStringKey` inits, `.glass` style.
- `CraftFloatingTabBar`: Add `style: CraftSurfaceStyle = .glass`, support `LocalizedStringKey` center action.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ContainerOverlayTests` and `swift test --filter NavigationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers CraftUIKit/Sources/CraftUIKit/Components/Overlays CraftUIKit/Sources/CraftUIKit/Components/Navigation CraftUIKit/Tests/CraftUIKitTests
git commit -m "feat: upgrade containers, overlays, and navigation with glass style and localization"
```

---

### Task 6: Generic Journey Path & Activity Tracker Primitives with Backward Compatibility

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Models/CraftJourneyModels.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftPathNode.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftJourneySection.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonDetailSheet.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Models/CraftActivityModels.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftCelebrationSheet.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStreakBadge.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftStreakCelebrationSheet.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakModelTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle`, `CraftLocalized`, `CraftTheme`.
- Produces: `CraftPathNode`, `CraftJourneySection`, `CraftActivityTrackerCard`, `CraftCelebrationSheet` and preserves full backward compatibility for `CraftLessonNode`, `CraftStreakCard`.

- [ ] **Step 1: Write failing tests for Generic Journey & Activity Tracker**

Create tests in `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift` and `CraftStreakComponentTests.swift` testing generic models:
```swift
func testGenericPathNodeInitialization() {
    let model = CraftPathNodeModel<String>(
        id: "step_1",
        title: "Workout Day 1",
        state: .active,
        shape: .diamond,
        surfaceStyle: .tactile3D
    )
    let node = CraftPathNode(model: model)
    XCTAssertNotNil(node)
}

func testGenericActivityTrackerCard() {
    let data = CraftActivityTrackerData(
        currentValue: 10,
        bestRecord: 20,
        unitKey: "craft.streak.daysUnit"
    )
    let card = CraftActivityTrackerCard(data: data)
    XCTAssertNotNil(card)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftLearningPathTests`
Expected: FAIL.

- [ ] **Step 3: Implement Generic Journey and Activity Models & Views**

- Create `CraftJourneyModels.swift` and `CraftActivityModels.swift`.
- Create `CraftPathNode.swift` with support for 5 shapes (Circle, Hexagon, Diamond, Squircle, Star), 5 surface styles, localized callout bubble.
- Create `CraftJourneySection.swift` & `CraftActivityTrackerCard.swift` & `CraftCelebrationSheet.swift`.
- Refactor `CraftLessonNode`, `CraftLessonSectionView`, `CraftLessonDetailSheet`, `CraftStreakCard`, `CraftStreakBadge`, `CraftStreakCelebrationSheet` to wrap the generic primitives with zero hardcoding and full tokenization.

- [ ] **Step 4: Run all journey and streak tests to verify they pass**

Run: `swift test --filter CraftLearningPathTests` and `swift test --filter CraftStreakComponentTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Models CraftUIKit/Sources/CraftUIKit/Components/Containers CraftUIKit/Sources/CraftUIKit/Components/Feedback CraftUIKit/Tests/CraftUIKitTests
git commit -m "feat: add generic journey path and activity tracker primitives with backward compatibility"
```

---

### Task 7: Showcase Catalog Update & Full Test Suite Verification

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Consumes: All updated CraftUIKit components.
- Produces: Interactive preview showcase demonstrating all 5 surface styles, theme switching, and localization toggle.

- [ ] **Step 1: Update CraftCatalogView with Style & Localization switcher**

Update `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift` to include sections for:
1. Surface Styles Showcase (`.flat`, `.elevated`, `.outlined`, `.tactile3D`, `.glass`).
2. Multi-language showcase (English / Vietnamese string catalog keys).
3. Generic Journey Path with multi-shape nodes.
4. Universal Activity Tracker & Celebration Sheet.

- [ ] **Step 2: Run complete test suite**

Run: `swift test`
Expected: 100% tests pass (over 320+ test cases).

- [ ] **Step 3: Commit and clean up**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift
git commit -m "feat: update CraftCatalogView showcase and verify full test suite"
```
