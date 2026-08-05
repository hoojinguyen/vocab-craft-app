# Topic Deck Detail View & Game-like Roadmap Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the interactive Topic Deck Detail screen (`TopicDeckDetailView`) featuring a Game-like Timeline Stepper (Roadmap), SF Symbols compliance, Light/Dark mode design token support, and auto-sync integration with the Personal Vocab Vault.

**Architecture:** A SwiftUI feature module inside `VocabCraftApp/Features/Vocabulary`. Uses state-driven UI for node states (`.completed`, `.active`, `.locked`), a bottom sheet for sub-topic word preview, and SF Symbols for native iOS aesthetics.

**Tech Stack:** Swift 5.10 / SwiftUI, Xcode project structure, `Color+VocabTheme.swift` tokens, XCTest for unit testing.

## Global Constraints

- **SF Symbols Only**: Icons MUST use Apple's standard SF Symbols (`systemName`) e.g. `graduationcap.fill`, `leaf.fill`, `cpu`, `checkmark.circle.fill`, `lock.fill`, `play.fill`, `bookmark.fill`.
- **Dual Theme Tokens**: Use `Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabInk`, `Color.vocabMuted`, `Color.vocabMint`, `Color.vocabHairline` from `Color+VocabTheme.swift`. Full support for Light and Dark modes.
- **Language**: SwiftUI in iOS 17+.

---

### Task 1: Topic Deck Data Models (`TopicDeckModels.swift`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift`
- Test: `VocabCraftAppTests/TopicDeckModelsTests.swift`

**Interfaces:**
- Consumes: None
- Produces: `NodeState`, `SubTopicNode`, `TopicWord` structs

- [ ] **Step 1: Write failing unit test for TopicDeckModels**

Create `VocabCraftAppTests/TopicDeckModelsTests.swift`:
```swift
import XCTest
@testable import VocabCraftApp

final class TopicDeckModelsTests: XCTestCase {
    func testSubTopicNodeInitialization() {
        let word = TopicWord(
            id: "w1",
            english: "Algorithm",
            phonetic: "/ˈæl.ɡə.rɪ.ðəm/",
            vietnamese: "Thuật toán",
            isMastered: true,
            isSavedToPersonalVault: true
        )
        let node = SubTopicNode(
            id: "node-1",
            title: "Công nghệ & AI",
            iconName: "cpu",
            totalWords: 25,
            learnedWords: 12,
            state: .active,
            words: [word]
        )
        XCTAssertEqual(node.state, .active)
        XCTAssertEqual(node.words.count, 1)
        XCTAssertEqual(node.words.first?.english, "Algorithm")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TopicDeckModelsTests` or `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: FAIL due to missing `TopicDeckModels.swift`.

- [ ] **Step 3: Write minimal implementation for TopicDeckModels**

Create `VocabCraftAppServices/TopicDeckModels.swift` or `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift`:
```swift
import Foundation
import SwiftUI

public enum NodeState: String, Codable, Sendable {
    case completed
    case active
    case locked
}

public struct TopicWord: Identifiable, Codable, Sendable {
    public let id: String
    public let english: String
    public let phonetic: String
    public let vietnamese: String
    public var isMastered: Bool
    public var isSavedToPersonalVault: Bool

    public init(
        id: String,
        english: String,
        phonetic: String,
        vietnamese: String,
        isMastered: Bool = false,
        isSavedToPersonalVault: Bool = false
    ) {
        self.id = id
        self.english = english
        self.phonetic = phonetic
        self.vietnamese = vietnamese
        self.isMastered = isMastered
        self.isSavedToPersonalVault = isSavedToPersonalVault
    }
}

public struct SubTopicNode: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let iconName: String
    public let totalWords: Int
    public let learnedWords: Int
    public let state: NodeState
    public let words: [TopicWord]

    public init(
        id: String,
        title: String,
        iconName: String,
        totalWords: Int,
        learnedWords: Int,
        state: NodeState,
        words: [TopicWord]
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.totalWords = totalWords
        self.learnedWords = learnedWords
        self.state = state
        self.words = words
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TopicDeckModelsTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift VocabCraftAppTests/TopicDeckModelsTests.swift
git commit -m "feat: add TopicDeckModels with SubTopicNode and TopicWord"
```

---

### Task 2: SubTopic Preview Bottom Sheet (`SubTopicPreviewSheet.swift`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/SubTopicPreviewSheet.swift`
- Test: `VocabCraftAppTests/SubTopicPreviewSheetTests.swift`

**Interfaces:**
- Consumes: `SubTopicNode`, `TopicWord` from Task 1, `Color+VocabTheme.swift` tokens
- Produces: `SubTopicPreviewSheet` SwiftUI view

- [ ] **Step 1: Write failing UI test or view initialization test**

Create `VocabCraftAppTests/SubTopicPreviewSheetTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class SubTopicPreviewSheetTests: XCTestCase {
    func testSheetInitialization() {
        let node = SubTopicNode(
            id: "n1",
            title: "Môi trường",
            iconName: "leaf.fill",
            totalWords: 25,
            learnedWords: 25,
            state: .completed,
            words: []
        )
        let sheet = SubTopicPreviewSheet(node: node, onStartDrill: {}, onToggleVault: { _ in })
        XCTAssertNotNil(sheet)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SubTopicPreviewSheetTests`
Expected: FAIL due to missing `SubTopicPreviewSheet`.

- [ ] **Step 3: Write implementation for `SubTopicPreviewSheet.swift`**

Create `VocabCraftApp/Features/Vocabulary/Views/SubTopicPreviewSheet.swift`:
```swift
import SwiftUI

public struct SubTopicPreviewSheet: View {
    public let node: SubTopicNode
    public let onStartDrill: () -> Void
    public let onToggleVault: (TopicWord) -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        node: SubTopicNode,
        onStartDrill: @escaping () -> Void,
        onToggleVault: @escaping (TopicWord) -> Void
    ) {
        self.node = node
        self.onStartDrill = onStartDrill
        self.onToggleVault = onToggleVault
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Sheet Header
            HStack(spacing: 12) {
                Image(systemName: node.iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                    .padding(10)
                    .background(Color.vocabMint.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                    Text("\(node.learnedWords)/\(node.totalWords) từ đã thuộc")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                }

                Spacer()
            }
            .padding(.top, 8)

            Divider()
                .background(Color.vocabHairline)

            // Word List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(node.words) { word in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(word.english)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color.vocabInk)
                                    Text(word.phonetic)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.vocabMuted)
                                }
                                Text(word.vietnamese)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.vocabBody)
                            }

                            Spacer()

                            // Status badge
                            if word.isMastered {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.vocabMint)
                            } else {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(Color.vocabPeach)
                            }

                            // Vault toggle button
                            Button(action: { onToggleVault(word) }) {
                                Image(systemName: word.isSavedToPersonalVault ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(word.isSavedToPersonalVault ? Color.vocabPeach : Color.vocabMuted)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(12)
                        .background(Color.vocabSurfaceCard)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vocabHairline, lineWidth: 1)
                        )
                    }
                }
            }

            // Start Drill Button
            Button(action: onStartDrill) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Luyện tập riêng chặng này")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.vocabInk)
                .foregroundColor(Color.vocabCanvas)
                .cornerRadius(14)
            }
        }
        .padding(20)
        .background(Color.vocabCanvas)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SubTopicPreviewSheetTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/SubTopicPreviewSheet.swift VocabCraftAppTests/SubTopicPreviewSheetTests.swift
git commit -m "feat: add SubTopicPreviewSheet with SF Symbols and theme tokens"
```

---

### Task 3: Topic Deck Detail Screen & Timeline Roadmap (`TopicDeckDetailView.swift`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/TopicDeckDetailView.swift`
- Test: `VocabCraftAppTests/TopicDeckDetailViewTests.swift`

**Interfaces:**
- Consumes: `TopicDeck`, `SubTopicNode`, `SubTopicPreviewSheet`, `Color+VocabTheme.swift` tokens
- Produces: `TopicDeckDetailView` SwiftUI view

- [ ] **Step 1: Write failing unit test for `TopicDeckDetailView`**

Create `VocabCraftAppTests/TopicDeckDetailViewTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class TopicDeckDetailViewTests: XCTestCase {
    func testDetailViewInitialization() {
        let view = TopicDeckDetailView(deckId: "1", onBack: {})
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter TopicDeckDetailViewTests`
Expected: FAIL due to missing `TopicDeckDetailView`.

- [ ] **Step 3: Write implementation for `TopicDeckDetailView.swift`**

Create `VocabCraftApp/Features/Vocabulary/Views/TopicDeckDetailView.swift`:
```swift
import SwiftUI

public struct TopicDeckDetailView: View {
    public let deckId: String
    public let onBack: () -> Void

    @State private var selectedNode: SubTopicNode? = nil
    @Environment(\.colorScheme) private var colorScheme

    // Sample data (to be wired to ViewModel)
    private let nodes: [SubTopicNode] = [
        SubTopicNode(
            id: "1",
            title: "Môi trường & Khí hậu",
            iconName: "leaf.fill",
            totalWords: 25,
            learnedWords: 25,
            state: .completed,
            words: [
                TopicWord(id: "w1", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w2", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", isMastered: true, isSavedToPersonalVault: true)
            ]
        ),
        SubTopicNode(
            id: "2",
            title: "Giáo dục & Đào tạo",
            iconName: "graduationcap.fill",
            totalWords: 25,
            learnedWords: 25,
            state: .completed,
            words: []
        ),
        SubTopicNode(
            id: "3",
            title: "Công nghệ & AI",
            iconName: "cpu",
            totalWords: 25,
            learnedWords: 12,
            state: .active,
            words: [
                TopicWord(id: "w3", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w4", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Tự động hóa", isMastered: false, isSavedToPersonalVault: false)
            ]
        ),
        SubTopicNode(
            id: "4",
            title: "Kinh tế & Thị trường",
            iconName: "chart.line.uptrend.xyaxis",
            totalWords: 25,
            learnedWords: 0,
            state: .locked,
            words: []
        )
    ]

    public init(deckId: String, onBack: @escaping () -> Void) {
        self.deckId = deckId
        self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Header Card
                VStack(spacing: 12) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                        }

                        Text("IELTS Academic 500")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.vocabInk)

                        Spacer()

                        Text("B2 - C1")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.vocabMint.opacity(0.2))
                            .foregroundColor(Color.vocabInk)
                            .cornerRadius(6)
                    }

                    HStack {
                        Text("Tiến độ: 65% (325/500 từ)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                        Spacer()
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.vocabHairline)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.vocabMint)
                                .frame(width: geo.size.width * 0.65)
                        }
                    }
                    .frame(height: 6)

                    // Hero CTA
                    Button(action: {
                        if let active = nodes.first(where: { $0.state == .active }) {
                            selectedNode = active
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("BẮT ĐẦU HỌC CHẶNG 3 (CÔNG NGHỆ)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.vocabPeach)
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(12)
                    }
                }
                .padding(16)
                .background(Color.vocabSurfaceCard)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.vocabHairline, lineWidth: 1)
                )

                // Timeline Roadmap
                VStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                        VStack(spacing: 0) {
                            HStack(spacing: 14) {
                                // Node Circle Icon
                                ZStack {
                                    Circle()
                                        .fill(nodeColor(for: node.state))
                                        .frame(width: 48, height: 48)

                                    if node.state == .completed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color.vocabCanvas)
                                    } else if node.state == .active {
                                        Text("\(index + 1)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color.vocabInk)
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.vocabMuted)
                                    }
                                }

                                // Node Card Info
                                Button(action: { selectedNode = node }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Image(systemName: node.iconName)
                                                Text(node.title)
                                                    .font(.system(size: 15, weight: .bold))
                                            }
                                            .foregroundColor(Color.vocabInk)

                                            Text("\(node.learnedWords)/\(node.totalWords) từ đã thuộc")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.vocabMuted)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.vocabMuted)
                                    }
                                    .padding(12)
                                    .background(Color.vocabSurfaceCard)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(node.state == .active ? Color.vocabPeach : Color.vocabHairline, lineWidth: node.state == .active ? 2 : 1)
                                    )
                                }
                            }

                            // Vertical Line (except for last item)
                            if index < nodes.count - 1 {
                                HStack {
                                    Rectangle()
                                        .fill(node.state == .completed ? Color.vocabMint : Color.vocabHairline)
                                        .frame(width: 4, height: 28)
                                        .padding(.leading, 22)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
        .sheet(item: $selectedNode) { node in
            SubTopicPreviewSheet(
                node: node,
                onStartDrill: {
                    selectedNode = nil
                },
                onToggleVault: { word in
                    // Toggle vault logic
                }
            )
        }
    }

    private func nodeColor(for state: NodeState) -> Color {
        switch state {
        case .completed: return Color.vocabMint
        case .active: return Color.vocabPeach
        case .locked: return Color.vocabSurfaceSoft
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter TopicDeckDetailViewTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/TopicDeckDetailView.swift VocabCraftAppTests/TopicDeckDetailViewTests.swift
git commit -m "feat: add TopicDeckDetailView with timeline roadmap stepper"
```

---

### Task 4: Integration with `TopicDecksGridView` and Navigation

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`

**Interfaces:**
- Consumes: `TopicDeckDetailView`, `onDeckSelected` callback
- Produces: Seamless push/presentation of `TopicDeckDetailView` from Topic Decks tab.

- [ ] **Step 1: Update `TopicDecksGridView.swift` & `VocabularyView.swift`**

Wire `selectedDeckId` state in `VocabularyView.swift` to present `TopicDeckDetailView(deckId: id, onBack: { selectedDeckId = nil })`.

- [ ] **Step 2: Run all tests to verify clean integration**

Run: `swift test` or build project via `xcodebuild`
Expected: PASS cleanly.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift
git commit -m "feat: integrate TopicDeckDetailView into VocabularyView navigation"
```
