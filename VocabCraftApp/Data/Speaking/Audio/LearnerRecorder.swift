import AudioToolbox
import AVFoundation
import Foundation

public enum LearnerRecorderError: Error {
    case invalidFormat
    case alreadyRecording
    case cannotCreateFile
}

/// Writes learner audio as AAC. The lock serializes conversion, accepted-frame accounting, and file writes.
/// AVAudioPCMBuffer is consumed synchronously and never escapes this call.
public final class LearnerRecorder: @unchecked Sendable {
    private let storage: SpeakingAudioStorage
    private let lock = NSLock()
    private var writer: AVAudioFile?
    private var converter: AVAudioConverter?
    private var converterInputFormat: AVAudioFormat?
    private var currentFileName: String?
    private var acceptedDuration: TimeInterval = 0
    private var writeFailed = false

    public init(storage: SpeakingAudioStorage) {
        self.storage = storage
    }

    public func begin(sessionId: UUID, format: AVAudioFormat) throws -> String {
        try lock.withLock {
            guard writer == nil else { throw LearnerRecorderError.alreadyRecording }
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw LearnerRecorderError.invalidFormat
            }

            let fileName = "\(sessionId.uuidString).m4a"
            let fileURL = storage.url(for: fileName)
            guard fileURL.lastPathComponent == fileName else {
                throw LearnerRecorderError.cannotCreateFile
            }
            try storage.createDirectoryIfNeeded()
            try? FileManager.default.removeItem(at: fileURL)
            let nextConverter = try makeConverter(from: format)

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 32_000
            ]
            do {
                writer = try AVAudioFile(
                    forWriting: fileURL,
                    settings: settings,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
            } catch {
                throw LearnerRecorderError.cannotCreateFile
            }

            converter = nextConverter
            converterInputFormat = format
            currentFileName = fileName
            acceptedDuration = 0
            writeFailed = false
            return fileName
        }
    }

    public func append(_ buffer: AVAudioPCMBuffer) {
        lock.withLock {
            guard !writeFailed, let writer, buffer.frameLength > 0 else { return }
            do {
                if converterInputFormat?.isEqual(buffer.format) != true {
                    if let converter {
                        try flush(converter, into: writer)
                    }
                    converter = try makeConverter(from: buffer.format)
                    converterInputFormat = buffer.format
                }
                guard let converter,
                      let converted = try convert(buffer, using: converter, to: writer.processingFormat)
                else {
                    return
                }

                if converted.frameLength > 0 {
                    try writer.write(from: converted)
                }
                acceptedDuration += Double(buffer.frameLength) / buffer.format.sampleRate
            } catch {
                writeFailed = true
            }
        }
    }

    public var elapsed: TimeInterval {
        lock.withLock { acceptedDuration }
    }

    public func finish() -> URL? {
        lock.withLock {
            if let writer, let converter {
                do {
                    try flush(converter, into: writer)
                } catch {
                    writeFailed = true
                }
            }
            writer = nil
            converter = nil
            converterInputFormat = nil

            guard let fileName = currentFileName else { return nil }
            currentFileName = nil
            guard acceptedDuration > 0, !writeFailed else {
                storage.delete(fileNames: [fileName])
                return nil
            }

            let fileURL = storage.url(for: fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path),
                  let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                  (attributes[.size] as? NSNumber)?.intValue ?? 0 > 0
            else {
                storage.delete(fileNames: [fileName])
                return nil
            }
            return fileURL
        }
    }

    private func makeConverter(from inputFormat: AVAudioFormat) throws -> AVAudioConverter {
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0,
              let outputFormat = AVAudioFormat(
                  commonFormat: .pcmFormatFloat32,
                  sampleRate: 16_000,
                  channels: 1,
                  interleaved: false
              ),
              let converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        else {
            throw LearnerRecorderError.invalidFormat
        }
        return converter
    }

    private func convert(
        _ input: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        to outputFormat: AVAudioFormat
    ) throws -> AVAudioPCMBuffer? {
        let scale = outputFormat.sampleRate / input.format.sampleRate
        let capacity = AVAudioFrameCount(ceil(Double(input.frameLength) * scale)) + 64
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            throw LearnerRecorderError.invalidFormat
        }

        var conversionError: NSError?
        var didProvideInput = false
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            guard !didProvideInput else {
                inputStatus.pointee = .noDataNow
                return nil
            }
            didProvideInput = true
            inputStatus.pointee = .haveData
            return input
        }
        guard status != .error, conversionError == nil else {
            throw conversionError ?? LearnerRecorderError.invalidFormat
        }
        return output
    }

    private func flush(_ converter: AVAudioConverter, into writer: AVAudioFile) throws {
        guard let output = AVAudioPCMBuffer(pcmFormat: writer.processingFormat, frameCapacity: 4_096) else {
            throw LearnerRecorderError.invalidFormat
        }
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            inputStatus.pointee = .endOfStream
            return nil
        }
        guard status != .error, conversionError == nil else {
            throw conversionError ?? LearnerRecorderError.invalidFormat
        }
        if output.frameLength > 0 {
            try writer.write(from: output)
        }
    }
}
