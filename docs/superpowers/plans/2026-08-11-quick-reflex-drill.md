# Quick Reflex Drill ("Luyện phản xạ từ này") Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the "Luyện phản xạ từ này" feature allowing users to launch a targeted 3-step micro-drill directly from any word card in `VocabularyView`, updating SRS mastery and visual feedback upon completion.

**Architecture:** Create dedicated `QuickReflexDrillViewModel` and `QuickReflexDrillSheetView` in `Presentation/Features/Vocabulary/`, consuming `WordItem` data to generate a 3-step exercise sequence (`Pronunciation` -> `Speed Meaning Match` -> `Fill-in-the-Blank`), utilizing `SpeechRecognitionProtocol`, `TextToSpeechProtocol`, and `EvaluateSRSUseCaseProtocol` to update SRS mastery.

**Tech Stack:** Swift 5.9, SwiftUI, `@Observable` macro (iOS 17+), Speech framework, AVFoundation.

## Global Constraints
- Target platform: iOS 17.0+
- State management: `@Observable` on ViewModels
- UI Design System: Use existing `Color.vocab*` tokens (e.g. `Color.vocabInk`, `Color.vocabCanvas`, `Color.vocabPeach`, `Color.vocabMint`)
- Speech / Audio: Use existing `SpeechRecognitionProtocol` and `TextToSpeechProtocol` abstractions
- Tests: XCTest / Swift Testing in `VocabCraftAppTests`

---

### Task 1: Data Model (`QuickDrillStep`)

**Files:**
- Create: `VocabCraftApp/Domain/Models/QuickDrillStep.swift`
- Test: `VocabCraftAppTests/QuickDrillStepTests.swift`

**Interfaces:**
- Consumes: None
- Produces: `QuickDrillStepType`, `QuickDrillStep`

- [ ] **Step 1: Write failing test for `QuickDrillStep`**

Create `VocabCraftAppTests/QuickDrillStepTests.swift`:
```swift
import XCTest
@testable import VocabCraftApp

final class QuickDrillStepTests: XCTestCase {
    func testQuickDrillStepInitialization() {
        let step = QuickDrillStep(
            id: 1,
            type: .pronunciation,
            promptText: "Đọc to câu ví dụ",
            targetText: "Her fame proved to be ephemeral.",
            options: [],
            sentenceWithGap: nil
        )
        XCTAssertEqual(step.id, 1)
        XCTAssertEqual(step.type, .pronunciation)
        XCTAssertEqual(step.targetText, "Her fame proved to be ephemeral.")
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run xcodebuild test via Xcode or xcodebuild CLI command:
Expected: FAIL with "cannot find 'QuickDrillStep' in scope"

- [ ] **Step 3: Implement `QuickDrillStep` model**

Create `VocabCraftApp/Domain/Models/QuickDrillStep.swift`:
```swift
import Foundation

public enum QuickDrillStepType: String, Equatable, Sendable {
    case pronunciation // Step 1: Read example sentence using mic
    case fastMeaning   // Step 2: Pick correct VN definition under time limit
    case fillInBlank   // Step 3: Complete context sentence missing lemma
}

public struct QuickDrillStep: Identifiable, Equatable, Sendable {
    public let id: Int
    public let type: QuickDrillStepType
    public let promptText: String
    public let targetText: String
    public let options: [String]
    public let sentenceWithGap: String?

    public init(
        id: Int,
        type: QuickDrillStepType,
        promptText: String,
        targetText: String,
        options: [String] = [],
        sentenceWithGap: String? = nil
    ) {
        self.id = id
        self.type = type
        self.promptText = promptText
        self.targetText = targetText
        self.options = options
        self.sentenceWithGap = sentenceWithGap
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Models/QuickDrillStep.swift VocabCraftAppTests/QuickDrillStepTests.swift
git commit -m "feat: add QuickDrillStep domain model and unit tests"
```

---

### Task 2: ViewModel Logic (`QuickReflexDrillViewModel`)

**Files:**
- Create: `VocabCraftApp/Presentation/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`
- Test: `VocabCraftAppTests/QuickReflexDrillViewModelTests.swift`

**Interfaces:**
- Consumes: `QuickDrillStep`, `WordItem`, `TextToSpeechProtocol`, `SpeechRecognitionProtocol`, `EvaluateSRSUseCaseProtocol`
- Produces: `QuickReflexDrillViewModel`, state management for 3-step drill & completion

- [ ] **Step 1: Write failing unit tests for `QuickReflexDrillViewModel`**

Create `VocabCraftAppTests/QuickReflexDrillViewModelTests.swift`:
```swift
import XCTest
@testable import VocabCraftApp

final class QuickReflexDrillViewModelTests: XCTestCase {
    var targetWord: WordItem!
    var samplePool: [WordItem]!

    override func setUp() {
        super.setUp()
        targetWord = WordItem(
            id: 1,
            lemma: "Ephemeral",
            pos: "adj.",
            phonetic: "/'fem.ər.əl/",
            definition: "Phù du, chóng phai",
            cefrLevel: "B2",
            masteryLevel: 2,
            exampleSentenceEn: "Her fame proved to be ephemeral.",
            exampleSentenceVi: "Sự nổi tiếng của cô ấy chỉ kéo dài ngắn ngủi."
        )
        samplePool = [
            targetWord,
            WordItem(id: 2, lemma: "Resilience", pos: "n.", phonetic: "/rɪ'zɪl.jəns/", definition: "Khả năng phục hồi", cefrLevel: "C1", masteryLevel: 5, exampleSentenceEn: "Test", exampleSentenceVi: "Test"),
            WordItem(id: 3, lemma: "Meticulous", pos: "adj.", phonetic: "/mə'tɪk.jə.ləs/", definition: "Tỉ mỉ, cẩn thận", cefrLevel: "B2", masteryLevel: 1, exampleSentenceEn: "Test", exampleSentenceVi: "Test"),
            WordItem(id: 4, lemma: "Pragmatic", pos: "adj.", phonetic: "/præɡ'mæt.ɪk/", definition: "Thực tế", cefrLevel: "C1", masteryLevel: 3, exampleSentenceEn: "Test", exampleSentenceVi: "Test")
        ]
    }

    func testStepGeneration() async {
        let viewModel = await QuickReflexDrillViewModel(targetWord: targetWord, allWords: samplePool)
        let steps = await viewModel.steps
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0].type, .pronunciation)
        XCTAssertEqual(steps[1].type, .fastMeaning)
        XCTAssertEqual(steps[2].type, .fillInBlank)
        XCTAssertTrue(steps[1].options.contains("Phù du, chóng phai"))
    }

    func testAnswerValidationAndAdvancement() async {
        let viewModel = await QuickReflexDrillViewModel(targetWord: targetWord, allWords: samplePool)
        
        // Step 1 correct
        await viewModel.submitAnswer("Her fame proved to be ephemeral.")
        var currentStep = await viewModel.currentStepIndex
        XCTAssertEqual(currentStep, 1)

        // Step 2 correct option
        await viewModel.submitAnswer("Phù du, chóng phai")
        currentStep = await viewModel.currentStepIndex
        XCTAssertEqual(currentStep, 2)

        // Step 3 correct lemma
        await viewModel.submitAnswer("Ephemeral")
        let isCompleted = await viewModel.isCompleted
        XCTAssertTrue(isCompleted)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Expected: FAIL with "cannot find 'QuickReflexDrillViewModel' in scope"

- [ ] **Step 3: Implement `QuickReflexDrillViewModel`**

Create `VocabCraftApp/Presentation/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`:
```swift
import Foundation
import Observation

@MainActor
@Observable
public final class QuickReflexDrillViewModel {
    public let targetWord: WordItem
    public let allWords: [WordItem]
    public var steps: [QuickDrillStep] = []
    public var currentStepIndex: Int = 0
    public var elapsedTimeMs: Int = 0
    public var isCompleted: Bool = false
    public var isCorrect: Bool = false
    public var stepSuccessCount: Int = 0
    public var srsResult: SRSResult?
    public var triggerSparkle: Bool = false
    public var feedbackMessage: String = ""

    private let ttsService: TextToSpeechProtocol
    private let sttService: SpeechRecognitionProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol?
    private var startTime: Date?
    private var timerTask: Task<Void, Never>?

    public var isListening: Bool { sttService.isListening }
    public var recognizedText: String { sttService.recognizedText }

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol? = nil
    ) {
        self.targetWord = targetWord
        self.allWords = allWords
        self.ttsService = ttsService ?? TextToSpeechService()
        self.sttService = sttService ?? SpeechRecognitionService()
        self.evaluateSRSUseCase = evaluateSRSUseCase
        generateSteps()
        startTimer()
    }

    deinit {
        let stt = sttService
        Task { @MainActor in stt.stopListening() }
    }

    public func generateSteps() {
        let distractors = allWords.filter { $0.id != targetWord.id }
        
        // Step 1: Pronunciation
        let step1 = QuickDrillStep(
            id: 1,
            type: .pronunciation,
            promptText: "Đọc to câu ví dụ chứa từ \(targetWord.lemma)",
            targetText: targetWord.exampleSentenceEn
        )

        // Step 2: Fast Meaning Match
        var defOptions = distractors.shuffled().prefix(3).map { $0.definition }
        defOptions.append(targetWord.definition)
        defOptions.shuffle()

        let step2 = QuickDrillStep(
            id: 2,
            type: .fastMeaning,
            promptText: "Chọn nghĩa tiếng Việt đúng của từ '\(targetWord.lemma)'",
            targetText: targetWord.definition,
            options: Array(defOptions)
        )

        // Step 3: Fill in Blank
        let sentenceGap = targetWord.exampleSentenceEn.replacingOccurrences(
            of: targetWord.lemma,
            with: "_______",
            options: .caseInsensitive
        )
        var lemmaOptions = distractors.shuffled().prefix(3).map { $0.lemma }
        lemmaOptions.append(targetWord.lemma)
        lemmaOptions.shuffle()

        let step3 = QuickDrillStep(
            id: 3,
            type: .fillInBlank,
            promptText: "Hoàn thành câu bằng từ tiếng Anh chính xác",
            targetText: targetWord.lemma,
            options: Array(lemmaOptions),
            sentenceWithGap: sentenceGap
        )

        self.steps = [step1, step2, step3]
    }

    public func startTimer() {
        startTime = Date()
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self = self, let start = self.startTime else { break }
                self.elapsedTimeMs = Int(Date().timeIntervalSince(start) * 1000)
            }
        }
    }

    public func speakTargetSentence() {
        guard currentStepIndex < steps.count else { return }
        ttsService.speak(text: steps[currentStepIndex].targetText)
    }

    public func handleMicTap() {
        if isListening {
            sttService.stopListening()
            submitAnswer(recognizedText)
        } else {
            ttsService.stop()
            sttService.startListening(
                onResult: { [weak self] text in
                    guard let self = self, self.currentStepIndex < self.steps.count else { return }
                    let target = self.steps[self.currentStepIndex].targetText
                    if self.isAnswerMatching(userText: text, targetText: target) {
                        self.sttService.stopListening()
                        self.submitAnswer(text)
                    }
                },
                onError: { [weak self] _ in
                    self?.feedbackMessage = "Không thể nhận diện giọng nói"
                }
            )
        }
    }

    public func submitAnswer(_ answer: String) {
        guard currentStepIndex < steps.count else { return }
        let currentStep = steps[currentStepIndex]
        let correct = isAnswerMatching(userText: answer, targetText: currentStep.targetText)

        if correct {
            stepSuccessCount += 1
        }

        if currentStepIndex + 1 < steps.count {
            currentStepIndex += 1
        } else {
            finishDrill()
        }
    }

    public func finishDrill() {
        timerTask?.cancel()
        sttService.stopListening()
        
        let allCorrect = stepSuccessCount == steps.count
        let avgTimeMs = steps.isEmpty ? 2000 : elapsedTimeMs / steps.count

        let result: SRSResult
        if let useCase = evaluateSRSUseCase {
            result = useCase.evaluateResponse(
                currentMastery: targetWord.masteryLevel,
                easeFactor: 2.5,
                isCorrect: allCorrect,
                responseTimeMs: avgTimeMs
            )
        } else {
            result = SRSEngine.calculateNextInterval(
                currentMastery: targetWord.masteryLevel,
                easeFactor: 2.5,
                isCorrect: allCorrect,
                responseTimeMs: avgTimeMs
            )
        }

        self.srsResult = result
        self.isCorrect = allCorrect
        self.triggerSparkle = allCorrect
        self.isCompleted = true
    }

    private func isAnswerMatching(userText: String, targetText: String) -> Bool {
        let u = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let t = targetText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !u.isEmpty, !t.isEmpty else { return false }
        return u == t || u.contains(t) || t.contains(u)
    }
}
```

- [ ] **Step 4: Run unit tests to verify they pass**

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Presentation/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift VocabCraftAppTests/QuickReflexDrillViewModelTests.swift
git commit -m "feat: add QuickReflexDrillViewModel with 3-step drill synthesis & SRS evaluation"
```

---

### Task 3: UI Sheet View (`QuickReflexDrillSheetView`)

**Files:**
- Create: `VocabCraftApp/Presentation/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift`

**Interfaces:**
- Consumes: `QuickReflexDrillViewModel`, `WordItem`
- Produces: `QuickReflexDrillSheetView`

- [ ] **Step 1: Create `QuickReflexDrillSheetView`**

Create `VocabCraftApp/Presentation/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift`:
```swift
import SwiftUI

public struct QuickReflexDrillSheetView: View {
    @State private var viewModel: QuickReflexDrillViewModel
    public let onComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        onComplete: @escaping (Int) -> Void
    ) {
        self._viewModel = State(initialValue: QuickReflexDrillViewModel(targetWord: targetWord, allWords: allWords))
        self.onComplete = onComplete
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.vocabCanvas.ignoresSafeArea()

                if viewModel.isCompleted {
                    completionCardView
                } else {
                    drillContentBody
                }
            }
            .navigationTitle("Luyện Phản Xạ Nhanh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.vocabMuted)
                    }
                }
            }
        }
    }

    private var drillContentBody: some View {
        VStack(spacing: 20) {
            // Step Progress Bar
            HStack(spacing: 6) {
                ForEach(0..<viewModel.steps.count, id: \.self) { idx in
                    Rectangle()
                        .fill(idx <= viewModel.currentStepIndex ? Color.vocabPeach : Color.vocabHairline)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Target Word Header Badge
            HStack(spacing: 8) {
                Text(viewModel.targetWord.lemma)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                Text(viewModel.targetWord.pos)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.vocabMuted)
                Spacer()
                Text(viewModel.targetWord.phonetic)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(Color.vocabMuted)
            }
            .padding(14)
            .background(Color.vocabSurfaceCard)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.vocabHairline, lineWidth: 1))
            .padding(.horizontal)

            if viewModel.currentStepIndex < viewModel.steps.count {
                let currentStep = viewModel.steps[viewModel.currentStepIndex]
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bước \(currentStep.id)/3: \(currentStep.promptText)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.vocabInk)

                    switch currentStep.type {
                    case .pronunciation:
                        pronunciationStepView(step: currentStep)
                    case .fastMeaning:
                        optionsStepView(step: currentStep)
                    case .fillInBlank:
                        fillInBlankStepView(step: currentStep)
                    }
                }
                .padding()
                .background(Color.vocabSurfaceCard)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.vocabHairline, lineWidth: 1.5))
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    private func pronunciationStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 20) {
            Text("\"\(step.targetText)\"")
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundColor(Color.vocabInk)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: { viewModel.speakTargetSentence() }) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Nghe câu mẫu")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.vocabHeroAccent)
            }

            Button(action: { viewModel.handleMicTap() }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isListening ? Color.red.opacity(0.15) : Color.vocabPeach.opacity(0.2))
                        .frame(width: 72, height: 72)
                    Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.isListening ? .red : Color.vocabInk)
                }
            }
            .buttonStyle(BentoCardButtonStyle())

            if !viewModel.recognizedText.isEmpty {
                Text("Đã nghe: \"\(viewModel.recognizedText)\"")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }
        }
    }

    private func optionsStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 10) {
            ForEach(step.options, id: \.self) { option in
                Button(action: { viewModel.submitAnswer(option) }) {
                    Text(option)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.vocabCanvas)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vocabHairline, lineWidth: 1))
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
    }

    private func fillInBlankStepView(step: QuickDrillStep) -> some View {
        VStack(spacing: 14) {
            if let gapSentence = step.sentenceWithGap {
                Text("\"\(gapSentence)\"")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.vocabInk)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            ForEach(step.options, id: \.self) { option in
                Button(action: { viewModel.submitAnswer(option) }) {
                    Text(option)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.vocabCanvas)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.vocabHairline, lineWidth: 1))
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
    }

    private var completionCardView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.vocabMint.opacity(0.2))
                    .frame(width: 90, height: 90)
                Image(systemName: viewModel.isCorrect ? "sparkles" : "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.vocabMint)
            }

            Text(viewModel.isCorrect ? "Xuất sắc! Đã làm chủ phản xạ" : "Đã hoàn thành lượt luyện tập!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.vocabInk)

            if let result = viewModel.srsResult {
                HStack(spacing: 4) {
                    Text("Độ thuộc SRS mới:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= result.nextMastery ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(star <= result.nextMastery ? Color.vocabMint : Color.vocabMuted.opacity(0.3))
                    }
                }
            }

            Text("Thời gian phản xạ: \(viewModel.elapsedTimeMs / 3) ms / câu")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)

            Spacer()

            Button(action: {
                let updatedLevel = viewModel.srsResult?.nextMastery ?? viewModel.targetWord.masteryLevel
                onComplete(updatedLevel)
                dismiss()
            }) {
                Text("Hoàn tất")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.vocabCanvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.vocabInk)
                    .cornerRadius(16)
            }
            .buttonStyle(BentoCardButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}
```

- [ ] **Step 2: Verify SwiftUI compilation**

Run xcodebuild build to verify `QuickReflexDrillSheetView` compiles cleanly.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Presentation/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift
git commit -m "feat: add QuickReflexDrillSheetView with step subviews and completion card"
```

---

### Task 4: Integration with `VocabularyView`

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`

**Interfaces:**
- Consumes: `QuickReflexDrillSheetView`, `WordAccordionCard`
- Produces: Live sheet trigger from word card drill button

- [ ] **Step 1: Modify `VocabularyView.swift` to add `@State private var selectedDrillWord: WordItem?`**

Update `VocabularyView.swift`:
Add state variable:
```swift
@State private var selectedDrillWord: WordItem? = nil
```

Wire `onDrillTap` closure on `WordAccordionCard` (line 89):
```swift
onDrillTap: {
    selectedDrillWord = item
}
```

Attach `.sheet(item: $selectedDrillWord)` to the container:
```swift
.sheet(item: $selectedDrillWord) { targetWord in
    QuickReflexDrillSheetView(
        targetWord: targetWord,
        allWords: wordItems,
        onComplete: { updatedMastery in
            if let idx = wordItems.firstIndex(where: { $0.id == targetWord.id }) {
                wordItems[idx].masteryLevel = updatedMastery
            }
        }
    )
}
```

- [ ] **Step 2: Build & Test project**

Run xcodebuild build and run test suite:
```bash
xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16'
```
Expected: BUILD SUCCEEDED, tests PASS.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift
git commit -m "feat: wire QuickReflexDrillSheetView to WordAccordionCard drill button in VocabularyView"
```

---

## Self-Review Checklist
- Spec coverage: 100% (3-step micro drill, sheet presentation, Speech/TTS integration, SRS calculation, star update).
- No Placeholders: All step instructions and code blocks complete.
- Type consistency: `QuickDrillStep`, `QuickReflexDrillViewModel`, `QuickReflexDrillSheetView` interfaces match across all tasks.
