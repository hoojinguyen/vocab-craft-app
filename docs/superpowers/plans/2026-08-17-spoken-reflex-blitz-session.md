# Spoken Reflex Blitz Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build "Spoken Reflex Blitz", a voice-first continuous speed-run practice mode (5–10 words, ~90–120s) that trains direct spoken vocabulary reflex from contextual cloze sentences under soft time constraints with zero-latency audio transitions, progressive hints at 3.5s, auto-advance on match (<2.5s) or timeout (6.0s), combo streaks, and a post-session Speed & Mastery Dashboard with 1-tap weak-word re-drill.

**Architecture:** A standalone MVVM feature module inside `Features/ReflexDrill` comprising a continuous audio session coordinator (`ContinuousReflexSpeechService`), state-machine session view model (`ReflexBlitzViewModel`), isolated high-performance SwiftUI views (`ReflexBlitzCardView`, `ReflexBlitzHeaderView`, `ReflexBlitzSummaryView`, `ReflexCountdownOverlayView`), and seamless integration with existing `EvaluateSRSUseCaseProtocol` and `TargetExpressionMatcher`.

**Tech Stack:** Swift 6, SwiftUI, Observation framework, AVFoundation / SpeechKit, SwiftData / SRS domain use cases, XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-17-spoken-reflex-blitz-session-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-17-spoken-reflex-blitz-session-design.md)

## Global Constraints

- **Language & Platform:** Swift 6.0+, iOS 17.0+ (utilizing `@Observable` and `Observation` framework).
- **Audio Reliability:** Continuous speech recognition must run on an active `AVAudioEngine` without stopping/restarting between words in a single session.
- **Latency Target:** Word transition delay $< 400\text{ms}$ upon matching lemma; buffer reset $< 15\text{ms}$.
- **Design System:** Strictly adopt existing tokens (`Color.vocabCanvas`, `Color.vocabHeroAccent`, `Color.vocabPeach`, `Color.vocabMint`, `Color.vocabCoral`, `Color.vocabHairline`, `BentoCardButtonStyle`).
- **Touch & Accessibility:** Minimum 44pt touch targets for all interactive elements, dynamic type scaling, and VoiceOver labels.

---

### Task 1: Core Blitz Data Models & Attempt Tracking

**Files:**
- Create: `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`

**Interfaces:**
- Produces: `ReflexSpeedTier`, `ReflexBlitzWordItem`, `ReflexBlitzAttempt`, `ReflexBlitzSessionSummary`, and cloze generator `ReflexClozeFormatter`.

- [ ] **Step 1: Write the failing unit test**

Create `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`:
```swift
@testable import VocabCraftApp
import XCTest

final class ReflexBlitzModelsTests: XCTestCase {
    func testClozeSentenceGeneration() {
        let sentence = "Her fame proved to be ephemeral in the modern era."
        let lemma = "ephemeral"
        let cloze = ReflexClozeFormatter.formatCloze(sentenceEn: sentence, lemma: lemma)
        
        XCTAssertEqual(cloze, "Her fame proved to be [ _________ ] in the modern era.")
    }
    
    func testSpeedTierClassification() {
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 1800, usedHint: false), .flash)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 3200, usedHint: true), .hinted)
        XCTAssertEqual(ReflexSpeedTier.from(responseTimeMs: 6500, usedHint: false), .needsPractice)
    }
    
    func testSessionSummaryCalculations() {
        let attempts = [
            ReflexBlitzAttempt(id: UUID(), wordId: 1, lemma: "ephemeral", responseTimeMs: 1500, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 2, lemma: "serendipity", responseTimeMs: 2200, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 3, lemma: "ubiquitous", responseTimeMs: 6200, usedHint: true, isCorrect: false, timestamp: Date())
        ]
        
        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 2)
        XCTAssertEqual(summary.totalWords, 3)
        XCTAssertEqual(summary.correctWords, 2)
        XCTAssertEqual(summary.weakWordAttempts.count, 1)
        XCTAssertEqual(summary.weakWordAttempts.first?.lemma, "ubiquitous")
        XCTAssertEqual(summary.speedRating, "⚡️ Reflex Master")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzModelsTests`  
Expected: FAIL with "cannot find type 'ReflexClozeFormatter' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift`:
```swift
import Foundation

public enum ReflexSpeedTier: String, Sendable, Codable {
    case flash
    case hinted
    case needsPractice

    public static func from(responseTimeMs: Int, usedHint: Bool) -> ReflexSpeedTier {
        if responseTimeMs < 2500 && !usedHint {
            return .flash
        } else if responseTimeMs < 6000 {
            return .hinted
        } else {
            return .needsPractice
        }
    }
}

public struct ReflexClozeFormatter: Sendable {
    public static func formatCloze(sentenceEn: String, lemma: String) -> String {
        guard !sentenceEn.isEmpty, !lemma.isEmpty else { return sentenceEn }
        let pattern = "(?i)\\b" + NSRegularExpression.escapedPattern(for: lemma) + "\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return sentenceEn.replacingOccurrences(of: lemma, with: "[ _________ ]", options: .caseInsensitive)
        }
        let range = NSRange(sentenceEn.startIndex..., in: sentenceEn)
        return regex.stringByReplacingMatches(in: sentenceEn, options: [], range: range, withTemplate: "[ _________ ]")
    }
}

public struct ReflexBlitzWordItem: Identifiable, Equatable, Sendable {
    public let id: Int
    public let lemma: String
    public let pos: String
    public let definitionVi: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let clozeSentenceEn: String
    public let initialLetterHint: String

    public init(
        id: Int,
        lemma: String,
        pos: String,
        definitionVi: String,
        exampleSentenceEn: String,
        exampleSentenceVi: String
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.definitionVi = definitionVi
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = exampleSentenceVi
        self.clozeSentenceEn = ReflexClozeFormatter.formatCloze(sentenceEn: exampleSentenceEn, lemma: lemma)
        let firstLetter = lemma.prefix(1).lowercased()
        self.initialLetterHint = "\(pos). • \(firstLetter)..."
    }
}

public struct ReflexBlitzAttempt: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let wordId: Int
    public let lemma: String
    public let responseTimeMs: Int
    public let usedHint: Bool
    public let isCorrect: Bool
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        wordId: Int,
        lemma: String,
        responseTimeMs: Int,
        usedHint: Bool,
        isCorrect: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.lemma = lemma
        self.responseTimeMs = responseTimeMs
        self.usedHint = usedHint
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }

    public var speedTier: ReflexSpeedTier {
        ReflexSpeedTier.from(responseTimeMs: responseTimeMs, usedHint: usedHint)
    }
}

public struct ReflexBlitzSessionSummary: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let totalWords: Int
    public let correctWords: Int
    public let averageResponseTimeMs: Int
    public let maxComboStreak: Int
    public let attempts: [ReflexBlitzAttempt]
    public let weakWordAttempts: [ReflexBlitzAttempt]
    public let speedRating: String

    public static func create(from attempts: [ReflexBlitzAttempt], maxCombo: Int) -> ReflexBlitzSessionSummary {
        let total = attempts.count
        let correct = attempts.filter { $0.isCorrect }.count
        let avgTime = total > 0 ? attempts.reduce(0) { $0 + $1.responseTimeMs } / total : 0
        let weak = attempts.filter { !$0.isCorrect || $0.speedTier == .needsPractice }

        let rating: String
        if avgTime <= 2500 && correct == total {
            rating = "⚡️ Reflex Master"
        } else if avgTime <= 4000 && Double(correct) / Double(max(1, total)) >= 0.7 {
            rating = "🔥 Swift Reflex"
        } else {
            rating = "🌱 Steady Learner"
        }

        return ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: total,
            correctWords: correct,
            averageResponseTimeMs: avgTime,
            maxComboStreak: maxCombo,
            attempts: attempts,
            weakWordAttempts: weak,
            speedRating: rating
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzModelsTests`  
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift
git commit -m "feat(reflex): add reflex blitz models, cloze formatter and summary calculations"
```

---

### Task 2: Continuous Speech Recognition & Zero-Latency Word Transition

**Files:**
- Create: `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`

**Interfaces:**
- Produces: `ContinuousReflexSpeechProtocol`, `ContinuousReflexSpeechService`, `MockContinuousReflexSpeechService`.

- [ ] **Step 1: Write the failing unit test**

Create `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`:
```swift
@testable import VocabCraftApp
import XCTest

final class ContinuousReflexSpeechServiceTests: XCTestCase {
    func testTargetSwitchingAndMatching() {
        let mockService = MockContinuousReflexSpeechService()
        var matchedTarget: String?
        
        mockService.onMatchDetected = { matched in
            matchedTarget = matched
        }
        
        mockService.startSession()
        XCTAssertTrue(mockService.isSessionActive)
        
        // Set target 1
        mockService.setTargetWord(lemma: "ephemeral", contextualPhrases: ["Her fame proved to be ephemeral"])
        mockService.simulateTranscript("I think it is ephemeral indeed")
        XCTAssertEqual(matchedTarget, "ephemeral")
        
        // Reset and switch to target 2 without stopping session
        matchedTarget = nil
        mockService.setTargetWord(lemma: "serendipity", contextualPhrases: ["Pure serendipity"])
        mockService.simulateTranscript("serendipity")
        XCTAssertEqual(matchedTarget, "serendipity")
        
        mockService.stopSession()
        XCTAssertFalse(mockService.isSessionActive)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ContinuousReflexSpeechServiceTests`  
Expected: FAIL with "cannot find 'MockContinuousReflexSpeechService' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift`:
```swift
import Foundation
import Speech
import AVFoundation

public protocol ContinuousReflexSpeechProtocol: AnyObject, Sendable {
    var isSessionActive: Bool { get }
    var currentTranscript: String { get }
    func startSession()
    func stopSession()
    func setTargetWord(lemma: String, contextualPhrases: [String])
    func resetBuffer()
}

public final class MockContinuousReflexSpeechService: ContinuousReflexSpeechProtocol, @unchecked Sendable {
    public var isSessionActive: Bool = false
    public var currentTranscript: String = ""
    public var currentTargetLemma: String = ""
    public var contextualPhrases: [String] = []
    public var onMatchDetected: ((String) -> Void)?

    public init() {}

    public func startSession() {
        isSessionActive = true
    }

    public func stopSession() {
        isSessionActive = false
        currentTranscript = ""
        currentTargetLemma = ""
    }

    public func setTargetWord(lemma: String, contextualPhrases: [String]) {
        self.currentTargetLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contextualPhrases = contextualPhrases
        self.currentTranscript = ""
    }

    public func resetBuffer() {
        self.currentTranscript = ""
    }

    public func simulateTranscript(_ text: String) {
        self.currentTranscript = text
        let clean = text.lowercased()
        if !currentTargetLemma.isEmpty && (clean == currentTargetLemma || clean.contains(currentTargetLemma)) {
            onMatchDetected?(currentTargetLemma)
        }
    }
}

public final class ContinuousReflexSpeechService: ContinuousReflexSpeechProtocol, @unchecked Sendable {
    public private(set) var isSessionActive: Bool = false
    public private(set) var currentTranscript: String = ""
    
    private var currentTargetLemma: String = ""
    private var contextualPhrases: [String] = []
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    public init() {}

    public func startSession() {
        guard !isSessionActive else { return }
        isSessionActive = true
        startAudioStream()
    }

    public func stopSession() {
        isSessionActive = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        currentTranscript = ""
        currentTargetLemma = ""
    }

    public func setTargetWord(lemma: String, contextualPhrases: [String]) {
        self.currentTargetLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contextualPhrases = contextualPhrases
        self.currentTranscript = ""
    }

    public func resetBuffer() {
        self.currentTranscript = ""
    }

    private func startAudioStream() {
        let engine = AVAudioEngine()
        self.audioEngine = engine
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation
        self.recognitionRequest = request

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        do {
            try engine.start()
            self.recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    self.onError?(error)
                    return
                }
                if let result = result {
                    let spoken = result.bestTranscription.formattedString
                    self.currentTranscript = spoken
                    self.onTranscriptUpdate?(spoken)
                    self.evaluateSpokenText(spoken)
                }
            }
        } catch {
            self.onError?(error)
        }
    }

    private func evaluateSpokenText(_ spoken: String) {
        guard !currentTargetLemma.isEmpty else { return }
        let clean = spoken.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        if clean == currentTargetLemma || clean.contains(currentTargetLemma) {
            onMatchDetected?(currentTargetLemma)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ContinuousReflexSpeechServiceTests`  
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Services/ContinuousReflexSpeechService.swift VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift
git commit -m "feat(reflex): implement continuous zero-latency speech recognition service"
```

---

### Task 3: ReflexBlitzViewModel & State Machine

**Files:**
- Create: `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzWordItem`, `ContinuousReflexSpeechProtocol`, `EvaluateSRSUseCaseProtocol`, `TextToSpeechProtocol`.
- Produces: `ReflexBlitzPhase` state machine, hint scheduling at 3.5s, auto-advance at 6.0s timeout, combo counter, and summary generator.

- [ ] **Step 1: Write the failing unit test**

Create `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`:
```swift
@testable import VocabCraftApp
import XCTest

@MainActor
final class ReflexBlitzViewModelTests: XCTestCase {
    private var mockSpeech: MockContinuousReflexSpeechService!
    private var mockTTS: MockTextToSpeechService!
    private var mockSRS: MockEvaluateSRSUseCase!
    private var viewModel: ReflexBlitzViewModel!

    override func setUp() {
        super.setUp()
        mockSpeech = MockContinuousReflexSpeechService()
        mockTTS = MockTextToSpeechService()
        mockSRS = MockEvaluateSRSUseCase()
        
        let words = [
            ReflexBlitzWordItem(id: 1, lemma: "ephemeral", pos: "adj.", definitionVi: "Phù du", exampleSentenceEn: "Fame is ephemeral", exampleSentenceVi: "Danh tiếng phù du"),
            ReflexBlitzWordItem(id: 2, lemma: "vital", pos: "adj.", definitionVi: "Quan trọng", exampleSentenceEn: "Water is vital", exampleSentenceVi: "Nước rất quan trọng")
        ]
        
        viewModel = ReflexBlitzViewModel(
            words: words,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
    }

    func testInitialCountdownPhase() {
        XCTAssertEqual(viewModel.phase, .countdown)
        XCTAssertEqual(viewModel.countdownCount, 3)
    }

    func testStartDrillingAndAutoAdvanceOnCorrectMatch() async {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.phase, .drilling)
        XCTAssertEqual(viewModel.currentWordIndex, 0)
        XCTAssertEqual(viewModel.currentWord?.lemma, "ephemeral")
        
        // Simulate correct speech recognition
        mockSpeech.simulateTranscript("ephemeral")
        
        XCTAssertTrue(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    func testHintRevealsAt3500ms() {
        viewModel.beginSessionDirectly()
        XCTAssertFalse(viewModel.showHint)
        
        viewModel.simulateElapsedTime(ms: 3600)
        XCTAssertTrue(viewModel.showHint)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzViewModelTests`  
Expected: FAIL with "cannot find type 'ReflexBlitzViewModel' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift`:
```swift
import Foundation
import Observation

public enum ReflexBlitzPhase: Equatable, Sendable {
    case countdown
    case drilling
    case timeoutRevealing
    case summary
}

@MainActor
@Observable
public final class ReflexBlitzViewModel {
    public var phase: ReflexBlitzPhase = .countdown
    public var countdownCount: Int = 3
    public var words: [ReflexBlitzWordItem] = []
    public var currentWordIndex: Int = 0
    public var elapsedTimeMs: Int = 0
    public var showHint: Bool = false
    public var comboStreak: Int = 0
    public var maxComboStreak: Int = 0
    public var currentAttemptIsCorrect: Bool = false
    public var isKeyboardFallbackActive: Bool = false
    public var sessionSummary: ReflexBlitzSessionSummary?
    public var attempts: [ReflexBlitzAttempt] = []

    private let continuousSpeechService: ContinuousReflexSpeechProtocol
    private let ttsService: TextToSpeechProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol

    private var sessionTimerTask: Task<Void, Never>?
    private var wordStartTime: Date?

    public var currentWord: ReflexBlitzWordItem? {
        guard currentWordIndex >= 0 && currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }

    public var progressFraction: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count)
    }

    public init(
        words: [ReflexBlitzWordItem],
        continuousSpeechService: ContinuousReflexSpeechProtocol,
        ttsService: TextToSpeechProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    ) {
        self.words = words
        self.continuousSpeechService = continuousSpeechService
        self.ttsService = ttsService
        self.evaluateSRSUseCase = evaluateSRSUseCase
    }

    public func startCountdown() {
        phase = .countdown
        countdownCount = 3
        continuousSpeechService.startSession()

        Task { @MainActor in
            for i in stride(from: 3, through: 1, by: -1) {
                self.countdownCount = i
                try? await Task.sleep(for: .seconds(1))
            }
            self.beginDrilling()
        }
    }

    public func beginSessionDirectly() {
        continuousSpeechService.startSession()
        beginDrilling()
    }

    private func beginDrilling() {
        phase = .drilling
        currentWordIndex = 0
        comboStreak = 0
        maxComboStreak = 0
        attempts = []
        loadWord(at: 0)
    }

    private func loadWord(at index: Int) {
        guard index < words.count else {
            finishSession()
            return
        }
        currentWordIndex = index
        let word = words[index]
        showHint = false
        currentAttemptIsCorrect = false
        elapsedTimeMs = 0
        wordStartTime = Date()
        phase = .drilling

        continuousSpeechService.setTargetWord(
            lemma: word.lemma,
            contextualPhrases: [word.exampleSentenceEn]
        )

        startStopwatch()
    }

    private func startStopwatch() {
        sessionTimerTask?.cancel()
        sessionTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self = self, self.phase == .drilling, let start = self.wordStartTime else { break }
                let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                self.elapsedTimeMs = elapsed

                if elapsed >= 3500 && !self.showHint {
                    self.showHint = true
                }

                if elapsed >= 6000 {
                    self.handleTimeout()
                    break
                }
            }
        }
    }

    public func simulateElapsedTime(ms: Int) {
        self.elapsedTimeMs = ms
        if ms >= 3500 {
            self.showHint = true
        }
    }

    public func handleSpokenMatch(_ matchedLemma: String) {
        guard phase == .drilling, let word = currentWord, word.lemma.lowercased() == matchedLemma.lowercased() else { return }
        sessionTimerTask?.cancel()
        currentAttemptIsCorrect = true
        comboStreak += 1
        if comboStreak > maxComboStreak { maxComboStreak = comboStreak }

        let attempt = ReflexBlitzAttempt(
            wordId: word.id,
            lemma: word.lemma,
            responseTimeMs: elapsedTimeMs,
            usedHint: showHint,
            isCorrect: true
        )
        attempts.append(attempt)

        // Dispatch SRS
        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id),
                isCorrect: true,
                responseTimeMs: self.elapsedTimeMs
            )
        }

        // Auto-advance in 400ms
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            self.loadWord(at: self.currentWordIndex + 1)
        }
    }

    public func handleTimeout() {
        guard phase == .drilling, let word = currentWord else { return }
        sessionTimerTask?.cancel()
        phase = .timeoutRevealing
        comboStreak = 0

        let attempt = ReflexBlitzAttempt(
            wordId: word.id,
            lemma: word.lemma,
            responseTimeMs: 6000,
            usedHint: true,
            isCorrect: false
        )
        attempts.append(attempt)

        ttsService.speak(text: word.lemma, rate: 0.5, locale: "en-US")

        Task {
            _ = try? await self.evaluateSRSUseCase.recordReview(
                wordId: Int64(word.id),
                isCorrect: false,
                responseTimeMs: 6000
            )
        }

        // Auto-advance after 1.2s reveal
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            self.loadWord(at: self.currentWordIndex + 1)
        }
    }

    public func finishSession() {
        sessionTimerTask?.cancel()
        continuousSpeechService.stopSession()
        sessionSummary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: maxComboStreak)
        phase = .summary
    }

    public func reDrillWeakWords() {
        guard let summary = sessionSummary, !summary.weakWordAttempts.isEmpty else { return }
        let weakWordIds = Set(summary.weakWordAttempts.map { $0.wordId })
        let reDrillItems = words.filter { weakWordIds.contains($0.id) }
        guard !reDrillItems.isEmpty else { return }
        self.words = reDrillItems
        startCountdown()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzViewModelTests`  
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/ViewModels/ReflexBlitzViewModel.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift
git commit -m "feat(reflex): implement reflex blitz viewmodel state machine and timing logic"
```

---

### Task 4: UI Components (Card, Header, Scaffolding Pill, Countdown)

**Files:**
- Create: `VocabCraftApp/Features/ReflexDrill/Views/ReflexCountdownOverlayView.swift`
- Create: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`
- Create: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`

**Interfaces:**
- Produces: `ReflexCountdownOverlayView`, `ReflexBlitzHeaderView`, `ReflexBlitzCardView`.

- [ ] **Step 1: Write the failing unit test**

Create `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift`:
```swift
@testable import VocabCraftApp
import SwiftUI
import XCTest

final class ReflexBlitzComponentsTests: XCTestCase {
    @MainActor
    func testHeaderViewInstantiation() {
        let header = ReflexBlitzHeaderView(
            currentIndex: 2,
            totalCount: 8,
            comboStreak: 3,
            onClose: {},
            onSkip: {}
        )
        XCTAssertNotNil(header)
    }

    @MainActor
    func testCardViewInstantiation() {
        let word = ReflexBlitzWordItem(
            id: 1,
            lemma: "ephemeral",
            pos: "adj.",
            definitionVi: "Phù du",
            exampleSentenceEn: "Her fame is ephemeral",
            exampleSentenceVi: "Danh tiếng phù du"
        )
        let card = ReflexBlitzCardView(
            word: word,
            showHint: true,
            isCorrect: false,
            isTimeout: false
        )
        XCTAssertNotNil(card)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzComponentsTests`  
Expected: FAIL with "cannot find type 'ReflexBlitzHeaderView' in scope"

- [ ] **Step 3: Write minimal implementations**

Create `VocabCraftApp/Features/ReflexDrill/Views/ReflexCountdownOverlayView.swift`:
```swift
import SwiftUI

public struct ReflexCountdownOverlayView: View {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(count > 0 ? "\(count)" : "GO!")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundColor(.vocabPeach)
                    .scaleEffect(count > 0 ? 1.0 : 1.3)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: count)

                Text("Chuẩn bị nói từ tiếng Anh...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}
```

Create `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift`:
```swift
import SwiftUI

public struct ReflexBlitzHeaderView: View {
    public let currentIndex: Int
    public let totalCount: Int
    public let comboStreak: Int
    public let onClose: () -> Void
    public let onSkip: () -> Void

    public init(
        currentIndex: Int,
        totalCount: Int,
        comboStreak: Int,
        onClose: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.comboStreak = comboStreak
        self.onClose = onClose
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.vocabInk)
                        .frame(width: 36, height: 36)
                        .background(Color.vocabMuted.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(BentoCardButtonStyle())

                Spacer()

                if comboStreak >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("x\(comboStreak) COMBO")
                            .fontWeight(.heavy)
                    }
                    .font(.caption.smallCaps())
                    .foregroundColor(.vocabPeach)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.vocabPeach.opacity(0.15))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                Button(action: onSkip) {
                    Text("Bỏ qua")
                        .font(.subheadline.bold())
                        .foregroundColor(.vocabMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.vocabMuted.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(BentoCardButtonStyle())
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.vocabHairline)
                        .frame(height: 6)

                    Capsule()
                        .fill(Color.vocabHeroAccent)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(1, totalCount)))), height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal)
    }
}
```

Create `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`:
```swift
import SwiftUI

public struct ReflexBlitzCardView: View {
    public let word: ReflexBlitzWordItem
    public let showHint: Bool
    public let isCorrect: Bool
    public let isTimeout: Bool

    public init(
        word: ReflexBlitzWordItem,
        showHint: Bool,
        isCorrect: Bool,
        isTimeout: Bool
    ) {
        self.word = word
        self.showHint = showHint
        self.isCorrect = isCorrect
        self.isTimeout = isTimeout
    }

    public var body: some View {
        VStack(spacing: 20) {
            // English Cloze Sentence
            Text(isTimeout ? word.exampleSentenceEn : word.clozeSentenceEn)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(isTimeout ? .vocabCoral : (isCorrect ? .vocabMint : .vocabInk))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.2), value: isTimeout)

            // Vietnamese Subtitle
            Text(word.definitionVi)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.vocabMuted)
                .multilineTextAlignment(.center)

            // Progressive Scaffolding Pill
            if showHint && !isCorrect && !isTimeout {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                    Text("Gợi ý: \(word.initialLetterHint)")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.vocabPeach.opacity(0.15))
                .foregroundColor(.vocabPeach)
                .clipShape(Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    isCorrect ? Color.vocabMint : (isTimeout ? Color.vocabCoral : Color.vocabHairline),
                    lineWidth: isCorrect || isTimeout ? 2.5 : 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzComponentsTests`  
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexCountdownOverlayView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzHeaderView.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzComponentsTests.swift
git commit -m "feat(reflex): add reflex blitz card, header, scaffolding and countdown views"
```

---

### Task 5: Speed & Mastery Summary Dashboard with 1-Tap Re-drill

**Files:**
- Create: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`

**Interfaces:**
- Produces: `ReflexBlitzSummaryView` (Displays speed metrics, weak list, and handlers for `onReDrillWeak` and `onFinish`).

- [ ] **Step 1: Write the failing unit test**

Create `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift`:
```swift
@testable import VocabCraftApp
import SwiftUI
import XCTest

final class ReflexBlitzSummaryViewTests: XCTestCase {
    @MainActor
    func testSummaryViewInstantiation() {
        let summary = ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: 5,
            correctWords: 4,
            averageResponseTimeMs: 1900,
            maxComboStreak: 4,
            attempts: [],
            weakWordAttempts: [],
            speedRating: "⚡️ Reflex Master"
        )
        let view = ReflexBlitzSummaryView(
            summary: summary,
            onReDrillWeak: {},
            onFinish: {}
        )
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzSummaryViewTests`  
Expected: FAIL with "cannot find type 'ReflexBlitzSummaryView' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift`:
```swift
import SwiftUI

public struct ReflexBlitzSummaryView: View {
    public let summary: ReflexBlitzSessionSummary
    public let onReDrillWeak: () -> Void
    public let onFinish: () -> Void

    public init(
        summary: ReflexBlitzSessionSummary,
        onReDrillWeak: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.summary = summary
        self.onReDrillWeak = onReDrillWeak
        self.onFinish = onFinish
    }

    private var formattedAvgTime: String {
        String(format: "%.1fs", Double(summary.averageResponseTimeMs) / 1000.0)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Title Badge
                VStack(spacing: 8) {
                    Text(summary.speedRating)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.vocabInk)

                    Text("Hoàn thành phiên phản xạ Blitz")
                        .font(.subheadline)
                        .foregroundColor(.vocabMuted)
                }
                .padding(.top, 20)

                // Bento Metrics Grid
                HStack(spacing: 12) {
                    // Avg Speed Card
                    VStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.title3)
                            .foregroundColor(.vocabPeach)
                        Text(formattedAvgTime)
                            .font(.title2.bold())
                            .foregroundColor(.vocabInk)
                        Text("Tốc độ TB")
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)

                    // Accuracy Card
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.vocabMint)
                        Text("\(summary.correctWords)/\(summary.totalWords)")
                            .font(.title2.bold())
                            .foregroundColor(.vocabInk)
                        Text("Độ chính xác")
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)

                    // Max Combo Card
                    VStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .foregroundColor(.vocabLavender)
                        Text("x\(summary.maxComboStreak)")
                            .font(.title2.bold())
                            .foregroundColor(.vocabInk)
                        Text("Max Combo")
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)
                }
                .padding(.horizontal)

                // Weak Words Section
                if !summary.weakWordAttempts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Từ cần củng cố (\(summary.weakWordAttempts.count))")
                            .font(.headline)
                            .foregroundColor(.vocabInk)
                            .padding(.horizontal)

                        ForEach(summary.weakWordAttempts) { weak in
                            HStack {
                                Text(weak.lemma)
                                    .font(.body.bold())
                                    .foregroundColor(.vocabInk)

                                Spacer()

                                Text(weak.responseTimeMs >= 6000 ? "Hết giờ" : "\(String(format: "%.1fs", Double(weak.responseTimeMs)/1000.0))")
                                    .font(.caption.bold())
                                    .foregroundColor(.vocabCoral)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.vocabCoral.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .padding()
                            .background(Color.vocabSurfaceCard)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }

                        // Re-drill Button
                        Button(action: onReDrillWeak) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Củng cố ngay \(summary.weakWordAttempts.count) từ yếu")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.vocabCoral)
                            .cornerRadius(16)
                            .shadow(color: Color.vocabCoral.opacity(0.3), radius: 8, y: 4)
                        }
                        .buttonStyle(BentoCardButtonStyle())
                        .padding(.horizontal)
                    }
                }

                // Finish Button
                Button(action: onFinish) {
                    Text("Hoàn thành & Lưu tiến độ")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.vocabHeroAccent)
                        .cornerRadius(16)
                        .shadow(color: Color.vocabHeroAccent.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(BentoCardButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzSummaryViewTests`  
Expected: PASS with 0 failures.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzSummaryView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzSummaryViewTests.swift
git commit -m "feat(reflex): add reflex blitz summary dashboard with 1-tap re-drill"
```

---

### Task 6: Main Screen Assembly, Navigation Wiring & End-to-End Integration

**Files:**
- Create: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/ActionCardsGrid.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`

**Interfaces:**
- Produces: `ReflexBlitzView` as the root presentation sheet/screen for continuous blitz practice.

- [ ] **Step 1: Write the failing unit test**

Create `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift`:
```swift
@testable import VocabCraftApp
import SwiftUI
import XCTest

@MainActor
final class ReflexBlitzViewIntegrationTests: XCTestCase {
    func testBlitzViewInstantiation() {
        let mockSpeech = MockContinuousReflexSpeechService()
        let mockTTS = MockTextToSpeechService()
        let mockSRS = MockEvaluateSRSUseCase()
        let words = [
            ReflexBlitzWordItem(id: 1, lemma: "ephemeral", pos: "adj.", definitionVi: "Phù du", exampleSentenceEn: "Her fame is ephemeral", exampleSentenceVi: "Danh tiếng phù du")
        ]
        let vm = ReflexBlitzViewModel(
            words: words,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
        let view = ReflexBlitzView(viewModel: vm, onDismiss: {})
        XCTAssertNotNil(view)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzViewIntegrationTests`  
Expected: FAIL with "cannot find type 'ReflexBlitzView' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift`:
```swift
import SwiftUI

public struct ReflexBlitzView: View {
    @State private var viewModel: ReflexBlitzViewModel
    public var onDismiss: () -> Void

    public init(viewModel: ReflexBlitzViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            if viewModel.phase == .summary, let summary = viewModel.sessionSummary {
                ReflexBlitzSummaryView(
                    summary: summary,
                    onReDrillWeak: {
                        viewModel.reDrillWeakWords()
                    },
                    onFinish: onDismiss
                )
            } else {
                VStack(spacing: 24) {
                    // Header Bar
                    ReflexBlitzHeaderView(
                        currentIndex: viewModel.currentWordIndex,
                        totalCount: viewModel.words.count,
                        comboStreak: viewModel.comboStreak,
                        onClose: onDismiss,
                        onSkip: {
                            viewModel.handleTimeout()
                        }
                    )
                    .padding(.top)

                    Spacer()

                    // Challenge Card
                    if let word = viewModel.currentWord {
                        ReflexBlitzCardView(
                            word: word,
                            showHint: viewModel.showHint,
                            isCorrect: viewModel.currentAttemptIsCorrect,
                            isTimeout: viewModel.phase == .timeoutRevealing
                        )
                    }

                    Spacer()

                    // Visualizer & Listening Indicator
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Capsule()
                                    .fill(Color.vocabHeroAccent)
                                    .frame(width: 4, height: CGFloat(12 + (index % 3) * 8))
                            }
                        }
                        .frame(height: 32)

                        Text("Nói từ tiếng Anh vào micro...")
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                    .padding(.bottom, 30)
                }

                if viewModel.phase == .countdown {
                    ReflexCountdownOverlayView(count: viewModel.countdownCount)
                }
            }
        }
        .onAppear {
            if viewModel.phase == .countdown {
                viewModel.startCountdown()
            }
        }
    }
}
```

- [ ] **Step 4: Run test and full suite to verify everything passes**

Run: `swift test`  
Expected: PASS all test suites.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewIntegrationTests.swift
git commit -m "feat(reflex): assemble reflex blitz main view and integrate with homepage action cards"
```

---
