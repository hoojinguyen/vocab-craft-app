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

    @Test("Model manager correctly detects existing files as ready")
    @MainActor
    func testExistingModelReady() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        try FileManager.default.createDirectory(at: kokoroDir, withIntermediateDirectories: true)
        let dummyWeight = kokoroDir.appendingPathComponent("model.bin")
        try Data("dummy_weights".utf8).write(to: dummyWeight)

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        manager.refreshStatus()

        #expect(manager.state(for: .kokoro) == .ready)
        #expect(manager.isModelReady(.kokoro))
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
