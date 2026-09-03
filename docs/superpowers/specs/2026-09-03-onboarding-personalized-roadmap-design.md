# Design Spec: VocabCraft Personalized Onboarding & Learning Roadmap

**Date**: 2026-09-03  
**Status**: Approved (Brainstorming Phase Completed)  
**Target Module**: `VocabCraftApp` (Features/Onboarding) & `CraftUIKit` (Reuse existing components)

---

## 1. Executive Summary & Goals

### 1.1 Objectives
When a user launches `VocabCraft` for the first time (or after authenticating), the app must deliver an intuitive, frictionless, and engaging onboarding funnel. This experience serves four primary purposes:
1. **Identify User Motivation**: Determine the primary domain they want to master (*Daily Communication*, *Business & Career*, *Academic & IELTS*, or *Technology & AI*).
2. **Assess Baseline Proficiency**: Enable users to self-assess their current English ability mapped directly to the Common European Framework of Reference for Languages (CEFR: A1, A2, B1/B2, C1) without the cognitive friction of an exam.
3. **Anchor Habit & Commitment**: Establish a sustainable daily vocabulary volume (5, 10, 15, or 20 words/day) and request push notification permission timed to their lifestyle.
4. **Synthesize a Personalized Roadmap**: Generate an individualized learning plan that auto-unlocks foundational levels for intermediate/advanced learners, directs them to their ideal starting stage on the `CraftLearningPath`, and provides an immediate "First Win" mini-lesson activating their Day-1 streak.

---

## 2. Architecture & Data Flow

### 2.1 App Entry & Lifecycle Routing (`VocabCraftApp.swift`)
The app inspects `UserSettingsStore.hasCompletedOnboarding`:
- **If `false`**: The root scene presents `OnboardingCoordinatorView`.
- **If `true`**: The root scene presents `HomepageView` (with liquid glass floating tab bar).
- Upon completing the first mini-lesson (or tapping "Skip"), `hasCompletedOnboarding` is set to `true`, transitioning smoothly into `HomepageView`.

```
                  ┌──────────────────────────────┐
                  │      App Launch / Login      │
                  └──────────────┬───────────────┘
                                 │
                 hasCompletedOnboarding == true?
                                 │
                 ┌───────────────┴───────────────┐
            No (false)                      Yes (true)
                 │                               │
                 ▼                               ▼
    ┌──────────────────────────┐        ┌──────────────────┐
    │ OnboardingCoordinatorView│        │   HomepageView   │
    │  (4 Interactive Steps)   │        │ (Learning Path)  │
    └────────────┬─────────────┘        └──────────────────┘
                 │
        Complete Mini-Lesson
                 │
                 ▼
    ┌──────────────────────────┐
    │ Set flag & celebrate Day1│
    │  hasCompletedOnboarding  │
    └──────────────────────────┘
```

### 2.2 Persistence Layer (`UserSettingsStore.swift`)
We extend `UserSettingsStore` with dedicated properties backed by `UserDefaults`:
- `hasCompletedOnboarding: Bool`: Tracks completion of onboarding (default: `false`).
- `selectedGoalDeckId: String`: Selected primary topic deck ID (e.g., `"deck_daily"`, default: `"deck_daily"`).
- `assessedCefrLevel: String`: Self-assessed CEFR rating (e.g., `"A1"`, `"A2"`, `"B1"`, `"B2"`, `"C1"`, default: `"A1"`).
- Reuses existing stored properties:
  - `dailyGoalCount: Int` (default: 10, choices: 5, 10, 15, 20).
  - `notificationTimeInterval: Double` (default: 72,000s = 20:00).
  - `isNotificationEnabled: Bool`.

### 2.3 Roadmap Initialization Domain Service (`InitializeUserRoadmapUseCase`)
- **Protocol**: `InitializeUserRoadmapUseCaseProtocol`
- **Dependencies**: `VocabularyDataSourceProtocol`, `StageProgressRepositoryProtocol`, `UserSettingsStore`.
- **Logic**:
  1. Save `selectedGoalDeckId`, `assessedCefrLevel`, `dailyGoalCount`, and `notificationTimeInterval` to `UserSettingsStore`.
  2. Fetch all stages belonging to the selected deck.
  3. **Auto-Unlock Algorithm**:
     - If `assessedCefrLevel` is `"A1"` or `"A2"`: User starts at Stage 1 of the chosen deck (`isCompleted = false`).
     - If `assessedCefrLevel` is `"B1"`, `"B2"`, or `"C1"`: Preceding foundational stages (e.g., Stage 1) are marked completed in `StageProgressRepository` with `progressFraction = 1.0`, `isCompleted = true`, and `score = 100`, positioning the user's active node directly at their proficiency level on `CraftLearningPath`.
  4. Schedule daily notification at the selected hour if push permission is granted.
  5. Fetch and return the first 3 starter words from the active starting stage for the immediate mini-lesson.

---

## 3. Step-by-Step UI Design & Component Specifications

All screens strictly adhere to `CraftUIKit` design tokens (`CraftTheme`, `CraftColor`, `CraftSpacingTokens`, `CraftRadiusTokens`) with **zero hardcoded strings** and **zero raw color literals**.

### 3.1 Common Onboarding Header & Shell
- **Back Button**: `CraftIconButton(icon: .chevronLeft)` (hidden on Step 1).
- **Progress Indicator**: `CraftStepProgressIndicator(totalSteps: 4, currentStep: stepIndex, counterStyle: .phrase)`.
- **Skip Action**: Prominent text button in top-right corner invoking default configuration and immediate transition.

---

### 3.2 Step 1: Motivation & Focus Goal (`OnboardingGoalStepView`)
- **Header**:
  - Title: `app.onboarding.goal.title` ("What is your English goal? / Mục tiêu học tiếng Anh của bạn là gì?")
  - Subtitle: `app.onboarding.goal.subtitle` ("We'll tailor vocabulary you actually use in daily life.")
- **Options (4 x `CraftChoiceCard`)**:
  1. `deck_daily`: SF Symbol `bubble.left.and.bubble.right` — Daily Communication (*Giao tiếp hằng ngày*)
  2. `deck_business`: SF Symbol `briefcase` — Career & Business (*Công sở & Sự nghiệp*)
  3. `deck_academic`: SF Symbol `graduationcap` — Academic & Exam Prep (*Học thuật & IELTS/TOEIC*)
  4. `deck_tech`: SF Symbol `cpu` — Technology & Innovation (*Công nghệ & AI*)
- **Footer**: `CraftButton` (variant: `.primary`, disabled until 1 card is selected).

---

### 3.3 Step 2: Baseline Proficiency Assessment (`OnboardingProficiencyStepView`)
- **Header**:
  - Title: `app.onboarding.level.title` ("What is your current level? / Trình độ tiếng Anh hiện tại của bạn?")
  - Subtitle: `app.onboarding.level.subtitle` ("You can always change your starting point later in Settings.")
- **Options (4 x `CraftChoiceCard`)**:
  1. **A1 (Beginner)**: "Starting fresh with everyday fundamentals / Mới bắt đầu, muốn học từ nền tảng vững chắc"
  2. **A2 (Elementary)**: "Know simple words, but hesitate when speaking / Biết từ đơn giản, nhưng phản xạ còn ngập ngừng"
  3. **B1/B2 (Intermediate)**: "Comfortable in routine situations, want fluency / Tự tin giao tiếp quen thuộc, muốn mở rộng phản xạ"
  4. **C1 (Advanced)**: "Aiming for nuanced, academic, and native expressions / Muốn làm chủ từ vựng chuyên sâu và tự nhiên"
- **Footer**: `CraftButton` (variant: `.primary`).

---

### 3.4 Step 3: Daily Habit & Push Reminders (`OnboardingHabitStepView`)
- **Header**:
  - Title: `app.onboarding.habit.title` ("How many words do you want to learn each day?")
  - Subtitle: `app.onboarding.habit.subtitle` ("Small daily steps lead to massive long-term fluency.")
- **Word Goal Cards (4 x `CraftChoiceCard`)**:
  - **5 words/day**: Casual (5 min/day)
  - **10 words/day**: Steady (10 min/day) — Marked with `CraftBadge("Popular")`
  - **15 words/day**: Dedicated (15 min/day)
  - **20 words/day**: Intensive (20 min/day)
- **Reminder Time Selector**:
  - Morning (`08:00`) | Noon (`12:30`) | Evening (`20:00` - default)
- **Footer**: `CraftButton` (variant: `.primary`, requests notification permission when advancing).

---

### 3.5 Step 4: Roadmap Generation & Reveal (`OnboardingRoadmapRevealStepView`)
- **Phase A (~1.5s Calculation Animation)**:
  - Visual: `CraftPulsingAuraRing` with rhythmic state transitions.
  - Cycling captions:
    - *"Analyzing your goal & current level..."*
    - *"Personalizing your optimal vocabulary syllabus..."*
    - *"Your custom roadmap is ready!"*
- **Phase B (Personalized Roadmap Summary Card)**:
  - Enclosed in `CraftCard`:
    - Header: Target Deck badge (`CraftBadge` with deck color) + Deck Title.
    - Projection Metric: *"At 10 words/day, you will master 300 core words in 30 days!"*
    - Starting Milestone: Stage 1 (or advanced stage unlocked according to CEFR level).
- **Primary CTA**:
  - `CraftButton(variant: .primary, size: .lg)`: *"Start First Lesson (1 min) / Bắt đầu bài học đầu tiên"*
  - Direct transition to the First Win mini-lesson.

---

## 4. Immediate First Win & Day-1 Streak Celebration

### 4.1 Mini-Lesson Flow (`OnboardingFirstLessonView`)
- Presents 3 core words from the user's initial stage.
- Each word features:
  1. Pronunciation audio via `TTSService`.
  2. Lemma, IPA transcription, and contextual definition.
  3. Single quick-recall reflex question (using `CraftChoiceCard`).
- Clean, fast, frictionless experience completed in ~60 seconds.

### 4.2 Celebration Modal (`OnboardingCelebrationSheet`)
- Triggered immediately after completing word 3:
  - Particle burst via `.craftConfetti(isTriggered: true)`.
  - Display `CraftStreakBadge` with **"Day 1 Streak Unlocked 🔥"**.
  - Encouragement text: *"You just crushed your first lesson! Keep the momentum going tomorrow."*
  - CTA Button: *"Explore My Learning Path"* $\rightarrow$ Sets `hasCompletedOnboarding = true`, dismisses sheet, and reveals `HomepageView` with the active node ready.

---

## 5. Edge Cases & Resilience

1. **User Taps "Skip"**:
   - Persists safe default: `deck_daily`, `A1`, `dailyGoalCount = 10`, `notificationTimeInterval = 72000` (20:00).
   - Sets `hasCompletedOnboarding = true` immediately and opens `HomepageView`.
2. **Notification Permission Denied**:
   - If user denies system notification alert, the app saves `isNotificationEnabled = false` and continues without interruption.
3. **Dataset Failure / Empty Stage**:
   - If fetching words for the selected stage fails, fallback instantly to bundled safe words (`ReflexBlitzWordItem.defaultStarterWords`).
4. **App Killed During Onboarding**:
   - Because `hasCompletedOnboarding` is only persisted upon mini-lesson completion or skip, restarting the app cleanly resumes the onboarding flow.

---

## 6. Localization Taxonomy (`Localizable.xcstrings`)

All keys live in `VocabCraftApp/Resources/Localizable.xcstrings` under `app.onboarding.*` with 100% English and Vietnamese parity:

| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `app.onboarding.common.skip` | "Skip" | "Bỏ qua" |
| `app.onboarding.common.continue` | "Continue" | "Tiếp tục" |
| `app.onboarding.goal.title` | "What is your learning goal?" | "Mục tiêu học tiếng Anh của bạn là gì?" |
| `app.onboarding.goal.subtitle` | "We will curate vocabulary matching your exact focus." | "Chúng tôi sẽ tập trung vào nhóm từ vựng bạn thực sự cần." |
| `app.onboarding.level.title` | "What is your current English level?" | "Trình độ tiếng Anh hiện tại của bạn?" |
| `app.onboarding.level.subtitle` | "Don't worry, you can adjust this anytime in Settings." | "Đừng lo, bạn có thể điều chỉnh lại bất cứ lúc nào trong Cài đặt." |
| `app.onboarding.habit.title` | "Set your daily learning goal" | "Mỗi ngày bạn muốn học bao nhiêu từ?" |
| `app.onboarding.habit.subtitle` | "Consistency is the secret to fluent vocabulary recall." | "Học đều đặn mỗi ngày là bí quyết ghi nhớ phản xạ lâu dài." |
| `app.onboarding.reveal.analyzing` | "Analyzing your profile..." | "Đang phân tích mục tiêu & trình độ..." |
| `app.onboarding.reveal.curating` | "Curating personalized vocabulary decks..." | "Đang cá nhân hóa bộ từ vựng tối ưu..." |
| `app.onboarding.reveal.ready` | "Your learning path is ready!" | "Lộ trình hoàn hảo của bạn đã sẵn sàng!" |
| `app.onboarding.reveal.cta` | "Start First Lesson (1 min)" | "Bắt đầu bài học đầu tiên (1 phút)" |
| `app.onboarding.celebration.title` | "Day 1 Streak Unlocked!" | "🔥 Đã kích hoạt Streak Ngày 1!" |
| `app.onboarding.celebration.cta` | "Explore My Learning Path" | "Khám phá lộ trình học" |

---

## 7. Verification & Quality Gates

1. **Swift Testing Framework (`@Test`)**:
   - `InitializeUserRoadmapUseCaseTests`: Test level mapping, stage unlocking for B1/B2 vs A1, and persistence in `UserSettingsStore`.
   - `OnboardingViewModelTests`: Validate step navigation transitions (0 $\rightarrow$ 3), back tracking, skip defaults, and selection mutations.
2. **Bilingual Parity**:
   - Automated scan verifying matching key counts and format specifier compatibility between `en` and `vi`.
3. **Xcode Build & Linting**:
   - Zero compiler warnings.
   - 100% clean `swiftlint` check.
