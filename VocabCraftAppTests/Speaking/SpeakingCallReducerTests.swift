import Testing
@testable import VocabCraftApp

@Suite("Speaking call state reducer")
struct SpeakingCallReducerTests {
    @Test func startOpensSocketWithoutResumptionHandle() {
        var state = SpeakingCallState()

        #expect(state.reduce(.start) == [.openSocket(resumptionHandle: nil)])
        #expect(state.phase == .connecting)
        #expect(state.reduce(.start).isEmpty)
    }

    @Test func initialSetupStartsAudioAndSendsOpeningTriggerOnce() {
        var state = connectingState()

        #expect(state.reduce(.setupComplete) == [.startAudio, .sendOpeningTrigger])
        #expect(state.phase == .live)
        #expect(state.hasBeenLive)
        #expect(state.reduce(.setupComplete).isEmpty)
    }

    @Test func connectionFailureBeforeFirstLiveClosesWithoutFinalizing() {
        var state = connectingState()

        #expect(state.reduce(.connectFailed(.network)) == [.closeSocket])
        #expect(state.phase == .failed(.network))
        #expect(!state.hasBeenLive)
    }

    @Test func learnerCanEndBeforeFirstLiveWithoutFinalizing() {
        var state = connectingState()

        #expect(state.reduce(.learnerEnded) == [.closeSocket])
        #expect(state.phase == .ended(.learnerEnded))
    }

    @Test func liveStateStoresResumptionHandleWithoutEffects() {
        var state = liveState()

        #expect(state.reduce(.resumptionHandle("resume-1")).isEmpty)
        #expect(state.resumptionHandle == "resume-1")
    }

    @Test func firstTransportDropStopsAudioAndStartsSingleReconnect() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))

        #expect(state.reduce(.transportDropped) == [
            .stopAudio,
            .startReconnectTimer(seconds: 8),
            .openSocket(resumptionHandle: "resume-1")
        ])
        #expect(state.phase == .reconnecting)
        #expect(state.reconnectAttempts == 1)
    }

    @Test func secondTransportDropEndsAndFinalizesWithoutOpeningAnotherSocket() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.transportDropped)
        _ = state.reduce(.setupComplete)

        let effects = state.reduce(.transportDropped)

        #expect(effects == [.stopAudio, .closeSocket, .finalize(.connectionLost)])
        #expect(!effects.contains(.openSocket(resumptionHandle: nil)))
        #expect(state.phase == .ended(.connectionLost))
        #expect(state.reconnectAttempts == 2)
    }

    @Test func transportDropWithoutHandleEndsInsteadOfStartingFreshConversation() {
        var state = liveState()

        let effects = state.reduce(.transportDropped)

        #expect(effects == [.stopAudio, .closeSocket, .finalize(.connectionLost)])
        #expect(!effects.contains(.openSocket(resumptionHandle: nil)))
        #expect(state.phase == .ended(.connectionLost))
        #expect(state.reconnectAttempts == 1)
    }

    @Test func goAwayReconnectsWithHandleWithoutStoppingAudioOrCountingDrop() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))

        #expect(state.reduce(.goAway) == [
            .startReconnectTimer(seconds: 8),
            .openSocket(resumptionHandle: "resume-1")
        ])
        #expect(state.phase == .reconnecting)
        #expect(state.reconnectAttempts == 0)
    }

    @Test func goAwayWithoutHandleEndsWithoutOpeningFreshConversation() {
        var state = liveState()

        let effects = state.reduce(.goAway)

        #expect(effects == [.stopAudio, .closeSocket, .finalize(.connectionLost)])
        #expect(!effects.contains(.openSocket(resumptionHandle: nil)))
        #expect(state.phase == .ended(.connectionLost))
        #expect(state.reconnectAttempts == 0)
    }

    @Test func reconnectSetupRestartsStoppedAudioWithoutOpeningTrigger() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.transportDropped)

        #expect(state.reduce(.setupComplete) == [.cancelReconnectTimer, .startAudio])
        #expect(state.phase == .live)
        #expect(state.reconnectAttempts == 1)
    }

    @Test func reconnectSetupAfterGoAwayKeepsRunningAudioAndOmitsOpeningTrigger() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.goAway)

        #expect(state.reduce(.setupComplete) == [.cancelReconnectTimer])
        #expect(state.phase == .live)
        #expect(state.reconnectAttempts == 0)
    }

    @Test func reconnectTimeoutAfterDroppedTransportFinalizesLostCallOnce() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.transportDropped)

        #expect(state.reduce(.reconnectTimedOut) == [
            .closeSocket,
            .cancelReconnectTimer,
            .finalize(.connectionLost)
        ])
        #expect(state.phase == .ended(.connectionLost))
        #expect(state.reduce(.reconnectTimedOut).isEmpty)
    }

    @Test func reconnectTimeoutAfterGoAwayStopsStillRunningAudio() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.goAway)

        #expect(state.reduce(.reconnectTimedOut) == [
            .stopAudio,
            .closeSocket,
            .cancelReconnectTimer,
            .finalize(.connectionLost)
        ])
        #expect(state.phase == .ended(.connectionLost))
    }

    @Test func reconnectConnectionFailureFinalizesLostCall() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.goAway)

        #expect(state.reduce(.connectFailed(.network)) == [
            .stopAudio,
            .closeSocket,
            .cancelReconnectTimer,
            .finalize(.connectionLost)
        ])
        #expect(state.phase == .ended(.connectionLost))
    }

    @Test func wrapUpKeepsLiveCallActive() {
        var state = liveState()

        #expect(state.reduce(.wrapUpDue) == [.sendWrapUp])
        #expect(state.phase == .live)
    }

    @Test(arguments: [
        (SpeakingCallInput.aiRequestedEnd, SpeakingEndReason.aiEnded),
        (.learnerEnded, .learnerEnded),
        (.hardLimitReached, .timeLimit),
        (.audioInterrupted, .interrupted)
    ])
    func terminalLiveInputStopsAudioClosesAndFinalizes(
        input: SpeakingCallInput,
        reason: SpeakingEndReason
    ) {
        var state = liveState()

        #expect(state.reduce(input) == [.stopAudio, .closeSocket, .finalize(reason)])
        #expect(state.phase == .ended(reason))
    }

    @Test(arguments: [
        (SpeakingCallInput.aiRequestedEnd, SpeakingEndReason.aiEnded),
        (.learnerEnded, .learnerEnded),
        (.hardLimitReached, .timeLimit),
        (.audioInterrupted, .interrupted)
    ])
    func terminalReconnectingInputCancelsTimerAndFinalizes(
        input: SpeakingCallInput,
        reason: SpeakingEndReason
    ) {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.goAway)

        #expect(state.reduce(input) == [
            .stopAudio,
            .closeSocket,
            .cancelReconnectTimer,
            .finalize(reason)
        ])
        #expect(state.phase == .ended(reason))
    }

    @Test(arguments: [SpeakingCallFailure.unauthorized, .quotaExceeded])
    func fatalLiveConnectionFailurePreservesFailureAndFinalizesPartialCall(
        failure: SpeakingCallFailure
    ) {
        var state = liveState()

        #expect(state.reduce(.connectFailed(failure)) == [
            .stopAudio,
            .closeSocket,
            .finalize(.connectionLost)
        ])
        #expect(state.phase == .failed(failure))
        #expect(state.reduce(.transportDropped).isEmpty)
    }

    @Test(arguments: [SpeakingCallFailure.unauthorized, .quotaExceeded])
    func fatalReconnectingFailureCancelsTimerAndFinalizesPartialCall(
        failure: SpeakingCallFailure
    ) {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.goAway)

        #expect(state.reduce(.connectFailed(failure)) == [
            .stopAudio,
            .closeSocket,
            .cancelReconnectTimer,
            .finalize(.connectionLost)
        ])
        #expect(state.phase == .failed(failure))
        #expect(state.reduce(.setupComplete).isEmpty)
    }

    @Test func repeatedInterruptionWhileReconnectingFinalizesOnlyOnce() {
        var state = liveState()
        _ = state.reduce(.resumptionHandle("resume-1"))
        _ = state.reduce(.transportDropped)

        let interruption = state.reduce(.audioInterrupted)
        let staleTimeout = state.reduce(.reconnectTimedOut)
        let finalizationCount = [interruption, staleTimeout]
            .flatMap { $0 }
            .filter { if case .finalize = $0 { true } else { false } }
            .count

        #expect(finalizationCount == 1)
        #expect(state.phase == .ended(.interrupted))
    }

    @Test func terminalStateIgnoresAllLaterInputs() {
        var state = liveState()
        _ = state.reduce(.learnerEnded)

        #expect(state.reduce(.start).isEmpty)
        #expect(state.reduce(.transportDropped).isEmpty)
        #expect(state.reduce(.audioInterrupted).isEmpty)
        #expect(state.phase == .ended(.learnerEnded))
    }

    private func connectingState() -> SpeakingCallState {
        var state = SpeakingCallState()
        _ = state.reduce(.start)
        return state
    }

    private func connectedState() -> SpeakingCallState {
        var state = connectingState()
        _ = state.reduce(.setupComplete)
        return state
    }

    private func liveState() -> SpeakingCallState {
        connectedState()
    }
}
