# Settings Screen Redesign with CraftUIKit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and refactor the `VocabCraft` Settings screen to achieve 100% CraftUIKit compliance with a modern card-grouped layout, illuminated Hero Profile & Pro card, 7-day Streak activity tracker, isolated Developer & Testing tools, and complete bilingual localization taxonomy (`app.settings.*`).

**Architecture:** Replace the current SwiftUI `List` with a `ScrollView` composed of grouped `CraftCard` containers. Connect UI controls directly to `UserSettingsStore` via `SettingsViewModel` using CraftUIKit components (`CraftSegmentedControl`, `CraftStepper`, `CraftSwitch`, `CraftBadge`, `CraftButton`, `CraftStreakCard`, `CraftListRow`, `CraftDivider`).

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit (Design System), Observation framework (`@Observable`), XCTest.

**Spec:** `docs/superpowers/specs/2026-08-28-settings-craftuikit-redesign.md`

## Global Constraints

- **Design System Conformance:** Use ONLY `CraftUIKit` components, tokens (`theme.colors.*`, `theme.typography.*`, `theme.radii.*`, `theme.spacing.*`, `theme.shadows.*`, `theme.gradients.*`). Zero raw styling (`Color.red`, ad-hoc hex colors, or custom un-tokenized shapes).
- **Localization Taxonomy:** All strings must use `app.settings.*` key taxonomy in `VocabCraftApp/Resources/Localizable.xcstrings` with 100% paired `vi` and `en` translations, `extractionState: "manual"`, and `state: "translated"`.
- **Quality Gates:** 0 compiler warnings, 0 compiler errors, 0 SwiftLint violations, 100% test pass rate.
- **Xcode Generated Files:** Do not commit unexpected Xcode cache files.

---

### Task 1: Localization & AppStrings Infrastructure for Settings

**Files:**
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift:270-311`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Create: `VocabCraftAppTests/SettingsLocalizationTests.swift`

**Interfaces:**
- Consumes: None
- Produces: Complete `AppStrings.Settings` typed accessors and bilingual string catalogs in `Localizable.xcstrings`.

- [ ] **Step 1: Write the failing localization test**

Create `VocabCraftAppTests/SettingsLocalizationTests.swift`:
```swift
import SwiftUI
@testable import VocabCraftApp
import XCTest

final class SettingsLocalizationTests: XCTestCase {
    func testAllSettingsStringsHaveBilingualTranslations() {
        let keys: [String] = [
            "app.settings.title",
            "app.settings.profile.membership_active",
            "app.settings.profile.perks",
            "app.settings.profile.action_view",
            "app.settings.section.learning",
            "app.settings.learning.target_level",
            "app.settings.learning.app_language",
            "app.settings.learning.lang_system",
            "app.settings.learning.lang_vi",
            "app.settings.learning.lang_en",
            "app.settings.learning.daily_goal",
            "app.settings.learning.reminders",
            "app.settings.learning.reminder_time",
            "app.settings.learning.reset_srs",
            "app.settings.learning.reset_srs_subtitle",
            "app.settings.learning.reset_confirm_title",
            "app.settings.learning.reset_confirm_message",
            "app.settings.section.audio",
            "app.settings.audio.accent",
            "app.settings.audio.accent_us",
            "app.settings.audio.accent_uk",
            "app.settings.audio.speed",
            "app.settings.audio.test_tts",
            "app.settings.audio.playing_preview",
            "app.settings.section.appearance",
            "app.settings.appearance.theme_mode",
            "app.settings.appearance.theme_dark",
            "app.settings.appearance.theme_light",
            "app.settings.appearance.theme_system",
            "app.settings.appearance.haptics",
            "app.settings.appearance.sound_effects",
            "app.settings.section.dev_tools",
            "app.settings.dev.theme_preset",
            "app.settings.dev.catalog_title",
            "app.settings.dev.catalog_subtitle",
            "app.settings.section.about",
            "app.settings.about.icloud_sync",
            "app.settings.about.synced",
            "app.settings.about.clear_cache",
            "app.settings.about.app_version"
        ]

        for key in keys {
            let viString = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "vi"), bundle: .main)
            let enString = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "en"), bundle: .main)

            XCTAssertNotEqual(viString, key, "Missing VI translation for key: \(key)")
            XCTAssertNotEqual(enString, key, "Missing EN translation for key: \(key)")
            XCTAssertFalse(viString.isEmpty, "Empty VI translation for key: \(key)")
            XCTAssertFalse(enString.isEmpty, "Empty EN translation for key: \(key)")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SettingsLocalizationTests` or `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/SettingsLocalizationTests`
Expected: FAIL due to missing keys in `Localizable.xcstrings`.

- [ ] **Step 3: Update `Localizable.xcstrings` and `AppStrings.swift`**

Add all `app.settings.*` entries with `extractionState: "manual"` and `state: "translated"` to `VocabCraftApp/Resources/Localizable.xcstrings`.

Update `VocabCraftApp/Core/Localization/AppStrings.swift` within `public enum Settings`:
```swift
    // MARK: - Settings View
    public enum Settings {
        public static var title: LocalizedStringKey { "app.settings.title" }
        public static var titleText: String { String(localized: "app.settings.title", defaultValue: "Cài đặt", bundle: .module) }
        
        // Profile
        public static var membershipActive: LocalizedStringKey { "app.settings.profile.membership_active" }
        public static var membershipActiveText: String { String(localized: "app.settings.profile.membership_active", defaultValue: "PRO ACTIVE", bundle: .module) }
        public static var profilePerks: LocalizedStringKey { "app.settings.profile.perks" }
        public static var profilePerksText: String { String(localized: "app.settings.profile.perks", defaultValue: "Thành viên Pro · Đã mở khoá toàn bộ 3,000+ từ Oxford & Reflex Blitz", bundle: .module) }
        public static var profileActionView: LocalizedStringKey { "app.settings.profile.action_view" }
        public static var profileActionViewText: String { String(localized: "app.settings.profile.action_view", defaultValue: "Xem hồ sơ & thành tích", bundle: .module) }
        
        // Learning Section
        public static var sectionLearning: LocalizedStringKey { "app.settings.section.learning" }
        public static var targetLevel: LocalizedStringKey { "app.settings.learning.target_level" }
        public static var targetLevelText: String { String(localized: "app.settings.learning.target_level", defaultValue: "Trình độ mục tiêu", bundle: .module) }
        public static var appLanguage: LocalizedStringKey { "app.settings.learning.app_language" }
        public static var appLanguageText: String { String(localized: "app.settings.learning.app_language", defaultValue: "Ngôn ngữ ứng dụng", bundle: .module) }
        public static var langSystem: LocalizedStringKey { "app.settings.learning.lang_system" }
        public static var langVietnamese: LocalizedStringKey { "app.settings.learning.lang_vi" }
        public static var langEnglish: LocalizedStringKey { "app.settings.learning.lang_en" }
        public static var dailyGoal: LocalizedStringKey { "app.settings.learning.daily_goal" }
        public static var dailyGoalText: String { String(localized: "app.settings.learning.daily_goal", defaultValue: "Mục tiêu hàng ngày", bundle: .module) }
        public static var reminders: LocalizedStringKey { "app.settings.learning.reminders" }
        public static var reminderTime: LocalizedStringKey { "app.settings.learning.reminder_time" }
        public static var resetSRS: LocalizedStringKey { "app.settings.learning.reset_srs" }
        public static var resetSRSSubtitle: LocalizedStringKey { "app.settings.learning.reset_srs_subtitle" }
        public static var resetConfirmTitle: LocalizedStringKey { "app.settings.learning.reset_confirm_title" }
        public static var resetConfirmMessage: LocalizedStringKey { "app.settings.learning.reset_confirm_message" }
        
        // Audio Section
        public static var sectionAudio: LocalizedStringKey { "app.settings.section.audio" }
        public static var audioAccent: LocalizedStringKey { "app.settings.audio.accent" }
        public static var accentUS: LocalizedStringKey { "app.settings.audio.accent_us" }
        public static var accentUSText: String { String(localized: "app.settings.audio.accent_us", defaultValue: "US (Mỹ)", bundle: .module) }
        public static var accentUK: LocalizedStringKey { "app.settings.audio.accent_uk" }
        public static var accentUKText: String { String(localized: "app.settings.audio.accent_uk", defaultValue: "UK (Anh)", bundle: .module) }
        public static var speechSpeed: LocalizedStringKey { "app.settings.audio.speed" }
        public static var testTTS: LocalizedStringKey { "app.settings.audio.test_tts" }
        public static var playingPreview: LocalizedStringKey { "app.settings.audio.playing_preview" }
        
        // Appearance Section
        public static var sectionAppearance: LocalizedStringKey { "app.settings.section.appearance" }
        public static var appearanceMode: LocalizedStringKey { "app.settings.appearance.theme_mode" }
        public static var themeDark: LocalizedStringKey { "app.settings.appearance.theme_dark" }
        public static var themeDarkText: String { String(localized: "app.settings.appearance.theme_dark", defaultValue: "Tối", bundle: .module) }
        public static var themeLight: LocalizedStringKey { "app.settings.appearance.theme_light" }
        public static var themeLightText: String { String(localized: "app.settings.appearance.theme_light", defaultValue: "Sáng", bundle: .module) }
        public static var themeSystem: LocalizedStringKey { "app.settings.appearance.theme_system" }
        public static var themeSystemText: String { String(localized: "app.settings.appearance.theme_system", defaultValue: "Tự động", bundle: .module) }
        public static var haptics: LocalizedStringKey { "app.settings.appearance.haptics" }
        public static var soundEffects: LocalizedStringKey { "app.settings.appearance.sound_effects" }
        
        // Developer Tools Section
        public static var sectionDevTools: LocalizedStringKey { "app.settings.section.dev_tools" }
        public static var themePreset: LocalizedStringKey { "app.settings.dev.theme_preset" }
        public static var craftCatalog: LocalizedStringKey { "app.settings.dev.catalog_title" }
        public static var craftCatalogSubtitle: LocalizedStringKey { "app.settings.dev.catalog_subtitle" }
        
        // About Section
        public static var sectionAbout: LocalizedStringKey { "app.settings.section.about" }
        public static var icloudSync: LocalizedStringKey { "app.settings.about.icloud_sync" }
        public static var synced: LocalizedStringKey { "app.settings.about.synced" }
        public static var clearCache: LocalizedStringKey { "app.settings.about.clear_cache" }
        public static var appVersion: LocalizedStringKey { "app.settings.about.app_version" }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SettingsLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftAppTests/SettingsLocalizationTests.swift
git commit -m "feat(settings): add app.settings.* localization taxonomy and keys"
```

---

### Task 2: Build `HeroProfileCard` Component with CraftUIKit

**Files:**
- Create: `VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift`
- Modify: `VocabCraftAppTests/SettingsViewTests.swift`

**Interfaces:**
- Consumes: `CraftCard`, `CraftBadge`, `CraftButton`, `CraftText`, `CraftTheme`
- Produces: `HeroProfileCard(userName:userLevel:onTapAction:)`

- [ ] **Step 1: Write test for `HeroProfileCard`**

Add to `VocabCraftAppTests/SettingsViewTests.swift`:
```swift
func testHeroProfileCardInitialization() {
    var actionTapped = false
    let card = HeroProfileCard(
        userName: "Hooji N.",
        userLevel: "B2 Intermediate",
        onTapAction: { actionTapped = true }
    )
    XCTAssertEqual(card.userName, "Hooji N.")
    XCTAssertEqual(card.userLevel, "B2 Intermediate")
    card.onTapAction?()
    XCTAssertTrue(actionTapped)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/SettingsViewTests/testHeroProfileCardInitialization`
Expected: FAIL with `HeroProfileCard` not found.

- [ ] **Step 3: Implement `HeroProfileCard`**

Create `VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift`:
```swift
import CraftUIKit
import SwiftUI

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
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Top Header Row
                HStack(spacing: theme.spacing.md) {
                    // Avatar with glowing aura
                    ZStack {
                        Circle()
                            .fill(theme.gradients.brandHero)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .strokeBorder(theme.colors.borderHighlight, lineWidth: 2)
                            )
                            .craftShadow(theme.shadows.md)

                        Text(userName.prefix(1))
                            .font(theme.typography.titleLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                        HStack(spacing: theme.spacing.xs) {
                            CraftText(userName, style: .headline, color: theme.colors.textPrimary)
                            CraftBadge(
                                AppStrings.Settings.membershipActive,
                                symbol: .sparkles,
                                variant: .subtle,
                                tone: .success,
                                size: .sm
                            )
                        }

                        CraftBadge(
                            userLevel,
                            symbol: .star,
                            variant: .subtle,
                            tone: .primary,
                            size: .sm
                        )
                    }

                    Spacer()
                }

                // Perks Tagline
                CraftText(
                    AppStrings.Settings.profilePerks,
                    style: .caption,
                    color: theme.colors.textSecondary
                )
                .fixedSize(horizontal: false, vertical: true)

                // Action Button
                CraftButton(
                    AppStrings.Settings.profileActionView,
                    variant: .secondary,
                    size: .md,
                    action: {
                        onTapAction?()
                    }
                )
            }
        }
    }
}

#Preview("HeroProfileCard") {
    HeroProfileCard()
        .padding()
        .background(Color.gray.opacity(0.1))
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/SettingsViewTests/testHeroProfileCardInitialization`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift VocabCraftAppTests/SettingsViewTests.swift
git commit -m "feat(settings): create HeroProfileCard component using CraftUIKit"
```

---

### Task 3: Refactor & Modernize `SettingsView` into Grouped `CraftCard` Layout

**Files:**
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Delete: `VocabCraftApp/Features/Settings/Views/Components/ProfileHeaderCard.swift`
- Delete: `VocabCraftApp/Features/Settings/Views/Components/SettingsRowView.swift`

**Interfaces:**
- Consumes: `HeroProfileCard`, `CraftStreakCard`, `CraftSegmentOption`, `CraftSegmentedControl`, `CraftStepper`, `CraftSwitch`, `CraftListRow`, `CraftDivider`, `CraftBadge`, `CraftCard`
- Produces: Refactored `SettingsView(viewModel:)`

- [ ] **Step 1: Write integration tests for `SettingsView` rendering and interactions**

Update `VocabCraftAppTests/SettingsViewTests.swift` to verify all section cards, segment bindings, and theme switching.

- [ ] **Step 2: Run test to verify current state**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/SettingsViewTests`

- [ ] **Step 3: Refactor `SettingsView.swift`**

Replace `SettingsView.swift` with the full modern `ScrollView` layout composed of `HeroProfileCard`, `CraftStreakCard`, and categorized `CraftCard` containers using `CraftSegmentedControl`, `CraftStepper`, `CraftSwitch`, `CraftListRow`, and `CraftDivider`.

Delete obsolete `ProfileHeaderCard.swift` and `SettingsRowView.swift`.

- [ ] **Step 4: Run full Settings tests to verify pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/SettingsViewTests -only-testing:VocabCraftAppTests/SettingsViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git rm VocabCraftApp/Features/Settings/Views/Components/ProfileHeaderCard.swift VocabCraftApp/Features/Settings/Views/Components/SettingsRowView.swift
git add VocabCraftApp/Features/Settings/Views/SettingsView.swift VocabCraftAppTests/SettingsViewTests.swift
git commit -m "feat(settings): redesign SettingsView with grouped CraftCards and CraftUIKit controls"
```

---

### Task 4: Diagnostics, SwiftLint Compliance & Quality Gate

**Files:**
- Verify: Full workspace compilation and test suite

- [ ] **Step 1: Run SwiftLint**

Run: `swiftlint lint --path VocabCraftApp/Features/Settings`
Expected: 0 errors, 0 warnings.

- [ ] **Step 2: Run Full App Test Suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: 100% tests pass.

- [ ] **Step 3: Verify Xcode compiler diagnostics**

Run: `xcodebuild build -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: **0 errors, 0 warnings**.

- [ ] **Step 4: Commit and finalize**

```bash
git commit --allow-empty -m "chore(settings): complete quality gate with zero warnings and full test coverage"
```
