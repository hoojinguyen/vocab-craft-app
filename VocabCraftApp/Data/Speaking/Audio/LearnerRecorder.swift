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
    private var queuedBytes = 0
    private var writer: AVAudioFile?
    private var currentFileName: String?
    private var acceptedFrames: Int64 = 0
    private var writtenFrames: Int64 = 0
    private var writeFailed = false
    private var recordedOverflowCount = 0
    private var format: AVAudioFormat?

    public init(storage: SpeakingAudioStorage, maximumQueuedBytes: Int = 64_000) {
        self.storage = storage
        self.maximumQueuedBytes = max(2, maximumQueuedBytes)
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
            writeFailed = false
            stateLock.withLock { queuedBytes = 0; recordedOverflowCount = 0 }
            return fileName
        }
    }

    /// Nonblocking bounded enqueue. Capacity contention or overflow invalidates the recording and is reported by finish().
    public func append(_ pcm16kMono: Data) {
        guard !pcm16kMono.isEmpty, pcm16kMono.count.isMultiple(of: 2) else { return }
        guard stateLock.try() else {
            writerQueue.async { [weak self] in
                guard let self else { return }
                self.writeFailed = true
                self.stateLock.withLock { self.recordedOverflowCount += 1 }
            }
            return
        }
        guard queuedBytes + pcm16kMono.count <= maximumQueuedBytes else {
            recordedOverflowCount += 1
            stateLock.unlock()
            writerQueue.async { [weak self] in self?.writeFailed = true }
            return
        }
        queuedBytes += pcm16kMono.count
        acceptedFrames += Int64(pcm16kMono.count / 2)
        stateLock.unlock()

        writerQueue.async { [weak self] in
            guard let self else { return }
            defer { self.stateLock.withLock { self.queuedBytes -= pcm16kMono.count } }
            guard !self.writeFailed, let writer = self.writer, let format = self.format else { return }
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
                self.writeFailed = true
            }
        }
    }

    public var elapsed: TimeInterval {
        stateLock.withLock { Double(acceptedFrames) / 16_000 }
    }

    public var overflowCount: Int { stateLock.withLock { recordedOverflowCount } }

    public func finish() -> URL? {
        writerQueue.sync {
            let fileName = currentFileName
            writer = nil
            format = nil
            currentFileName = nil
            guard let fileName else { return nil }
            guard writtenFrames > 0, !writeFailed else {
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
