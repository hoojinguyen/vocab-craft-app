import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking learner recorder")
struct LearnerRecorderTests {
    @Test func writesPlayableAACFileAndMeasuresAcceptedFrames() throws {
        let storage = try temporaryStorage()
        let recorder = LearnerRecorder(storage: storage)
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let sessionId = UUID()

        #expect(try recorder.begin(sessionId: sessionId, format: format) == "\(sessionId.uuidString).m4a")
        recorder.append(try sine(format: format, frames: 48_000))
        recorder.append(try sine(format: format, frames: 48_000))

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
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))

        _ = try recorder.begin(sessionId: UUID(), format: format)
        recorder.append(try sine(format: format, frames: 4_410))
        recorder.append(try sine(format: format, frames: 8_820))

        #expect(abs(recorder.elapsed - 0.3) < 0.001)
        _ = recorder.finish()
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
