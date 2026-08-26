# VocabCraft v1 — Feature Design Spec

## Overview

VocabCraft là ứng dụng học từ vựng tiếng Anh cho người Việt, sử dụng phương pháp phản xạ nhanh (Reflex Blitz) để giúp người dùng ghi nhớ lâu dài. App v1 tập trung vào core learning loop: Learning Path → Reflex Blitz → Kho Từ, với 5 tabs navigation.

Mục tiêu không phải đọc đúng chính xác 100% IPA, mà là **đọc được từ đó lên, phản xạ nhanh, nhớ lâu**.

---

## Navigation Structure — 5 Tabs

| Tab | Feature | Description |
|---|---|---|
| **Home** | Learning Path | Duolingo-style linear path, structured learning |
| **Kho Từ** | Vocabulary Vault | Flat list + filters, review learned words |
| **Reflex Blitz** | Free Practice | Pick 1 of 4 modes, smart priority queue, cross-topic |
| **AI Tutor** | Placeholder | "Coming Soon" screen |
| **Settings** | Settings | Basic app settings |

---

## Core Learning Loop

```
Home (Learning Path)
    │
    │  tap node → detail sheet → "Start Lesson"
    ▼
Mixed Reflex Session (auto-mix 4 modes, 2 rounds)
    │
    │  complete session
    ▼
Session Summary (stars 1-3, accuracy, weak words)
    │
    ├──→ Update node state (completed, unlock next)
    └──→ Weak words pushed to Kho Từ (needsReview = true)

Reflex Tab (Free Practice)
    │
    │  pick 1 mode → smart priority queue words
    ▼
Single-mode Session → Summary → Update word mastery

Kho Từ
    │
    │  filter words → "Ôn luyện" CTA
    ▼
Mixed Review Session → Summary → Update mastery
```

---

## Feature 1: Home — Learning Path

### Concept

Replace the current bento dashboard with a Duolingo-style linear path using `CraftLearningPath` from CraftUIKit. Each node represents a SubTopic containing vocabulary words. Users progress linearly through nodes, unlocking the next upon completion.

### Data Mapping

```
TopicDeck (SQLite)        →  LessonSection (CraftUIKit)
SubTopicNode (SQLite)     →  LessonNodeModel (CraftUIKit)
TopicWord (SQLite)        →  ReflexBlitzWordItem (drill session)
UserStageProgress (SwiftData)  →  node state (locked/active/completed)
```

### Screen Layout

- **HeaderView** (top): greeting, streak, daily progress — kept from current design
- **CraftLearningPath** (main content): scrollable vertical path with sections and nodes
- **Auto-scroll**: to active node on appear (300ms delay, spring animation)

### Node States & Transitions

```
locked → active          (when previous node completed)
active → completed       (when user completes 1 session)
```

- First node of Section 1 is always `active` for new users
- Node kind `.checkpoint` (hexagon) at the end of each section — review all section words, must complete to unlock next section
- Node kind `.treasureChest` — bonus XP milestone reward

### Stars Calculation

| Accuracy | Stars | Speed Rating |
|---|---|---|
| ≥ 95% | ⭐⭐⭐ | ⚡️ Reflex Master |
| ≥ 80% | ⭐⭐ | 🔥 Swift Reflex |
| < 80% | ⭐ | 🌱 Steady Learner |

### Tap Flow

1. User taps active/completed node
2. `CraftLessonDetailSheet` presents (bottom sheet, `.fraction(0.48)`)
3. Shows: 3D icon, title, status badge, metrics (+XP, duration, word count), objectives
4. CTA: "Bắt đầu bài học" / "Tiếp tục" / "Ôn lại"
5. Tap CTA → dismiss sheet → navigate to Mixed Reflex Session

---

## Feature 2: Mixed Reflex Session (from Learning Path)

### Concept

When launching from a Learning Path node, the session **auto-mixes all 4 modes** in a structured 2-round system. No mode selection screen.

### 2-Round System

| Round | Purpose | Modes | Rationale |
|---|---|---|---|
| **Round 1: Nhận diện** | Receptive recognition | `multipleChoice` + `listening` | Easier — user selects/listens, doesn't produce |
| **Round 2: Sản xuất** | Productive recall | `typing` + `speaking` | Harder — user must type/speak the word |

- Within each round, modes are **alternated** (MC → Listening → MC → ...) for variety
- Each word appears **exactly 2 times** total (1 receptive + 1 productive)
- Word order in Round 2 is **reshuffled** from Round 1

### Time Limits (unchanged from current)

| Mode | Time Limit |
|---|---|
| Multiple Choice | 4.5s |
| Listening | 5.5s |
| Speaking | 6.0s |
| Typing | 7.5s |

### Batching for Large SubTopics

- **Batch size**: 10-15 words per session
- If SubTopic > 15 words → split into multiple sessions
- Node shows `inProgress` state with progress bar until all words drilled
- Example: 25 words → Session 1 (13 words) → Session 2 (12 words) → Node completed

### UI Additions

- **Round indicator** at top of card: "Round 1/2 · Nhận diện" + progress fraction
- Everything else (card UI, countdown, combo, hint) — unchanged from current `ReflexBlitzCardView`

### Session Complete

- Navigate to `ReflexBlitzSummaryView` (existing)
- Show: stars, accuracy, avg response time, max combo, XP earned, weak words
- CTA: "Tiếp tục" → back to Learning Path (node now shows completed state)

---

## Feature 3: Reflex Blitz Tab — Free Practice

### Concept

Standalone free practice mode. User picks 1 of 4 modes and drills words sourced from the Smart Priority Queue. Words are mixed cross-topic, prioritizing weak words and current learning path progress.

### Distinction from Learning Path Session

| Aspect | Learning Path Session | Reflex Tab Session |
|---|---|---|
| Word source | SubTopic-specific | Smart Priority Queue (cross-topic) |
| Mode | Auto-mix 4 modes (2 rounds) | User picks 1 mode |
| Session size | All SubTopic words (batched 10-15) | Fixed 10 words |
| Progression | Updates node state on path | Updates word mastery only |
| Purpose | Structured learning — learn new | Free drill — reflex practice |

### Mode Selection Screen

Keep existing `ReflexBlitzModeSelectionView` with 4 mode cards:
- 🗣️ Luyện nói (Speaking)
- ⌨️ Gõ từ (Typing)
- 🎯 Trắc nghiệm (Multiple Choice)
- 👂 Phản xạ nghe (Listening)

Add quick stats section below: words practiced this week, words needing review, avg response time.

### Smart Priority Queue Algorithm

```
Input:  allLearnedWords, currentLearningPathTopic, userWordProgress
Output: orderedQueue (10 words)

Tier 1 — Weak Words (up to 5):
  Filter: needsReview == true OR (mistakeCount > 0 AND !isMastered) OR correctStreak == 0
  Sort: mistakeCount DESC, lastReviewDate ASC

Tier 2 — Current Topic Words (up to 5):
  Filter: words from active/recently-completed SubTopic on Learning Path, !isMastered
  Exclude: already in Tier 1
  Sort: consecutiveCorrectStreak ASC

Tier 3 — SRS Due Words (up to 5):
  Filter: nextReviewDate <= now, !isMastered
  Exclude: already in Tier 1-2
  Sort: nextReviewDate ASC (most overdue first)

Tier 4 — Random Learned (fill remaining):
  Filter: totalReviews > 0
  Exclude: already in Tier 1-3
  Fallback: starter words if insufficient
  Shuffle: random

Final: shuffle entire queue to mix tiers
Target: 10 words per session
```

---

## Feature 4: Kho Từ — Vocabulary Vault

### Concept

Flat list of all learned words with filter tabs and a prominent "Ôn luyện" CTA. Users can browse, search, bookmark, and review vocabulary.

### Screen Layout

- **Summary header**: total words learned, total mastered
- **Search bar**: filter by lemma
- **Filter tabs**: Tất cả · Chưa thuộc · Đã thuộc · ❤️ Yêu thích
- **Word list**: scrollable flat list with word cards
- **Floating CTA**: "⚡ Ôn luyện (N từ cần ôn)"

### Filter Logic

| Filter | Predicate |
|---|---|
| Tất cả | `totalReviews > 0` (appeared in any session) |
| Chưa thuộc | `isMastered == false` |
| Đã thuộc | `isMastered == true` |
| Yêu thích | `isBookmarked == true` |

### Word Card (list row)

Each row shows:
- **lemma** + **part of speech** + **IPA**
- **definitionVi** (1 line, truncated)
- **Mastery stars** (0-3) based on `consecutiveCorrectStreak`
- **Status icon**: ❤️ bookmarked · ⚠️ needsReview · ✅ mastered

### Tap → Word Detail

Expandable or sheet showing:
- Full word info: lemma, pos, IPA, audio button, bookmark toggle
- Definitions: Vietnamese + English
- Example sentences: EN + VI
- Progress: mastery stars, correct streak, practiced modes, source deck/stage

### "Ôn luyện" Flow

1. Tap floating CTA
2. Collect words matching current active filter
3. Launch Mixed Reflex Session (auto-mix 4 modes, same as Learning Path)
4. Session size: up to 15 words (batch if more)
5. Complete → summary → update mastery → back to Kho Từ

---

## Feature 5: AI Tutor — Placeholder

Simple `ContentUnavailableView`-style screen with:
- Robot emoji icon
- "AI Tutor đang được phát triển" title
- Feature preview bullet points
- "Sắp ra mắt 🚀" badge

No business logic. Tab icon displays normally on tab bar.

---

## Feature 6: Settings

Keep existing `SettingsView` with sections:
- **Giao diện**: Dark mode toggle (🌙/☀️/Auto), App language (VN/EN)
- **Âm thanh**: Auto-pronunciation toggle, Sound effects toggle
- **Học tập**: Reset learning progress
- **Thông tin**: App version, Rate app, Feedback

No new features for v1.

---

## Technical Architecture

### Files to Keep (unchanged)

- `Packages/CraftUIKit/` — entire design system
- `Packages/SpeechKit/` — speech recognition
- `Core/SRS/SRSEngine.swift` — SM-2 algorithm
- `Domain/Policies/MasteryEvaluationPolicy.swift`
- `Core/Database/SwiftDataModels.swift` — persistence models
- `Core/Database/DatasetEngine.swift` — SQLite data access
- `Domain/Entities/*` — all domain entities
- `Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- `Features/ReflexDrill/Views/ReflexBlitzCardReviewedView.swift`
- `Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`
- `Features/ReflexDrill/Models/ReflexBlitzModels.swift`
- `Features/Homepage/Views/HeaderView.swift`
- `Features/Homepage/Views/LiquidGlassTabBar.swift`

### Files to Enhance

| File | Changes |
|---|---|
| `HomepageView.swift` | Replace bento dashboard → `CraftLearningPath` + HeaderView |
| `HomepageViewModel.swift` | Add: load LessonSections, handle node tap → navigate |
| `ReflexBlitzViewModel.swift` | Add: mixed mode logic (2-round), accept word source param |
| `ReflexBlitzView.swift` | Add: round indicator, mixed mode flow support |
| `PersonalVaultViewModel` | Add: filter tabs logic, "Ôn luyện" launch |
| `VocabularyView.swift` | Refactor → Kho Từ layout (flat list + filters + floating CTA) |
| `AppRouter.swift` / `TabItem` | Change `search` → `aiTutor`, mixed session navigation |
| `FetchPersonalVaultUseCase.swift` | Add filter params |
| `FetchDeckRoadmapUseCase.swift` | Map SubTopicStage → LessonNodeModel with state |

### Files to Create

| File | Purpose | Location |
|---|---|---|
| `LearningPathViewModel.swift` | Load sections, data mapping, progression | `Features/Homepage/ViewModels/` |
| `LearningPathDataMapper.swift` | TopicDeck/SubTopicNode → LessonSection/LessonNodeModel | `Features/Homepage/ViewModels/` |
| `MixedReflexSessionManager.swift` | 2-round orchestration, word batching, mode assignment | `Features/ReflexDrill/Services/` |
| `SmartPriorityQueueService.swift` | 4-tier word selection algorithm | `Domain/Services/` |
| `CompleteLessonUseCase.swift` | Complete node, unlock next, calculate stars | `Domain/UseCases/` |
| `AITutorPlaceholderView.swift` | Coming Soon screen | `Features/AITutor/Views/` |

### Localization

All new UI text must follow the two-layer localization architecture:
- **CraftUIKit keys** (`craft.*`): Already exist for learning path components
- **App keys** (`app.*`): New keys needed for Home, Kho Từ, Reflex, AI Tutor, Settings
- Both `en` and `vi` translations required with `extractionState: "manual"` and `state: "translated"`

---

## Out of v1 Scope

- Authentication / User accounts
- Onboarding flow
- AI Tutor full implementation
- Streak system UI (data layer exists, UI deferred)
- Push notifications / Local reminders
- Cloud sync / Backup
- Social features / Leaderboard
- Advanced SRS analytics dashboard
