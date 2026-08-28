# Feature 6: Settings Screen Redesign with CraftUIKit

## 1. Overview & Objectives

This specification details the comprehensive redesign and refactoring of **Feature 6: Settings** in the `VocabCraft` iOS application. The primary objectives are:

1. **100% CraftUIKit Conformance**: Replace all custom, ad-hoc views, manual shapes, raw gradients, and hardcoded colors with standardized components, surface styles, and tokens from `Packages/CraftUIKit/`.
2. **Modern Bento & Card-Grouped Layout**: Transform the screen from a default iOS `List` into a modern, card-driven `ScrollView` layout inspired by high-polish mobile interfaces (such as Wordy / Duolingo / Headspace), featuring an illuminated Hero Profile & Pro card, a 7-day Streak activity tracker, and grouped settings containers.
3. **Developer & Testing Tools Isolation**: Place testing controls (Theme Preset switcher and CraftUIKit Catalog) in a dedicated developer card with clear `#if DEBUG` / staging boundaries.
4. **Strict Localization Architecture**: Adhere strictly to the two-layer localization taxonomy (`app.settings.*`) with 100% bilingual parity (Vietnamese & English) in `Localizable.xcstrings`.
5. **Zero Errors & Zero Warnings**: Guarantee strict Swift 6 concurrency compliance, accessibility compliance (WCAG AAA contrast, dynamic type, VoiceOver labels), and zero SwiftLint or compiler warnings.

---

## 2. Layout Structure & Visual Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                       Cài đặt / Settings                    │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                  HERO PROFILE & PRO CARD                │ │
│ │   [ Avatar with Aura ]   Hooji N.   [ PRO ACTIVE ]      │ │
│ │   B2 Intermediate • Oxford 3000+ • Reflex Blitz         │ │
│ │   [ CraftButton (Secondary): Xem hồ sơ & thành tích ]   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │            STREAK ACTIVITY CARD (CraftStreakCard)       │ │
│ │   🔥 14 ngày chuỗi (Blaze)         🏆 Kỷ lục: 30 ngày   │ │
│ │   (T2)  (T3)  (T4)  (T5-Today)  (T6)  (T7)  (CN)        │ │
│ │   ❄️ 2/3 Freeze Shield          [==== Progress ====>]   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  HỌC TẬP & ÔN TẬP                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🎓 Trình độ mục tiêu                    B2 Intermediate │ │
│ │ 🌐 Ngôn ngữ ứng dụng                    Tiếng Việt / EN │ │
│ │ 🎯 Mục tiêu hàng ngày         [-]  15 từ  [+] (Stepper) │ │
│ │ 🔔 Nhắc nhở ôn tập                       [ Switch ON ]  │ │
│ │ ⏰ Giờ nhắc nhở                             [ 20:00 ]   │ │
│ │ 🔄 Đặt lại tiến độ SRS (Destructive)                >   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ÂM THANH & PHÁT ÂM                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🔊 Giọng phát âm (TTS)           [ US (Mỹ) | UK (Anh) ] │ │
│ │ ⏱️ Tốc độ đọc                          [ 1.00x ] (Badge) │ │
│ │    [━━━━━━━━━━━━━━━●━━━━━━━━━━━━━━] (Slider 0.5x-1.5x)  │ │
│ │ ▶️ Nghe thử phát âm             [ Waveform Animation ]   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  GIAO DIỆN & TRẢI NGHIỆM                                    │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🎨 Chế độ hiển thị               [ Tối | Sáng | Tự động ]│ │
│ │ 📳 Rung phản hồi (Haptics)               [ Switch ON ]  │ │
│ │ 🎵 Âm thanh hiệu ứng (SFX)               [ Switch ON ]  │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  CÔNG CỤ PHÁT TRIỂN (DEV & TESTING)                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🪄 Theme thiết kế (Presets)       [ Editorial Slate ▾ ] │ │
│ │ 🧩 CraftUIKit Catalog               Interactive Gallery >│ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  THÔNG TIN ỨNG DỤNG                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ☁️ Đồng bộ iCloud                         [ Đã đồng bộ ] │ │
│ │ 🗑️ Xoá bộ nhớ đệm                               12.4 MB │ │
│ │ ℹ️ Phiên bản                               v1.2.0 (B42) │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Component Breakdown & Mapping to CraftUIKit

| Section | Element | CraftUIKit Component | Role & Styling |
|---|---|---|---|
| **Root Container** | Settings Screen | `ScrollView` + `VStack` | Background: `theme.colors.canvasBackground`, Spacing: `theme.spacing.lg` |
| **Hero Profile** | Card Container | `CraftCard(style: .elevated)` | Dynamic shadow, top highlight border |
| | User Avatar | `ZStack` + `theme.gradients.brandHero` | Circular avatar with glowing aura effect |
| | Pro Badge | `CraftBadge` | Tone: `.success`, Symbol: `.sparkles`, Variant: `.subtle`, Size: `.sm` |
| | Perks Description | `CraftText` | Style: `.caption`, Color: `theme.colors.textSecondary` |
| | CTA Button | `CraftButton` | Variant: `.secondary`, Size: `.md`, tactile press haptic |
| **Streak Tracker** | 7-Day Activity Widget | `CraftStreakCard` | 7-day node track, tier gradient flame, freeze tokens, milestone bar |
| **Learning & SRS** | Section Card | `CraftCard(style: .outlined)` | Border: `theme.colors.borderDefault`, Fill: `theme.colors.surfaceCard` |
| | Rows | `CraftListRow` | Leading icon in colored squircle, localized title/subtitle |
| | Level & Language | `CraftBadge` / `Menu` | Badge tone: `.primary`, subtle variant |
| | Daily Goal | `CraftStepper` | Step 5, bounded 5...100, monospaced digits, sensory feedback |
| | Reminders Toggle | `CraftSwitch` / `ToggleStyle.craft` | Theme brand tint, tactile spring animation |
| | Reset SRS Row | `CraftListRow` | Icon tone: `theme.colors.statusDanger`, opens `CraftDialog` or alert |
| **Audio & TTS** | Section Card | `CraftCard(style: .outlined)` | Contains TTS configuration controls |
| | Voice Accent | `CraftSegmentedControl` | 2 segments (`US` / `UK`), smooth slide transition |
| | Speech Speed | `CraftBadge` + `Slider` | Speed badge (e.g. `1.00x`, tone: `.warning`) + themed accent track |
| | Speech Preview | `CraftListRow` + `CraftWaveformView` | Animated 4-bar waveform when `isPlayingAudio` is active |
| **Appearance** | Section Card | `CraftCard(style: .outlined)` | User appearance preferences |
| | Appearance Mode | `CraftSegmentedControl` | 3 segments: `dark`, `light`, `system` |
| | Haptics & SFX | `CraftSwitch` / `CraftToggle` | Standalone switch controls |
| **Dev Tools** | Dev Section Card | `CraftCard(style: .outlined)` | Conditioned by `#if DEBUG` or dev flag |
| | Theme Preset | `CraftListRow` + Menu | Select from 8 `CraftThemePreset` options |
| | Craft Catalog | `CraftListRow` (with chevron) | Opens full-screen `CraftCatalogView` |
| **App Info** | Section Card | `CraftCard(style: .outlined)` | App metadata & maintenance |
| | iCloud Sync | `CraftBadge` | Tone: `.success`, Icon: `checkmark`, Variant: `.subtle` |
| | Clear Cache | `CraftListRow` | Displays MB size, triggers clean-up action |
| | Version | `CraftListRow` | Shows semantic version and build number |

---

## 4. Localization Taxonomy (`app.settings.*`)

All user-facing strings must be localized inside `VocabCraftApp/Resources/Localizable.xcstrings` adhering to the following standard taxonomy:

| Localization Key | Vietnamese (vi) | English (en) |
|---|---|---|
| `app.settings.title` | "Cài đặt" | "Settings" |
| `app.settings.profile.membership_active` | "PRO ACTIVE" | "PRO ACTIVE" |
| `app.settings.profile.perks` | "Thành viên Pro · Đã mở khoá toàn bộ 3,000+ từ Oxford & Reflex Blitz" | "Pro Member · Unlocked all 3,000+ Oxford words & Reflex Blitz" |
| `app.settings.profile.action_view` | "Xem hồ sơ & thành tích" | "View Profile & Achievements" |
| `app.settings.section.learning` | "HỌC TẬP & ÔN TẬP (SRS)" | "LEARNING & SRS" |
| `app.settings.learning.target_level` | "Trình độ mục tiêu" | "Target Level" |
| `app.settings.learning.app_language` | "Ngôn ngữ ứng dụng" | "App Language" |
| `app.settings.learning.lang_system` | "Hệ thống" | "System" |
| `app.settings.learning.lang_vi` | "Tiếng Việt" | "Vietnamese" |
| `app.settings.learning.lang_en` | "English" | "English" |
| `app.settings.learning.daily_goal` | "Mục tiêu hàng ngày" | "Daily Goal" |
| `app.settings.learning.reminders` | "Nhắc nhở ôn tập" | "Review Reminders" |
| `app.settings.learning.reminder_time` | "Giờ nhắc nhở" | "Reminder Time" |
| `app.settings.learning.reset_srs` | "Đặt lại tiến độ SRS" | "Reset SRS Progress" |
| `app.settings.learning.reset_srs_subtitle` | "Xoá toàn bộ từ đã học và chuỗi ghi nhớ" | "Reset all learned words and memory streaks" |
| `app.settings.learning.reset_confirm_title` | "Xác nhận đặt lại tiến độ?" | "Confirm Reset Progress?" |
| `app.settings.learning.reset_confirm_message` | "Hành động này sẽ xoá toàn bộ thống kê SRS và không thể hoàn tác." | "This will erase all SRS statistics and cannot be undone." |
| `app.settings.section.audio` | "ÂM THANH & PHÁT ÂM" | "AUDIO & PRONUNCIATION" |
| `app.settings.audio.accent` | "Giọng phát âm TTS" | "TTS Voice Accent" |
| `app.settings.audio.accent_us` | "US (Mỹ)" | "US (American)" |
| `app.settings.audio.accent_uk` | "UK (Anh)" | "UK (British)" |
| `app.settings.audio.speed` | "Tốc độ đọc" | "Speech Speed" |
| `app.settings.audio.test_tts` | "Nghe thử phát âm mẫu" | "Test Speech Pronunciation" |
| `app.settings.audio.playing_preview` | "Đang phát âm thanh mẫu..." | "Playing sample audio..." |
| `app.settings.section.appearance` | "GIAO DIỆN & TRẢI NGHIỆM" | "APPEARANCE & EXPERIENCE" |
| `app.settings.appearance.theme_mode` | "Chế độ giao diện" | "Appearance Mode" |
| `app.settings.appearance.theme_dark` | "Tối" | "Dark" |
| `app.settings.appearance.theme_light` | "Sáng" | "Light" |
| `app.settings.appearance.theme_system` | "Tự động" | "System" |
| `app.settings.appearance.haptics` | "Rung phản hồi" | "Haptic Feedback" |
| `app.settings.appearance.sound_effects` | "Âm thanh hiệu ứng" | "Sound Effects" |
| `app.settings.section.dev_tools` | "CÔNG CỤ PHÁT TRIỂN (DEV ONLY)" | "DEVELOPER TOOLS (DEV ONLY)" |
| `app.settings.dev.theme_preset` | "Theme thiết kế (Design Preset)" | "Design Preset Theme" |
| `app.settings.dev.catalog_title` | "CraftUIKit Catalog" | "CraftUIKit Catalog" |
| `app.settings.dev.catalog_subtitle` | "Bộ sưu tập linh kiện & token giao diện" | "Interactive component & token gallery" |
| `app.settings.section.about` | "THÔNG TIN ỨNG DỤNG" | "ABOUT & SYSTEM" |
| `app.settings.about.icloud_sync` | "Đồng bộ iCloud" | "iCloud Sync" |
| `app.settings.about.synced` | "Đã đồng bộ" | "Synced" |
| `app.settings.about.clear_cache` | "Xoá bộ nhớ đệm" | "Clear Cache" |
| `app.settings.about.app_version` | "Phiên bản ứng dụng" | "App Version" |

---

## 5. Technical Implementation & Architecture

### 5.1 Architecture & State Ownership
- `SettingsView`: Root View holding `@Bindable public var viewModel: SettingsViewModel` and `@Environment(\.craftTheme) private var theme`.
- `UserSettingsStore`: Single source of truth for persistent user preferences stored in `UserDefaults` (`dailyGoalCount`, `themePreset`, `appTheme`, `appLanguage`, `ttsVoiceGender`, `ttsSpeed`, `isNotificationEnabled`, `isHapticsEnabled`, `isSoundEffectsEnabled`).
- `SettingsViewModel`: Handles business operations (`playAudioPreview()`, `clearCache()`, `resetSRSProgress()`), provides audio playback animation state (`isPlayingAudio`), and formats display values.

### 5.2 Files to Modify & Refactor
1. **`VocabCraftApp/Features/Settings/Views/SettingsView.swift`**:
   - Refactor body to `ScrollView` + `VStack` containing grouped `CraftCard` containers.
   - Replace standard Pickers with `CraftSegmentedControl` (for Accent and Appearance Mode).
   - Use `CraftStepper`, `CraftSwitch`, `CraftBadge`, `CraftButton`, `CraftDivider`, `CraftListRow`.
   - Embed `CraftStreakCard` with live streak data binding.
2. **`VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift`** (replaces `ProfileHeaderCard.swift`):
   - Refactored to utilize `CraftCard(style: .elevated)`, `CraftBadge`, `CraftButton`, `CraftText`, and `theme.gradients.brandHero`.
3. **`VocabCraftApp/Core/Localization/AppStrings.swift`**:
   - Update `AppStrings.Settings` namespace with complete `app.settings.*` keys.
4. **`VocabCraftApp/Resources/Localizable.xcstrings`**:
   - Add all new `app.settings.*` localization entries with 100% paired `en` and `vi` translations.
5. **`VocabCraftAppTests/SettingsViewTests.swift` & `SettingsViewModelTests.swift`**:
   - Update tests to verify new state interactions, segmented control bindings, and audio test flows.

---

## 6. Verification & Quality Assurance Plan

### 6.1 Automated Verification
1. **Localization Verification**:
   ```bash
   swift test --filter LocalizationTests
   ```
2. **Unit & Integration Tests**:
   ```bash
   xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/SettingsViewModelTests -only-testing:VocabCraftAppTests/UserSettingsStoreTests
   ```
3. **SwiftLint Compliance**:
   ```bash
   swiftlint lint --path VocabCraftApp/Features/Settings
   ```
4. **Compiler Warnings & Diagnostics**:
   - Build project with `0 errors` and `0 warnings`.

### 6.2 Manual & UI Verification
- **Visual Inspection across Theme Presets**: Switch between *Editorial Slate*, *Kyoto Matcha*, *Neo Arcade*, and *Tactile Clay* to confirm cards, glass effects, borders, and shadows react dynamically.
- **Dark / Light Mode Segment Switching**: Verify dark, light, and system color schemes apply immediately without visual glitches.
- **Audio Preview Test**: Confirm audio playback starts, the 4-bar waveform animates, and resets after 1.5s.
- **Streak Tracker Node Tapping**: Verify 7-day activity nodes and freeze shields respond to touch.
- **Dynamic Type & VoiceOver**: Verify labels scale with Dynamic Type and VoiceOver speaks clear accessibility values.
