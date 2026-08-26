# CraftSearchBar UI/UX Evolution, Performance Optimization & Full-Spectrum Styles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate `CraftSearchBar` into a high-performance, zero-lag, full-spectrum styled, and ergonomically sized search bar in CraftUIKit supporting 7 surface styles, 3 size tiers (`sm`, `md`, `lg`), loading spinner, sensory haptics, and SF Symbol micro-interactions.

**Architecture:** Eliminate nested `.animation()` spring storms to resolve keyboard hitching, intercept taps across the entire pill container with `.contentShape(Rectangle())`, integrate CraftUIKit's 5 core surface styles (`flat`, `elevated`, `outlined`, `tactile3D`, `glass`) + `recessed` and `standard`, ensure 44x44pt touch targets for action buttons, and provide smooth state transitions.

**Tech Stack:** Swift 6, SwiftUI (iOS 17+, macOS 14+), XCTest, CraftUIKit theming engine.

**Spec:** `docs/superpowers/specs/2026-08-26-craftsearchbar-design.md`

## Global Constraints
- Target iOS 17.0+, macOS 14.0+
- Native SwiftUI with zero UIKit workarounds
- Dynamic Type and Dark Mode compliant with zero hardcoded hex colors
- Maintain 100% backward compatibility for existing callers and test cases (`.standard`, `.recessed`, `.glass`)
- Minimum 44x44pt tap target bounds for interactive buttons (Clear, Cancel, Trailing Action) according to Apple HIG

---

### Task 1: Refactor CraftSearchBar Enums, Sizes, Performance & Surface Styles

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Consumes:
  - `CraftTheme`, `CraftSurfaceStyle`, `CraftSurfaceModifier`, `CraftIcon`, `CraftSpinner`, `CraftLocalized`, `CraftSymbol`
- Produces:
  - `public enum CraftSearchBarStyle: String, Sendable, CaseIterable { case standard, flat, elevated, outlined, recessed, tactile3D, glass }`
  - `public enum CraftSearchBarSize: String, Sendable, CaseIterable { case sm, md, lg }`
  - `public struct CraftSearchBar: View` supporting `size`, `style`, `shape`, `customTint`, `customGradient`, `isLoading`, `trailingIcon`, `trailingAction`, `onCancel`, `onSubmit` with `String` and `LocalizedStringKey` initializers.

- [ ] **Step 1: Write failing unit tests in ControlComponentTests.swift**

```swift
// Add to CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
func testSearchBarFullSpectrumStyles() {
    XCTAssertEqual(CraftSearchBarStyle.allCases.count, 7)
    XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.standard))
    XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.flat))
    XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.elevated))
    XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.outlined))
    XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.recessed))
    XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.tactile3D))
    XCTAssertTrue(CraftSearchBarStyle.allCases.contains(.glass))

    for style in CraftSearchBarStyle.allCases {
        var query = "test"
        let searchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            placeholder: "Search in \(style.rawValue)...",
            style: style,
            customTint: .teal
        )
        XCTAssertEqual(searchBar.style, style)
        XCTAssertEqual(searchBar.customTint, .teal)
        XCTAssertNotNil(searchBar.body)
    }
}

func testSearchBarSizesAndLoadingState() {
    XCTAssertEqual(CraftSearchBarSize.allCases.count, 3)
    XCTAssertEqual(CraftSearchBarSize.sm.height, 36)
    XCTAssertEqual(CraftSearchBarSize.md.height, 44)
    XCTAssertEqual(CraftSearchBarSize.lg.height, 52)

    for size in CraftSearchBarSize.allCases {
        var query = "size test"
        let searchBar = CraftSearchBar(
            text: Binding(get: { query }, set: { query = $0 }),
            size: size,
            isLoading: true
        )
        XCTAssertEqual(searchBar.size, size)
        XCTAssertTrue(searchBar.isLoading)
        XCTAssertNotNil(searchBar.body)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter testSearchBarFullSpectrumStyles`
Expected: FAIL with compilation error (missing cases in `CraftSearchBarStyle` or `CraftSearchBarSize`).

- [ ] **Step 3: Implement CraftSearchBar.swift refactoring**

```swift
import SwiftUI

// MARK: - SearchBar Enums

/// Visual style variants for CraftSearchBar supporting CraftUIKit's full surface spectrum.
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

/// Sizing tiers for CraftSearchBar.
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

    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 10
        case .md: return 12
        case .lg: return 16
        }
    }
}

/// Border geometry shape for CraftSearchBar.
public enum CraftSearchBarShape: Sendable, Equatable {
    case capsule
    case roundedRectangle(radius: CGFloat)
}

// MARK: - Backing Shape

private struct CraftSearchBarBackingShape: Shape {
    let shape: CraftSearchBarShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .capsule:
            return Capsule().path(in: rect)
        case .roundedRectangle(let radius):
            return RoundedRectangle(cornerRadius: radius).path(in: rect)
        }
    }
}

// MARK: - CraftSearchBar Component

/// A high-performance, tactile, and full-spectrum styled search input bar with focus glow, clear action, sensory haptics, and optional trailing actions.
public struct CraftSearchBar: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @FocusState private var isFocused: Bool
    @State private var clearHapticTrigger: Bool = false
    @State private var cancelHapticTrigger: Bool = false

    public var text: Binding<String>
    private let placeholderKey: LocalizedStringKey?
    private let rawPlaceholder: String?
    public let size: CraftSearchBarSize
    public let style: CraftSearchBarStyle
    public let shape: CraftSearchBarShape
    public let customTint: Color?
    public let customGradient: LinearGradient?
    public let trailingIcon: String?
    public let trailingAction: (() -> Void)?
    public let isLoading: Bool
    public let onCancel: (() -> Void)?
    public let onSubmit: (() -> Void)?

    public var placeholder: String {
        rawPlaceholder ?? CraftLocalized.string("craft.search.placeholder")
    }

    public init(
        text: Binding<String>,
        placeholder: String = CraftLocalized.string("craft.search.placeholder"),
        size: CraftSearchBarSize = .md,
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        isLoading: Bool = false,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = nil
        self.rawPlaceholder = placeholder
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
        self.customGradient = customGradient
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.isLoading = isLoading
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public init(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        size: CraftSearchBarSize = .md,
        style: CraftSearchBarStyle = .standard,
        shape: CraftSearchBarShape = .capsule,
        customTint: Color? = nil,
        customGradient: LinearGradient? = nil,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        isLoading: Bool = false,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.text = text
        self.placeholderKey = placeholder
        self.rawPlaceholder = nil
        self.size = size
        self.style = style
        self.shape = shape
        self.customTint = customTint
        self.customGradient = customGradient
        self.trailingIcon = trailingIcon
        self.trailingAction = trailingAction
        self.isLoading = isLoading
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Search Input Field Container
            HStack(spacing: size == .sm ? theme.spacing.xs : theme.spacing.sm) {
                // Leading Icon or Loading Spinner
                if isLoading {
                    CraftSpinner(size: size.iconSize, color: customTint ?? theme.colors.brandPrimary)
                } else {
                    CraftIcon(
                        .search,
                        size: size.iconSize,
                        color: isFocused ? (customTint ?? theme.colors.borderFocus) : theme.colors.textMuted
                    )
                    .symbolEffect(.bounce, value: isFocused)
                }

                // Text Input
                Group {
                    if let placeholderKey {
                        TextField(placeholderKey, text: text)
                    } else {
                        TextField(placeholder, text: text)
                    }
                }
                .font(textFieldFont)
                .foregroundStyle(theme.colors.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

                // Clear Action Button
                if !text.wrappedValue.isEmpty && !isLoading {
                    Button(action: {
                        text.wrappedValue = ""
                        clearHapticTrigger.toggle()
                    }) {
                        CraftIcon(.wrongCircle, size: .sm, color: theme.colors.textMuted)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 32, minHeight: 32)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .sensoryFeedback(.impact(weight: .light), trigger: clearHapticTrigger)
                    .accessibilityLabel(CraftLocalized.string("craft.search.clear_a11y"))
                }

                // Optional Trailing Action Icon Button
                if let trailingIcon, let trailingAction {
                    Button(action: trailingAction) {
                        CraftIcon(
                            trailingIcon,
                            size: .sm,
                            color: isFocused ? (customTint ?? theme.colors.brandPrimary) : theme.colors.textMuted
                        )
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 32, minHeight: 32)
                    .accessibilityLabel(CraftLocalized.string("craft.search.trailing_action_a11y"))
                }
            }
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background(backgroundView)
            .clipShape(searchShape)
            .overlay(borderOverlay)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isFocused {
                    isFocused = true
                }
            }

            // Cancel Button
            if isFocused && onCancel != nil {
                Button(action: {
                    isFocused = false
                    cancelHapticTrigger.toggle()
                    onCancel?()
                }) {
                    Text(CraftLocalized.string("craft.common.action.cancel"))
                        .font(cancelButtonFont)
                        .foregroundStyle(customTint ?? theme.colors.brandPrimary)
                        .padding(.horizontal, 4)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                .sensoryFeedback(.selection, trigger: cancelHapticTrigger)
            }
        }
        .animation(theme.animations.springSnappy, value: isFocused)
    }

    private var textFieldFont: Font {
        switch size {
        case .sm: return theme.typography.bodySmall
        case .md: return theme.typography.bodyMedium
        case .lg: return theme.typography.bodyLarge
        }
    }

    private var cancelButtonFont: Font {
        switch size {
        case .sm: return theme.typography.label
        case .md: return theme.typography.bodyMedium
        case .lg: return theme.typography.bodyLarge
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let customGradient {
            searchShape.fill(customGradient)
        } else if let customTint {
            switch style {
            case .glass:
                ZStack {
                    searchShape.fill(.ultraThinMaterial)
                    searchShape.fill(customTint.opacity(theme.glass.tintOpacity))
                }
            case .tactile3D, .elevated, .outlined:
                searchShape.fill(theme.colors.surfaceCard)
            case .standard, .flat:
                searchShape.fill(customTint.opacity(0.12))
            case .recessed:
                ZStack {
                    customTint.opacity(0.15)
                    LinearGradient(
                        colors: [Color.black.opacity(0.15), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        } else {
            switch style {
            case .standard, .flat:
                theme.colors.surfaceSubtle
            case .elevated:
                theme.colors.surfaceElevated
            case .outlined:
                theme.colors.surfaceCard
            case .recessed:
                ZStack {
                    theme.colors.surfaceSubtle.opacity(0.6)
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            case .tactile3D:
                theme.colors.surfaceCard
            case .glass:
                ZStack {
                    searchShape.fill(.ultraThinMaterial)
                    searchShape.fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
                }
            }
        }
    }

    private var searchShape: CraftSearchBarBackingShape {
        CraftSearchBarBackingShape(shape: shape)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        let strokeWidth: CGFloat = isFocused ? 1.5 : 1.0

        if isFocused {
            shapeStroke(color: customTint ?? theme.colors.borderFocus, width: strokeWidth)
        } else {
            switch style {
            case .standard, .flat:
                shapeStroke(color: theme.colors.borderDefault, width: strokeWidth)
            case .elevated:
                shapeStroke(
                    gradient: LinearGradient(
                        stops: [
                            .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                            .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    width: strokeWidth
                )
            case .outlined:
                shapeStroke(color: theme.colors.borderDefault, width: strokeWidth)
            case .recessed:
                shapeStroke(color: theme.colors.hairline, width: strokeWidth)
            case .tactile3D:
                shapeStroke(
                    gradient: LinearGradient(
                        stops: [
                            .init(color: .craftDynamic(light: Color.white.opacity(0.75), dark: Color.white.opacity(0.20)), location: 0.0),
                            .init(color: theme.colors.borderDefault.opacity(0.6), location: 0.4),
                            .init(color: theme.colors.borderDefault, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    width: strokeWidth
                )
            case .glass:
                shapeStroke(gradient: theme.glass.borderGradient, width: strokeWidth)
            }
        }
    }

    @ViewBuilder
    private func shapeStroke(color: Color, width: CGFloat) -> some View {
        switch shape {
        case .capsule:
            Capsule().strokeBorder(color, lineWidth: width)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius).strokeBorder(color, lineWidth: width)
        }
    }

    @ViewBuilder
    private func shapeStroke(gradient: LinearGradient, width: CGFloat) -> some View {
        switch shape {
        case .capsule:
            Capsule().strokeBorder(gradient, lineWidth: width)
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius).strokeBorder(gradient, lineWidth: width)
        }
    }
}
```

- [ ] **Step 4: Run tests to verify all pass**

Run: `swift test --package-path CraftUIKit --filter testSearchBar`
Expected: PASS with 100% assertions.

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
git commit -m "feat: upgrade CraftSearchBar with full-spectrum styles, sizes, haptics, and zero-lag focus"
```

---

### Task 2: Update Interactive Gallery Showcase in CraftCatalogView & Catalog Tests

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift:1470-1500`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Consumes:
  - `CraftSearchBar`, `CraftSearchBarStyle`, `CraftSearchBarSize`, `CraftSearchBarShape`
- Produces:
  - Interactive multi-style, multi-size, loading demo in `CraftCatalogView`

- [ ] **Step 1: Write test assertion in CatalogViewTests.swift for new search bar styles & sizes**

```swift
// Add to CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift
func testCatalogSearchBarStylesAndSizes() {
    var query = ""
    let binding = Binding(get: { query }, set: { query = $0 })
    for style in CraftSearchBarStyle.allCases {
        for size in CraftSearchBarSize.allCases {
            let sb = CraftSearchBar(text: binding, size: size, style: style)
            XCTAssertNotNil(sb.body)
        }
    }
}
```

- [ ] **Step 2: Update CraftCatalogView.swift Controls Section**

```swift
// Update CraftCatalogView.swift SearchBar showcase
CraftText("CraftSearchBar (7 Styles, 3 Sizes, Haptics & Micro-Interactions)", style: .headline)

CraftSearchBar(
    text: $searchQuery,
    placeholder: "Search in .flat style (md)...",
    size: .md,
    style: .flat,
    shape: .capsule,
    onCancel: { searchQuery = "" }
)

CraftSearchBar(
    text: $searchQuery,
    placeholder: "Search in .elevated style (lg)...",
    size: .lg,
    style: .elevated,
    shape: .roundedRectangle(radius: 16),
    trailingIcon: "slider.horizontal.3",
    trailingAction: {},
    onCancel: { searchQuery = "" }
)

CraftSearchBar(
    text: $searchQuery,
    placeholder: "Search in .tactile3D style (md)...",
    size: .md,
    style: .tactile3D,
    shape: .roundedRectangle(radius: 14),
    customTint: theme.colors.brandPrimary,
    onCancel: { searchQuery = "" }
)

CraftSearchBar(
    text: $searchQuery,
    placeholder: "Search in .glass style (sm)...",
    size: .sm,
    style: .glass,
    shape: .capsule,
    onCancel: { searchQuery = "" }
)
```

- [ ] **Step 3: Run catalog test suite to verify 100% pass**

Run: `swift test --package-path CraftUIKit --filter CatalogViewTests`
Expected: PASS with 100% assertions.

- [ ] **Step 4: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift
git commit -m "feat: showcase CraftSearchBar full-spectrum styles and sizes in catalog gallery"
```

---

### Task 3: Full Package Build and Regression Verification

**Files:**
- Test: `CraftUIKit/Tests/CraftUIKitTests/`

- [ ] **Step 1: Run full test suite**

Run: `swift test --package-path CraftUIKit`
Expected: ALL test suites pass (ControlComponentTests, CatalogViewTests, InteractiveCardTests, etc.).

- [ ] **Step 2: Commit final documentation & code verification**

```bash
git add docs/superpowers/plans/2026-08-26-craftsearchbar-redesign-plan.md
git commit -m "chore: complete CraftSearchBar redesign and performance optimization plan verification"
```
