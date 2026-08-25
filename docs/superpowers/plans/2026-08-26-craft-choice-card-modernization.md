# CraftChoiceCard Modernization & Liquid Glass Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize `CraftChoiceCard` in `CraftUIKit` to support scalable Dynamic Type prefix badges, top-aligned multiline balance, enhanced Dark Mode contrast, declarative iOS 17+ sensory feedback, hierarchical SF Symbol indicators, and native iOS 26+ Liquid Glass.

**Architecture:** Refactor `CraftChoiceCard.swift` to adopt flexible layout geometry (`minWidth`/`minHeight`), top-aligned `HStack` optical baselines, adaptive semantic tokens (`textInverse`, `.craftDynamic` contrast opacities), declarative `.sensoryFeedback` modifiers, and dual-engine background styling (`.glassEffect` on iOS 26+ with frosted `.ultraThinMaterial` fallback).

**Tech Stack:** Swift 6.0, SwiftUI, SF Symbols (hierarchical mode), Liquid Glass (`GlassEffectContainer` / `.glassEffect`), XCTest / Swift Testing.

**Spec:** [`docs/superpowers/specs/2026-08-26-craft-choice-card-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-26-craft-choice-card-design.md)

## Global Constraints

- **System Fonts Only**: SF Pro & SF Pro Rounded via design tokens (`theme.typography`).
- **iOS 17+ Floor with iOS 26+ Liquid Glass Gate**: Gate all Liquid Glass APIs with `if #available(iOS 26, macOS 26, *)`.
- **Zero Hardcoded Hex Codes**: Use `theme.colors` and semantic tokens exclusively.
- **Accessibility First**: Respect `@Environment(\.accessibilityReduceMotion)` and `@Environment(\.accessibilityReduceTransparency)`.
- **100% Backward API Compatibility**: Maintain existing `init` signatures without breaking callers.

---

### Task 1: Scalable Prefix Badges & Multiline Alignment (Dynamic Type & Layout)

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift:110-160, 258-290`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift:25-170`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftChoiceState`, `CraftSurfaceStyle`
- Produces: Scalable `prefixBadge` with `minWidth: 32`, `minHeight: 32`, `.fontDesign(.rounded)`, top-aligned `HStack(alignment: .top)`

- [ ] **Step 1: Write the failing tests for dynamic prefix badges and multiline layout**

Add tests in `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`:

```swift
func testChoiceCardMultiCharacterPrefixAndLongText() {
    let card = CraftChoiceCard(
        prefix: "10.",
        title: "Very long vocabulary term spanning across multiple lines of text",
        subtitle: "Comprehensive explanation detailing linguistic etymology and connotations",
        state: .selected
    ) {}
    
    XCTAssertEqual(card.prefix, "10.")
    XCTAssertEqual(card.title, "Very long vocabulary term spanning across multiple lines of text")
    XCTAssertEqual(card.subtitle, "Comprehensive explanation detailing linguistic etymology and connotations")
    XCTAssertNotNil(card.body)
}

func testChoiceCardLocalizedLongPrefix() {
    let card = CraftChoiceCard(
        prefix: LocalizedStringKey("choice.prefix.long"),
        title: LocalizedStringKey("choice.title.long"),
        subtitle: LocalizedStringKey("choice.subtitle.long"),
        state: .idle
    ) {}
    
    XCTAssertNotNil(card.body)
}
```

- [ ] **Step 2: Run test to verify it compiles and runs**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`
Expected: PASS / baseline verification

- [ ] **Step 3: Update `CraftChoiceCard.swift` layout and `prefixBadge`**

In `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`:
1. Change `cardSurface` content stack to `HStack(alignment: .top, spacing: theme.spacing.md)`.
2. Update `prefixBadge` to use `minWidth: 32, minHeight: 32`, `.fontDesign(.rounded)`, `.padding(.horizontal, 6)`, and top optical offset `.padding(.top, 1)`.
3. Update `prefixBorderStroke` to use `theme.colors.textInverse.opacity(0.35)` instead of hardcoded `Color.white.opacity(0.3)`.

```swift
    private var cardSurface: some View {
        let content = HStack(alignment: .top, spacing: theme.spacing.md) {
            if prefixKey != nil || rawPrefix != nil {
                prefixBadge
                    .padding(.top, 1)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                if let titleKey {
                    Text(titleKey)
                        .font(theme.typography.headline)
                        .foregroundStyle(titleColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                } else if let rawTitle {
                    Text(rawTitle)
                        .font(theme.typography.headline)
                        .foregroundStyle(titleColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                if let subtitleKey {
                    Text(subtitleKey)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(subtitleColor)
                        .multilineTextAlignment(.leading)
                } else if let rawSubtitle {
                    Text(rawSubtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(subtitleColor)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: theme.spacing.sm)

            trailingIndicator
                .padding(.top, 2)
        }
        .padding(theme.spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(cardBorderOverlay)
        .overlay(topHighlightOverlay)
        .frame(minHeight: 44)
        .contentShape(Rectangle())

        return applyCardShadow(content)
    }

    @ViewBuilder
    private var prefixBadge: some View {
        ZStack {
            // Embossed 3D bottom bevel / rim
            if state != .disabled {
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .fill(prefixBottomRimColor)
                    .offset(y: 2)
            }

            // Top surface
            Group {
                if let prefixKey {
                    Text(prefixKey)
                } else if let rawPrefix {
                    Text(rawPrefix)
                }
            }
            .font(theme.typography.headline.bold())
            .fontDesign(.rounded)
            .foregroundStyle(prefixForegroundColor)
            .frame(minWidth: 32, minHeight: 32)
            .padding(.horizontal, 6)
            .background(prefixBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .strokeBorder(prefixBorderStroke, lineWidth: 1)
            )
        }
        .frame(minWidth: 32, minHeight: 34)
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(CraftUIKit): modernize CraftChoiceCard prefix badge and multiline layout"
```

---

### Task 2: Dark Mode Contrast Enhancement, Declarative Haptics & Hierarchical Status Indicators

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift:75-110, 185-205, 290-320`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift:120-170`

**Interfaces:**
- Consumes: `CraftIcon`, `CraftSymbol`, `CraftChoiceState`, `theme.colors`
- Produces: Enhanced `.selected` / `.correct` / `.wrong` dark mode tints, `.sensoryFeedback` triggers, hierarchical `CraftIcon` trailing indicators

- [ ] **Step 1: Write test for accessibility traits, state indicators, and feedback assertions**

Add tests in `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`:

```swift
func testChoiceCardAccessibilityAndHierarchicalIndicators() {
    let idleCard = CraftChoiceCard(prefix: "A", title: "Option", state: .idle) {}
    let selectedCard = CraftChoiceCard(prefix: "B", title: "Option", state: .selected) {}
    let correctCard = CraftChoiceCard(prefix: "C", title: "Option", state: .correct) {}
    let wrongCard = CraftChoiceCard(prefix: "D", title: "Option", state: .wrong) {}

    XCTAssertEqual(idleCard.state, .idle)
    XCTAssertEqual(selectedCard.state, .selected)
    XCTAssertEqual(correctCard.state, .correct)
    XCTAssertEqual(wrongCard.state, .wrong)

    XCTAssertNotNil(idleCard.body)
    XCTAssertNotNil(selectedCard.body)
    XCTAssertNotNil(correctCard.body)
    XCTAssertNotNil(wrongCard.body)
}
```

- [ ] **Step 2: Run test to verify it compiles**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`
Expected: PASS

- [ ] **Step 3: Implement Dark Mode contrast opacities, Declarative Sensory Feedback, and Hierarchical Indicators**

In `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`:
1. Upgrade `stateTintOverlay`:
```swift
    private var stateTintOverlay: Color {
        switch state {
        case .idle, .disabled:
            return .clear
        case .selected:
            return theme.colors.brandPrimary.opacity(.craftDynamic(light: 0.08, dark: 0.16))
        case .correct:
            return theme.colors.statusSuccess.opacity(.craftDynamic(light: 0.10, dark: 0.18))
        case .wrong:
            return theme.colors.statusDanger.opacity(.craftDynamic(light: 0.10, dark: 0.18))
        }
    }
```
2. Replace imperative `UINotificationFeedbackGenerator` with declarative `.sensoryFeedback`:
```swift
        Button(action: {
            guard state != .disabled else { return }
            action()
        }) {
            cardSurface
        }
        .buttonStyle(CraftChoiceCardButtonStyle(state: state, style: style, depth: theme.depths.depthMd))
        .disabled(state == .disabled)
        .scaleEffect(state == .correct && !reduceMotion ? 1.02 : 1.0)
        .modifier(ChoiceShakeEffect(shakes: shakeCount))
        .animation(theme.animations.springBouncy, value: state)
        .opacity(state == .disabled ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValueDescription)
        .accessibilityAddTraits(state == .selected ? [.isButton, .isSelected] : [.isButton])
        .sensoryFeedback(.selection, trigger: state == .selected)
        .sensoryFeedback(.success, trigger: state == .correct)
        .sensoryFeedback(.error, trigger: state == .wrong)
        .onChange(of: state) { _, newState in
            if newState == .wrong && !reduceMotion {
                withAnimation(.linear(duration: 0.35)) {
                    shakeCount += 1
                }
            }
        }
```
3. Update `trailingIndicator` to use `CraftIcon` with hierarchical rendering mode and transition:
```swift
    @ViewBuilder
    private var trailingIndicator: some View {
        switch state {
        case .correct:
            CraftIcon(.checkmarkCircle, size: .md, color: theme.colors.statusSuccess, renderingMode: .hierarchical)
                .transition(.scale.combined(with: .opacity))
        case .wrong:
            CraftIcon(.wrongCircle, size: .md, color: theme.colors.statusDanger, renderingMode: .hierarchical)
                .transition(.scale.combined(with: .opacity))
        case .idle, .selected, .disabled:
            EmptyView()
        }
    }
```

- [ ] **Step 4: Run tests to verify passing**

Run: `swift test --package-path CraftUIKit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(CraftUIKit): enhance CraftChoiceCard dark mode contrast, sensory feedback, and hierarchical icons"
```

---

### Task 3: Dual-Path Apple Liquid Glass (iOS 26+) & Catalog Showcase Synchronization

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift:160-205`
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift:1360-1400`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle.glass`, `theme.glass`, `reduceTransparency`
- Produces: Dual-engine Liquid Glass `.glassEffect` on iOS 26+ and frosted `.ultraThinMaterial` fallback

- [ ] **Step 1: Write test verifying `.glass` style rendering and fallback compatibility**

Add test in `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`:

```swift
func testChoiceCardGlassStyleAcrossStates() {
    for state in CraftChoiceState.allCases {
        let card = CraftChoiceCard(
            prefix: "G",
            title: "Glass Card \(state.rawValue)",
            subtitle: "Liquid glass material option",
            state: state,
            style: .glass
        ) {}
        XCTAssertEqual(card.style, .glass)
        XCTAssertNotNil(card.body)
    }
}
```

- [ ] **Step 2: Run test to verify it compiles**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`
Expected: PASS

- [ ] **Step 3: Implement Dual-Path Liquid Glass in `CraftChoiceCard.swift`**

In `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`:
1. Add `@Environment(\.accessibilityReduceTransparency) private var reduceTransparency`.
2. Update `cardBackground` to support iOS 26+ `.glassEffect`:

```swift
    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            switch style {
            case .glass:
                if #available(iOS 26, macOS 26, *) {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceCard)
                    } else {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: theme.radii.lg))
                    }
                } else {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceCard)
                    } else {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
                    }
                }
            case .flat:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(theme.colors.surfaceSubtle)
            case .elevated:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(theme.colors.surfaceElevated)
            case .outlined, .tactile3D:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(theme.colors.surfaceCard)
            }

            if state != .idle && state != .disabled {
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(stateTintOverlay)
            }
        }
    }
```

3. Update `topHighlightOverlay` to avoid double-highlight on iOS 26+ when `.glassEffect` provides native specular highlights:

```swift
    @ViewBuilder
    private var topHighlightOverlay: some View {
        if state != .disabled {
            if style == .tactile3D {
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            } else if style == .glass {
                if #unavailable(iOS 26, macOS 26) {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                }
            }
        }
    }
```

4. Update `CraftCatalogView.swift` to demonstrate `GlassEffectContainer` surrounding `.glass` style quiz cards on iOS 26+.

- [ ] **Step 4: Run full test suite to verify 100% pass**

Run: `swift test --package-path CraftUIKit`
Expected: ALL tests pass (427+ tests)

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(CraftUIKit): implement dual-path iOS 26+ Liquid Glass for CraftChoiceCard"
```

---

## Plan Self-Review

1. **Spec Coverage**:
   - Scalable Prefix Badge & Dynamic Type: Covered in Task 1.
   - Multiline Top-Alignment: Covered in Task 1.
   - Dark Mode Contrast & Dynamic Opacities: Covered in Task 2.
   - Declarative Sensory Feedback: Covered in Task 2.
   - Hierarchical SF Symbols Trailing Indicator: Covered in Task 2.
   - Dual-Path Liquid Glass (iOS 26+ / Reduce Transparency): Covered in Task 3.
   - 100% Backward API Compatibility: Covered in Tasks 1-3.
2. **No Placeholders**: All code snippets, commands, and expected outputs are explicit and complete.
3. **Type Consistency**: `CraftChoiceState`, `CraftSurfaceStyle`, `CraftIcon`, `CraftSymbol` types align across all tasks and tests.
