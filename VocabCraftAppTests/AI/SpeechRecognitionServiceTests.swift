import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("SpeechRecognitionService Tests")
@MainActor
struct SpeechRecognitionServiceTests {
    @Test("audioLevel initially within normalized range 0.0...1.0")
    func testAudioLevelCalculatesNormalizedDecibels() {
        let service = SpeechRecognitionService()
        #expect(service.audioLevel >= 0.0 && service.audioLevel <= 1.0)
        #expect(service.audioLevel == 0.0)
    }

    @Test("RMS normalization formula maps -50 dB...0 dB to 0.0...1.0")
    func testRMSDecibelNormalizationFormula() {
        // Silence (below threshold) -> clamped to 0.0
        #expect(SpeechRecognitionService.calculateNormalizedAudioLevel(rms: 0.0) == 0.0)
        #expect(SpeechRecognitionService.calculateNormalizedAudioLevel(rms: 0.00001) == 0.0)

        // Threshold boundary: 0.003162277 is approx -50 dB -> 0.0
        let thresholdLevel = SpeechRecognitionService.calculateNormalizedAudioLevel(rms: 0.003162277)
        #expect(abs(thresholdLevel - 0.0) < 0.01)

        // Mid point: -25 dB is approx rms 0.056234 -> 0.5
        let midLevel = SpeechRecognitionService.calculateNormalizedAudioLevel(rms: 0.05623413)
        #expect(abs(midLevel - 0.5) < 0.01)

        // Full scale: 0 dB is rms 1.0 -> 1.0
        let fullLevel = SpeechRecognitionService.calculateNormalizedAudioLevel(rms: 1.0)
        #expect(abs(fullLevel - 1.0) < 0.001)

        // Clipping: rms > 1.0 -> clamped to 1.0
        #expect(SpeechRecognitionService.calculateNormalizedAudioLevel(rms: 2.0) == 1.0)
    }

    @Test("RMS calculation on audio buffer correctly computes mean square root")
    func testRMSCalculationFromBuffer() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100) else {
            Issue.record("Failed to create PCM buffer")
            return
        }
        buffer.frameLength = 100
        guard let channelData = buffer.floatChannelData?[0] else {
            Issue.record("Failed to access channel data")
            return
        }

        // Fill buffer with constant sample 0.5 -> RMS must be exactly 0.5
        for i in 0..<100 {
            channelData[i] = 0.5
        }

        let computedRMS = SpeechRecognitionService.calculateRMS(buffer: buffer)
        #expect(abs(computedRMS - 0.5) < 0.0001)

        let normalized = SpeechRecognitionService.calculateNormalizedAudioLevel(rms: computedRMS)
        // 20 * log10(0.5) = -6.0206 dB; (-6.0206 + 50) / 50 = 0.87958
        #expect(abs(normalized - 0.87958) < 0.01)
    }

    @Test("SpeechRecognitionService awaits audioSessionCoordinator lease before recording starts")
    func testSequentialLeaseAcquisitionBeforeCapture() async throws {
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let service = SpeechRecognitionService(audioSessionCoordinator: coordinator)

        #expect(service.isRecording == false)
        #expect(service.activeLease == nil)

        try service.startListening()
        // Wait for lease acquisition task to finish
        _ = await service.leaseAcquisitionTask?.value

        #expect(service.isRecording == true)
        #expect(service.activeLease != nil)
        #expect(await coordinator.activeLeaseCount == 1)
        #expect(await coordinator.effectiveIntent == .speechCapture)

        service.stopListening()
        _ = await service.leaseReleaseTask?.value
        #expect(service.isRecording == false)
        #expect(service.activeLease == nil)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("stopListening resets audioLevel to 0.0")
    func testStopListeningResetsAudioLevel() async throws {
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let service = SpeechRecognitionService(audioSessionCoordinator: coordinator)

        try service.startListening()
        _ = await service.leaseAcquisitionTask?.value

        // Injected level
        service.injectAudioLevelForTesting(0.75)
        #expect(service.audioLevel == 0.75)

        service.stopListening()
        #expect(service.audioLevel == 0.0)
    }

    @Test("startListening delivers audioLevel updates via callback")
    func testAudioLevelCallback() async throws {
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let service = SpeechRecognitionService(audioSessionCoordinator: coordinator)

        var receivedAudioLevels: [Float] = []
        service.startListening(
            onResult: { _ in },
            onAudioLevel: { level in
                receivedAudioLevels.append(level)
            },
            onError: { _ in }
        )

        _ = await service.leaseAcquisitionTask?.value
        #expect(service.isRecording == true)

        service.injectAudioLevelForTesting(0.65)
        #expect(service.audioLevel == 0.65)
        #expect(receivedAudioLevels.contains(0.65))

        service.stopListening()
        #expect(service.audioLevel == 0.0)
    }
}
