import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking learner recorder")
struct LearnerRecorderTests {
    @Test func writesPlayableAACFileAndMeasuresAcceptedFrames() throws {
        let storage = try temporaryStorage()
        let recorder = LearnerRecorder(storage: storage)
        let inputFormat = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let recordingFormat = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let sessionId = UUID()

        #expect(try recorder.begin(sessionId: sessionId, format: recordingFormat) == "\(sessionId.uuidString).m4a")
        let converter = try PCMConverter(inputFormat: inputFormat)
        recorder.append(try converter.pcm16kMono(from: sine(format: inputFormat, frames: 48_000)))
        recorder.append(try converter.pcm16kMono(from: sine(format: inputFormat, frames: 48_000)))

        #expect(abs(recorder.elapsed - 2) < 0.001)
        let finishedURL = recorder.finish()
        let url = try #require(finishedURL)
        let file = try AVAudioFile(forReading: url)
        let duration = Double(file.length) / file.processingFormat.sampleRate

        #expect(url.pathExtension == "m4a")
        #expect(file.fileFormat.sampleRate == 16_000)
        #expect(file.fileFormat.channelCount == 1)
        #expect(abs(duration - 2) < 0.1)
        #expect(abs(recorder.elapsed - 2) < 0.001)
    }

    @Test func emptyRecordingReturnsNoPlayableURL() throws {
        let storage = try temporaryStorage()
        let recorder = LearnerRecorder(storage: storage)
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))

        let fileName = try recorder.begin(sessionId: UUID(), format: format)

        #expect(recorder.finish() == nil)
        #expect(recorder.elapsed == 0)
        #expect(!FileManager.default.fileExists(atPath: storage.url(for: fileName).path))
    }

    @Test func elapsedUsesAcceptedFramesAndActualInputRate() throws {
        let recorder = LearnerRecorder(storage: try temporaryStorage())
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))

        _ = try recorder.begin(sessionId: UUID(), format: format)
        recorder.append(try PCMConverter(inputFormat: format).pcm16kMono(from: sine(format: format, frames: 1_600)))
        recorder.append(try PCMConverter(inputFormat: format).pcm16kMono(from: sine(format: format, frames: 3_200)))

        #expect(abs(recorder.elapsed - 0.3) < 0.001)
        _ = recorder.finish()
    }

    @Test func recorderRejectsOverflowWithoutReturningTruncatedAudio() throws {
        let storage = try temporaryStorage()
        let recorder = LearnerRecorder(storage: storage, maximumQueuedBytes: 64)
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let fileName = try recorder.begin(sessionId: UUID(), format: format)
        recorder.append(Data(repeating: 0, count: 128))

        #expect(recorder.finish() == nil)
        #expect(!FileManager.default.fileExists(atPath: storage.url(for: fileName).path))
        #expect(recorder.overflowCount == 1)
    }

    private func temporaryStorage() throws -> SpeakingAudioStorage {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("speaking-recorder-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SpeakingAudioStorage(directory: directory)
    }

    private func sine(format: AVAudioFormat, frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        let channels = try #require(buffer.floatChannelData)
        for frame in 0..<Int(frames) {
            let phase = 2.0 * Double.pi * 220.0 * Double(frame) / format.sampleRate
            channels[0][frame] = Float(sin(phase))
        }
        return buffer
    }
}
