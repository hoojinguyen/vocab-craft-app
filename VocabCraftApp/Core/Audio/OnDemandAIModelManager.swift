import Darwin
import Foundation
import Observation
import os

public enum AIModelType: String, CaseIterable, Sendable {
    case kokoro
    case whisper
    case llama

    public var displayName: String {
        switch self {
        case .kokoro: "Kokoro Neural Voice"
        case .whisper: "WhisperKit Speech Recognition"
        case .llama: "Llama 3.2 1B Neural LLM"
        }
    }

    public var sizeMB: Int {
        switch self {
        case .kokoro: 85
        case .whisper: 48
        case .llama: 740
        }
    }

    public var estimatedSizeMB: Int { sizeMB }

    public var defaultRemoteURL: URL {
        switch self {
        case .kokoro: URL(string: "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-en-v0_19.tar.bz2")!
        case .whisper: URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-tiny.en/whisperkit.zip")!
        case .llama: URL(string: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf")!
        }
    }

    public var remoteURL: URL { defaultRemoteURL }
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
        case .fileNotFound(let url): "Archive file not found at: \(url.path)"
        case .extractionFailed(let message): "Archive extraction failed: \(message)"
        }
    }
}

@MainActor
@Observable
public final class OnDemandAIModelManager: NSObject {
    nonisolated private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "AIModelManager")

    public static let shared = OnDemandAIModelManager()

    public private(set) var kokoroState: AIModelDownloadState = .notDownloaded
    public private(set) var whisperState: AIModelDownloadState = .notDownloaded
    public private(set) var llamaState: AIModelDownloadState = .notDownloaded

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
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
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
        case .kokoro: kokoroState
        case .whisper: whisperState
        case .llama: llamaState
        }
    }

    public func isModelReady(_ type: AIModelType) -> Bool {
        let dir = modelURL(for: type)
        switch type {
        case .kokoro:
            let requiredFiles = ["model.onnx", "voices.bin", "tokens.txt", "espeak-ng-data"]
            var isComplete = requiredFiles.allSatisfy { FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path) }
            if !isComplete, FileManager.default.fileExists(atPath: dir.path) {
                if let subItems = try? FileManager.default.contentsOfDirectory(
                    at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
                ) {
                    for subItem in subItems {
                        var isSubDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: subItem.path, isDirectory: &isSubDir), isSubDir.boolValue {
                            let subHasAll = requiredFiles.allSatisfy {
                                FileManager.default.fileExists(atPath: subItem.appendingPathComponent($0).path)
                            }
                            if subHasAll {
                                Self.flattenDirectory(from: subItem, to: dir)
                                break
                            }
                        }
                    }
                }
                isComplete = requiredFiles.allSatisfy { FileManager.default.fileExists(atPath: dir.appendingPathComponent($0).path) }
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
        case .llama:
            let modelFile = dir.appendingPathComponent("model.gguf")
            let minSizeBytes: Int64 = 700 * 1024 * 1024
            if FileManager.default.fileExists(atPath: modelFile.path),
               let attributes = try? FileManager.default.attributesOfItem(atPath: modelFile.path),
               let fileSize = attributes[.size] as? Int64,
               fileSize > minSizeBytes {
                if llamaState != .ready { updateState(.ready, for: .llama) }
                return true
            } else {
                if llamaState == .ready { updateState(.notDownloaded, for: .llama) }
                return false
            }
        }
    }

    public func modelURL(for type: AIModelType) -> URL {
        modelsDirectory.appendingPathComponent(type.rawValue, isDirectory: true)
    }

    public func refreshStatus() {
        for type in AIModelType.allCases where !isModelReady(type) {
            if case .downloading = state(for: type) {
                // Retain downloading state
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

    public func startDownload(for type: AIModelType, remoteURL: URL? = nil) {
        let targetURL = remoteURL ?? type.defaultRemoteURL
        guard !isModelReady(type) else { return }
        downloadTasks[type]?.cancel()
        updateState(.downloading(progress: 0.0), for: type)
        let task = urlSession.downloadTask(with: targetURL)
        downloadTasks[type] = task
        task.resume()
    }

    private func updateState(_ newState: AIModelDownloadState, for type: AIModelType) {
        switch type {
        case .kokoro: kokoroState = newState
        case .whisper: whisperState = newState
        case .llama: llamaState = newState
        }
        NotificationCenter.default.post(name: .onDemandAIModelStatusDidChange, object: nil)
    }

    // MARK: - Unified Full Offline Pack Coordinator

    public var fullOfflinePackProgress: Double {
        let weights: [AIModelType: Double] = [.kokoro: 0.09, .whisper: 0.15, .llama: 0.76]
        return AIModelType.allCases.reduce(0.0) { sum, type in
            let progress: Double
            if isModelReady(type) {
                progress = 1.0
            } else if case .downloading(let downloadProgress) = state(for: type) {
                progress = max(0.0, min(1.0, downloadProgress))
            } else {
                progress = 0.0
            }
            return sum + progress * (weights[type] ?? 0.0)
        }
    }

    public var fullOfflinePackState: AIModelDownloadState {
        if isFullOfflinePackReady() { return .ready }
        let states = [kokoroState, whisperState, llamaState]
        if states.contains(where: { if case .downloading = $0 { return true }; return false }) {
            return .downloading(progress: fullOfflinePackProgress)
        }
        if let errorState = states.first(where: { if case .error = $0 { return true }; return false }) {
            return errorState
        }
        return .notDownloaded
    }

    public var remainingOfflinePackSizeMB: Int {
        AIModelType.allCases.filter { !isModelReady($0) }.reduce(0) { $0 + $1.sizeMB }
    }

    public func isFullOfflinePackReady() -> Bool {
        isModelReady(.kokoro) && isModelReady(.whisper) && isModelReady(.llama)
    }

    public func startFullOfflinePackDownload() {
        for type in AIModelType.allCases where !isModelReady(type) {
            if case .downloading = state(for: type) { continue }
            startDownload(for: type)
        }
    }

    public func cancelDownload(for type: AIModelType) {
        downloadTasks.removeValue(forKey: type)?.cancel()
        if case .downloading = state(for: type) { updateState(.notDownloaded, for: type) }
    }

    public func cancelFullOfflinePackDownload() {
        AIModelType.allCases.forEach { cancelDownload(for: $0) }
    }

    public func deleteFullOfflinePack() {
        cancelFullOfflinePackDownload()
        for type in AIModelType.allCases {
            do {
                try deleteModel(type)
            } catch {
                Self.logger.error("Failed to delete model \(type.rawValue): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension OnDemandAIModelManager: URLSessionDownloadDelegate {
    public nonisolated func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
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
        _ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL
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
                guard let (type, _) = self.downloadTasks.first(where: { $0.value == downloadTask }) else { return (nil, nil) }
                return (type, self.modelURL(for: type))
            }
            guard let type = targetType, let dest = destURL else {
                try? FileManager.default.removeItem(at: safeTempLocation)
                return
            }
            defer { Task { @MainActor in self.downloadTasks.removeValue(forKey: type) } }

            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                if type == .llama {
                    let targetModelFile = dest.appendingPathComponent("model.gguf")
                    let nestedModel = safeTempLocation.appendingPathComponent("model.gguf")
                    let srcFile = FileManager.default.fileExists(atPath: nestedModel.path) ? nestedModel : safeTempLocation
                    try FileManager.default.moveItem(at: srcFile, to: targetModelFile)
                } else {
                    try Self.extractArchive(at: safeTempLocation, to: dest)
                }
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
                await MainActor.run { self.updateState(.error(error.localizedDescription), for: type) }
            }
        }
    }

    public nonisolated func urlSession(
        _ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?
    ) {
        guard let error = error else { return }
        Task { @MainActor in
            guard let (type, _) = self.downloadTasks.first(where: { $0.value == task }) else { return }
            self.downloadTasks.removeValue(forKey: type)
            self.updateState(.error(error.localizedDescription), for: type)
            Self.logger.error("Download failed for \(type.rawValue): \(error.localizedDescription)")
        }
    }
}

// MARK: - Archive Extraction & Decompression

extension OnDemandAIModelManager {
    public nonisolated func extractArchive(at sourceURL: URL, to destinationURL: URL) throws {
        try Self.extractArchive(at: sourceURL, to: destinationURL)
    }

    public nonisolated static func extractArchive(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sourceURL.path) else { throw AIModelExtractionError.fileNotFound(sourceURL) }
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDir), isDir.boolValue {
            let subItems = try fileManager.contentsOfDirectory(
                at: sourceURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
            )
            let sourceDir = (subItems.count == 1 && (try? subItems.first?.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true)
                ? (subItems.first ?? sourceURL) : sourceURL
            let items = try fileManager.contentsOfDirectory(atPath: sourceDir.path)
            for item in items {
                let srcItem = sourceDir.appendingPathComponent(item)
                let dstItem = destinationURL.appendingPathComponent(item)
                if fileManager.fileExists(atPath: dstItem.path) { try fileManager.removeItem(at: dstItem) }
                try fileManager.copyItem(at: srcItem, to: dstItem)
            }
            applyBackupExclusion(to: destinationURL)
            return
        }

        let tempExtractDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempExtractDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempExtractDir) }

        try executeInProcessTarExtraction(from: sourceURL, to: tempExtractDir)

        let extractedItems = try fileManager.contentsOfDirectory(
            at: tempExtractDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        )
        let contentsSourceDir = (extractedItems.count == 1 && (try? extractedItems.first?.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true)
            ? (extractedItems.first ?? tempExtractDir) : tempExtractDir

        let itemsToMove = try fileManager.contentsOfDirectory(atPath: contentsSourceDir.path)
        for item in itemsToMove {
            let src = contentsSourceDir.appendingPathComponent(item)
            let dst = destinationURL.appendingPathComponent(item)
            if fileManager.fileExists(atPath: dst.path) { try fileManager.removeItem(at: dst) }
            try fileManager.moveItem(at: src, to: dst)
        }
        applyBackupExclusion(to: destinationURL)
    }

    public nonisolated static func applyBackupExclusion(to url: URL) {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var targetUrl = url
        try? targetUrl.setResourceValues(resourceValues)
    }

    fileprivate nonisolated static func flattenDirectory(from sourceDir: URL, to destDir: URL) {
        let fileManager = FileManager.default
        guard let items = try? fileManager.contentsOfDirectory(atPath: sourceDir.path) else { return }
        for item in items {
            let src = sourceDir.appendingPathComponent(item)
            let dst = destDir.appendingPathComponent(item)
            if fileManager.fileExists(atPath: dst.path) { try? fileManager.removeItem(at: dst) }
            try? fileManager.moveItem(at: src, to: dst)
        }
        try? fileManager.removeItem(at: sourceDir)
    }

    private nonisolated static func executeInProcessTarExtraction(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        let reader = try ArchiveReader(path: sourceURL.path)
        defer { reader.close() }

        var pendingLongName: String?

        while true {
            let header = try reader.readExact(count: 512)
            if header.isEmpty || header.allSatisfy({ $0 == 0 }) { break }
            guard verifyTarChecksum(header) else { throw AIModelExtractionError.extractionFailed("Invalid tar header checksum") }

            guard let entry = parseTarHeader(from: header, pendingLongName: pendingLongName) else { continue }
            pendingLongName = nil
            if entry.isLongNameHeader {
                let longData = try reader.readExact(count: Int(entry.size))
                let end = longData.firstIndex(of: 0) ?? longData.endIndex
                pendingLongName = String(data: longData[..<end], encoding: .utf8)
                if entry.padding > 0 { try reader.discardBytes(count: entry.padding) }
                continue
            }

            try extractTarEntry(entry: entry, reader: reader, destinationURL: destinationURL, fileManager: fileManager)
        }
    }

    private struct TarEntryHeader {
        let name: String
        let size: Int64
        let typeFlag: Character
        let typeFlagByte: UInt8
        let padding: Int
        var isLongNameHeader: Bool { typeFlag == "L" }
    }

    private nonisolated static func parseTarHeader(from header: Data, pendingLongName: String?) -> TarEntryHeader? {
        let rawNameData = header.subdata(in: 0..<100)
        let nameEnd = rawNameData.firstIndex(of: 0) ?? rawNameData.endIndex
        let rawName = String(data: rawNameData[..<nameEnd], encoding: .utf8) ?? ""

        let prefixData = header.subdata(in: 245..<400)
        let prefixEnd = prefixData.firstIndex(of: 0) ?? prefixData.endIndex
        let prefix = String(data: prefixData[..<prefixEnd], encoding: .utf8) ?? ""

        let entryName = pendingLongName ?? (!prefix.isEmpty ? "\(prefix)/\(rawName)" : rawName)
        let size = parseTarOctal(header.subdata(in: 124..<136)) ?? 0
        let typeFlagByte = header[156]
        let typeFlag = Character(UnicodeScalar(typeFlagByte))
        let padding = (512 - (Int(size) % 512)) % 512

        return TarEntryHeader(name: entryName, size: size, typeFlag: typeFlag, typeFlagByte: typeFlagByte, padding: padding)
    }

    private nonisolated static func extractTarEntry(
        entry: TarEntryHeader, reader: ArchiveReader, destinationURL: URL, fileManager: FileManager
    ) throws {
        var relative = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
        while relative.hasPrefix("./") { relative.removeFirst(2) }
        while relative.hasPrefix("/") { relative.removeFirst(1) }

        if relative.isEmpty || relative == "." {
            if entry.size > 0 || entry.padding > 0 { try reader.discardBytes(count: Int(entry.size) + entry.padding) }
            return
        }
        guard !relative.split(separator: "/").contains("..") else {
            throw AIModelExtractionError.extractionFailed("Invalid path traversal in archive: \(entry.name)")
        }

        let targetURL = destinationURL.appendingPathComponent(relative)
        if entry.typeFlag == "5" || relative.hasSuffix("/") {
            try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)
            if entry.size > 0 || entry.padding > 0 { try reader.discardBytes(count: Int(entry.size) + entry.padding) }
        } else if entry.typeFlag == "0" || entry.typeFlagByte == 0 || entry.typeFlag == "7" {
            try writeRegularFile(targetURL: targetURL, size: entry.size, padding: entry.padding, reader: reader, fileManager: fileManager)
        } else {
            if entry.size > 0 || entry.padding > 0 { try reader.discardBytes(count: Int(entry.size) + entry.padding) }
        }
    }

    private nonisolated static func writeRegularFile(
        targetURL: URL, size: Int64, padding: Int, reader: ArchiveReader, fileManager: FileManager
    ) throws {
        try fileManager.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: targetURL.path) { try fileManager.removeItem(at: targetURL) }
        fileManager.createFile(atPath: targetURL.path, contents: nil)
        guard let fileHandle = try? FileHandle(forWritingTo: targetURL) else {
            throw AIModelExtractionError.extractionFailed("Failed to open file for writing: \(targetURL.path)")
        }
        var remaining = Int(size)
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        while remaining > 0 {
            let toRead = min(remaining, buffer.count)
            let bytesRead = try buffer.withUnsafeMutableBytes { ptr -> Int in
                try reader.read(into: UnsafeMutableRawBufferPointer(start: ptr.baseAddress, count: toRead))
            }
            if bytesRead == 0 {
                try? fileHandle.close()
                throw AIModelExtractionError.extractionFailed("Unexpected EOF while extracting \(targetURL.lastPathComponent)")
            }
            try fileHandle.write(contentsOf: buffer[0..<bytesRead])
            remaining -= bytesRead
        }
        try fileHandle.close()
        if padding > 0 { try reader.discardBytes(count: padding) }
    }
}

// MARK: - In-Process Archive Decompression & TAR Parsing

private final class BZ2Library: @unchecked Sendable {
    typealias BZReadOpenFunc = @convention(c) (
        UnsafeMutablePointer<Int32>?, UnsafeMutablePointer<FILE>?, Int32, Int32, UnsafeMutableRawPointer?, Int32
    ) -> OpaquePointer?
    typealias BZReadFunc = @convention(c) (
        UnsafeMutablePointer<Int32>?, OpaquePointer?, UnsafeMutableRawPointer?, Int32
    ) -> Int32
    typealias BZReadCloseFunc = @convention(c) (UnsafeMutablePointer<Int32>?, OpaquePointer?) -> Void

    static let shared: BZ2Library? = BZ2Library()

    let bzReadOpen: BZReadOpenFunc
    let bzRead: BZReadFunc
    let bzReadClose: BZReadCloseFunc

    private init?() {
        guard let handle = dlopen("/usr/lib/libbz2.dylib", RTLD_NOW)
            ?? dlopen("libbz2.dylib", RTLD_NOW)
            ?? dlopen("/usr/lib/libbz2.1.0.dylib", RTLD_NOW),
              let symOpen = dlsym(handle, "BZ2_bzReadOpen"),
              let symRead = dlsym(handle, "BZ2_bzRead"),
              let symClose = dlsym(handle, "BZ2_bzReadClose") else { return nil }
        self.bzReadOpen = unsafeBitCast(symOpen, to: BZReadOpenFunc.self)
        self.bzRead = unsafeBitCast(symRead, to: BZReadFunc.self)
        self.bzReadClose = unsafeBitCast(symClose, to: BZReadCloseFunc.self)
    }
}

private final class ArchiveReader {
    private let fileHandle: UnsafeMutablePointer<FILE>
    private let bzHandle: OpaquePointer?
    private let bz2Lib: BZ2Library?
    private var isClosed = false
    private var hasReachedEnd = false

    init(path: String) throws {
        guard let openedFile = fopen(path, "rb") else { throw AIModelExtractionError.fileNotFound(URL(fileURLWithPath: path)) }
        var magic = [UInt8](repeating: 0, count: 3)
        let magicRead = fread(&magic, 1, 3, openedFile)
        fseek(openedFile, 0, SEEK_SET)

        let isBz2 = (magicRead == 3 && magic[0] == 0x42 && magic[1] == 0x5A && magic[2] == 0x68)
        if isBz2 {
            guard let lib = BZ2Library.shared else {
                fclose(openedFile)
                throw AIModelExtractionError.extractionFailed("libbz2 is unavailable")
            }
            var bzerror: Int32 = 0
            guard let bzPtr = lib.bzReadOpen(&bzerror, openedFile, 0, 0, nil, 0), bzerror == 0 else {
                fclose(openedFile)
                throw AIModelExtractionError.extractionFailed("bzReadOpen failed: \(bzerror)")
            }
            self.fileHandle = openedFile
            self.bzHandle = bzPtr
            self.bz2Lib = lib
        } else {
            self.fileHandle = openedFile
            self.bzHandle = nil
            self.bz2Lib = nil
        }
    }

    deinit { close() }

    func read(into buffer: UnsafeMutableRawBufferPointer) throws -> Int {
        guard !hasReachedEnd, let base = buffer.baseAddress, !buffer.isEmpty else { return 0 }
        if let bzHandle, let bz2Lib {
            var bzerror: Int32 = 0
            let bytesRead = bz2Lib.bzRead(&bzerror, bzHandle, base, Int32(min(buffer.count, 65536)))
            if bzerror == 0 { return Int(bytesRead) }
            if bzerror == 4 { hasReachedEnd = true; return Int(bytesRead) }
            throw AIModelExtractionError.extractionFailed("libbz2 read error code: \(bzerror)")
        } else {
            let bytesRead = fread(base, 1, buffer.count, fileHandle)
            if bytesRead == 0 && ferror(fileHandle) != 0 { throw AIModelExtractionError.extractionFailed("File read error") }
            return bytesRead
        }
    }

    func readExact(count: Int) throws -> Data {
        var data = Data(count: count)
        var totalRead = 0
        try data.withUnsafeMutableBytes { (rawPtr: UnsafeMutableRawBufferPointer) in
            guard let base = rawPtr.baseAddress else { return }
            while totalRead < count {
                let dest = UnsafeMutableRawBufferPointer(start: base.advanced(by: totalRead), count: count - totalRead)
                let bytesRead = try read(into: dest)
                if bytesRead == 0 { break }
                totalRead += bytesRead
            }
        }
        if totalRead == 0 { return Data() }
        if totalRead < count { throw AIModelExtractionError.extractionFailed("Truncated archive: expected \(count) bytes, got \(totalRead)") }
        return data
    }

    func discardBytes(count: Int) throws {
        var remaining = count
        var buffer = [UInt8](repeating: 0, count: min(remaining, 64 * 1024))
        while remaining > 0 {
            let toRead = min(remaining, buffer.count)
            let bytesRead = try buffer.withUnsafeMutableBytes { ptr -> Int in
                try read(into: UnsafeMutableRawBufferPointer(start: ptr.baseAddress, count: toRead))
            }
            if bytesRead == 0 { throw AIModelExtractionError.extractionFailed("Unexpected end of archive in padding") }
            remaining -= bytesRead
        }
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        if let bzHandle, let bz2Lib {
            var bzerror: Int32 = 0
            bz2Lib.bzReadClose(&bzerror, bzHandle)
        }
        fclose(fileHandle)
    }
}

private func parseTarOctal(_ bytes: Data) -> Int64? {
    var str = ""
    for byte in bytes {
        if byte == 0 || byte == 0x20 { continue }
        if byte >= 0x30 && byte <= 0x37 { str.append(Character(UnicodeScalar(byte))) } else { break }
    }
    return str.isEmpty ? 0 : Int64(str, radix: 8)
}

private func verifyTarChecksum(_ header: Data) -> Bool {
    guard header.count == 512, let stored = parseTarOctal(header.subdata(in: 148..<156)) else { return false }
    var unsignedSum: Int64 = 0
    var signedSum: Int64 = 0
    for i in 0..<512 {
        if i >= 148 && i < 156 {
            unsignedSum += 32
            signedSum += 32
        } else {
            let byte = header[i]
            unsignedSum += Int64(byte)
            signedSum += Int64(Int8(bitPattern: byte))
        }
    }
    return stored == unsignedSum || stored == signedSum
}

extension Notification.Name {
    public static let onDemandAIModelStatusDidChange = Notification.Name("OnDemandAIModelStatusDidChangeNotification")
}
