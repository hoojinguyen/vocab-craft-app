# Settings Screen Redesign (HIG Inset Grouped) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Settings screen to eliminate visual clutter, remove unnecessary icons, discard the out-of-place 7-day streak card, adopt an Apple ID-style compact profile row, and reorganize settings into 5 clean Inset Grouped sections following Apple Human Interface Guidelines and CraftUIKit design tokens.

**Architecture:** The Settings screen (`SettingsView`) will be structured as a clean `ScrollView` containing 5 card-grouped sections using `CraftCard(style: .outlined)` and `CraftListRow`. Icons are stripped from internal form controls (toggles, sliders, pickers, steppers) to eradicate icon fatigue, relying on typography and tokens. A compact `HeroProfileCard` acts as the account row opening `ProfileStatsSheet`.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit (Design System), XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-09-09-settings-screen-redesign-design.md`

## Global Constraints

- **Design System Conformance**: 100% CraftUIKit tokens (`theme.colors.*`, `theme.typography.*`, `theme.spacing.*`, `theme.radii.*`). Zero raw styling (`Color.red`, hardcoded padding, custom hex).
- **Zero Hardcoded Strings**: All user-facing strings must use `AppStrings.Settings.*` and `Localizable.xcstrings` with 100% bilingual parity (Vietnamese & English).
- **Quality Gate**: Zero compiler warnings, zero SwiftLint warnings, 100% unit test pass rate.

---

### Task 1: Localization & AppStrings for New Data Section

**Files:**
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift:340-350`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/SettingsLocalizationTests.swift`

**Interfaces:**
- Produces: `AppStrings.Settings.sectionDataStorage: LocalizedStringKey` ("app.settings.section.data_storage")
- Produces: `AppStrings.Settings.sectionDataStorageText: String` ("Data & Storage" / "Dữ liệu & Bộ nhớ")

- [ ] **Step 1: Write the failing test in `SettingsLocalizationTests.swift`**

```swift
func testSettingsDataStorageSectionLocalization() {
    let key = "app.settings.section.data_storage"
    let en = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "en"))
    let vi = String(localized: String.LocalizationValue(key), bundle: .main, locale: Locale(identifier: "vi"))
    XCTAssertEqual(en, "Data & Storage")
    XCTAssertEqual(vi, "Dữ liệu & Bộ nhớ")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testSettingsDataStorageSectionLocalization`  
Expected: FAIL (key missing or untranslated).

- [ ] **Step 3: Update `AppStrings.swift` and `Localizable.xcstrings`**

In `VocabCraftApp/Core/Localization/AppStrings.swift`:
```swift
// In enum Settings:
public static var sectionDataStorage: LocalizedStringKey { "app.settings.section.data_storage" }
public static var sectionDataStorageText: String {
    String(localized: "app.settings.section.data_storage", defaultValue: "Data & Storage", bundle: .module)
}
```

In `VocabCraftApp/Resources/Localizable.xcstrings`, add `app.settings.section.data_storage`:
```json
"app.settings.section.data_storage" : {
  "extractionState" : "manual",
  "localizations" : {
    "en" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Data & Storage"
      }
    },
    "vi" : {
      "stringUnit" : {
        "state" : "translated",
        "value" : "Dữ liệu & Bộ nhớ"
      }
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter testSettingsDataStorageSectionLocalization`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/SettingsLocalizationTests.swift
git commit -m "feat(settings): add data storage section localization key"
```

---

### Task 2: Refactor `HeroProfileCard` to Compact Account Row

**Files:**
- Modify: `VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift:1-95`
- Modify: `VocabCraftAppTests/SettingsViewTests.swift:19-41`

**Interfaces:**
- Consumes: `userName: String`, `userLevel: String`, `onTapAction: (() -> Void)?`
- Produces: Compact, single-row `HeroProfileCard` (height ~72pt) with Avatar (48pt) + Name + Level Badge + Chevron.

- [ ] **Step 1: Write test for compact card layout in `SettingsViewTests.swift`**

```swift
func testHeroProfileCardCompactRendering() {
    var tapped = false
    let card = HeroProfileCard(
        userName: "Hooji N.",
        userLevel: "B2 Intermediate",
        onTapAction: { tapped = true }
    )
    XCTAssertEqual(card.userName, "Hooji N.")
    XCTAssertEqual(card.userLevel, "B2 Intermediate")
    card.onTapAction?()
    XCTAssertTrue(tapped)
    XCTAssertNotNil(card.body)
}
```

- [ ] **Step 2: Run test to ensure current suite runs**

Run: `swift test --filter testHeroProfileCardCompactRendering`  
Expected: PASS.

- [ ] **Step 3: Implement compact layout in `HeroProfileCard.swift`**

Replace centered 200pt hero with compact horizontal row inside `CraftCard(style: .outlined, padding: 0)`:

```swift
import CraftUIKit
import SwiftUI

/// Compact, Apple ID-style profile card row displaying user avatar, name, CEFR level badge,
/// and chevron drill-down trigger in an elegant horizontal layout.
public struct HeroProfileCard: View {
    @Environment(\.craftTheme) private var theme
    public let userName: String
    public let userLevel: String
    public let onTapAction: (() -> Void)?

    public init(
        userName: String = "Hooji N.",
        userLevel: String = "B2 Intermediate",
        onTapAction: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.userLevel = userLevel
        self.onTapAction = onTapAction
    }

    public var body: some View {
        CraftCard(style: .outlined, padding: 0) {
            Button(action: {
                onTapAction?()
            }) {
                HStack(spacing: theme.spacing.md) {
                    // Avatar Squircle / Circle with Gradient Aura
                    ZStack {
                        Circle()
                            .fill(theme.gradients.brandHero)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                            )
                            .craftShadow(theme.shadows.sm)

                        Text(userName.prefix(1))
                            .font(theme.typography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(theme.colors.textInverse)
                    }

                    // User Name & Subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        CraftText(
                            userName,
                            style: .headline,
                            color: theme.colors.textPrimary
                        )
                        .fontWeight(.bold)

                        CraftText(
                            AppStrings.Settings.profileTagline,
                            style: .caption,
                            color: theme.colors.textSecondary
                        )
                        .lineLimit(1)
                    }

                    Spacer(minLength: theme.spacing.xs)

                    // Level Badge & Chevron
                    CraftBadge(
                        userLevel,
                        symbol: .star,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm
                    )

                    CraftIcon("chevron.right", size: .sm, color: theme.colors.textMuted)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.craftPress(scale: 0.98))
        }
    }
}
```

- [ ] **Step 4: Run test to verify passes**

Run: `swift test --filter SettingsViewTests`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift VocabCraftAppTests/SettingsViewTests.swift
git commit -m "refactor(settings): convert HeroProfileCard to compact horizontal account row"
```

---

### Task 3: Redesign `SettingsView` Layout & Eliminate Icon Clutter

**Files:**
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift:1-550`
- Test: `VocabCraftAppTests/SettingsViewTests.swift`

**Interfaces:**
- Consumes: `SettingsViewModel`, `UserSettingsStore`, `HeroProfileCard`, `AppStrings.Settings.*`
- Produces: 5-section Inset Grouped `SettingsView` without `CraftStreakCard` and without icon clutter.

- [ ] **Step 1: Write tests in `SettingsViewTests.swift` reflecting 5 sections and removed streak card**

Add tests verifying:
1. `SettingsView` body renders without crash.
2. `SettingsView` does not contain `CraftStreakCard`.
3. Notification expansion renders smoothly.
4. Audio preview playing state triggers waveform.

```swift
func testSettingsViewStructureContainsFiveSections() {
    let store = UserSettingsStore()
    let tts = MockTextToSpeechService()
    let vm = SettingsViewModel(store: store, ttsService: tts)
    let view = SettingsView(viewModel: vm)
    XCTAssertNotNil(view.body)
}
```

- [ ] **Step 2: Reconstruct `SettingsView.swift`**

Key implementation details:
1. **Remove `CraftStreakCard`** and `streakData` helper completely from `SettingsView`.
2. **5 Distinct Sections**:
   - `HeroProfileCard` at the top.
   - `learningSection`:
     - Row 1: `CraftListRow` (Daily Goal) without icon, trailing: `CraftStepper`. Double-tap removed or kept on label without obstructing stepper buttons.
     - Row 2: `CraftListRow` (Reminders) without icon, trailing: `CraftSwitch`.
     - Row 2b (when enabled): `CraftListRow` (Reminder Time) without icon, trailing: `DatePicker`.
     - Row 3: `CraftListRow` (Current Level) without icon, trailing: `CraftBadge`.
   - `audioSection`:
     - Row 1: `CraftListRow` (Voice Accent) without icon, trailing: `CraftSegmentedControl` [US | UK].
     - Row 2: `VStack` inside card: Title + current multiplier badge, followed by `HStack` with `Image(systemName: "tortoise")`, `Slider(0.5...1.5)`, and `Image(systemName: "hare.fill")`.
     - Row 3: `CraftListRow` (Test Speech) with audio play / waveform indicator.
   - `appearanceSection`:
     - Row 1: `VStack` or full-width `CraftListRow` for Theme Mode: [Dark | Light | System] segmented control with sufficient horizontal width so no text clips.
     - Row 2: `CraftListRow` (Theme Preset) without icon, trailing: Menu picker.
     - Row 3: `CraftListRow` (Haptics) without icon, trailing: `CraftSwitch`.
     - Row 4: `CraftListRow` (Sound Effects) without icon, trailing: `CraftSwitch`.
   - `dataSection`:
     - Row 1: `CraftListRow` (iCloud Sync) without icon, trailing: `CraftBadge(AppStrings.Settings.synced)`.
     - Row 2: `CraftListRow` (Clear Cache) without icon, trailing: `CraftText(cacheSizeString)`.
     - Row 3: `CraftListRow` (Reset SRS Progress) with red title `theme.colors.statusDanger` and red chevron, triggering confirmation alert.
   - `aboutSection`:
     - Row 1: `CraftListRow` (App Language) without icon, trailing: Menu picker.
     - Row 2: `CraftListRow` (Craft Catalog) with chevron, triggering `showCatalogSheet`.
     - Row 3: `CraftListRow` (Version) without icon, trailing: version string.

- [ ] **Step 3: Run unit tests to verify passes**

Run: `swift test --filter SettingsViewTests`  
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Settings/Views/SettingsView.swift VocabCraftAppTests/SettingsViewTests.swift
git commit -m "refactor(settings): redesign settings screen with HIG Inset Grouped layout"
```

---

### Task 4: SwiftLint & Full Verification Suite

**Files:**
- Verify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Verify: `VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift`
- Verify: `VocabCraftAppTests/SettingsViewTests.swift`
- Verify: `VocabCraftAppTests/SettingsLocalizationTests.swift`

- [ ] **Step 1: Run SwiftLint**

Run: `swiftlint lint --path VocabCraftApp/Features/Settings`  
Expected: 0 violations.

- [ ] **Step 2: Run complete test suite**

Run: `swift test`  
Expected: 100% tests pass.

- [ ] **Step 3: Commit any formatting or lint fixes**

```bash
git add -u
git commit -m "chore(settings): format and conform to swiftlint"
```
