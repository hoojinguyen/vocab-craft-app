# Design Spec: Topic Deck Detail & Roadmap Workflow (Bộ từ chủ đề)

- **Date**: 2026-08-05
- **Feature**: Topic Deck Detail View & Game-like Roadmap Workflow
- **Module**: `VocabCraftApp/Features/Vocabulary`
- **Status**: Approved by User

---

## 1. Overview & Purpose

The **Topic Deck Detail View** provides an engaging, structured learning journey when a user taps on any Topic Deck card (e.g., *IELTS Academic 500*, *Oxford 3000*, *TOEIC Business*) from the Vocabulary tab.

Instead of a flat table or raw list, the experience adopts a **Game-like Timeline Stepper (Roadmap)** layout. Words are grouped into logical Sub-topics / Units. Users progress sequentially through milestones while enjoying auto-sync capabilities with their Personal Vocabulary Vault.

---

## 2. User Journey & Workflow

```
VocabularyView (Topic Decks Tab)
       │
       ▼ (Tap Topic Deck Card)
TopicDeckDetailView
  ├── Top Header (Title, Level Badge, Progress %, CTA "Bắt đầu học Chặng X")
  ├── Game-like Timeline Stepper (Vertical Node Roadmap)
  │     ├── Completed Nodes (✓)
  │     ├── Active Node (Highlighted, Pulsing border, Progress %)
  │     └── Locked Nodes (🔒)
  │
  ├── Tap Active CTA ──► Launch ReflexDrillView (Study session for active unit)
  │
  └── Tap any Node ──► Open SubTopicPreviewSheet (Bottom Sheet)
                            ├── List of Words (English, Phonetic, Vietnamese, Status)
                            ├── Manual Toggle "+ Kho cá nhân"
                            └── Button "Luyện tập riêng chặng này" ──► Launch ReflexDrillView
```

---

## 3. UI/UX Architecture & Component Breakdown

### 3.1 Top Header Banner
- **Title & Metadata**: Displays Deck Title, Icon, Word Count, and Difficulty Level Badge (e.g., `B2-C1`).
- **Progress Overview**:
  - Percentage completed bar (e.g., `65%`).
  - Stat line: `325 / 500 từ đã thuộc • Tự động đồng bộ Kho cá nhân`.
- **Primary Hero Action Button**:
  - Gradient CTA button: `"⚡ BẮT ĐẦU HỌC CHẶNG 3 (CÔNG NGHỆ)"`.
  - Single tap directly launches the drill/study session for the active unlocked node.

### 3.2 Game-like Timeline Stepper (Roadmap Path)
- **Visual Design**:
  - Vertical connecting line linking sequential nodes.
  - Distinct node states:
    - **`.completed`**: Green/Mint circular icon (`✓`), 100% completion label.
    - **`.active`**: Gold/Amber pulsing circular icon with node number, active glow, completion ratio (e.g., `12/25 từ • 48%`).
    - **`.locked`**: Dark slate circular icon with lock emblem (`🔒`), opacity 0.6.
- **Interactivity**:
  - Tapping any node opens the `SubTopicPreviewSheet`.

### 3.3 SubTopic Preview Bottom Sheet (`SubTopicPreviewSheet`)
- **Header**: Sub-topic title, icon, total word count, progress.
- **Word List Accordion / Rows**:
  - English word, phonetic pronunciation, Vietnamese meaning.
  - Status indicators (`✓ Đã thuộc`, `⚡ Đang học`, `○ Chưa học`).
  - Bookmark button (`🔖`) to manually toggle inclusion in Personal Vocab Vault.
- **Action**: `"Luyện tập riêng chặng này"` button to start a targeted drill session.

---

## 4. Data Model & Auto-Sync Engine

### 4.1 Data Models (`TopicDeckModels.swift`)

```swift
public enum NodeState: String, Codable, Sendable {
    case completed
    case active
    case locked
}

public struct SubTopicNode: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let iconName: String
    public let totalWords: Int
    public let learnedWords: Int
    public let state: NodeState
    public let words: [TopicWord]
}

public struct TopicWord: Identifiable, Codable, Sendable {
    public let id: String
    public let english: String
    public let phonetic: String
    public let vietnamese: String
    public var isMastered: Bool
    public var isSavedToPersonalVault: Bool
}
```

### 4.2 Auto-Sync Specification
- **Trigger**: When a user completes a word during a Topic Deck drill or marks it as learned in the preview sheet.
- **Behavior**:
  - System automatically adds the word to `UserVocabularyStore` (Personal Vocab Vault).
  - Word receives metadata tag: `sourceDeckId: String` and initial SRS review intervals.
  - Updates total word counts and mastery stats in both Topic Deck progress and overall profile stats.

---

## 5. File Structure & Changes

- `VocabCraftApp/Features/Vocabulary/Views/TopicDeckDetailView.swift` (New Detail Screen & Stepper Roadmap)
- `VocabCraftApp/Features/Vocabulary/Views/SubTopicPreviewSheet.swift` (New Bottom Sheet for Node Words)
- `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift` (Updated models for SubTopics & Word status)
- `VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift` (Updated selection callback to push detail view)

---

## 6. Verification & Acceptance Criteria

1. Tapping any Topic Deck card in `TopicDecksGridView` navigates cleanly to `TopicDeckDetailView`.
2. `TopicDeckDetailView` displays the Hero CTA and Timeline Stepper with correct node states (`.completed`, `.active`, `.locked`).
3. Tapping the Hero CTA launches a study session for the active node.
4. Tapping a node presents `SubTopicPreviewSheet` with word details and status.
5. Learning words in a Topic Deck updates progress and auto-syncs to the user's Personal Vocab Vault.
