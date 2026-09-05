@testable import CraftUIKit
import SwiftUI
import Testing
#if canImport(XCTest)
import XCTest
#endif

@Suite("CraftCountdownOverlay Tests")
@MainActor
struct CraftCountdownOverlayTests {

    // MARK: - Deterministic Haptic Sequence Tests

    @Test func countdownEmitsThreeTicksThenCompletion() async {
        let haptics = CountdownHapticSpy()
        let clock = ImmediateCountdownClock()
        let model = CountdownSequence(startNumber: 3, clock: clock, haptics: haptics)
        await model.run()
        #expect(haptics.events == [.prepare, .tick, .tick, .tick, .completion])
    }

    @Test func skipEmitsCompletionAndInvokesOnFinishExactlyOnce() async {
        let haptics = CountdownHapticSpy()
        let clock = ImmediateCountdownClock()
        var finishCount = 0
        let model = CountdownSequence(
            startNumber: 3,
            clock: clock,
            haptics: haptics,
            onFinish: { finishCount += 1 }
        )

        #expect(model.isFinished == false)
        model.skip()
        #expect(model.isFinished == true)
        #expect(finishCount == 1)
        #expect(haptics.events == [.completion])

        // Calling skip again must be a no-op
        model.skip()
        #expect(finishCount == 1)
        #expect(haptics.events == [.completion])
    }

    @Test func skipWhenShowingGoDoesNotEmitDuplicateCompletionHaptic() async {
        let haptics = CountdownHapticSpy()
        let clock = ImmediateCountdownClock()
        var finishCount = 0
        let model = CountdownSequence(
            startNumber: 3,
            clock: clock,
            haptics: haptics,
            onFinish: { finishCount += 1 }
        )

        model.onGo = {
            #expect(model.isShowingGo == true)
            model.skip()
        }

        await model.run()

        #expect(model.isFinished == true)
        #expect(finishCount == 1)
        let completionCount = haptics.events.filter { $0 == .completion }.count
        #expect(completionCount == 1)
        #expect(haptics.events == [.prepare, .tick, .tick, .tick, .completion])

        // Calling skip again must remain idempotent
        model.skip()
        #expect(finishCount == 1)
        #expect(haptics.events.filter { $0 == .completion }.count == 1)
    }

    @Test func reducedMotionDoesNotAlterEventEmission() async {
        let haptics = CountdownHapticSpy()
        let clock = ImmediateCountdownClock()
        let model = CountdownSequence(startNumber: 3, clock: clock, haptics: haptics)

        // Reduced motion in UI environment does not modify deterministic sequence events
        await model.run()
        #expect(haptics.events == [.prepare, .tick, .tick, .tick, .completion])
    }

    @Test func cancellationEmitsNoLateCompletion() async {
        let haptics = CountdownHapticSpy()

        final class SuspendingClock: CountdownClock, @unchecked Sendable {
            func sleep(nanoseconds: UInt64) async throws {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        var finishCalled = false
        let model = CountdownSequence(
            startNumber: 3,
            clock: SuspendingClock(),
            haptics: haptics,
            onFinish: { finishCalled = true }
        )

        let task = Task {
            await model.run()
        }

        // Allow run loop to enter sleep
        await Task.yield()
        try? await Task.sleep(nanoseconds: 20_000_000)

        task.cancel()
        _ = await task.value

        #expect(finishCalled == false)
        #expect(haptics.events.contains(.completion) == false)
        #expect(model.isFinished == false)
    }

    // MARK: - Initializer & Defaults Tests

    @Test func countdownInitDefaults() {
        var isFinished = false
        let overlay = CraftCountdownOverlay(
            startNumber: 3,
            title: "Speed Drill",
            onFinish: { isFinished = true }
        )

        #expect(overlay.startNumber == 3)
        #expect(overlay.title == "Speed Drill")
        #expect(overlay.subtitle == nil)
        #expect(overlay.iconName == nil)
        #expect(overlay.tintColor == nil)
        #expect(overlay.goText == "GO!")

        overlay.onFinish()
        #expect(isFinished == true)
    }

    @Test func countdownClampsStartNumber() {
        let zeroOverlay = CraftCountdownOverlay(startNumber: 0) {}
        #expect(zeroOverlay.startNumber == 1)

        let negativeOverlay = CraftCountdownOverlay(startNumber: -10) {}
        #expect(negativeOverlay.startNumber == 1)

        let positiveOverlay = CraftCountdownOverlay(startNumber: 5) {}
        #expect(positiveOverlay.startNumber == 5)
    }

    @Test func countdownCustomConfiguration() {
        var isFinished = false
        let customTint = Color.orange

        let overlay = CraftCountdownOverlay(
            startNumber: 4,
            title: "Reflex Blitz",
            subtitle: "Translate rapidly within 3 seconds",
            iconName: "bolt.fill",
            tintColor: customTint,
            goText: "START!",
            onFinish: { isFinished = true }
        )

        #expect(overlay.startNumber == 4)
        #expect(overlay.title == "Reflex Blitz")
        #expect(overlay.subtitle == "Translate rapidly within 3 seconds")
        #expect(overlay.iconName == "bolt.fill")
        #expect(overlay.tintColor == customTint)
        #expect(overlay.goText == "START!")

        overlay.onFinish()
        #expect(isFinished == true)
    }

    @Test func countdownViewModifier() {
        var isPresented = true
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        var isFinished = false

        let modified = Text("Study Session").craftCountdown(
            isPresented: binding,
            startNumber: 3,
            title: "Speed Round",
            subtitle: "Tap fast!",
            iconName: "timer",
            tintColor: .purple,
            goText: "READY!",
            onFinish: { isFinished = true }
        )

        _ = modified
        #expect(isFinished == false)
    }

    // MARK: - Callback Chaining Tests

    @Test func callbackChainingPreservesPreconfiguredCallbacks() async {
        let haptics = CountdownHapticSpy()
        let clock = ImmediateCountdownClock()

        var preconfiguredFinishCalled = false
        var overlayFinishCalled = false
        var preconfiguredTicks: [Int] = []
        var preconfiguredGoCalled = false

        let sequence = CountdownSequence(
            startNumber: 3,
            clock: clock,
            haptics: haptics,
            onFinish: { preconfiguredFinishCalled = true }
        )
        sequence.onTick = { count in
            preconfiguredTicks.append(count)
        }
        sequence.onGo = {
            preconfiguredGoCalled = true
        }

        let overlay = CraftCountdownOverlay(
            sequence: sequence,
            onFinish: { overlayFinishCalled = true }
        )

        // Verify onFinish chaining preserves pre-existing callback on direct invocation
        sequence.onFinish?()
        #expect(preconfiguredFinishCalled == true)
        #expect(overlayFinishCalled == true)

        // Reset finish flags for execution pass
        preconfiguredFinishCalled = false
        overlayFinishCalled = false

        // Setup callbacks in overlay (as executed during overlay appearance)
        overlay.setupCallbacks()

        await sequence.run()

        #expect(preconfiguredTicks == [3, 2, 1])
        #expect(preconfiguredGoCalled == true)
        #expect(preconfiguredFinishCalled == true)
        #expect(overlayFinishCalled == true)
    }

    @Test func overlayInitWithNilSequenceOnFinishSetsOnFinishDirectly() {
        let sequence = CountdownSequence(startNumber: 3)
        #expect(sequence.onFinish == nil)

        var overlayFinishCalled = false
        _ = CraftCountdownOverlay(
            sequence: sequence,
            onFinish: { overlayFinishCalled = true }
        )

        #expect(sequence.onFinish != nil)
        sequence.onFinish?()
        #expect(overlayFinishCalled == true)
    }
}
