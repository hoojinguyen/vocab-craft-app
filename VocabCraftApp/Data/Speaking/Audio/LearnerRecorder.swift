import AudioToolbox
import AVFoundation
import Foundation

public enum LearnerRecorderError: Error {
    case invalidFormat
    case alreadyRecording
    case cannotCreateFile
}

/// Copies bounded PCM packets into a serial AAC writer. The capture caller never performs file I/O.
public final class LearnerRecorder: @unchecked Sendable {
    private let storage: SpeakingAudioStorage
    private let writerQueue = DispatchQueue(label: "app.vocabcraft.speaking.recorder-writer")
    private let stateLock = NSLock()
    private let maximumQueuedBytes: Int
    private let beforeWriteEnqueue: () -> Void
    private var queuedBytes = 0
    private var writer: AVAudioFile?
    private var currentFileName: String?
    private var acceptedFrames: Int64 = 0
    private var writtenFrames: Int64 = 0
    private var writeFailed = false
    private var recordedOverflowCount = 0
    private var pendingWriteOperations = 0
    private var recordingActive = false
    private var format: AVAudioFormat?

    public convenience init(storage: SpeakingAudioStorage, maximumQueuedBytes: Int = 64_000) {
        self.init(storage: storage, maximumQueuedBytes: maximumQueuedBytes, beforeWriteEnqueue: {})
    }

    init(storage: SpeakingAudioStorage, maximumQueuedBytes: Int = 64_000, beforeWriteEnqueue: @escaping () -> Void) {
        self.storage = storage
        self.maximumQueuedBytes = max(2, maximumQueuedBytes)
        self.beforeWriteEnqueue = beforeWriteEnqueue
    }

    public func begin(sessionId: UUID, format: AVAudioFormat) throws -> String {
        try writerQueue.sync {
            guard writer == nil else { throw LearnerRecorderError.alreadyRecording }
            guard format.sampleRate == 16_000, format.channelCount == 1 else {
                throw LearnerRecorderError.invalidFormat
            }
            let fileName = "\(sessionId.uuidString).m4a"
            let fileURL = storage.url(for: fileName)
            guard fileURL.lastPathComponent == fileName else { throw LearnerRecorderError.cannotCreateFile }
            try storage.createDirectoryIfNeeded()
            try? FileManager.default.removeItem(at: fileURL)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 32_000
            ]
            do {
                writer = try AVAudioFile(forWriting: fileURL, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            } catch {
                throw LearnerRecorderError.cannotCreateFile
            }
            self.format = format
            currentFileName = fileName
            acceptedFrames = 0
            writtenFrames = 0
            stateLock.withLock {
                queuedBytes = 0
                recordedOverflowCount = 0
                pendingWriteOperations = 0
                writeFailed = false
                recordingActive = true
            }
            return fileName
        }
    }

    /// Enqueues bounded PCM writes; a failed capacity reservation invalidates the recording synchronously.
    public func append(_ pcm16kMono: Data) {
        guard !pcm16kMono.isEmpty, pcm16kMono.count.isMultiple(of: 2) else { return }
        stateLock.lock()
        guard recordingActive else {
            stateLock.unlock()
            return
        }
        guard queuedBytes + pcm16kMono.count <= maximumQueuedBytes else {
            recordedOverflowCount += 1
            writeFailed = true
            stateLock.unlock()
            return
        }
        guard !writeFailed else {
            stateLock.unlock()
            return
        }
        queuedBytes += pcm16kMono.count
        pendingWriteOperations += 1
        acceptedFrames += Int64(pcm16kMono.count / 2)
        beforeWriteEnqueue()
        writerQueue.async { [weak self] in
            guard let self else { return }
            defer {
                self.stateLock.withLock {
                    self.queuedBytes -= pcm16kMono.count
                    self.pendingWriteOperations -= 1
                }
            }
            let shouldWrite = self.stateLock.withLock { !self.writeFailed }
            guard shouldWrite, let writer = self.writer, let format = self.format else { return }
            do {
                let frames = pcm16kMono.count / 2
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
                      let samples = buffer.floatChannelData?[0]
                else { throw LearnerRecorderError.invalidFormat }
                buffer.frameLength = AVAudioFrameCount(frames)
                pcm16kMono.withUnsafeBytes { raw in
                    let bytes = raw.bindMemory(to: UInt8.self)
                    for index in 0..<frames {
                        let value = Int16(bitPattern: UInt16(bytes[index * 2]) | (UInt16(bytes[index * 2 + 1]) << 8))
                        samples[index] = Float(value) / 32_768
                    }
                }
                try writer.write(from: buffer)
                self.writtenFrames += Int64(buffer.frameLength)
            } catch {
                self.stateLock.withLock { self.writeFailed = true }
            }
        }
        stateLock.unlock()
    }

    public var elapsed: TimeInterval {
        stateLock.withLock { Double(acceptedFrames) / 16_000 }
    }

    public var overflowCount: Int { stateLock.withLock { recordedOverflowCount } }

    var pendingWriteOperationCount: Int { stateLock.withLock { pendingWriteOperations } }

    public func finish() -> URL? {
        stateLock.withLock { recordingActive = false }
        return writerQueue.sync {
            let fileName = currentFileName
            writer = nil
            format = nil
            currentFileName = nil
            let didFail = stateLock.withLock { writeFailed }
            guard let fileName else { return nil }
            guard writtenFrames > 0, !didFail else {
                storage.delete(fileNames: [fileName])
                return nil
            }
            let fileURL = storage.url(for: fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path),
                  let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                  let size = attributes[.size] as? NSNumber,
                  size.intValue > 0
            else {
                storage.delete(fileNames: [fileName])
                return nil
            }
            return fileURL
        }
    }
}
