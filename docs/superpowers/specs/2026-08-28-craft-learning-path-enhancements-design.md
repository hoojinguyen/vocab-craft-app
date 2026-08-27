# Design Spec: CraftLearningPath Component Enhancements

- **Author**: Antigravity & Hoo Ji Nguyen
- **Date**: 2026-08-28
- **Status**: Validated Design
- **Target Package**: `CraftUIKit` (Design System) & `VocabCraftApp`

---

## 1. Overview & Problem Statement

`CraftLearningPath` is the primary gamified curriculum journey organism in `CraftUIKit`. While it already provides serpentine winding, 3D tactile nodes, section portals, and modal sheets, three critical capabilities are required to elevate its UX, telemetry, and accessibility to modern Apple standards:

1. **Sticky HUD when Header Docks**: As users scroll down multi-unit learning paths, section headers scroll out of view. A top floating overlay HUD provides continuous unit orientation and progress feedback, with full customization via a `@ViewBuilder stickyHUD:` closure.
2. **Advanced Impression Telemetry (`onNodeImpression`)**: Analytics require tracking when lesson nodes actually enter the viewport and remain visible for a minimum threshold (e.g. $\ge 0.5\text{s}$) rather than firing immediately on ephemeral scroll passes (fast flick-scrolling).
3. **Modal Sheet Focus & Accessibility (`@AccessibilityFocusState`)**: For VoiceOver and assistive tech users, opening `CraftLessonDetailSheet` must immediately focus the modal title/header, support the two-finger scrub/Escape gesture (`.accessibilityAction(.escape)`), and semantically group metric chips for seamless navigation.

---

## 2. Architectural Design & Public APIs

### 2.1 Feature 1: Sticky HUD on Section Docking

#### API Additions in `CraftLearningPath.swift`
```swift
public struct CraftLearningPath: View {
    // New properties
    public let stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)?
    
    // Initializers updated with stickyHUD builder support
    public init(
        sections: [LessonSection],
        winding: SerpentineWinding = .standard,
        rowPattern: RowPattern = .standard,
        onNodeTap: (@Sendable (LessonNodeModel) -> Void)? = nil,
        onStartLesson: (@Sendable (LessonNodeModel) -> Void)? = nil,
        showDetailModal: Bool = true,
        scrollToActive: Bool = true,
        showCelebration: Bool = true,
        pinSectionHeaders: Bool = true,
        headerDockThreshold: CGFloat = 15,
        scrollAnimation: Animation = .spring(response: 0.5, dampingFraction: 0.8),
        scrollAnchor: UnitPoint = .center,
        @ViewBuilder stickyHUD: ((LessonSection) -> some View)? = nil,
        @ViewBuilder detailSheet: ((LessonNodeModel, @escaping (LessonNodeModel) -> Void, @escaping () -> Void) -> some View)? = nil,
        @ViewBuilder background: (() -> some View)? = nil,
        @ViewBuilder emptyState: (() -> some View)? = nil,
        connectorDotDiameter: CGFloat? = nil,
        connectorDotSpacing: CGFloat? = nil,
        connectorTurnRadius: CGFloat? = nil,
        connectorEdgeInset: CGFloat? = nil,
        onSectionAppear: (@Sendable (LessonSection) -> Void)? = nil,
        onAutoScrolled: (@Sendable (String) -> Void)? = nil,
        onNodeImpression: (@Sendable (LessonNodeModel) -> Void)? = nil,
        nodeImpressionThreshold: TimeInterval = 0.5,
        connectorStyleResolver: ((LessonNodeState, LessonNodeState) -> SmartConnectorStyle)? = nil
    )
}
```

#### Docking State Flow
1. Each `CraftLessonSectionHeaderView` continuously measures its `minY` relative to `CraftLearningPathScrollView`.
2. When `minY <= headerDockThreshold`, it reports `onDockChange(true)`.
3. `CraftLearningPath` maintains `@State private var dockedSection: LessonSection?`.
4. When `dockedSection` is non-nil, an overlay floating HUD bar appears at the top:
   - **Default View**: A compact capsule with `theme.colors.surfaceElevated`, `theme.radii.xl`, `craftShadow(theme.shadows.md)`, displaying the unit level badge, icon, section title, and mini progress indicator.
   - **Custom Builder**: If `stickyHUDBuilder` is supplied, `stickyHUDBuilder(dockedSection)` is rendered.
   - **Transition**: Smooth `.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity))` animated with `.spring(response: 0.35, dampingFraction: 0.8)`.

---

### 2.2 Feature 2: Debounced Node Impression Telemetry (`onNodeImpression`)

#### API Additions
```swift
public let onNodeImpression: (@Sendable (LessonNodeModel) -> Void)?
public let nodeImpressionThreshold: TimeInterval // default: 0.5s
```

#### Impression Pipeline
1. Passed down through `CraftLearningPath` $\rightarrow$ `CraftLessonSectionBodyView` $\rightarrow$ `CraftLessonRow` $\rightarrow$ `CraftLessonNode`.
2. Inside `CraftLessonNode`:
   - `@State private var impressionTask: Task<Void, Never>? = nil`
   - `@State private var hasTrackedImpression: Bool = false`
3. On `.onAppear`:
   ```swift
   guard let onNodeImpression, !hasTrackedImpression else { return }
   impressionTask = Task { @MainActor in
       try? await Task.sleep(nanoseconds: UInt64(nodeImpressionThreshold * 1_000_000_000))
       if !Task.isCancelled {
           onNodeImpression(model)
           hasTrackedImpression = true
       }
   }
   ```
4. On `.onDisappear`:
   ```swift
   impressionTask?.cancel()
   impressionTask = nil
   ```
5. Fast scrolling past nodes cancels the task before `nodeImpressionThreshold` expires, preventing spurious analytics events.

---

### 2.3 Feature 3: Enhanced Sheet Focus & Accessibility

#### Implementation in `CraftLessonDetailSheet.swift`
1. **Focus State Management**:
   ```swift
   @AccessibilityFocusState private var isHeaderFocused: Bool
   ```
   On `.onAppear`, trigger `@MainActor` task with 100ms delay to assign `isHeaderFocused = true`, directing VoiceOver focus immediately to the modal title.
2. **Escape Action / Two-Finger Scrub**:
   ```swift
   .accessibilityAction(.escape) {
       triggerDismissFeedback()
       onDismiss?()
   }
   ```
3. **Metric Chips Semantic Grouping**:
   - Wrap each `metricChip` with `.accessibilityElement(children: .combine)` and clear, concise accessibility descriptions (e.g. `"Reward: 25 XP"`, `"Duration: 5 minutes"`, `"15 words"`).
4. **Header Accessibility Traits**:
   - Add `.accessibilityAddTraits(.isHeader)` to the sheet's title text for VoiceOver heading rotor navigation.

---

## 3. Design System & Token Discipline

- **Color Tokens**: `theme.colors.surfaceElevated`, `theme.colors.brandPrimary`, `theme.colors.hairline`, `theme.colors.textPrimary`, `theme.colors.textSecondary`.
- **Typography Tokens**: `theme.typography.titleMedium`, `theme.typography.caption`, `theme.typography.label`.
- **Spacing & Radii**: `theme.spacing.base`, `theme.spacing.sm`, `theme.radii.xl`, `theme.radii.full`.
- **Depth & Shadows**: `theme.shadows.md`, `theme.depths.topHighlight`.
- **Zero Raw Values**: No hardcoded colors, sizes, or un-tokenized padding.

---

## 4. Localization Architecture (100% Bilingual Parity)

Catalog: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
Prefix: `craft.learning_path.*`

| Key | English (`en`) | Vietnamese (`vi`) |
|---|---|---|
| `craft.learning_path.sticky_hud_progress_format` | `%lld%% complete` | `Hoàn thành %lld%%` |
| `craft.learning_path.close_sheet_hint` | `Dismisses the lesson detail sheet` | `Đóng bảng chi tiết bài học` |

---

## 5. Verification & Testing Plan

### Automated Unit Tests (`CraftLearningPathTests.swift`)
1. **Sticky HUD Tests**:
   - Verify `CraftLearningPath` properly initializes with default and custom `stickyHUDBuilder`.
   - Verify dock state update logic when `onDockChange` is triggered.
2. **Node Impression Telemetry Tests**:
   - Verify `onNodeImpression` callback fires when node remains visible for `threshold`.
   - Verify cancellation when node disappears before `threshold`.
3. **Accessibility & Sheet Tests**:
   - Verify `CraftLessonDetailSheet` escape action and accessibility traits.
   - Verify metric chips accessibility properties.
4. **Localization Parity**:
   - Run `swift test --filter LocalizationTests`.

### Manual & Interactive Verification
- Build and run `CraftUIKit` test suite (`swift test`).
- SwiftLint validation with 0 errors and 0 warnings.
- Xcode compiler diagnostic check: 0 errors, 0 warnings.
