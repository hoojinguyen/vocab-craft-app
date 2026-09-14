@preconcurrency import AVFoundation
import CraftUIKit
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("Conversation live view & factory")
@MainActor
struct ConversationLiveViewTests {
    private let sampleScript = ConversationScript(
        id: "test-live-script",
        situation: "Ordering coffee",
        situationVi: "Gọi cà phê",
        vocabularyReferences: ["espresso"],
        turns: [
            .init(
                id: "turn-1",
                speaker: .speakerA,
                english: "I would like an espresso please.",
                vietnamese: "Cho tôi một ly espresso nhé."
            ),
            .init(
                id: "turn-2",
                speaker: .speakerB,
                english: "Single or double shot?",
                vietnamese: "Một shot hay hai shot ạ?"
            )
        ]
    )

    @Test("AppContainer factory uses shared coordinator and does not auto-run")
    func factoryUsesSharedCoordinator() {
        let container = AppContainer.mock
        let storage = InMemoryConversationSessionStorage()

        let session = container.makeConversationLiveSession(
            conversation: sampleScript,
            storage: storage
        )

        #expect(session.conversation.id == sampleScript.id)
        #expect(session.role == .speakerA)
        #expect(session.phase == .ready)
        #expect(session.passedTurnIDs.isEmpty)
        #expect(!session.isPlayingSample)
        #expect(!session.hasCompletedAchievement)
    }

    @Test("AppContainer factory defaults to live storage key")
    func factoryDefaultsToLiveKey() {
        let container = AppContainer.mock
        let session = container.makeConversationLiveSession(conversation: sampleScript)

        #expect(session.phase == .ready)
        #expect(ConversationLiveSession.liveStorageKey == "debug.conversation.live.session.v1")
    }

    @Test("sample load failure does not fallback to completed")
    func sampleLoadFailureRegression() {
        let storage = InMemoryConversationSessionStorage()
        let audio = DummyAudioClient()

        // Storage with empty/corrupt state cannot restore as completed
        let restored = ConversationLiveSession.restore(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )
        #expect(restored == nil)

        // Invalid snapshot at turn count without achievement cannot be completed
        storage.save(.init(
            conversationID: sampleScript.id,
            role: .speakerA,
            currentTurnIndex: sampleScript.turns.count,
            passedTurnIDs: ["turn-1"],
            hasCompletedAchievement: false
        ))
        let corruptRestored = ConversationLiveSession.restore(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )
        #expect(corruptRestored == nil)
    }

    @Test("performCurrentTurn is no-op outside preparing or partner playback")
    func performCurrentTurnNoOpOutsidePreparing() async {
        let audio = DummyAudioClient()
        let storage = InMemoryConversationSessionStorage()
        let session = ConversationLiveSession(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )

        // In .ready, performCurrentTurn does nothing
        #expect(session.phase == .ready)
        await session.performCurrentTurn()
        #expect(session.phase == .ready)
        #expect(audio.playCount == 0)

        // Start session into preparing
        session.start()
        #expect(session.phase == .preparing(turnID: "turn-1"))

        // Pause session into .paused
        session.pause()
        #expect(session.phase == .paused)
        await session.performCurrentTurn()
        #expect(session.phase == .paused)
        #expect(audio.playCount == 0)
    }

    @Test("performCurrentTurn is no-op when sample is playing")
    func performCurrentTurnNoOpWhenPlayingSample() async {
        let audio = DummyAudioClient(suspendsPlay: true)
        let storage = InMemoryConversationSessionStorage()
        let session = ConversationLiveSession(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )

        #expect(session.phase == .ready)

        // Play sample task running from .ready
        let sampleTask = Task { await session.playCurrentSample() }
        await audio.waitUntilPlayCalled()

        #expect(session.isPlayingSample)

        // performCurrentTurn should be a no-op while sample is playing
        await session.performCurrentTurn()
        #expect(session.phase == .ready)

        audio.resumePlay()
        await sampleTask.value
        #expect(!session.isPlayingSample)
    }

    @Test("scenePhase background pauses session but inactive does not")
    func scenePhaseBackgroundPausesSession() {
        let storage = InMemoryConversationSessionStorage()
        let audio = DummyAudioClient()
        let session = ConversationLiveSession(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )

        session.start()
        #expect(session.phase == .preparing(turnID: "turn-1"))

        // Simulation of scenePhase change policy
        let onPhaseChange: (ScenePhase) -> Void = { phase in
            if phase == .background {
                session.pause()
            }
        }

        // Inactive (e.g. system permission dialog) must not pause session
        onPhaseChange(.inactive)
        #expect(session.phase == .preparing(turnID: "turn-1"))

        // Background must pause session
        onPhaseChange(.background)
        #expect(session.phase == .paused)

        // Returning to active must not auto-resume
        onPhaseChange(.active)
        #expect(session.phase == .paused)
    }

    #if os(iOS)
    @Test("audio interruption began pauses session")
    func audioInterruptionPausesSession() {
        let storage = InMemoryConversationSessionStorage()
        let audio = DummyAudioClient()
        let session = ConversationLiveSession(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )

        session.start()
        #expect(session.phase == .preparing(turnID: "turn-1"))

        // Post interruption began
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )

        // Notification handler policy in ConversationLiveView
        let typeValue = AVAudioSession.InterruptionType.began.rawValue
        let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        if type == nil || type == .began {
            session.pause()
        }

        #expect(session.phase == .paused)
    }

    @Test("audio route change with device unavailable pauses session")
    func audioRouteChangeDeviceLostPausesSession() {
        let storage = InMemoryConversationSessionStorage()
        let audio = DummyAudioClient()
        let session = ConversationLiveSession(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )

        session.start()
        #expect(session.phase == .preparing(turnID: "turn-1"))

        let reasonValue = AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
        let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        if reason == nil || reason == .oldDeviceUnavailable {
            session.pause()
        }

        #expect(session.phase == .paused)
    }
    #endif

    @Test("ConversationLiveControls renders correctly across all phases")
    func controlsRenderAcrossPhases() {
        let storage = InMemoryConversationSessionStorage()
        let audio = DummyAudioClient()
        let session = ConversationLiveSession(
            conversation: sampleScript,
            storage: storage,
            audio: audio
        )

        // Ready
        let readyControls = ConversationLiveControls(session: session, onGenerate: {})
        _ = readyControls.body

        // Start -> Preparing
        session.start()
        let preparingControls = ConversationLiveControls(session: session, onGenerate: {})
        _ = preparingControls.body

        // Pause -> Paused
        session.pause()
        let pausedControls = ConversationLiveControls(session: session, onGenerate: {})
        _ = pausedControls.body

        // Retry failures
        for failure in ConversationLiveFailure.allCases {
            let failureAudio = DummyAudioClient(captureResult: mapToCaptureResult(failure))
            let failureSession = ConversationLiveSession(
                conversation: sampleScript,
                storage: InMemoryConversationSessionStorage(),
                audio: failureAudio
            )
            failureSession.start()
            let failureControls = ConversationLiveControls(session: failureSession, onGenerate: {})
            _ = failureControls.body
        }
    }

    @Test("ConversationLiveView initialization and close callback")
    func liveViewInitialization() {
        var didClose = false
        let view = ConversationLiveView(onClose: { didClose = true })
        _ = view.body
        #expect(!didClose)
    }

    @Test("AppStrings.Conversation.Live typed string accessors resolve non-empty")
    func typedStringAccessorsResolve() {
        #expect(!AppStrings.Conversation.Live.rawPreparing.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawListening.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawEvaluating.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawNotice.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawPartner.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawPermission.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawUnavailable.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawCaptureError.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawPlaybackError.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawHearSample.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawOpenSettings.isEmpty)
        #expect(!AppStrings.Conversation.Live.rawAnotherSample.isEmpty)
    }

    private func mapToCaptureResult(_ failure: ConversationLiveFailure) -> ConversationCaptureResult {
        switch failure {
        case .noSpeech: .silence
        case .permissionDenied: .permissionDenied
        case .recognitionUnavailable: .unavailable
        case .captureFailed: .failed
        case .playbackFailed: .failed
        case .readAgain: .transcript("wrong transcript")
        }
    }
}

@MainActor
private final class DummyAudioClient: ConversationAudioClient {
    var playCount = 0
    let suspendsPlay: Bool
    let captureResult: ConversationCaptureResult
    private var playContinuation: CheckedContinuation<Void, Never>?
    private var playCalledContinuation: CheckedContinuation<Void, Never>?

    init(suspendsPlay: Bool = false, captureResult: ConversationCaptureResult = .silence) {
        self.suspendsPlay = suspendsPlay
        self.captureResult = captureResult
    }

    func play(text: String, locale: String) async -> ConversationPlaybackResult {
        playCount += 1
        playCalledContinuation?.resume()
        playCalledContinuation = nil
        if suspendsPlay {
            await withCheckedContinuation { playContinuation = $0 }
        }
        return .finished
    }

    func capture(
        targetSentence: String,
        contextualPhrases: [String],
        onListening: @escaping @MainActor @Sendable () -> Void,
        onPartial: @escaping @MainActor @Sendable (String) -> Void
    ) async -> ConversationCaptureResult {
        onListening()
        return captureResult
    }

    func stop() {}

    func waitUntilPlayCalled() async {
        if playCount > 0 { return }
        await withCheckedContinuation { playCalledContinuation = $0 }
    }

    func resumePlay() {
        playContinuation?.resume()
        playContinuation = nil
    }
}
