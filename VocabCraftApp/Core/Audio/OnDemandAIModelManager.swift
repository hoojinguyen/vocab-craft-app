import Foundation
import Observation
import os

public enum AIModelType: String, CaseIterable, Sendable {
    case kokoro
    case whisper

    public var displayName: String {
        switch self {
        case .kokoro: return "Kokoro Neural Voice"
        case .whisper: return "WhisperKit Speech Recognition"
        }
    }

    public var estimatedSizeMB: Int {
        switch self {
        case .kokoro: return 145
        case .whisper: return 48
        }
    }
}

public enum AIModelDownloadState: Sendable, Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case ready
    case error(String)
}

@MainActor
@Observable
public final class OnDemandAIModelManager: NSObject, URLSessionDownloadDelegate {
    nonisolated private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "AIModelManager")

    public static let shared = OnDemandAIModelManager()

    public private(set) var kokoroState: AIModelDownloadState = .notDownloaded
    public private(set) var whisperState: AIModelDownloadState = .notDownloaded

    @ObservationIgnored
    private let modelsDirectory: URL

    @ObservationIgnored
    private var downloadTasks: [AIModelType: URLSessionDownloadTask] = [:]

    @ObservationIgnored
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    public init(modelsDirectory: URL? = nil) {
        if let dir = modelsDirectory {
            self.modelsDirectory = dir
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.modelsDirectory = appSupport.appendingPathComponent("VocabCraft/AIModels", isDirectory: true)
        }
        super.init()
        createDirectoryAndExcludeFromBackup()
        refreshStatus()
    }

    private func createDirectoryAndExcludeFromBackup() {
        do {
            try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var targetUrl = modelsDirectory
            try targetUrl.setResourceValues(resourceValues)
        } catch {
            Self.logger.error("Failed to create models directory: \(error.localizedDescription)")
        }
    }

    public func state(for type: AIModelType) -> AIModelDownloadState {
        switch type {
        case .kokoro: return kokoroState
        case .whisper: return whisperState
        }
    }

    public func isModelReady(_ type: AIModelType) -> Bool {
        state(for: type) == .ready
    }

    public func modelURL(for type: AIModelType) -> URL {
        modelsDirectory.appendingPathComponent(type.rawValue, isDirectory: true)
    }

    public func refreshStatus() {
        for type in AIModelType.allCases {
            let dir = modelURL(for: type)
            if FileManager.default.fileExists(atPath: dir.path),
               let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path),
               !contents.isEmpty {
                updateState(.ready, for: type)
            } else {
                updateState(.notDownloaded, for: type)
            }
        }
    }

    public func deleteModel(_ type: AIModelType) throws {
        let dir = modelURL(for: type)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
        updateState(.notDownloaded, for: type)
        Self.logger.info("Deleted model: \(type.rawValue)")
    }

    public func startDownload(for type: AIModelType, remoteURL: URL) {
        guard state(for: type) != .ready else { return }
        updateState(.downloading(progress: 0.0), for: type)
        let task = urlSession.downloadTask(with: remoteURL)
        downloadTasks[type] = task
        task.resume()
    }

    private func updateState(_ newState: AIModelDownloadState, for type: AIModelType) {
        switch type {
        case .kokoro: kokoroState = newState
        case .whisper: whisperState = newState
        }
    }

    public nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0.0
        Task { @MainActor in
            for (type, task) in self.downloadTasks where task == downloadTask {
                self.updateState(.downloading(progress: progress), for: type)
            }
        }
    }

    public nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let tempUUID = UUID().uuidString
        let safeTempLocation = FileManager.default.temporaryDirectory.appendingPathComponent(tempUUID)

        do {
            try FileManager.default.moveItem(at: location, to: safeTempLocation)
        } catch {
            Self.logger.error("Failed to move downloaded file to safe temp location: \(error.localizedDescription)")
            return
        }

        Task { @MainActor in
            guard let (type, _) = self.downloadTasks.first(where: { $0.value == downloadTask }) else {
                try? FileManager.default.removeItem(at: safeTempLocation)
                return
            }
            let dest = self.modelURL(for: type)
            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                let targetFile = dest.appendingPathComponent("model_archive.bin")
                try FileManager.default.moveItem(at: safeTempLocation, to: targetFile)
                self.updateState(.ready, for: type)
                self.downloadTasks.removeValue(forKey: type)
            } catch {
                self.updateState(.error(error.localizedDescription), for: type)
                try? FileManager.default.removeItem(at: safeTempLocation)
            }
        }
    }
}
