import Darwin
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

    @Test("extractArchive unpacks valid tar archive and validates model readiness")
    @MainActor
    func testExtractArchiveTarArchive() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let srcDir = tempDir.appendingPathComponent("raw_files")
        let tarFile = tempDir.appendingPathComponent("kokoro.tar")
        let destDir = tempDir.appendingPathComponent("kokoro")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let required = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
        for file in required {
            let path = srcDir.appendingPathComponent(file)
            if file == "espeak-ng-data" {
                try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                let sampleDict = path.appendingPathComponent("dict")
                try "sample-phonemes".write(to: sampleDict, atomically: true, encoding: .utf8)
            } else {
                try "dummy-content".write(to: path, atomically: true, encoding: .utf8)
            }
        }

        try createTarArchive(from: srcDir, archiveURL: tarFile)
        #expect(FileManager.default.fileExists(atPath: tarFile.path))

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        try manager.extractArchive(at: tarFile, to: destDir)

        #expect(manager.isModelReady(.kokoro))
        let values = try destDir.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test("extractArchive throws when archive is corrupt or invalid")
    @MainActor
    func testExtractArchiveThrowsOnCorruptArchive() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let corruptFile = tempDir.appendingPathComponent("invalid.tar.bz2")
        let destDir = tempDir.appendingPathComponent("dest")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "not a valid tar or bz2 archive".write(to: corruptFile, atomically: true, encoding: .utf8)

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(throws: Error.self) {
            try manager.extractArchive(at: corruptFile, to: destDir)
        }
    }

    @Test("extractArchive throws when source file does not exist")
    @MainActor
    func testExtractArchiveThrowsWhenSourceNotFound() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nonExistentFile = tempDir.appendingPathComponent("missing.tar.bz2")
        let destDir = tempDir.appendingPathComponent("dest")

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(throws: Error.self) {
            try manager.extractArchive(at: nonExistentFile, to: destDir)
        }
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

    private func createTarArchive(from sourceDir: URL, archiveURL: URL) throws {
        var pid: pid_t = 0
        let args = ["/usr/bin/tar", "-cf", archiveURL.path, "-C", sourceDir.path, "."]
        var cArgs = args.map { strdup($0) }
        cArgs.append(nil)
        defer {
            for ptr in cArgs where ptr != nil {
                free(ptr)
            }
        }

        let spawnStatus = cArgs.withUnsafeMutableBufferPointer { buffer in
            posix_spawn(&pid, "/usr/bin/tar", nil, nil, buffer.baseAddress, nil)
        }
        guard spawnStatus == 0 else {
            throw NSError(domain: "TarTest", code: Int(spawnStatus))
        }

        var exitStatus: Int32 = 0
        waitpid(pid, &exitStatus, 0)
        let code = (exitStatus >> 8) & 0xff
        guard code == 0 else {
            throw NSError(domain: "TarTest", code: Int(code))
        }
    }

    @Test("Llama model type configuration, directory URL, and size check")
    @MainActor
    func testLlamaModelConfiguration() {
        let manager = OnDemandAIModelManager.shared
        #expect(AIModelType.llama.rawValue == "llama")
        #expect(AIModelType.llama.displayName == "Llama 3.2 1B Neural LLM")
        #expect(AIModelType.llama.sizeMB == 740)
        let url = manager.modelURL(for: .llama)
        #expect(url.lastPathComponent == "llama")
    }

    @Test("Unified full offline pack readiness and progress")
    @MainActor
    func testFullOfflinePackReadinessAndProgress() {
        let manager = OnDemandAIModelManager.shared
        // Initially not ready if files don't exist
        #expect(!manager.isFullOfflinePackReady() || manager.isModelReady(.llama))
        #expect(manager.fullOfflinePackProgress >= 0.0 && manager.fullOfflinePackProgress <= 1.0)
    }

    @Test("Llama model readiness strictly enforces >700MB file size threshold")
    @MainActor
    func testLlamaModelReadinessWithFileSizeThreshold() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let llamaDir = tempDir.appendingPathComponent("llama")
        try FileManager.default.createDirectory(at: llamaDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)

        // 1. Missing model.gguf
        #expect(!manager.isModelReady(.llama))

        // 2. Truncated model.gguf (< 700MB)
        let modelFile = llamaDir.appendingPathComponent("model.gguf")
        try "dummy-small-content".write(to: modelFile, atomically: true, encoding: .utf8)
        #expect(!manager.isModelReady(.llama))

        // 3. Exactly 700MB or less (699MB)
        let handle = try FileHandle(forWritingTo: modelFile)
        try handle.truncate(atOffset: UInt64(699 * 1024 * 1024))
        try handle.close()
        #expect(!manager.isModelReady(.llama))

        // 4. Valid model.gguf (> 700MB, e.g. 740MB)
        let validHandle = try FileHandle(forWritingTo: modelFile)
        try validHandle.truncate(atOffset: UInt64(740 * 1024 * 1024))
        try validHandle.close()
        #expect(manager.isModelReady(.llama))
        #expect(manager.state(for: .llama) == .ready)
    }

    @Test("Unified pack coordinator handles lifecycle methods cleanly")
    @MainActor
    func testUnifiedPackCoordinatorLifecycle() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(!manager.isFullOfflinePackReady())
        #expect(manager.fullOfflinePackState == .notDownloaded)

        // Cancellation on idle does not crash
        manager.cancelFullOfflinePackDownload()
        #expect(manager.fullOfflinePackState == .notDownloaded)

        // Deletion cleans all directories
        manager.deleteFullOfflinePack()
        #expect(manager.fullOfflinePackState == .notDownloaded)
    }

    @Test("In-process archive extractor extracts tar and tar.bz2 without posix_spawn")
    func testInProcessArchiveExtraction() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let destDir = tempDir.appendingPathComponent("extracted")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Test directory extraction
        let sourceDir = tempDir.appendingPathComponent("source")
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        let fileA = sourceDir.appendingPathComponent("model.onnx")
        try "dummy-model".write(to: fileA, atomically: true, encoding: .utf8)

        try OnDemandAIModelManager.extractArchive(at: sourceDir, to: destDir)
        #expect(FileManager.default.fileExists(atPath: destDir.appendingPathComponent("model.onnx").path))

        // Test tar.bz2 extraction
        let bz2Archive = tempDir.appendingPathComponent("model.tar.bz2")
        let bz2Dest = tempDir.appendingPathComponent("extracted_bz2")
        try createTarBz2Archive(from: sourceDir, archiveURL: bz2Archive)
        #expect(FileManager.default.fileExists(atPath: bz2Archive.path))

        try OnDemandAIModelManager.extractArchive(at: bz2Archive, to: bz2Dest)
        #expect(FileManager.default.fileExists(atPath: bz2Dest.appendingPathComponent("model.onnx").path))
    }

    @Test("Auto-flattening of nested kokoro directory")
    @MainActor
    func testKokoroAutoFlattening() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        let nestedDir = kokoroDir.appendingPathComponent("kokoro-en-v0_19")
        try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "dummy".write(to: nestedDir.appendingPathComponent("model.onnx"), atomically: true, encoding: .utf8)
        try "dummy".write(to: nestedDir.appendingPathComponent("voices.bin"), atomically: true, encoding: .utf8)
        try "dummy".write(to: nestedDir.appendingPathComponent("tokens.txt"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: nestedDir.appendingPathComponent("espeak-ng-data"), withIntermediateDirectories: true)

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        #expect(manager.isModelReady(.kokoro))
        #expect(FileManager.default.fileExists(atPath: kokoroDir.appendingPathComponent("model.onnx").path))
    }

    @Test("Remaining offline pack size computation")
    @MainActor
    func testRemainingOfflinePackSize() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let manager = OnDemandAIModelManager(modelsDirectory: tempDir)
        let totalSize = AIModelType.kokoro.sizeMB + AIModelType.whisper.sizeMB + AIModelType.llama.sizeMB
        #expect(manager.remainingOfflinePackSizeMB == totalSize)

        // Make kokoro ready
        let kokoroDir = tempDir.appendingPathComponent("kokoro")
        try FileManager.default.createDirectory(at: kokoroDir, withIntermediateDirectories: true)
        for file in ["model.onnx", "voices.bin", "tokens.txt"] {
            try "dummy".write(to: kokoroDir.appendingPathComponent(file), atomically: true, encoding: .utf8)
        }
        try FileManager.default.createDirectory(at: kokoroDir.appendingPathComponent("espeak-ng-data"), withIntermediateDirectories: true)

        #expect(manager.isModelReady(.kokoro))
        #expect(manager.remainingOfflinePackSizeMB == totalSize - AIModelType.kokoro.sizeMB)
    }

    private func createTarBz2Archive(from sourceDir: URL, archiveURL: URL) throws {
        var pid: pid_t = 0
        let args = ["/usr/bin/tar", "-cjf", archiveURL.path, "-C", sourceDir.path, "."]
        var cArgs = args.map { strdup($0) }
        cArgs.append(nil)
        defer {
            for ptr in cArgs where ptr != nil {
                free(ptr)
            }
        }

        let spawnStatus = cArgs.withUnsafeMutableBufferPointer { buffer in
            posix_spawn(&pid, "/usr/bin/tar", nil, nil, buffer.baseAddress, nil)
        }
        guard spawnStatus == 0 else {
            throw NSError(domain: "TarBz2Test", code: Int(spawnStatus))
        }

        var exitStatus: Int32 = 0
        waitpid(pid, &exitStatus, 0)
        let code = (exitStatus >> 8) & 0xff
        guard code == 0 else {
            throw NSError(domain: "TarBz2Test", code: Int(code))
        }
    }
}
