import Foundation
import Observation
import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Countdown Haptic Driving Protocol

/// Retained feedback interface orchestrating countdown haptic ticks and drill start completion.
@MainActor
public protocol CountdownHapticDriving: AnyObject {
    /// Pre-warms haptic engines before the initial count tick.
    func prepare()

    /// Dispatches an impact tick corresponding to a countdown number.
    ///
    /// - Parameter count: The remaining count value (e.g. 3, 2, 1).
    func tick(count: Int)

    /// Dispatches a completion notification haptic (e.g. on GO! or tap-to-skip).
    func completion()
}

// MARK: - Production Countdown Haptic Driver

/// Production driver that retains `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`
/// across countdown ticks to avoid audio/haptic server spin-up latency on iOS.
@MainActor
public final class CountdownHapticDriver: CountdownHapticDriving {
    public static let shared = CountdownHapticDriver()

    #if os(iOS)
    private let impactGenerator: UIImpactFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator

    public init() {
        self.impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        self.notificationGenerator = UINotificationFeedbackGenerator()
    }

    public func prepare() {
        impactGenerator.prepare()
    }

    public func tick(count: Int) {
        impactGenerator.impactOccurred()
        if count > 1 {
            impactGenerator.prepare()
        }
    }

    public func completion() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }
    #else
    public init() {}
    public func prepare() {}
    public func tick(count: Int) {}
    public func completion() {}
    #endif
}

// MARK: - Countdown Clock

/// Abstract clock protocol providing async sleep for countdown pacing.
public protocol CountdownClock: Sendable {
    func sleep(nanoseconds: UInt64) async throws
}

/// System clock using `Task.sleep(nanoseconds:)`.
public struct SystemCountdownClock: CountdownClock {
    public init() {}

    public func sleep(nanoseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

/// Immediate clock for unit and integration testing without wall-clock delay.
public struct ImmediateCountdownClock: CountdownClock {
    public init() {}

    public func sleep(nanoseconds: UInt64) async throws {
        try Task.checkCancellation()
        await Task.yield()
    }
}

// MARK: - Test Spy & Events

/// Haptic events emitted during countdown sequences.
public enum CountdownHapticEvent: Equatable, Sendable {
    case prepare
    case tick
    case completion
}

/// Test spy recording haptic lifecycle events.
@MainActor
public final class CountdownHapticSpy: CountdownHapticDriving {
    public private(set) var events: [CountdownHapticEvent] = []

    public init() {}

    public func prepare() {
        events.append(.prepare)
    }

    public func tick(count: Int) {
        events.append(.tick)
    }

    public func completion() {
        events.append(.completion)
    }

    public func reset() {
        events.removeAll()
    }
}

// MARK: - Countdown Sequence Model

/// Pure sequence logic managing countdown count, haptic dispatch, timing delays, and skip handling.
@MainActor
@Observable
public final class CountdownSequence {
    public static let defaultTickDelayNanoseconds: UInt64 = 850_000_000
    public static let defaultCompletionDelayNanoseconds: UInt64 = 650_000_000

    public let startNumber: Int
    public private(set) var currentCount: Int
    public private(set) var isShowingGo: Bool = false
    public private(set) var isFinished: Bool = false

    private let clock: CountdownClock
    private let haptics: (any CountdownHapticDriving)?
    public var onFinish: (() -> Void)?
    public var onTick: ((Int) -> Void)?
    public var onGo: (() -> Void)?

    public init(
        startNumber: Int = 3,
        clock: CountdownClock = SystemCountdownClock(),
        haptics: (any CountdownHapticDriving)? = nil,
        onFinish: (() -> Void)? = nil
    ) {
        let clamped = max(1, startNumber)
        self.startNumber = clamped
        self.currentCount = clamped
        self.clock = clock
        self.haptics = haptics ?? CountdownHapticDriver.shared
        self.onFinish = onFinish
    }

    public func run() async {
        guard !isFinished && !Task.isCancelled else { return }

        haptics?.prepare()

        for number in stride(from: startNumber, through: 1, by: -1) {
            guard !Task.isCancelled && !isFinished else { return }
            currentCount = number
            isShowingGo = false
            haptics?.tick(count: number)
            onTick?(number)

            do {
                try await clock.sleep(nanoseconds: Self.defaultTickDelayNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled && !isFinished else { return }
        }

        // Final GO!
        isShowingGo = true
        haptics?.completion()
        onGo?()

        do {
            try await clock.sleep(nanoseconds: Self.defaultCompletionDelayNanoseconds)
        } catch {
            return
        }
        guard !Task.isCancelled && !isFinished else { return }
        isFinished = true
        onFinish?()
    }

    public func skip() {
        guard !isFinished else { return }
        isFinished = true
        haptics?.completion()
        onFinish?()
    }
}

/// Type alias for CountdownSequence adhering to CraftUIKit naming conventions.
public typealias CraftCountdownModel = CountdownSequence
