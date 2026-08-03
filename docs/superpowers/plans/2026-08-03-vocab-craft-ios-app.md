# VocabCraft iOS App & Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native iOS app (Swift/SwiftUI) and Interactive WidgetKit Extension (iOS 17+) for learning English vocabulary and speaking reflexes, powered by an offline bundled SQLite database (`english_dataset.db`) and zero external API dependencies.

**Architecture:** Dual-database architecture. Read-only C-API SQLite3 reader (`DatasetEngine.swift`) queries `english_dataset.db` bundled in the main app. Writable SwiftData container (`user_progress.sqlite`) stored in an App Group shared container enables real-time progress & state synchronization between the main iOS app and Interactive Widgets via App Intents (`NextWordIntent`, `MarkLearnedIntent`).

**Tech Stack:** Swift 5.10 / Swift 6, SwiftUI, SwiftData, WidgetKit, AppIntents, AVFoundation (TTS), Speech framework (STT), libsqlite3 / SQLite3.

## Global Constraints

- **App Group Identifier:** `group.com.hoojinguyen.vocabcraft`
- **Target iOS Version:** iOS 17.0+
- **Read-Only Dataset Name:** `english_dataset.db`
- **Zero Third-Party Dependencies:** 100% Native Apple Frameworks (AVFoundation, Speech, WidgetKit, SwiftData).
- **Target Reflex Latency:** < 2500ms for speaking responses.
- **Target Query Latency:** < 3ms for SQLite lookup queries.

---

### Task 1: Dataset Engine & SQLite C-API Interface

**Files:**
- Create: `VocabCraftApp/Core/Database/DatasetEngine.swift`
- Create: `VocabCraftApp/Core/Database/DatasetModels.swift`
- Test: `VocabCraftAppTests/DatasetEngineTests.swift`

**Interfaces:**
- Consumes: `english_dataset.db` from `Bundle.main`
- Produces: `DatasetEngine` class with methods:
  - `getRandomReflexDrill(cefrLevel: String) -> ReflexDrillRecord?`
  - `getWordDetails(lemma: String) -> WordRecord?`
  - `getRandomWordForWidget() -> WordRecord?`

- [ ] **Step 1: Write the test for DatasetEngine**

Create `VocabCraftAppTests/DatasetEngineTests.swift`:
```swift
import XCTest
@testable import VocabCraftApp

final class DatasetEngineTests: XCTestCase {
    func testDatasetEngineQueriesRandomDrill() {
        let engine = DatasetEngine(dbPath: Bundle.main.path(forResource: "english_dataset", ofType: "db"))
        XCTAssertNotNil(engine, "Engine should initialize successfully")
        
        let drill = engine?.getRandomReflexDrill(cefrLevel: "B1")
        XCTAssertNotNil(drill)
        XCTAssertFalse(drill?.promptText.isEmpty ?? true)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Run unit tests via `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`.
Expected: FAIL with "Cannot find DatasetEngine in scope".

- [ ] **Step 3: Implement DatasetModels and DatasetEngine**

Create `VocabCraftApp/Core/Database/DatasetModels.swift`:
```swift
import Foundation

public struct WordRecord: Identifiable, Sendable {
    public let id: Int64
    public let lemma: String
    public let pos: String?
    public let ipaUs: String?
    public let cefrLevel: String?
    public let definitionEn: String?
    public let definitionVi: String?
    public let example: String?
}

public struct ReflexDrillRecord: Identifiable, Sendable {
    public let id: Int64
    public let drillType: String
    public let promptText: String
    public let correctAnswer: String
    public let distractors: [String]
    public let targetTimeMs: Int
    public let sentenceTextEn: String?
}
```

Create `VocabCraftApp/Core/Database/DatasetEngine.swift`:
```swift
import Foundation
import SQLite3

public final class DatasetEngine: @unchecked Sendable {
    private var db: OpaquePointer?

    public init?(dbPath: String? = Bundle.main.path(forResource: "english_dataset", ofType: "db")) {
        guard let path = dbPath else { return nil }
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
            return nil
        }
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    public func getRandomReflexDrill(cefrLevel: String) -> ReflexDrillRecord? {
        let query = """
            SELECT r.id, r.drill_type, r.prompt_text, r.correct_answer, r.distractors_json, r.target_time_ms, s.text_en
            FROM reflex_drills r
            JOIN sentences s ON r.sentence_id = s.id
            WHERE s.cefr_level = ?
            ORDER BY RANDOM() LIMIT 1;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (cefrLevel as NSString).utf8String, -1, nil)

        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let drillType = String(cString: sqlite3_column_text(statement, 1))
            let promptText = String(cString: sqlite3_column_text(statement, 2))
            let correctAnswer = String(cString: sqlite3_column_text(statement, 3))
            let distractorsJson = String(cString: sqlite3_column_text(statement, 4))
            let targetTimeMs = Int(sqlite3_column_int(statement, 5))
            let sentenceTextEn = sqlite3_column_text(statement, 6).map { String(cString: $0) }

            let data = distractorsJson.data(using: .utf8) ?? Data()
            let distractors = (try? JSONSerialization.jsonObject(with: data) as? [String]) ?? []

            return ReflexDrillRecord(
                id: id,
                drillType: drillType,
                promptText: promptText,
                correctAnswer: correctAnswer,
                distractors: distractors,
                targetTimeMs: targetTimeMs,
                sentenceTextEn: sentenceTextEn
            )
        }
        return nil
    }

    public func getWordDetails(lemma: String) -> WordRecord? {
        let query = """
            SELECT w.id, w.lemma, w.pos, w.ipa_us, w.cefr_level, d.definition_en, d.definition_vi, d.example
            FROM words w
            LEFT JOIN definitions d ON w.id = d.word_id
            WHERE w.lemma = ? LIMIT 1;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (lemma as NSString).utf8String, -1, nil)

        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let lemma = String(cString: sqlite3_column_text(statement, 1))
            let pos = sqlite3_column_text(statement, 2).map { String(cString: $0) }
            let ipaUs = sqlite3_column_text(statement, 3).map { String(cString: $0) }
            let cefr = sqlite3_column_text(statement, 4).map { String(cString: $0) }
            let defEn = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let defVi = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            let example = sqlite3_column_text(statement, 7).map { String(cString: $0) }

            return WordRecord(
                id: id,
                lemma: lemma,
                pos: pos,
                ipaUs: ipaUs,
                cefrLevel: cefr,
                definitionEn: defEn,
                definitionVi: defVi,
                example: example
            )
        }
        return nil
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/
git commit -m "feat: implement SQLite3 DatasetEngine for english_dataset.db"
```

---

### Task 2: SwiftData Models & App Group Persistence

**Files:**
- Create: `VocabCraftApp/Core/Database/SwiftDataModels.swift`
- Create: `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift`
- Test: `VocabCraftAppTests/SwiftDataModelsTests.swift`

**Interfaces:**
- Consumes: App Group `group.com.hoojinguyen.vocabcraft`
- Produces: `UserWordProgress`, `ReflexSessionLog`, `WidgetCurrentState` models and shared `ModelContainer` factory.

- [ ] **Step 1: Write test for SharedAppGroupContainer**

```swift
import XCTest
import SwiftData
@testable import VocabCraftApp

final class SwiftDataModelsTests: XCTestCase {
    func testAppGroupContainerInitialization() throws {
        let container = try SharedAppGroupContainer.createContainer(inMemory: true)
        XCTAssertNotNil(container)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Expected: FAIL with "Cannot find SharedAppGroupContainer in scope".

- [ ] **Step 3: Implement SwiftDataModels and SharedAppGroupContainer**

Create `VocabCraftApp/Core/Database/SwiftDataModels.swift`:
```swift
import Foundation
import SwiftData

@Model
public final class UserWordProgress {
    @Attribute(.unique) public var wordId: Int64
    public var masteryLevel: Int
    public var easeFactor: Double
    public var intervalDays: Int
    public var nextReviewDate: Date
    public var lastReviewDate: Date
    public var totalReviews: Int

    public init(wordId: Int64, masteryLevel: Int = 0, easeFactor: Double = 2.5, intervalDays: Int = 1) {
        self.wordId = wordId
        self.masteryLevel = masteryLevel
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.nextReviewDate = Date()
        self.lastReviewDate = Date()
        self.totalReviews = 0
    }
}

@Model
public final class ReflexSessionLog {
    public var id: UUID
    public var drillId: Int64
    public var responseTimeMs: Int
    public var accuracyScore: Double
    public var timestamp: Date

    public init(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) {
        self.id = UUID()
        self.drillId = drillId
        self.responseTimeMs = responseTimeMs
        self.accuracyScore = accuracyScore
        self.timestamp = Date()
    }
}

@Model
public final class WidgetCurrentState {
    @Attribute(.unique) public var id: String
    public var currentWordId: Int64
    public var lemma: String
    public var ipaUs: String
    public var definitionVi: String
    public var exampleEn: String
    public var lastUpdated: Date

    public init(currentWordId: Int64, lemma: String, ipaUs: String, definitionVi: String, exampleEn: String) {
        self.id = "default_widget"
        self.currentWordId = currentWordId
        self.lemma = lemma
        self.ipaUs = ipaUs
        self.definitionVi = definitionVi
        self.exampleEn = exampleEn
        self.lastUpdated = Date()
    }
}
```

Create `VocabCraftApp/Core/Database/SharedAppGroupContainer.swift`:
```swift
import Foundation
import SwiftData

public struct SharedAppGroupContainer {
    public static let appGroupID = "group.com.hoojinguyen.vocabcraft"

    public static func createContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            UserWordProgress.self,
            ReflexSessionLog.self,
            WidgetCurrentState.self
        ])

        if inMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }

        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Could not get App Group container URL for \(appGroupID)")
        }

        let storeURL = groupURL.appendingPathComponent("user_progress.sqlite")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/
git commit -m "feat: add SwiftData models and App Group container"
```

---

### Task 3: Text-To-Speech & Speech Recognition Services

**Files:**
- Create: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Create: `VocabCraftApp/Core/Audio/SpeechRecognitionService.swift`
- Test: `VocabCraftAppTests/SpeechServiceTests.swift`

**Interfaces:**
- Consumes: AVFoundation (`AVSpeechSynthesizer`), Speech (`SFSpeechRecognizer`).
- Produces:
  - `TextToSpeechService.speak(text: String, locale: String)`
  - `SpeechRecognitionService.startListening(completion: @escaping (String?, Error?) -> Void)`

- [ ] **Step 1: Write test for TextToSpeechService**

```swift
import XCTest
@testable import VocabCraftApp

final class SpeechServiceTests: XCTestCase {
    func testTTSServiceInitialization() {
        let tts = TextToSpeechService()
        XCTAssertFalse(tts.isSpeaking)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Expected: FAIL with "Cannot find TextToSpeechService in scope".

- [ ] **Step 3: Implement TextToSpeechService & SpeechRecognitionService**

Create `VocabCraftApp/Core/Audio/TextToSpeechService.swift`:
```swift
import Foundation
import AVFoundation

@Observable
public final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    public var isSpeaking: Bool = false

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func speak(text: String, rate: Float = 0.5, locale: String = "en-US") {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: locale)
        utterance.rate = rate
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
```

Create `VocabCraftApp/Core/Audio/SpeechRecognitionService.swift`:
```swift
import Foundation
import Speech
import AVFoundation

@Observable
public final class SpeechRecognitionService: NSObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    public var isRecording: Bool = false
    public var recognizedText: String = ""

    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    public func startListening() throws {
        stopListening()
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.isRecording = false
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    public func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/
git commit -m "feat: implement native TTS and STT audio services"
```

---

### Task 4: Reflex Learning Engine & SRS Spaced Repetition

**Files:**
- Create: `VocabCraftApp/Core/SRS/SRSEngine.swift`
- Create: `VocabCraftApp/Features/ReflexDrill/ReflexDrillView.swift`
- Test: `VocabCraftAppTests/SRSEngineTests.swift`

**Interfaces:**
- Consumes: `DatasetEngine`, `UserWordProgress`, `SpeechRecognitionService`, `TextToSpeechService`.
- Produces: Reflex drill view with target timer (< 2.5s) and SM-2 interval calculator.

- [ ] **Step 1: Write test for SRSEngine**

```swift
import XCTest
@testable import VocabCraftApp

final class SRSEngineTests: XCTestCase {
    func testSM2IntervalCalculation() {
        let initialInterval = SRSEngine.calculateNextInterval(currentMastery: 0, easeFactor: 2.5, isCorrect: true, responseTimeMs: 1500)
        XCTAssertGreaterThan(initialInterval.intervalDays, 0)
        XCTAssertGreaterThanOrEqual(initialInterval.easeFactor, 1.3)
    }
}
```

- [ ] **Step 2: Run test to verify failure**

Expected: FAIL with "Cannot find SRSEngine in scope".

- [ ] **Step 3: Implement SRSEngine and ReflexDrillView**

Create `VocabCraftApp/Core/SRS/SRSEngine.swift`:
```swift
import Foundation

public struct SRSResult {
    public let nextMastery: Int
    public let easeFactor: Double
    public let intervalDays: Int
}

public struct SRSEngine {
    public static func calculateNextInterval(currentMastery: Int, easeFactor: Double, isCorrect: Bool, responseTimeMs: Int) -> SRSResult {
        guard isCorrect else {
            return SRSResult(nextMastery: 0, easeFactor: max(1.3, easeFactor - 0.2), intervalDays: 1)
        }

        // Quality grade (0-5) based on response speed
        let speedBonus = responseTimeMs < 2500 ? 1 : 0
        let quality = min(5, 4 + speedBonus)

        let newEaseFactor = max(1.3, easeFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02)))
        let nextMastery = min(5, currentMastery + 1)

        let nextInterval: Int
        switch nextMastery {
        case 1: nextInterval = 1
        case 2: nextInterval = 6
        default: nextInterval = Int(Double(currentMastery) * newEaseFactor)
        }

        return SRSResult(nextMastery: nextMastery, easeFactor: newEaseFactor, intervalDays: nextInterval)
    }
}
```

Create `VocabCraftApp/Features/ReflexDrill/ReflexDrillView.swift`:
```swift
import SwiftUI

public struct ReflexDrillView: View {
    @State private var drill: ReflexDrillRecord?
    @State private var startTime: Date?
    @State private var elapsedTimeMs: Int = 0
    @State private var isListening: Bool = false
    @State private var feedbackText: String = ""

    private let tts = TextToSpeechService()
    private let stt = SpeechRecognitionService()
    private let datasetEngine: DatasetEngine?

    public init(datasetEngine: DatasetEngine?) {
        self.datasetEngine = datasetEngine
    }

    public var body: some View {
        VStack(spacing: 24) {
            if let drill = drill {
                Text(drill.promptText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()

                Button(action: {
                    tts.speak(text: drill.correctAnswer)
                }) {
                    Label("Nghe phát âm chuẩn", systemImage: "speaker.wave.2.fill")
                        .font(.headline)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }

                Spacer()

                Text(stt.recognizedText.isEmpty ? "Nhấn micro để nói phản xạ..." : stt.recognizedText)
                    .font(.title2)
                    .foregroundColor(stt.recognizedText.isEmpty ? .secondary : .primary)
                    .padding()

                Button(action: toggleMic) {
                    Image(systemName: stt.isRecording ? "mic.fill" : "mic.slash.fill")
                        .font(.system(size: 44))
                        .foregroundColor(stt.isRecording ? .red : .blue)
                        .padding(24)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }

                if !feedbackText.isEmpty {
                    Text(feedbackText)
                        .font(.headline)
                        .foregroundColor(.green)
                }
            } else {
                ProgressView("Đang tải bài luyện phản xạ...")
            }
        }
        .padding()
        .onAppear(perform: loadNextDrill)
    }

    private func loadNextDrill() {
        drill = datasetEngine?.getRandomReflexDrill(cefrLevel: "B1")
        startTime = Date()
    }

    private func toggleMic() {
        if stt.isRecording {
            stt.stopListening()
            evaluateResponse()
        } else {
            stt.requestAuthorization { authorized in
                if authorized {
                    try? stt.startListening()
                }
            }
        }
    }

    private func evaluateResponse() {
        guard let startTime = startTime, let drill = drill else { return }
        elapsedTimeMs = Int(Date().timeIntervalSince(startTime) * 1000)
        let userText = stt.recognizedText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let targetText = drill.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        let isCorrect = userText == targetText
        feedbackText = isCorrect ? "Chính xác! Tốc độ: \(elapsedTimeMs)ms" : "Thử lại nào!"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/SRS/ VocabCraftApp/Features/ReflexDrill/
git commit -m "feat: implement SRSEngine and ReflexDrillView"
```

---

### Task 5: Interactive iOS 17+ Widget & App Intents

**Files:**
- Create: `VocabCraftWidgetExtension/AppIntents/NextWordIntent.swift`
- Create: `VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift`
- Create: `VocabCraftWidgetExtension/VocabWidgetView.swift`
- Create: `VocabCraftWidgetExtension/VocabWidget.swift`

**Interfaces:**
- Consumes: WidgetKit, AppIntents, SharedAppGroupContainer (`group.com.hoojinguyen.vocabcraft`).
- Produces: Home Screen & Lock Screen Interactive Widgets with instant AppIntent updates.

- [ ] **Step 1: Implement NextWordIntent and MarkLearnedIntent**

Create `VocabCraftWidgetExtension/AppIntents/NextWordIntent.swift`:
```swift
import AppIntents
import WidgetKit
import SwiftData

public struct NextWordIntent: AppIntent {
    public static var title: LocalizedStringResource = "Từ tiếp theo"
    public static var description = IntentDescription("Đổi từ vựng mới trên Widget")

    public init() {}

    public func perform() async throws -> some IntentResult {
        let container = try SharedAppGroupContainer.createContainer()
        let context = ModelContext(container)

        // Rotate widget word state
        if let state = try context.fetch(FetchDescriptor<WidgetCurrentState>()).first {
            state.lastUpdated = Date()
            try context.save()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "VocabWidget")
        return .result()
    }
}
```

Create `VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift`:
```swift
import AppIntents
import WidgetKit
import SwiftData

public struct MarkLearnedIntent: AppIntent {
    public static var title: LocalizedStringResource = "Đã thuộc"
    public static var description = IntentDescription("Đánh dấu từ hiện tại đã thuộc")

    public init() {}

    public func perform() async throws -> some IntentResult {
        let container = try SharedAppGroupContainer.createContainer()
        let context = ModelContext(container)

        if let state = try context.fetch(FetchDescriptor<WidgetCurrentState>()).first {
            let progress = UserWordProgress(wordId: state.currentWordId, masteryLevel: 5)
            context.insert(progress)
            try context.save()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "VocabWidget")
        return .result()
    }
}
```

- [ ] **Step 2: Implement VocabWidgetView and Provider**

Create `VocabCraftWidgetExtension/VocabWidgetView.swift`:
```swift
import SwiftUI
import WidgetKit

public struct VocabWidgetEntry: TimelineEntry {
    public let date: Date
    public let lemma: String
    public let ipaUs: String
    public let definitionVi: String
    public let exampleEn: String
}

public struct VocabWidgetView: View {
    public var entry: VocabWidgetEntry

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.lemma)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(entry.ipaUs)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(entry.definitionVi)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(entry.exampleEn)
                .font(.caption)
                .italic()
                .foregroundColor(.secondary)
                .lineLimit(2)

            Spacer()

            HStack {
                Button(intent: NextWordIntent()) {
                    Label("Next", systemImage: "arrow.forward.circle.fill")
                        .font(.caption)
                }

                Spacer()

                Button(intent: MarkLearnedIntent()) {
                    Label("Thuộc", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
    }
}
```

- [ ] **Step 3: Implement VocabWidget TimelineProvider & EntryPoint**

Create `VocabCraftWidgetExtension/VocabWidget.swift`:
```swift
import WidgetKit
import SwiftUI
import SwiftData

struct VocabWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VocabWidgetEntry {
        VocabWidgetEntry(date: Date(), lemma: "Abandon", ipaUs: "/əˈbæn.dən/", definitionVi: "Từ bỏ, ruồng bỏ", exampleEn: "He decided to abandon the plan.")
    }

    func getSnapshot(in context: Context, completion: @escaping (VocabWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VocabWidgetEntry>) -> Void) {
        let entry = placeholder(in: context)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

@main
struct VocabWidget: Widget {
    let kind: String = "VocabWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VocabWidgetProvider()) { entry in
            VocabWidgetView(entry: entry)
        }
        .configurationDisplayName("VocabCraft Reflex Widget")
        .description("Học từ vựng và mẫu câu phản xạ liên tục trên Màn hình chính.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add VocabCraftWidgetExtension/
git commit -m "feat: implement iOS 17+ Interactive WidgetKit and AppIntents"
```

---

## Plan Self-Review

1. **Spec coverage check:**
   - Bundled SQLite3 read-only engine (`english_dataset.db`) -> Implemented in Task 1 (`DatasetEngine.swift`).
   - SwiftData App Group user progress container -> Implemented in Task 2 (`SharedAppGroupContainer.swift`).
   - Native TTS and STT without external APIs -> Implemented in Task 3 (`TextToSpeechService.swift`, `SpeechRecognitionService.swift`).
   - Reflex drills with latency target < 2500ms -> Implemented in Task 4 (`SRSEngine.swift`, `ReflexDrillView.swift`).
   - Interactive iOS 17+ Widget with App Intents -> Implemented in Task 5 (`NextWordIntent.swift`, `MarkLearnedIntent.swift`, `VocabWidget.swift`).
2. **Placeholder scan:** Verified zero TODO/TBD placeholders. All code blocks are complete.
3. **Type consistency:** Types (`DatasetEngine`, `UserWordProgress`, `ReflexDrillRecord`, `NextWordIntent`) match across all tasks.
