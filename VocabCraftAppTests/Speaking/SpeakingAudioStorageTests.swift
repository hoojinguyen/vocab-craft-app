import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking audio storage")
struct SpeakingAudioStorageTests {
    @Test func deletesOnlyNamedFilesInsideConfiguredDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("speaking-storage-\(UUID().uuidString)", isDirectory: true)
        let directory = root.appendingPathComponent("audio", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let storage = SpeakingAudioStorage(directory: directory)
        let first = storage.url(for: "first.m4a")
        let second = storage.url(for: "second.m4a")
        let outside = root.appendingPathComponent("outside.m4a")
        try Data([1]).write(to: first)
        try Data([2]).write(to: second)
        try Data([3]).write(to: outside)

        storage.delete(fileNames: ["first.m4a", "../outside.m4a", outside.path])

        #expect(!FileManager.default.fileExists(atPath: first.path))
        #expect(FileManager.default.fileExists(atPath: second.path))
        #expect(FileManager.default.fileExists(atPath: outside.path))
    }

    @Test func resolvesOnlyLeafFileNamesInsideConfiguredDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("speaking-storage-\(UUID().uuidString)", isDirectory: true)
        let storage = SpeakingAudioStorage(directory: directory)

        #expect(storage.url(for: "session.m4a").deletingLastPathComponent() == directory)
        #expect(storage.url(for: "../outside.m4a").standardizedFileURL == directory.standardizedFileURL)
        #expect(storage.url(for: "session.m4a").lastPathComponent == "session.m4a")
    }

    @Test func defaultsToDedicatedApplicationSupportDirectory() throws {
        let storage = try SpeakingAudioStorage()

        #expect(storage.url(for: "session.m4a").pathComponents.suffix(3) == ["VocabCraft", "SpeakingAudio", "session.m4a"])
    }
}
