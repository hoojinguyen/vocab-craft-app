import Foundation

/// Detects conversational silence using a dual-phase timeout (initial wait vs. trailing silence)
/// and triggers an auto-stop callback after a specified duration of inactivity.
public final class SilenceDetector: @unchecked Sendable {
    private let initialSilenceDuration: Duration
    private let trailingSilenceDuration: Duration
    private let onSilence: @Sendable () -> Void
    private let lock = NSLock()
    private var timerTask: Task<Void, Never>?
    private var hasRegisteredActivity = false

    /// Initializes a dual-phase silence detector.
    ///
    /// - Parameters:
    ///   - initialSilenceDuration: Duration to wait before first speech before auto-stopping (default: 5.0s).
    ///   - trailingSilenceDuration: Inactivity duration after speech activity before auto-stopping (default: 1.3s).
    ///   - onSilence: Callback invoked when silence threshold elapses.
    public init(
        initialSilenceDuration: Duration = .seconds(5),
        trailingSilenceDuration: Duration = .milliseconds(1300),
        onSilence: @escaping @Sendable () -> Void
    ) {
        self.initialSilenceDuration = initialSilenceDuration
        self.trailingSilenceDuration = trailingSilenceDuration
        self.onSilence = onSilence
    }

    /// Convenience initializer using default 5s initial silence and custom trailing silence duration.
    public convenience init(
        silenceDuration: Duration = .milliseconds(1300),
        onSilence: @escaping @Sendable () -> Void
    ) {
        self.init(
            initialSilenceDuration: .seconds(5),
            trailingSilenceDuration: silenceDuration,
            onSilence: onSilence
        )
    }

    deinit {
        cancel()
    }

    /// Arms the silence detector, starting the initial silence countdown.
    public func arm() {
        lock.lock()
        timerTask?.cancel()
        hasRegisteredActivity = false
        let duration = initialSilenceDuration
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

    /// Registers acoustic or speech activity, switching to or resetting the trailing silence timer.
    public func registerActivity() {
        lock.lock()
        timerTask?.cancel()
        hasRegisteredActivity = true
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

    /// Cancels any pending silence timer.
    public func cancel() {
        lock.lock()
        timerTask?.cancel()
        timerTask = nil
        lock.unlock()
    }
}
