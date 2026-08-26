# CraftUIKit Animation Audit, Performance Optimization & Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all animation lag, layout thrashing, and animation leakage in CraftUIKit, expand `CraftAnimationTokens`, and add modern gamified animations (Squash & Stretch, Path Surge, Symbol Effects, Numeric Text transitions).

**Architecture:** Mở rộng hệ thống Tokens với 5 đường cong Spring chuyên dụng và Scoped Animation Helpers. Cô lập các vòng lặp hoạt cảnh vô tận (`repeatForever`) vào leaf subview độc lập để triệt tiêu bão invalidation trên SwiftUI Attribute Graph. Loại bỏ `.animation` lan truyền ngoài ý muốn trên các modifier overlays (`CraftToast`, `CraftBottomSheet`, `CraftDialog`). Tích hợp `KeyframeAnimator`, `PhaseAnimator`, và `.symbolEffect` theo chuẩn iOS 17+/18+.

**Tech Stack:** Swift 6, SwiftUI (iOS 17+/18+), XCTest.

**Spec:** `docs/superpowers/specs/2026-08-26-animation-audit-and-enhancement-design.md`

## Global Constraints
- Target platform: iOS 17.0+ (Swift 6.0 compatibility, Swift Testing & XCTest).
- Maintain 100% test compatibility: all 471+ existing tests in `CraftUIKit` must pass.
- All animated components must strictly respect `accessibilityReduceMotion`.
- No `.animation(..., value: ...)` on root container `ZStack` wrapping arbitrary user content.

---

### Task 1: Expand `CraftAnimationTokens` & Motion Helpers

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Tokens/CraftAnimationTokens.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Modifiers/CraftMotionGuardModifier.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/TokenTests.swift`

**Interfaces:**
- Consumes: SwiftUI `Animation`, `CraftAnimationTokens`
- Produces:
  - `CraftAnimationTokens.springGentle: Animation`
  - `CraftAnimationTokens.springInteractive: Animation`
  - `View.craftAnimation(_:value:) -> some View`
  - `View.craftScopedAnimation(_:) -> some View`

- [ ] **Step 1: Write the failing tests in TokenTests.swift**

```swift
// In TokenTests.swift:
func testExpandedAnimationTokens() {
    let tokens = CraftDefaultAnimationTokens()
    _ = tokens.springSnappy
    _ = tokens.springSmooth
    _ = tokens.springBouncy
    _ = tokens.springGentle
    _ = tokens.springInteractive
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TokenTests`
Expected: FAIL (missing `springGentle` and `springInteractive`)

- [ ] **Step 3: Implement updated `CraftAnimationTokens.swift` and `CraftMotionGuardModifier.swift`**

Update `CraftAnimationTokens.swift`:
```swift
public protocol CraftAnimationTokens: Sendable {
    var springSnappy: Animation { get }
    var springSmooth: Animation { get }
    var springBouncy: Animation { get }
    var springGentle: Animation { get }
    var springInteractive: Animation { get }
}

public extension CraftAnimationTokens {
    var springGentle: Animation {
        .spring(response: 0.55, dampingFraction: 0.90)
    }
    var springInteractive: Animation {
        .spring(response: 0.15, dampingFraction: 0.82)
    }
}

public struct CraftDefaultAnimationTokens: CraftAnimationTokens {
    public var springSnappy: Animation
    public var springSmooth: Animation
    public var springBouncy: Animation
    public var springGentle: Animation
    public var springInteractive: Animation

    public init(
        springSnappy: Animation = .spring(response: 0.22, dampingFraction: 0.68),
        springSmooth: Animation = .spring(response: 0.35, dampingFraction: 0.85),
        springBouncy: Animation = .spring(response: 0.42, dampingFraction: 0.58),
        springGentle: Animation = .spring(response: 0.55, dampingFraction: 0.90),
        springInteractive: Animation = .spring(response: 0.15, dampingFraction: 0.82)
    ) {
        self.springSnappy = springSnappy
        self.springSmooth = springSmooth
        self.springBouncy = springBouncy
        self.springGentle = springGentle
        self.springInteractive = springInteractive
    }
}
```

Create `CraftMotionGuardModifier.swift`:
```swift
import SwiftUI

public struct CraftMotionGuardModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    public func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : animation, value: value)
    }
}

public extension View {
    func craftAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(CraftMotionGuardModifier(animation: animation, value: value))
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TokenTests`
Expected: PASS

---

### Task 2: Fix Animation Leakage in Overlays (`CraftToast`, `CraftBottomSheet`, `CraftDialog`)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftToast.swift:250-270`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftBottomSheet.swift:250-302`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift:445-481`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`

**Interfaces:**
- Consumes: `CraftToastModifier`, `CraftBottomSheetModifier`, `CraftDialogModifier`
- Produces: Isolated transitions on modal surfaces without root `.animation` leakage.

- [ ] **Step 1: Write test for isolated overlay presentation**

Add to `ContainerOverlayTests.swift`:
```swift
func testOverlayDoesNotCorruptHostHierarchy() {
    // Assert overlay view mounts with correct transitions
}
```

- [ ] **Step 2: Remove root `.animation` from `CraftToastModifier`, `CraftBottomSheetModifier`, `CraftDialogModifier`**

In `CraftToastModifier`:
```swift
// Remove .animation(theme.animations.springSmooth, value: isPresented) from outer ZStack.
// Use scoped withAnimation on dismiss and transition on toast card.
```

In `CraftBottomSheetModifier`:
```swift
// Remove .animation(theme.animations.springSmooth, value: isPresented) from outer ZStack.
// Scrim gets .transition(.opacity)
// Sheet gets .transition(.move(edge: .bottom).combined(with: .opacity))
```

In `CraftDialogModifier`:
```swift
// Remove .animation(theme.animations.springSmooth, value: isPresented) from outer ZStack.
// Backdrop gets .transition(.opacity)
// Dialog card gets .transition(.scale(scale: 0.92).combined(with: .opacity))
```

- [ ] **Step 3: Run test suite to verify overlays pass**

Run: `swift test --filter ContainerOverlayTests`
Expected: PASS

---

### Task 3: Eliminate Invalidation Storms in `CraftActivityTrackerCard`, `CraftStepNode`, `CraftSpinner`, `ShimmerModifier`

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftPulsingAuraRing.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftActivityTrackerCard.swift:520-530`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftStepNode.swift:188-204`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftSpinner.swift:40-72`
- Modify: `CraftUIKit/Sources/CraftUIKit/Modifiers/ShimmerModifier.swift:20-55`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftStreakComponentTests.swift`, `AtomComponentTests.swift`

**Interfaces:**
- Consumes: `CraftPulsingAuraRing`
- Produces: 0% body invalidation on parent cards when aura rings pulse.

- [ ] **Step 1: Create `CraftPulsingAuraRing` leaf atom view**

```swift
import SwiftUI

public struct CraftPulsingAuraRing: View {
    public let color: Color
    public let size: CGFloat
    public let lineWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(color: Color, size: CGFloat = 28, lineWidth: CGFloat = 2.5) {
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        if reduceMotion {
            Circle()
                .stroke(color.opacity(0.35), lineWidth: lineWidth)
                .frame(width: size, height: size)
        } else {
            PhaseAnimator([false, true]) { isExpanded in
                Circle()
                    .stroke(color.opacity(isExpanded ? 0.0 : 0.6), lineWidth: isExpanded ? lineWidth * 1.4 : lineWidth)
                    .scaleEffect(isExpanded ? 1.28 : 1.0)
                    .frame(width: size, height: size)
            } animation: { _ in
                .easeInOut(duration: 1.4)
            }
        }
    }
}
```

- [ ] **Step 2: Replace `@State isPulsing` in `CraftActivityTrackerCard` & `CraftStepNode`**

Use `CraftPulsingAuraRing` in `CraftActivityTrackerCard` (removing the parent `@State private var isPulsing` and its `withAnimation.repeatForever` loop).
Do the same in `CraftStepNode`.

- [ ] **Step 3: Refactor `CraftSpinner` & `ShimmerModifier`**

Refactor `CraftSpinner` to use `PhaseAnimator` or `TimelineView` rotation without calling `withAnimation.repeatForever` inside parent state handlers.
Refactor `ShimmerModifier` to animate phase via an isolated `AnimatableModifier`.

- [ ] **Step 4: Run test suite**

Run: `swift test --filter CraftStreakComponentTests`
Run: `swift test --filter AtomComponentTests`
Expected: PASS

---

### Task 4: Optimize `CraftLearningPath`, `CraftLessonNode`, `CraftNodeConnector`, `CraftCelebrationSheet`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift:515-550`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftPathNode.swift:465-500`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift:250-310`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftCelebrationSheet.swift:380-435`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`, `FeedbackFXTests.swift`

**Interfaces:**
- Consumes: Native `.contentTransition(.numericText)`
- Produces: GPU-efficient halo glow, cached Bézier dotted paths, high-performance counter.

- [ ] **Step 1: Replace dynamic shadow in `CraftLessonNode` & `CraftPathNode`**

Use radial multi-stop gradient without continuous `.shadow(radius: 6)` evaluation during phase animations.

- [ ] **Step 2: Optimize `CraftSnakeDottedSegmentView`**

Pre-calculate stroke style dimensions and simplify dash phase updates.

- [ ] **Step 3: Update `CraftCelebrationSheet` counter**

Remove `async for` + `sleep(30ms)` loop. Instead, trigger single `withAnimation(theme.animations.springSmooth)` on `displayedValue` with `.contentTransition(.numericText(countsDown: false))` and single haptic feedback trigger.

- [ ] **Step 4: Run test suite**

Run: `swift test --filter CraftLearningPathTests`
Run: `swift test --filter FeedbackFXTests`
Expected: PASS

---

### Task 5: Implement `CraftSquashAndStretch` Keyframe Physics

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Modifiers/CraftSquashAndStretchModifier.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `KeyframeAnimator`
- Produces: `View.craftSquashAndStretch(trigger:) -> some View`

- [ ] **Step 1: Create `CraftSquashAndStretchModifier.swift`**

```swift
import SwiftUI

struct SquashValues {
    var scaleX: Double = 1.0
    var scaleY: Double = 1.0
    var yOffset: Double = 0.0
}

public struct CraftSquashAndStretchModifier<T: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public let trigger: T

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .keyframeAnimator(
                    initialValue: SquashValues(),
                    trigger: trigger
                ) { view, value in
                    view
                        .scaleEffect(x: value.scaleX, y: value.scaleY)
                        .offset(y: value.yOffset)
                } keyframes: { _ in
                    KeyframeTrack(\.scaleX) {
                        SpringKeyframe(1.08, duration: 0.12)
                        SpringKeyframe(0.95, duration: 0.15)
                        CubicKeyframe(1.0, duration: 0.10)
                    }
                    KeyframeTrack(\.scaleY) {
                        SpringKeyframe(0.92, duration: 0.12)
                        SpringKeyframe(1.06, duration: 0.15)
                        CubicKeyframe(1.0, duration: 0.10)
                    }
                    KeyframeTrack(\.yOffset) {
                        SpringKeyframe(3.0, duration: 0.12)
                        SpringKeyframe(-2.0, duration: 0.15)
                        CubicKeyframe(0.0, duration: 0.10)
                    }
                }
        }
    }
}

public extension View {
    func craftSquashAndStretch<T: Equatable>(trigger: T) -> some View {
        modifier(CraftSquashAndStretchModifier(trigger: trigger))
    }
}
```

- [ ] **Step 2: Integrate into `CraftButton` & `CraftChoiceCard`**

Apply modifier on press or state selection events.

- [ ] **Step 3: Run interactive tests**

Run: `swift test --filter InteractiveCardTests`
Expected: PASS

---

### Task 6: Implement Semantic Symbol Effects & Path Surge Animations

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Feedback/CraftSymbolEffects.swift`
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftPathUnlockSurge.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/FeedbackFXTests.swift`

**Interfaces:**
- Consumes: SF Symbol Effects (iOS 17+)
- Produces: `.craftSymbolBounce()`, `.craftSymbolPulse()`, `CraftPathUnlockSurgeView`

- [ ] **Step 1: Create `CraftSymbolEffects.swift`**

```swift
import SwiftUI

public extension View {
    @ViewBuilder
    func craftSymbolBounce<V: Equatable>(value: V) -> some View {
        self.symbolEffect(.bounce, value: value)
    }

    @ViewBuilder
    func craftSymbolPulse(isActive: Bool) -> some View {
        self.symbolEffect(.pulse, isActive: isActive)
    }

    @ViewBuilder
    func craftSymbolVariableColor(isActive: Bool) -> some View {
        self.symbolEffect(
            .variableColor.iterative.reversing.dimInactiveLayers,
            options: .repeating,
            isActive: isActive
        )
    }
}
```

- [ ] **Step 2: Create `CraftPathUnlockSurge.swift`**

Implement the light surge particle that animates along Bézier paths for node unlock celebrations.

- [ ] **Step 3: Run test suite**

Run: `swift test --filter FeedbackFXTests`
Expected: PASS

---

### Task 7: Comprehensive Regression Verification

- [ ] **Step 1: Execute full test suite**

Run: `swift test` in `CraftUIKit/`
Expected: 100% pass (all 471+ tests pass without warnings or errors).
