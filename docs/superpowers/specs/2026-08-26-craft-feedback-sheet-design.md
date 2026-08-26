# CraftFeedbackSheet Technical Design Specification

**Document:** `docs/superpowers/specs/2026-08-26-craft-feedback-sheet-design.md`  
**Date:** 2026-08-26  
**Status:** In Review  
**Target:** `CraftUIKit` (iOS 17.0+, macOS 14.0+)  

---

## 1. Executive Overview & Design Rationale

In language learning apps (e.g., Duolingo, VocabCraft practice & reflex drills), presenting immediate, highly legible, and tactile feedback after a user submits an answer is a core interaction loop. 

### Why a Dedicated `CraftFeedbackSheet` over `CraftBottomSheet`?

| Attribute | `CraftBottomSheet` (Generic Modal) | `CraftFeedbackSheet` (Assessment Dock) |
| :--- | :--- | :--- |
| **Purpose** | Information display, settings, menus, custom forms | Answer feedback (Success / Error / Warning / Info) in drills & quizzes |
| **Dismissal Model** | Dismissable via swipe down drag gesture, backdrop tap, close button | **Non-dismissable via gesture**: Requires intentional forward progression via "CONTINUE" action |
| **Placement** | Modal overlay with detents (`.medium`, `.large`) | Fixed bottom dock (`ignoresSafeArea(edges: .bottom)`) hugging the thumb zone |
| **Semantic States** | Neutral surfaces (`surfaceCard`, `surfaceElevated`) | Status-driven tinting (`statusSuccess`, `statusDanger`, `statusWarning`, `statusInfo`) |
| **Action Priority** | Optional secondary buttons | Dominant, tactile primary action button ("CONTINUE") + optional accessory actions |

Separating `CraftFeedbackSheet` into `CraftUIKit/Sources/CraftUIKit/Components/Feedback/` maintains strict adherence to the **Single Responsibility Principle (SRP)**, avoids regression risks in generic sheets, and provides specialized sensory feedback and layout ergonomics tailored for learning workflows.

---

## 2. Architecture & Public API Specification

### 2.1. Semantic Status Enum (`CraftFeedbackStatus`)

```swift
/// Semantic status for assessment feedback sheets.
public enum CraftFeedbackStatus: String, Sendable, CaseIterable {
    case success
    case error
    case warning
    case info

    /// SF Symbol icon representation for the feedback state.
    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}
```

---

### 2.2. Component Definition (`CraftFeedbackSheet`)

```swift
/// A bottom-docked feedback sheet providing immediate validation, corrective instruction,
/// and primary progression action for quizzes, pronunciation, and reflex exercises.
public struct CraftFeedbackSheet<ExtraContent: View>: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Core Properties
    public let status: CraftFeedbackStatus
    public let title: String
    public let message: String?
    public let actionTitle: String
    public let surfaceStyle: CraftSurfaceStyle?
    public let onContinue: () -> Void
    public let onSecondaryAction: (() -> Void)?
    public let secondaryActionTitle: String?
    public let extraContent: ExtraContent?

    // MARK: - Initializers
    
    /// Initializer without extra accessory content.
    public init(
        status: CraftFeedbackStatus,
        title: String,
        message: String? = nil,
        actionTitle: String = CraftLocalized.string("craft.common.action.continue"),
        surfaceStyle: CraftSurfaceStyle? = nil,
        secondaryActionTitle: String? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void
    ) where ExtraContent == EmptyView

    /// Initializer with customizable extra content slot (@ViewBuilder).
    public init(
        status: CraftFeedbackStatus,
        title: String,
        message: String? = nil,
        actionTitle: String = CraftLocalized.string("craft.common.action.continue"),
        surfaceStyle: CraftSurfaceStyle? = nil,
        secondaryActionTitle: String? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder extraContent: () -> ExtraContent
    )
}
```

---

### 2.3. ViewModifier Presentation Extension

```swift
public extension View {
    /// Presents a feedback sheet docked at the bottom of the screen upon question submission.
    func craftFeedbackSheet<ExtraContent: View>(
        isPresented: Binding<Bool>,
        status: CraftFeedbackStatus,
        title: String,
        message: String? = nil,
        actionTitle: String = CraftLocalized.string("craft.common.action.continue"),
        surfaceStyle: CraftSurfaceStyle? = nil,
        secondaryActionTitle: String? = nil,
        onSecondaryAction: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        @ViewBuilder extraContent: @escaping () -> ExtraContent = { EmptyView() }
    ) -> some View
}
```

---

## 3. Theme & Surface Integration

### 3.1. Semantic Color Mapping & Dark Mode Contrast

Colors adapt dynamically using `CraftTheme.colors`:

| Status | Icon & Title Color | Light Mode Surface Tint | Dark Mode Surface Tint | Primary Action Button Tint |
| :--- | :--- | :--- | :--- | :--- |
| **`.success`** | `theme.colors.statusSuccess` | `statusSuccess.opacity(0.16)` | `statusSuccess.opacity(0.24)` | `statusSuccess` (Green Tactile) |
| **`.error`** | `theme.colors.statusDanger` | `statusDanger.opacity(0.12)` | `statusDanger.opacity(0.22)` | `statusDanger` (Red Tactile) |
| **`.warning`** | `theme.colors.statusWarning` | `statusWarning.opacity(0.14)` | `statusWarning.opacity(0.22)` | `statusWarning` (Amber Tactile) |
| **`.info`** | `theme.colors.statusInfo` | `statusInfo.opacity(0.12)` | `statusInfo.opacity(0.20)` | `brandPrimary` / `statusInfo` |

### 3.2. Surface Style Support (`CraftSurfaceStyle`)

- **`.flat`**: Clean semantic background fill without elevation.
- **`.elevated`**: Multi-stop border highlight gradient + `theme.shadows.xl` elevation.
- **`.glass`**: Translucent `.ultraThinMaterial` frosted backing with status color refraction tint and specular border gradient.
- **`.tactile3D`**: Extruded 3D bottom bevel with top highlight stroke.
- **`.outlined`**: 1.5pt solid semantic border stroke with subtle tinted card background.

---

## 4. Sensory Feedback & Motion Physics

1. **Appearance Haptics:**
   - Automatically executes appropriate haptic feedback on presentation:
     - `.success` $\rightarrow$ `UINotificationFeedbackGenerator().notificationOccurred(.success)`
     - `.error` $\rightarrow$ `UINotificationFeedbackGenerator().notificationOccurred(.error)`
     - `.warning` $\rightarrow$ `UINotificationFeedbackGenerator().notificationOccurred(.warning)`
     - `.info` $\rightarrow$ `UIImpactFeedbackGenerator(style: .medium).impactOccurred()`
2. **Micro-Transitions:**
   - Slide-up transition from screen bottom with spring damping (`theme.animations.springSmooth`).
   - Icon pulse on entry using SF Symbols `.symbolEffect(.bounce.byLayer)`.
3. **Accessibility:**
   - Tagged with `.accessibilityElement(children: .combine)`.
   - VoiceOver description: `"[Status Title], [Message]. Action: [ActionTitle]"`.

---

## 5. Testing & Verification Strategy

1. **Unit Tests (`FeedbackComponentTests.swift`):**
   - Verify `CraftFeedbackStatus` icon names, titles, and semantic resolution.
   - Verify initializers with both default and custom `extraContent`.
   - Verify action triggers for both `onContinue` and `onSecondaryAction`.
   - Verify surface style propagation and tint calculations.
2. **Design Catalog Preview (`CraftCatalogView.swift`):**
   - Add a dedicated section in the `CraftCatalogView` showing interactive success, error (with correct answer message), warning, and liquid glass variants.
3. **Regression Testing:**
   - Execute full test suite (`swift test`) ensuring existing 417+ tests pass.

---

## 6. Implementation Boundaries

| File | Action | Description |
| :--- | :--- | :--- |
| `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftFeedbackSheet.swift` | **NEW** | Implement `CraftFeedbackStatus`, `CraftFeedbackSheet`, and `.craftFeedbackSheet()` view modifier. |
| `CraftUIKit/Sources/CraftUIKit/Environment/CraftLocalized.swift` | **MODIFY** | Ensure localized string keys for common feedback strings (`craft.feedback.success_title`, `craft.feedback.error_title`, `craft.feedback.continue_action`). |
| `CraftUIKit/Tests/CraftUIKitTests/FeedbackComponentTests.swift` | **NEW** | Comprehensive unit test suite for feedback sheet states and interactions. |
| `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift` | **MODIFY** | Add interactive preview matrix to the design system catalog. |
