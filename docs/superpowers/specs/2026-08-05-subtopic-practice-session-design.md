# Design Spec: Sub-topic Practice Session Screen (Màn hình Học & Luyện tập Chặng - Redesign V4)

- **Date**: 2026-08-05
- **Feature**: Sub-topic Practice Session, Minimal 3D Flip Flashcard & Ergonomic UI Redesign V4
- **Module**: `VocabCraftApp/Features/Vocabulary`
- **Status**: Approved by User

---

## 1. Overview & UI/UX Design Principles

The **Sub-topic Practice Session Screen** (`SubTopicStudySessionView`) provides a gamified, high-contrast, one-handed ergonomic learning experience on iOS.

### Core UX Principles (V4 Upgrade):
1. **High-Contrast Premium Light Mode Aesthetics**: Clean Slate-50 background (`Color.vocabCanvas`), pure white cards (`Color.vocabSurfaceCard`), crisp ink typography (`Color.vocabInk`), and zero washed-out/dull tones.
2. **Minimalist Flashcard**:
   - **Front Face**: Only Word (large title) ➔ IPA Phonetic ➔ Pure Icon Audio Button (`speaker.wave.2.fill` in a circle). No clutter, no instruction labels.
   - **Back Face**: Mint Green / Coral Red border. Word ➔ IPA ➔ Circle Audio Icon ➔ `[Part of speech] Vietnamese Definition` ➔ Highlighted Context Example (*"Ví dụ:"*).
3. **Re-architected Top Header Bar**:
   - Close Button (`xmark`) in a 32pt circular pill.
   - 10-Segmented Progress Bar.
   - **`⚡ +XP` Badge** directly on the top header bar next to the progress bar (replacing streak counter).
4. **Thumb-Zone Ergonomics**:
   - Quiz options grid and action buttons positioned in the lower 55% of the screen for single-handed thumb accessibility.
   - Nudge/bounce tactile feedback (`scaleEffect(0.98)` on press).
   - Quiz section title: *"Chọn đáp án đúng:"* with subtle attempt indicator (`Lần 1/2`).
5. **Clean Bottom Toast Feedback**:
   - Toast banner displays concise status (`✓ Chính xác! (+10 XP)` or `✕ Chưa chính xác (-5 XP)`).
   - Action button maintains simple, actionable text (`Tiếp tục ➔`).
6. **10-Word Dataset**: Sub-topic nodes supply 10 sample words per node for rich progress tracking.

---

## 2. Component Structure & Data Flow

```
TopicDeckDetailView
  │ (Tap "Luyện tập riêng chặng này" / Hero CTA)
  ▼
SubTopicStudySessionView
  ├── Top Header Bar (Close Circle, 10-Segment Progress, ⚡ XP Badge)
  │
  ├── ReflexFlipCardView (3D Y-axis Flip)
  │     ├── FRONT: Word ➔ IPA ➔ Icon Audio Button
  │     └── BACK: Word ➔ IPA ➔ Icon Audio Button ➔ [partOfSpeech] Meaning ➔ Highlighted Example
  │
  ├── Thumb-Zone Quiz Grid ("Chọn đáp án đúng:", 4 Options, Tactile press 0.98)
  │
  └── Bottom Feedback Sheet (Concise Toast Banner + "Tiếp tục ➔" Button)
       │
       ▼ (All 10 words completed)
SubTopicSessionSummaryView
  ├── CAEmitterLayer ProMotion 120Hz GPU Confetti Particles
  ├── SwiftUI Sensory Haptics (.sensoryFeedback(.success))
  ├── SF Symbol Animation (🏆 .symbolEffect(.bounce))
  └── Actions: "CHUYỂN CHẶNG TIẾP THEO" | "Ôn lại chặng này"
```

---

## 3. Detailed Data Models & Dataset Extensions

### Sample 10-Word Subtopic Dataset (`TopicDeckModels.swift`):
- `Automation` ("Sự tự động hóa")
- `Algorithm` ("Thuật toán")
- `Ecosystem` ("Hệ sinh thái")
- `Biodiversity` ("Đa dạng sinh học")
- `Sustainability` ("Sự bền vững")
- `Innovation` ("Sự đổi mới sáng tạo")
- `Infrastructure` ("Hạ tầng")
- `Artificial` ("Nhân tạo")
- `Intelligence` ("Trí tuệ")
- `Architecture` ("Kiến trúc")

### Highlighting Target Word in Examples:
Target words in example sentences are dynamically formatted or bolded/highlighted with a soft yellow background tag (`Color.vocabYellowHighlight`).

---

## 4. File Structure & Target Files

- `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift` (10-word dataset & model fields)
- `VocabCraftApp/Features/Vocabulary/Models/SubTopicSessionEngine.swift` (XP & attempt formatting fix)
- `VocabCraftApp/Features/Vocabulary/Views/ReflexFlipCardView.swift` (Minimal Front face & Back face with highlighted example)
- `VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift` (Header XP badge, 10 segments, clean toast, thumb ergonomics)
- `VocabCraftApp/Features/Vocabulary/Views/SubTopicSessionSummaryView.swift` (Completion view with CAEmitterLayer confetti & Sensory Haptics)
- `VocabCraftApp/Features/Vocabulary/Views/TopicDeckDetailView.swift` (Navigation presentation)

---

## 5. Verification & Acceptance Criteria

1. XP text on status bar shows clean formatting (`+10 XP`, `-5 XP`), no `+-5` strings.
2. Distractor options generated do not produce near-identical choices.
3. Flashcard front face displays only Word, IPA text (Row 2), and Circle Audio Icon (Row 3).
4. Flashcard back face highlights target word in the example sentence cleanly.
5. Quiz section header displays *"Chọn đáp án đúng:"* with `Lần 1/2` tag.
6. Progress bar renders 10 segments for 10-word dataset.
7. Bottom action button uses simple *"Tiếp tục ➔"* text with top toast banner showing feedback.
8. 74+ unit tests pass cleanly, `xcodebuild build` succeeds, and app runs on iPhone Simulator.
