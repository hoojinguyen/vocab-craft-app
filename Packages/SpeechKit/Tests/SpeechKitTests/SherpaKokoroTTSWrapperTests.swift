import Foundation
@testable import SpeechKit
import Testing

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

    @Test("Wrapper handles empty text cleanly without requiring initialization")
    func testEmptyTextGeneration() throws {
        let wrapper = SherpaKokoroTTSWrapper()
        let samples = try wrapper.generate(text: "", speakerId: 0, speed: 1.0)
        #expect(samples.isEmpty)
    }

    @Test("Wrapper throws notInitialized when generating non-empty text without initialization")
    func testGenerationThrowsWhenNotInitialized() {
        let wrapper = SherpaKokoroTTSWrapper()
        #expect(throws: SherpaKokoroError.self) {
            _ = try wrapper.generate(text: "Hello world", speakerId: 0, speed: 1.0)
        }
    }

    @Test("Wrapper unload resets state safely")
    func testUnload() {
        let wrapper = SherpaKokoroTTSWrapper()
        #expect(!wrapper.isInitialized)
        wrapper.unload()
        #expect(!wrapper.isInitialized)
    }
}
