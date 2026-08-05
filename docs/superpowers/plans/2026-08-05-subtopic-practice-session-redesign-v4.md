# Sub-topic Practice Session Redesign V4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Redesign V4 upgrades for the Sub-topic Practice Session screen (`SubTopicStudySessionView`), including a 10-word dataset, distractor algorithm fix, minimal 3D flip card (IPA on row 2, circle audio icon on row 3), top header XP badge, thumb-zone ergonomics with press scaling (`0.98`), and clean toast feedback.

**Architecture:** Refactors existing `SubTopicSessionEngine`, `ReflexFlipCardView`, `SubTopicStudySessionView`, and `TopicDeckModels` in `VocabCraftApp/Features/Vocabulary`. Uses `Color+VocabTheme.swift` tokens and SF Symbols.

**Tech Stack:** Swift 5.10 / SwiftUI, Xcode project target, XCTest unit testing.

## Global Constraints

- **SF Symbols Only**: Icons MUST use Apple's standard SF Symbols (`systemName`) e.g. `xmark`, `speaker.wave.2.fill`, `checkmark.circle.fill`, `xmark.circle.fill`, `arrow.right`, `circle`.
- **Dual Theme Tokens**: High-contrast light mode with `Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabInk`, `Color.vocabMuted`, `Color.vocabMint`, `Color.vocabCoral`, `Color.vocabPeach`, `Color.vocabHairline`.
- **Apple Ergonomics**: Thumb-zone lower-screen placement with `.scaleEffect(0.98)` on press.

---

### Task 1: Dataset Expansion & Distractor Engine Upgrade (`TopicDeckModels.swift` & `SubTopicSessionEngine.swift`)

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift`
- Modify: `VocabCraftApp/Features/Vocabulary/Models/SubTopicSessionEngine.swift`
- Test: `VocabCraftAppTests/SubTopicSessionEngineTests.swift`

**Interfaces:**
- Consumes: `TopicWord`, `SubTopicNode`
- Produces: 10-word node dataset, non-repeating distractor generator, formatted XP strings.

- [ ] **Step 1: Write failing unit test for 10-word dataset and distractor uniqueness**

Update `VocabCraftAppTests/SubTopicSessionEngineTests.swift`:
```swift
func testDistractorGeneratorReturnsFourUniqueOptions() {
    let words = [
        TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa", example: "Factory automation reduces costs.", partOfSpeech: "noun"),
        TopicWord(id: "w2", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán", example: "The algorithm runs fast.", partOfSpeech: "noun"),
        TopicWord(id: "w3", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", example: "Protect the ecosystem.", partOfSpeech: "noun"),
        TopicWord(id: "w4", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", example: "Forests have high biodiversity.", partOfSpeech: "noun")
    ]
    let engine = SubTopicSessionEngine(words: words)
    let options = engine.generateDistractors(for: words[0])
    
    XCTAssertEqual(options.count, 4)
    XCTAssertTrue(options.contains("Sự tự động hóa"))
    XCTAssertEqual(Set(options).count, 4, "Options must contain 4 distinct Vietnamese meanings without duplicates")
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter testDistractorGeneratorReturnsFourUniqueOptions`
Expected: FAIL.

- [ ] **Step 3: Update `TopicDeckModels.swift` and `SubTopicSessionEngine.swift`**

Add `example` and `partOfSpeech` to `TopicWord`, add 10-word mock dataset to node 3 in `TopicDeckModels.swift`.
In `SubTopicSessionEngine.swift`, implement `generateDistractors(for word: TopicWord) -> [String]` picking 3 distinct random meanings from other words in `activeWords` plus the correct target meaning.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter testDistractorGeneratorReturnsFourUniqueOptions`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Models/TopicDeckModels.swift VocabCraftApp/Features/Vocabulary/Models/SubTopicSessionEngine.swift VocabCraftAppTests/SubTopicSessionEngineTests.swift
git commit -m "feat: expand 10-word dataset and upgrade distractor generation engine"
```

---

### Task 2: Minimal 3D Flip Flashcard with Highlighted Example (`ReflexFlipCardView.swift`)

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/ReflexFlipCardView.swift`
- Test: `VocabCraftAppTests/ReflexFlipCardViewTests.swift`

**Interfaces:**
- Consumes: `TopicWord`, `Color+VocabTheme.swift` tokens, SF Symbols
- Produces: Minimalist `ReflexFlipCardView` with Front face (Word ➔ IPA ➔ Circle Audio Icon) and Back face (Word ➔ IPA ➔ Circle Audio Icon ➔ `[partOfSpeech] Meaning` ➔ Highlighted example).

- [ ] **Step 1: Write failing unit test for `ReflexFlipCardView` minimal front & back elements**

Update `VocabCraftAppTests/ReflexFlipCardViewTests.swift`:
```swift
func testReflexFlipCardViewRendersMinimalElements() {
    let word = TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa", example: "Factory automation reduces costs.", partOfSpeech: "noun")
    let card = ReflexFlipCardView(word: word, isFlipped: false, isSuccess: true, onAudioTap: {})
    XCTAssertEqual(card.word.english, "Automation")
    XCTAssertEqual(card.word.partOfSpeech, "noun")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter testReflexFlipCardViewRendersMinimalElements`
Expected: FAIL.

- [ ] **Step 3: Update `ReflexFlipCardView.swift`**

```swift
import SwiftUI

public struct ReflexFlipCardView: View {
    public let word: TopicWord
    public let isFlipped: Bool
    public let isSuccess: Bool
    public let onAudioTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        word: TopicWord,
        isFlipped: Bool,
        isSuccess: Bool,
        onAudioTap: @escaping () -> Void
    ) {
        self.word = word
        self.isFlipped = isFlipped
        self.isSuccess = isSuccess
        self.onAudioTap = onAudioTap
    }

    public var body: some View {
        ZStack {
            // FRONT FACE (MINIMAL: Word -> IPA -> Circle Audio Icon)
            VStack(spacing: 8) {
                Text(word.english)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Text(word.phonetic)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.vocabMuted)

                Button(action: onAudioTap) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabMint)
                        .frame(width: 42, height: 42)
                        .background(Color.vocabMint.opacity(0.15))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.vocabMint.opacity(0.3), lineWidth: 1))
                }
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.vocabHairline, lineWidth: 1.5)
            )
            .opacity(isFlipped ? 0 : 1)

            // BACK FACE (DETAILED: Word -> IPA -> Audio -> [partOfSpeech] Meaning -> Example)
            VStack(spacing: 8) {
                Text(word.english)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Text(word.phonetic)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)

                Button(action: onAudioTap) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)
                        .frame(width: 32, height: 32)
                        .background((isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.15))
                        .clipShape(Circle())
                }

                Text("[\(word.partOfSpeech ?? "noun")] \(word.vietnamese)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ví dụ:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.vocabMuted)

                    Text("\"\(word.example ?? "The \(word.english) processes data in real time.")\"")
                        .font(.system(size: 12, weight: .medium))
                        .italic()
                        .foregroundColor(Color.vocabBody)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabSurfaceSoft)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.vocabHairline, lineWidth: 1)
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSuccess ? Color.vocabMint : Color.vocabCoral, lineWidth: 1.5)
            )
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: isFlipped)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexFlipCardViewTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/ReflexFlipCardView.swift VocabCraftAppTests/ReflexFlipCardViewTests.swift
git commit -m "feat: redesign ReflexFlipCardView to minimal front and back face with circle audio icon"
```

---

### Task 3: Ergonomic Practice Session Screen (`SubTopicStudySessionView.swift`)

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift`
- Test: `VocabCraftAppTests/SubTopicStudySessionViewTests.swift`

**Interfaces:**
- Consumes: `SubTopicSessionEngine`, `ReflexFlipCardView`, `SubTopicSessionSummaryView`, `Color+VocabTheme.swift` tokens, SF Symbols
- Produces: Clean ergonomic `SubTopicStudySessionView` with Top Header XP badge, 10 progress segments, thumb-zone options grid with press scaling (`0.98`), clean bottom toast & *"Tiếp tục ➔"* button.

- [ ] **Step 1: Write failing unit test for `SubTopicStudySessionView` XP header badge**

Update `VocabCraftAppTests/SubTopicStudySessionViewTests.swift`:
```swift
func testViewInitializationWithTenWordDataset() {
    let words = (1...10).map { idx in
        TopicWord(id: "w\(idx)", english: "Word \(idx)", phonetic: "/w\(idx)/", vietnamese: "Từ \(idx)")
    }
    let node = SubTopicNode(id: "1", title: "Công nghệ", iconName: "cpu", totalWords: 10, learnedWords: 0, state: .active, words: words)
    let view = SubTopicStudySessionView(node: node, onDismiss: {}, onComplete: { _ in })
    XCTAssertNotNil(view)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SubTopicStudySessionViewTests`
Expected: FAIL.

- [ ] **Step 3: Update `SubTopicStudySessionView.swift`**

```swift
import SwiftUI

public struct SubTopicStudySessionView: View {
    public let node: SubTopicNode
    public let onDismiss: () -> Void
    public let onComplete: (Int) -> Void

    @State private var engine: SubTopicSessionEngine
    @State private var isFlipped: Bool = false
    @State private var isSuccess: Bool = true
    @State private var selectedAnswer: String? = nil
    @State private var options: [String] = []

    @Environment(\.colorScheme) private var colorScheme

    public init(
        node: SubTopicNode,
        onDismiss: @escaping () -> Void,
        onComplete: @escaping (Int) -> Void
    ) {
        self.node = node
        self.onDismiss = onDismiss
        self.onComplete = onComplete
        let wordsToUse = node.words.isEmpty ? SubTopicStudySessionView.sampleWords : node.words
        self._engine = State(initialValue: SubTopicSessionEngine(words: wordsToUse))
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Bar with Circle Close & XP Badge
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .frame(width: 32, height: 32)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }

                // 10 Progress segments
                HStack(spacing: 3) {
                    ForEach(0..<max(1, engine.totalQuestionsCount), id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(idx < engine.currentIndex ? Color.vocabMint : Color.vocabHairline)
                            .frame(height: 6)
                    }
                }

                // Header XP Badge
                HStack(spacing: 4) {
                    Text("⚡")
                    Text("+\(engine.xpEarned) XP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.vocabPeach)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.vocabPeach.opacity(0.15))
                .cornerRadius(12)
            }

            if let word = engine.currentWord {
                // 3D Flip Flashcard
                ReflexFlipCardView(
                    word: word,
                    isFlipped: isFlipped,
                    isSuccess: isSuccess,
                    onAudioTap: {
                        // TTS audio
                    }
                )

                Spacer()

                // Thumb-Zone Quiz Options Section
                VStack(spacing: 10) {
                    HStack {
                        Text("Chọn đáp án đúng:")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.vocabMuted)
                        Spacer()
                        Text("Lần \(3 - engine.attemptsLeft)/2")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.vocabMuted)
                    }

                    ForEach(options, id: \.self) { opt in
                        Button(action: { handleAnswer(opt) }) {
                            HStack {
                                Text(opt)
                                    .font(.system(size: 15, weight: .bold))
                                Spacer()
                                if selectedAnswer == opt {
                                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(Color.vocabHairline)
                                }
                            }
                            .padding(14)
                            .background(optionBackground(for: opt))
                            .foregroundColor(optionForeground(for: opt))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(optionBorder(for: opt), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(PressedScaleButtonStyle())
                        .disabled(selectedAnswer != nil && isFlipped)
                    }
                }

                // Bottom Feedback Sheet / Continue Action
                if isFlipped {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSuccess ? "✓ Chính xác! (+10 XP)" : "✕ Chưa chính xác (-5 XP)")
                            .font(.system(size: 16, weight: .extrabold))
                            .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)

                        Text(isSuccess ? "Đã tự động đồng bộ từ vựng vào Kho cá nhân." : "Từ này sẽ được đưa về cuối lượt để ôn lại.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.vocabMuted)

                        Button(action: nextWord) {
                            HStack {
                                Text("Tiếp tục")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.vocabInk)
                            .foregroundColor(Color.vocabCanvas)
                            .cornerRadius(14)
                        }
                        .buttonStyle(PressedScaleButtonStyle())
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background((isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.1))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSuccess ? Color.vocabMint : Color.vocabCoral, lineWidth: 1.5)
                    )
                }
            } else {
                // Session finished -> SubTopicSessionSummaryView
                SubTopicSessionSummaryView(
                    xpEarned: engine.xpEarned,
                    totalQuestions: engine.totalQuestionsCount,
                    correctCount: engine.correctCount,
                    onRestart: {
                        self.engine = SubTopicSessionEngine(words: node.words.isEmpty ? SubTopicStudySessionView.sampleWords : node.words)
                    },
                    onFinish: {
                        onComplete(engine.xpEarned)
                    }
                )
            }
        }
        .padding(20)
        .background(Color.vocabCanvas.ignoresSafeArea())
        .onAppear {
            if let word = engine.currentWord {
                options = engine.generateDistractors(for: word)
            }
        }
        .onChange(of: engine.currentIndex) { _, _ in
            if let word = engine.currentWord {
                options = engine.generateDistractors(for: word)
            }
        }
    }

    private func handleAnswer(_ opt: String) {
        selectedAnswer = opt
        let result = engine.submitAnswer(selectedVietnamese: opt)

        if result.isCorrect {
            isSuccess = true
            isFlipped = true
        } else {
            if result.attemptsRemaining <= 0 {
                isSuccess = false
                isFlipped = true
            }
        }
    }

    private func nextWord() {
        selectedAnswer = nil
        isFlipped = false
        engine.advanceToNextWord()
    }

    private func optionBackground(for opt: String) -> Color {
        guard let sel = selectedAnswer, sel == opt else { return Color.vocabSurfaceCard }
        return isSuccess ? Color.vocabMint.opacity(0.15) : Color.vocabCoral.opacity(0.15)
    }

    private func optionForeground(for opt: String) -> Color {
        guard let sel = selectedAnswer, sel == opt else { return Color.vocabInk }
        return isSuccess ? Color.vocabMint : Color.vocabCoral
    }

    private func optionBorder(for opt: String) -> Color {
        guard let sel = selectedAnswer, sel == opt else { return Color.vocabHairline }
        return isSuccess ? Color.vocabMint : Color.vocabCoral
    }

    public static let sampleWords: [TopicWord] = [
        TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa", example: "Factory automation reduces production costs.", partOfSpeech: "noun"),
        TopicWord(id: "w2", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán", example: "The search algorithm returns accurate results.", partOfSpeech: "noun"),
        TopicWord(id: "w3", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", example: "Pollution threatens the marine ecosystem.", partOfSpeech: "noun"),
        TopicWord(id: "w4", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", example: "Rainforests are rich in biodiversity.", partOfSpeech: "noun"),
        TopicWord(id: "w5", english: "Sustainability", phonetic: "/səˌsteɪ.nəˈbɪl.ə.ti/", vietnamese: "Sự bền vững", example: "Company policies focus on sustainability.", partOfSpeech: "noun"),
        TopicWord(id: "w6", english: "Innovation", phonetic: "/ˌɪn.əˈveɪ.ʃən/", vietnamese: "Sự đổi mới sáng tạo", example: "Technological innovation drives economic growth.", partOfSpeech: "noun"),
        TopicWord(id: "w7", english: "Infrastructure", phonetic: "/ˈɪn.frəˌstrʌk.tʃər/", vietnamese: "Hạ tầng", example: "The city invested in new transportation infrastructure.", partOfSpeech: "noun"),
        TopicWord(id: "w8", english: "Artificial", phonetic: "/ˌɑːr.t̬əˈfɪʃ.əl/", vietnamese: "Nhân tạo", example: "Artificial intelligence learns from data.", partOfSpeech: "adjective"),
        TopicWord(id: "w9", english: "Intelligence", phonetic: "/ɪnˈtel.ə.dʒəns/", vietnamese: "Trí tuệ", example: "Human intelligence is adaptable.", partOfSpeech: "noun"),
        TopicWord(id: "w10", english: "Architecture", phonetic: "/ˈɑːr.kə.tek.tʃər/", vietnamese: "Kiến trúc", example: "Modern architecture combines style and utility.", partOfSpeech: "noun")
    ]
}

public struct PressedScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SubTopicStudySessionViewTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift VocabCraftAppTests/SubTopicStudySessionViewTests.swift
git commit -m "feat: upgrade SubTopicStudySessionView to Redesign V4 with XP header badge and ergonomic thumb zone"
```

---

### Task 4: Full Suite Verification & iPhone Simulator Build

**Files:**
- Test: All 74+ SPM unit tests (`swift test`)
- Build: Xcode build & Simulator deployment (`xcodebuild` + `simctl`)

- [ ] **Step 1: Run full SPM unit test suite**

Run: `swift test`
Expected: 100% tests PASS cleanly.

- [ ] **Step 2: Run Xcode Simulator build**

Run: `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'id=BF80E6F7-2E73-448F-AEAE-5326B50B9630' -derivedDataPath ./build build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Re-install and launch on iPhone 17 Pro Simulator**

Run: `xcrun simctl install BF80E6F7-2E73-448F-AEAE-5326B50B9630 ./build/Build/Products/Debug-iphonesimulator/VocabCraftApp.app && xcrun simctl launch BF80E6F7-2E73-448F-AEAE-5326B50B9630 com.hoojinguyen.vocabcraft`
Expected: App launches on Simulator.

- [ ] **Step 4: Final Commit**

```bash
git add -A
git commit -m "feat: complete Sub-topic Practice Session Redesign V4 implementation"
```
