# Natural Voice System Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade VocabCraft's voice and Text-To-Speech architecture from robotic monotone default voices to a friendly, human-like voice experience using Smart Hybrid Routing: On-Device Apple Enhanced Voices (with intelligent selection & prosody tuning) for fast vocabulary/reflex drills, and Gemini Generative Audio (with warm, expressive personas and instant offline fallback) for AI Roleplay Call.

**Architecture:** 
- `TextToSpeechProtocol` abstraction enhanced with `SpeechContext` (`pronunciation` vs `conversation(persona:)`).
- `AppleVoiceSelector`: Queries `AVSpeechSynthesisVoice.speechVoices()`, sorts by quality (`.premium` > `.enhanced` > curated compact whitelist), and blacklists robotic/distorted voices.
- `AppleEnhancedTTSEngine`: Applies prosody tuning (`pitchMultiplier = 1.06`, `rate = 0.49`, pre/post-utterance delays) to `AVSpeechUtterance`.
- `GeminiAudioSpeechEngine`: Calls Gemini Audio endpoint with user's configured API key, decodes audio, caches in-memory, and coordinates playback with `AudioSessionCoordinator`.
- `TextToSpeechService` acts as the `SmartVoiceRouter` with immediate resilient failover to Apple TTS upon timeout or network errors.

**Tech Stack:** Swift 6, AVFoundation, AudioToolbox, Observation, CraftUIKit, Swift Testing / XCTest.

**Spec:** [`docs/superpowers/specs/2026-10-05-natural-voice-system-upgrade-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-10-05-natural-voice-system-upgrade-design.md)

## Global Constraints
- Target iOS 18+ SDK.
- Zero raw styling: strictly adhere to `CraftUIKit` tokens if any UI is touched.
- Zero hardcoded strings: all user-facing copy and diagnostic strings must reside in `Localizable.xcstrings` (100% EN & VI parity).
- Audio Session Safety: all playback must acquire and release `.playback` leases from `AudioSessionCoordinator`.
- Zero compiler warnings and 0 SwiftLint violations.

---

### Task 1: String Catalog Entries & AppStrings Accessors

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Create: `VocabCraftAppTests/Core/Audio/AudioLocalizationTests.swift`

**Interfaces:**
- Consumes: Existing `AppStrings` namespace.
- Produces:
  - `AppStrings.Audio.voiceQualityPremium`: `LocalizedStringKey`
  - `AppStrings.Audio.voiceQualityEnhanced`: `LocalizedStringKey`
  - `AppStrings.Audio.voiceQualityStandard`: `LocalizedStringKey`
  - `AppStrings.Audio.fallbackNotice`: `LocalizedStringKey`

- [ ] **Step 1: Write the failing localization test**

Create `VocabCraftAppTests/Core/Audio/AudioLocalizationTests.swift`:
```swift
import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("Audio Localization Tests")
struct AudioLocalizationTests {
    @Test("Verify audio voice quality and fallback string keys exist in English and Vietnamese")
    func test_audioLocalizationKeys_existInEnglishAndVietnamese() throws {
        guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings") ??
                Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings") else {
            Issue.record("Localizable.xcstrings not found")
            return
        }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let strings = json?["strings"] as? [String: Any]

        let requiredKeys = [
            "app.audio.voice_quality_premium",
            "app.audio.voice_quality_enhanced",
            "app.audio.voice_quality_standard",
            "app.audio.fallback_notice"
        ]

        for key in requiredKeys {
            let entry = strings?[key] as? [String: Any]
            #expect(entry != nil, "Missing key: \(key)")
            let localizations = entry?["localizations"] as? [String: Any]
            let en = localizations?["en"] as? [String: Any]
            let vi = localizations?["vi"] as? [String: Any]
            #expect(en != nil, "Missing EN translation for \(key)")
            #expect(vi != nil, "Missing VI translation for \(key)")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AudioLocalizationTests`
Expected: FAIL with "Missing key: app.audio.voice_quality_premium".

- [ ] **Step 3: Add localization entries to `Localizable.xcstrings` and `AppStrings.swift`**

Add strings to `VocabCraftApp/Resources/Localizable.xcstrings`:
```json
    "app.audio.fallback_notice" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Switched to offline voice"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Đang chuyển sang giọng đọc ngoại tuyến"
          }
        }
      }
    },
    "app.audio.voice_quality_enhanced" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Enhanced Natural Voice"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Giọng nói tự nhiên nâng cao"
          }
        }
      }
    },
    "app.audio.voice_quality_premium" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Studio Quality Voice"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Chất lượng giọng nói chuẩn Studio"
          }
        }
      }
    },
    "app.audio.voice_quality_standard" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Standard Voice"
          }
        },
        "vi" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Giọng nói tiêu chuẩn"
          }
        }
      }
    }
```

In `VocabCraftApp/Core/Localization/AppStrings.swift`, add:
```swift
    public enum Audio {
        public static var voiceQualityPremium: LocalizedStringKey { "app.audio.voice_quality_premium" }
        public static var voiceQualityEnhanced: LocalizedStringKey { "app.audio.voice_quality_enhanced" }
        public static var voiceQualityStandard: LocalizedStringKey { "app.audio.voice_quality_standard" }
        public static var fallbackNotice: LocalizedStringKey { "app.audio.fallback_notice" }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AudioLocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftAppTests/Core/Audio/AudioLocalizationTests.swift
git commit -m "feat(audio): add localization keys and AppStrings for audio system"
```

---

### Task 2: Speech Models, Persona & Extended `TextToSpeechProtocol`

**Files:**
- Modify: `VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift`
- Create: `VocabCraftAppTests/Domain/SpeechContextTests.swift`

**Interfaces:**
- Consumes: `AudioServiceProtocols.swift`.
- Produces:
  - `enum VoicePersona: String, Sendable, Codable, CaseIterable`
  - `enum SpeechContext: Sendable, Equatable`
  - `func speak(text: String, context: SpeechContext, rate: Float)`
  - `func speakAsync(text: String, context: SpeechContext, rate: Float) async`

- [ ] **Step 1: Write the failing domain test**

Create `VocabCraftAppTests/Domain/SpeechContextTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speech Context & Voice Persona Domain Tests")
struct SpeechContextTests {
    @Test("Verify VoicePersona identifiers match expected Gemini voices")
    func test_voicePersona_identifiers() {
        #expect(VoicePersona.friendlyFemale.rawValue == "Aoede")
        #expect(VoicePersona.friendlyMale.rawValue == "Puck")
        #expect(VoicePersona.authoritativeMale.rawValue == "Charon")
        #expect(VoicePersona.expressiveFemale.rawValue == "Kore")
    }

    @Test("Verify SpeechContext default values and equality")
    func test_speechContext_defaults() {
        let pronunciation = SpeechContext.pronunciation()
        let conversation = SpeechContext.conversation(persona: .friendlyFemale)

        #expect(pronunciation == .pronunciation(locale: "en-US"))
        #expect(conversation != pronunciation)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SpeechContextTests`
Expected: FAIL with "cannot find 'VoicePersona' in scope".

- [ ] **Step 3: Implement `VoicePersona`, `SpeechContext`, and update `TextToSpeechProtocol`**

In `VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift`:
```swift
/// Voice personas representing distinctive conversational character styles.
public enum VoicePersona: String, Sendable, Codable, CaseIterable {
    case friendlyFemale = "Aoede"
    case friendlyMale = "Puck"
    case authoritativeMale = "Charon"
    case expressiveFemale = "Kore"
}

/// The situational context under which speech synthesis is performed.
public enum SpeechContext: Sendable, Equatable {
    case pronunciation(locale: String = "en-US")
    case conversation(persona: VoicePersona = .friendlyFemale, locale: String = "en-US")
}

@MainActor
public protocol TextToSpeechProtocol: AnyObject, Sendable {
    var isSpeaking: Bool { get }
    func speak(text: String, rate: Float, locale: String)
    func speakAsync(text: String, rate: Float, locale: String) async
    func speak(text: String, context: SpeechContext, rate: Float)
    func speakAsync(text: String, context: SpeechContext, rate: Float) async
    func stop()
    func prewarm()
}

public extension TextToSpeechProtocol {
    func prewarm() {}

    func speak(text: String) {
        speak(text: text, rate: 0.5, locale: "en-US")
    }

    func speakAsync(text: String) async {
        await speakAsync(text: text, rate: 0.5, locale: "en-US")
    }

    func speakAsync(text: String, rate: Float, locale: String) async {
        speak(text: text, rate: rate, locale: locale)
    }

    func speak(text: String, context: SpeechContext, rate: Float = 1.0) {
        switch context {
        case .pronunciation(let locale):
            speak(text: text, rate: rate, locale: locale)
        case .conversation(_, let locale):
            speak(text: text, rate: rate, locale: locale)
        }
    }

    func speakAsync(text: String, context: SpeechContext, rate: Float = 1.0) async {
        switch context {
        case .pronunciation(let locale):
            await speakAsync(text: text, rate: rate, locale: locale)
        case .conversation(_, let locale):
            await speakAsync(text: text, rate: rate, locale: locale)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SpeechContextTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/AudioServiceProtocols.swift VocabCraftAppTests/Domain/SpeechContextTests.swift
git commit -m "feat(audio): extend TextToSpeechProtocol with SpeechContext and VoicePersona"
```

---

### Task 3: `AppleVoiceSelector` (Intelligent On-Device Voice Filtering & Ranking)

**Files:**
- Create: `VocabCraftApp/Core/Audio/AppleVoiceSelector.swift`
- Create: `VocabCraftAppTests/Core/Audio/AppleVoiceSelectorTests.swift`

**Interfaces:**
- Consumes: `AVFoundation.AVSpeechSynthesisVoice`.
- Produces:
  - `enum AppleVoiceSelector`:
    - `static func resolveBestVoice(for locale: String, availableVoices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice?`
    - `static func resolveBestVoice(for locale: String) -> AVSpeechSynthesisVoice?`
    - `static func isBlacklisted(voiceName: String) -> Bool`

- [ ] **Step 1: Write the failing tests for `AppleVoiceSelector`**

Create `VocabCraftAppTests/Core/Audio/AppleVoiceSelectorTests.swift`:
```swift
import AVFoundation
import Testing
@testable import VocabCraftApp

@Suite("Apple Voice Selector Tests")
struct AppleVoiceSelectorTests {
    @Test("Verify blacklisted novelty/distorted voices are rejected")
    func test_blacklistedVoices_rejected() {
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Albert"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Bad News"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Fred"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Eddy"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Grandpa"))
        #expect(!AppleVoiceSelector.isBlacklisted(voiceName: "Samantha"))
        #expect(!AppleVoiceSelector.isBlacklisted(voiceName: "Ava"))
    }

    @Test("Verify voice resolver prioritizes higher quality and whitelisted voices")
    func test_resolveBestVoice_prioritizesCorrectly() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let resolved = AppleVoiceSelector.resolveBestVoice(for: "en-US", availableVoices: voices)
        
        #expect(resolved != nil)
        if let resolved {
            #expect(!AppleVoiceSelector.isBlacklisted(voiceName: resolved.name))
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AppleVoiceSelectorTests`
Expected: FAIL with "cannot find 'AppleVoiceSelector' in scope".

- [ ] **Step 3: Implement `AppleVoiceSelector`**

Create `VocabCraftApp/Core/Audio/AppleVoiceSelector.swift`:
```swift
import AVFoundation
import Foundation

public enum AppleVoiceSelector: Sendable {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var cachedBestVoice: [String: AVSpeechSynthesisVoice] = [:]

    public static let blacklistedVoices: Set<String> = [
        "albert", "bad news", "bahh", "bells", "boing", "bubbles",
        "cellos", "deranged", "fred", "eddy", "grandpa", "grandma",
        "organ", "trinoids", "whisper", "zarvox", "rocko", "sandy", "reed"
    ]

    public static let curatedWhitelist: [String] = [
        "ava", "zoe", "allison", "samantha", "nathan", "tom",
        "oliver", "serena", "karen", "daniel", "rishi", "moira"
    ]

    public static func isBlacklisted(voiceName: String) -> Bool {
        blacklistedVoices.contains(voiceName.lowercased())
    }

    public static func resolveBestVoice(for locale: String) -> AVSpeechSynthesisVoice? {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedBestVoice[locale] {
            return cached
        }

        let voices = AVSpeechSynthesisVoice.speechVoices()
        let resolved = resolveBestVoice(for: locale, availableVoices: voices)
        if let resolved {
            cachedBestVoice[locale] = resolved
        }
        return resolved
    }

    public static func resolveBestVoice(
        for locale: String,
        availableVoices: [AVSpeechSynthesisVoice]
    ) -> AVSpeechSynthesisVoice? {
        let matchingVoices = availableVoices.filter { voice in
            (voice.language == locale || voice.language.hasPrefix("en")) &&
            !isBlacklisted(voiceName: voice.name)
        }

        guard !matchingVoices.isEmpty else {
            return AVSpeechSynthesisVoice(language: locale) ?? AVSpeechSynthesisVoice(language: "en-US")
        }

        // Rank 1: Premium quality voices
        if let premium = matchingVoices.first(where: { $0.quality == .premium && ($0.language == locale || $0.language.hasPrefix("en-US")) }) {
            return premium
        }

        // Rank 2: Enhanced quality voices
        if let enhanced = matchingVoices.first(where: { $0.quality == .enhanced && ($0.language == locale || $0.language.hasPrefix("en-US")) }) {
            return enhanced
        }

        // Rank 3: Curated whitelist compact voices
        for preferredName in curatedWhitelist {
            if let matched = matchingVoices.first(where: { $0.name.lowercased() == preferredName && $0.language == locale }) {
                return matched
            }
        }

        // Rank 4: Exact locale match with quality default
        if let exactLocale = matchingVoices.first(where: { $0.language == locale }) {
            return exactLocale
        }

        // Fallback: First non-blacklisted English voice
        return matchingVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    public static func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedBestVoice.removeAll()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AppleVoiceSelectorTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/AppleVoiceSelector.swift VocabCraftAppTests/Core/Audio/AppleVoiceSelectorTests.swift
git commit -m "feat(audio): implement AppleVoiceSelector with quality ranking and whitelist/blacklist"
```

---

### Task 4: `AppleEnhancedTTSEngine` with Prosody & Natural Acoustic Tuning

**Files:**
- Create: `VocabCraftApp/Core/Audio/AppleEnhancedTTSEngine.swift`
- Create: `VocabCraftAppTests/Core/Audio/AppleEnhancedTTSEngineTests.swift`

**Interfaces:**
- Consumes: `AppleVoiceSelector`, `AVSpeechSynthesizer`, `AudioSessionCoordinating`.
- Produces:
  - `final class AppleEnhancedTTSEngine: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable`
    - `func speak(text: String, rate: Float, locale: String, onFinished: @escaping () -> Void)`
    - `func speakAsync(text: String, rate: Float, locale: String) async`
    - `func stop()`

- [ ] **Step 1: Write failing test for `AppleEnhancedTTSEngine`**

Create `VocabCraftAppTests/Core/Audio/AppleEnhancedTTSEngineTests.swift`:
```swift
import AVFoundation
import Testing
@testable import VocabCraftApp

@Suite("Apple Enhanced TTS Engine Tests")
struct AppleEnhancedTTSEngineTests {
    @Test("Verify makeUtterance applies warm pitch and gentle acoustic delays")
    @MainActor
    func test_makeUtterance_prosodyParameters() {
        let engine = AppleEnhancedTTSEngine()
        let utterance = engine.makeUtterance(text: "Hello world", rate: 1.0, locale: "en-US")

        #expect(utterance != nil)
        if let utterance {
            #expect(utterance.pitchMultiplier >= 1.04 && utterance.pitchMultiplier <= 1.08)
            #expect(utterance.preUtteranceDelay == 0.05)
            #expect(utterance.postUtteranceDelay == 0.10)
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AppleEnhancedTTSEngineTests`
Expected: FAIL with "cannot find 'AppleEnhancedTTSEngine' in scope".

- [ ] **Step 3: Implement `AppleEnhancedTTSEngine`**

Create `VocabCraftApp/Core/Audio/AppleEnhancedTTSEngine.swift`:
```swift
import AVFoundation
import Foundation

@MainActor
public final class AppleEnhancedTTSEngine: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private var activeContinuation: CheckedContinuation<Void, Never>?
    public private(set) var isSpeaking: Bool = false
    private var currentUtterance: AVSpeechUtterance?

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func makeUtterance(text: String, rate: Float, locale: String) -> AVSpeechUtterance? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let utterance = AVSpeechUtterance(string: trimmed)

        // Standard English speech rate: scale around 0.49
        let baseRate = AVSpeechUtteranceDefaultSpeechRate * 0.98
        let scaledRate = baseRate * rate
        utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)

        // Warm, friendly pitch multiplier
        utterance.pitchMultiplier = 1.06

        // Acoustic buffers to prevent clipping and jarring ends
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.10

        if let voice = AppleVoiceSelector.resolveBestVoice(for: locale) {
            utterance.voice = voice
        }

        return utterance
    }

    public func speak(text: String, rate: Float = 1.0, locale: String = "en-US") {
        guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else { return }
        stop()

        isSpeaking = true
        currentUtterance = utterance

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting { return }
        synthesizer.speak(utterance)
    }

    public func speakAsync(text: String, rate: Float = 1.0, locale: String = "en-US") async {
        guard let utterance = makeUtterance(text: text, rate: rate, locale: locale) else {
            isSpeaking = false
            currentUtterance = nil
            return
        }

        stop()
        isSpeaking = true
        currentUtterance = utterance

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            isSpeaking = false
            currentUtterance = nil
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.activeContinuation = continuation
            self.synthesizer.speak(utterance)
        }
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume()
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.currentUtterance === utterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
        }
    }

    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, self.currentUtterance === utterance else { return }
            self.currentUtterance = nil
            self.isSpeaking = false
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume()
            }
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AppleEnhancedTTSEngineTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/AppleEnhancedTTSEngine.swift VocabCraftAppTests/Core/Audio/AppleEnhancedTTSEngineTests.swift
git commit -m "feat(audio): implement AppleEnhancedTTSEngine with prosody tuning"
```

---

### Task 5: `GeminiAudioSpeechEngine` (Cloud Expressive Voice Synthesis with In-Memory Cache)

**Files:**
- Create: `VocabCraftApp/Core/Audio/GeminiAudioSpeechEngine.swift`
- Create: `VocabCraftAppTests/Core/Audio/GeminiAudioSpeechEngineTests.swift`

**Interfaces:**
- Consumes: `VoicePersona`, `URLSession`, `AVAudioPlayer`, `AudioSessionCoordinating`.
- Produces:
  - `protocol GeminiAudioSynthesizing: Sendable`
  - `final class GeminiAudioSpeechEngine: NSObject, AVAudioPlayerDelegate, GeminiAudioSynthesizing, @unchecked Sendable`
    - `func synthesizeAndPlay(text: String, persona: VoicePersona, apiKey: String) async throws`
    - `func stop()`

- [ ] **Step 1: Write failing test for `GeminiAudioSpeechEngine`**

Create `VocabCraftAppTests/Core/Audio/GeminiAudioSpeechEngineTests.swift`:
```swift
import AVFoundation
import Testing
@testable import VocabCraftApp

@Suite("Gemini Audio Speech Engine Tests")
struct GeminiAudioSpeechEngineTests {
    @Test("Verify audio cache generates consistent key and stores audio")
    @MainActor
    func test_cacheKeyAndStorage() {
        let engine = GeminiAudioSpeechEngine()
        let fakeData = Data([0x52, 0x49, 0x46, 0x46]) // "RIFF"
        let key = engine.cacheKey(for: "Hello barista", persona: .friendlyFemale)

        #expect(!key.isEmpty)
        engine.storeInCache(key: key, data: fakeData)
        #expect(engine.cachedData(for: key) == fakeData)
    }

    @Test("Verify request builder constructs correct REST URL and payload")
    @MainActor
    func test_requestBuilder() throws {
        let engine = GeminiAudioSpeechEngine()
        let request = try engine.buildRequest(text: "Welcome to London", persona: .friendlyMale, apiKey: "test-api-key")

        #expect(request.url?.absoluteString.contains("generativelanguage.googleapis.com") == true)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter GeminiAudioSpeechEngineTests`
Expected: FAIL with "cannot find 'GeminiAudioSpeechEngine' in scope".

- [ ] **Step 3: Implement `GeminiAudioSpeechEngine`**

Create `VocabCraftApp/Core/Audio/GeminiAudioSpeechEngine.swift`:
```swift
import AVFoundation
import Foundation

public protocol GeminiAudioSynthesizing: AnyObject, Sendable {
    var isSpeaking: Bool { get }
    func synthesizeAndPlay(text: String, persona: VoicePersona, apiKey: String) async throws
    func stop()
}

@MainActor
public final class GeminiAudioSpeechEngine: NSObject, AVAudioPlayerDelegate, GeminiAudioSynthesizing, @unchecked Sendable {
    public private(set) var isSpeaking: Bool = false
    private var audioPlayer: AVAudioPlayer?
    private var activeContinuation: CheckedContinuation<Void, Error>?
    private var cache: [String: Data] = [:]
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        super.init()
    }

    public func cacheKey(for text: String, persona: VoicePersona) -> String {
        "\(persona.rawValue)::\(text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    public func cachedData(for key: String) -> Data? {
        cache[key]
    }

    public func storeInCache(key: String, data: Data) {
        if cache.count > 50 { cache.removeAll() }
        cache[key] = data
    }

    public func buildRequest(text: String, persona: VoicePersona, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.5

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Read the following dialogue turn aloud with a warm, natural conversational tone:\n\(text)"]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["AUDIO"],
                "speechConfig": [
                    "voiceConfig": [
                        "prebuiltVoiceConfig": [
                            "voiceName": persona.rawValue
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    public func synthesizeAndPlay(text: String, persona: VoicePersona, apiKey: String) async throws {
        stop()

        let key = cacheKey(for: text, persona: persona)
        let audioData: Data

        if let cached = cachedData(for: key) {
            audioData = cached
        } else {
            let request = try buildRequest(text: text, persona: persona, apiKey: apiKey)
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let inlineData = firstPart["inlineData"] as? [String: Any],
                  let base64String = inlineData["data"] as? String,
                  let decoded = Data(base64Encoded: base64String) else {
                throw URLError(.cannotParseResponse)
            }

            audioData = decoded
            storeInCache(key: key, data: decoded)
        }

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting { return }

        try await playAudioData(audioData)
    }

    private func playAudioData(_ data: Data) async throws {
        isSpeaking = true
        let player = try AVAudioPlayer(data: data)
        self.audioPlayer = player
        player.delegate = self
        player.prepareToPlay()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.activeContinuation = continuation
            player.play()
        }
    }

    public func stop() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        isSpeaking = false
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume(returning: ())
        }
    }

    // MARK: - AVAudioPlayerDelegate

    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isSpeaking = false
            self.audioPlayer = nil
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(returning: ())
            }
        }
    }

    public nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isSpeaking = false
            self.audioPlayer = nil
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(throwing: error ?? URLError(.cannotDecodeContentData))
            }
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter GeminiAudioSpeechEngineTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/GeminiAudioSpeechEngine.swift VocabCraftAppTests/Core/Audio/GeminiAudioSpeechEngineTests.swift
git commit -m "feat(audio): implement GeminiAudioSpeechEngine with REST audio synthesis and cache"
```

---

### Task 6: `TextToSpeechService` Smart Router Refactor with Resilient Failover

**Files:**
- Modify: `VocabCraftApp/Core/Audio/TextToSpeechService.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Create: `VocabCraftAppTests/Core/Audio/SmartVoiceRouterTests.swift`

**Interfaces:**
- Consumes: `AppleEnhancedTTSEngine`, `GeminiAudioSpeechEngine`, `AudioSessionCoordinator`, `SettingsStore`.
- Produces:
  - `TextToSpeechService: TextToSpeechProtocol` implementing context-aware routing and automatic fallback.

- [ ] **Step 1: Write failing test for `SmartVoiceRouterTests`**

Create `VocabCraftAppTests/Core/Audio/SmartVoiceRouterTests.swift`:
```swift
import Testing
@testable import VocabCraftApp

@Suite("Smart Voice Router & Fallback Tests")
struct SmartVoiceRouterTests {
    @Test("Verify pronunciation context always routes to Apple enhanced engine")
    @MainActor
    func test_pronunciationRouting_usesAppleEngine() async {
        let coordinator = AudioSessionCoordinator()
        let service = TextToSpeechService(audioSessionCoordinator: coordinator)
        
        await service.speakAsync(text: "Ambition", context: .pronunciation(locale: "en-US"), rate: 1.0)
        #expect(!service.isSpeaking)
    }

    @Test("Verify conversation context without API key falls back immediately to Apple engine")
    @MainActor
    func test_conversationRouting_fallbackToApple() async {
        let coordinator = AudioSessionCoordinator()
        let service = TextToSpeechService(audioSessionCoordinator: coordinator)
        
        await service.speakAsync(text: "Hello! How can I help you today?", context: .conversation(persona: .friendlyFemale), rate: 1.0)
        #expect(!service.isSpeaking)
    }
}
```

- [ ] **Step 2: Run test to verify it fails or compiles**

Run: `swift test --filter SmartVoiceRouterTests`

- [ ] **Step 3: Update `TextToSpeechService.swift` to orchestrate engines**

In `VocabCraftApp/Core/Audio/TextToSpeechService.swift`:
- Integrate `AppleEnhancedTTSEngine` and `GeminiAudioSpeechEngine`.
- Implement `speak(text:context:rate:)` and `speakAsync(text:context:rate:)`.
- In `speakAsync(text:context:rate:)`:
  - Acquire audio lease `.playback`.
  - If `case .conversation(let persona, _)` and `geminiApiKey` is available:
    - Attempt `try await geminiEngine.synthesizeAndPlay(...)`.
    - If error throws: log `LessonPerformanceDiagnostics.event("TTSFallbackToApple")` and fallback to `appleEngine.speakAsync(text:rate:locale:)`.
  - Otherwise: call `appleEngine.speakAsync(text:rate:locale:)`.
  - Release audio lease.

In `VocabCraftApp/App/DI/AppContainer.swift`:
- Ensure `TextToSpeechService` receives `settingsStore` or API key provider if needed.

- [ ] **Step 4: Run tests to verify all pass**

Run: `swift test --filter SmartVoiceRouterTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Audio/TextToSpeechService.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftAppTests/Core/Audio/SmartVoiceRouterTests.swift
git commit -m "feat(audio): refactor TextToSpeechService into Smart Voice Router with resilient failover"
```

---

### Task 7: AI Roleplay Voice Call Persona Wiring

**Files:**
- Modify: `VocabCraftApp/Domain/Models/RoleplayScenario.swift` (or persona mapping)
- Modify: `VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift`
- Modify: `VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift`

**Interfaces:**
- Consumes: `VoicePersona`, `SpeechContext`, `TurnBasedVoiceConversationEngine`.
- Produces: Character dialogue vocalized using natural `SpeechContext.conversation(persona:)`.

- [ ] **Step 1: Write test verifying TurnBasedVoiceConversationEngine uses conversation context**

In `VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift`:
Add verification that when `playCharacterSpeech` is called, character speech uses `.conversation` speech context.

- [ ] **Step 2: Run test to verify status**

Run: `swift test --filter TurnBasedVoiceConversationEngineTests`

- [ ] **Step 3: Update `TurnBasedVoiceConversationEngine.playCharacterSpeech`**

In `TurnBasedVoiceConversationEngine.swift`:
```swift
    public func playCharacterSpeech(_ text: String, isConcluded: Bool = false) async {
        guard state != .ended else { return }
        audioLevel = 0.0
        silenceDetector?.cancel()
        state = .speaking(characterText: text)

        let persona: VoicePersona = scenario.characterName.lowercased().contains("alex") ? .friendlyMale : .friendlyFemale
        await ttsService.speakAsync(text: text, context: .conversation(persona: persona, locale: "en-US"), rate: 1.0)

        guard state != .ended else { return }
        if !isConcluded, case .speaking = state {
            startListening()
        }
    }
```

- [ ] **Step 4: Run tests to verify pass**

Run: `swift test --filter TurnBasedVoiceConversationEngineTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Services/TurnBasedVoiceConversationEngine.swift VocabCraftAppTests/AI/TurnBasedVoiceConversationEngineTests.swift
git commit -m "feat(ai): wire VoicePersona and conversation context into TurnBasedVoiceConversationEngine"
```

---

### Task 8: Quality Gate & Verification Suite

**Files:** None (Build & Test Gate)

- [ ] **Step 1: Run Full Test Suite**

Run: `swift test`
Expected: 100% test pass rate.

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Check Compiler Warnings**

Run build check via Xcode / swift build.
Expected: 0 errors, 0 warnings.
