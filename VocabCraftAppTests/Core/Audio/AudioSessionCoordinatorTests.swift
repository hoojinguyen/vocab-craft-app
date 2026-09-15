@preconcurrency import AVFoundation
import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("AudioSessionCoordinator Tests")
struct AudioSessionCoordinatorTests {
    @Test("Capture acquire configures duplex audio, haptics during recording, and speaker routing")
    func captureAcquireConfiguresDuplexAndHaptics() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let lease = try await coordinator.acquire(.speechCapture)

        #expect(lease.intent == .speechCapture)
        #expect(lease.generation == 1)
        #expect(mock.operations == [
            .setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP]),
            .allowHaptics(true),
            .setActive(true, options: []),
            .overrideOutputAudioPort(.speaker)
        ])
    }

    @Test("Playback acquire does not downgrade active capture session")
    func playbackDoesNotDowngradeActiveCapture() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let captureLease = try await coordinator.acquire(.speechCapture)
        #expect(captureLease.intent == .speechCapture)
        let operationsAfterCapture = mock.operations

        let playbackLease = try await coordinator.acquire(.playback)
        #expect(playbackLease.intent == .playback)

        #expect(mock.operations == operationsAfterCapture)
        #expect(!mock.operations.contains { operation in
            if case .setCategory(.playback, _, _) = operation {
                return true
            }
            return false
        })
    }

    @Test("Last capture release restores playback when a playback lease remains")
    func lastCaptureReleaseRestoresPlaybackWhenPlaybackLeaseRemains() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let captureLease = try await coordinator.acquire(.speechCapture)
        let playbackLease = try await coordinator.acquire(.playback)

        await coordinator.release(captureLease)

        #expect(mock.operations == [
            .setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP]),
            .allowHaptics(true),
            .setActive(true, options: []),
            .overrideOutputAudioPort(.speaker),
            .setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        ])

        await coordinator.release(playbackLease)
        #expect(mock.operations.last == .setActive(false, options: [.notifyOthersOnDeactivation]))
    }

    @Test("Stale generation release cannot deactivate a new session")
    func staleGenerationReleaseCannotDeactivateNewSession() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let lease1 = try await coordinator.acquire(.speechCapture)
        #expect(lease1.generation == 1)
        await coordinator.release(lease1)
        #expect(mock.operations.last == .setActive(false, options: [.notifyOthersOnDeactivation]))

        let lease2 = try await coordinator.acquire(.playback)
        #expect(lease2.generation == 2)
        #expect(mock.operations.last == .setActive(true, options: []))

        let operationsBeforeStaleRelease = mock.operations

        // Attempting to release the old lease from generation 1 should be ignored
        await coordinator.release(lease1)
        #expect(mock.operations == operationsBeforeStaleRelease)

        // Fabricated lease with old generation should also be ignored
        let staleLease = AudioSessionLease(id: lease2.id, generation: 1, intent: .playback)
        await coordinator.release(staleLease)
        #expect(mock.operations == operationsBeforeStaleRelease)

        #expect(await coordinator.activeLeaseCount == 1)
    }

    @Test("Duplicate release is idempotent")
    func duplicateReleaseIsIdempotent() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let lease = try await coordinator.acquire(.playback)
        await coordinator.release(lease)

        let operationsAfterFirstRelease = mock.operations
        #expect(operationsAfterFirstRelease.last == .setActive(false, options: [.notifyOthersOnDeactivation]))

        await coordinator.release(lease)
        #expect(mock.operations == operationsAfterFirstRelease)

        await coordinator.release(lease)
        #expect(mock.operations == operationsAfterFirstRelease)
        #expect(await coordinator.activeLeaseCount == 0)
    }

    @Test("Activation failure does not publish lease or leak state")
    func activationFailureDoesNotPublishLease() async throws {
        let mock = MockAudioSessionHardware()
        mock.shouldFailSetActive = true
        let coordinator = AudioSessionCoordinator(hardware: mock)

        await #expect(throws: MockAudioSessionError.self) {
            try await coordinator.acquire(.speechCapture)
        }

        #expect(await coordinator.activeLeaseCount == 0)
        #expect(await coordinator.effectiveIntent == nil)
    }

    @Test("Port override failure does not prevent lease publication")
    func portOverrideFailureDoesNotPreventLeasePublication() async throws {
        let mock = MockAudioSessionHardware()
        mock.shouldFailPortOverride = true
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let lease = try await coordinator.acquire(.speechCapture)

        #expect(lease.intent == .speechCapture)
        #expect(await coordinator.activeLeaseCount == 1)
        #expect(mock.operations.contains(.overrideOutputAudioPort(.speaker)))
    }

    @Test("Dynamic escalation: Concurrent speechCapture and playback leases escalate effective intent to duplexSpeech")
    func concurrentCaptureAndPlaybackEscalatesToDuplex() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let captureLease = try await coordinator.acquire(.speechCapture)
        #expect(await coordinator.effectiveIntent == .speechCapture)

        let playbackLease = try await coordinator.acquire(.playback)
        #expect(await coordinator.effectiveIntent == .duplexSpeech)
        #expect(await coordinator.activeLeaseCount == 2)

        // Releasing playback restores speechCapture
        await coordinator.release(playbackLease)
        #expect(await coordinator.effectiveIntent == .speechCapture)

        await coordinator.release(captureLease)
        #expect(await coordinator.effectiveIntent == nil)
        #expect(mock.operations.last == .setActive(false, options: [.notifyOthersOnDeactivation]))
    }

    @Test("Media services reset invalidates all active leases and emits reset event")
    func mediaServicesResetClearsLeasesAndBroadcastsEvent() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let stream = coordinator.events
        var iterator = stream.makeAsyncIterator()

        let lease = try await coordinator.acquire(.speechCapture)
        #expect(await coordinator.activeLeaseCount == 1)

        // Trigger media services reset
        await coordinator.handleMediaServicesReset()

        #expect(await coordinator.activeLeaseCount == 0)
        #expect(await coordinator.effectiveIntent == nil)
        #expect(await coordinator.currentGeneration > lease.generation)

        let event = await iterator.next()
        #expect(event == .mediaServicesReset)
    }

    @Test("Broadcast event emits to active event stream")
    func broadcastEventEmitsToActiveStream() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let stream = coordinator.events
        var iterator = stream.makeAsyncIterator()

        await coordinator.broadcastEventForTesting(.interruptionBegan)
        let event1 = await iterator.next()
        #expect(event1 == .interruptionBegan)

        await coordinator.broadcastEventForTesting(.interruptionEnded(shouldResume: true))
        let event2 = await iterator.next()
        #expect(event2 == .interruptionEnded(shouldResume: true))

        await coordinator.broadcastEventForTesting(.routeChanged(reason: .newDeviceAvailable))
        let event3 = await iterator.next()
        #expect(event3 == .routeChanged(reason: .newDeviceAvailable))
    }

    #if os(iOS)
    @Test("System interruption notifications are parsed and broadcast correctly")
    func systemInterruptionNotificationsBroadcastCorrectly() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let stream = coordinator.events
        var iterator = stream.makeAsyncIterator()

        // Began
        let beganNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
            ]
        )
        await coordinator.handleInterruption(beganNotification)
        let event1 = await iterator.next()
        #expect(event1 == .interruptionBegan)

        // Ended with shouldResume = true
        let endedResumeNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        await coordinator.handleInterruption(endedResumeNotification)
        let event2 = await iterator.next()
        #expect(event2 == .interruptionEnded(shouldResume: true))

        // Ended with shouldResume = false
        let endedNoResumeNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: UInt(0)
            ]
        )
        await coordinator.handleInterruption(endedNoResumeNotification)
        let event3 = await iterator.next()
        #expect(event3 == .interruptionEnded(shouldResume: false))
    }

    @Test("System route change notifications are parsed and broadcast correctly")
    func systemRouteChangeNotificationsBroadcastCorrectly() async throws {
        let mock = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mock)

        let stream = coordinator.events
        var iterator = stream.makeAsyncIterator()

        let routeChangeNotification = Notification(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
            ]
        )
        await coordinator.handleRouteChange(routeChangeNotification)
        let event1 = await iterator.next()
        #expect(event1 == .routeChanged(reason: .newDeviceAvailable))

        let routeChangeOldDevice = Notification(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
            ]
        )
        await coordinator.handleRouteChange(routeChangeOldDevice)
        let event2 = await iterator.next()
        #expect(event2 == .routeChanged(reason: .oldDeviceUnavailable))

        let routeChangeCategory = Notification(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.categoryChange.rawValue
            ]
        )
        await coordinator.handleRouteChange(routeChangeCategory)
        let event3 = await iterator.next()
        #expect(event3 == .routeChanged(reason: .categoryChange))
    }
    #endif
}

// MARK: - MockAudioSessionHardware

enum MockAudioSessionOperation: Equatable, Sendable {
    case setCategory(AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)
    case allowHaptics(Bool)
    case setActive(Bool, options: AVAudioSession.SetActiveOptions)
    case overrideOutputAudioPort(AVAudioSession.PortOverride)
}

enum MockAudioSessionError: Error, Sendable {
    case simulatedActivationFailure
    case simulatedCategoryFailure
    case simulatedPortOverrideFailure
}

final class MockAudioSessionHardware: AudioSessionHardware, @unchecked Sendable {
    private let lock = NSLock()
    private var _operations: [MockAudioSessionOperation] = []
    var shouldFailSetActive: Bool = false
    var shouldFailSetCategory: Bool = false
    var shouldFailPortOverride: Bool = false

    var operations: [MockAudioSessionOperation] {
        lock.withLock { _operations }
    }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        lock.withLock {
            _operations.append(.setCategory(category, mode: mode, options: options))
        }
        if shouldFailSetCategory {
            throw MockAudioSessionError.simulatedCategoryFailure
        }
    }

    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws {
        lock.withLock {
            _operations.append(.allowHaptics(inValue))
        }
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        lock.withLock {
            _operations.append(.setActive(active, options: options))
        }
        if shouldFailSetActive {
            throw MockAudioSessionError.simulatedActivationFailure
        }
    }

    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws {
        lock.withLock {
            _operations.append(.overrideOutputAudioPort(portOverride))
        }
        if shouldFailPortOverride {
            throw MockAudioSessionError.simulatedPortOverrideFailure
        }
    }
}
#endif
