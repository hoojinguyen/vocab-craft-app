# Vocabulary Screen Neumorphic-Bento Design Spec

> **Status**: APPROVED
> **Target**: `VocabCraftApp/Features/Vocabulary/`
> **Rule Compliance**: Enforces `.gemini/rules/ui-design-system.md` (Dynamic Semantic Tokens, 44pt minimum touch targets, 48pt tab bar items, `BentoCardButtonStyle`).

---

## 1. Overview & Architecture

`VocabularyView` is the primary hub for managing personal vocabulary and discovering topic-based word collections. It employs a two-tab Segmented Control layout within a sticky header navigation container.

```
┌──────────────────────────────────────────────────────────┐
│ [🔍 Tra cứu từ vựng...]                   [🎙️ 44pt]    │  Sticky Search
├──────────────────────────────────────────────────────────┤
│ [Tất cả] [Cần ôn ⚡] [Đã thuộc ⭐5] [A1-A2] [B1-B2]        │  Filter Pills
├──────────────────────────────────────────────────────────┤
│ ( Kho Từ Cá Nhân )   |   ( Bộ Từ Theo Chủ Đề )            │  Segmented Switch
├──────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────────────┐ │
│ │ 1.420 Từ        85% Trí Nhớ        24 Cần Ôn        │ │  Summary Bento
│ └──────────────────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Ephemeral  /ɪˈfem.ər.əl/  n.  [B2] [⭐⭐⭐⭐★ 4/5]    │ │  Accordion Card
│ │ Nghĩa: Phù du, chóng phai                              │ │  (Collapsed)
│ └──────────────────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Resilience  /rɪˈzɪl.jəns/ n.  [C1] [⭐⭐⭐⭐⭐ 5/5]    │ │  Accordion Card
│ │ Nghĩa: Khả năng phục hồi                               │ │  (Expanded)
│ │ 🔊 [Audio TTS 44pt]  "Her resilience was remarkable"  │ │
│ │ [⚡ Luyện phản xạ từ này (44pt)]                        │ │
│ └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Component Specifications

### 2.1 Navigation & Header (`VocabularyHeaderView`)
- **Search Bar**: Reuses `MobileSearchView` with binding `$searchText` and voice search callback.
- **Filter Bar**: Scrollable horizontal `HStack` of capsule pills (`vocabSurfaceCard` fill, 1.5pt `vocabHairline` stroke, 44pt hit target).
  - Selected state: `vocabInk` fill, `vocabCanvas` text.
  - Unselected state: `vocabSurfaceCard` fill, `vocabInk` text.
- **Segmented Control Switch**: Floating pill container (`vocabSurfaceCard` background, 20pt corner radius). Active tab capsule uses `vocabInk.opacity(0.08)`. Tab hit targets: 44pt height.

### 2.2 Summary Bento Strip (`VocabularySummaryCard`)
- Container: 20pt continuous corner radius, `vocabSurfaceCard` background, 1.5pt `vocabHairline` stroke, 6pt shadow.
- Displays 3 metrics in an `HStack` with divider lines (`vocabHairline`):
  1. **Tổng từ**: `1.420` (18pt Bold `vocabInk`) + Label (11pt `vocabMuted`).
  2. **Trí nhớ SRS**: `85%` (18pt Bold `vocabMint`) + Label (11pt `vocabMuted`).
  3. **Cần ôn**: `24` (18pt Bold `vocabCoral`) + Label (11pt `vocabMuted`).

### 2.3 Expandable Word Accordion Card (`WordAccordionCard`)
- Container: `vocabSurfaceCard` background, 20pt corner radius, 1.5pt `vocabHairline` stroke.
- **Header Row (Collapsed State)**:
  - Left: Lemma text (17pt Bold `vocabInk`), Phonetic string (13pt Italic `vocabMuted`), POS tag (`n.`, `v.`, `adj.` in 11pt Bold `vocabMuted`).
  - Right: CEFR Badge (`vocabMint.opacity(0.18)` fill for A1-A2, `vocabPeach.opacity(0.18)` for B1-B2, `vocabLavender.opacity(0.18)` for C1-C2) + 5-step SRS indicator gauge.
- **Body Content (Expanded State - Triggered via Tap Animation)**:
  - Audio TTS Button: 44x44 pt circle (`vocabHeroAccent.opacity(0.12)` fill) with `speaker.wave.2.fill` icon (`vocabHeroAccent`).
  - Definition: Vietnamese translation string (14pt Medium `vocabInk`).
  - Example Sentence: English sentence with target word highlighted in bold `vocabHeroAccent` + Vietnamese translation beneath (13pt Regular `vocabMuted`).
  - Quick Action Button: `"⚡ Luyện phản xạ từ này"` (Touch target 44pt, `BentoCardButtonStyle` spring interaction).

### 2.4 Topic Decks Grid (`TopicDecksGridView`)
- 2-Column Bento Grid (`LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())])`).
- Card layout: 20pt corner radius, `vocabSurfaceCard` fill, 1.5pt `vocabHairline` stroke.
  - Topic Icon / Badge: 10pt corner radius pill (`vocabLavender.opacity(0.20)`).
  - Deck Title: `IELTS Academic`, `TOEIC Business`, `Oxford 3000`, `Travel & Food`.
  - Progress bar: 4pt height with `vocabMint` fill indicating % completed.

---

## 3. Data Models & SwiftData Binding

`VocabularyViewModel` interfaces with `UserWordProgress` (SwiftData):

```swift
public struct WordItem: Identifiable, Equatable {
    public let id: Int64
    public let lemma: String
    public let phonetic: String
    public let pos: String
    public let definition: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let cefrLevel: String // "A1", "A2", "B1", "B2", "C1", "C2"
    public var masteryLevel: Int // 0..5
    public var nextReviewDate: Date
}
```

---

## 4. UI Design System Rule Enforcement Matrix

| Element | Requirement | Token / Property |
| :--- | :--- | :--- |
| **Canvas Background** | Dynamic Light/Dark | `Color.vocabCanvas` |
| **Card Fill** | Dynamic Light/Dark | `Color.vocabSurfaceCard` |
| **Border Hairline** | 1.5pt stroke | `Color.vocabHairline` |
| **Search/Card Icons** | High contrast in Dark Mode | `Color.vocabHeroAccent` |
| **Min Touch Targets** | All interactive controls | 44x44 pt (`.contentShape(Rectangle())`) |
| **Button Interactions**| Tactile Spring | `BentoCardButtonStyle` |
