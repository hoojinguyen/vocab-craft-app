public enum SpeakingCallFailure: Error, Equatable, Sendable {
    case missingKey
    case unauthorized
    case quotaExceeded
    case offline
    case network
    case microphoneDenied
    case unknown
}

public enum SpeakingCallPhase: Equatable, Sendable {
    case idle
    case connecting
    case live
    case reconnecting
    case ended(SpeakingEndReason)
    case failed(SpeakingCallFailure)
}

public enum SpeakingCallInput: Equatable, Sendable {
    case start
    case setupComplete
    case transportDropped
    case reconnectTimedOut
    case goAway
    case resumptionHandle(String)
    case aiRequestedEnd
    case learnerEnded
    case wrapUpDue
    case hardLimitReached
    case audioInterrupted
    case connectFailed(SpeakingCallFailure)
}

public enum SpeakingCallEffect: Equatable, Sendable {
    case openSocket(resumptionHandle: String?)
    case sendOpeningTrigger
    case startAudio
    case stopAudio
    case closeSocket
    case startReconnectTimer(seconds: Int)
    case cancelReconnectTimer
    case sendWrapUp
    case finalize(SpeakingEndReason)
}

public struct SpeakingCallState: Equatable, Sendable {
    public private(set) var phase: SpeakingCallPhase = .idle
    public private(set) var reconnectAttempts = 0
    public private(set) var resumptionHandle: String?
    public private(set) var hasBeenLive = false

    private var audioIsRunning = false
    private var reconnectTimerIsActive = false
    private var hasFinalized = false

    public init() {}

    public mutating func reduce(_ input: SpeakingCallInput) -> [SpeakingCallEffect] {
        guard !phase.isTerminal else { return [] }

        switch phase {
        case .idle:
            guard case .start = input else { return [] }
            phase = .connecting
            return [.openSocket(resumptionHandle: nil)]
        case .connecting:
            return reduceWhileConnecting(input)
        case .live:
            return reduceWhileLive(input)
        case .reconnecting:
            return reduceWhileReconnecting(input)
        case .ended, .failed:
            return []
        }
    }

    private mutating func reduceWhileConnecting(_ input: SpeakingCallInput) -> [SpeakingCallEffect] {
        switch input {
        case .setupComplete:
            phase = .live
            hasBeenLive = true
            audioIsRunning = true
            return [.startAudio, .sendOpeningTrigger]
        case let .connectFailed(failure):
            phase = .failed(failure)
            return [.closeSocket]
        case .learnerEnded:
            phase = .ended(.learnerEnded)
            return [.closeSocket]
        default:
            return []
        }
    }

    private mutating func reduceWhileLive(_ input: SpeakingCallInput) -> [SpeakingCallEffect] {
        switch input {
        case let .resumptionHandle(handle):
            resumptionHandle = handle
            return []
        case .transportDropped:
            return reconnectAfterTransportDrop()
        case .goAway:
            return reconnectAfterGoAway()
        case .wrapUpDue:
            return [.sendWrapUp]
        case .aiRequestedEnd:
            return finish(reason: .aiEnded, phase: .ended(.aiEnded))
        case .learnerEnded:
            return finish(reason: .learnerEnded, phase: .ended(.learnerEnded))
        case .hardLimitReached:
            return finish(reason: .timeLimit, phase: .ended(.timeLimit))
        case .audioInterrupted:
            return finish(reason: .interrupted, phase: .ended(.interrupted))
        case let .connectFailed(failure) where failure.isFatal:
            return finish(reason: .connectionLost, phase: .failed(failure))
        default:
            return []
        }
    }

    private mutating func reconnectAfterTransportDrop() -> [SpeakingCallEffect] {
        reconnectAttempts += 1
        guard reconnectAttempts == 1, let resumptionHandle else {
            return finish(reason: .connectionLost, phase: .ended(.connectionLost))
        }

        phase = .reconnecting
        audioIsRunning = false
        reconnectTimerIsActive = true
        return [
            .stopAudio,
            .startReconnectTimer(seconds: 8),
            .openSocket(resumptionHandle: resumptionHandle)
        ]
    }

    private mutating func reconnectAfterGoAway() -> [SpeakingCallEffect] {
        guard let resumptionHandle else {
            return finish(reason: .connectionLost, phase: .ended(.connectionLost))
        }

        phase = .reconnecting
        reconnectTimerIsActive = true
        return [
            .startReconnectTimer(seconds: 8),
            .openSocket(resumptionHandle: resumptionHandle)
        ]
    }

    private mutating func reduceWhileReconnecting(_ input: SpeakingCallInput) -> [SpeakingCallEffect] {
        switch input {
        case .setupComplete:
            phase = .live
            var effects: [SpeakingCallEffect] = []
            if reconnectTimerIsActive {
                reconnectTimerIsActive = false
                effects.append(.cancelReconnectTimer)
            }
            if !audioIsRunning {
                audioIsRunning = true
                effects.append(.startAudio)
            }
            return effects
        case .reconnectTimedOut:
            return finish(reason: .connectionLost, phase: .ended(.connectionLost))
        case let .connectFailed(failure):
            let terminalPhase: SpeakingCallPhase = failure.isFatal
                ? .failed(failure)
                : .ended(.connectionLost)
            return finish(reason: .connectionLost, phase: terminalPhase)
        case .aiRequestedEnd:
            return finish(reason: .aiEnded, phase: .ended(.aiEnded))
        case .learnerEnded:
            return finish(reason: .learnerEnded, phase: .ended(.learnerEnded))
        case .hardLimitReached:
            return finish(reason: .timeLimit, phase: .ended(.timeLimit))
        case .audioInterrupted:
            return finish(reason: .interrupted, phase: .ended(.interrupted))
        default:
            return []
        }
    }

    private mutating func finish(
        reason: SpeakingEndReason,
        phase terminalPhase: SpeakingCallPhase
    ) -> [SpeakingCallEffect] {
        phase = terminalPhase
        var effects: [SpeakingCallEffect] = []

        if audioIsRunning {
            audioIsRunning = false
            effects.append(.stopAudio)
        }
        effects.append(.closeSocket)

        if reconnectTimerIsActive {
            reconnectTimerIsActive = false
            effects.append(.cancelReconnectTimer)
        }

        if hasBeenLive, !hasFinalized {
            hasFinalized = true
            effects.append(.finalize(reason))
        }

        return effects
    }
}

private extension SpeakingCallPhase {
    var isTerminal: Bool {
        switch self {
        case .ended, .failed:
            true
        case .idle, .connecting, .live, .reconnecting:
            false
        }
    }
}

private extension SpeakingCallFailure {
    var isFatal: Bool {
        self == .unauthorized || self == .quotaExceeded
    }
}
