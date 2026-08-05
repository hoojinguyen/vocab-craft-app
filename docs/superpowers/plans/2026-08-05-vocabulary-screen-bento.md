# Vocabulary Screen Neumorphic-Bento Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Vocabulary Screen (`VocabularyView`) with sticky search & horizontal filter pills, a two-tab Segmented Switch (Kho Từ Cá Nhân vs Bộ Từ Chủ Đề), SRS summary bento bar, expandable word accordion cards with Audio TTS & quick drill actions, and 2-column bento topic decks.

**Architecture:** Create modular views under `VocabCraftApp/Features/Vocabulary/` using dynamic semantic color tokens (`Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabHeroAccent`, `Color.vocabInk`, `Color.vocabMuted`, `Color.vocabHairline`, `Color.vocabCoral`, `Color.vocabMint`, `Color.vocabPeach`, `Color.vocabLavender`) and minimum 44pt touch targets.

**Tech Stack:** Swift, SwiftUI, SwiftData, XCTest

## Global Constraints

- Must follow `.gemini/rules/ui-design-system.md`
- Minimum touch target: 44x44 pt on interactive buttons
- Card surfaces: `Color.vocabSurfaceCard`, corner radius 20pt, stroke `Color.vocabHairline` (1.5pt), shadow `Color.vocabHeroTeal.opacity(0.05)` (radius 6)
- Icon contrast rule: Use `Color.vocabHeroAccent` for icons (never use `vocabHeroTeal` directly on surface cards)
- Tactile spring interactions: `BentoCardButtonStyle` for interactive cards and primary action buttons

---

### Task 1: WordItem Model & Mock Provider

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Models/WordItem.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/VocabularyModelsTests.swift`

**Interfaces:**
- Consumes: Standard Swift `Identifiable`, `Equatable`, `Date`
- Produces: `WordItem` model struct and `WordItem.mockData: [WordItem]`

- [ ] **Step 1: Write failing test for WordItem**

Create `VocabCraftAppTests/Features/Vocabulary/VocabularyModelsTests.swift`:

```swift
import XCTest
@testable import VocabCraftApp

final class VocabularyModelsTests: XCTestCase {
    func testWordItemInitializationAndMockData() {
        let item = WordItem(
            id: 101,
            lemma: "Ephemeral",
            phonetic: "/ɪˈfem.ər.əl/",
            pos: "adj.",
            definition: "Phù du, chóng phai",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy tỏ ra rất ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 4,
            nextReviewDate: Date()
        )
        XCTAssertEqual(item.id, 101)
        XCTAssertEqual(item.lemma, "Ephemeral")
        XCTAssertEqual(item.cefrLevel, "B2")
        XCTAssertEqual(item.masteryLevel, 4)
        XCTAssertFalse(WordItem.mockData.isEmpty)
    }
}
```

- [ ] **Step 2: Run test baseline**

Run: `swift test --filter VocabularyModelsTests`
Expected: FAIL with "cannot find WordItem in scope"

- [ ] **Step 3: Implement WordItem struct**

Create `VocabCraftApp/Features/Vocabulary/Models/WordItem.swift`:

```swift
import Foundation

public struct WordItem: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let lemma: String
    public let phonetic: String
    public let pos: String
    public let definition: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let cefrLevel: String
    public var masteryLevel: Int
    public var nextReviewDate: Date

    public init(
        id: Int64,
        lemma: String,
        phonetic: String,
        pos: String,
        definition: String,
        exampleSentenceEn: String,
        exampleSentenceVi: String,
        cefrLevel: String,
        masteryLevel: Int,
        nextReviewDate: Date = Date()
    ) {
        self.id = id
        self.lemma = lemma
        self.phonetic = phonetic
        self.pos = pos
        self.definition = definition
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = exampleSentenceVi
        self.cefrLevel = cefrLevel
        self.masteryLevel = masteryLevel
        self.nextReviewDate = nextReviewDate
    }

    public static let mockData: [WordItem] = [
        WordItem(
            id: 1,
            lemma: "Ephemeral",
            phonetic: "/ɪˈfem.ər.əl/",
            pos: "adj.",
            definition: "Phù du, chóng phai, kéo dài trong thời gian ngắn",
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy chỉ kéo dài ngắn ngủi.",
            cefrLevel: "B2",
            masteryLevel: 4
        ),
        WordItem(
            id: 2,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "n.",
            definition: "Khả năng phục hồi, tính kiên cường",
            exampleSentenceEn: "Courage and resilience are essential for victory.",
            exampleSentenceVi: "Lòng dũng cảm và sự kiên cường là cần thiết để chiến thắng.",
            cefrLevel: "C1",
            masteryLevel: 5
        ),
        WordItem(
            id: 3,
            lemma: "Meticulous",
            phonetic: "/məˈtɪk.jə.ləs/",
            pos: "adj.",
            definition: "Tỉ mỉ, cẩn thận từng chi tiết",
            exampleSentenceEn: "He paid meticulous attention to detail.",
            exampleSentenceVi: "Anh ấy chú ý tỉ mỉ đến từng chi tiết.",
            cefrLevel: "B2",
            masteryLevel: 2
        )
    ]
}
```

- [ ] **Step 4: Update Xcode project python script**

Update `scripts/generate_xcodeproj.py` to register `WordItem.swift` and `VocabularyModelsTests.swift`.

- [ ] **Step 5: Run tests**

Run: `swift test --filter VocabularyModelsTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Models/WordItem.swift VocabCraftAppTests/Features/Vocabulary/VocabularyModelsTests.swift scripts/generate_xcodeproj.py
git commit -m "feat(vocabulary): add WordItem model and unit tests"
```

---

### Task 2: VocabularySummaryCard Bento Metric Bar

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/VocabularySummaryCard.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift`

**Interfaces:**
- Consumes: `totalWords: Int`, `srsRetentionPercentage: Double`, `dueCount: Int`
- Produces: `VocabularySummaryCard` SwiftUI View

- [ ] **Step 1: Write failing test for VocabularySummaryCard**

Create `VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class VocabularyViewsTests: XCTestCase {
    func testVocabularySummaryCardInstantiation() {
        let view = VocabularySummaryCard(
            totalWords: 1420,
            srsRetentionPercentage: 0.85,
            dueCount: 24
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.totalWords, 1420)
        XCTAssertEqual(view.srsRetentionPercentage, 0.85)
        XCTAssertEqual(view.dueCount, 24)
    }
}
```

- [ ] **Step 2: Run test baseline**

Run: `swift test --filter VocabularyViewsTests`
Expected: FAIL with "cannot find VocabularySummaryCard in scope"

- [ ] **Step 3: Implement VocabularySummaryCard**

Create `VocabCraftApp/Features/Vocabulary/Views/VocabularySummaryCard.swift`:

```swift
import SwiftUI

public struct VocabularySummaryCard: View {
    public let totalWords: Int
    public let srsRetentionPercentage: Double
    public let dueCount: Int

    public init(totalWords: Int, srsRetentionPercentage: Double, dueCount: Int) {
        self.totalWords = totalWords
        self.srsRetentionPercentage = srsRetentionPercentage
        self.dueCount = dueCount
    }

    public var body: some View {
        HStack(spacing: 0) {
            metricItem(title: "\(totalWords)", label: "Tổng số từ", color: .vocabInk)
            
            Divider()
                .frame(height: 32)
                .overlay(Color.vocabHairline)
            
            metricItem(title: "\(Int(srsRetentionPercentage * 100))%", label: "Trí nhớ SRS", color: .vocabMint)
            
            Divider()
                .frame(height: 32)
                .overlay(Color.vocabHairline)
            
            metricItem(title: "\(dueCount)", label: "Cần ôn", color: .vocabCoral)
        }
        .padding(.vertical, 14)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.vocabHeroTeal.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }

    private func metricItem(title: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.vocabMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 4: Update Xcode project python script**

Update `scripts/generate_xcodeproj.py` to add `VocabularySummaryCard.swift` and `VocabularyViewsTests.swift`.

- [ ] **Step 5: Run tests**

Run: `swift test --filter VocabularyViewsTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularySummaryCard.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift scripts/generate_xcodeproj.py
git commit -m "feat(vocabulary): add VocabularySummaryCard bento component"
```

---

### Task 3: WordAccordionCard Component

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/WordAccordionCard.swift`
- Test: Add tests to `VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift`

**Interfaces:**
- Consumes: `item: WordItem`, `isExpanded: Bool`, `onTap: () -> Void`, `onAudioTap: () -> Void`, `onDrillTap: () -> Void`
- Produces: `WordAccordionCard` SwiftUI View

- [ ] **Step 1: Write failing test for WordAccordionCard**

Add test to `VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift`:

```swift
    func testWordAccordionCardExpandedState() {
        let item = WordItem.mockData[0]
        let card = WordAccordionCard(
            item: item,
            isExpanded: true,
            onTap: {},
            onAudioTap: {},
            onDrillTap: {}
        )
        XCTAssertNotNil(card.body)
        XCTAssertTrue(card.isExpanded)
    }
```

- [ ] **Step 2: Run test baseline**

Run: `swift test --filter VocabularyViewsTests`
Expected: FAIL with "cannot find WordAccordionCard in scope"

- [ ] **Step 3: Implement WordAccordionCard**

Create `VocabCraftApp/Features/Vocabulary/Views/WordAccordionCard.swift`:

```swift
import SwiftUI

public struct WordAccordionCard: View {
    public let item: WordItem
    public let isExpanded: Bool
    public let onTap: () -> Void
    public let onAudioTap: () -> Void
    public let onDrillTap: () -> Void

    public init(
        item: WordItem,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        onAudioTap: @escaping () -> Void,
        onDrillTap: @escaping () -> Void
    ) {
        self.item = item
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.onAudioTap = onAudioTap
        self.onDrillTap = onDrillTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row (Tappable)
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(item.lemma)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                            
                            Text(item.pos)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.vocabMuted)
                        }
                        
                        Text(item.phonetic)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundColor(Color.vocabMuted)
                    }
                    
                    Spacer()
                    
                    // CEFR Badge
                    Text(item.cefrLevel)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(cefrColor(item.cefrLevel).opacity(0.18))
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(8)
                    
                    // SRS Mastery Stars
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= item.masteryLevel ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundColor(star <= item.masteryLevel ? Color.vocabMint : Color.vocabMuted.opacity(0.4))
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Collapsed Definition Snippet
            if !isExpanded {
                Text(item.definition)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                    .lineLimit(1)
            }

            // Expanded Detail Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .overlay(Color.vocabHairline)

                    // Definition
                    Text(item.definition)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabInk)

                    // Example Sentence + TTS Audio Button
                    HStack(alignment: .top, spacing: 10) {
                        Button(action: onAudioTap) {
                            ZStack {
                                Circle()
                                    .fill(Color.vocabHeroAccent.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.vocabHeroAccent)
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.exampleSentenceEn)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.vocabInk)
                            Text(item.exampleSentenceVi)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color.vocabMuted)
                        }
                    }

                    // Quick Practice Button
                    Button(action: onDrillTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Luyện phản xạ từ này")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color.vocabInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.vocabPeach.opacity(0.25))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.vocabHairline, lineWidth: 1.5)
        )
        .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func cefrColor(_ level: String) -> Color {
        switch level {
        case "A1", "A2": return Color.vocabMint
        case "B1", "B2": return Color.vocabPeach
        case "C1", "C2": return Color.vocabLavender
        default: return Color.vocabMint
        }
    }
}
```

- [ ] **Step 4: Update generate_xcodeproj.py**

Update `scripts/generate_xcodeproj.py` to register `WordAccordionCard.swift`.

- [ ] **Step 5: Run tests**

Run: `swift test --filter VocabularyViewsTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/WordAccordionCard.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift scripts/generate_xcodeproj.py
git commit -m "feat(vocabulary): add WordAccordionCard expandable component"
```

---

### Task 4: TopicDecksGridView Bento Deck Grid

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift`
- Test: Add tests to `VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift`

**Interfaces:**
- Consumes: `onDeckSelected: (String) -> Void`
- Produces: `TopicDecksGridView` SwiftUI View

- [ ] **Step 1: Write failing test for TopicDecksGridView**

Add test to `VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift`:

```swift
    func testTopicDecksGridViewInstantiation() {
        let view = TopicDecksGridView(onDeckSelected: { _ in })
        XCTAssertNotNil(view.body)
    }
```

- [ ] **Step 2: Run test baseline**

Run: `swift test --filter VocabularyViewsTests`
Expected: FAIL with "cannot find TopicDecksGridView in scope"

- [ ] **Step 3: Implement TopicDecksGridView**

Create `VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift`:

```swift
import SwiftUI

public struct TopicDeck: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let wordCount: Int
    public let completionPercentage: Double
    public let badgeColor: Color
    public let iconName: String
}

public struct TopicDecksGridView: View {
    public let onDeckSelected: (String) -> Void

    private let decks: [TopicDeck] = [
        TopicDeck(id: "1", title: "IELTS Academic", wordCount: 500, completionPercentage: 0.65, badgeColor: .vocabLavender, iconName: "graduationcap.fill"),
        TopicDeck(id: "2", title: "TOEIC Business", wordCount: 450, completionPercentage: 0.40, badgeColor: .vocabPeach, iconName: "briefcase.fill"),
        TopicDeck(id: "3", title: "Oxford 3000", wordCount: 3000, completionPercentage: 0.85, badgeColor: .vocabMint, iconName: "book.closed.fill"),
        TopicDeck(id: "4", title: "Travel & Food", wordCount: 250, completionPercentage: 0.20, badgeColor: .vocabCoral, iconName: "airplane"),
        TopicDeck(id: "5", title: "Công Nghệ & AI", wordCount: 350, completionPercentage: 0.55, badgeColor: .vocabPeach, iconName: "cpu.fill"),
        TopicDeck(id: "6", title: "Giao Tiếp Ngày", wordCount: 400, completionPercentage: 0.90, badgeColor: .vocabMint, iconName: "bubble.left.and.bubble.right.fill")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public init(onDeckSelected: @escaping (String) -> Void) {
        self.onDeckSelected = onDeckSelected
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(decks) { deck in
                Button(action: { onDeckSelected(deck.id) }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: deck.iconName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                                .padding(8)
                                .background(deck.badgeColor.opacity(0.20))
                                .clipShape(Circle())
                            
                            Spacer()
                            
                            Text("📚 \(deck.wordCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.vocabMuted)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deck.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                            
                            Text("\(Int(deck.completionPercentage * 100))% hoàn thành")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.vocabMuted)
                        }

                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.vocabHairline)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.vocabMint)
                                    .frame(width: geo.size.width * CGFloat(deck.completionPercentage))
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(14)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.vocabHairline, lineWidth: 1.5)
                    )
                    .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Update generate_xcodeproj.py**

Update `scripts/generate_xcodeproj.py` to register `TopicDecksGridView.swift`.

- [ ] **Step 5: Run tests**

Run: `swift test --filter VocabularyViewsTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift scripts/generate_xcodeproj.py
git commit -m "feat(vocabulary): add TopicDecksGridView 2-column bento component"
```

---

### Task 5: VocabularyView Main Screen Integration

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift` (wire second tab to `VocabularyView`)
- Test: Add integration tests to `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`

**Interfaces:**
- Consumes: All `Vocabulary` subviews (`MobileSearchView`, `VocabularySummaryCard`, `WordAccordionCard`, `TopicDecksGridView`)
- Produces: Complete `VocabularyView` tab screen

- [ ] **Step 1: Write failing integration test for VocabularyView**

Create `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class VocabularyViewTests: XCTestCase {
    func testVocabularyViewInitializationAndTabSwitch() {
        let view = VocabularyView()
        XCTAssertNotNil(view.body)
    }
}
```

- [ ] **Step 2: Run test baseline**

Run: `swift test --filter VocabularyViewTests`
Expected: FAIL with "cannot find VocabularyView in scope"

- [ ] **Step 3: Implement VocabularyView**

Create `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`:

```swift
import SwiftUI

public struct VocabularyView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "Tất cả"
    @State private var selectedTab = 0 // 0: Kho từ cá nhân, 1: Bộ từ chủ đề
    @State private var expandedWordId: Int64? = 1 // Expand first word by default
    @State private var wordItems: [WordItem] = WordItem.mockData

    private let filterOptions = ["Tất cả", "Cần ôn ⚡", "Đã thuộc ⭐5", "A1-A2", "B1-B2", "C1-C2"]

    public init() {}

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            VStack(spacing: 14) {
                // Sticky Header Search Bar
                MobileSearchView(searchText: $searchText, onVoiceSearchTapped: {})
                    .padding(.top, 8)

                // Segmented Switch (Kho Từ Cá Nhân vs Bộ Từ Chủ Đề)
                HStack(spacing: 0) {
                    segmentedTabButton(title: "Kho Từ Cá Nhân", tabIndex: 0)
                    segmentedTabButton(title: "Bộ Từ Chủ Đề", tabIndex: 1)
                }
                .padding(4)
                .background(Color.vocabSurfaceCard)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                )
                .padding(.horizontal)

                if selectedTab == 0 {
                    // Filter Pills (Horizontal Scroll)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filterOptions, id: \.self) { filter in
                                filterPill(filter)
                            }
                        }
                        .padding(.horizontal)
                    }

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Bento Summary Strip
                            VocabularySummaryCard(
                                totalWords: wordItems.count * 473,
                                srsRetentionPercentage: 0.85,
                                dueCount: 24
                            )

                            // Word Accordion Cards List
                            VStack(spacing: 10) {
                                ForEach(filteredWords) { item in
                                    WordAccordionCard(
                                        item: item,
                                        isExpanded: expandedWordId == item.id,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if expandedWordId == item.id {
                                                    expandedWordId = nil
                                                } else {
                                                    expandedWordId = item.id
                                                }
                                            }
                                        },
                                        onAudioTap: {},
                                        onDrillTap: {}
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 90) // Clear floating tab bar
                    }
                } else {
                    // Topic Decks Grid Tab
                    ScrollView(.vertical, showsIndicators: false) {
                        TopicDecksGridView(onDeckSelected: { _ in })
                            .padding(.top, 4)
                            .padding(.bottom, 90)
                    }
                }
            }
        }
    }

    private var filteredWords: [WordItem] {
        var result = wordItems
        if !searchText.isEmpty {
            result = result.filter { $0.lemma.localizedCaseInsensitiveContains(searchText) || $0.definition.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedFilter == "A1-A2" {
            result = result.filter { $0.cefrLevel == "A1" || $0.cefrLevel == "A2" }
        } else if selectedFilter == "B1-B2" {
            result = result.filter { $0.cefrLevel == "B1" || $0.cefrLevel == "B2" }
        } else if selectedFilter == "C1-C2" {
            result = result.filter { $0.cefrLevel == "C1" || $0.cefrLevel == "C2" }
        } else if selectedFilter == "Cần ôn ⚡" {
            result = result.filter { $0.masteryLevel < 3 }
        } else if selectedFilter == "Đã thuộc ⭐5" {
            result = result.filter { $0.masteryLevel >= 4 }
        }
        return result
    }

    private func segmentedTabButton(title: String, tabIndex: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                selectedTab = tabIndex
            }
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(selectedTab == tabIndex ? Color.vocabInk : Color.vocabMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(selectedTab == tabIndex ? Color.vocabInk.opacity(0.08) : Color.clear)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func filterPill(_ title: String) -> some View {
        let isSelected = selectedFilter == title
        return Button(action: {
            selectedFilter = title
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color.vocabCanvas : Color.vocabInk)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(isSelected ? Color.vocabInk : Color.vocabSurfaceCard)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Color.clear : Color.vocabHairline, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 4: Wire VocabularyView in HomepageView**

Modify `VocabCraftApp/Features/Homepage/Views/HomepageView.swift` to render `VocabularyView()` when `selectedTab == 1`.

- [ ] **Step 5: Update generate_xcodeproj.py**

Update `scripts/generate_xcodeproj.py` to add `VocabularyView.swift` and `VocabularyViewTests.swift`.

- [ ] **Step 6: Run full unit test suite**

Run: `swift test`
Expected: PASS (100% clean pass across all 55+ tests)

- [ ] **Step 7: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift scripts/generate_xcodeproj.py
git commit -m "feat(vocabulary): complete VocabularyView screen integration"
```
