import Foundation

/// Detects conversational silence using a dual-phase timeout (initial wait vs. trailing silence)
/// and triggers an auto-stop callback after a specified duration of inactivity.
public final class SilenceDetector: @unchecked Sendable {
    private let initialSilenceDuration: Duration
    private let trailingSilenceDuration: Duration
    private let firesSilenceOnInitialTimeout: Bool
    private let onSilence: @Sendable () -> Void
    private let lock = NSLock()
    private var timerTask: Task<Void, Never>?
    private var hasRegisteredActivity = false
    private var isStandby = false

    /// Indicates whether the silence detector is in standby mode after initial silence elapsed without speech.
    public var isInStandby: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isStandby
    }

    /// Alias for `isInStandby`.
    public var isStandbyMode: Bool {
        isInStandby
    }

    /// Initializes a dual-phase silence detector.
    ///
    /// - Parameters:
    ///   - initialSilenceDuration: Duration to wait before first speech before timeout or entering standby (default: 5.0s).
    ///   - trailingSilenceDuration: Inactivity duration after speech activity before auto-stopping (default: 1.3s).
    ///   - firesSilenceOnInitialTimeout: Whether onSilence fires when initial silence expires without speech (default: true).
    ///     When false, enters standby mode instead of firing onSilence.
    ///   - onSilence: Callback invoked when silence threshold elapses.
    public init(
        initialSilenceDuration: Duration = .seconds(5),
        trailingSilenceDuration: Duration = .milliseconds(1300),
        firesSilenceOnInitialTimeout: Bool = true,
        onSilence: @escaping @Sendable () -> Void
    ) {
        self.initialSilenceDuration = initialSilenceDuration
        self.trailingSilenceDuration = trailingSilenceDuration
        self.firesSilenceOnInitialTimeout = firesSilenceOnInitialTimeout
        self.onSilence = onSilence
    }

    /// Convenience initializer using default 5s initial silence and custom trailing silence duration.
    public convenience init(
        silenceDuration: Duration = .milliseconds(1300),
        firesSilenceOnInitialTimeout: Bool = true,
        onSilence: @escaping @Sendable () -> Void
    ) {
        self.init(
            initialSilenceDuration: .seconds(5),
            trailingSilenceDuration: silenceDuration,
            firesSilenceOnInitialTimeout: firesSilenceOnInitialTimeout,
            onSilence: onSilence
        )
    }

    deinit {
        cancel()
    }

    /// Arms the silence detector, starting the initial silence countdown.
    /// If no speech activity is registered before the initial duration expires:
    /// - If `firesSilenceOnInitialTimeout` is true, fires `onSilence`.
    /// - If `firesSilenceOnInitialTimeout` is false, enters standby mode without firing `onSilence`.
    public func arm() {
        lock.lock()
        timerTask?.cancel()
        hasRegisteredActivity = false
        isStandby = false
        let duration = initialSilenceDuration

        timerTask = Task { [weak self] in
            do {
                try await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                self?.handleInitialTimeout()
            } catch {
                // Cancelled
            }
        }
        lock.unlock()
    }

    private func handleInitialTimeout() {
        var shouldFireCallback = false
        lock.withLock {
            guard !hasRegisteredActivity else { return }
            if firesSilenceOnInitialTimeout {
                shouldFireCallback = true
            } else {
                isStandby = true
            }
        }
        if shouldFireCallback {
            onSilence()
        }
    }

    /// Registers acoustic or speech activity, switching to or resetting the trailing silence timer.
    /// Exits standby mode if currently in standby.
    public func registerActivity() {
        lock.lock()
        timerTask?.cancel()
        hasRegisteredActivity = true
        isStandby = false
        let duration = trailingSilenceDuration
        let callback = onSilence

        timerTask = Task {
            do {
                try await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                callback()
            } catch {
                // Cancelled
            }
        }
        lock.unlock()
    }

    /// Cancels any pending silence timer and resets state.
    public func cancel() {
        lock.lock()
        timerTask?.cancel()
        timerTask = nil
        hasRegisteredActivity = false
        isStandby = false
        lock.unlock()
    }
}
