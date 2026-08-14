import Foundation

/// Detects conversational silence and triggers an auto-stop callback after a specified duration of inactivity.
public final class SilenceDetector: @unchecked Sendable {
    private let silenceDuration: Duration
    private let onSilence: @Sendable () -> Void
    private let lock = NSLock()
    private var timerTask: Task<Void, Never>?

    /// Initializes a silence detector with a specified silence duration.
    ///
    /// - Parameters:
    ///   - silenceDuration: Inactivity duration before firing silence callback (default: 1.3s).
    ///   - onSilence: Callback invoked when silence threshold elapses.
    public init(
        silenceDuration: Duration = .milliseconds(1300),
        onSilence: @escaping @Sendable () -> Void
    ) {
        self.silenceDuration = silenceDuration
        self.onSilence = onSilence
    }

    deinit {
        cancel()
    }

    /// Registers acoustic or speech activity, resetting the silence debounce timer.
    public func registerActivity() {
        lock.lock()
        timerTask?.cancel()
        let duration = silenceDuration
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
