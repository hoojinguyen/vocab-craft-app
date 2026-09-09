# Design Specification: Settings Screen Redesign (HIG Inset Grouped)

**Date**: 2026-09-09  
**Status**: Draft for User Review  
**Target Flow**: Settings Screen (`VocabCraftApp/Features/Settings/Views/SettingsView.swift`)  

---

## 1. Overview & Problem Statement

The previous iteration of the Settings screen adopted an over-decorated "Bento" approach that introduced several significant usability and aesthetic issues:
1. **Scope Bloat**: Embedding a full 7-day `CraftStreakCard` directly in Settings duplicated data already present on Home and in the Profile sheet, adding over 200pt of unnecessary vertical scrolling.
2. **Hero Header Fatigue**: `HeroProfileCard` consumed substantial vertical space with a large centered avatar, tagline, and full-width CTA, resembling a marketing landing page rather than a native iOS configuration screen.
3. **Icon Clutter ("Icon Fatigue")**: Every single row used an identical purple/brand-colored squircle container (`iconBackgroundColor: surfaceSubtle`, `iconColor: brandPrimary`), producing a repetitive "visual wall" that degraded scannability instead of aiding it.
4. **Cramped Form Controls**: Segmented controls (Theme mode) and sliders (TTS speed) were squeezed into row trailing slots or padded awkwardly underneath text, leading to horizontal clipping on smaller devices (iPhone SE/mini).
5. **Muddled Information Architecture (IA)**: App Language was placed under "Learning", and destructive actions like "Reset SRS Progress" were mixed into learning preference toggles.

### Solution & Design Goals
Adopt **Apple Human Interface Guidelines (HIG) Inset Grouped** best practices:
- **Clean Compact Profile Row**: Replace the oversized hero with an Apple ID-style compact horizontal row (Avatar 48pt with subtle aura + Name + CEFR Level badge + chevron) opening `ProfileStatsSheet`.
- **Zero Streak Card in Settings**: Keep Settings dedicated strictly to app preferences and system configuration.
- **Strict Iconography Hierarchy ("Less is More")**: Remove icon squircles from all internal form controls (toggles, sliders, steppers, pickers). Reserve icons or visual cues only for specific interactive media items (e.g. TTS audio preview, speed bounds).
- **5 Clean Semantic Groups**:
  1. *Header*: Compact Account / Profile Row
  2. *Học tập & Mục tiêu* (Learning & Goals)
  3. *Âm thanh & Phát âm* (Audio & TTS)
  4. *Giao diện & Phản hồi* (Appearance & Sensory Feedback)
  5. *Dữ liệu & Bộ nhớ* (Data & Storage - including isolated Reset SRS)
  6. *Thông tin & Hệ thống* (App Language, Developer Tools, App Version)
- **100% CraftUIKit Token & Localization Discipline**: Zero hardcoded strings, zero raw colors, full bilingual (EN/VI) support.

---

## 2. Layout Structure & Visual Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                     Cài đặt / Settings                      │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [Avatar 48pt]  Hooji N.                [ B2 Inter ]  >  │ │ (Compact Profile Row)
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  HỌC TẬP & MỤC TIÊU                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Mục tiêu hàng ngày             [-]  15 từ  [+] (Stepper)│ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Nhắc nhở học tập                          [ Switch ON ] │ │
│ │  └─ (nếu ON) Thời gian nhắc                    [ 20:00 ]│ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Trình độ hiện tại                       B2 Intermediate │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ÂM THANH & PHÁT ÂM                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Giọng đọc (Accent)                 [ US (Mỹ) | UK (Anh) ]│ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Tốc độ đọc                                      [ 1.00x ]│ │
│ │  🐢 ━━━━━━━●━━━━━━━━━━━━━ 🐇                            │ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Nghe thử phát âm             [▶ / Animated Waveform]    │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  GIAO DIỆN & PHẢN HỒI                                       │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Chế độ hiển thị                [ Tối | Sáng | Tự động ] │ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Bộ màu chủ đề                     [ Classic Indigo ▾ ]  │ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Rung phản hồi (Haptics)                   [ Switch ON ] │ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Âm thanh hiệu ứng                         [ Switch ON ] │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  DỮ LIỆU & BỘ NHỚ                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Đồng bộ iCloud                             [ Đã đồng bộ ]│ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Xoá bộ nhớ đệm                                  12.4 MB │ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Đặt lại tiến độ SRS (Màu đỏ cảnh báo)                 > │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  THÔNG TIN & HỆ THỐNG                                       │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Ngôn ngữ ứng dụng                    [ Tiếng Việt ▾ ]   │ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Craft UI Catalog (Dev)                 Component Lab  > │ │
│ │─────────────────────────────────────────────────────────│ │
│ │ Phiên bản                                   v1.0.0 (B1) │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Section & Component Specifications

### 3.1 Compact Profile Row (`CompactProfileRow`)
- **Container**: `CraftCard(style: .outlined, padding: 0)` with internal horizontal padding `theme.spacing.base` and vertical padding `theme.spacing.md`.
- **Leading**: Circle 48x48 with `theme.gradients.brandHero` and subtle outline, displaying the first letter of `userName`.
- **Center Title & Subtitle**: 
  - `userName` using `theme.typography.headline.bold()`, foreground `theme.colors.textPrimary`.
  - Tagline or membership note using `theme.typography.caption`, foreground `theme.colors.textSecondary`.
- **Trailing Slot**:
  - `CraftBadge` with CEFR Level (e.g. "B2 Intermediate"), subtle variant, primary tone.
  - `CraftIcon("chevron.right", size: .sm, color: theme.colors.textMuted)`.
- **Interaction**: Full-card tap with `.craftPress(scale: 0.98)` opens `ProfileStatsSheet`.

### 3.2 Learning & Goals Section (`learningSection`)
- **Header**: Section label `AppStrings.Settings.sectionLearning` using `CraftText(..., style: .caption, color: textSecondary)`.
- **Row 1: Daily Goal (`AppStrings.Settings.dailyGoal`)**:
  - Uses `CraftListRow` without icon squircle.
  - Trailing slot: `CraftStepper(value: $store.dailyGoalCount, range: 5...100, step: 5, unit: AppStrings.Common.wordUnit)`.
- **Row 2: Reminders Toggle (`AppStrings.Settings.reminders`)**:
  - `CraftListRow` without icon squircle.
  - Trailing slot: `CraftSwitch(isOn: $store.isNotificationEnabled)`.
- **Row 2b: Reminder Time (`AppStrings.Settings.reminderTime`)**:
  - Conditionally rendered with smooth height/opacity animation when `isNotificationEnabled` is true.
  - Native `DatePicker` hidden labels, tint `theme.colors.brandPrimary`.
- **Row 3: Current Level (`AppStrings.Settings.targetLevel`)**:
  - Shows current assessed level badge `CraftBadge(store.assessedCefrLevel)`.

### 3.3 Audio & Speech Section (`audioSection`)
- **Header**: Section label `AppStrings.Settings.sectionAudio`.
- **Row 1: Audio Accent (`AppStrings.Settings.audioAccent`)**:
  - `CraftSegmentedControl` with flat style, selection `store.ttsVoiceGender`, options `US` and `UK`.
- **Row 2: Speech Speed (`AppStrings.Settings.speechSpeed`)**:
  - Top line: Title + current multiplier badge (`CraftBadge(format: "%.2fx")`).
  - Bottom line: Centered `Slider(0.5...1.5, step: 0.05)` flanked by `Image(systemName: "tortoise")` and `Image(systemName: "hare.fill")` in `theme.colors.textMuted`.
- **Row 3: Test Speech (`AppStrings.Settings.testTTS`)**:
  - Tappable row triggering `viewModel.playAudioPreview()`.
  - Trailing: `CraftWaveformView` if `viewModel.isPlayingAudio` is active, else `CraftIcon("play.circle.fill", color: brandPrimary)`.

### 3.4 Appearance & Sensory Feedback Section (`appearanceSection`)
- **Header**: Section label `AppStrings.Settings.sectionAppearance`.
- **Row 1: Theme Mode (`AppStrings.Settings.appearanceMode`)**:
  - `CraftSegmentedControl` with options [Dark | Light | System]. Full width within the row to ensure no text clipping.
- **Row 2: Theme Color Preset (`AppStrings.Settings.themePreset`)**:
  - Shows current preset name with Menu picker.
- **Row 3: Haptics Feedback (`AppStrings.Settings.haptics`)**:
  - Toggle `CraftSwitch(isOn: $store.isHapticsEnabled)`. No icon.
- **Row 4: Sound Effects (`AppStrings.Settings.soundEffects`)**:
  - Toggle `CraftSwitch(isOn: $store.isSoundEffectsEnabled)`. No icon.

### 3.5 Data & Storage Section (`dataSection`)
- **Header**: Section label `AppStrings.Settings.sectionDataStorage` (New localization key).
- **Row 1: iCloud Sync (`AppStrings.Settings.icloudSync`)**:
  - Trailing: `CraftBadge(AppStrings.Settings.synced, symbol: .check, variant: .subtle, tone: .success)`.
- **Row 2: Clear Cache (`AppStrings.Settings.clearCache`)**:
  - Action row showing `viewModel.cacheSizeString`, tapping calls `viewModel.clearCache()`.
- **Row 3: Reset SRS Progress (`AppStrings.Settings.resetSRS`)**:
  - Styled with destructive intent: title in `theme.colors.statusDanger`, subtitle in `theme.colors.textSecondary`, chevron in `theme.colors.statusDanger.opacity(0.6)`. Tapping opens confirmation alert.

### 3.6 App Info & Developer Section (`aboutSection`)
- **Header**: Section label `AppStrings.Settings.sectionAbout`.
- **Row 1: App Language (`AppStrings.Settings.appLanguage`)**:
  - Menu picker: [Hệ thống / System | Tiếng Việt | English].
- **Row 2: Craft UI Catalog (`AppStrings.Settings.craftCatalog`)**:
  - Action row opening `CraftCatalogView` full screen sheet.
- **Row 3: App Version (`AppStrings.Settings.appVersion`)**:
  - Display string: `v1.0.0 (Build 1)` in `theme.colors.textMuted`.

---

## 4. Design Token Discipline & CraftUIKit Alignment

All visual styling strictly references `CraftUIKit` tokens via `@Environment(\.craftTheme) private var theme`:
- **Colors**:
  - Canvas background: `theme.colors.canvasBackground`
  - Cards & Rows: `theme.colors.surfaceCard`, `theme.colors.surfaceSubtle`
  - Primary text: `theme.colors.textPrimary`
  - Secondary text: `theme.colors.textSecondary`, `theme.colors.textMuted`
  - Brand accents: `theme.colors.brandPrimary`
  - Danger / Warnings: `theme.colors.statusDanger`, `theme.colors.statusWarning`
- **Spacing & Radii**:
  - Card horizontal padding: `theme.spacing.base` (16pt)
  - Section stack spacing: `theme.spacing.lg` (24pt)
  - Row internal spacing: `theme.spacing.sm` / `theme.spacing.md`
  - Corner radius: `theme.radii.lg` (16pt) for `CraftCard`
- **Sensory & Haptics**:
  - All interactive toggles and segmented controls trigger `.sensoryFeedback` gated by `store.isHapticsEnabled`.

---

## 5. Localization Architecture & Key Inventory

New and modified keys in `VocabCraftApp/Resources/Localizable.xcstrings`:
- `app.settings.section_data_storage`:
  - `en`: "Data & Storage"
  - `vi`: "Dữ liệu & Bộ nhớ"
- All existing keys (`app.settings.*`, `app.profile.*`, `app.common.*`) remain preserved with 100% bilingual parity.

---

## 6. Testing & Quality Verification Plan

1. **Unit Tests**:
   - `SettingsViewTests`: Verify presence and correct rendering of 5 sections, profile row tap trigger, notification toggle expansion, and reset alert trigger.
   - `SettingsLocalizationTests`: Run `swift test --filter SettingsLocalizationTests` to verify 100% key and translation parity between EN and VI.
2. **SwiftLint & Compilation**:
   - Zero compiler warnings with strict concurrency.
   - Zero SwiftLint errors or warnings.
3. **Responsive UI Verification**:
   - Verified on small screen (iPhone SE 375pt) and large screen (iPhone 16 Pro Max 430pt) for zero text truncation in segmented controls and steppers.
