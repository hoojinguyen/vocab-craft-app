# CraftDialog Redesign & HIG Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize and redesign `CraftDialog` in `CraftUIKit` to support adaptive horizontal/vertical button layouts (`ViewThatFits`), context-aware backdrop tap dismissal with callback safety, enhanced title typography, custom badge tints, declarative haptic feedback, and modal accessibility traits.

**Architecture:** 
1. Introduce `CraftDialogButtonLayout` (`.automatic`, `.horizontal`, `.vertical`) with an adaptive layout engine using `ViewThatFits` to automatically switch between `HStack` (paired with `.outline` cancel button) and `VStack` (paired with `.ghost` cancel button).
2. Upgrade backdrop dismissal logic in `CraftDialogModifier` to automatically protect `.danger` alerts from accidental backdrop tap dismissal while guaranteeing `cancelAction` callback invocation upon allowed dismissals.
3. Enhance title typography to `.title3.bold()` with `.rounded` font design and add `.sensoryFeedback` and SF Symbol entry motion.
4. Add full accessibility conformance (`.isModal`, `.contain`) and ensure backward compatibility with existing convenience initializers and view extensions.

**Tech Stack:** Swift 5.10+, SwiftUI (iOS 17.0+, macOS 14.0+), XCTest.

**Spec:** `docs/superpowers/specs/2026-08-26-craftdialog-redesign-design.md`

## Global Constraints

- Platform Target: iOS 17.0+, macOS 14.0+.
- Zero third-party dependencies (Pure SwiftUI + Foundation).
- Dynamic Type: Dialog buttons and content must scale without text clipping.
- Minimum 44x44pt touch targets for all button variants.
- Strict backward compatibility for existing callers of `.craftDialog(...)`.
- Zero test regressions across existing `CraftUIKit` test suite.

---

## File Structure & Responsibilities

| File Path | Action | Responsibility |
| :--- | :--- | :--- |
| `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift` | Modify | Implement `CraftDialogButtonLayout`, adaptive `ViewThatFits` button rendering, smart backdrop dismiss guardrails, haptics, title typography, and modal accessibility. |
| `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift` | Modify | Unit test suite verifying button layouts, backdrop dismissal rules, cancel callback execution, and custom badge coloring. |
| `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift` | Modify | Update showcase previews in the design catalog for all dialog variations. |

---

## Tasks

### Task 1: Add `CraftDialogButtonLayout` and Smart Backdrop Logic in `CraftDialogModifier`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift:1-30, 325-376`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift:540-670`

**Interfaces:**
- Produces:
  ```swift
  public enum CraftDialogButtonLayout: Sendable, CaseIterable {
      case automatic
      case horizontal
      case vertical
  }
  ```
- Modifies `CraftDialogModifier`:
  ```swift
  public struct CraftDialogModifier<DialogBody: View>: ViewModifier {
      @Environment(\.craftTheme) private var theme
      @Binding public var isPresented: Bool
      public let backdrop: CraftDialogBackdrop
      public let dismissOnBackdropTap: Bool
      public let onBackdropDismiss: (() -> Void)?
      public let dialogContent: DialogBody
  }
  ```

- [ ] **Step 1: Write failing unit test for `CraftDialogButtonLayout` and backdrop dismiss callback**

Add test methods in `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`:
```swift
func testDialogButtonLayoutEnumCases() {
    XCTAssertEqual(CraftDialogButtonLayout.allCases.count, 3)
    XCTAssertTrue(CraftDialogButtonLayout.allCases.contains(.automatic))
    XCTAssertTrue(CraftDialogButtonLayout.allCases.contains(.horizontal))
    XCTAssertTrue(CraftDialogButtonLayout.allCases.contains(.vertical))
}

func testDialogModifierSmartBackdropTapCallback() {
    var isPresented = true
    var cancelled = false

    let modifier = CraftDialogModifier(
        isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
        backdrop: .dimmed,
        dismissOnBackdropTap: true,
        onBackdropDismiss: { cancelled = true }
    ) {
        Text("Dialog Body")
    }

    XCTAssertTrue(modifier.dismissOnBackdropTap)
    XCTAssertNotNil(modifier.onBackdropDismiss)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ContainerOverlayTests`
Expected: FAIL with "cannot find type 'CraftDialogButtonLayout' in scope"

- [ ] **Step 3: Implement `CraftDialogButtonLayout` and update `CraftDialogModifier`**

In `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift`:
1. Define `CraftDialogButtonLayout`.
2. Update `CraftDialogModifier` to support `dismissOnBackdropTap: Bool = true` and `onBackdropDismiss: (() -> Void)? = nil`.
3. In `CraftDialogModifier.body`, when backdrop tap gesture is triggered:
   ```swift
   .onTapGesture {
       guard dismissOnBackdropTap else { return }
       onBackdropDismiss?()
       withAnimation(theme.animations.springSmooth) {
           isPresented = false
       }
   }
   ```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ContainerOverlayTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift
git commit -m "feat(dialog): add CraftDialogButtonLayout and smart backdrop tap dismiss modifier"
```

---

### Task 2: Redesign `CraftDialog` with Adaptive Layout, Typography, and Accessibility

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift:15-268`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift:540-670`

**Interfaces:**
- Produces:
  - `CraftDialog.init(title:message:iconName:iconColor:primaryButtonTitle:primaryButtonVariant:primaryAction:cancelButtonTitle:cancelButtonVariant:cancelAction:style:buttonLayout:customContent:)`
  - `CraftDialog.init(titleKey:messageKey:iconName:iconColor:primaryButtonTitleKey:primaryButtonVariant:primaryAction:cancelButtonTitleKey:cancelButtonVariant:cancelAction:style:buttonLayout:customContent:)`
  - Adaptive button layout using `ViewThatFits`.
  - Title typography: `.title3.bold()`.
  - Haptic feedback and SF Symbol bounce effect.

- [ ] **Step 1: Write failing unit test for `CraftDialog` new properties, buttonLayout, and iconColor**

In `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`:
```swift
func testDialogButtonLayoutAndCustomIconColor() {
    let dialog = CraftDialog(
        title: "Test Layout",
        message: "Message",
        iconName: "bell.fill",
        iconColor: .orange,
        primaryButtonTitle: "Confirm",
        primaryButtonVariant: .primary,
        primaryAction: {},
        cancelButtonTitle: "Cancel",
        cancelAction: {},
        style: .elevated,
        buttonLayout: .horizontal
    )

    XCTAssertEqual(dialog.buttonLayout, .horizontal)
    XCTAssertEqual(dialog.iconColor, .orange)
    XCTAssertEqual(dialog.iconName, "bell.fill")
    XCTAssertNotNil(dialog.body)
}

func testDialogVerticalButtonLayout() {
    let dialog = CraftDialog(
        title: "Vertical Layout",
        primaryAction: {},
        buttonLayout: .vertical
    )

    XCTAssertEqual(dialog.buttonLayout, .vertical)
    XCTAssertNotNil(dialog.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ContainerOverlayTests`
Expected: FAIL with "extra argument 'iconColor' in call" or "extra argument 'buttonLayout' in call"

- [ ] **Step 3: Implement updated `CraftDialog` struct**

In `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift`:
1. Add `public let iconColor: Color?`, `public let cancelButtonVariant: CraftButtonVariant?`, and `public let buttonLayout: CraftDialogButtonLayout`.
2. Update Title rendering to use `.title3` with bold weight.
3. Add `@ViewBuilder private var dialogActions: some View` implementing:
   - When `.horizontal`: `HStack` with Cancel (`.outline`) and Primary (`primaryButtonVariant`).
   - When `.vertical`: `VStack` with Primary (`primaryButtonVariant`) and Cancel (`.ghost`).
   - When `.automatic`: `ViewThatFits(in: .horizontal)` checking `horizontalActions` then falling back to `verticalActions`.
4. Wrap dialog content with accessibility attributes: `.accessibilityElement(children: .contain)` and `.accessibilityAddTraits(.isModal)`.
5. Add sensory feedback for `.danger` dialogs.
6. Provide default arguments for backward compatibility.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ContainerOverlayTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift
git commit -m "feat(dialog): implement adaptive button layout, title3 typography, and a11y traits in CraftDialog"
```

---

### Task 3: Update View Extensions & Backdrop Dismissal Resolution

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift:378-472`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift:620-670`

**Interfaces:**
- Produces:
  - `View.craftDialog(isPresented:title:message:iconName:iconColor:primaryButtonTitle:primaryButtonVariant:primaryAction:cancelButtonTitle:cancelButtonVariant:cancelAction:style:backdrop:buttonLayout:dismissOnBackdropTap:)`
  - `View.craftDialog(isPresented:titleKey:messageKey:iconName:iconColor:primaryButtonTitleKey:primaryButtonVariant:primaryAction:cancelButtonTitleKey:cancelButtonVariant:cancelAction:style:backdrop:buttonLayout:dismissOnBackdropTap:)`
  - `View.craftDialog(isPresented:backdrop:dismissOnBackdropTap:onBackdropDismiss:content:)`

- [ ] **Step 1: Write unit tests for updated View extensions with dismissOnBackdropTap and buttonLayout**

In `CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift`:
```swift
func testDialogModifierWithCustomButtonLayoutAndBackdropTap() {
    var isPresented = true
    var cancelled = false
    let view = Text("Host View")
        .craftDialog(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            title: "Danger Zone",
            message: "Permanent action",
            iconName: "exclamationmark.triangle.fill",
            iconColor: .red,
            primaryButtonTitle: "Delete",
            primaryButtonVariant: .danger,
            primaryAction: {},
            cancelButtonTitle: "Cancel",
            cancelAction: { cancelled = true },
            style: .elevated,
            backdrop: .dimmed,
            buttonLayout: .horizontal,
            dismissOnBackdropTap: false
        )
    XCTAssertNotNil(view)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ContainerOverlayTests`
Expected: FAIL with "extra argument 'buttonLayout' in call" or "extra argument 'dismissOnBackdropTap' in call"

- [ ] **Step 3: Update View extensions in `CraftDialog.swift`**

Implement the updated `View.craftDialog(...)` extensions with parameter defaults:
- `buttonLayout: CraftDialogButtonLayout = .automatic`
- `dismissOnBackdropTap: Bool? = nil`
- `iconColor: Color? = nil`
- Calculate `resolvedDismissOnBackdropTap = dismissOnBackdropTap ?? (primaryButtonVariant != .danger)`.
- Pass `onBackdropDismiss: cancelAction` to `CraftDialogModifier` so cancel logic fires automatically when tapping backdrop.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ContainerOverlayTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift CraftUIKit/Tests/CraftUIKitTests/ContainerOverlayTests.swift
git commit -m "feat(dialog): update View.craftDialog extensions with smart backdrop dismiss and buttonLayout"
```

---

### Task 4: Update Showcase Catalog & Verify Full Test Suite

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift:473-510`
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: All unit tests (`swift test`)

- [ ] **Step 1: Update Previews in `CraftDialog.swift` and `CraftCatalogView.swift`**

Update `#Preview("CraftDialog")` to include:
1. Standard Confirmation (`.automatic` HStack layout).
2. Destructive Dialog (`.danger`, locked backdrop, warning haptic).
3. Informational Dialog (custom `iconColor: .blue`, single button).
4. Liquid Glass Dialog (`style: .glass`, `backdrop: .material`).

- [ ] **Step 2: Run full test suite across CraftUIKit**

Run: `swift test`
Expected: All 417+ tests PASS with 0 failures and 0 warnings.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Overlays/CraftDialog.swift CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "test(dialog): update CraftDialog previews and verify complete test suite"
```
