# Design Spec: Sub-topic Practice Session Screen (Màn hình Học & Luyện tập Chặng)

- **Date**: 2026-08-05
- **Feature**: Sub-topic Practice Session & Interactive 3D Flip Flashcard Flow
- **Module**: `VocabCraftApp/Features/Vocabulary`
- **Status**: Approved by User

---

## 1. Overview & Purpose

The **Sub-topic Practice Session Screen** (`SubTopicStudySessionView`) is the core interactive learning view launched when a user taps *"Luyện tập riêng chặng này"* or *"⚡ Bắt đầu học Chặng X"* from the Topic Deck Detail screen.

It implements an engaging **Gamified Micro-Learning Loop** combining a 2-sided 3D Flipping Flashcard (`ReflexFlipCardView`), a 2-attempt penalty multiple-choice quiz challenge, Apple Native FX (Core Animation `CAEmitterLayer` ProMotion particle confetti & Sensory Haptics), and automatic synchronization of mastered words to the user's Personal Vocabulary Vault.

---

## 2. User Journey & Core Interactive Flow

```
SubTopicPreviewSheet / TopicDeckDetailView
       │
       ▼ (Tap "Luyện tập riêng chặng này" / "Bắt đầu học Chặng X")
SubTopicStudySessionView
  ├── Top Header (Exit xmark, Segmented Progress Bar, 🔥 Combo Counter)
  │
  ├── Interactive 3D Flip Flashcard (ReflexFlipCardView)
  │     ├── FRONT: English Word, Phonetic IPA, Audio Button (🔊)
  │     └── BACK: Vietnamese Definition, Part of Speech, Context Example Sentence
  │
  ├── Quiz Options Grid (4 Multiple Choice Options, 2 Attempts Left "2/2")
  │     ├── Attempt 1 Correct ──► 3D Flip Card to BACK (Green Theme), +10 XP, Auto-Sync Vault
  │     ├── Attempt 1 Wrong   ──► Shake animation, Hint, "1/2" attempts left (+5 XP potential)
  │     └── Attempt 2 Wrong   ──► 3D Flip Card to BACK (Red Theme), -5 XP, Move to Retry Queue
  │
  └── Bottom Feedback Toast Sheet ──► Tap "TỪ TIẾP THEO ➔"
       │
       ▼ (All words in session completed)
SubTopicSessionSummaryView
  ├── Apple Native CAEmitterLayer GPU Confetti
  ├── SwiftUI Sensory Haptics (.sensoryFeedback(.success))
  ├── SF Symbol Animations (🏆 .symbolEffect(.bounce))
  └── Actions: "🔄 Ôn lại chặng này" | "🚀 Chuyển sang Chặng tiếp theo ➔"
```

---

## 3. Detailed Component Architecture

### 3.1 Design System, SF Symbols & Dual Theme Standards
- **SF Symbols Compliance**: 100% Apple standard SF Symbols via `Image(systemName:)`:
  - Exit: `xmark`
  - Audio: `speaker.wave.2.fill`
  - Selection states: `checkmark.circle.fill`, `xmark.circle.fill`
  - Streak & Trophy: `flame.fill`, `trophy.fill`, `star.fill`
  - Actions: `arrow.right`, `arrow.counterclockwise`
- **Dual Theme Support (Light & Dark Mode)**:
  - Canvas & Surfaces: `Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabSurfaceSoft`.
  - Text Ink: `Color.vocabInk`, `Color.vocabBody`, `Color.vocabMuted`.
  - Accents: `Color.vocabMint`, `Color.vocabPeach`, `Color.vocabCoral`, `Color.vocabLavender`.
  - Hairlines: `Color.vocabHairline`.

### 3.2 3D Flip Flashcard Component (`ReflexFlipCardView`)
- **Front Face**:
  - English word title in bold typography (`title-lg`).
  - Audio pill with `speaker.wave.2.fill` icon & IPA phonetic pronunciation.
  - Prompt text: *"Chọn nghĩa tiếng Việt chính xác bên dưới"*.
- **Back Face**:
  - Vietnamese definition in bold accent color.
  - Context sentence card with target word bolded (e.g. *"The **algorithm** processes data in real time."*).
- **3D Rotation**: Smooth Y-axis 3D flip animation using SwiftUI `.rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))`.

### 3.3 Game Engine & Penalty Logic (`SubTopicSessionEngine`)
- **Max Attempts**: 2 attempts per word.
- **Scoring**:
  - 1st attempt correct: **+10 XP**, `comboCount += 1`, Card flips 3D to Back (Green accent).
  - 1st attempt incorrect: `attemptsLeft = 1`, option turns red, user can try 1 more time for **+5 XP**.
  - 2nd attempt incorrect: **-5 XP**, `comboCount = 0`, Card flips 3D to Back (Red accent), word appended to `retryQueue` to be reviewed at the end of the session.

### 3.4 Celebration & Summary View (`SubTopicSessionSummaryView`)
- **Apple Native Effects**:
  - **`CAEmitterLayer` Particle Engine**: GPU-accelerated confetti running at 120Hz ProMotion directly via Core Animation without webviews or GIFs.
  - **Sensory Feedback**: `UIImpactFeedbackGenerator` / `.sensoryFeedback(.success, trigger: ...)` for tactile satisfaction.
  - **Symbol Effects**: `trophy.fill` animated with `.symbolEffect(.bounce)`.

---

## 4. File Structure & Changes

- `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift` (Update models with session state & retry queue)
- `VocabCraftApp/Features/Vocabulary/Models/SubTopicSessionEngine.swift` (New session state machine)
- `VocabCraftApp/Features/Vocabulary/Views/ReflexFlipCardView.swift` (New 3D flip card component)
- `VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift` (New main study session view)
- `VocabCraftApp/Features/Vocabulary/Views/SubTopicSessionSummaryView.swift` (New summary view with native FX)

---

## 5. Verification & Acceptance Criteria

1. Tapping *"Luyện tập riêng chặng này"* opens `SubTopicStudySessionView`.
2. Flashcard starts on **Front Face** showing only Word + IPA + Audio button.
3. Answering correctly flips card 3D to **Back Face** (Green theme) showing Vietnamese definition + Example sentence, awards **+10 XP**, and auto-syncs word to Personal Vocab Vault.
4. Answering incorrectly twice flips card 3D to **Back Face** (Red theme), deducts **-5 XP**, and adds word to retry queue.
5. Finishing the session presents `SubTopicSessionSummaryView` with `CAEmitterLayer` confetti and sensory haptics.
6. Build and unit tests pass cleanly with 100% SF Symbols and Light/Dark mode token compliance.
