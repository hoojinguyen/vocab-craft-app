import Foundation

struct AnySpeakingClock: Sendable {
    private let readNow: @Sendable () -> AnySpeakingInstant
    private let sleepFor: @Sendable (Duration) async throws -> Void

    init<C: Clock>(_ clock: C) where C.Duration == Duration {
        readNow = {
            AnySpeakingInstant(clock.now) { deadline in
                try await clock.sleep(until: deadline, tolerance: nil)
            }
        }
        sleepFor = { duration in
            try await clock.sleep(until: clock.now.advanced(by: duration), tolerance: nil)
        }
    }

    var now: AnySpeakingInstant { readNow() }

    func sleep(for duration: Duration) async throws {
        try await sleepFor(duration)
    }

    func sleep(until instant: AnySpeakingInstant) async throws {
        try await instant.sleepUntil()
    }
}

struct AnySpeakingInstant: @unchecked Sendable {
    private let value: Any
    private let durationTo: @Sendable (Any) -> Duration
    private let advance: @Sendable (Duration) -> AnySpeakingInstant
    private let sleep: @Sendable () async throws -> Void

    init<I: InstantProtocol>(
        _ instant: I,
        sleepUntil: @escaping @Sendable (I) async throws -> Void
    ) where I.Duration == Duration {
        value = instant
        durationTo = { other in
            guard let otherInstant = other as? I else {
                preconditionFailure("Clock instant types must match")
            }
            return instant.duration(to: otherInstant)
        }
        advance = { duration in
            AnySpeakingInstant(instant.advanced(by: duration), sleepUntil: sleepUntil)
        }
        sleep = { try await sleepUntil(instant) }
    }

    func duration(to other: AnySpeakingInstant) -> Duration { durationTo(other.value) }

    func advanced(by duration: Duration) -> AnySpeakingInstant { advance(duration) }

    func sleepUntil() async throws {
        try await sleep()
    }
}
