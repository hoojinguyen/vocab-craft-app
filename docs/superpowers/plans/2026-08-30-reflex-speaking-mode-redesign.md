# Reflex Speaking Mode Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Reflex Speaking Mode to use 3D Flip Card architecture with `CraftTactileMicHubView` and a resilient speech pipeline that separates `AVAudioEngine` lifecycle from `SFSpeechRecognitionRequest` lifecycle — achieving full parity with the 3 completed modes (MC, Listening, Typing).

**Architecture:** Clean Architecture + MVVM. New `ResilientReflexSpeechEngine` replaces `ContinuousReflexSpeechService` for speaking mode. View rebuilt with `CraftFlipCard(.tactile3D)` + `CraftTactileMicHubView` on canvas. ViewModel updated to use new engine interface with simplified `beginWord()`/`endWord()` lifecycle.

**Tech Stack:** SwiftUI, AVFoundation, Speech framework, SpeechKit package, CraftUIKit design system, Swift Testing / XCTest

**Spec:** `docs/superpowers/specs/2026-08-30-reflex-speaking-mode-redesign-design.md`

## Global Constraints

- iOS 17.0+ deployment target
- All UI styling via CraftUIKit tokens — zero raw colors, fonts, padding
- All strings via localization (`AppStrings` / `Localizable.xcstrings`) — zero hardcoded strings
- `CraftFlipCard` must use `.tactile3D` style (consistency with other 3 modes)
- `CraftBadge` info uses `.subtle`, hint uses `.outline`, transcript uses `.solid`
- `@MainActor` isolation for all UI and speech engine code — no `NSLock`
- All new files must pass SwiftLint and compile with zero warnings

---

### Task 1: Protocol & Mock — `ReflexSpeechEngineProtocol`

**Files:**
- Create: `VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift`
- Create: `VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift`
- Test: `VocabCraftAppTests/Features/Reflex/MockResilientReflexSpeechEngineTests.swift`

**Interfaces:**
- Consumes: Nothing (foundation layer)
- Produces:
  - `ReflexSpeechEngineProtocol` — protocol with `startSession(contextualPhrases:)`, `stopSession()`, `beginWord(targetLemma:contextualPhrases:)`, `endWord()`, observable properties `isSessionActive`, `isWordActive`, `liveTranscript`, callback closures `onMatchDetected`, `onTranscriptUpdate`, `onError`
  - `MockResilientReflexSpeechEngine` — testable mock conforming to protocol

- [ ] **Step 1: Write the protocol**

```swift
// VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift
import Foundation

@MainActor
public protocol ReflexSpeechEngineProtocol: AnyObject {
    var isSessionActive: Bool { get }
    var isWordActive: Bool { get }
    var liveTranscript: String { get }
    var onMatchDetected: ((String) -> Void)? { get set }
    var onTranscriptUpdate: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func startSession(contextualPhrases: [String])
    func stopSession()
    func beginWord(targetLemma: String, contextualPhrases: [String])
    func endWord()
}
```

- [ ] **Step 2: Write the mock implementation**

```swift
// VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift
import Foundation

@MainActor
public final class MockResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    public var isSessionActive: Bool = false
    public var isWordActive: Bool = false
    public var liveTranscript: String = ""
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // Test tracking
    public var startSessionCallCount: Int = 0
    public var stopSessionCallCount: Int = 0
    public var beginWordCallCount: Int = 0
    public var endWordCallCount: Int = 0
    public var lastTargetLemma: String = ""
    public var lastContextualPhrases: [String] = []

    public init() {}

    public func startSession(contextualPhrases: [String]) {
        isSessionActive = true
        startSessionCallCount += 1
    }

    public func stopSession() {
        isSessionActive = false
        isWordActive = false
        liveTranscript = ""
        stopSessionCallCount += 1
    }

    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        lastTargetLemma = targetLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        lastContextualPhrases = contextualPhrases
        isWordActive = true
        liveTranscript = ""
        beginWordCallCount += 1
    }

    public func endWord() {
        isWordActive = false
        endWordCallCount += 1
    }

    // Test helpers
    public func simulateTranscript(_ text: String) {
        guard isWordActive else { return }
        liveTranscript = text
        onTranscriptUpdate?(text)
    }

    public func simulateMatch(_ lemma: String) {
        guard isWordActive else { return }
        onMatchDetected?(lemma)
    }

    public func simulateError(_ error: Error) {
        onError?(error)
    }
}
```

- [ ] **Step 3: Write tests for mock**

```swift
// VocabCraftAppTests/Features/Reflex/MockResilientReflexSpeechEngineTests.swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class MockResilientReflexSpeechEngineTests: XCTestCase {
    private var engine: MockResilientReflexSpeechEngine!

    override func setUp() {
        super.setUp()
        engine = MockResilientReflexSpeechEngine()
    }

    func testStartSession_setsActive() {
        engine.startSession(contextualPhrases: ["hello"])
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertEqual(engine.startSessionCallCount, 1)
    }

    func testStopSession_resetsState() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    func testBeginWord_setsTargetAndActivates() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "Ephemeral", contextualPhrases: ["test"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.lastTargetLemma, "ephemeral")
        XCTAssertEqual(engine.beginWordCallCount, 1)
    }

    func testEndWord_deactivatesWord() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.endWord()
        XCTAssertFalse(engine.isWordActive)
        XCTAssertEqual(engine.endWordCallCount, 1)
    }

    func testSimulateTranscript_firesCallback() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertEqual(received, "hello")
        XCTAssertEqual(engine.liveTranscript, "hello")
    }

    func testSimulateTranscript_ignoredWhenNotActive() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.simulateTranscript("hello")
        XCTAssertNil(received)
    }

    func testSimulateMatch_firesCallback() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateMatch("test")
        XCTAssertEqual(matched, "test")
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/MockResilientReflexSpeechEngineTests 2>&1 | tail -20`
Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift \
       VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift \
       VocabCraftAppTests/Features/Reflex/MockResilientReflexSpeechEngineTests.swift
git commit -m "feat(speech): add ReflexSpeechEngineProtocol and mock implementation

- Protocol with session/word lifecycle separation
- Mock with test tracking properties and simulation helpers
- 7 unit tests covering lifecycle, callbacks, and edge cases"
```

---

### Task 2: `ResilientReflexSpeechEngine` — Real Implementation

**Files:**
- Create: `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift`

**Interfaces:**
- Consumes: `ReflexSpeechEngineProtocol` (Task 1), `ReflexSpeechMatcher` (existing in `ContinuousReflexSpeechService.swift`)
- Produces: `ResilientReflexSpeechEngine` — production implementation with persistent `AVAudioEngine` and per-word `SFSpeechRecognitionRequest` cycling

- [ ] **Step 1: Write the engine implementation**

Create `VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift` with:

```swift
import AVFoundation
import Foundation
import Observation
import Speech
import SpeechKit

@MainActor
@Observable
public final class ResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    // MARK: - Observable State
    public private(set) var isSessionActive: Bool = false
    public private(set) var isWordActive: Bool = false
    public private(set) var liveTranscript: String = ""

    // MARK: - Callbacks
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // MARK: - Engine layer (session-scoped)
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var sessionContextualPhrases: [String] = []
    private var sessionStartTime: Date?
    private var needsEngineRenew: Bool = false

    // MARK: - Request layer (word-scoped)
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeTask: SFSpeechRecognitionTask?
    private var currentTargetLemma: String = ""
    private var currentWordSessionToken: UUID = UUID()

    public init() {}

    deinit {
        // Clean up is handled by stopSession
    }

    // MARK: - Session Lifecycle

    public func startSession(contextualPhrases: [String]) {
        guard !isSessionActive else { return }
        self.sessionContextualPhrases = contextualPhrases
        self.sessionStartTime = Date()
        self.needsEngineRenew = false
        self.isSessionActive = true

        #if targetEnvironment(simulator) || os(macOS)
        // Simulator: no real audio engine
        #else
        requestAuthorizationAndStartEngine()
        #endif
    }

    public func stopSession() {
        endWord()
        teardownEngine()
        isSessionActive = false
        sessionContextualPhrases = []
        sessionStartTime = nil
        needsEngineRenew = false
    }

    // MARK: - Word Lifecycle

    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        // End previous word if still active
        if isWordActive {
            endWord()
        }

        // Proactive engine renewal if near 60s limit
        if needsEngineRenew {
            renewEngine()
        }

        let token = UUID()
        currentWordSessionToken = token
        currentTargetLemma = targetLemma
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        liveTranscript = ""
        isWordActive = true

        #if targetEnvironment(simulator) || os(macOS)
        // Simulator: no real recognition, test via simulateTranscript
        #else
        startRecognitionRequest(
            targetLemma: currentTargetLemma,
            contextualPhrases: contextualPhrases,
            sessionToken: token
        )
        #endif
    }

    public func endWord() {
        let wordToken = currentWordSessionToken
        currentWordSessionToken = UUID() // Invalidate current token

        activeRequest?.endAudio()
        activeTask?.cancel()
        activeRequest = nil
        activeTask = nil
        isWordActive = false

        // Check if engine needs renewal for next word
        if let start = sessionStartTime,
           Date().timeIntervalSince(start) > 50 {
            needsEngineRenew = true
        }
    }

    // MARK: - Simulator support
    public func simulateTranscript(_ text: String) {
        guard isWordActive else { return }
        liveTranscript = text
        onTranscriptUpdate?(text)

        if !currentTargetLemma.isEmpty,
           ReflexSpeechMatcher.isReflexMatch(
               spokenText: text,
               targetLemma: currentTargetLemma
           ) {
            onMatchDetected?(currentTargetLemma)
        }
    }
}

// MARK: - Audio Engine Management

extension ResilientReflexSpeechEngine {
    #if !targetEnvironment(simulator) && !os(macOS)
    private func requestAuthorizationAndStartEngine() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self, self.isSessionActive else { return }
                guard status == .authorized else {
                    self.onError?(NSError(
                        domain: "ResilientReflexSpeech",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized."]
                    ))
                    return
                }
                self.requestMicPermissionAndStartEngine()
            }
        }
    }

    private func requestMicPermissionAndStartEngine() {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self, self.isSessionActive else { return }
                    if granted {
                        self.setupAndStartEngine()
                    } else {
                        self.onError?(NSError(
                            domain: "ResilientReflexSpeech",
                            code: 403,
                            userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."]
                        ))
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self, self.isSessionActive else { return }
                    if granted {
                        self.setupAndStartEngine()
                    } else {
                        self.onError?(NSError(
                            domain: "ResilientReflexSpeech",
                            code: 403,
                            userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."]
                        ))
                    }
                }
            }
        }
        #else
        setupAndStartEngine()
        #endif
    }

    private func setupAndStartEngine() {
        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
                throw NSError(
                    domain: "ResilientReflexSpeech",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid microphone format."]
                )
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
                [weak self] buffer, _ in
                // Forward buffer to active request (nil-safe: discarded when no word active)
                self?.activeRequest?.append(buffer)
            }

            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            self.sessionStartTime = Date()
        } catch {
            onError?(error)
        }
    }
    #endif

    private func teardownEngine() {
        #if !targetEnvironment(simulator) && !os(macOS)
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        #endif
    }

    private func renewEngine() {
        #if !targetEnvironment(simulator) && !os(macOS)
        teardownEngine()
        setupAndStartEngine()
        #endif
        needsEngineRenew = false
        sessionStartTime = Date()
    }
}

// MARK: - Recognition Request Management

extension ResilientReflexSpeechEngine {
    #if !targetEnvironment(simulator) && !os(macOS)
    private func startRecognitionRequest(
        targetLemma: String,
        contextualPhrases: [String],
        sessionToken: UUID
    ) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            onError?(NSError(
                domain: "ResilientReflexSpeech",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable."]
            ))
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation

        var biasedPhrases = sessionContextualPhrases + contextualPhrases
        if !biasedPhrases.contains(targetLemma) {
            biasedPhrases.append(targetLemma)
        }
        request.contextualStrings = Array(Set(biasedPhrases.filter { !$0.isEmpty }))

        #if os(iOS)
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        #endif

        self.activeRequest = request

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self,
                      self.isWordActive,
                      self.currentWordSessionToken == sessionToken else { return }

                if let error = error {
                    let nsError = error as NSError
                    // 216 = cancelled (normal), 1110 = timeout (60s limit)
                    if nsError.code == 1110 {
                        // 60s limit hit — auto-recover
                        self.endWord()
                        self.beginWord(
                            targetLemma: targetLemma,
                            contextualPhrases: contextualPhrases
                        )
                    } else if nsError.code != 216 {
                        self.onError?(error)
                    }
                    return
                }

                guard let result else { return }
                let spoken = result.bestTranscription.formattedString
                self.liveTranscript = spoken
                self.onTranscriptUpdate?(spoken)

                // Evaluate match
                if ReflexSpeechMatcher.isReflexMatch(
                    spokenText: spoken,
                    targetLemma: targetLemma
                ) {
                    self.onMatchDetected?(targetLemma)
                }
            }
        }

        self.activeTask = task
    }
    #endif
}
```

- [ ] **Step 2: Write tests for the engine (simulator-safe)**

```swift
// VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class ResilientReflexSpeechEngineTests: XCTestCase {
    private var engine: ResilientReflexSpeechEngine!

    override func setUp() {
        super.setUp()
        engine = ResilientReflexSpeechEngine()
    }

    override func tearDown() {
        engine.stopSession()
        engine = nil
        super.tearDown()
    }

    func testStartSession_activatesSession() {
        engine.startSession(contextualPhrases: ["hello", "world"])
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testStopSession_deactivatesEverything() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testBeginWord_activatesWord() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: ["test"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    func testEndWord_deactivatesWordKeepsSession() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.endWord()
        XCTAssertFalse(engine.isWordActive)
        XCTAssertTrue(engine.isSessionActive)
    }

    func testMultipleWordCycles_nocrash() {
        engine.startSession(contextualPhrases: [])
        for i in 0..<10 {
            engine.beginWord(targetLemma: "word\(i)", contextualPhrases: [])
            engine.endWord()
        }
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testSimulateTranscript_updatesLiveTranscript() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateTranscript("hello world")
        XCTAssertEqual(engine.liveTranscript, "hello world")
        XCTAssertEqual(received, "hello world")
    }

    func testSimulateTranscript_matchDetected() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: [])
        engine.simulateTranscript("ephemeral")
        XCTAssertEqual(matched, "ephemeral")
    }

    func testSimulateTranscript_noMatchForWrongWord() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertNil(matched)
    }

    func testSimulateTranscript_ignoredWhenWordNotActive() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertNil(received)
    }

    func testBeginWord_endsPreviousWordAutomatically() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "word1", contextualPhrases: [])
        XCTAssertTrue(engine.isWordActive)
        engine.beginWord(targetLemma: "word2", contextualPhrases: [])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }
}
```

- [ ] **Step 3: Run tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests/ResilientReflexSpeechEngineTests 2>&1 | tail -20`
Expected: All 9 tests PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift \
       VocabCraftAppTests/Features/Reflex/ResilientReflexSpeechEngineTests.swift
git commit -m "feat(speech): add ResilientReflexSpeechEngine implementation

- Persistent AVAudioEngine across session (start once, stop once)
- Per-word SFSpeechRecognitionRequest cycling (<1ms transition)
- Proactive 60s limit renewal in reviewed state gaps
- Auto-recovery on recognition task errors
- Simulator-safe with simulateTranscript() support
- 9 unit tests covering lifecycle, matching, and edge cases"
```

---

### Task 3: Rebuild `ReflexSpeakingModeView` — 3D Flip Card Architecture

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift` (full rewrite)

**Interfaces:**
- Consumes: `ReflexDrillable` protocol (existing), `CraftFlipCard` (CraftUIKit), `CraftTactileMicHubView` (CraftUIKit), `CraftBadge` (CraftUIKit), `CraftSpeakerButton` (CraftUIKit), `CraftSpeechState` (CraftUIKit), `ReflexClozeStageSet` / `ClozeSentenceParts` (existing)
- Produces: `ReflexSpeakingModeView` — complete view with Zone 1 (flip card) + Zone 2 (mic hub + transcript badge)

- [ ] **Step 1: Rewrite ReflexSpeakingModeView**

Full rewrite of `VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift`:

```swift
import CraftUIKit
import SwiftUI

/// Redesigned Speaking Mode view with Dual-Zone 3D Flip Card architecture.
/// Zone 1 (Top): CraftFlipCard (.tactile3D) — front: Vietnamese definition + cloze prompt; back: consolidation.
/// Zone 2 (Bottom): CraftTactileMicHubView on canvas + live transcript CraftBadge.
public struct ReflexSpeakingModeView: View {
    @Environment(\.craftTheme) private var theme

    // MARK: - Word & Challenge Data
    public let word: any ReflexDrillable
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let showHint: Bool
    public let hintStage: Int
    public let clozeStages: ReflexClozeStageSet?
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String
    public let hintBadgeText: String?

    // MARK: - Mic & Transcript
    public let speechState: CraftSpeechState
    public let liveTranscript: String
    public let onReplayAudio: (() -> Void)?

    public init(
        word: any ReflexDrillable,
        isReviewed: Bool = false,
        isResultCorrect: Bool = false,
        isResultTimeout: Bool = false,
        showHint: Bool = false,
        hintStage: Int = 0,
        clozeStages: ReflexClozeStageSet? = nil,
        clozeParts: ClozeSentenceParts? = nil,
        displayedSentence: String = "",
        hintBadgeText: String? = nil,
        speechState: CraftSpeechState = .listening(),
        liveTranscript: String = "",
        onReplayAudio: (() -> Void)? = nil
    ) {
        self.word = word
        self.isReviewed = isReviewed
        self.isResultCorrect = isResultCorrect
        self.isResultTimeout = isResultTimeout
        self.showHint = showHint
        self.hintStage = hintStage
        self.clozeStages = clozeStages
        self.clozeParts = clozeParts
        self.displayedSentence = displayedSentence.isEmpty ? word.clozeSentenceEn : displayedSentence
        self.hintBadgeText = hintBadgeText
        self.speechState = speechState
        self.liveTranscript = liveTranscript
        self.onReplayAudio = onReplayAudio
    }

    public var activeClozeParts: ClozeSentenceParts? {
        guard let stages = clozeStages else { return clozeParts }
        switch hintStage {
        case 0: return stages.initialParts
        case 1: return stages.lengthMaskedParts
        default: return stages.patternRevealedParts
        }
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Zone 1: 3D Flip Card
            flipStimulusCard

            // Zone 2: Mic Hub + Transcript (on canvas, no card wrapper)
            micHubArea
        }
    }

    // MARK: - Zone 1: 3D Flip Stimulus Card

    @ViewBuilder
    private var flipStimulusCard: some View {
        let statusGlow: Color? = isReviewed
            ? (isResultCorrect
                ? theme.colors.statusSuccess.opacity(0.2)
                : theme.colors.statusDanger.opacity(0.2))
            : nil

        CraftFlipCard(
            isFlipped: Binding(
                get: { isReviewed },
                set: { _ in }
            ),
            style: .tactile3D,
            axis: .horizontal,
            showSpecularGlare: true,
            showsHighlightBorder: false,
            highlightShadowColor: statusGlow,
            isTapToFlipEnabled: false,
            isSensoryFeedbackEnabled: false,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.base,
            perspective: 0.5,
            animation: .spring(response: 0.45, dampingFraction: 0.78)
        ) {
            frontPromptFace
        } back: {
            backResultFace
        }
    }

    // MARK: - Front Face (Active Challenge)

    private var frontPromptFace: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftText(
                word.definitionVi,
                style: .titleLarge,
                color: theme.colors.textPrimary,
                textAlignment: .center
            )
            .lineLimit(2)
            .accessibilityLabel(AppStrings.ReflexBlitz.definitionA11y(word.definitionVi))

            HStack(alignment: .center, spacing: theme.spacing.xs) {
                if !word.cleanPos.isEmpty {
                    CraftBadge(
                        word.cleanPos,
                        variant: .subtle,
                        tone: .neutral,
                        size: .sm,
                        shape: .capsule
                    )
                }

                CraftBadge(
                    word.cleanLevel,
                    variant: .subtle,
                    tone: .warning,
                    size: .sm,
                    shape: .capsule
                )

                if showHint || hintStage >= 2 {
                    let badgeText: String = {
                        if let text = hintBadgeText, !text.isEmpty {
                            return text
                        }
                        return AppStrings.ReflexBlitz.hintPrefix(word.cleanInitialLetterHint)
                    }()
                    CraftBadge(
                        badgeText,
                        iconName: "lightbulb.min.fill",
                        variant: .outline,
                        tone: .warning,
                        size: .sm,
                        shape: .capsule
                    )
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel(
                        AppStrings.ReflexBlitz.hintA11y(word.cleanInitialLetterHint)
                    )
                }
            }
            .opacity(hintStage >= 1 ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: hintStage)

            frontSentenceArea
                .padding(.top, theme.spacing.xs / 2)
        }
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .center)
    }

    // MARK: - Back Face (Reviewed Consolidation)

    private var backResultFace: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .center) {
                CraftText(
                    word.lemma,
                    style: .titleLargeSerif,
                    color: theme.colors.textPrimary,
                    textAlignment: .leading
                )

                Spacer(minLength: theme.spacing.sm)

                if let onReplayAudio {
                    CraftSpeakerButton(
                        variant: .subtle,
                        size: .md,
                        isPlaying: false,
                        label: nil,
                        action: onReplayAudio
                    )
                }
            }

            if !word.ipa.isEmpty {
                CraftText(
                    word.ipa,
                    style: .caption,
                    color: theme.colors.textMuted,
                    textAlignment: .leading
                )
                .accessibilityLabel(AppStrings.ReflexBlitz.ipaA11y(word.ipa))
            }

            HStack(spacing: theme.spacing.xs) {
                if !word.cleanPos.isEmpty {
                    CraftBadge(
                        word.cleanPos,
                        variant: .subtle,
                        tone: .neutral,
                        size: .sm,
                        shape: .capsule
                    )
                }

                CraftBadge(
                    word.cleanLevel,
                    variant: .subtle,
                    tone: .warning,
                    size: .sm,
                    shape: .capsule
                )
            }
            .padding(.vertical, 2)

            CraftText(
                word.definitionVi,
                style: .titleMedium,
                color: theme.colors.textPrimary,
                textAlignment: .leading
            )
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                backSentenceView
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if !word.exampleSentenceVi.isEmpty {
                    CraftText(
                        word.exampleSentenceVi,
                        style: .caption,
                        color: theme.colors.textMuted,
                        textAlignment: .leading
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .center)
    }

    // MARK: - Zone 2: Mic Hub + Transcript Badge

    @ViewBuilder
    private var micHubArea: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftTactileMicHubView(
                speechState: isReviewed
                    ? .evaluated(overallScore: isResultCorrect ? 100 : 0)
                    : speechState,
                onTapMic: {}  // No tap action — continuous listening
            )
            .disabled(true)  // Disable tap — mic is auto-controlled

            if !liveTranscript.isEmpty {
                CraftBadge(
                    liveTranscript,
                    iconName: "waveform",
                    variant: isReviewed ? .subtle : .solid,
                    tone: isReviewed
                        ? (isResultCorrect ? .success : .danger)
                        : .primary,
                    size: .md,
                    shape: .capsule
                )
                .transition(.scale.combined(with: .opacity))
            } else if !isReviewed {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon("mic.fill", size: .sm, color: theme.colors.textMuted)
                    CraftText(
                        AppStrings.ReflexBlitz.speakingListeningText,
                        style: .caption,
                        color: theme.colors.textMuted
                    )
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: liveTranscript.isEmpty)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isReviewed)
    }

    // MARK: - Sentence Helpers

    @ViewBuilder
    private var frontSentenceArea: some View {
        VStack(spacing: theme.spacing.xs) {
            frontSentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, theme.spacing.xs)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: hintStage)
                .accessibilityLabel(
                    AppStrings.ReflexBlitz.clozeSentenceA11y(word.clozeSentenceEn)
                )
        }
    }

    @ViewBuilder
    private var frontSentenceView: some View {
        if let parts = activeClozeParts ?? clozeParts {
            activeClozeText(parts: parts)
        } else {
            Text(displayedSentence)
                .font(theme.typography.bodySerif.weight(.medium))
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private func activeClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotColor = (hintStage >= 2) ? theme.colors.statusWarning : theme.colors.brandPrimary
        let slotText = Text(parts.slot)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }

    @ViewBuilder
    private var backSentenceView: some View {
        if let parts = clozeParts {
            reviewedClozeText(parts: parts)
        } else {
            Text(word.completedSentenceWithTargetWord)
                .font(theme.typography.bodySerif.weight(.bold))
                .foregroundColor(
                    isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
                )
        }
    }

    private func reviewedClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotColor: Color = isResultCorrect
            ? theme.colors.statusSuccess
            : theme.colors.statusDanger
        let slotWord = parts.slot.contains("_") ? word.lemma : parts.slot
        let slotText = Text(slotWord)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }
}
```

- [ ] **Step 2: Verify the view compiles**

Run: `xcodebuild build -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(error:|BUILD)' | tail -10`
Expected: BUILD SUCCEEDED with 0 errors

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift
git commit -m "feat(speaking): rebuild ReflexSpeakingModeView with 3D Flip Card

- Zone 1: CraftFlipCard (.tactile3D) with front/back faces
- Zone 2: CraftTactileMicHubView + transcript CraftBadge on canvas
- Standardized back face consolidation (lemma, IPA, badges, sentence)
- 3-stage visual-only hint progression
- Consistent component styling across all modes"
```

---

### Task 4: ViewModel Integration — Wire New Engine + Update Speaking Branch

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel+Configuration.swift`
- Modify: `VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift`

**Interfaces:**
- Consumes: `ReflexSpeechEngineProtocol` (Task 1), `MockResilientReflexSpeechEngine` (Task 1), `ReflexSpeakingModeView` (Task 3)
- Produces: Updated ViewModel with `speechEngine` dependency, simplified speaking mode flow, updated view integration

- [ ] **Step 1: Add `speechEngine` dependency to ViewModel**

In `ReflexBlitzViewModel.swift`, add new property alongside existing `continuousSpeechService`:

```swift
// Add property
let speechEngine: ReflexSpeechEngineProtocol

// Update convenience init to create default engine
public convenience init(
    words: [ReflexBlitzWordItem] = ReflexBlitzWordItem.defaultStarterWords,
    weeklyPracticedCount: Int = 0,
    weakWordsCount: Int = 0,
    averageSpeedSeconds: Double = 0.0
) {
    self.init(
        words: words,
        weeklyPracticedCount: weeklyPracticedCount,
        weakWordsCount: weakWordsCount,
        averageSpeedSeconds: averageSpeedSeconds,
        continuousSpeechService: ContinuousReflexSpeechService(),
        ttsService: TextToSpeechService(),
        evaluateSRSUseCase: EvaluateSRSUseCase(srsRepository: SRSRepositoryImpl()),
        soundEffectService: SoundEffectService.shared,
        speechEngine: ResilientReflexSpeechEngine()
    )
}

// Update full init to accept speechEngine parameter
public init(
    words: [ReflexBlitzWordItem] = ...,
    ...
    speechEngine: ReflexSpeechEngineProtocol = ResilientReflexSpeechEngine()
) {
    ...
    self.speechEngine = speechEngine
    setupSpeechEngineBindings()
}
```

- [ ] **Step 2: Add speech engine bindings method**

In `ReflexBlitzViewModel.swift`, add new binding method:

```swift
private func setupSpeechEngineBindings() {
    speechEngine.onMatchDetected = { [weak self] matched in
        self?.handleSpokenMatch(matched)
    }
    speechEngine.onTranscriptUpdate = { [weak self] transcript in
        self?.liveTranscript = transcript
    }
    speechEngine.onError = { [weak self] error in
        print("[ReflexBlitzViewModel] Speech engine error: \(error.localizedDescription)")
    }
}
```

- [ ] **Step 3: Update `startCountdown()` and `beginSessionDirectly()` to use new engine**

Replace `continuousSpeechService.startSession(...)` calls with `speechEngine.startSession(...)` for speaking mode:

```swift
// In startCountdown():
if selectedMode == .speaking {
    let contextualPhrases = words.flatMap { [$0.lemma, $0.exampleSentenceEn] }
    speechEngine.startSession(contextualPhrases: contextualPhrases)
}

// In beginSessionDirectly():
if selectedMode == .speaking {
    let contextualPhrases = words.flatMap { [$0.lemma, $0.exampleSentenceEn] }
    speechEngine.startSession(contextualPhrases: contextualPhrases)
}
```

- [ ] **Step 4: Update `loadWord(at:)` to use `beginWord()`**

Replace `setTargetWord()` + `resumeListening()` with single `beginWord()`:

```swift
// In loadWord(at:) — replace the speaking branch:
if selectedMode == .speaking {
    speechEngine.beginWord(
        targetLemma: word.lemma,
        contextualPhrases: [word.exampleSentenceEn]
    )
} else {
    continuousSpeechService.pauseListening()
}
```

- [ ] **Step 5: Update `handleSpokenMatch()` and `handleTimeout()` to use `endWord()`**

```swift
// In handleSpokenMatch() — replace:
continuousSpeechService.pauseListening()
// With:
speechEngine.endWord()

// In handleTimeout() — replace:
continuousSpeechService.pauseListening()
// With:
if selectedMode == .speaking {
    speechEngine.endWord()
} else {
    continuousSpeechService.pauseListening()
}
```

- [ ] **Step 6: Update `finishSession()` and `cancelSession()` in Configuration extension**

In `ReflexBlitzViewModel+Configuration.swift`:

```swift
// finishSession():
public func finishSession() {
    cancelAllTasks()
    continuousSpeechService.stopSession()
    speechEngine.stopSession()
    sessionSummary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: maxComboStreak)
    phase = .summary
}

// cancelSession():
public func cancelSession() {
    cancelAllTasks()
    continuousSpeechService.stopSession()
    speechEngine.stopSession()
    ttsService.stop()
}
```

- [ ] **Step 7: Update hint timers for 3-stage progression**

In `ReflexBlitzViewModel.swift`, update `scheduleSpeakingTimers()`:

```swift
private func scheduleSpeakingTimers() {
    hintTimerTask = Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(2500))
        guard !Task.isCancelled else { return }
        guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
        self.hintStage = max(self.hintStage, 1)
    }
    hintStage2Task = Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(4000))
        guard !Task.isCancelled else { return }
        guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
        self.hintStage = max(self.hintStage, 2)
    }
    hintStage3Task = Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(5000))
        guard !Task.isCancelled else { return }
        guard let self, self.phase == .drilling, self.cardPhase == .activeCountdown else { return }
        self.hintStage = max(self.hintStage, 3)
    }
}
```

- [ ] **Step 8: Update `ReflexBlitzView.swift` — replace `containerCard` speaking branch**

Replace the `containerCard(for:)` function with new `speakingCard(for:)` and update `cardContent(for:)`:

```swift
// Update cardContent(for:):
@ViewBuilder
private func cardContent(for word: ReflexBlitzWordItem) -> some View {
    if viewModel.selectedMode == .multipleChoice {
        multipleChoiceCard(for: word)
    } else if viewModel.selectedMode == .typing {
        typingCard(for: word)
    } else if viewModel.selectedMode == .listening {
        listeningCard(for: word)
    } else if viewModel.selectedMode == .speaking {
        speakingCard(for: word)
    }
}

// Add new speakingCard(for:):
@ViewBuilder
private func speakingCard(for word: ReflexBlitzWordItem) -> some View {
    ReflexSpeakingModeView(
        word: word,
        isReviewed: isReviewed,
        isResultCorrect: viewModel.currentAttemptIsCorrect,
        isResultTimeout: isReviewedTimeout,
        showHint: viewModel.showHint,
        hintStage: viewModel.hintStage,
        clozeStages: viewModel.currentClozeStages,
        clozeParts: ReflexClozeFormatter.extractTemplateParts(from: word.clozeSentenceEn),
        displayedSentence: isReviewed ? word.completedSentenceWithTargetWord : word.clozeSentenceEn,
        hintBadgeText: viewModel.currentHintBadgeText,
        speechState: viewModel.cardPhase == .activeCountdown ? .listening() : .evaluated(overallScore: viewModel.currentAttemptIsCorrect ? 100 : 0),
        liveTranscript: viewModel.liveTranscript,
        onReplayAudio: {
            viewModel.speakCurrentWord()
        }
    )
    .padding(.horizontal, theme.spacing.base)
}
```

- [ ] **Step 9: Remove Skip button for speaking mode (now handled by header)**

Remove the dedicated skip button block from `drillingView` in `ReflexBlitzView.swift` (lines 190-206) since speaking mode will use the header skip button like other modes.

- [ ] **Step 10: Verify build succeeds**

Run: `xcodebuild build -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(error:|BUILD)' | tail -10`
Expected: BUILD SUCCEEDED with 0 errors

- [ ] **Step 11: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift \
       VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel+Configuration.swift \
       VocabCraftApp/Features/Reflex/Blitz/Views/ReflexBlitzView.swift
git commit -m "feat(speaking): wire ResilientReflexSpeechEngine into ViewModel + View

- Add speechEngine dependency with protocol injection
- Replace setTargetWord/pauseListening with beginWord/endWord
- 3-stage hint progression (2.5s → 4.0s → 5.0s)
- New speakingCard() in ReflexBlitzView with CraftFlipCard + MicHub
- Remove legacy containerCard speaking branch"
```

---

### Task 5: Update Tests — ViewModel Speaking Mode Tests

**Files:**
- Modify: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`
- Create: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift`

**Interfaces:**
- Consumes: `MockResilientReflexSpeechEngine` (Task 1), updated `ReflexBlitzViewModel` (Task 4)
- Produces: Comprehensive speaking-mode-specific ViewModel tests

- [ ] **Step 1: Update existing test setUp to include speechEngine**

In `ReflexBlitzViewModelTests.swift`, add `MockResilientReflexSpeechEngine` to setUp:

```swift
private var mockSpeechEngine: MockResilientReflexSpeechEngine!

override func setUp() {
    super.setUp()
    mockSpeech = MockContinuousReflexSpeechService()
    mockTTS = MockTextToSpeechService()
    mockSRS = MockEvaluateSRSUseCase()
    mockSound = MockSoundEffectService()
    mockSpeechEngine = MockResilientReflexSpeechEngine()

    viewModel = ReflexBlitzViewModel(
        words: sampleWords,
        continuousSpeechService: mockSpeech,
        ttsService: mockTTS,
        evaluateSRSUseCase: mockSRS,
        soundEffectService: mockSound,
        speechEngine: mockSpeechEngine
    )
}
```

- [ ] **Step 2: Create speaking-specific test file**

```swift
// VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift
import XCTest
@testable import VocabCraftApp

@MainActor
final class ReflexBlitzViewModelSpeakingTests: XCTestCase {
    private var mockSpeechEngine: MockResilientReflexSpeechEngine!
    private var mockTTS: MockTextToSpeechService!
    private var mockSRS: MockEvaluateSRSUseCase!
    private var mockSound: MockSoundEffectService!
    private var viewModel: ReflexBlitzViewModel!

    private let sampleWords = [
        ReflexBlitzWordItem(
            id: 1, lemma: "ephemeral", pos: "adj.",
            definitionVi: "Phù du", exampleSentenceEn: "Fame is ephemeral",
            exampleSentenceVi: "Danh tiếng thì phù du"
        ),
        ReflexBlitzWordItem(
            id: 2, lemma: "vital", pos: "adj.",
            definitionVi: "Quan trọng", exampleSentenceEn: "Water is vital",
            exampleSentenceVi: "Nước là sống còn"
        )
    ]

    override func setUp() {
        super.setUp()
        mockSpeechEngine = MockResilientReflexSpeechEngine()
        mockTTS = MockTextToSpeechService()
        mockSRS = MockEvaluateSRSUseCase()
        mockSound = MockSoundEffectService()

        viewModel = ReflexBlitzViewModel(
            words: sampleWords,
            continuousSpeechService: MockContinuousReflexSpeechService(),
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS,
            soundEffectService: mockSound,
            speechEngine: mockSpeechEngine
        )
    }

    // MARK: - Session Lifecycle

    func testSpeakingMode_startCountdown_startsEngine() {
        viewModel.selectMode(.speaking)
        XCTAssertTrue(mockSpeechEngine.isSessionActive)
        XCTAssertEqual(mockSpeechEngine.startSessionCallCount, 1)
    }

    func testSpeakingMode_beginDrilling_callsBeginWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        XCTAssertEqual(mockSpeechEngine.beginWordCallCount, 1)
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, "ephemeral")
        XCTAssertTrue(mockSpeechEngine.isWordActive)
    }

    // MARK: - Match Detection

    func testSpeakingMode_matchDetected_transitionsToReviewed() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateMatch("ephemeral")

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertTrue(result.isCorrect)
            XCTAssertFalse(result.isTimeout)
        } else {
            XCTFail("Expected reviewed state")
        }
    }

    func testSpeakingMode_matchDetected_callsEndWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateMatch("ephemeral")
        XCTAssertEqual(mockSpeechEngine.endWordCallCount, 1)
    }

    func testSpeakingMode_matchDetected_playsSuccessChime() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateMatch("ephemeral")
        XCTAssertTrue(mockSound.successChimePlayed)
    }

    // MARK: - Timeout

    func testSpeakingMode_timeout_transitionsToReviewed() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 6000)

        if case .reviewed(let result) = viewModel.cardPhase {
            XCTAssertFalse(result.isCorrect)
            XCTAssertTrue(result.isTimeout)
        } else {
            XCTFail("Expected reviewed state")
        }
    }

    func testSpeakingMode_timeout_callsEndWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertTrue(mockSpeechEngine.endWordCallCount >= 1)
    }

    // MARK: - Transcript Updates

    func testSpeakingMode_transcriptUpdate_reflectedInViewModel() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        mockSpeechEngine.simulateTranscript("hello world")
        XCTAssertEqual(viewModel.liveTranscript, "hello world")
    }

    // MARK: - Word Transition

    func testSpeakingMode_advanceToNextWord_cyclesBeginEndWord() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        let initialBeginCount = mockSpeechEngine.beginWordCallCount

        mockSpeechEngine.simulateMatch("ephemeral")
        viewModel.advanceToNextWord()

        XCTAssertEqual(mockSpeechEngine.beginWordCallCount, initialBeginCount + 1)
        XCTAssertEqual(mockSpeechEngine.lastTargetLemma, "vital")
    }

    // MARK: - Hint Progression

    func testSpeakingMode_hintStage1_at2500ms() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 2500)
        XCTAssertGreaterThanOrEqual(viewModel.hintStage, 1)
    }

    func testSpeakingMode_hintStage2_at4000ms() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 4000)
        XCTAssertGreaterThanOrEqual(viewModel.hintStage, 2)
    }

    func testSpeakingMode_hintStage3_at5000ms() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 5000)
        XCTAssertGreaterThanOrEqual(viewModel.hintStage, 3)
    }

    // MARK: - Session End

    func testSpeakingMode_finishSession_stopsEngine() {
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.finishSession()
        XCTAssertEqual(mockSpeechEngine.stopSessionCallCount, 1)
        XCTAssertFalse(mockSpeechEngine.isSessionActive)
    }
}
```

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:VocabCraftAppTests 2>&1 | tail -30`
Expected: All tests PASS (including existing tests + new speaking tests)

- [ ] **Step 4: Commit**

```bash
git add VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift \
       VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift
git commit -m "test(speaking): add ViewModel speaking mode tests

- 12 tests covering session lifecycle, match detection, timeout,
  transcript updates, word transitions, hint progression, and session end
- Updated existing test setUp with speechEngine mock"
```

---

### Task 6: Update `simulateElapsedTime` + Localization Parity Check

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift` (update `simulateElapsedTime` speaking branch)
- Verify: `VocabCraftApp/Resources/Localizable.xcstrings` (check all speaking strings exist in both EN + VI)

**Interfaces:**
- Consumes: Updated ViewModel (Task 4)
- Produces: Correct `simulateElapsedTime` for 3-stage speaking hints, verified localization

- [ ] **Step 1: Update `simulateElapsedTime` speaking branch**

In `ReflexBlitzViewModel.swift`, update the speaking case in `simulateElapsedTime(ms:)`:

```swift
// Replace the existing speaking branch (currently only has 1 stage at 3500ms):
} else {
    if ms >= 3500 {
        self.hintStage = 1
    }
}

// With 3-stage progression:
} else {
    if ms >= 5000 { self.hintStage = max(self.hintStage, 3) }
    else if ms >= 4000 { self.hintStage = max(self.hintStage, 2) }
    else if ms >= 2500 { self.hintStage = max(self.hintStage, 1) }
}
```

Also update `ReflexMode.hintStage(forElapsedTimeMs:)` in `ReflexMode.swift`:

```swift
case .speaking:
    if elapsed >= 5000 { return 3 }
    if elapsed >= 4000 { return 2 }
    if elapsed >= 2500 { return 1 }
    return 0
```

- [ ] **Step 2: Verify localization strings exist**

Check that these strings exist in `Localizable.xcstrings` for both EN and VI:
- `app.reflex.blitz.speaking_listening` (or equivalent key used by `AppStrings.ReflexBlitz.speakingListeningText`)
- `app.reflex.blitz.speaking_title`
- `app.reflex.blitz.speaking_instruction`

Run: `grep -c "speakingListeningText\|speakingTitleText\|speakingInstructionText" VocabCraftApp/Core/Localization/AppStrings+ReflexBlitz.swift`
Expected: All keys found and mapped

- [ ] **Step 3: Run full test suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: All tests PASS, 0 warnings

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift \
       VocabCraftApp/Features/Reflex/Core/Models/ReflexMode.swift
git commit -m "fix(speaking): update hint progression to 3-stage (2.5s/4.0s/5.0s)

- simulateElapsedTime and ReflexMode.hintStage updated for speaking
- Stage 1: POS badge (2.5s), Stage 2: initial letter (4.0s), Stage 3: pattern (5.0s)
- Verified localization string parity"
```

---

### Task 7: Final Verification — Build + Full Test Suite + SwiftLint

**Files:**
- All files from Tasks 1-6

**Interfaces:**
- Consumes: Everything from previous tasks
- Produces: Verified, ship-ready implementation

- [ ] **Step 1: Full project build**

Run: `xcodebuild build -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E '(error:|warning:|BUILD)' | tail -20`
Expected: BUILD SUCCEEDED, 0 errors, 0 warnings

- [ ] **Step 2: Full test suite**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30`
Expected: All tests PASS

- [ ] **Step 3: SwiftLint**

Run: `swiftlint lint --path VocabCraftApp/Core/Audio/ResilientReflexSpeechEngine.swift --path VocabCraftApp/Core/Audio/MockResilientReflexSpeechEngine.swift --path VocabCraftApp/Domain/Protocols/ReflexSpeechEngineProtocol.swift --path VocabCraftApp/Features/Reflex/Core/Components/Modes/ReflexSpeakingModeView.swift`
Expected: 0 violations

- [ ] **Step 4: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "chore: final lint and build fixes for speaking mode redesign"
```
