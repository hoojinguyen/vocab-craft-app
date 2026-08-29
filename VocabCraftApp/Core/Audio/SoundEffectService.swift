import AVFoundation
import Foundation

public protocol SoundEffectServiceProtocol: Sendable {
    func playSuccessChime()
    func playIncorrectChime()
}

public final class SoundEffectService: SoundEffectServiceProtocol, @unchecked Sendable {
    public static let shared = SoundEffectService()

    private var successPlayer: AVAudioPlayer?
    private var incorrectPlayer: AVAudioPlayer?
    private let lock = NSLock()

    public init() {
        setupPlayers()
    }

    private func setupPlayers() {
        if let successData = Self.generateChimeData(frequencies: [587.33, 880.0], durations: [0.08, 0.16]) {
            successPlayer = try? AVAudioPlayer(data: successData)
            successPlayer?.prepareToPlay()
            successPlayer?.volume = 0.5
        }

        if let incorrectData = Self.generateChimeData(frequencies: [349.23, 261.63], durations: [0.08, 0.14]) {
            incorrectPlayer = try? AVAudioPlayer(data: incorrectData)
            incorrectPlayer?.prepareToPlay()
            incorrectPlayer?.volume = 0.4
        }
    }

    public func playSuccessChime() {
        lock.lock()
        defer { lock.unlock() }
        successPlayer?.currentTime = 0
        successPlayer?.play()
    }

    public func playIncorrectChime() {
        lock.lock()
        defer { lock.unlock() }
        incorrectPlayer?.currentTime = 0
        incorrectPlayer?.play()
    }

    private static func generateChimeData(frequencies: [Double], durations: [Double], sampleRate: Double = 44100.0) -> Data? {
        var samples: [Int16] = []
        let totalDuration = durations.reduce(0, +)
        let totalSamples = Int(totalDuration * sampleRate)
        samples.reserveCapacity(totalSamples)

        for (index, freq) in frequencies.enumerated() {
            let noteDuration = durations[index]
            let noteSampleCount = Int(noteDuration * sampleRate)

            for i in 0..<noteSampleCount {
                let t = Double(i) / sampleRate
                let progress = Double(i) / Double(noteSampleCount)
                // Smooth envelope: quick attack, exponential decay
                let attack = min(1.0, progress / 0.05)
                let decay = exp(-progress * 4.0)
                let envelope = attack * decay

                let sampleValue = sin(2.0 * .pi * freq * t) * envelope * 0.7
                let clamped = max(-1.0, min(1.0, sampleValue))
                let int16Sample = Int16(clamped * 32767.0)
                samples.append(int16Sample)
            }
        }

        return createWavData(from: samples, sampleRate: Int(sampleRate))
    }

    private static func createWavData(from samples: [Int16], sampleRate: Int) -> Data {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        let dataSize = Int32(samples.count * 2)
        let chunkSize = 36 + dataSize

        var data = Data()
        // RIFF header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSizeLE = chunkSize.littleEndian
        data.append(Data(bytes: &chunkSizeLE, count: 4))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        // fmt subchunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size = Int32(16).littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat = Int16(1).littleEndian // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var channelsLE = numChannels.littleEndian
        data.append(Data(bytes: &channelsLE, count: 2))
        var sampleRateLE = Int32(sampleRate).littleEndian
        data.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE = byteRate.littleEndian
        data.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE = blockAlign.littleEndian
        data.append(Data(bytes: &blockAlignLE, count: 2))
        var bitsPerSampleLE = bitsPerSample.littleEndian
        data.append(Data(bytes: &bitsPerSampleLE, count: 2))

        // data subchunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var dataSizeLE = dataSize.littleEndian
        data.append(Data(bytes: &dataSizeLE, count: 4))

        for sample in samples {
            var sampleLE = sample.littleEndian
            data.append(Data(bytes: &sampleLE, count: 2))
        }

        return data
    }
}
