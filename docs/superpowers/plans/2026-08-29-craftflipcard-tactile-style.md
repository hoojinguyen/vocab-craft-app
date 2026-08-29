# CraftFlipCard Style Architecture & Reflex Multi-Choice Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate `CraftFlipCard` in `CraftUIKit` to natively support container styling (`style: CraftCardStyle`, `.tactile3D`, `.elevated`, `.outlined`, `.glass`, `highlightShadowColor: Color?`), and refactor `ReflexBlitzMultipleChoiceCardView` into a pure declarative view tree with zero-shift 3D flipping, clean front/back badges, and refined tactile feedback.

**Architecture:** Natively encapsulate card surface geometry, 3D bottom lip extrusion, top highlight, corner radii, and optional perimeter shadow directly inside `CraftFlipCard` in `CraftUIKit`. In `VocabCraftApp`, remove all ad-hoc ZStacks and strokes, passing pure domain content into `CraftFlipCard` while stabilizing vertical rhythm and deleting `TODO.md`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Package Manager, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-29-craftflipcard-tactile-style-design.md`

## Global Constraints
- **Strict Theme & Token Conformance**: Zero hardcoded colors, fonts, or padding. Use `theme.colors`, `theme.radii`, `theme.spacing`, `theme.depths`, `theme.shadows`.
- **CraftUIKit-First Architecture**: All visual container mechanics belong in `CraftUIKit`. App-layer views must not construct manual extrusion ZStacks.
- **Zero Hardcoded Strings**: All text uses `CraftLocalized` (in `CraftUIKit`) or `AppStrings` / `LocalizedStringKey` (in app).
- **Zero Warnings Gate**: 0 SwiftLint violations, 0 compiler warnings, 100% test pass rate.

---

### Task 1: Elevate `CraftFlipCard` in `CraftUIKit` with First-Class Style & Shadow Highlight Architecture

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Cards/CraftFlipCard.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/Containers/CraftFlipCardTests.swift`

**Interfaces:**
- Consumes: `CraftCardStyle`, `CraftTheme`, `CraftDepthTokens`, `CraftSpecularGlareModifier`, `Craft3DFlipModifier`
- Produces: `CraftFlipCard<Front: View, Back: View>` with `init(isFlipped:style:axis:edgeThickness:showSpecularGlare:showsHighlightBorder:highlightShadowColor:isTapToFlipEnabled:cornerRadius:padding:customTint:customGradient:perspective:animation:front:back:)`

- [ ] **Step 1: Write unit tests for `CraftFlipCard` styling and initializers in `CraftUIKitTests`**

Create `Packages/CraftUIKit/Tests/CraftUIKitTests/Containers/CraftFlipCardTests.swift`:
```swift
import CraftUIKit
import SwiftUI
import XCTest

final class CraftFlipCardTests: XCTestCase {
    @MainActor
    func testCraftFlipCardInstantiationWithTactile3DStyle() {
        var isFlipped = false
        let binding = Binding<Bool>(get: { isFlipped }, set: { isFlipped = $0 })
        let card = CraftFlipCard(
            isFlipped: binding,
            style: .tactile3D,
            cornerRadius: 20,
            padding: 16
        ) {
            Text("Front Content")
        } back: {
            Text("Back Content")
        }

        XCTAssertNotNil(card)
        XCTAssertEqual(card.style, .tactile3D)
        XCTAssertEqual(card.cornerRadius, 20)
        XCTAssertEqual(card.padding, 16)
        XCTAssertNotNil(card.body)
    }

    @MainActor
    func testCraftFlipCardWithHighlightShadowColor() {
        let binding = Binding<Bool>.constant(true)
        let card = CraftFlipCard(
            isFlipped: binding,
            style: .tactile3D,
            highlightShadowColor: Color.green.opacity(0.3)
        ) {
            Text("Front")
        } back: {
            Text("Back")
        }

        XCTAssertNotNil(card)
        XCTAssertEqual(card.highlightShadowColor, Color.green.opacity(0.3))
        XCTAssertNotNil(card.body)
    }

    @MainActor
    func testCraftFlipCardAcrossAllSurfaceStyles() {
        for style in CraftCardStyle.allCases {
            let card = CraftFlipCard(
                isFlipped: .constant(false),
                style: style
            ) {
                Text("Front \(style.rawValue)")
            } back: {
                Text("Back \(style.rawValue)")
            }
            XCTAssertNotNil(card.body)
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftFlipCardTests` in `Packages/CraftUIKit`
Expected: FAIL (missing `style` / `highlightShadowColor` parameters on `CraftFlipCard`)

- [ ] **Step 3: Update `CraftFlipCard.swift` with first-class card surface architecture**

Modify `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Cards/CraftFlipCard.swift`:
1. Add properties: `public let style: CraftCardStyle`, `public let cornerRadius: CGFloat?`, `public let padding: CGFloat?`, `public let customTint: Color?`, `public let customGradient: LinearGradient?`, `public let highlightShadowColor: Color?`.
2. Implement private helper `cardFaceContainer(_:radius:contentPadding:depth:)` that encapsulates surface background, tactile 3D lip extrusion (`RoundedRectangle(cornerRadius: radius).fill(theme.colors.borderDefault).offset(y: depth)`), top highlight, stroke border, and optional `highlightShadowColor`.
3. Wrap `front` and `back` in `cardFaceContainer` inside `CraftFlipCard.body`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS (all 626+ tests pass with 0 failures)

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/
git commit -m "feat(craftuikit): elevate CraftFlipCard with first-class style and shadow highlight architecture"
```

---

### Task 2: Refactor `ReflexBlitzMultipleChoiceCardView` with Declarative `CraftFlipCard` & Refined Front/Back Layout

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzMultipleChoiceCardView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Consumes: `CraftFlipCard` (with `style: .tactile3D`, `highlightShadowColor`), `ReflexBlitzWordItem`, `ReflexBlitzOption`, `AppStrings.ReflexBlitz`
- Produces: Clean declarative `ReflexBlitzMultipleChoiceCardView` with zero manual ZStacks

- [ ] **Step 1: Write/update component tests in `ReflexBlitzComponentsTests.swift`**

Add unit test to `ReflexBlitzComponentsTests.swift`:
```swift
@MainActor
func testReflexBlitzMultipleChoiceCardViewUsesDeclarativeFlipCard() {
    let word = ReflexBlitzWordItem.defaultStarterWords[0]
    let options = word.generateOptions(mode: .multipleChoice, allPool: ReflexBlitzWordItem.defaultStarterWords)
    
    // Active Prompt State: front card has no CEFR badge
    let activeCard = ReflexBlitzMultipleChoiceCardView(
        word: word,
        options: options,
        isReviewed: false,
        isResultCorrect: false,
        isResultTimeout: false,
        showHint: false,
        selectedOptionText: nil,
        clozeParts: nil,
        displayedSentence: word.clozeSentenceEn,
        cardBorderColor: .clear,
        onSelectOption: nil,
        onReplayAudio: nil
    )
    XCTAssertNotNil(activeCard.body)
    
    // Reviewed State: back card has CEFR badge and audio replay
    let reviewedCard = ReflexBlitzMultipleChoiceCardView(
        word: word,
        options: options,
        isReviewed: true,
        isResultCorrect: true,
        isResultTimeout: false,
        showHint: false,
        selectedOptionText: "habit",
        clozeParts: nil,
        displayedSentence: word.completedSentenceWithTargetWord,
        cardBorderColor: .clear,
        onSelectOption: nil,
        onReplayAudio: {}
    )
    XCTAssertNotNil(reviewedCard.body)
}
```

- [ ] **Step 2: Refactor `ReflexBlitzMultipleChoiceCardView.swift`**

1. Replace `flipStimulusCard` body with:
```swift
@ViewBuilder
private var flipStimulusCard: some View {
    let statusGlow: Color? = isReviewed
        ? (isResultCorrect ? theme.colors.statusSuccess.opacity(0.2) : theme.colors.statusDanger.opacity(0.2))
        : nil

    CraftFlipCard(
        isFlipped: Binding(
            get: { isReviewed },
            set: { _ in }
        ),
        style: .tactile3D,
        axis: .horizontal,
        showSpecularGlare: true,
        showsHighlightBorder: false,
        highlightShadowColor: statusGlow,
        isTapToFlipEnabled: false,
        cornerRadius: theme.radii.xl,
        padding: theme.spacing.base,
        perspective: 0.5,
        animation: .spring(response: 0.45, dampingFraction: 0.78)
    ) {
        frontPromptFace
    } back: {
        backResultFace
    }
}
```
2. In `frontPromptFace`:
   - Remove manual `ZStack` and `offset(y: depth)` code.
   - Retain `VStack(spacing: theme.spacing.sm)` with `Spacer(minLength: 0)` top and bottom, `.frame(maxWidth: .infinity, minHeight: 195)`.
   - Remove `CraftBadge(word.cleanLevel)` from front (only keep `cleanPos` and `hintBadge`).
3. In `backResultFace`:
   - Remove manual `ZStack` and `offset(y: depth)` code.
   - Retain `VStack(alignment: .leading, spacing: theme.spacing.xs)` with `.frame(maxWidth: .infinity, minHeight: 195, alignment: .leading)`.
   - Retain `word.cleanPos` and `word.cleanLevel` badges.

- [ ] **Step 3: Run component tests to verify they pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:VocabCraftAppTests/ReflexBlitzComponentsTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzMultipleChoiceCardView.swift VocabCraftAppTests/
git commit -m "refactor(reflex): adopt native CraftFlipCard tactile styling and clean front/back card layouts"
```

---

### Task 3: Refine Choice Card State Styling, Vertical Rhythm, and Cleanup `TODO.md`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Delete: `TODO.md`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`

**Interfaces:**
- Consumes: `CraftChoiceCard`, `ReflexBlitzView`, `CraftFeedbackSheet`
- Produces: Polished full Multi-Choice experience with zero layout shift and clean repo state

- [ ] **Step 1: Ensure `CraftChoiceCard` tactile styling conforms to spec**

Verify:
- Clean card face in `.tactile3D` (subtle tint overlay `0.05` / `0.10`).
- Semantic highlight focused on the 3D bottom lip (`bottomLipColor`) and localized bottom shadow (`radius: 8, y: 4, opacity: 0.3`).
- Top highlight stroke preserved across all states.

- [ ] **Step 2: Ensure `ReflexBlitzView.swift` vertical rhythm & bottom clearance**

Verify:
- Top spacing between `ReflexBlitzHeaderView` and `ReflexBlitzCardView` uses `.padding(.top, theme.spacing.xs)` with no unbound stretching `Spacer()`.
- Bottom clearance is stabilized at `140pt` during Multiple Choice mode to guarantee 0px layout shift.

- [ ] **Step 3: Delete `TODO.md`**

Delete `TODO.md` as requested by user.

- [ ] **Step 4: Run full test suite & swiftlint**

1. Run: `swift test --package-path Packages/CraftUIKit`
2. Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17'`
3. Run: `swiftlint`
Expected: 100% tests pass, 0 lint warnings, 0 compiler warnings.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/ VocabCraftApp/ TODO.md
git commit -m "feat(reflex): polish tactile choice feedback, zero-shift rhythm, and remove temporary tracking"
```
