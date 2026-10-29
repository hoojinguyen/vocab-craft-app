import AVFoundation
import Foundation

public enum PCMConverterError: Error, Equatable {
    case invalidInputFormat
    case unsupportedConversion
    case inputFormatMismatch
    case conversionFailed
}

/// Converts one input format to the wire and playback formats used by Gemini Live.
public struct PCMConverter {
    private let inputFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat

    public init(inputFormat: AVAudioFormat) throws {
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw PCMConverterError.invalidInputFormat
        }

        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16_000,
            channels: 1,
            interleaved: true
        ) else {
            throw PCMConverterError.unsupportedConversion
        }
        guard AVAudioConverter(from: inputFormat, to: outputFormat) != nil else {
            throw PCMConverterError.unsupportedConversion
        }

        self.inputFormat = inputFormat
        self.outputFormat = outputFormat
    }

    /// Returns signed 16-bit little-endian mono samples at 16 kHz.
    public func pcm16kMono(from buffer: AVAudioPCMBuffer) throws -> Data {
        guard inputFormat.isEqual(buffer.format) else {
            throw PCMConverterError.inputFormatMismatch
        }
        guard buffer.frameLength > 0 else { return Data() }
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw PCMConverterError.unsupportedConversion
        }

        let ratio = outputFormat.sampleRate / inputFormat.sampleRate
        let capacity = AVAudioFrameCount(ceil(Double(buffer.frameLength) * ratio)) + 64
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            throw PCMConverterError.conversionFailed
        }

        var conversionError: NSError?
        var providedInput = false
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            guard !providedInput else {
                inputStatus.pointee = .endOfStream
                return nil
            }
            providedInput = true
            inputStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, conversionError == nil else {
            throw conversionError ?? PCMConverterError.conversionFailed
        }
        guard output.frameLength > 0, let samples = output.int16ChannelData?[0] else {
            return Data()
        }

        var data = Data(capacity: Int(output.frameLength) * MemoryLayout<Int16>.size)
        for index in 0..<Int(output.frameLength) {
            let sampleBits = UInt16(bitPattern: samples[index])
            data.append(UInt8(truncatingIfNeeded: sampleBits))
            data.append(UInt8(truncatingIfNeeded: sampleBits >> 8))
        }
        return data
    }

    /// Decodes signed 16-bit little-endian mono samples to Float32 at 24 kHz.
    public static func playbackBuffer(fromPCM24k data: Data) -> AVAudioPCMBuffer? {
        guard !data.isEmpty, data.count.isMultiple(of: MemoryLayout<Int16>.size),
              let format = AVAudioFormat(standardFormatWithSampleRate: 24_000, channels: 1),
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: format,
                  frameCapacity: AVAudioFrameCount(data.count / MemoryLayout<Int16>.size)
              ),
              let samples = buffer.floatChannelData?[0]
        else {
            return nil
        }

        let frameCount = data.count / MemoryLayout<Int16>.size
        buffer.frameLength = AVAudioFrameCount(frameCount)
        data.withUnsafeBytes { rawBytes in
            guard let bytes = rawBytes.bindMemory(to: UInt8.self).baseAddress else { return }
            for index in 0..<frameCount {
                let low = UInt16(bytes[index * 2])
                let high = UInt16(bytes[index * 2 + 1]) << 8
                let sample = Int16(bitPattern: high | low)
                samples[index] = Float(sample) / 32_768
            }
        }
        return buffer
    }
}
