import Foundation

/// Isolated file storage managing temporary audio capture and playback buffers for Guided Practice.
///
/// Guarantees that audio recordings are strictly confined to a dedicated practice directory,
/// and that cleanup operations never affect other app recordings or system caches.
public struct PracticePrivacyStore: Sendable {
    public let directory: URL

    public init(
        directory: URL = FileManager.default.temporaryDirectory.appendingPathComponent("GuidedPracticeAudio", isDirectory: true)
    ) {
        self.directory = directory
    }

    /// Computes the isolated temporary audio file URL for a given session and filename, ensuring the session directory exists.
    public func temporaryAudioURL(sessionId: UUID, filename: String) -> URL {
        let sessionDir = directory.appendingPathComponent(sessionId.uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)
        return sessionDir.appendingPathComponent(filename)
    }

    /// Removes all temporary audio files belonging exclusively to the specified practice session.
    public func removeTemporaryAudio(sessionId: UUID) throws {
        let sessionDir = directory.appendingPathComponent(sessionId.uuidString, isDirectory: true)
        if FileManager.default.fileExists(atPath: sessionDir.path) {
            try FileManager.default.removeItem(at: sessionDir)
        }
    }

    /// Removes all temporary audio files across all practice sessions, recreating the root practice directory empty.
    public func removeAllTemporaryAudio() throws {
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
