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
        case .kokoro: return 85
        case .whisper: return 48
        }
    }

    public var defaultRemoteURL: URL {
        switch self {
        case .kokoro:
            return URL(string: "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-en-v0_19.tar.bz2")!
        case .whisper:
            return URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-tiny.en/whisperkit.zip")!
        }
    }

    public var remoteURL: URL {
        defaultRemoteURL
    }
}

public enum AIModelDownloadState: Sendable, Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case ready
    case error(String)
}

public enum AIModelExtractionError: LocalizedError, Sendable {
    case fileNotFound(URL)
    case extractionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "Archive file not found at: \(url.path)"
        case .extractionFailed(let message):
            return "Archive extraction failed: \(message)"
        }
    }
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
            Self.applyBackupExclusion(to: modelsDirectory)
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
        let dir = modelURL(for: type)
        switch type {
        case .kokoro:
            let requiredFiles = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
            let isComplete = requiredFiles.allSatisfy {
                FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path)
            }
            if isComplete {
                if kokoroState != .ready { updateState(.ready, for: .kokoro) }
                return true
            } else {
                if kokoroState == .ready { updateState(.notDownloaded, for: .kokoro) }
                return false
            }
        case .whisper:
            if FileManager.default.fileExists(atPath: dir.path),
               let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path),
               !contents.isEmpty {
                if whisperState != .ready { updateState(.ready, for: .whisper) }
                return true
            } else {
                if whisperState == .ready { updateState(.notDownloaded, for: .whisper) }
                return false
            }
        }
    }

    public func modelURL(for type: AIModelType) -> URL {
        modelsDirectory.appendingPathComponent(type.rawValue, isDirectory: true)
    }

    public func refreshStatus() {
        for type in AIModelType.allCases {
            if isModelReady(type) {
                // isModelReady already called updateState(.ready, for: type) if complete
            } else {
                if case .downloading = state(for: type) {
                    // Retain downloading state
                } else {
                    updateState(.notDownloaded, for: type)
                }
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

    public func startDownload(for type: AIModelType, remoteURL: URL? = nil) {
        let targetURL = remoteURL ?? type.defaultRemoteURL
        guard state(for: type) != .ready else { return }
        updateState(.downloading(progress: 0.0), for: type)
        let task = urlSession.downloadTask(with: targetURL)
        downloadTasks[type] = task
        task.resume()
    }

    public nonisolated func extractArchive(at sourceURL: URL, to destinationURL: URL) throws {
        try Self.extractArchive(at: sourceURL, to: destinationURL)
    }

    public nonisolated static func extractArchive(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw AIModelExtractionError.fileNotFound(sourceURL)
        }

        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDir), isDir.boolValue {
            let items = try fileManager.contentsOfDirectory(atPath: sourceURL.path)
            for item in items {
                let srcItem = sourceURL.appendingPathComponent(item)
                let dstItem = destinationURL.appendingPathComponent(item)
                if fileManager.fileExists(atPath: dstItem.path) {
                    try fileManager.removeItem(at: dstItem)
                }
                try fileManager.copyItem(at: srcItem, to: dstItem)
            }
            applyBackupExclusion(to: destinationURL)
            return
        }

        let tempExtractDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempExtractDir, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: tempExtractDir)
        }

        try executeTarExtraction(from: sourceURL.path, to: tempExtractDir.path)

        let extractedItems = try fileManager.contentsOfDirectory(
            at: tempExtractDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        let contentsSourceDir: URL
        if extractedItems.count == 1,
           let first = extractedItems.first,
           (try? first.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            contentsSourceDir = first
        } else {
            contentsSourceDir = tempExtractDir
        }

        let itemsToMove = try fileManager.contentsOfDirectory(atPath: contentsSourceDir.path)
        for item in itemsToMove {
            let src = contentsSourceDir.appendingPathComponent(item)
            let dst = destinationURL.appendingPathComponent(item)
            if fileManager.fileExists(atPath: dst.path) {
                try fileManager.removeItem(at: dst)
            }
            try fileManager.moveItem(at: src, to: dst)
        }

        applyBackupExclusion(to: destinationURL)
    }

    private nonisolated static func executeTarExtraction(from sourcePath: String, to destinationPath: String) throws {
        var pid: pid_t = 0
        let args = ["/usr/bin/tar", "-xf", sourcePath, "-C", destinationPath]
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
            throw AIModelExtractionError.extractionFailed("posix_spawn failed with error code \(spawnStatus)")
        }

        var exitStatus: Int32 = 0
        waitpid(pid, &exitStatus, 0)
        let code = (exitStatus >> 8) & 0xff
        guard code == 0 else {
            throw AIModelExtractionError.extractionFailed("tar command failed with exit code \(code)")
        }
    }

    public nonisolated static func applyBackupExclusion(to url: URL) {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var targetUrl = url
        try? targetUrl.setResourceValues(resourceValues)
    }

    private func updateState(_ newState: AIModelDownloadState, for type: AIModelType) {
        switch type {
        case .kokoro: kokoroState = newState
        case .whisper: whisperState = newState
        }
        NotificationCenter.default.post(name: .onDemandAIModelStatusDidChange, object: nil)
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

        Task {
            let (targetType, destURL) = await MainActor.run { () -> (AIModelType?, URL?) in
                guard let (type, _) = self.downloadTasks.first(where: { $0.value == downloadTask }) else {
                    return (nil, nil)
                }
                return (type, self.modelURL(for: type))
            }

            guard let type = targetType, let dest = destURL else {
                try? FileManager.default.removeItem(at: safeTempLocation)
                return
            }

            defer {
                Task { @MainActor in
                    self.downloadTasks.removeValue(forKey: type)
                }
            }

            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                try Self.extractArchive(at: safeTempLocation, to: dest)
                try? FileManager.default.removeItem(at: safeTempLocation)

                Self.applyBackupExclusion(to: dest)

                await MainActor.run {
                    if self.isModelReady(type) {
                        self.updateState(.ready, for: type)
                    } else {
                        self.updateState(.error("Model integrity check failed after extraction"), for: type)
                    }
                }
            } catch {
                try? FileManager.default.removeItem(at: safeTempLocation)
                await MainActor.run {
                    self.updateState(.error(error.localizedDescription), for: type)
                }
            }
        }
    }

    public nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error = error else { return }
        Task { @MainActor in
            guard let (type, _) = self.downloadTasks.first(where: { $0.value == task }) else {
                return
            }
            self.downloadTasks.removeValue(forKey: type)
            self.updateState(.error(error.localizedDescription), for: type)
            Self.logger.error("Download failed for \(type.rawValue): \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    public static let onDemandAIModelStatusDidChange = Notification.Name("OnDemandAIModelStatusDidChangeNotification")
}
