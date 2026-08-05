# Sub-topic Practice Session Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the interactive Sub-topic Practice Session screen (`SubTopicStudySessionView`) with a 3D Flipping Flashcard (`ReflexFlipCardView`), 2-attempt penalty quiz logic, Apple Native FX celebration (`CAEmitterLayer` confetti + Sensory Haptics), SF Symbols compliance, and auto-sync with the Personal Vocab Vault.

**Architecture:** A SwiftUI feature module inside `VocabCraftApp/Features/Vocabulary`. Uses a clean state engine (`SubTopicSessionEngine`) for word progression and scoring, 3D Y-axis rotation effects, and Core Animation GPU particle emitters.

**Tech Stack:** Swift 5.10 / SwiftUI, CoreAnimation (`CAEmitterLayer`), Xcode project structure, `Color+VocabTheme.swift` tokens, XCTest for unit testing.

## Global Constraints

- **SF Symbols Only**: Icons MUST use Apple's standard SF Symbols (`systemName`) e.g. `xmark`, `speaker.wave.2.fill`, `checkmark.circle.fill`, `flame.fill`, `trophy.fill`, `arrow.right`.
- **Dual Theme Tokens**: Use `Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabInk`, `Color.vocabMuted`, `Color.vocabMint`, `Color.vocabCoral`, `Color.vocabHairline` from `Color+VocabTheme.swift`. Full support for Light and Dark modes.
- **Apple Native FX**: Use `CAEmitterLayer` for ProMotion GPU confetti and `.sensoryFeedback` / `UIImpactFeedbackGenerator` for haptics.

---

### Task 1: Sub-topic Session Engine & State Machine (`SubTopicSessionEngine.swift`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Models/SubTopicSessionEngine.swift`
- Test: `VocabCraftAppTests/SubTopicSessionEngineTests.swift`

**Interfaces:**
- Consumes: `TopicWord`, `SubTopicNode`
- Produces: `SubTopicSessionEngine` class/struct managing attempts, XP, combo, retry queue

- [ ] **Step 1: Write failing unit test for `SubTopicSessionEngine`**

Create `VocabCraftAppTests/SubTopicSessionEngineTests.swift`:
```swift
import XCTest
@testable import VocabCraftApp

final class SubTopicSessionEngineTests: XCTestCase {
    func testEngineInitializationAndScoring() {
        let words = [
            TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán"),
            TopicWord(id: "w2", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Tự động hóa")
        ]
        let engine = SubTopicSessionEngine(words: words)

        XCTAssertEqual(engine.currentWord?.english, "Algorithm")
        XCTAssertEqual(engine.attemptsLeft, 2)
        XCTAssertEqual(engine.xpEarned, 0)

        // Correct answer on first try
        let result = engine.submitAnswer(selectedVietnamese: "Thuật toán")
        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(engine.xpEarned, 10)
        XCTAssertEqual(engine.comboCount, 1)
    }

    func testTwoWrongAttemptsEnqueuesRetry() {
        let words = [
            TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán")
        ]
        let engine = SubTopicSessionEngine(words: words)

        // First wrong attempt
        let res1 = engine.submitAnswer(selectedVietnamese: "Sai 1")
        XCTAssertFalse(res1.isCorrect)
        XCTAssertEqual(engine.attemptsLeft, 1)

        // Second wrong attempt
        let res2 = engine.submitAnswer(selectedVietnamese: "Sai 2")
        XCTAssertFalse(res2.isCorrect)
        XCTAssertEqual(engine.attemptsLeft, 0)
        XCTAssertEqual(engine.xpEarned, -5)
        XCTAssertEqual(engine.retryQueue.count, 1)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SubTopicSessionEngineTests`
Expected: FAIL due to missing `SubTopicSessionEngine`.

- [ ] **Step 3: Write implementation for `SubTopicSessionEngine.swift`**

Create `VocabCraftApp/Features/Vocabulary/Models/SubTopicSessionEngine.swift`:
```swift
import Foundation

public struct SubmitResult: Sendable {
    public let isCorrect: Bool
    public let attemptsRemaining: Int
    public let xpDelta: Int
    public let isSessionFinished: Bool
}

@Observable
public final class SubTopicSessionEngine: @unchecked Sendable {
    public private(set) var activeWords: [TopicWord]
    public private(set) var retryQueue: [TopicWord] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var attemptsLeft: Int = 2
    public private(set) var comboCount: Int = 0
    public private(set) var xpEarned: Int = 0
    public private(set) var correctCount: Int = 0
    public private(set) var totalQuestionsCount: Int = 0

    public var currentWord: TopicWord? {
        guard currentIndex < activeWords.count else { return nil }
        return activeWords[currentIndex]
    }

    public var isSessionComplete: Bool {
        return currentIndex >= activeWords.count
    }

    public init(words: [TopicWord]) {
        self.activeWords = words
        self.totalQuestionsCount = words.count
    }

    public func submitAnswer(selectedVietnamese: String) -> SubmitResult {
        guard let word = currentWord else {
            return SubmitResult(isCorrect: false, attemptsRemaining: 0, xpDelta: 0, isSessionFinished: true)
        }

        let isCorrect = selectedVietnamese == word.vietnamese

        if isCorrect {
            let xp = (attemptsLeft == 2) ? 10 : 5
            xpEarned += xp
            comboCount += 1
            correctCount += 1
            return SubmitResult(isCorrect: true, attemptsRemaining: attemptsLeft, xpDelta: xp, isSessionFinished: false)
        } else {
            attemptsLeft -= 1
            if attemptsLeft <= 0 {
                xpEarned -= 5
                comboCount = 0
                retryQueue.append(word)
                return SubmitResult(isCorrect: false, attemptsRemaining: 0, xpDelta: -5, isSessionFinished: false)
            } else {
                return SubmitResult(isCorrect: false, attemptsRemaining: 1, xpDelta: 0, isSessionFinished: false)
            }
        }
    }

    public func advanceToNextWord() {
        currentIndex += 1
        attemptsLeft = 2
        if currentIndex >= activeWords.count && !retryQueue.isEmpty {
            activeWords.append(contentsOf: retryQueue)
            retryQueue.removeAll()
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SubTopicSessionEngineTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Models/SubTopicSessionEngine.swift VocabCraftAppTests/SubTopicSessionEngineTests.swift
git commit -m "feat: add SubTopicSessionEngine state machine with retry queue"
```

---

### Task 2: Reusable 3D Flip Flashcard (`ReflexFlipCardView.swift`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/ReflexFlipCardView.swift`
- Test: `VocabCraftAppTests/ReflexFlipCardViewTests.swift`

**Interfaces:**
- Consumes: `TopicWord`, `Color+VocabTheme.swift` tokens, SF Symbols
- Produces: `ReflexFlipCardView` SwiftUI component with 3D Y-rotation flip

- [ ] **Step 1: Write failing unit test for `ReflexFlipCardView`**

Create `VocabCraftAppTests/ReflexFlipCardViewTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class ReflexFlipCardViewTests: XCTestCase {
    func testCardInitialization() {
        let word = TopicWord(id: "w1", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán")
        let card = ReflexFlipCardView(word: word, isFlipped: false, isSuccess: true, onAudioTap: {})
        XCTAssertNotNil(card)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexFlipCardViewTests`
Expected: FAIL due to missing `ReflexFlipCardView`.

- [ ] **Step 3: Write implementation for `ReflexFlipCardView.swift`**

Create `VocabCraftApp/Features/Vocabulary/Views/ReflexFlipCardView.swift`:
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
            // FRONT FACE
            VStack(spacing: 12) {
                Text("MẶT TRƯỚC • THỬ THÁCH NHỚ NGHĨA")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.vocabSurfaceSoft)
                    .foregroundColor(Color.vocabMuted)
                    .cornerRadius(6)

                Text(word.english)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Button(action: onAudioTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text(word.phonetic)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.vocabMint.opacity(0.15))
                    .foregroundColor(Color.vocabMint)
                    .cornerRadius(16)
                }

                Text("👇 Chọn đáp án tiếng Việt chính xác bên dưới")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.vocabHairline, lineWidth: 1)
            )
            .opacity(isFlipped ? 0 : 1)

            // BACK FACE
            VStack(spacing: 12) {
                Text(isSuccess ? "✓ CHÍNH XÁC! MẶT SAU & VÍ DỤ NGUYÊN CẢNH" : "⚠️ SAI 2 LẦN! MẶT SAU & GIẢI THÍCH")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isSuccess ? Color.vocabMint : Color.vocabCoral).opacity(0.2))
                    .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)
                    .cornerRadius(6)

                Text(word.vietnamese)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isSuccess ? Color.vocabMint : Color.vocabCoral)

                VStack(alignment: .leading, spacing: 4) {
                    Text("💡 Ví dụ ngữ cảnh:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.vocabMuted)
                    Text("\"The \(word.english) processes data in real time.\"")
                        .font(.system(size: 12, weight: .medium))
                        .italic()
                        .foregroundColor(Color.vocabBody)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.vocabSurfaceSoft)
                .cornerRadius(10)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 200)
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
git commit -m "feat: add ReflexFlipCardView 3D flip card component"
```

---

### Task 3: Practice Session View (`SubTopicStudySessionView.swift`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift`
- Test: `VocabCraftAppTests/SubTopicStudySessionViewTests.swift`

**Interfaces:**
- Consumes: `SubTopicSessionEngine`, `ReflexFlipCardView`, `SubTopicNode`, `Color+VocabTheme.swift` tokens, SF Symbols
- Produces: `SubTopicStudySessionView` main practice session screen

- [ ] **Step 1: Write failing unit test for `SubTopicStudySessionView`**

Create `VocabCraftAppTests/SubTopicStudySessionViewTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp

final class SubTopicStudySessionViewTests: XCTestCase {
    func testViewInitialization() {
        let node = SubTopicNode(id: "1", title: "Công nghệ", iconName: "cpu", totalWords: 10, learnedWords: 0, state: .active, words: [])
        let view = SubTopicStudySessionView(node: node, onDismiss: {}, onComplete: { _ in })
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SubTopicStudySessionViewTests`
Expected: FAIL due to missing `SubTopicStudySessionView`.

- [ ] **Step 3: Write implementation for `SubTopicStudySessionView.swift`**

Create `VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift`:
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
        self._engine = State(initialValue: SubTopicSessionEngine(words: node.words))
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Bar
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }

                // Progress segments
                HStack(spacing: 4) {
                    ForEach(0..<max(1, engine.totalQuestionsCount), id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(idx < engine.currentIndex ? Color.vocabMint : Color.vocabHairline)
                            .frame(height: 5)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color.vocabPeach)
                    Text("\(engine.comboCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                }
            }

            if let word = engine.currentWord {
                // 3D Flip Flashcard
                ReflexFlipCardView(
                    word: word,
                    isFlipped: isFlipped,
                    isSuccess: isSuccess,
                    onAudioTap: {
                        // Audio TTS trigger
                    }
                )

                // Quiz Options Grid
                VStack(spacing: 8) {
                    HStack {
                        Text("Số lần thử còn lại: \(engine.attemptsLeft)/2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(engine.attemptsLeft == 1 ? Color.vocabCoral : Color.vocabMuted)
                        Spacer()
                        Text("XP: +\(engine.xpEarned)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.vocabMint)
                    }

                    ForEach(generateOptions(for: word), id: \.self) { opt in
                        Button(action: { handleAnswer(opt) }) {
                            HStack {
                                Text(opt)
                                    .font(.system(size: 14, weight: .semibold))
                                Spacer()
                                if selectedAnswer == opt {
                                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(Color.vocabMuted)
                                }
                            }
                            .padding(14)
                            .background(optionBackground(for: opt))
                            .foregroundColor(optionForeground(for: opt))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(optionBorder(for: opt), lineWidth: 1)
                            )
                        }
                        .disabled(selectedAnswer != nil && isFlipped)
                    }
                }

                Spacer()

                // Bottom Feedback Sheet / Continue Button
                if isFlipped {
                    Button(action: nextWord) {
                        HStack {
                            Text(isSuccess ? "✓ CHÍNH XÁC! (+10 XP) • TIẾP TỤC" : "✕ SAI 2 LẦN (-5 XP) • TIẾP TỤC")
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSuccess ? Color.vocabMint : Color.vocabCoral)
                        .foregroundColor(Color.vocabCanvas)
                        .cornerRadius(14)
                    }
                }
            } else {
                // Session finished
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.vocabPeach)
                    Text("CHÚC MỪNG HOÀN THÀNH CHẶNG!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                    Text("Tổng XP nhận được: +\(engine.xpEarned)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabMuted)

                    Button(action: { onComplete(engine.xpEarned) }) {
                        Text("HOÀN THÀNH")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.vocabInk)
                            .foregroundColor(Color.vocabCanvas)
                            .cornerRadius(14)
                    }
                }
                .padding(24)
            }
        }
        .padding(20)
        .background(Color.vocabCanvas.ignoresSafeArea())
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

    private func generateOptions(for word: TopicWord) -> [String] {
        return [word.vietnamese, "Sự tự động hóa", "Đa dạng sinh học", "Hệ sinh thái"].shuffled()
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
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SubTopicStudySessionViewTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift VocabCraftAppTests/SubTopicStudySessionViewTests.swift
git commit -m "feat: add SubTopicStudySessionView practice session screen"
```

---

### Task 4: Integration & Xcode Project PBX Registration

**Files:**
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`
- Modify: `VocabCraftApp/Features/Vocabulary/Views/SubTopicPreviewSheet.swift`
- Test: All SPM & Xcode build targets

**Interfaces:**
- Consumes: `SubTopicStudySessionView`, `SubTopicPreviewSheet`
- Produces: Seamless presentation of study session from preview sheet.

- [ ] **Step 1: Wire `SubTopicPreviewSheet` to present `SubTopicStudySessionView`**

Update `onStartDrill` closure in `SubTopicPreviewSheet.swift` to set `@State private var isPresentingSession = true`.

- [ ] **Step 2: Add newly created files to `project.pbxproj`**

Register `SubTopicSessionEngine.swift`, `ReflexFlipCardView.swift`, `SubTopicStudySessionView.swift` and their tests in `VocabCraftApp.xcodeproj/project.pbxproj`.

- [ ] **Step 3: Run full test suite and verify build**

Run: `swift test` and `xcodebuild -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination 'id=BF80E6F7-2E73-448F-AEAE-5326B50B9630' -derivedDataPath ./build build`
Expected: PASS and BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp.xcodeproj/project.pbxproj VocabCraftApp/Features/Vocabulary/Views/SubTopicPreviewSheet.swift
git commit -m "feat: register study session files in Xcode target and wire drill presentation"
```
