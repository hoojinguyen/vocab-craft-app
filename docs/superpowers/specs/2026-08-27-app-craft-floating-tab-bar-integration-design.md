# Design Specification: CraftFloatingTabBar Integration in VocabCraftApp

**Date:** 2026-08-27  
**Target:** `VocabCraftApp` Navigation Layer (`HomepageView`, `TabItem`, `AppRouter`)  
**Status:** In Review  

---

## 1. Overview & Problem Statement

`CraftUIKit` provides `CraftFloatingTabBar`, a design-system floating capsule navigation component with native Liquid Glass (`iOS 26+`), smooth spring pill indicator animations (`matchedGeometryEffect`), multi-surface support, and accessibility VoiceOver compliance.

However, `VocabCraftApp` currently relies on an ad-hoc legacy component `LiquidGlassTabBar.swift` in `Features/Homepage/Views/`, leading to:
- Code duplication between the design system (`CraftUIKit`) and application layer (`VocabCraftApp`).
- Inconsistent tactile elevation, safe area handling, and animation choreography.
- `TabItem` being tightly coupled inside `LiquidGlassTabBar.swift` rather than properly isolated in the app's Navigation architecture.

### Objectives:
1. **Adopt `CraftFloatingTabBar` in `VocabCraftApp`**: Replace `LiquidGlassTabBar` in `HomepageView` with `CraftFloatingTabBar` using `.glass` style and `.floating` center action button.
2. **Promote `TabItem` to Core Navigation**: Isolate `TabItem` into `VocabCraftApp/App/Navigation/TabItem.swift` and conform it to `CraftTabItemProtocol`.
3. **Configure 4 Side Tabs + Center Reflex Hero FAB**:
   - Left Tabs: `.home` (Trang chủ), `.vocabulary` (Từ vựng)
   - Center FAB: `.reflex` (Phản xạ / Quick Reflex Blitz) with `CraftSymbol.practice` (`bolt.fill`)
   - Right Tabs: `.search` (Tra từ), `.settings` (Cài đặt)
4. **Comply with Zero Hardcoded Strings Policy**: Ensure all tab titles, VoiceOver labels, and center FAB actions use `AppStrings.Tabs.*` (under `Localizable.xcstrings`).
5. **Clean Legacy Code & Project References**: Remove `LiquidGlassTabBar.swift` and update `VocabCraftApp.xcodeproj/project.pbxproj`.
6. **Comprehensive Unit Testing**: Update `HomepageViewTests.swift` to validate `TabItem` conformance, tab switching, and `CraftFloatingTabBar` binding.

---

## 2. Architecture & Data Flow

```
VocabCraftApp
├── App/Navigation/
│   ├── AppRouter.swift (Manages selectedTab & Deep Links)
│   └── TabItem.swift [NEW] (Conforms to CraftTabItemProtocol & Identifiable)
│
├── Features/Homepage/Views/
│   └── HomepageView.swift
│       └── CraftFloatingTabBar<TabItem> (From CraftUIKit)
│           ├── selectedItem: $router.selectedTab
│           ├── items: TabItem.navigationTabs ([.home, .vocabulary, .search, .settings])
│           ├── style: .glass
│           ├── centerPosition: .floating
│           ├── centerAction: { router.navigateToReflex() }
│           ├── centerSymbol: CraftSymbol.practice.rawValue ("bolt")
│           └── centerTitleKey: AppStrings.Tabs.reflex
```

---

## 3. Detailed Component Specifications

### 3.1 `TabItem` Model (`App/Navigation/TabItem.swift`)

`TabItem` will be extracted from `LiquidGlassTabBar.swift` into a dedicated file conforming to `CraftTabItemProtocol`:

```swift
import CraftUIKit
import Foundation
import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable, Sendable, CraftTabItemProtocol {
    case home = 0
    case vocabulary = 1
    case search = 4
    case reflex = 2
    case settings = 3

    public var id: Int { rawValue }

    public var title: String { "" }

    public var titleKey: LocalizedStringKey? {
        switch self {
        case .home: return AppStrings.Tabs.home
        case .vocabulary: return AppStrings.Tabs.vocabulary
        case .search: return AppStrings.Tabs.search
        case .reflex: return AppStrings.Tabs.reflex
        case .settings: return AppStrings.Tabs.settings
        }
    }

    public var symbol: String {
        switch self {
        case .home: return CraftSymbol.home.rawValue
        case .vocabulary: return CraftSymbol.study.rawValue
        case .search: return CraftSymbol.search.rawValue
        case .reflex: return CraftSymbol.practice.rawValue
        case .settings: return CraftSymbol.settings.rawValue
        }
    }

    public var badgeCount: Int? { nil }

    /// The 4 navigation tabs rendered on the sides of the floating dock.
    public static var navigationTabs: [TabItem] {
        [.home, .vocabulary, .search, .settings]
    }
}
```

### 3.2 `HomepageView` Integration

In `HomepageView.swift`, replace `LiquidGlassTabBar` with `CraftFloatingTabBar`:

```swift
if router.selectedTab != .reflex {
    CraftFloatingTabBar(
        selectedItem: $router.selectedTab,
        items: TabItem.navigationTabs,
        style: .glass,
        centerPosition: .floating,
        centerAction: {
            router.navigateToReflex()
        },
        centerSymbol: CraftSymbol.practice.rawValue,
        centerTitleKey: AppStrings.Tabs.reflex
    )
    .transition(.move(edge: .bottom).combined(with: .opacity))
}
```

- When the user taps the center FAB, `router.navigateToReflex()` activates `.reflex`.
- Since `router.selectedTab == .reflex`, the tab bar automatically slides out via its transition while the full-screen `ReflexBlitzView` takes focus.
- When dismissing `ReflexBlitzView`, `handleReflexDismiss()` resets to `.home` and the tab bar smoothly reappears.

### 3.3 Deletion of Legacy `LiquidGlassTabBar.swift`

- Remove `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift`.
- Update `VocabCraftApp.xcodeproj/project.pbxproj` to replace `LiquidGlassTabBar.swift` with `TabItem.swift` under the Navigation group.

---

## 4. Accessibility & Localization

1. **Zero Hardcoded Strings**:
   - `AppStrings.Tabs.home` -> `"tabs.home"`
   - `AppStrings.Tabs.vocabulary` -> `"tabs.vocabulary"`
   - `AppStrings.Tabs.search` -> `"tabs.search"`
   - `AppStrings.Tabs.reflex` -> `"tabs.reflex"`
   - `AppStrings.Tabs.settings` -> `"tabs.settings"`
2. **VoiceOver Accessibility**:
   - Each tab button automatically receives `.accessibilityLabel`, `.accessibilityAddTraits([.isButton, .isSelected])` directly handled by `CraftFloatingTabBar`.
   - The center FAB receives `.accessibilityLabel(Text(AppStrings.Tabs.reflex))`.
3. **Motion & Transparency**:
   - Respects `accessibilityReduceMotion` and `accessibilityReduceTransparency` via `CraftUIKit` built-in environment observers.

---

## 5. Verification & Testing Plan

### Automated Unit Tests (`VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`)

1. **`testTabItemCraftProtocolConformance`**:
   - Verify `TabItem.home.titleKey == AppStrings.Tabs.home`
   - Verify `TabItem.home.symbol == CraftSymbol.home.rawValue`
   - Verify `TabItem.navigationTabs.count == 4`
   - Verify `TabItem.allCases.count == 5`
2. **`testCraftFloatingTabBarIntegration`**:
   - Initialize `CraftFloatingTabBar(selectedItem:items:style:centerPosition:centerAction:centerSymbol:centerTitleKey:)` with `TabItem.navigationTabs`.
   - Verify binding changes from `.home` to `.vocabulary`, `.search`, `.settings`.
3. **`testHomepageViewBodyAcrossAllTabs`**:
   - Ensure `HomepageView` renders correctly across `.home`, `.vocabulary`, `.search`, `.reflex`, and `.settings`.
4. **Full Test Suite Run**:
   - Execute `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` (or `swift test`).

---

## 6. Files Touched

| Action | Path | Purpose |
| :--- | :--- | :--- |
| **NEW** | `VocabCraftApp/App/Navigation/TabItem.swift` | Isolated `TabItem` enum conforming to `CraftTabItemProtocol` |
| **MODIFY** | `VocabCraftApp/Features/Homepage/Views/HomepageView.swift` | Integrate `CraftFloatingTabBar` |
| **MODIFY** | `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift` | Update unit tests for `CraftFloatingTabBar` & `TabItem` |
| **DELETE** | `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift` | Remove legacy duplicate component |
| **MODIFY** | `VocabCraftApp.xcodeproj/project.pbxproj` | Update Xcode project file hierarchy |
