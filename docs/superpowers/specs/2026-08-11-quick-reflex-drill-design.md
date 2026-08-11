# Design Specification: Quick Reflex Drill ("Luyện phản xạ từ này")

Date: 2026-08-11  
Status: Approved  

## Overview
Feature "Luyện phản xạ từ này" (Quick Reflex Drill for a single word) allows users to launch an instant 3-step targeted micro-drill directly from any word accordion card in `VocabularyView`. Upon completion, user performance updates SRS mastery levels with visual feedback (sparkles/completion card), returning the user seamlessly to the vocabulary list.

---

## 1. User Experience & Interaction Flow

1. **Trigger**: User taps the `⚡ Luyện phản xạ từ này` button on an expanded `WordAccordionCard` for a specific word (e.g., *Ephemeral*).
2. **Sheet Launch**: A modal sheet (`QuickReflexDrillSheetView`) presents over the current view.
3. **3-Step Micro Drill**:
   - **Step 1 - Pronunciation & Speech**: Read aloud the example sentence containing the target word using Speech Recognition (STT).
   - **Step 2 - Speed Meaning Match**: Quick multi-choice selection for the Vietnamese definition under time pressure.
   - **Step 3 - Fill-in-the-Blank**: Complete the context sentence missing the target word.
4. **Completion Card & SRS Update**:
   - Displays average reaction time (in ms) and performance rating (*Phản xạ xuất sắc* / *Tốt*).
   - Evaluates response via `EvaluateSRSUseCaseProtocol` to update mastery level stars.
   - Triggers celebratory sparkle effect.
5. **Dismissal**: Tapping "Hoàn tất" closes the sheet and updates the word's SRS stars instantly on `VocabularyView`.

---

## 2. Architecture & Component Design

### 2.1 Data Models (`QuickDrillStep.swift`)
```swift
public enum QuickDrillStepType: Equatable {
    case pronunciation // Step 1: Speak example sentence
    case fastMeaning   // Step 2: Select Vietnamese definition
    case fillInBlank   // Step 3: Complete context sentence with target lemma
}

public struct QuickDrillStep: Identifiable, Equatable {
    public let id: Int
    public let type: QuickDrillStepType
    public let promptText: String
    public let targetText: String
    public let options: [String]
    public let sentenceWithGap: String?
}
```

### 2.2 ViewModel (`QuickReflexDrillViewModel.swift`)
- **Dependencies**:
  - `targetWord`: `WordItem`
  - `allWords`: `[WordItem]` (for generating realistic distractors)
  - `ttsService`: `TextToSpeechProtocol`
  - `sttService`: `SpeechRecognitionProtocol`
  - `evaluateSRSUseCase`: `EvaluateSRSUseCaseProtocol?`
- **State**:
  - `currentStepIndex`: Int (0, 1, 2 for steps; 3 for completion screen)
  - `steps`: `[QuickDrillStep]`
  - `elapsedTimeMs`: Int
  - `isCorrect`: Bool
  - `stepSuccessCount`: Int
  - `srsResult`: `SRSResult?`
  - `isCompleted`: Bool
  - `triggerSparkle`: Bool
- **Methods**:
  - `generateSteps()`: Synthesizes 3 steps from target word data and distractors from allWords.
  - `handleVoiceRecording()`: Starts/stops speech recognition for Step 1.
  - `submitAnswer(_ answer: String)`: Validates current step answer, records time, moves to next step or calculates final SRS result.
  - `finishDrill()`: Evaluates cumulative performance with `evaluateSRSUseCase` and updates DB/state.

### 2.3 Presentation View (`QuickReflexDrillSheetView.swift`)
- **Header**: Compact word badge + Progress bar (3 segments).
- **Body**: Step-specific content card:
  - Step 1: Big mic button + target sentence + real-time STT feedback.
  - Step 2: Target lemma + 4 definition option buttons.
  - Step 3: Sentence with blank + 4 lemma option buttons.
- **Completion Card**: Summary statistics, SRS level increment badge, sparkle animations, and "Hoàn tất" button.

---

## 3. Integration Plan

- **`VocabularyView` Integration**:
  - Add `@State private var selectedDrillWord: WordItem? = nil`
  - Bind `onDrillTap` in `WordAccordionCard` to set `selectedDrillWord = item`.
  - Attach `.sheet(item: $selectedDrillWord)` presenting `QuickReflexDrillSheetView(word: word, allWords: wordItems, onComplete: { updatedMastery in ... })`.
  - Upon completion callback, update local `wordItems` state to reflect updated star rating.

---

## 4. Verification & Testing

- **Unit Tests**:
  - `QuickReflexDrillViewModelTests`: Verify 3-step generation, answer validation, time tracking, and SRS evaluation logic.
- **Manual QA**:
  - Test voice recognition in Step 1.
  - Test option selection in Steps 2 & 3.
  - Confirm sheet presentation, completion card, and star update on `VocabularyView`.
