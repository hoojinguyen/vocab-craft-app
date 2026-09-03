# Lesson Learning Path Refinement — Design Specification

> Comprehensive architectural and UX/UI refinement for the interactive Lesson Learning Path session in VocabCraft.

---

## 1. Background & Goals

During hands-on testing of the Lesson Learning Path (`LessonLearningView`, `LessonLearningViewModel`, `LessonDiscoveryCardView`, `LessonExerciseContainerView`, and `LessonFeedbackBannerView`), 10 key functional and UX issues were identified:

1. **Flashcard TTS Lifecycle**: Discovery flashcard only speaks the first word; subsequent words do not auto-play when pressing "Continue".
2. **Tactile 3D Styling Parity**: Primary action buttons (e.g. Continue CTA) look flat or outlined rather than matching the 3D Tactile depth of Cards.
3. **Feedback Bottom Sheet Fragmentation**: `LessonFeedbackBannerView` is an ad-hoc custom view rather than reusing the standardized `CraftFeedbackSheet` from `CraftUIKit`.
4. **Speaking Modality Malfunction**: Speech recognition fails because `startSession` is called synchronously on every word before permissions resolve, and prompt UI lacks cloze masking.
5. **Multiple Choice Answer Leaking**: The question sentence reveals and highlights the target answer inside the question text instead of masking it with a cloze blank `[ _________ ]`.
6. **Listening Mode Flakiness & Missing Replay**: Audio fails to trigger across consecutive listening steps due to missing view identity, and the front face lacks a replay button and hint support.
7. **Missing Skip Button for Typing**: Typing exercises lack a "Skip / Bỏ qua" escape hatch when the user does not know the answer.
8. **Infinite Retry Loop**: Erroneous answers are endlessly requeued in the same difficult mode, trapping users indefinitely.
9. **On-Demand Hint System**: Exercises lack an active hint mechanism to assist stuck users without leaking answers upfront.
10. **Design System & Theme Discipline**: Inconsistent styling across containers, buttons, and sheets.

---

## 2. Core Architecture & Design Decisions

### 2.1 Smart Requeue & Mode Downgrading (Decision 1 - Option A)
Instead of infinite retries of the same modality, `LessonLearningViewModel` adopts a structured 2-tier learning safety net:

```
[Challenge Step]
       │
       ▼
 ┌───────────┐
 │ Is Correct?│──► (Yes) ──► Advance & Reward XP
 └─────┬─────┘
       │ (No / Skip)
       ▼
 ┌──────────────────────────────────────────────┐
 │ Attempt Count per Word == 1 ?                 │
 └─────┬──────────────────────────────────┬─────┘
       │ (Yes - 1st Failure)              │ (No - 2nd Failure)
       ▼                                  ▼
 ┌─────────────────────────┐        ┌────────────────────────────────┐
 │ Active Mode (.typing /  │        │ Mark as `weakWordIds`           │
 │ .speaking)?             │        │ Show correct answer feedback   │
 └─────┬─────────────┬─────┘        │ NO further requeue (Proceed)   │
       │ (Yes)       │ (No)         └────────────────────────────────┘
       ▼             ▼
 ┌───────────┐ ┌───────────────┐
 │ Downgrade │ │ Requeue once  │
 │ to MCQ /  │ │ with fresh    │
 │ Listening │ │ distractors   │
 └───────────┘ └───────────────┘
```

- **First Failure on Active Mode (`.typing` / `.speaking`)**: Downgrades to a passive recognition mode (`.multipleChoice` or `.listening`), pulls fresh distractors, and appends to the end of the queue.
- **First Failure on Passive Mode (`.multipleChoice` / `.listening`)**: Requeues once with reshuffled options.
- **Second Failure (Max 1 Retry)**: The word is recorded in `weakWordIds` for review in the Summary screen and Spaced Repetition (SRS), feedback displays the full solution, and the flow proceeds without getting stuck.

### 2.2 On-Demand Manual Hint System (Decision 2 - Active Hint)
Users can actively request assistance by tapping a dedicated "Gợi ý" (Hint) button in the exercise header or prompt:
- **Tap 1 (Hint Stage 1)**: Displays Part of Speech badge (e.g. `noun`, `verb`) and first-letter length mask `[ h _ _ _ _ ]`.
- **Tap 2 (Hint Stage 2 - MCQ only)**: Eliminates 1 incorrect distractor (50/50 assistance).

---

## 3. Component & Layer Modifications

### 3.1 `LessonLearningViewModel.swift`
- **Speech Engine Lifecycle**:
  - `startSession()` is called **once** on session entry in `LessonLearningView.onAppear`.
  - `beginWord()` / `endWord()` are called per speaking step.
  - `stopSession()` is called when exiting the lesson.
- **State Properties**:
  - `attemptCountPerWord: [Int64: Int]`
  - `hintStage: Int` (0 = default, 1 = masked hint, 2 = 50/50 eliminated option)
  - `eliminatedOptionId: String?`
- **Actions**:
  - `requestHint()`: Advances hint stage for the current step and applies cloze/distractor masking.
  - `skipCurrentExercise()`: Marks attempt as skipped/incorrect, triggers `CraftFeedbackSheet`, and applies smart requeue.

### 3.2 `LessonDiscoveryCardView.swift` & `LessonLearningView.swift`
- **Audio Lifecycle**: Replace `.onAppear` with `.task(id: word.id) { onPlayAudio() }` and assign `.id("discovery-\(word.id)")` in `LessonLearningView` so TTS triggers for each new flashcard.
- **Tactile Styling**: Update Continue button to `CraftButton(..., variant: .tactile, style: .tactile3D)`.

### 3.3 `LessonExerciseContainerView.swift`
- **Identity & Audio**: Use `.id("exercise-\(item.id)")` and `.task(id: item.id)` so step transitions cleanly reset state and auto-play listening audio.
- **Cloze Sentence Generation**:
  - Construct `ReflexClozeStageSet` for each item using `ReflexHintMaskGenerator.generateStages(lemma: item.word.lemma, sentenceEn: item.word.exampleEn, pos: item.word.pos)`.
  - Pass `clozeStages` and `hintStage` into child mode views so the stimulus prompt displays `[ _________ ]` instead of the raw lemma.
- **Skip CTA**: Add `CraftButton(AppStrings.ReflexBlitz.skip, iconName: "forward.fill", variant: .outline, style: .outlined)` for `.typing` and `.speaking` modes.
- **Active Hint CTA**: Add a subtle "Gợi ý" / Hint button in the top navigation or stimulus bar.

### 3.4 `CraftFeedbackSheet` Adoption (Replacing `LessonFeedbackBannerView`)
- Remove `LessonFeedbackBannerView.swift`.
- Embed `CraftFeedbackSheet` in `LessonLearningView` / `LessonExerciseContainerView`:
  ```swift
  CraftFeedbackSheet(
      status: viewModel.lastAttemptCorrect ? .success : .error,
      title: viewModel.lastAttemptCorrect ? AppStrings.ReflexBlitz.correctTitleText : AppStrings.ReflexBlitz.incorrectTitleText,
      message: viewModel.lastAttemptCorrect ? nil : AppStrings.Lesson.correctAnswerFormat(item.word.lemma),
      actionTitle: AppStrings.ReflexBlitz.continueCTAText,
      streakCount: nil,
      style: .tactile3D,
      onContinue: {
          viewModel.advanceStep()
      }
  )
  ```

### 3.5 `ReflexListeningModeView.swift` & `ReflexSpeakingModeView.swift`
- In `ReflexListeningModeView`: Add a front-face `CraftSpeakerButton` allowing immediate manual audio replay before answering.
- In `ReflexSpeakingModeView`: Ensure continuous waveform state and live transcription badge are wired with `viewModel.speechState` and `viewModel.liveTranscript`.

---

## 4. File Structure Changes

```
VocabCraftApp/
├── Domain/
│   ├── Entities/
│   │   └── LessonPlanModels.swift                  [MODIFY] (Add hint & requeue metadata)
│   └── UseCases/
│       └── LessonPlanGenerator.swift               [MODIFY] (Generate cloze stages)
├── Features/
│   ├── Lesson/
│   │   ├── ViewModels/
│   │   │   └── LessonLearningViewModel.swift       [MODIFY] (Speech session, requeue, hints)
│   │   └── Views/
│   │       ├── LessonLearningView.swift            [MODIFY] (View IDs, CraftFeedbackSheet, unified theme)
│   │       └── Components/
│   │           ├── LessonDiscoveryCardView.swift   [MODIFY] (Task audio lifecycle, tactile button)
│   │           ├── LessonExerciseContainerView.swift [MODIFY] (Cloze masking, hint CTA, skip button)
│   │           └── LessonFeedbackBannerView.swift  [DELETE] (Replaced by CraftFeedbackSheet)
│   └── Reflex/Core/Components/Modes/
│       └── ReflexListeningModeView.swift           [MODIFY] (Front face speaker button)
└── Resources/
    └── Localizable.xcstrings                       [MODIFY] (Ensure 100% bilingual keys)
```

---

## 5. Verification Plan

### 5.1 Automated Unit Tests
Run existing and expanded test suites:
- `swift test --filter LessonLearningViewModelTests`
- `swift test --filter LessonPlanGeneratorTests`
- `swift test --filter ReflexDrillableTests`
- `swift test --filter LocalizationTests`

Key test cases:
1. **Mode Downgrading**: Verifies 1st failure on `.typing` requeues as `.multipleChoice`.
2. **Max 1 Retry Guarantee**: Verifies 2nd failure marks `weakWordIds` and terminates retry queue.
3. **Cloze Masking**: Verifies `extractTemplateParts` renders `[ _________ ]` and never leaks target lemma in prompt text.
4. **TTS Audio Lifecycle**: Verifies consecutive flashcard transitions invoke speech synthesizer.
5. **Hint Progression**: Verifies tapping hint advances from `hintStage 0` to `hintStage 1` (mask) to `hintStage 2` (50/50 distractor elimination).

### 5.2 Manual UI & Functional Verification on Simulator
- Verify audio auto-plays on flashcard 1, 2, and 3 when hitting Continue.
- Verify Continue CTA button renders with full Tactile 3D bottom lip.
- Verify Multiple Choice questions show `[ _________ ]` and do not reveal the answer.
- Verify "Gợi ý" (Hint) button reveals POS and first letter.
- Verify Typing mode has a functional "Bỏ qua" button.
- Verify Speaking mode activates microphone and recognizes spoken words.
- Verify `CraftFeedbackSheet` slides up from bottom with correct status color and sound chime.
