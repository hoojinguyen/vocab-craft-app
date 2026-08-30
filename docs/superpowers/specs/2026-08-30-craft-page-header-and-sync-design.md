# Feature Spec: CraftPageHeader & Cross-Screen Header Synchronization

- **Date:** 2026-08-30
- **Status:** Approved / Ready for Implementation Planning
- **Component Layer:** `CraftUIKit` (Design System Organism) + `VocabCraftApp` (Features)
- **Target Platforms:** iOS 17.0+ (SwiftUI 6 / Swift 6 Strict Concurrency)

---

## 1. Executive Summary

This specification defines the creation of a modular, reusable **`CraftPageHeader`** component in **`CraftUIKit`**, featuring **Apple Books-inspired scroll-driven fading animations** and **Slot-based architecture**. It unifies header presentation across all screens in `VocabCraftApp` (starting with **Home** and **Kho từ / Vocabulary Vault**, and prepared for future screens like **AI Tutor** and **Settings**).

### Key Deliverables:
1. **`CraftPageHeader` in `CraftUIKit`**:
   - Universal slot-based container component with `.leading` (Large Title) and `.center` (Inline Title) alignment variants.
   - Customizable `@ViewBuilder leading` and `@ViewBuilder trailing` slots.
   - Native Apple Books scroll-driven fade & subtle scale transition (`.scrollTransition(.animated)`).
2. **Scroll Position & Tab Switch Stabilization**:
   - Resolve the auto-scroll bug on the Home screen so switching tabs preserves the user's scroll position without forcing repeated auto-scrolls.
3. **Vocabulary Vault (Kho từ) Header Redesign**:
   - Replace standard navigation bar with `CraftPageHeader` (`.leading` Large Title).
   - Add toggleable `CraftSearchBar` triggered from the trailing search button with smooth spring motion.
4. **Zero Hardcoded Strings & Token Conformance**:
   - 100% token usage (`CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`).
   - 100% bilingual localization parity in `Localizable.xcstrings`.

---

## 2. Component Architecture & API: `CraftPageHeader`

### 2.1 Enum & Type Definitions (`Packages/CraftUIKit`)

```swift
/// Layout alignment variant for `CraftPageHeader`.
public enum CraftHeaderAlignment: Sendable, Equatable {
    /// Large Title style (Leading-aligned title with `displayLarge` typography, Apple Books style).
    case leading
    /// Inline Title style (Centered title with `headline`/`titleLarge` typography).
    case center
}

/// A unified, slot-based navigation and page header organism in CraftUIKit.
public struct CraftPageHeader<Leading: View, Trailing: View>: View {
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?
    public let alignment: CraftHeaderAlignment
    public let enableScrollFade: Bool
    
    private let leadingContent: Leading
    private let trailingContent: Trailing
    
    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        alignment: CraftHeaderAlignment = .leading,
        enableScrollFade: Bool = true,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
        self.enableScrollFade = enableScrollFade
        self.leadingContent = leading()
        self.trailingContent = trailing()
    }
}
```

### 2.2 Layout Topologies

#### Topology A: `.leading` (Large Title — Default for Primary Screens like Home, Kho từ)
```
┌─────────────────────────────────────────────────────────────┐
│ [Leading Slot]                                              │
│                                                             │
│ Title (Display Large, Bold)              [ Trailing Slot ]  │
│ Subtitle (Caption, Muted)                                   │
└─────────────────────────────────────────────────────────────┘
```

#### Topology B: `.center` (Inline Title — For Sub-screens, Detail Modals, AI Tutor)
```
┌─────────────────────────────────────────────────────────────┐
│ [Leading Slot]        Title (Headline)      [Trailing Slot] │
│                       Subtitle (Caption)                    │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Styling & Design Tokens

| Property | Leading Variant | Center Variant | Design Token Reference |
| :--- | :--- | :--- | :--- |
| **Title Font** | `displayLarge` (bold, serif/rounded) | `headline` (semibold) | `theme.typography.displayLarge` / `headline` |
| **Title Color** | `textPrimary` | `textPrimary` | `theme.colors.textPrimary` |
| **Subtitle Font** | `caption` (regular) | `caption` (regular) | `theme.typography.caption` |
| **Subtitle Color** | `textSecondary` | `textSecondary` | `theme.colors.textSecondary` |
| **Horizontal Inset** | 16pt (`spacing.base`) | 16pt (`spacing.base`) | `theme.spacing.base` |
| **Vertical Inset** | 8pt (`spacing.xs`) | 8pt (`spacing.xs`) | `theme.spacing.xs` |

---

## 3. Apple Books Scroll Transition Mechanics

### 3.1 Scroll-Driven Motion Modifier
When `enableScrollFade == true`, `CraftPageHeader` attaches `.scrollTransition(.animated)` to dynamically respond to scroll offsets:

- **Opacity Curve:** Transition smoothly from `1.0` (at top) to `0.0` as the header moves past the top boundary (`max(0.0, 1.0 - abs(phase.value) * 1.25)`).
- **Scale & Parallax Dampening:** Subtle scale factor (`1.0 - abs(phase.value) * 0.04`) and vertical offset damping (`phase.value * -8pt`).
- **Reduce Motion Support:** When `@Environment(\.accessibilityReduceMotion)` is active, scale and parallax offsets are omitted, applying only gentle linear opacity change.

```swift
@ViewBuilder
private func applyScrollTransition<Content: View>(_ content: Content) -> some View {
    if enableScrollFade {
        content.scrollTransition(.animated) { view, phase in
            view
                .opacity(reduceMotion ? (phase.isIdentity ? 1.0 : 0.0) : max(0.0, 1.0 - abs(phase.value) * 1.25))
                .scaleEffect(reduceMotion ? 1.0 : (1.0 - abs(phase.value) * 0.04))
                .offset(y: reduceMotion ? 0 : phase.value * -8)
        }
    } else {
        content
    }
}
```

---

## 4. Feature Integrations

### 4.1 Home Screen (`HomepageView` & `CraftLearningPath`)
- **Header Placement:** Configured via `topHeaderBuilder` of `CraftLearningPath`.
- **Trailing Slot Components:**
  1. `CraftStreakBadge` (size: `.sm`, displays current streak 🔥).
  2. `CraftProgressRing` (36pt circular goal progress ring `8/10`).
  3. Circular User Avatar Button (initials, tap navigates to Settings/Profile).
- **Tab Switching & Scroll Stabilization:**
  - Introduce `hasPerformedInitialScroll: Bool` inside `CraftLearningPath` state.
  - On app launch, view renders at top, pauses 300ms, then smoothly scrolls to the active lesson node.
  - On tab switching, scroll position is preserved without triggering repeated programmatic scrolls.

### 4.2 Kho từ / Vocabulary Vault (`VocabularyView`)
- **Header Placement:** At the top of `VocabularyView` scroll hierarchy.
- **Title:** `app.vault.title` ("Kho từ" / "Vocabulary Vault").
- **Trailing Slot:** `CraftIconButton(iconName: "magnifyingglass", variant: .subtle, shape: .circle)`.
- **Collapsible Search Interaction:**
  - `@State private var isSearchVisible: Bool = false` (default: hidden).
  - Tapping search icon toggles `isSearchVisible` with spring animation.
  - `CraftSearchBar` smoothly slides down with `.transition(.move(edge: .top).combined(with: .opacity))`.
  - When search is active and dismissed, `isSearchVisible` collapses back.
- **Subsequent Content:** Segmented tab control (`Chưa thuộc`, `Đã thuộc`, `Đã lưu`), `CraftButton` (Luyện tập), Word List.

---

## 5. Localization & String Catalog

### 5.1 CraftUIKit Catalog (`Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`)
| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `craft.header.a11y.title` | `Page Header` | `Tiêu đề trang` |
| `craft.header.a11y.search_toggle` | `Toggle Search` | `Bật tắt tìm kiếm` |

### 5.2 App Catalog (`VocabCraftApp/Resources/Localizable.xcstrings`)
| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `app.home.title` | `Home` | `Học tập` |
| `app.vault.title` | `Vocabulary Vault` | `Kho từ` |

---

## 6. Verification & Quality Gates

1. **Automated Unit & View Tests:**
   - `CraftPageHeaderTests.swift` in `CraftUIKitTests`:
     - Test leading and center alignment layout render.
     - Test subtitle display and custom leading/trailing slots.
     - Test accessibility labels and traits.
   - `HomepageViewTests.swift`:
     - Verify header integration and scroll preservation behavior.
   - `VocabularyViewTests.swift`:
     - Verify search bar toggle on search button tap and header render.
2. **Compiler & Linter Verification:**
   - 0 compiler warnings, 0 SwiftLint warnings.
   - Run `swift test` across packages and Xcode test suite.
