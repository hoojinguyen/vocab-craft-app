# Kế hoạch Triển khai: Tái cấu trúc Kho từ & Chế độ Luyện tập Nhanh Ngẫu nhiên (Mixed Reflex Drill)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tái cấu trúc Kho từ thành trung tâm quản lý từ vựng tinh gọn (Chưa thuộc, Đã thuộc, Đã lưu), cung cấp màn hình chọn từ để luyện tập và chế độ Luyện tập nhanh ngẫu nhiên 4 chế độ với cơ chế Loop-back khi làm sai.

**Architecture:** Áp dụng Clean Architecture và MVVM với Observation (`@Observable`) trong SwiftUI (iOS 17+ / Swift 6). Đóng gói quy tắc thành thạo vào `MasteryEvaluationPolicy` thuần túy, điều phối dữ liệu qua Use Cases và Presentation ViewModels độc lập.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Testing (`@Suite`, `@Test`, `#expect`), SpeechKit / AVFoundation.

**Spec:** `docs/superpowers/specs/2026-08-21-vocabulary-vault-redesign-design.md`

## Global Constraints

- Không dùng Emoji làm icon tính năng; chỉ dùng 100% SF Symbols nguyên bản của Apple.
- Không dùng gradient màu tím-xanh rẻ tiền (Anti-AI-Slop); tuân thủ Design Tokens của VocabCraft (`Color.vocabCanvas`, `Color.vocabSurfaceCard`, `Color.vocabAccent`, `Color.vocabHairline`).
- Vùng chạm tương tác tối thiểu $\ge 44 \times 44\text{ pt}$.
- Tất cả các bước cập nhật trạng thái đa luồng tuân thủ Swift Concurrency (`@MainActor`, `Sendable`).

---

### Task 1: Domain Entities & Mastery Evaluation Policy

**Files:**
- Create: `VocabCraftApp/Domain/Entities/VaultWordItem.swift`
- Create: `VocabCraftApp/Domain/Entities/MixedReflexDrillItem.swift`
- Create: `VocabCraftApp/Domain/Policies/MasteryEvaluationPolicy.swift`
- Test: `VocabCraftAppTests/Domain/MasteryEvaluationPolicyTests.swift`

**Interfaces:**
- Produces:
  - `VaultWordItem`: Model bất biến đại diện cho từ trong Kho từ.
  - `MixedReflexDrillItem`: Model phần tử trong hàng đợi luyện tập.
  - `MasteryEvaluationPolicy.evaluate(currentStreak:practicedModes:isCorrect:currentMode:) -> (newStreak: Int, newPracticedModes: Set<ReflexBlitzMode>, isMastered: Bool)`

- [ ] **Step 1: Viết test kiểm tra MasteryEvaluationPolicy**

Tạo file `VocabCraftAppTests/Domain/MasteryEvaluationPolicyTests.swift`:
```swift
import Testing
@testable import VocabCraftApp

@Suite("MasteryEvaluationPolicy Tests")
struct MasteryEvaluationPolicyTests {
    @Test("Chưa thuộc khi streak < 3 hoặc chỉ có 1 mode")
    func testNotMasteredWhenStreakLowOrSingleMode() {
        // Lần 1 đúng với MultipleChoice
        let result1 = MasteryEvaluationPolicy.evaluate(
            currentStreak: 0,
            practicedModes: [],
            isCorrect: true,
            currentMode: .multipleChoice
        )
        #expect(result1.newStreak == 1)
        #expect(result1.newPracticedModes.contains(.multipleChoice))
        #expect(result1.isMastered == false)
        
        // Lần 2 đúng vẫn với MultipleChoice (chưa đủ 2 chế độ khác nhau)
        let result2 = MasteryEvaluationPolicy.evaluate(
            currentStreak: 2,
            practicedModes: [.multipleChoice],
            isCorrect: true,
            currentMode: .multipleChoice
        )
        #expect(result2.newStreak == 3)
        #expect(result2.isMastered == false) // Sai điều kiện >= 2 modes
    }

    @Test("Thăng hạng Đã thuộc khi streak >= 3 và có >= 2 modes khác nhau")
    func testMasteredWhenStreakThreeAndTwoModes() {
        let result = MasteryEvaluationPolicy.evaluate(
            currentStreak: 2,
            practicedModes: [.multipleChoice],
            isCorrect: true,
            currentMode: .speaking
        )
        #expect(result.newStreak == 3)
        #expect(result.newPracticedModes == [.multipleChoice, .speaking])
        #expect(result.isMastered == true)
    }

    @Test("Sai 1 lần lập tức reset streak về 0 và chuyển về Chưa thuộc")
    func testWrongAnswerResetsMastery() {
        let result = MasteryEvaluationPolicy.evaluate(
            currentStreak: 5,
            practicedModes: [.multipleChoice, .speaking, .typing],
            isCorrect: false,
            currentMode: .typing
        )
        #expect(result.newStreak == 0)
        #expect(result.newPracticedModes.isEmpty)
        #expect(result.isMastered == false)
    }
}
```

- [ ] **Step 2: Chạy test để xác nhận fail**

Chạy lệnh kiểm thử:
`swift test --filter MasteryEvaluationPolicyTests`
Kỳ vọng: Lỗi biên dịch vì chưa định nghĩa `MasteryEvaluationPolicy`.

- [ ] **Step 3: Triển khai Domain Models và MasteryEvaluationPolicy**

Tạo file `VocabCraftApp/Domain/Entities/VaultWordItem.swift`:
```swift
import Foundation

public struct VaultWordItem: Identifiable, Sendable, Equatable {
    public let id: Int64
    public let lemma: String
    public let pos: String
    public let phonetic: String
    public let definitionVi: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let cefrLevel: String?
    
    public let isMastered: Bool
    public let isBookmarked: Bool
    public let correctStreak: Int
    public let practicedModes: Set<ReflexBlitzMode>
    public let lastPracticedAt: Date?

    public init(
        id: Int64,
        lemma: String,
        pos: String,
        phonetic: String = "",
        definitionVi: String,
        exampleSentenceEn: String = "",
        exampleSentenceVi: String = "",
        cefrLevel: String? = nil,
        isMastered: Bool = false,
        isBookmarked: Bool = false,
        correctStreak: Int = 0,
        practicedModes: Set<ReflexBlitzMode> = [],
        lastPracticedAt: Date? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.phonetic = phonetic
        self.definitionVi = definitionVi
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = exampleSentenceVi
        self.cefrLevel = cefrLevel
        self.isMastered = isMastered
        self.isBookmarked = isBookmarked
        self.correctStreak = correctStreak
        self.practicedModes = practicedModes
        self.lastPracticedAt = lastPracticedAt
    }
}
```

Tạo file `VocabCraftApp/Domain/Entities/MixedReflexDrillItem.swift`:
```swift
import Foundation

public struct MixedReflexDrillItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let word: VaultWordItem
    public let assignedMode: ReflexBlitzMode
    public let isRetry: Bool

    public init(
        id: UUID = UUID(),
        word: VaultWordItem,
        assignedMode: ReflexBlitzMode,
        isRetry: Bool = false
    ) {
        self.id = id
        self.word = word
        self.assignedMode = assignedMode
        self.isRetry = isRetry
    }
}
```

Tạo file `VocabCraftApp/Domain/Policies/MasteryEvaluationPolicy.swift`:
```swift
import Foundation

public struct MasteryEvaluationPolicy: Sendable {
    public static let requiredStreakForMastery = 3
    public static let requiredDistinctModesForMastery = 2

    public static func evaluate(
        currentStreak: Int,
        practicedModes: Set<ReflexBlitzMode>,
        isCorrect: Bool,
        currentMode: ReflexBlitzMode
    ) -> (newStreak: Int, newPracticedModes: Set<ReflexBlitzMode>, isMastered: Bool) {
        if !isCorrect {
            return (newStreak: 0, newPracticedModes: [], isMastered: false)
        }

        let newStreak = currentStreak + 1
        var newModes = practicedModes
        newModes.insert(currentMode)

        let isMastered = (newStreak >= requiredStreakForMastery) &&
                         (newModes.count >= requiredDistinctModesForMastery)

        return (newStreak: newStreak, newPracticedModes: newModes, isMastered: isMastered)
    }
}
```

- [ ] **Step 4: Chạy test xác nhận pass**

Chạy lệnh: `swift test --filter MasteryEvaluationPolicyTests`
Kỳ vọng: PASS toàn bộ test case.

- [ ] **Step 5: Commit Git**

```bash
git add VocabCraftApp/Domain/Entities/VaultWordItem.swift VocabCraftApp/Domain/Entities/MixedReflexDrillItem.swift VocabCraftApp/Domain/Policies/MasteryEvaluationPolicy.swift VocabCraftAppTests/Domain/MasteryEvaluationPolicyTests.swift
git commit -m "feat(domain): add VaultWordItem, MixedReflexDrillItem, and MasteryEvaluationPolicy"
```

---

### Task 2: Use Cases Layer (Fetch, Bookmark, Queue Generation, Record Result)

**Files:**
- Create: `VocabCraftApp/Domain/UseCases/GenerateMixedReflexQueueUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/RecordMixedDrillAttemptUseCase.swift`
- Modify: `VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift`
- Test: `VocabCraftAppTests/Domain/MixedReflexQueueUseCaseTests.swift`

**Interfaces:**
- Produces:
  - `GenerateMixedReflexQueueUseCaseProtocol.generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem]`
  - `GenerateMixedReflexQueueUseCaseProtocol.requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem`
  - `RecordMixedDrillAttemptUseCaseProtocol.execute(wordId: Int64, mode: ReflexBlitzMode, isCorrect: Bool) async throws -> VaultWordItem`

- [ ] **Step 1: Viết test cho GenerateMixedReflexQueueUseCase**

Tạo file `VocabCraftAppTests/Domain/MixedReflexQueueUseCaseTests.swift`:
```swift
import Testing
@testable import VocabCraftApp

@Suite("GenerateMixedReflexQueueUseCase Tests")
struct MixedReflexQueueUseCaseTests {
    @Test("Tạo hàng đợi gán ngẫu nhiên 4 mode cho danh sách từ")
    func testGenerateQueue() {
        let useCase = GenerateMixedReflexQueueUseCase()
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung"),
            VaultWordItem(id: 3, lemma: "create", pos: "v.", definitionVi: "Tạo ra")
        ]
        
        let queue = useCase.generate(from: words)
        #expect(queue.count == 3)
        #expect(queue.map(\.word.id) == [1, 2, 3])
        #expect(queue.allSatisfy { $0.isRetry == false })
    }

    @Test("Requeue từ làm sai chọn mode mới khác mode vừa sai")
    func testRequeueFailedItemDifferentMode() {
        let useCase = GenerateMixedReflexQueueUseCase()
        let word = VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen")
        let failedItem = MixedReflexDrillItem(word: word, assignedMode: .multipleChoice)
        
        let retryItem = useCase.requeueFailedItem(failedItem)
        #expect(retryItem.word.id == 1)
        #expect(retryItem.isRetry == true)
        #expect(retryItem.assignedMode != .multipleChoice)
    }
}
```

- [ ] **Step 2: Chạy test xác nhận fail**

Chạy lệnh: `swift test --filter MixedReflexQueueUseCaseTests`

- [ ] **Step 3: Viết mã triển khai cho GenerateMixedReflexQueueUseCase và Use Cases**

Tạo file `VocabCraftApp/Domain/UseCases/GenerateMixedReflexQueueUseCase.swift`:
```swift
import Foundation

public protocol GenerateMixedReflexQueueUseCaseProtocol: Sendable {
    func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem]
    func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem
}

public final class GenerateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol, Sendable {
    public init() {}

    public func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] {
        let allModes = ReflexBlitzMode.allCases
        return words.map { word in
            let randomMode = allModes.randomElement() ?? .multipleChoice
            return MixedReflexDrillItem(word: word, assignedMode: randomMode, isRetry: false)
        }
    }

    public func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem {
        let alternativeModes = ReflexBlitzMode.allCases.filter { $0 != item.assignedMode }
        let newMode = alternativeModes.randomElement() ?? .multipleChoice
        return MixedReflexDrillItem(word: item.word, assignedMode: newMode, isRetry: true)
    }
}
```

Tạo file `VocabCraftApp/Domain/UseCases/RecordMixedDrillAttemptUseCase.swift`:
```swift
import Foundation

public protocol RecordMixedDrillAttemptUseCaseProtocol: Sendable {
    func execute(wordId: Int64, mode: ReflexBlitzMode, isCorrect: Bool) async throws -> VaultWordItem?
}

public final class RecordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol, Sendable {
    private let progressRepo: any UserProgressRepositoryProtocol
    private let dataSource: VocabularyDataSourceProtocol

    public init(
        progressRepo: any UserProgressRepositoryProtocol,
        dataSource: VocabularyDataSourceProtocol
    ) {
        self.progressRepo = progressRepo
        self.dataSource = dataSource
    }

    public func execute(wordId: Int64, mode: ReflexBlitzMode, isCorrect: Bool) async throws -> VaultWordItem? {
        let existingProgress = try await progressRepo.fetchProgress(for: wordId)
        let currentStreak = existingProgress?.consecutiveCorrectStreak ?? 0
        let currentModes = existingProgress?.practicedModes ?? []
        
        let evaluation = MasteryEvaluationPolicy.evaluate(
            currentStreak: currentStreak,
            practicedModes: currentModes,
            isCorrect: isCorrect,
            currentMode: mode
        )

        try await progressRepo.recordDrillResult(
            wordId: wordId,
            isCorrect: isCorrect,
            newStreak: evaluation.newStreak,
            newModes: evaluation.newPracticedModes,
            isMastered: evaluation.isMastered
        )

        guard let wordDTO = try await dataSource.fetchWordById(id: wordId) else { return nil }
        let updatedProgress = try await progressRepo.fetchProgress(for: wordId)
        
        return VaultWordItem(
            id: wordDTO.id,
            lemma: wordDTO.lemma,
            pos: wordDTO.pos,
            phonetic: wordDTO.phonetic,
            definitionVi: wordDTO.definitionVi,
            exampleSentenceEn: wordDTO.exampleEn ?? "",
            exampleSentenceVi: wordDTO.exampleVi ?? "",
            cefrLevel: wordDTO.cefrLevel,
            isMastered: evaluation.isMastered,
            isBookmarked: updatedProgress?.isBookmarked ?? false,
            correctStreak: evaluation.newStreak,
            practicedModes: evaluation.newPracticedModes,
            lastPracticedAt: Date()
        )
    }
}
```

- [ ] **Step 4: Chạy test xác nhận pass**

Chạy lệnh: `swift test --filter MixedReflexQueueUseCaseTests`

- [ ] **Step 5: Commit Git**

```bash
git add VocabCraftApp/Domain/UseCases/GenerateMixedReflexQueueUseCase.swift VocabCraftApp/Domain/UseCases/RecordMixedDrillAttemptUseCase.swift VocabCraftAppTests/Domain/MixedReflexQueueUseCaseTests.swift
git commit -m "feat(usecases): add GenerateMixedReflexQueueUseCase and RecordMixedDrillAttemptUseCase"
```

---

### Task 3: Presentation ViewModels (PersonalVaultViewModel & Selection State)

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift`
- Test: `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`

**Interfaces:**
- Produces:
  - `PersonalVaultViewModel.vaultWords: [VaultWordItem]`
  - `PersonalVaultViewModel.selectedWordIds: Set<Int64>`
  - `PersonalVaultViewModel.toggleWordSelection(id: Int64)`
  - `PersonalVaultViewModel.selectAll()`
  - `PersonalVaultViewModel.deselectAll()`
  - `PersonalVaultViewModel.setFilter(_ filter: VaultTabFilter)`

- [x] **Step 1: Viết test cho PersonalVaultViewModel**

Tạo file `VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift`:
```swift
import Testing
import Foundation
@testable import VocabCraftApp

@Suite("PersonalVaultViewModel Tests")
struct PersonalVaultViewModelTests {
    @Test("Toggle chọn từng từ và Chọn tất cả")
    @MainActor
    func testSelectionManagement() async {
        let mockWords = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]
        
        let vm = PersonalVaultViewModel(mockWords: mockWords)
        #expect(vm.selectedWordIds.isEmpty)
        
        vm.toggleWordSelection(id: 1)
        #expect(vm.selectedWordIds.contains(1))
        
        vm.selectAll()
        #expect(vm.selectedWordIds.count == 2)
        
        vm.deselectAll()
        #expect(vm.selectedWordIds.isEmpty)
    }
}
```

- [x] **Step 2: Triển khai cập nhật trong PersonalVaultViewModel**

Cập nhật `VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift` với đầy đủ hỗ trợ `VaultTabFilter`, `selectedWordIds`, `toggleWordSelection`, `selectAll`, `deselectAll`.

- [x] **Step 3: Chạy test xác nhận pass**

Chạy lệnh: `swift test --filter PersonalVaultViewModelTests`

- [x] **Step 4: Commit Git**

```bash
git add VocabCraftApp/Features/Vocabulary/PersonalVault/ViewModels/PersonalVaultViewModel.swift VocabCraftAppTests/Features/PersonalVaultViewModelTests.swift
git commit -m "feat(viewmodel): update PersonalVaultViewModel with selection state and VaultTabFilter"
```

---

### Task 4: Mixed Reflex Drill ViewModel & Session Loop-Back Mechanics

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/ViewModels/MixedReflexDrillViewModel.swift`
- Test: `VocabCraftAppTests/Features/MixedReflexDrillViewModelTests.swift`

**Interfaces:**
- Produces:
  - `MixedReflexDrillViewModel.queue: [MixedReflexDrillItem]`
  - `MixedReflexDrillViewModel.currentItem: MixedReflexDrillItem?`
  - `MixedReflexDrillViewModel.submitAnswer(isCorrect: Bool)`
  - `MixedReflexDrillViewModel.isCompleted: Bool`
  - `MixedReflexDrillViewModel.sessionSummary: ReflexBlitzSessionSummary?`

- [ ] **Step 1: Viết test cho MixedReflexDrillViewModel**

Tạo file `VocabCraftAppTests/Features/MixedReflexDrillViewModelTests.swift`:
```swift
import Testing
import Foundation
@testable import VocabCraftApp

@Suite("MixedReflexDrillViewModel Tests")
struct MixedReflexDrillViewModelTests {
    @Test("Loop-back đẩy từ sai về cuối hàng đợi")
    @MainActor
    func testLoopBackOnWrongAnswer() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)
        
        #expect(vm.queue.count == 2)
        let firstWordId = vm.currentItem?.word.id
        
        // Trả lời sai câu 1
        await vm.submitAnswer(isCorrect: false)
        
        // Câu 1 phải được đẩy xuống cuối hàng đợi
        #expect(vm.queue.last?.word.id == firstWordId)
        #expect(vm.queue.last?.isRetry == true)
    }
}
```

- [ ] **Step 2: Triển khai MixedReflexDrillViewModel**

Tạo file `VocabCraftApp/Features/Vocabulary/ViewModels/MixedReflexDrillViewModel.swift`:
```swift
import Foundation
import Observation

@MainActor
@Observable
public final class MixedReflexDrillViewModel {
    public private(set) var queue: [MixedReflexDrillItem] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var comboStreak: Int = 0
    public private(set) var maxComboStreak: Int = 0
    public private(set) var attempts: [ReflexBlitzAttempt] = []
    public private(set) var isCompleted: Bool = false
    public private(set) var sessionSummary: ReflexBlitzSessionSummary?

    private let queueUseCase: GenerateMixedReflexQueueUseCaseProtocol
    private let recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?

    public init(
        selectedWords: [VaultWordItem],
        queueUseCase: GenerateMixedReflexQueueUseCaseProtocol,
        recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.queueUseCase = queueUseCase
        self.recordAttemptUseCase = recordAttemptUseCase
        self.ttsService = ttsService
        self.queue = queueUseCase.generate(from: selectedWords)
    }

    public var currentItem: MixedReflexDrillItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    public var progress: Double {
        guard !queue.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(queue.count)
    }

    public func submitAnswer(isCorrect: Bool, responseTimeMs: Int = 2000) async {
        guard let current = currentItem else { return }

        let attempt = ReflexBlitzAttempt(
            wordId: Int(current.word.id),
            lemma: current.word.lemma,
            pos: current.word.pos,
            definitionVi: current.word.definitionVi,
            responseTimeMs: responseTimeMs,
            usedHint: false,
            isCorrect: isCorrect
        )
        attempts.append(attempt)

        if isCorrect {
            comboStreak += 1
            maxComboStreak = max(maxComboStreak, comboStreak)
        } else {
            comboStreak = 0
            let retryItem = queueUseCase.requeueFailedItem(current)
            queue.append(retryItem)
        }

        _ = try? await recordAttemptUseCase?.execute(
            wordId: current.word.id,
            mode: current.assignedMode,
            isCorrect: isCorrect
        )

        currentIndex += 1
        if currentIndex >= queue.count {
            finishSession()
        }
    }

    private func finishSession() {
        isCompleted = true
        sessionSummary = ReflexBlitzSessionSummary.create(
            from: attempts,
            maxCombo: maxComboStreak
        )
    }

    public func playAudioForCurrentWord() {
        guard let current = currentItem else { return }
        ttsService?.speak(text: current.word.lemma)
    }
}
```

- [ ] **Step 3: Chạy test xác nhận pass**

Chạy lệnh: `swift test --filter MixedReflexDrillViewModelTests`

- [ ] **Step 4: Commit Git**

```bash
git add VocabCraftApp/Features/Vocabulary/ViewModels/MixedReflexDrillViewModel.swift VocabCraftAppTests/Features/MixedReflexDrillViewModelTests.swift
git commit -m "feat(viewmodel): add MixedReflexDrillViewModel with dynamic queue and loop-back mechanics"
```

---

### Task 5: UI Màn hình Chọn từ Luyện tập (`PracticeSelectionView`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/PracticeSelectionView.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/PracticeSelectionRow.swift`

**Interfaces:**
- Produces:
  - `PracticeSelectionView(vaultViewModel:onStartPractice:onClose:)`
  - `PracticeSelectionRow(word:isSelected:onToggle:)`

- [ ] **Step 1: Tạo Component PracticeSelectionRow**

Tạo file `VocabCraftApp/Features/Vocabulary/Views/Components/PracticeSelectionRow.swift`:
Thiết kế hàng chọn từ với Touch target $\ge 44\text{ pt}$, SF Symbols `circle` / `checkmark.circle.fill` với Spring animation và Haptic feedback.

- [ ] **Step 2: Tạo màn hình PracticeSelectionView**

Tạo file `VocabCraftApp/Features/Vocabulary/Views/PracticeSelectionView.swift`:
- Navigation header có `< Back`.
- Segmented filter để chuyển tab (Chưa thuộc / Đã thuộc / Đã lưu).
- Action row có nút "Chọn tất cả" / "Bỏ chọn".
- Danh sách từ `LazyVStack`.
- Sticky bottom bar `.safeAreaInset(edge: .bottom)` chứa nút "BẮT ĐẦU LUYỆN TẬP (X TỪ)".

- [ ] **Step 3: Commit Git**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/PracticeSelectionView.swift VocabCraftApp/Features/Vocabulary/Views/Components/PracticeSelectionRow.swift
git commit -m "feat(ui): add PracticeSelectionView and PracticeSelectionRow with sticky action bar"
```

---

### Task 6: UI Màn hình Luyện tập Nhanh Ngẫu nhiên (`MixedReflexDrillView` & `MixedReflexSummaryView`)

**Files:**
- Create: `VocabCraftApp/Features/Vocabulary/Views/MixedReflexDrillView.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/MixedReflexSummaryView.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/DynamicReflexModeBadge.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/DynamicPulseTimerBar.swift`

**Interfaces:**
- Produces:
  - `MixedReflexDrillView(viewModel:onFinish:)`
  - `MixedReflexSummaryView(summary:onRetry:onDone:)`

- [ ] **Step 1: Tạo DynamicReflexModeBadge và DynamicPulseTimerBar**

Tạo các component hiển thị huy hiệu 4 chế độ và thanh đếm ngược đổi màu động (Pulse Timer) theo chuẩn `swiftui-design-skill`.

- [ ] **Step 2: Tạo MixedReflexDrillView tích hợp 4 chế độ tương tác**

Tạo file `VocabCraftApp/Features/Vocabulary/Views/MixedReflexDrillView.swift` kết nối Trắc nghiệm, Luyện nói (`ContinuousReflexSpeechService`), Gõ từ và Nghe phản xạ.

- [ ] **Step 3: Tạo MixedReflexSummaryView**

Tạo file `VocabCraftApp/Features/Vocabulary/Views/MixedReflexSummaryView.swift` hiển thị kết quả và các từ thăng hạng "Đã thuộc".

- [ ] **Step 4: Commit Git**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/MixedReflexDrillView.swift VocabCraftApp/Features/Vocabulary/Views/MixedReflexSummaryView.swift VocabCraftApp/Features/Vocabulary/Views/Components/DynamicReflexModeBadge.swift VocabCraftApp/Features/Vocabulary/Views/Components/DynamicPulseTimerBar.swift
git commit -m "feat(ui): add MixedReflexDrillView, summary, pulse timer, and mode badge"
```

---

### Task 7: Tái cấu trúc Màn hình Kho từ (`VocabularyView`)

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Create: `VocabCraftApp/Features/Vocabulary/Views/Components/TopCarouselFlashcardView.swift`

**Interfaces:**
- Produces:
  - `VocabularyView` tinh gọn không còn tab phân mảnh, tích hợp nút "LUYỆN TẬP" mở `PracticeSelectionView`.
  - `TopCarouselFlashcardView`: Thẻ vuốt ngang xem từ mẫu kèm phát âm nhanh.

- [ ] **Step 1: Tạo TopCarouselFlashcardView**

Tạo file `VocabCraftApp/Features/Vocabulary/Views/Components/TopCarouselFlashcardView.swift` sử dụng `TabView` với `.tabViewStyle(.page)`.

- [ ] **Step 2: Tái cấu trúc VocabularyView**

Cập nhật `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`:
- Bỏ bộ chuyển đổi "Bộ từ chủ đề" (đã tách ra Home Screen).
- Thêm thanh tìm kiếm `TextField`.
- Thêm 3 tab Segmented: Chưa thuộc, Đã thuộc, Đã lưu.
- Thêm nút lớn "LUYỆN TẬP" mở sheet `PracticeSelectionView`.
- Thêm `TopCarouselFlashcardView` và danh sách từ vựng tinh gọn.

- [ ] **Step 3: Commit Git**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftApp/Features/Vocabulary/Views/Components/TopCarouselFlashcardView.swift
git commit -m "refactor(ui): redesign VocabularyView with 3 tabs, top carousel, and practice entry point"
```

---

### Task 8: DI Wiring, Router Integration & Full Test Verification

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/App/Navigation/AppRouter.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Test: Full Test Suite

- [ ] **Step 1: Cập nhật AppContainer Factory Methods**

Thêm các factory methods khởi tạo `MixedReflexDrillViewModel`, `GenerateMixedReflexQueueUseCase`, `RecordMixedDrillAttemptUseCase` trong `AppContainer.swift`.

- [ ] **Step 2: Cập nhật AppRouter và HomepageView**

Kết nối điều hướng từ Home sang Kho từ mới và các sheet luyện tập.

- [ ] **Step 3: Chạy toàn bộ Test Suite**

Chạy lệnh kiểm thử toàn diện:
`swift test`
Kỳ vọng: Toàn bộ Unit Tests và Integration Tests đều PASS xanh 100%.

- [ ] **Step 4: Commit Git**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/App/Navigation/AppRouter.swift VocabCraftApp/Features/Homepage/Views/HomepageView.swift
git commit -m "feat(app): wire DI dependencies and verify full test suite for vocabulary redesign"
```
