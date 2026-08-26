# Feature 1: Home — Learning Path Design Spec

## 1. Executive Summary

Feature 1 transforms the main Home tab of VocabCraft into a structured, linear, Duolingo-style learning journey using `CraftLearningPath` from `CraftUIKit`. 

The core philosophy is **focused vocabulary learning and long-term reflex retention** without distracting gamification gimmicks. The user progresses sequentially through Topic Units, conquering SubTopic nodes, earning mastery stars (⭐⭐⭐), taking Unit Checkpoint review exams, and unlocking subsequent units.

---

## 2. Screen Layout & Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ 👤 Hooji N.    🔥 14 ngày    🎯 75% mục tiêu ngày    🔔     │  <-- Sticky Compact Header
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [ UNIT 1: Giao Tiếp Hằng Ngày ] ────────────── 3/4 chặng    │  <-- Section Banner
│                                                             │
│                       ◯ (Node 1: Thói quen - ⭐⭐⭐)         │
│                      ╱                                      │
│           (Node 2: Cảm xúc - ⭐⭐) ◯                          │
│                                    ╲                        │
│                                     ◯ (Node 3: Ứng xử - ⏳) │  <-- Active Node (Đang học)
│                                    ╱                        │
│                      ⬡ (Node 4: Ôn tập Unit 1 - 🔒)         │  <-- Checkpoint Exam (Lục giác)
│                                                             │
│  [ UNIT 2: Công Sở & Kinh Doanh ] ───────────── 0/4 chặng    │  <-- Locked Section
│                                                             │
│                       ◯ (Node 1: Quản lý - 🔒)              │
│                               ...                           │
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Sticky Compact Header
- **Position:** Fixed at the top of the Home view; does not scroll away with the learning path.
- **Components:**
  - **User Profile Avatar & Radial Ring:** Displays user initials and daily goal progress ring (`dailyGoalProgress`).
  - **Greeting & Daily Goal Text:** E.g., *"Xin chào, Hooji"* and *"Mục tiêu: 75%"*.
  - **Streak Badge:** `CraftStreakBadge` displaying consecutive study streak days (`streakDays`).
  - **Notification Bell:** Quick action button (`bell.fill`) for future notification drawer.

### 2.2 CraftLearningPath View
- **Layout:** Vertical scrollable path utilizing `LazyVStack`, `SerpentineWinding.standard`, and `RowPattern.standard`.
- **Auto-scroll:** On view appear or return from drill session, smoothly scrolls to the `.active` node using `ScrollViewReader` with a 300ms layout stabilization delay and spring animation (`.spring(response: 0.5, dampingFraction: 0.8)`).
- **Unit Section Banner:** Displays Unit Title (e.g. *Unit 1: Giao Tiếp Hằng Ngày*), CEFR Level (*A2 - B1*), and completion fraction (*3/4 bài học*).
- **Standard Nodes (Circle):** Represents discrete SubTopics (~8–12 words each).
- **Checkpoint Exam Nodes (Hexagon ⬡):** Positioned at the end of each Unit, aggregating all words from the Unit for a milestone review test. Passing the checkpoint unlocks the next Unit.
- **Smart Connectors:**
  - `Solid`: Connecting completed nodes.
  - `Breathing`: Flowing pulse animation connecting the last completed node to the `.active` node.
  - `Dashed / Muted`: Connecting upcoming and locked nodes.

---

## 3. Data Mapping & Progression Engine

```
┌────────────────────────────────────────┐       ┌───────────────────────────────────────┐
│     Tầng Dữ Liệu Nội Dung (Master)     │       │       Tầng Lưu Trữ Tiến Độ (Local)    │
│  - TopicDeck (Chủ đề lớn / Unit)       │       │  - UserStageProgress (SwiftData)      │
│  - SubTopicStage (Chủ đề con / Node)   │       │    (isCompleted, score/stars, frac)   │
│  - TopicWord (Danh sách từ vựng)       │       │  - UserWordProgress (SRS / Mastery)   │
└───────────────────┬────────────────────┘       └───────────────────┬───────────────────┘
                    │                                                │
                    └───────────────────────┬────────────────────────┘
                                            ▼
                      ┌───────────────────────────────────────────┐
                      │        LearningPathDataMapper             │
                      │  - Phân bổ trạng thái: locked/active/done │
                      │  - Gắn bài thi Boss Checkpoint cuối Unit  │
                      │  - Tính toán số sao ⭐ và thời lượng      │
                      └─────────────────────┬─────────────────────┘
                                            ▼
                      ┌───────────────────────────────────────────┐
                      │    [LessonSection] & [LessonNodeModel]    │
                      │  (Hiển thị trực tiếp lên CraftUIKit View) │
                      └───────────────────────────────────────────┘
```

### 3.1 Data Entities Mapping
| Source Data Entity | Target Presentation Model | Mapping Logic |
| :--- | :--- | :--- |
| `TopicDeckDTO` / `TopicDeckRecord` | `LessonSection` | Deck title $\rightarrow$ Unit Title, CEFR Level $\rightarrow$ Subtitle, aggregate node progress $\rightarrow$ ProgressValue |
| `SubTopicStageDTO` / `SubTopicNodeRecord` | `LessonNodeModel` (`.standard`) | Stage title, iconName, calculated duration (~2–4 mins), word count |
| Auto-generated Checkpoint | `LessonNodeModel` (`.checkpoint`) | Aggregates all words of the Unit, hexagon shape, crown icon |
| `UserStageProgress` (SwiftData) | `LessonNodeState` & `stars` | `isCompleted == true` $\rightarrow$ `.completed` + stars (1–3); first uncompleted $\rightarrow$ `.active` or `.inProgress`; rest $\rightarrow$ `.locked` |

### 3.2 Linear Progression Algorithm
1. Units and nodes are evaluated sequentially according to their `sortOrder`.
2. For new users, Node 1 of Unit 1 is initialized as `.active`.
3. If Node $i$ has a corresponding `UserStageProgress` record with `isCompleted == true`:
   - State becomes `.completed`.
   - Displays stars (1–3 ⭐) recorded in `UserStageProgress.score`.
4. The first incomplete node encountered in traversal order:
   - If partial progress exists: assigned state `.inProgress` with `progress: progressFraction`.
   - If unattempted: assigned state `.active`.
5. All subsequent nodes after the `.active` node are marked `.locked`.
6. **Cross-Unit Unlock Gate:** Unit $K+1$ remains entirely `.locked` until the `.checkpoint` node of Unit $K$ is `.completed`.

### 3.3 Star Mastery Calculation
After finishing a drill session, stars are calculated based on accuracy:
- **⭐⭐⭐ (3 Stars - Reflex Master):** Accuracy $\ge 95\%$.
- **⭐⭐ (2 Stars - Swift Reflex):** Accuracy $\ge 80\%$.
- **⭐ (1 Star - Steady Learner):** Accuracy $< 80\%$.

### 3.4 Batching & In-Progress Handling
- Standard session size: **8–12 words**.
- If a SubTopic contains $> 12$ words (e.g. 18 words), it is split into 2 batches (9 words + 9 words).
- Completing Part 1 updates `UserStageProgress` with `progressFraction = 0.5` and `isCompleted = false` $\rightarrow$ Node renders `.inProgress` with a 50% circular progress ring and CTA label *"Tiếp tục (50%)"*.
- Completing Part 2 marks `isCompleted = true` and awards mastery stars.

---

## 4. Interactive Tap & Navigation Flow

### 4.1 Node Tap Handling
- **Tapping `.locked` Node:** Triggers warning haptic feedback; bottom sheet CTA is disabled with an informative prompt.
- **Tapping `.active`, `.inProgress`, or `.completed` Node:** Opens `CraftLessonDetailSheet` (`.presentationDetents([.fraction(0.48), .medium, .large])`).

### 4.2 CraftLessonDetailSheet Content
- **Header:** 3D Tactile Node Icon (Circle or Hexagon), SubTopic Title, and Status Badge (*"Đang học"* / *"Đã hoàn thành"* / *"Tiếp tục"*).
- **Metrics Chips:**
  - XP Reward: `+25 XP` (Standard) or `+80 XP` (Checkpoint).
  - Duration: `~3 phút` (Standard) or `~6 phút` (Checkpoint).
  - Vocabulary Count: `10 từ vựng` (Standard) or `35 từ tổng hợp` (Checkpoint).
- **Learning Objectives:**
  1. *Nắm vững N từ vựng trọng tâm.*
  2. *Luyện phản xạ Nhận diện & Sản xuất 2 chiều.*
  3. *Đạt độ chính xác $\ge 80\%$ để qua bài.*
- **Context-Sensitive CTA Button:**
  - `.active`: **"Bắt đầu bài học"** (Primary).
  - `.inProgress`: **"Tiếp tục (50%)"** (Primary).
  - `.completed`: **"Ôn lại bài học (+20 XP)"** (Secondary).

### 4.3 Transition to Drill Session
1. Tapping the sheet CTA dismisses the sheet.
2. `HomepageViewModel` triggers `AppRouter.startReflexSession(words: [ReflexBlitzWordItem], mode: .mixed)`.
3. `LiquidGlassTabBar` is hidden during active drilling.
4. User drills in Mixed Mode:
   - **Round 1: Nhận diện (Receptive):** Alternating `multipleChoice` and `listening`.
   - **Round 2: Sản xuất (Productive):** Alternating `typing` and `speaking`.
5. Upon completion, `ReflexBlitzSummaryView` is displayed with accuracy, response time, stars earned, and weak words.
6. Tapping *"Tiếp tục"* on Summary executes `CompleteLessonUseCase`, returns to Home tab, reloads learning path, and auto-scrolls to the newly unlocked node.

---

## 5. Technical Architecture & File Structure

```
VocabCraftApp/
├── Features/
│   └── Homepage/
│       ├── ViewModels/
│       │   ├── HomepageViewModel.swift       # State orchestrator (@Observable)
│       │   └── LearningPathDataMapper.swift  # DTO to CraftUIKit model mapping
│       └── Views/
│           ├── HomepageView.swift            # Top-level screen (Sticky Header + CraftLearningPath)
│           └── HeaderView.swift              # Sticky Compact Header view
├── Domain/
│   ├── Protocols/
│   │   └── LearningPathRepositoryProtocol.swift
│   └── UseCases/
│       ├── FetchLearningPathUseCase.swift    # Retrieves & constructs full learning path
│       └── CompleteLessonUseCase.swift       # Persists session score, unlocks next node
└── Data/
    └── Repositories/
        └── LearningPathRepositoryImpl.swift  # Implements repository combining DataSource + SwiftData
```

### 5.1 SwiftData Persistence Layer
`UserStageProgress` model is utilized:
```swift
@Model
public final class UserStageProgress {
    @Attribute(.unique) public var stageId: String
    public var deckId: String
    public var isCompleted: Bool
    public var score: Int                 // Stars earned (1-3)
    public var progressFraction: Double   // 0.0 to 1.0 for multi-batch subtopics
    public var completedAt: Date

    public init(stageId: String, deckId: String, isCompleted: Bool = false, score: Int = 0, progressFraction: Double = 0.0, completedAt: Date = Date()) {
        self.stageId = stageId
        self.deckId = deckId
        self.isCompleted = isCompleted
        self.score = score
        self.progressFraction = progressFraction
        self.completedAt = completedAt
    }
}
```

---

## 6. Two-Layer Localization Parity (EN & VI)

All user-facing strings are strictly defined in `VocabCraftApp/Resources/Localizable.xcstrings` under the `app.home.*` namespace with `extractionState: "manual"` and `state: "translated"`.

| Localization Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `app.home.header.greeting_format` | `Hello, %@` | `Xin chào, %@` |
| `app.home.header.daily_goal_format` | `Daily Goal: %lld%%` | `Mục tiêu: %lld%%` |
| `app.home.header.streak_format` | `%lld days` | `%lld ngày` |
| `app.home.section.unit_title_format` | `Unit %lld: %@` | `Unit %lld: %@` |
| `app.home.section.checkpoint_title` | `Unit Review Exam` | `Ôn tập tổng hợp` |
| `app.home.node.words_duration_format`| `%lld words • %lld min` | `%lld từ • %lld phút` |
| `app.home.node.objective_1_format` | `Master %lld core vocabulary words` | `Nắm vững %lld từ vựng trọng tâm` |
| `app.home.node.objective_2` | `Practice 2-way Receptive & Productive recall` | `Luyện phản xạ Nhận diện & Sản xuất 2 chiều` |
| `app.home.node.objective_3` | `Achieve ≥ 80%% accuracy to pass` | `Đạt độ chính xác ≥ 80%% để qua bài` |
| `app.home.node.cta_start` | `Start Lesson` | `Bắt đầu bài học` |
| `app.home.node.cta_continue_format` | `Continue (%lld%%)` | `Tiếp tục (%lld%%)` |
| `app.home.node.cta_review_format` | `Review Lesson (+%lld XP)` | `Ôn lại bài học (+%lld XP)` |
| `app.home.node.locked_hint` | `Complete previous lessons to unlock` | `Hoàn thành các bài học trước để mở khóa` |

---

## 7. Verification & Testing Strategy

### 7.1 Automated Unit Tests
1. **`LearningPathDataMapperTests`:**
   - **Initial User State:** Node 1 of Unit 1 is `.active`; all following nodes are `.locked`.
   - **Single Node Completion:** Completing Node 1 marks it `.completed` with correct stars (1-3) and unlocks Node 2 to `.active`.
   - **Unit Checkpoint Gate:** All standard nodes in Unit 1 completed $\rightarrow$ Checkpoint node becomes `.active`.
   - **Cross-Unit Gate:** Checkpoint completed $\rightarrow$ Unit 1 is 100% completed; Node 1 of Unit 2 unlocks to `.active`.
   - **Batching Progress:** Partial batch completion renders node as `.inProgress` with correct fractional value.
2. **`FetchLearningPathUseCaseTests`:**
   - Verifies combined mapping from `VocabularyDataSourceProtocol` and SwiftData `StageProgressRepository`.
3. **`CompleteLessonUseCaseTests`:**
   - Verifies persistence of `UserStageProgress`, assignment of weak words to `UserWordProgress.needsReview`, and daily goal updates.

### 7.2 UI & Manual Verification
- Verify Sticky Header remains fixed while scrolling through the serpentine path.
- Verify smooth auto-scroll to active node on appear.
- Verify `CraftLessonDetailSheet` presentation, correct metadata chips, and action button transitions.
- Verify dark/light mode appearance and complete bilingual localization strings.
