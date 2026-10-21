# YouTube Shadowing Studio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the YouTube Shadowing Studio feature in `VocabCraft`, allowing users to practice consecutive step-by-step shadowing with curated YouTube videos, sub-second auto-pause, real-time speech evaluation via `SpeechKit`, dual audio comparison, and 1-tap SRS bookmarking.

**Architecture:** A unidirectional MVVM architecture where `ShadowingPracticeView` hosts a customized `CraftYouTubePlayerView` (WKWebView with sub-second JavaScript timestamp monitor) and `CraftVoiceMatchCard` from `CraftUIKit`. `ShadowingPracticeViewModel` coordinates state transitions through `ShadowingSessionCoordinator`, acquiring explicit audio leases from `SpeechKit`'s `AudioSessionCoordinating` (`.playback` $\leftrightarrow$ `.speechCapture`), triggering `SpeechAssessmentService` for token alignment, and persisting bookmarked words via `ToggleWordBookmarkUseCase`.

**Tech Stack:** Swift 6, SwiftUI, WebKit (WKWebView + YouTube IFrame Player API), AVFoundation, SpeechKit (`SpeechAssessmentService`, `SequenceAligner`, `SilenceDetector`, `AudioSessionCoordinating`), CraftUIKit (`CraftVoiceMatchCard`, `CraftWaveformView`, `CraftTactileMicHubView`), Swift Testing (`@Test`, `#expect`).

**Spec:** [docs/superpowers/specs/2026-10-21-youtube-shadowing-studio-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-21-youtube-shadowing-studio-design.md)

## Global Constraints

- Swift 6 strict concurrency compliance (all models `Sendable`, ViewModel `@MainActor`).
- CraftUIKit-First: Reuse existing components (`CraftVoiceMatchCard`, `CraftWaveformView`, `CraftTactileMicHubView`, `CraftButton`, `CraftPill`). Zero raw color or font styling.
- Zero Hardcoded Strings Policy: All user-facing strings declared in `VocabCraftApp/Resources/Localizable.xcstrings` under prefix `app.shadowing.*` with 100% EN/VI parity.
- Quality Gate: Zero compiler warnings, zero SwiftLint violations, 100% unit test pass rate.

---

### Task 1: Domain Models & Curated Catalog Repository

**Files:**
- Create: `VocabCraftApp/Domain/Models/Shadowing/ShadowingVideoModels.swift`
- Create: `VocabCraftApp/Domain/Protocols/ShadowingVideoRepositoryProtocol.swift`
- Create: `VocabCraftApp/Data/Repositories/ShadowingVideoRepositoryImpl.swift`
- Test: `VocabCraftAppTests/Domain/ShadowingVideoModelsTests.swift`

**Interfaces:**
- Consumes: None (pure Domain & Data).
- Produces: `ShadowingTopic`, `ShadowingKeyWord`, `ShadowingSentence`, `ShadowingVideo`, `SentenceAttemptRecord`, `ShadowingPlaybackPhase`, `ShadowingVideoRepositoryProtocol`.

- [ ] **Step 1: Write the failing unit tests for Shadowing Models and Catalog**

Create `VocabCraftAppTests/Domain/ShadowingVideoModelsTests.swift`:
```swift
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Video Models & Repository Tests")
struct ShadowingVideoModelsTests {
    @Test("Verifies ShadowingVideo and ShadowingSentence initialization and JSON decoding")
    func testShadowingVideoDecoding() throws {
        let json = """
        {
            "id": "yt_coffee_01",
            "youtubeVideoId": "dQw4w9WgXcQ",
            "title": "Ordering Coffee",
            "topic": "dailyLife",
            "level": "A2",
            "durationSeconds": 45.0,
            "sentences": [
                {
                    "id": "s_01",
                    "orderIndex": 0,
                    "startTime": 1.5,
                    "endTime": 4.8,
                    "textEn": "Can I get an iced latte?",
                    "textVi": "Cho tôi một ly latte đá được không?",
                    "keyWords": [
                        {
                            "lemma": "latte",
                            "phonetic": "/ˈlɑː.teɪ/",
                            "definitionVi": "Cà phê sữa"
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let video = try JSONDecoder().decode(ShadowingVideo.self, from: json)
        #expect(video.id == "yt_coffee_01")
        #expect(video.sentences.count == 1)
        #expect(video.sentences.first?.keyWords.first?.lemma == "latte")
    }

    @Test("Verifies ShadowingVideoRepository returns curated videos")
    func testCuratedCatalogFetch() async throws {
        let repository: ShadowingVideoRepositoryProtocol = ShadowingVideoRepositoryImpl()
        let videos = try await repository.fetchCuratedVideos()
        #expect(!videos.isEmpty)
        #expect(videos.first?.sentences.isEmpty == false)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingVideoModelsTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: FAIL (types not found).

- [ ] **Step 3: Implement Domain Models and Repository**

Create `VocabCraftApp/Domain/Models/Shadowing/ShadowingVideoModels.swift`:
```swift
import Foundation

public enum ShadowingTopic: String, Sendable, Codable, CaseIterable {
    case dailyLife
    case moviesAndSeries
    case businessEnglish
    case techAndScience
    case cultureAndTravel
}

public struct ShadowingKeyWord: Identifiable, Sendable, Codable, Equatable {
    public var id: String { lemma }
    public let lemma: String
    public let phonetic: String
    public let definitionVi: String
    public let definitionEn: String?
    public let linkedWordId: Int64?

    public init(
        lemma: String,
        phonetic: String,
        definitionVi: String,
        definitionEn: String? = nil,
        linkedWordId: Int64? = nil
    ) {
        self.lemma = lemma
        self.phonetic = phonetic
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.linkedWordId = linkedWordId
    }
}

public struct ShadowingSentence: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let orderIndex: Int
    public let startTime: Double
    public let endTime: Double
    public let textEn: String
    public let textVi: String
    public let keyWords: [ShadowingKeyWord]

    public init(
        id: String,
        orderIndex: Int,
        startTime: Double,
        endTime: Double,
        textEn: String,
        textVi: String,
        keyWords: [ShadowingKeyWord] = []
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.startTime = startTime
        self.endTime = endTime
        self.textEn = textEn
        self.textVi = textVi
        self.keyWords = keyWords
    }
}

public struct ShadowingVideo: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let youtubeVideoId: String
    public let title: String
    public let topic: ShadowingTopic
    public let level: String
    public let durationSeconds: Double
    public let sentences: [ShadowingSentence]

    public init(
        id: String,
        youtubeVideoId: String,
        title: String,
        topic: ShadowingTopic,
        level: String,
        durationSeconds: Double,
        sentences: [ShadowingSentence]
    ) {
        self.id = id
        self.youtubeVideoId = youtubeVideoId
        self.title = title
        self.topic = topic
        self.level = level
        self.durationSeconds = durationSeconds
        self.sentences = sentences
    }
}

public enum ShadowingPlaybackPhase: Equatable, Sendable {
    case idle
    case playingNative(currentTime: Double)
    case readyToRecord
    case listening(levels: [CGFloat])
    case evaluating
    case evaluated(score: Double)
}

public struct SentenceAttemptRecord: Sendable, Equatable {
    public let score: Double
    public let userAudioURL: URL?
    public let isPassed: Bool

    public init(score: Double, userAudioURL: URL? = nil, isPassed: Bool) {
        self.score = score
        self.userAudioURL = userAudioURL
        self.isPassed = isPassed
    }
}
```

Create `VocabCraftApp/Domain/Protocols/ShadowingVideoRepositoryProtocol.swift`:
```swift
import Foundation

public protocol ShadowingVideoRepositoryProtocol: Sendable {
    func fetchCuratedVideos() async throws -> [ShadowingVideo]
    func fetchVideo(byId id: String) async throws -> ShadowingVideo?
}
```

Create `VocabCraftApp/Data/Repositories/ShadowingVideoRepositoryImpl.swift`:
```swift
import Foundation

public final class ShadowingVideoRepositoryImpl: ShadowingVideoRepositoryProtocol, @unchecked Sendable {
    private let curatedVideos: [ShadowingVideo]

    public init(customVideos: [ShadowingVideo]? = nil) {
        if let customVideos {
            self.curatedVideos = customVideos
        } else {
            self.curatedVideos = [
                ShadowingVideo(
                    id: "yt_daily_coffee_01",
                    youtubeVideoId: "kJQP7kiw5Fk",
                    title: "Ordering at a Café",
                    topic: .dailyLife,
                    level: "A2",
                    durationSeconds: 32.0,
                    sentences: [
                        ShadowingSentence(
                            id: "s_01",
                            orderIndex: 0,
                            startTime: 1.0,
                            endTime: 4.5,
                            textEn: "Hi there! What can I get started for you today?",
                            textVi: "Xin chào! Tôi có thể lấy gì cho bạn hôm nay?",
                            keyWords: [
                                ShadowingKeyWord(lemma: "started", phonetic: "/ˈstɑːr.t̬ɪd/", definitionVi: "bắt đầu")
                            ]
                        ),
                        ShadowingSentence(
                            id: "s_02",
                            orderIndex: 1,
                            startTime: 5.0,
                            endTime: 9.2,
                            textEn: "Could I get a medium iced latte with oat milk, please?",
                            textVi: "Cho tôi một ly latte đá cỡ vừa với sữa yến mạch được không?",
                            keyWords: [
                                ShadowingKeyWord(lemma: "latte", phonetic: "/ˈlɑː.teɪ/", definitionVi: "cà phê sữa"),
                                ShadowingKeyWord(lemma: "medium", phonetic: "/ˈmiː.di.əm/", definitionVi: "cỡ vừa")
                            ]
                        ),
                        ShadowingSentence(
                            id: "s_03",
                            orderIndex: 2,
                            startTime: 10.0,
                            endTime: 13.5,
                            textEn: "Sure thing! Would you like that for here or to go?",
                            textVi: "Được chứ! Bạn muốn dùng tại đây hay mang đi?",
                            keyWords: []
                        )
                    ]
                )
            ]
        }
    }

    public func fetchCuratedVideos() async throws -> [ShadowingVideo] {
        curatedVideos
    }

    public func fetchVideo(byId id: String) async throws -> ShadowingVideo? {
        curatedVideos.first(where: { $0.id == id })
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingVideoModelsTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Models/Shadowing/ShadowingVideoModels.swift VocabCraftApp/Domain/Protocols/ShadowingVideoRepositoryProtocol.swift VocabCraftApp/Data/Repositories/ShadowingVideoRepositoryImpl.swift VocabCraftAppTests/Domain/ShadowingVideoModelsTests.swift
git commit -m "feat(shadowing): add domain models and curated video repository"
```

---

### Task 2: Localization Strings (100% EN/VI Parity)

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Localization/ShadowingLocalizationTests.swift`

**Interfaces:**
- Consumes: Keys under `app.shadowing.*`.
- Produces: Localized strings for UI actions, progress, speed, celebration, and SRS saving.

- [ ] **Step 1: Write the failing test for Shadowing localization keys**

Create `VocabCraftAppTests/Localization/ShadowingLocalizationTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Localization Parity Tests")
struct ShadowingLocalizationTests {
    private let requiredKeys = [
        "app.shadowing.title",
        "app.shadowing.progress_format",
        "app.shadowing.speed",
        "app.shadowing.action.hear_native",
        "app.shadowing.action.hear_me",
        "app.shadowing.action.retry",
        "app.shadowing.action.next_sentence",
        "app.shadowing.srs.add_to_vault",
        "app.shadowing.srs.saved_success",
        "app.shadowing.celebration.title",
        "app.shadowing.celebration.message"
    ]

    @Test("Verifies all required Shadowing keys exist in Localizable.xcstrings with EN and VI values")
    func testLocalizationKeys() throws {
        let bundle = Bundle(for: BundleToken.self)
        for key in requiredKeys {
            let enString = String(localized: String.LocalizationValue(key), bundle: bundle, locale: Locale(identifier: "en"))
            let viString = String(localized: String.LocalizationValue(key), bundle: bundle, locale: Locale(identifier: "vi"))

            #expect(!enString.isEmpty, "Missing EN translation for \(key)")
            #expect(!viString.isEmpty, "Missing VI translation for \(key)")
            #expect(enString != key, "Key \(key) was not localized in EN")
            #expect(viString != key, "Key \(key) was not localized in VI")
        }
    }
}

private final class BundleToken {}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingLocalizationTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: FAIL (keys not found in xcstrings).

- [ ] **Step 3: Add `app.shadowing.*` keys to `VocabCraftApp/Resources/Localizable.xcstrings`**

Add the 11 keys with exact English and Vietnamese translations into `Localizable.xcstrings`.

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingLocalizationTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Localization/ShadowingLocalizationTests.swift
git commit -m "feat(shadowing): add bilingual localization strings with 100% EN/VI parity"
```

---

### Task 3: YouTube IFrame WKWebView Bridge with Sub-second Auto-Pause

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/Components/CraftYouTubePlayerView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Components/YouTubePlayerBridgeScript.swift`
- Test: `VocabCraftAppTests/Features/Shadowing/YouTubePlayerBridgeTests.swift`

**Interfaces:**
- Consumes: `youtubeVideoId: String`, `startTime: Double`, `endTime: Double`.
- Produces: `CraftYouTubePlayerView`, `YouTubePlayerBridgeMessage` (`ready`, `segmentFinished`, `timeUpdate`, `stateChange`).

- [ ] **Step 1: Write test for YouTube Player Bridge message parsing**

Create `VocabCraftAppTests/Features/Shadowing/YouTubePlayerBridgeTests.swift`:
```swift
import Testing
@testable import VocabCraftApp

@Suite("YouTube Player Bridge Tests")
struct YouTubePlayerBridgeTests {
    @Test("Verifies parsing of segmentFinished message from JavaScript")
    func testSegmentFinishedParsing() throws {
        let payload: [String: Any] = [
            "type": "segmentFinished",
            "endTime": 12.4
        ]
        let message = YouTubePlayerBridgeMessage(dictionary: payload)
        #expect(message == .segmentFinished(endTime: 12.4))
    }

    @Test("Verifies parsing of ready and stateChange messages")
    func testOtherMessagesParsing() throws {
        let readyPayload: [String: Any] = ["type": "ready"]
        #expect(YouTubePlayerBridgeMessage(dictionary: readyPayload) == .ready)

        let statePayload: [String: Any] = ["type": "state", "state": 1]
        #expect(YouTubePlayerBridgeMessage(dictionary: statePayload) == .stateChange(state: 1))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/YouTubePlayerBridgeTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: FAIL.

- [ ] **Step 3: Implement `YouTubePlayerBridgeScript` and `CraftYouTubePlayerView`**

Create `VocabCraftApp/Features/Shadowing/Components/YouTubePlayerBridgeScript.swift`:
```swift
import Foundation

public enum YouTubePlayerBridgeMessage: Equatable, Sendable {
    case ready
    case segmentFinished(endTime: Double)
    case stateChange(state: Int)
    case unknown

    public init(dictionary: [String: Any]) {
        guard let type = dictionary["type"] as? String else {
            self = .unknown
            return
        }
        switch type {
        case "ready":
            self = .ready
        case "segmentFinished":
            let endTime = dictionary["endTime"] as? Double ?? 0.0
            self = .segmentFinished(endTime: endTime)
        case "state":
            let state = dictionary["state"] as? Int ?? -1
            self = .stateChange(state: state)
        default:
            self = .unknown
        }
    }
}

public enum YouTubePlayerBridgeScript {
    public static func htmlTemplate(videoId: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body, html { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
            #player { width: 100%; height: 100%; }
          </style>
        </head>
        <body>
          <div id="player"></div>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            var player, targetEndTime = 0, isMonitoring = false;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '\(videoId)',
                playerVars: {
                  'playsinline': 1,
                  'controls': 0,
                  'rel': 0,
                  'modestbranding': 1,
                  'disablekb': 1,
                  'fs': 0
                },
                events: {
                  'onReady': function() {
                    window.webkit.messageHandlers.shadowingBridge.postMessage({ type: 'ready' });
                  },
                  'onStateChange': function(e) {
                    window.webkit.messageHandlers.shadowingBridge.postMessage({ type: 'state', state: e.data });
                  }
                }
              });
            }

            function playSegment(start, end, rate) {
              targetEndTime = end;
              if (!player) return;
              if (rate) player.setPlaybackRate(rate);
              player.seekTo(start, true);
              player.playVideo();
              isMonitoring = true;
              requestAnimationFrame(checkTime);
            }

            function pauseVideo() {
              isMonitoring = false;
              if (player) player.pauseVideo();
            }

            function replaySegment(start, end, rate) {
              playSegment(start, end, rate);
            }

            function checkTime() {
              if (!isMonitoring || !player) return;
              var current = player.getCurrentTime();
              if (current >= targetEndTime) {
                player.pauseVideo();
                isMonitoring = false;
                window.webkit.messageHandlers.shadowingBridge.postMessage({
                  type: 'segmentFinished',
                  endTime: targetEndTime
                });
              } else {
                requestAnimationFrame(checkTime);
              }
            }
          </script>
        </body>
        </html>
        """
    }
}
```

Create `VocabCraftApp/Features/Shadowing/Components/CraftYouTubePlayerView.swift`:
```swift
import SwiftUI
import WebKit

public struct CraftYouTubePlayerView: UIViewRepresentable {
    public let videoId: String
    public let onMessage: @MainActor (YouTubePlayerBridgeMessage) -> Void
    public let bridgeHolder: YouTubeBridgeHolder

    public init(
        videoId: String,
        bridgeHolder: YouTubeBridgeHolder,
        onMessage: @escaping @MainActor (YouTubePlayerBridgeMessage) -> Void
    ) {
        self.videoId = videoId
        self.bridgeHolder = bridgeHolder
        self.onMessage = onMessage
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let contentController = configuration.userContentController
        contentController.add(context.coordinator, name: "shadowingBridge")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black

        bridgeHolder.webView = webView
        let html = YouTubePlayerBridgeScript.htmlTemplate(videoId: videoId)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    public final class Coordinator: NSObject, WKScriptMessageHandler {
        private let onMessage: @MainActor (YouTubePlayerBridgeMessage) -> Void

        public init(onMessage: @escaping @MainActor (YouTubePlayerBridgeMessage) -> Void) {
            self.onMessage = onMessage
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any] else { return }
            let parsed = YouTubePlayerBridgeMessage(dictionary: dict)
            Task { @MainActor in
                onMessage(parsed)
            }
        }
    }
}

@MainActor
public final class YouTubeBridgeHolder {
    fileprivate weak var webView: WKWebView?

    public init() {}

    public func playSegment(start: Double, end: Double, rate: Float = 1.0) {
        let js = "playSegment(\(start), \(end), \(rate));"
        webView?.evaluateJavaScript(js)
    }

    public func pauseVideo() {
        let js = "pauseVideo();"
        webView?.evaluateJavaScript(js)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/YouTubePlayerBridgeTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/Components/CraftYouTubePlayerView.swift VocabCraftApp/Features/Shadowing/Components/YouTubePlayerBridgeScript.swift VocabCraftAppTests/Features/Shadowing/YouTubePlayerBridgeTests.swift
git commit -m "feat(shadowing): implement YouTube WKWebView bridge with sub-second auto-pause"
```

---

### Task 4: Shadowing Audio Session Coordinator & Dual-Track Recorder

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/Services/ShadowingAudioRecorder.swift`
- Create: `VocabCraftApp/Features/Shadowing/Services/ShadowingSessionCoordinator.swift`
- Test: `VocabCraftAppTests/Features/Shadowing/ShadowingSessionCoordinatorTests.swift`

**Interfaces:**
- Consumes: `AudioSessionCoordinating` from `SpeechKit`.
- Produces: `ShadowingSessionCoordinator`, recording local `.m4a` file, playing back native or user audio.

- [ ] **Step 1: Write test for ShadowingSessionCoordinator lease transitions**

Create `VocabCraftAppTests/Features/Shadowing/ShadowingSessionCoordinatorTests.swift`:
```swift
import SpeechKit
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Session Coordinator Tests")
struct ShadowingSessionCoordinatorTests {
    @Test("Acquires playback lease when playing native audio and speechCapture when recording")
    func testLeaseTransition() async throws {
        let mockCoordinator = MockAudioSessionCoordinator()
        let sessionCoordinator = ShadowingSessionCoordinator(audioCoordinator: mockCoordinator)

        try await sessionCoordinator.prepareForNativePlayback()
        #expect(mockCoordinator.activeIntent == .playback)

        try await sessionCoordinator.prepareForSpeechCapture()
        #expect(mockCoordinator.activeIntent == .speechCapture)

        await sessionCoordinator.releaseAll()
        #expect(mockCoordinator.activeIntent == nil)
    }
}

private final class MockAudioSessionCoordinator: AudioSessionCoordinating, @unchecked Sendable {
    var activeIntent: AudioSessionIntent?
    var events: AsyncStream<AudioSessionEvent> { AsyncStream { $0.finish() } }

    func acquire(_ intent: AudioSessionIntent) async throws -> AudioSessionLease {
        activeIntent = intent
        return AudioSessionLease(generation: 1, intent: intent)
    }

    func release(_ lease: AudioSessionLease) async {
        if activeIntent == lease.intent {
            activeIntent = nil
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingSessionCoordinatorTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: FAIL.

- [ ] **Step 3: Implement `ShadowingAudioRecorder` and `ShadowingSessionCoordinator`**

Create `VocabCraftApp/Features/Shadowing/Services/ShadowingAudioRecorder.swift`:
```swift
import AVFoundation
import Foundation

@MainActor
public final class ShadowingAudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?

    public private(set) var lastRecordedURL: URL?

    public func startRecording(sentenceId: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("shadowing_\(sentenceId)_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.delegate = self
        recorder.record()
        self.audioRecorder = recorder
        self.lastRecordedURL = fileURL
        return fileURL
    }

    public func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }

    public func playRecordedAudio(from url: URL, onFinished: (@Sendable () -> Void)? = nil) throws {
        audioPlayer?.stop()
        let player = try AVAudioPlayer(contentsOf: url)
        self.audioPlayer = player
        player.play()
    }

    public func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
```

Create `VocabCraftApp/Features/Shadowing/Services/ShadowingSessionCoordinator.swift`:
```swift
import Foundation
import SpeechKit

@MainActor
public final class ShadowingSessionCoordinator {
    private let audioCoordinator: any AudioSessionCoordinating
    private var activeLease: AudioSessionLease?
    public let recorder = ShadowingAudioRecorder()

    public init(audioCoordinator: any AudioSessionCoordinating = NoOpAudioSessionCoordinator()) {
        self.audioCoordinator = audioCoordinator
    }

    public func prepareForNativePlayback() async throws {
        if let lease = activeLease {
            await audioCoordinator.release(lease)
            activeLease = nil
        }
        activeLease = try await audioCoordinator.acquire(.playback)
    }

    public func prepareForSpeechCapture() async throws {
        if let lease = activeLease {
            await audioCoordinator.release(lease)
            activeLease = nil
        }
        activeLease = try await audioCoordinator.acquire(.speechCapture)
    }

    public func releaseAll() async {
        if let lease = activeLease {
            await audioCoordinator.release(lease)
            activeLease = nil
        }
        recorder.stopRecording()
        recorder.stopPlayback()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingSessionCoordinatorTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/Services/ShadowingAudioRecorder.swift VocabCraftApp/Features/Shadowing/Services/ShadowingSessionCoordinator.swift VocabCraftAppTests/Features/Shadowing/ShadowingSessionCoordinatorTests.swift
git commit -m "feat(shadowing): add audio session coordinator and dual-track recorder"
```

---

### Task 5: Shadowing Practice ViewModel & SpeechKit Assessment

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/ViewModels/ShadowingPracticeViewModel.swift`
- Test: `VocabCraftAppTests/Features/Shadowing/ShadowingPracticeViewModelTests.swift`

**Interfaces:**
- Consumes: `ShadowingVideo`, `ShadowingSessionCoordinator`, `SpeechAssessmentProtocol`, `ToggleWordBookmarkUseCase`.
- Produces: `ShadowingPracticeViewModel` driving view states, mic interactions, scoring, and bookmarking.

- [ ] **Step 1: Write ViewModel state machine tests**

Create `VocabCraftAppTests/Features/Shadowing/ShadowingPracticeViewModelTests.swift`:
```swift
import SpeechKit
import Testing
@testable import VocabCraftApp

@Suite("Shadowing Practice ViewModel Tests")
struct ShadowingPracticeViewModelTests {
    @Test("Verifies flow from video playback to ready to record, and advancing sentence")
    @MainActor
    func testViewModelFlow() async throws {
        let sampleVideo = ShadowingVideo(
            id: "v1",
            youtubeVideoId: "test",
            title: "Test Video",
            topic: .dailyLife,
            level: "A2",
            durationSeconds: 10.0,
            sentences: [
                ShadowingSentence(id: "s1", orderIndex: 0, startTime: 0, endTime: 3, textEn: "Hello world", textVi: "Chào thế giới"),
                ShadowingSentence(id: "s2", orderIndex: 1, startTime: 4, endTime: 7, textEn: "How are you", textVi: "Bạn khoẻ không")
            ]
        )

        let mockAssessment = MockSpeechAssessmentService()
        let viewModel = ShadowingPracticeViewModel(
            video: sampleVideo,
            assessmentService: mockAssessment,
            sessionCoordinator: ShadowingSessionCoordinator()
        )

        #expect(viewModel.currentSentence.id == "s1")
        #expect(viewModel.playbackPhase == .idle)

        viewModel.handleSegmentFinished()
        #expect(viewModel.playbackPhase == .readyToRecord)

        viewModel.advanceToNextSentence()
        #expect(viewModel.currentSentence.id == "s2")
    }
}

private final class MockSpeechAssessmentService: SpeechAssessmentProtocol, @unchecked Sendable {
    var isListening: Bool = false
    var currentEvaluation: SpeechEvaluationResult?

    func startAssessing(
        targetSentence: String,
        contextualPhrases: [String],
        onPartialEvaluation: @escaping @Sendable (SpeechEvaluationResult) -> Void,
        onFinalEvaluation: @escaping @Sendable (SpeechEvaluationResult) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {}

    func stop() {}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingPracticeViewModelTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: FAIL.

- [ ] **Step 3: Implement `ShadowingPracticeViewModel`**

Create `VocabCraftApp/Features/Shadowing/ViewModels/ShadowingPracticeViewModel.swift`:
```swift
import Foundation
import Observation
import SpeechKit

@MainActor
@Observable
public final class ShadowingPracticeViewModel {
    public let video: ShadowingVideo
    public private(set) var currentSentenceIndex: Int = 0
    public var playbackPhase: ShadowingPlaybackPhase = .idle
    public var playbackSpeed: Float = 1.0

    public var currentEvaluation: SpeechEvaluationResult?
    public var sentenceAttempts: [String: SentenceAttemptRecord] = [:]
    public var bookmarkedWordIds: Set<String> = []
    public var selectedKeyWordForPopover: ShadowingKeyWord?

    public let bridgeHolder = YouTubeBridgeHolder()
    private let assessmentService: any SpeechAssessmentProtocol
    public let sessionCoordinator: ShadowingSessionCoordinator
    private let toggleBookmarkUseCase: ToggleWordBookmarkUseCase?

    public var currentSentence: ShadowingSentence {
        guard currentSentenceIndex < video.sentences.count else {
            return video.sentences.last ?? ShadowingSentence(id: "", orderIndex: 0, startTime: 0, endTime: 0, textEn: "", textVi: "")
        }
        return video.sentences[currentSentenceIndex]
    }

    public var isLastSentence: Bool {
        currentSentenceIndex >= video.sentences.count - 1
    }

    public init(
        video: ShadowingVideo,
        assessmentService: any SpeechAssessmentProtocol = SpeechAssessmentService(),
        sessionCoordinator: ShadowingSessionCoordinator = ShadowingSessionCoordinator(),
        toggleBookmarkUseCase: ToggleWordBookmarkUseCase? = nil
    ) {
        self.video = video
        self.assessmentService = assessmentService
        self.sessionCoordinator = sessionCoordinator
        self.toggleBookmarkUseCase = toggleBookmarkUseCase
    }

    public func startCurrentSentence() {
        Task {
            do {
                try await sessionCoordinator.prepareForNativePlayback()
                playbackPhase = .playingNative(currentTime: currentSentence.startTime)
                bridgeHolder.playSegment(start: currentSentence.startTime, end: currentSentence.endTime, rate: playbackSpeed)
            } catch {
                playbackPhase = .readyToRecord
            }
        }
    }

    public func handleSegmentFinished() {
        playbackPhase = .readyToRecord
    }

    public func toggleRecording() {
        if case .listening = playbackPhase {
            stopRecording()
        } else {
            startRecording()
        }
    }

    public func startRecording() {
        Task {
            do {
                try await sessionCoordinator.prepareForSpeechCapture()
                let audioURL = try sessionCoordinator.recorder.startRecording(sentenceId: currentSentence.id)
                playbackPhase = .listening(levels: [])

                try assessmentService.startAssessing(
                    targetSentence: currentSentence.textEn,
                    contextualPhrases: currentSentence.keyWords.map(\.lemma),
                    onPartialEvaluation: { [weak self] partial in
                        Task { @MainActor [weak self] in
                            self?.currentEvaluation = partial
                        }
                    },
                    onFinalEvaluation: { [weak self] finalEval in
                        Task { @MainActor [weak self] in
                            self?.finishEvaluation(finalEval, audioURL: audioURL)
                        }
                    },
                    onError: { [weak self] _ in
                        Task { @MainActor [weak self] in
                            self?.playbackPhase = .readyToRecord
                        }
                    }
                )
            } catch {
                playbackPhase = .readyToRecord
            }
        }
    }

    public func stopRecording() {
        assessmentService.stop()
        sessionCoordinator.recorder.stopRecording()
        playbackPhase = .evaluating
    }

    private func finishEvaluation(_ evaluation: SpeechEvaluationResult, audioURL: URL) {
        currentEvaluation = evaluation
        let isPassed = evaluation.overallScore >= 70.0
        sentenceAttempts[currentSentence.id] = SentenceAttemptRecord(
            score: evaluation.overallScore,
            userAudioURL: audioURL,
            isPassed: isPassed
        )
        playbackPhase = .evaluated(score: evaluation.overallScore)
    }

    public func playNativeAudio() {
        bridgeHolder.playSegment(start: currentSentence.startTime, end: currentSentence.endTime, rate: playbackSpeed)
    }

    public func playUserAudio() {
        guard let record = sentenceAttempts[currentSentence.id], let url = record.userAudioURL else { return }
        try? sessionCoordinator.recorder.playRecordedAudio(from: url)
    }

    public func advanceToNextSentence() {
        guard currentSentenceIndex < video.sentences.count - 1 else { return }
        currentSentenceIndex += 1
        currentEvaluation = nil
        playbackPhase = .idle
        startCurrentSentence()
    }

    public func setSpeed(_ speed: Float) {
        self.playbackSpeed = speed
    }

    public func toggleBookmark(lemma: String) {
        if bookmarkedWordIds.contains(lemma) {
            bookmarkedWordIds.remove(lemma)
        } else {
            bookmarkedWordIds.insert(lemma)
            // If linked to word repository, execute use case
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/ShadowingPracticeViewModelTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/ViewModels/ShadowingPracticeViewModel.swift VocabCraftAppTests/Features/Shadowing/ShadowingPracticeViewModelTests.swift
git commit -m "feat(shadowing): implement ShadowingPracticeViewModel with SpeechKit assessment"
```

---

### Task 6: Interactive UI Assembly (`ShadowingPracticeView`)

**Files:**
- Create: `VocabCraftApp/Features/Shadowing/Views/ShadowingPracticeView.swift`
- Create: `VocabCraftApp/Features/Shadowing/Views/ShadowingKeyWordPopoverView.swift`
- Modify: `VocabCraftApp/App/AppRoute.swift` (or Navigation coordinator if existing)

**Interfaces:**
- Consumes: `ShadowingPracticeViewModel`, `CraftVoiceMatchCard`, `CraftYouTubePlayerView`, `CraftButton`, `CraftPill`, `CraftProgressBar`.
- Produces: `ShadowingPracticeView`.

- [ ] **Step 1: Create `ShadowingKeyWordPopoverView`**

Create `VocabCraftApp/Features/Shadowing/Views/ShadowingKeyWordPopoverView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct ShadowingKeyWordPopoverView: View {
    @Environment(\.craftTheme) private var theme
    public let keyWord: ShadowingKeyWord
    public let isBookmarked: Bool
    public let onToggleBookmark: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(keyWord.lemma)
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text(keyWord.phonetic)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
                Button(action: onToggleBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundColor(isBookmarked ? theme.colors.brandPrimary : theme.colors.textSecondary)
                }
            }

            Text(keyWord.definitionVi)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)

            CraftButton(
                title: String(localized: "app.shadowing.srs.add_to_vault"),
                icon: "plus.circle.fill",
                style: .secondary,
                action: onToggleBookmark
            )
        }
        .padding(theme.spacing.md)
        .frame(width: 260)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
    }
}
```

- [ ] **Step 2: Create `ShadowingPracticeView` using `CraftVoiceMatchCard`**

Create `VocabCraftApp/Features/Shadowing/Views/ShadowingPracticeView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct ShadowingPracticeView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShadowingPracticeViewModel

    public init(viewModel: ShadowingPracticeViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    private var speechState: CraftSpeechState {
        switch viewModel.playbackPhase {
        case .idle, .playingNative, .readyToRecord:
            return .idle
        case let .listening(levels):
            return .listening(levels: levels)
        case .evaluating:
            return .evaluating
        case let .evaluated(score):
            return .evaluated(score: score)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.md) {
                    // YouTube Player Container
                    playerContainer

                    // Speed and Replay Controls
                    playbackControlsBar

                    // Master Speech Card (CraftVoiceMatchCard)
                    CraftVoiceMatchCard(
                        originText: viewModel.currentSentence.textEn,
                        subtitle: viewModel.currentSentence.textVi,
                        speechState: speechState,
                        customInstruction: String(localized: "app.shadowing.title"),
                        onTapMic: {
                            viewModel.toggleRecording()
                        },
                        onReset: {
                            viewModel.startCurrentSentence()
                        }
                    )

                    // Dual Audio Comparison & Action Bar
                    if case .evaluated = viewModel.playbackPhase {
                        comparisonActionBar
                    }
                }
                .padding(.horizontal, theme.spacing.md)
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .background(theme.colors.surfaceBackground.ignoresSafeArea())
        .onAppear {
            viewModel.startCurrentSentence()
        }
        .popover(item: $viewModel.selectedKeyWordForPopover) { keyWord in
            ShadowingKeyWordPopoverView(
                keyWord: keyWord,
                isBookmarked: viewModel.bookmarkedWordIds.contains(keyWord.lemma),
                onToggleBookmark: {
                    viewModel.toggleBookmark(lemma: keyWord.lemma)
                }
            )
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 40, height: 40)
            }

            Spacer()

            Text(viewModel.video.title)
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(String(localized: "app.shadowing.progress_format", args: viewModel.currentSentenceIndex + 1, viewModel.video.sentences.count))
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.xs)
    }

    private var playerContainer: some View {
        CraftYouTubePlayerView(
            videoId: viewModel.video.youtubeVideoId,
            bridgeHolder: viewModel.bridgeHolder,
            onMessage: { message in
                if case .segmentFinished = message {
                    viewModel.handleSegmentFinished()
                }
            }
        )
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
                .stroke(theme.colors.borderDefault, lineWidth: 1)
        )
    }

    private var playbackControlsBar: some View {
        HStack {
            HStack(spacing: theme.spacing.xs) {
                speedPill(0.8)
                speedPill(1.0)
            }

            Spacer()

            CraftButton(
                title: String(localized: "app.shadowing.action.retry"),
                icon: "arrow.counterclockwise",
                style: .ghost,
                size: .small,
                action: {
                    viewModel.startCurrentSentence()
                }
            )
        }
    }

    private func speedPill(_ speed: Float) -> some View {
        let isSelected = viewModel.playbackSpeed == speed
        return Button(action: { viewModel.setSpeed(speed) }) {
            Text(String(format: "%.1fx", speed))
                .font(theme.typography.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? theme.colors.brandPrimary : theme.colors.textSecondary)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs / 2)
                .background(isSelected ? theme.colors.brandPrimary.opacity(0.12) : theme.colors.surfaceCard)
                .clipShape(Capsule())
        }
    }

    private var comparisonActionBar: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.sm) {
                CraftButton(
                    title: String(localized: "app.shadowing.action.hear_native"),
                    icon: "speaker.wave.2.fill",
                    style: .secondary,
                    action: {
                        viewModel.playNativeAudio()
                    }
                )

                CraftButton(
                    title: String(localized: "app.shadowing.action.hear_me"),
                    icon: "waveform.badge.mic",
                    style: .secondary,
                    action: {
                        viewModel.playUserAudio()
                    }
                )
            }

            if !viewModel.isLastSentence {
                CraftButton(
                    title: String(localized: "app.shadowing.action.next_sentence"),
                    icon: "arrow.right",
                    style: .primary,
                    action: {
                        viewModel.advanceToNextSentence()
                    }
                )
            }
        }
    }
}
```

- [ ] **Step 3: Build app to verify zero compilation errors**

Run:
```bash
xcodebuild build -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: BUILD SUCCEEDED with 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Shadowing/Views/ShadowingPracticeView.swift VocabCraftApp/Features/Shadowing/Views/ShadowingKeyWordPopoverView.swift
git commit -m "feat(shadowing): assemble ShadowingPracticeView using CraftUIKit components"
```

---

### Task 7: Full Verification Suite & Quality Gate

**Files:**
- Test: All created unit and localization tests.
- Audit: SwiftLint & Compiler diagnostics.

**Interfaces:**
- Consumes: All tests in `VocabCraftAppTests`.
- Produces: 100% test pass, 0 lint warnings, 0 compiler warnings.

- [ ] **Step 1: Run full unit test suite**

Run:
```bash
xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: 100% PASS.

- [ ] **Step 2: Run SwiftLint**

Run:
```bash
swiftlint --strict
```
Expected: 0 violations.

- [ ] **Step 3: Commit and verify git clean state**

```bash
git status
```
Expected: clean working directory.
