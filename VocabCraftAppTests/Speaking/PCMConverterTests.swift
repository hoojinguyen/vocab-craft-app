import AVFoundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking PCM conversion")
struct PCMConverterTests {
    @Test func converts48kFloatTo16kInt16() throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let buffer = try sine(format: format, frames: 4_800)
        let data = try PCMConverter(inputFormat: format).pcm16kMono(from: buffer)

        #expect(data.count == 1_600 * MemoryLayout<Int16>.size)
    }

    @Test func converts441kStereoInputToMonoAtExpectedRate() throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2))
        let buffer = try sine(format: format, frames: 4_410)
        let data = try PCMConverter(inputFormat: format).pcm16kMono(from: buffer)

        #expect(data.count == 1_600 * MemoryLayout<Int16>.size)
    }

    @Test func pcmOutputContainsExpectedLittleEndianAmplitude() throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let input = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1_600))
        input.frameLength = 1_600
        input.floatChannelData?[0].initialize(repeating: 0.5, count: 1_600)
        let data = try PCMConverter(inputFormat: format).pcm16kMono(from: input)
        let output = try #require(PCMConverter.playbackBuffer(fromPCM24k: data))
        let firstByte = try #require(data.first)
        let secondByte = try #require(data.dropFirst().first)

        #expect(firstByte == 0x00)
        #expect(secondByte == 0x40)
        #expect(abs((output.floatChannelData?[0][800] ?? 0) - 0.5) < 0.01)
    }

    @Test func playbackRejectsOddLengthPCM() {
        #expect(PCMConverter.playbackBuffer(fromPCM24k: Data([1, 2, 3])) == nil)
    }

    @Test func capturePayloadOwnsSamplesAfterCallbackReturns() throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let source = try sine(format: format, frames: 4_800)
        let payload = try PCMConverter(inputFormat: format).pcm16kMono(from: source)
        let original = payload
        source.floatChannelData?[0][0] = 0.75

        #expect(payload == original)
        #expect(payload.count == 3_200)
    }

    @Test func playbackQueueRejectsAudioBeyondTwoSecondBound() {
        #expect(!VoiceProcessingAudioIO.canSchedulePlayback(pendingFrames: 47_000, incomingFrames: 2_000, maximumFrames: 48_000))
        #expect(VoiceProcessingAudioIO.canSchedulePlayback(pendingFrames: 40_000, incomingFrames: 8_000, maximumFrames: 48_000))
    }

    @Test func tapCopyOwnsSamplesForOffCallbackConversion() throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let source = try sine(format: format, frames: 32)
        let copied = try #require(VoiceProcessingAudioIO.ownedCaptureSamples(from: source))
        let originalFirstSample = copied.channels[0][0]
        source.floatChannelData?[0][0] = 0.75

        #expect(copied.sampleRate == 48_000)
        #expect(copied.frameCount == 32)
        #expect(copied.channels[0][0] == originalFirstSample)
    }

    @Test func captureQueueRejectsSamplesBeyondTwoSecondBound() {
        #expect(!VoiceProcessingAudioIO.canQueueCapture(pendingFrames: 95_000, incomingFrames: 2_000, maximumFrames: 96_000))
        #expect(VoiceProcessingAudioIO.canQueueCapture(pendingFrames: 80_000, incomingFrames: 16_000, maximumFrames: 96_000))
    }

    @Test func captureReconstructionFailureIncrementsObservableFailureSignal() {
        let failures = SpeakingAudioCaptureFailureSignal()
        let invalidSamples = SpeakingCaptureSamples(sampleRate: 0, channels: [[0.25, -0.25]])

        let packet = VoiceProcessingAudioIO.queuedCapturePacket(from: invalidSamples, isCurrent: { true }, failureSignal: failures)

        #expect(packet == nil)
        #expect(failures.count == 1)
    }

    @Test func captureConversionFailureIncrementsObservableFailureSignal() throws {
        let failures = SpeakingAudioCaptureFailureSignal()
        let samples = SpeakingCaptureSamples(sampleRate: 48_000, channels: [[0.25, -0.25]])

        let packet = VoiceProcessingAudioIO.queuedCapturePacket(from: samples, isCurrent: { true }, failureSignal: failures) { _ in
            throw URLError(.cannotDecodeContentData)
        }

        #expect(packet == nil)
        #expect(failures.count == 1)
    }

    @Test func intentionalCaptureInvalidationDoesNotIncrementFailureSignal() {
        let failures = SpeakingAudioCaptureFailureSignal()
        let samples = SpeakingCaptureSamples(sampleRate: 48_000, channels: [[0.25, -0.25]])
        var packetIsCurrent = true

        let packet = VoiceProcessingAudioIO.queuedCapturePacket(from: samples, isCurrent: {
            packetIsCurrent
        }, failureSignal: failures) { _ in
            packetIsCurrent = false
            return Data([0x00, 0x00])
        }

        #expect(packet == nil)
        #expect(!failures.hasFailures)
    }

    @Test func playbackRejectsEmptyPCM() {
        #expect(PCMConverter.playbackBuffer(fromPCM24k: Data()) == nil)
    }

    @Test func playbackDecodesLittleEndianSamplesToFloatMono() throws {
        let data = Data([0x00, 0x40, 0x00, 0xC0])
        let buffer = try #require(PCMConverter.playbackBuffer(fromPCM24k: data))

        #expect(buffer.format.sampleRate == 24_000)
        #expect(buffer.format.channelCount == 1)
        #expect(buffer.frameLength == 2)
        #expect(buffer.floatChannelData?[0][0] ?? 0 == 0.5)
        #expect(buffer.floatChannelData?[0][1] ?? 0 == -0.5)
    }

    @Test func converterRejectsMismatchedInputFormat() throws {
        let configuredFormat = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let otherFormat = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let buffer = try sine(format: otherFormat, frames: 1_000)
        let converter = try PCMConverter(inputFormat: configuredFormat)

        #expect(throws: PCMConverterError.inputFormatMismatch) {
            try converter.pcm16kMono(from: buffer)
        }
    }

    private func sine(format: AVAudioFormat, frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        let channels = try #require(buffer.floatChannelData)

        for frame in 0..<Int(frames) {
            let phase = 2.0 * Double.pi * 440.0 * Double(frame) / format.sampleRate
            let sample = Float(sin(phase))
            channels[0][frame] = sample
            if buffer.format.channelCount > 1 {
                channels[1][frame] = sample
            }
        }

        return buffer
    }
}
