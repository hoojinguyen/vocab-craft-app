@preconcurrency import AVFoundation

protocol SpeechAudioEngineControlling: Sendable {
    func prepare(relay: AudioBufferRelay) async throws
    func resume() async throws
    func pause() async
    func teardown() async
}

protocol SpeechAudioHardware: Sendable {
    func prepare(relay: AudioBufferRelay) async throws
    func resume() async throws
    func pause() async
    func teardown() async
}

actor SpeechAudioEngineController: SpeechAudioEngineControlling {
    enum State: Equatable, Sendable {
        case idle
        case preparing
        case ready
        case failed
    }

    private(set) var state: State = .idle

    private var preparationTask: Task<Void, Error>?
    private var isPaused = false
    private let hardware: any SpeechAudioHardware

    init() {
        hardware = AVSpeechAudioHardware()
    }

    init(hardware: any SpeechAudioHardware) {
        self.hardware = hardware
    }

    func prepare(relay: AudioBufferRelay) async throws {
        if state == .ready {
            return
        }
        if let preparationTask {
            return try await preparationTask.value
        }

        state = .preparing
        let hardware = self.hardware
        let task = Task {
            try await hardware.prepare(relay: relay)
        }
        preparationTask = task

        do {
            try await task.value
            state = .ready
            isPaused = false
            preparationTask = nil
        } catch {
            state = .failed
            preparationTask = nil
            throw error
        }
    }

    func resume() async throws {
        guard state == .ready, isPaused else {
            return
        }

        isPaused = false
        do {
            try await hardware.resume()
        } catch {
            isPaused = true
            throw error
        }
    }

    func pause() async {
        guard state == .ready, !isPaused else {
            return
        }

        isPaused = true
        await hardware.pause()
    }

    func teardown() async {
        guard state != .idle else {
            return
        }

        state = .idle
        isPaused = false
        await hardware.teardown()
    }
}

private enum SpeechAudioHardwareError: Error {
    case invalidInputFormat
}

private actor AVSpeechAudioHardware: SpeechAudioHardware {
    private var audioEngine: AVAudioEngine?

    func prepare(relay: AudioBufferRelay) async throws {
        guard audioEngine == nil else {
            return
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        #if os(iOS)
        try? inputNode.setVoiceProcessingEnabled(true)
        #endif

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw SpeechAudioHardwareError.invalidInputFormat
        }

        inputNode.installTap(onBus: 0, bufferSize: 2_048, format: recordingFormat) { [relay] buffer, _ in
            relay.append(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
            audioEngine = engine
        } catch {
            inputNode.removeTap(onBus: 0)
            throw error
        }
    }

    func resume() async throws {
        guard let audioEngine, !audioEngine.isRunning else {
            return
        }
        try audioEngine.start()
    }

    func pause() async {
        guard let audioEngine, audioEngine.isRunning else {
            return
        }
        audioEngine.stop()
    }

    func teardown() async {
        guard let audioEngine else {
            return
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()
        self.audioEngine = nil
    }
}
