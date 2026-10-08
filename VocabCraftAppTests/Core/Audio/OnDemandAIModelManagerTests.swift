import Foundation
import Testing
@testable import VocabCraftApp

@Suite("OnDemandAIModelManager Tests")
struct OnDemandAIModelManagerTests {
    @Test("Model manager tracks initial state as notDownloaded")
    @MainActor
    func testInitialState() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)

        #expect(manager.state(for: .kokoro) == .notDownloaded)
        #expect(manager.state(for: .whisper) == .notDownloaded)
    }

    @Test("isModelReady returns false when required Kokoro files are missing")
    @MainActor
    func testModelNotReadyWhenFilesMissing() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(!manager.isModelReady(.kokoro))
    }

    @Test("isModelReady returns false when Kokoro files are incomplete")
    @MainActor
    func testModelNotReadyWhenFilesIncomplete() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        try FileManager.default.createDirectory(at: kokoroDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Only 1 out of 4 files exists
        let path = kokoroDir.appendingPathComponent("model.onnx")
        try "dummy".write(to: path, atomically: true, encoding: .utf8)

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(!manager.isModelReady(.kokoro))
    }

    @Test("isModelReady returns true only when all 4 Kokoro files exist")
    @MainActor
    func testModelReadyWhenAllFilesExist() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        try FileManager.default.createDirectory(at: kokoroDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let required = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
        for file in required {
            let path = kokoroDir.appendingPathComponent(file)
            if file == "espeak-ng-data" {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            } else {
                try "dummy".write(to: path, atomically: true, encoding: .utf8)
            }
        }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(manager.isModelReady(.kokoro))
    }

    @Test("extractArchive unpacks files from directory and sets backup exclusion")
    @MainActor
    func testExtractArchiveFromDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let srcDir = tempDir.appendingPathComponent("src")
        let destDir = tempDir.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let testFile = srcDir.appendingPathComponent("model.onnx")
        try "sample-onnx-content".write(to: testFile, atomically: true, encoding: .utf8)

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        try manager.extractArchive(at: srcDir, to: destDir)

        let extractedFile = destDir.appendingPathComponent("model.onnx")
        #expect(FileManager.default.fileExists(atPath: extractedFile.path))

        let values = try destDir.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test("Kokoro model type has expected remote URL and estimated size")
    func testKokoroModelTypeMetadata() {
        let type = AIModelType.kokoro
        #expect(type.estimatedSizeMB == 85)
        #expect(type.defaultRemoteURL.absoluteString.contains("kokoro-en-v0_19"))
        #expect(type.remoteURL == type.defaultRemoteURL)
    }

    @Test("Model manager deletes model directory and resets state")
    @MainActor
    func testDeleteModel() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let whisperDir = tempDir.appendingPathComponent("whisper")
        try FileManager.default.createDirectory(at: whisperDir, withIntermediateDirectories: true)
        let dummy = whisperDir.appendingPathComponent("weights.bin")
        try Data("weights".utf8).write(to: dummy)

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        manager.refreshStatus()
        #expect(manager.state(for: .whisper) == .ready)

        try manager.deleteModel(.whisper)
        #expect(manager.state(for: .whisper) == .notDownloaded)
        #expect(!manager.isModelReady(.whisper))
    }
}
