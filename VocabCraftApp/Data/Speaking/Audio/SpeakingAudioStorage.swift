import Foundation

/// Resolves and removes audio files within one dedicated directory.
public struct SpeakingAudioStorage: Sendable {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory.standardizedFileURL
    }

    public init() throws {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        self.init(directory: applicationSupport
            .appendingPathComponent("VocabCraft", isDirectory: true)
            .appendingPathComponent("SpeakingAudio", isDirectory: true))
    }

    public func url(for fileName: String) -> URL {
        guard Self.isLeafFileName(fileName) else { return directory }
        let resolved = directory.appendingPathComponent(fileName, isDirectory: false).standardizedFileURL
        guard resolved.deletingLastPathComponent() == directory else { return directory }
        return resolved
    }

    public func delete(fileNames: [String]) {
        for fileName in fileNames {
            let fileURL = url(for: fileName)
            guard fileURL != directory else { continue }
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    func createDirectoryIfNeeded() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private static func isLeafFileName(_ fileName: String) -> Bool {
        guard !fileName.isEmpty, fileName != ".", fileName != "..",
              !fileName.contains("/"), !fileName.contains("\\"),
              !fileName.hasPrefix("/")
        else {
            return false
        }
        return true
    }
}
