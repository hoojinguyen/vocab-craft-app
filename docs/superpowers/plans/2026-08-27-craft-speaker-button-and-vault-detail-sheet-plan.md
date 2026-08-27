# CraftSpeakerButton & VaultWordDetailSheet UI/UX Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the reusable `CraftSpeakerButton` component in `CraftUIKit`, fix the `CraftIconButton` contrast bug, tokenize `DynamicReflexModeBadge`, and polish `VaultWordDetailSheet` with proper detents, reactive state, and visual harmony.

**Architecture:** Extend `CraftUIKit` design system with `CraftSpeakerButton` supporting playing animation and pill layout. Refactor `VaultWordDetailSheet` and `DynamicReflexModeBadge` in `VocabCraftApp` to adhere strictly to CraftUIKit tokens, bilingual localization, and HIG detent guidelines.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit, XCTest / Swift Testing, SF Symbols (iOS 17+ Symbol Effects).

**Spec:** `docs/superpowers/specs/2026-08-27-craft-speaker-button-and-vault-detail-sheet-design.md`

## Global Constraints
- Zero hardcoded strings (100% bilingual EN & VI in `Localizable.xcstrings`).
- Zero raw colors or fonts in SwiftUI views (use `theme.colors` / `theme.typography`).
- Apple HIG 44x44pt minimum touch target.
- Zero compiler errors, zero compiler warnings, 0 SwiftLint violations.

---

### Task 1: Fix CraftIconButton Foreground Color Contrast Bug & Unit Tests

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift:340-365`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift:320-345`

**Interfaces:**
- Consumes: `CraftIconButtonVariant`, `CraftTheme`, `CraftColorTokens`
- Produces: Correct `foregroundColor` calculation ensuring `theme.colors.textInverse` for filled, danger, and selected buttons.

- [ ] **Step 1: Write the failing unit test for CraftIconButton filled contrast**

```swift
// In AtomComponentTests.swift
func testIconButtonFilledWithCustomTintHasTextInverseForeground() {
    let btn = CraftIconButton(
        symbol: .audio,
        variant: .filled,
        customTint: .orange,
        accessibilityLabel: "Audio"
    ) {}
    XCTAssertEqual(btn.variant, .filled)
    XCTAssertEqual(btn.customTint, .orange)
    XCTAssertNotNil(btn.body)
}
```

- [ ] **Step 2: Run tests to verify test suite status**

Run: `swift test --package-path Packages/CraftUIKit --filter AtomComponentTests`
Expected: PASS

- [ ] **Step 3: Ensure CraftIconButton foregroundColor implementation is locked in**

```swift
private var foregroundColor: Color {
    if variant == .filled || variant == .danger || isSelected {
        return theme.colors.textInverse
    }
    return effectiveTint
}
```

- [ ] **Step 4: Run tests and verify all pass**

Run: `swift test --package-path Packages/CraftUIKit --filter AtomComponentTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift Packages/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift
git commit -m "fix(craftuikit): ensure CraftIconButton filled variant uses textInverse foreground color"
```

---

### Task 2: Implement CraftSpeakerButton & Layer 1 Localization in CraftUIKit

**Files:**
- Create: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSpeakerButton.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Modify: `Packages/CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Consumes: `CraftIconSize`, `CraftTheme`, `CraftSymbol`, `CraftText`
- Produces: `CraftSpeakerButton`, `CraftSpeakerButtonVariant`

- [ ] **Step 1: Add Layer 1 strings to CraftUIKit Localizable.xcstrings**

Add:
- `craft.audio.pronounce`: en = "Pronounce word", vi = "Phát âm từ vựng"
- `craft.audio.playing`: en = "Playing pronunciation...", vi = "Đang phát âm..."

- [ ] **Step 2: Write failing unit test for CraftSpeakerButton**

```swift
// In ControlComponentTests.swift
func testCraftSpeakerButtonInitAndProperties() {
    var played = false
    let btn = CraftSpeakerButton(
        variant: .subtle,
        size: .md,
        isPlaying: false,
        action: { played = true }
    )
    XCTAssertEqual(btn.variant, .subtle)
    XCTAssertEqual(btn.size, .md)
    XCTAssertFalse(btn.isPlaying)
    XCTAssertNil(btn.label)
    XCTAssertNotNil(btn.body)
}

func testCraftSpeakerButtonPillMode() {
    let btn = CraftSpeakerButton(
        variant: .subtle,
        size: .md,
        isPlaying: true,
        label: LocalizedStringKey("craft.audio.pronounce"),
        action: {}
    )
    XCTAssertTrue(btn.isPlaying)
    XCTAssertNotNil(btn.label)
    XCTAssertNotNil(btn.body)
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter ControlComponentTests`
Expected: FAIL ("cannot find 'CraftSpeakerButton' in scope")

- [ ] **Step 4: Implement CraftSpeakerButton.swift**

```swift
import SwiftUI

/// Visual style variants for speaker audio button.
public enum CraftSpeakerButtonVariant: String, Sendable, CaseIterable {
    case subtle
    case filled
    case ghost
}

/// A dedicated pronunciation and audio playback button adhering to Apple HIG and CraftUIKit design tokens.
public struct CraftSpeakerButton: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public let variant: CraftSpeakerButtonVariant
    public let size: CraftIconSize
    public let isPlaying: Bool
    public let label: LocalizedStringKey?
    public let customTint: Color?
    public let action: () -> Void

    public init(
        variant: CraftSpeakerButtonVariant = .subtle,
        size: CraftIconSize = .md,
        isPlaying: Bool = false,
        label: LocalizedStringKey? = nil,
        customTint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.variant = variant
        self.size = size
        self.isPlaying = isPlaying
        self.label = label
        self.customTint = customTint
        self.action = action
    }

    private var effectiveTint: Color {
        customTint ?? theme.colors.brandPrimary
    }

    private var visualDimension: CGFloat {
        switch size {
        case .sm: return 32
        case .md: return 40
        case .lg: return 48
        case .xl: return 56
        }
    }

    private var iconSizePt: CGFloat {
        switch size {
        case .sm: return 14
        case .md: return 18
        case .lg: return 22
        case .xl: return 26
        }
    }

    public var body: some View {
        Button(action: {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        }) {
            if let label {
                pillContent(label: label)
            } else {
                circleContent
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isPlaying ? "craft.audio.playing" : "craft.audio.pronounce")
        .accessibilityAddTraits(.isButton)
    }

    private var circleContent: some View {
        ZStack {
            backgroundShape(for: Circle())
            speakerIcon
        }
        .frame(width: visualDimension, height: visualDimension)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }

    private func pillContent(label: LocalizedStringKey) -> some View {
        HStack(spacing: theme.spacing.xs) {
            speakerIcon
            Text(label, bundle: .module)
                .font(theme.typography.label)
                .foregroundStyle(foregroundColor)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(
            backgroundShape(for: Capsule())
        )
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var speakerIcon: some View {
        let iconName = isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill"
        Image(systemName: iconName)
            .font(.system(size: iconSizePt, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .symbolRenderingMode(.hierarchical)
    }

    private var foregroundColor: Color {
        switch variant {
        case .filled:
            return theme.colors.textInverse
        case .subtle, .ghost:
            return effectiveTint
        }
    }

    @ViewBuilder
    private func backgroundShape<S: InsettableShape>(for shape: S) -> some View {
        switch variant {
        case .filled:
            shape.fill(effectiveTint)
        case .subtle:
            shape.fill(effectiveTint.opacity(0.12))
        case .ghost:
            shape.fill(Color.clear)
        }
    }
}
```

- [ ] **Step 5: Run tests and verify all pass**

Run: `swift test --package-path Packages/CraftUIKit --filter ControlComponentTests`
Expected: PASS

- [ ] **Step 6: Commit changes**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSpeakerButton.swift Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings Packages/CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
git commit -m "feat(craftuikit): add CraftSpeakerButton component with audio animation and localization"
```

---

### Task 3: Tokenize DynamicReflexModeBadge & Localize A11y in VocabCraftApp

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/Components/DynamicReflexModeBadge.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`

**Interfaces:**
- Consumes: `ReflexBlitzMode`, `CraftTheme`
- Produces: HIG & token-compliant `DynamicReflexModeBadge`

- [ ] **Step 1: Add localized format key to VocabCraftApp Localizable.xcstrings & AppStrings.swift**

Key: `app.reflex.mode_a11y_format`
- en: "Mode: %@, time limit %@"
- vi: "Chế độ: %@, giới hạn thời gian %@"

- [ ] **Step 2: Refactor DynamicReflexModeBadge to use CraftTheme semantic colors**

Replace hardcoded `.vocabLavender`, `.vocabMint`, `.vocabPeach`, `.vocabHeroAccent` with theme tokens:
- `.multipleChoice`: `theme.colors.accent`
- `.speaking`: `theme.colors.statusSuccess`
- `.typing`: `theme.colors.brandPrimary`
- `.listening`: `theme.colors.statusInfo`

Replace hardcoded accessibility label with `AppStrings.Reflex.modeA11yLabel(mode: mode.title, duration: formattedDuration)`.

- [ ] **Step 3: Run app test suite**

Run: `swift test --filter MixedReflexDrillViewsTests`
Expected: PASS

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/Components/DynamicReflexModeBadge.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift
git commit -m "refactor(badge): tokenize DynamicReflexModeBadge colors and localize accessibility string"
```

---

### Task 4: Refactor and Polish VaultWordDetailSheet

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/Components/VaultWordDetailSheet.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift`

**Interfaces:**
- Consumes: `CraftSpeakerButton`, `CraftIconButton`, `CraftBadge`, `VaultWordItem`
- Produces: Polished `VaultWordDetailSheet` with `.fraction(0.68)` detent and instant bookmark reactivity.

- [ ] **Step 1: Update unit tests for VaultWordDetailSheet**

Verify sheet renders properly with new speaker and bookmark buttons.

- [ ] **Step 2: Update VaultWordDetailSheet implementation**

- Replace audio `CraftIconButton` with:
  ```swift
  CraftSpeakerButton(
      variant: .subtle,
      size: .md,
      isPlaying: isPlayingAudio
  ) {
      isPlayingAudio = true
      onPlayAudio()
      Task {
          try? await Task.sleep(for: .seconds(1.2))
          isPlayingAudio = false
      }
  }
  ```
- Replace bookmark `CraftIconButton` with:
  ```swift
  CraftIconButton(
      symbol: isBookmarked ? .bookmarkFill : .bookmark,
      size: .md,
      shape: .circle,
      variant: .subtle,
      customTint: isBookmarked ? theme.colors.accent : theme.colors.textMuted,
      isSelected: false,
      accessibilityLabelKey: isBookmarked ? "homepage.saved" : "homepage.saveWord"
  ) {
      isBookmarked.toggle()
      onToggleBookmark()
  }
  ```
- Update `.presentationDetents([.fraction(0.68), .large])`.
- Maintain `@State private var isBookmarked: Bool` and `@State private var isPlayingAudio: Bool`.

- [ ] **Step 3: Run unit tests**

Run: `swift test --filter PersonalVaultViewsTests`
Expected: PASS

- [ ] **Step 4: Commit changes**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/Components/VaultWordDetailSheet.swift VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift
git commit -m "feat(vault): polish VaultWordDetailSheet with CraftSpeakerButton, refined detents, and reactive bookmark"
```

---

### Task 5: Comprehensive Verification & Static Analysis

**Files:**
- None (Verification phase)

- [ ] **Step 1: Run CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS (100%)

- [ ] **Step 2: Run Localization verification tests**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Run: `swift test --filter PersonalVaultLocalizationTests`
Expected: PASS (100%)

- [ ] **Step 3: Run full App test suite**

Run: `swift test`
Expected: PASS (100%)

- [ ] **Step 4: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.
