# Sherpa-ONNX Kokoro Neural TTS Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the official `sherpa-onnx` on-device C++ ONNX runtime via `Packages/SpeechKit` to synthesize real, 24kHz human speech for Kokoro-82M neural voices (Nova, Orion, Sarah, Michael), completely replacing placeholder tone beeps.

**Architecture:** Embed `sherpa-onnx` SPM dependency (`1.13.8`) into the existing local package `Packages/SpeechKit`. Expose `SherpaKokoroTTSWrapper` conforming to `SherpaOnnxOfflineTtsWrapper`. Wire the wrapper into `KokoroInferenceWorker` inside `VocabCraftApp`, loading model weights lazily from `Application Support/VocabCraft/AIModels/kokoro` and offloading inference to background threads.

**Tech Stack:** Swift 6, `sherpa-onnx` Swift API, `SherpaOnnxIOS.xcframework`, `onnxruntime-ios.xcframework`, AVFoundation (`AVAudioPlayer`), XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-10-09-sherpa-onnx-kokoro-integration-design.md`

## Global Constraints

- Zero Silent Fallbacks: If model files are missing, fail fast with typed `AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~85MB")`.
- Zero Tone Beeping: In production, audio generation must never produce synthetic sine-wave beeps.
- Concurrency & Thread Safety: `KokoroInferenceWorker` must remain a background `actor`. ONNX inference must never block `@MainActor`.
- Storage Governance: Model directory is `Application Support/VocabCraft/AIModels/kokoro/` with `.isExcludedFromBackup = true`.
- Quality Gates: Zero compiler warnings, 0 SwiftLint violations across all files, 100% test pass rate.

---

### Task 1: Add `sherpa-onnx` Dependency & Implement `SherpaKokoroTTSWrapper` in `SpeechKit`

**Files:**
- Modify: `Packages/SpeechKit/Package.swift`
- Create: `Packages/SpeechKit/Sources/SpeechKit/Engine/SherpaKokoroTTSWrapper.swift`
- Test: `Packages/SpeechKit/Tests/SpeechKitTests/SherpaKokoroTTSWrapperTests.swift`

**Interfaces:**
- Consumes: `sherpa-onnx` Swift library (`SherpaOnnxOfflineTtsWrapper`, `sherpaOnnxOfflineTtsKokoroModelConfig`, `sherpaOnnxOfflineTtsModelConfig`, `sherpaOnnxOfflineTtsConfig`).
- Produces: `SherpaKokoroTTSWrapper: Sendable`, exposing:
  - `public init()`
  - `public func initialize(modelDirectory: URL) throws`
  - `public func generate(text: String, speakerId: Int, speed: Float) throws -> [Float]`
  - `public func unload()`
  - `public var isInitialized: Bool { get }`

- [ ] **Step 1: Update `Packages/SpeechKit/Package.swift` with `sherpa-onnx` dependency**

In `Packages/SpeechKit/Package.swift`:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeechKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SpeechKit",
            targets: ["SpeechKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/k2-fsa/sherpa-onnx", exact: "1.13.8")
    ],
    targets: [
        .target(
            name: "SpeechKit",
            dependencies: [
                .product(name: "sherpa-onnx", package: "sherpa-onnx")
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .testTarget(
            name: "SpeechKitTests",
            dependencies: ["SpeechKit"]
        )
    ]
)
```

- [ ] **Step 2: Write failing unit test in `SpeechKitTests`**

Create `Packages/SpeechKit/Tests/SpeechKitTests/SherpaKokoroTTSWrapperTests.swift`:
```swift
import Foundation
import Testing
@testable import SpeechKit

@Suite("SherpaKokoroTTSWrapper Tests")
struct SherpaKokoroTTSWrapperTests {
    @Test("Wrapper throws error when model directory is invalid or files are missing")
    func testInitializationThrowsOnMissingFiles() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let wrapper = SherpaKokoroTTSWrapper()

        #expect(!wrapper.isInitialized)
        #expect(throws: Error.self) {
            try wrapper.initialize(modelDirectory: tempDir)
        }
        #expect(!wrapper.isInitialized)
    }

    @Test("Wrapper generates audio when initialized with valid mock or handles empty text cleanly")
    func testEmptyTextGeneration() throws {
        let wrapper = SherpaKokoroTTSWrapper()
        let samples = try wrapper.generate(text: "", speakerId: 0, speed: 1.0)
        #expect(samples.isEmpty)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test --package-path Packages/SpeechKit --filter SherpaKokoroTTSWrapperTests`
Expected: FAIL (Cannot find `SherpaKokoroTTSWrapper` in scope).

- [ ] **Step 4: Implement `SherpaKokoroTTSWrapper`**

Create `Packages/SpeechKit/Sources/SpeechKit/Engine/SherpaKokoroTTSWrapper.swift`:
```swift
import Foundation
import os
import SherpaOnnx

public enum SherpaKokoroError: LocalizedError, Sendable {
    case missingRequiredFiles(String)
    case engineCreationFailed(String)
    case notInitialized
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredFiles(let detail):
            return "Kokoro model files are missing or incomplete: \(detail)"
        case .engineCreationFailed(let detail):
            return "Failed to initialize Sherpa-ONNX TTS engine: \(detail)"
        case .notInitialized:
            return "Sherpa-ONNX TTS engine is not initialized."
        case .generationFailed(let detail):
            return "Sherpa-ONNX speech synthesis failed: \(detail)"
        }
    }
}

public final class SherpaKokoroTTSWrapper: @unchecked Sendable {
    private static let logger = Logger(subsystem: "com.hoojinguyen.vocabcraft.speechkit", category: "SherpaKokoroTTS")

    private var tts: SherpaOnnxOfflineTtsWrapper?
    private let lock = NSLock()

    public init() {}

    public var isInitialized: Bool {
        lock.lock()
        defer { lock.unlock() }
        return tts != nil
    }

    public func initialize(modelDirectory: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        if tts != nil { return }

        let modelPath = modelDirectory.appendingPathComponent("model.onnx").path
        let voicesPath = modelDirectory.appendingPathComponent("voices.bin").path
        let tokensPath = modelDirectory.appendingPathComponent("tokens.txt").path
        let dataDirPath = modelDirectory.appendingPathComponent("espeak-ng-data").path

        let fm = FileManager.default
        guard fm.fileExists(atPath: modelPath),
              fm.fileExists(atPath: voicesPath),
              fm.fileExists(atPath: tokensPath),
              fm.fileExists(atPath: dataDirPath) else {
            throw SherpaKokoroError.missingRequiredFiles(modelDirectory.path)
        }

        let kokoro = sherpaOnnxOfflineTtsKokoroModelConfig(
            model: modelPath,
            voices: voicesPath,
            tokens: tokensPath,
            dataDir: dataDirPath,
            lengthScale: 1.0,
            noiseScale: 0.667,
            noiseScaleW: 0.8
        )
        let modelConfig = sherpaOnnxOfflineTtsModelConfig(kokoro: kokoro, debug: 0)
        var ttsConfig = sherpaOnnxOfflineTtsConfig(model: modelConfig)

        let engine = SherpaOnnxOfflineTtsWrapper(config: &ttsConfig)
        guard engine.tts != nil else {
            throw SherpaKokoroError.engineCreationFailed("Failed to allocate SherpaOnnxOfflineTts engine")
        }

        self.tts = engine
        Self.logger.info("SherpaKokoroTTSWrapper initialized successfully at \(modelDirectory.path)")
    }

    public func generate(text: String, speakerId: Int = 0, speed: Float = 1.0) throws -> [Float] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        lock.lock()
        guard let engine = self.tts else {
            lock.unlock()
            throw SherpaKokoroError.notInitialized
        }
        lock.unlock()

        let audio = engine.generate(text: trimmed, sid: speakerId, speed: speed)
        guard audio.audio != nil else {
            throw SherpaKokoroError.generationFailed("No audio generated for text: \(trimmed)")
        }

        return audio.samples
    }

    public func unload() {
        lock.lock()
        defer { lock.unlock() }
        tts = nil
        Self.logger.info("SherpaKokoroTTSWrapper unloaded model memory")
    }
}
```

- [ ] **Step 5: Run tests in `SpeechKit` to verify they pass**

Run: `swift test --package-path Packages/SpeechKit`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Packages/SpeechKit/Package.swift Packages/SpeechKit/Sources/SpeechKit/Engine/SherpaKokoroTTSWrapper.swift Packages/SpeechKit/Tests/SpeechKitTests/SherpaKokoroTTSWrapperTests.swift
git commit -m "feat(audio): add sherpa-onnx dependency and SherpaKokoroTTSWrapper in SpeechKit"
```

---

### Task 2: Integrate `SherpaKokoroTTSWrapper` into `KokoroInferenceWorker`

**Files:**
- Modify: `VocabCraftApp/Core/Audio/KokoroInferenceWorker.swift`
- Modify: `VocabCraftAppTests/Core/Audio/KokoroTTSEngineTests.swift`

**Interfaces:**
- Consumes: `SpeechKit.SherpaKokoroTTSWrapper`
- Produces: `KokoroInferenceWorker` using `SherpaKokoroTTSWrapper` by default, generating real neural audio samples and eliminating placeholder tone beeps.

- [ ] **Step 1: Write test in `KokoroTTSEngineTests.swift` verifying real wrapper initialization**

In `VocabCraftAppTests/Core/Audio/KokoroTTSEngineTests.swift`, add:
```swift
@Test("KokoroInferenceWorker loads model and propagates errors cleanly")
func testWorkerLoadsModel() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let worker = KokoroInferenceWorker(modelDirectory: tempDir)
    #expect(!worker.isModelReady)

    await #expect(throws: AIPackError.self) {
        try await worker.loadModelIfNeeded()
    }
}
```

- [ ] **Step 2: Update `KokoroInferenceWorker.swift` to use `SherpaKokoroTTSWrapper`**

In `VocabCraftApp/Core/Audio/KokoroInferenceWorker.swift`:
1. `import SpeechKit`.
2. Update protocol conformance or adapt `SherpaKokoroTTSWrapper` to `SherpaOnnxOfflineTtsWrapper`:
```swift
public protocol SherpaOnnxOfflineTtsWrapper: Sendable {
    func initialize(modelDirectory: URL) throws
    func generate(text: String, speakerId: Int, speed: Float) throws -> [Float]
    func unload()
}

extension SherpaKokoroTTSWrapper: SherpaOnnxOfflineTtsWrapper {}
```
3. Update `init`:
```swift
    public init(
        modelDirectory: URL? = nil,
        ttsWrapper: (any SherpaOnnxOfflineTtsWrapper)? = nil
    ) {
        if let dir = modelDirectory {
            self.modelDirectory = dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.modelDirectory = appSupport.appendingPathComponent("VocabCraft/AIModels/kokoro", isDirectory: true)
        }
        self.ttsWrapper = ttsWrapper ?? SherpaKokoroTTSWrapper()
    }
```
4. Update `generateSamples`:
```swift
    public func generateSamples(text: String, speakerId: Int = 0, speed: Float = 1.0) throws -> [Float] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        try loadModelIfNeeded()

        if let wrapper = ttsWrapper {
            return try wrapper.generate(text: trimmed, speakerId: speakerId, speed: speed)
        }

        throw AIPackError.ttsFailed(packName: "Kokoro TTS", underlyingMessage: "No TTS wrapper available")
    }
```

- [ ] **Step 3: Run `KokoroTTSEngineTests` to verify pass**

Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/KokoroTTSEngineTests`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Core/Audio/KokoroInferenceWorker.swift VocabCraftAppTests/Core/Audio/KokoroTTSEngineTests.swift
git commit -m "feat(audio): connect SherpaKokoroTTSWrapper to KokoroInferenceWorker"
```

---

### Task 3: Full Verification, SwiftLint & Regression Testing

**Files:**
- Entire repository

- [ ] **Step 1: Run SwiftLint strict**
Run: `swiftlint lint --strict`
Expected: 0 violations across all files.

- [ ] **Step 2: Run all AI & SpeechKit test suites**
Run: `swift test --package-path Packages/SpeechKit`
Run: `xcodebuild test -project VocabCraftApp.xcodeproj -scheme VocabCraftApp -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:VocabCraftAppTests/OnDemandAIModelManagerTests -only-testing:VocabCraftAppTests/AIAssistantLocalizationTests -only-testing:VocabCraftAppTests/ConcreteAIPackTests -only-testing:VocabCraftAppTests/KokoroTTSEngineTests -only-testing:VocabCraftAppTests/LlamaInferenceWorkerTests`
Expected: 100% PASS.

- [ ] **Step 3: Run CraftUIKit tests**
Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% PASS.

- [ ] **Step 4: Verify git status**
Run: `git status`
Expected: Clean working tree.
