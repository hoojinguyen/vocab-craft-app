# Lesson Learning Flow Design Specification

**Author**: Antigravity  
**Date**: 2026-09-02  
**Status**: Approved / Ready for Implementation  
**Target Module**: `VocabCraftApp` / `CraftUIKit`  

---

## 1. Overview & Problem Statement

### 1.1 Background & Current Problem
In the current implementation of VocabCraft:
- Tapping a lesson node in `CraftLearningPath` opens `CraftLessonDetailSheet`.
- Tapping "Start Lesson" (`onStartLesson`) currently navigates directly to the **Reflex Blitz** screen (`ReflexBlitzView`).
- Learners are presented with `ReflexBlitzModeSelectionView` where they are forced to manually pick one drill mode (Multiple Choice, Listening, Speaking, or Typing) and rushed through a high-speed countdown timer (4.5s - 7.5s/word).

### 1.2 The Pedagogical Gap
1. **No Discovery Phase**: Learners are tested on unfamiliar words without prior introduction to pronunciation, IPA, definitions, or sentence context.
2. **Manual Mode Selection in Structured Curriculum**: A curriculum learning path must systematically guide learners through multi-sensory cognitive stages (listening, reading, speaking, spelling) rather than asking learners to pick a single mode.
3. **Reflex Blitz vs Lesson Learning**: Reflex Blitz is an unguided, high-intensity speed drill for review, whereas Lesson Learning is a guided acquisition and mastery journey.

---

## 2. Core Architecture & Pedagogical Model

### 2.1 The 3-Stage Scaffolded Micro-Cycles Model
Lessons are broken down into **Micro-Cycles** (chunks of 3–4 words) to minimize cognitive load:

```
[Lesson Start]
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│ MICRO-CYCLE 1 (Words 1..3)                                  │
│  1. Discovery Phase: Tactile 3D cards with TTS & context    │
│  2. Practice Phase: 4-mode interactive scaffolded exercises │
│     (Listening ➔ Multiple Choice ➔ Speaking ➔ Typing)       │
│  3. Re-queue on Mistake: Immediate retry of weak items     │
└─────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│ MICRO-CYCLE 2 (Words 4..6)                                  │
│  1. Discovery Phase (Words 4..6)                            │
│  2. Practice Phase (Words 4..6)                             │
│  3. Re-queue on Mistake                                     │
└─────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│ LESSON SUMMARY & MASTERY COMPLETION                         │
│  - Star Rating (1..3 stars) based on mistake count          │
│  - XP Earned (+25 XP standard, +80 XP checkpoint)           │
│  - Mastered Words List with audio replay                    │
│  - Stage Progress Saved & Next Path Node Unlocked           │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 The Mastery Loop (Untimed & Re-queue)
- **Untimed / Relaxed**: No timeout failure countdown during Lesson Learning. Learners have ample time to listen, speak, and type.
- **Re-queue on Mistake**: If a learner makes an error during practice, the system explains the correct answer and appends a single retry of the question to the end of the micro-cycle queue, downgraded to multiple choice and capped at max 1 retry per word to avoid infinite loops.
- **Star Scoring Policy**:
  - 0 errors: **3 Stars (Mastery)**
  - 1–2 errors: **2 Stars (Proficient)**
  - >2 errors: **1 Star (Completed)**

---

## 3. Detailed Component & UI/UX Design

### 3.1 Step Hierarchy (`LessonStep`)
```swift
public enum LessonStep: Identifiable, Sendable {
    case discovery(word: TopicWordDTO, index: Int, totalInCycle: Int)
    case exercise(item: LessonExerciseItem)
    case summary(summary: LessonSummaryModel)

    public var id: String {
        switch self {
        case .discovery(let word, let index, _):
            return "discovery-\(word.id)-\(index)"
        case .exercise(let item):
            return "exercise-\(item.id)"
        case .summary:
            return "summary"
        }
    }
}
```

### 3.2 View Architecture
1. **`LessonLearningView`**:
   - Navigation & Top Bar: Close button `(X)` with confirmation alert, animated `CraftProgressBar` tracking total steps.
   - Dynamic Content Container: Smooth transitions between `LessonDiscoveryCardView`, Exercise Views, and `LessonSummaryView`.
2. **`LessonDiscoveryCardView`**:
   - Uses `CraftCard` / `CraftFlipCard` styling.
   - Pronunciation header with auto-play TTS `CraftSpeakerButton` and IPA.
   - Part of Speech and CEFR Level badges using `CraftBadge`.
   - Vietnamese definition + English context example with highlighted target word and Vietnamese sentence translation.
   - Primary `CraftButton` for "Tiếp tục" (Continue).
3. **Interactive Mode Views (Reused & Configured for Untimed Lesson Practice)**:
   - `ReflexListeningModeView`: Audio stimulus ➔ 4 `CraftChoiceCard` options.
   - `ReflexMultipleChoiceModeView`: Cloze sentence + Vietnamese meaning ➔ 4 `CraftChoiceCard` options.
   - `ReflexSpeakingModeView`: Meaning + Cloze prompt ➔ `CraftVoiceMatchCard` with "Không tiện nói lúc này" (Skip to non-speaking mode) fallback.
   - `ReflexTypingModeView`: Meaning + Cloze prompt ➔ `CraftTextField` with keyboard auto-focus and return key submission.
4. **`CraftFeedbackSheet` (docked bottom sheet)**:
   - Screen-level sheet (`.tactile3D`) flush to the bottom edge, appearing upon answer submission.
   - Correct: Green accent, celebratory sound effect, "Tiếp tục" button.
   - Incorrect: Red accent, incorrect sound effect, displays correct answer + brief explanation, "Tiếp tục" button (re-queues question).
5. **`LessonSummaryView`**:
   - Hero star animation + `craftConfetti` for 3-star runs.
   - XP badge and accuracy metrics.
   - Mastered words list with audio replay buttons.
   - Primary `CraftButton("Hoàn thành bài học")` returning to `HomepageView`.

---

## 4. Data Flow & Integration

### 4.1 Integration with `HomepageView`
- In `HomepageView.swift`, update `startLesson(for node: LessonNodeModel)` to present `LessonLearningView` (via sheet or full-screen modal) initialized with `LessonLearningViewModel(stageId: node.id, deckId: deckId)`.
- On lesson completion:
  1. Calls `CompleteLessonUseCase.execute(stageId:deckId:stars:weakWordIds:progressFraction:1.0)`.
  2. Reloads learning path (`viewModel.loadLearningPath()`).
  3. Triggers haptic success, confetti, and completion toast on Homepage.

### 4.2 State & Dependency Injection
- `LessonLearningViewModel` is `@Observable` and `@MainActor`.
- Injected with:
  - `DatasetEngine` (or `VocabularyDataSourceProtocol`) for words and distractors.
  - `CompleteLessonUseCaseProtocol` for stage progress persistence.
  - `TextToSpeechProtocol` for speech synthesis.
  - `ReflexSpeechEngineProtocol` for spoken pronunciation matching.
  - `SoundEffectServiceProtocol` for haptics and audio feedback.

---

## 5. Localization & CraftUIKit Standards

### 5.1 Zero Hardcoded Strings
All strings are declared in `VocabCraftApp/Resources/Localizable.xcstrings` and accessed via `AppStrings.Lesson.*`:
- `app.lesson.discovery.title`
- `app.lesson.discovery.continue_action`
- `app.lesson.exercise.check_action`
- `app.lesson.feedback.correct`
- `app.lesson.feedback.incorrect`
- `app.lesson.feedback.correct_answer_format`
- `app.lesson.summary.title`
- `app.lesson.summary.xp_earned_format`
- `app.lesson.summary.mastered_words`
- `app.lesson.exit_alert.title`
- `app.lesson.exit_alert.message`
- `app.lesson.exit_alert.confirm`
- `app.lesson.exit_alert.cancel`

### 5.2 Zero Raw Styling
- Strict conformance to `CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, and `CraftShadowTokens`.

---

## 6. Verification & Test Plan

1. **Unit Tests**:
   - `LessonPlanGeneratorTests`: Verify chunking into micro-cycles, mode assignment, distractor generation.
   - `LessonLearningViewModelTests`: Verify step transitions, re-queue mechanism on incorrect answers, star calculation, speech skip fallback, and completion payload.
2. **UI & Theme Verification**:
   - Test on iOS Simulator for Light Mode, Dark Mode, VoiceOver accessibility, and Dynamic Type.
3. **Zero Warnings & SwiftLint Quality Gate**:
   - Run `swift test` and `swiftlint` to ensure 0 errors and 0 warnings.
