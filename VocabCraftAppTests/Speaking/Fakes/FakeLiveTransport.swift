import Foundation
@testable import VocabCraftApp

actor FakeLiveTransport: LiveTransport {
    private var continuation: AsyncThrowingStream<Data, Error>.Continuation?
    private var connectError: LiveTransportError?
    private var shouldSuspendWrapUp = false
    private var wrapUpSendContinuation: CheckedContinuation<Void, Never>?
    private var didStartWrapUpSend = false
    private(set) var sent: [LiveClientMessage] = []
    private(set) var connectCount = 0
    private(set) var closeCount = 0

    init(connectError: LiveTransportError? = nil) {
        self.connectError = connectError
    }

    func connect(apiKey: String) async throws -> AsyncThrowingStream<Data, Error> {
        connectCount += 1
        if let connectError {
            self.connectError = nil
            throw connectError
        }
        continuation?.finish()
        let (stream, nextContinuation) = AsyncThrowingStream<Data, Error>.makeStream()
        continuation = nextContinuation
        return stream
    }

    func send(_ message: LiveClientMessage) async throws {
        sent.append(message)
        guard case let .hiddenText(text) = message,
              text == SpeakingPromptBuilder.wrapUpRequest,
              shouldSuspendWrapUp else { return }
        didStartWrapUpSend = true
        await withCheckedContinuation { continuation in
            wrapUpSendContinuation = continuation
        }
    }

    func close() async {
        closeCount += 1
        continuation?.finish()
        continuation = nil
    }

    func emit(_ data: Data) {
        continuation?.yield(data)
    }

    func fail(_ error: Error) {
        continuation?.finish(throwing: error)
        continuation = nil
    }

    func suspendWrapUpSend() {
        shouldSuspendWrapUp = true
    }

    func wrapUpSendStarted() -> Bool {
        didStartWrapUpSend
    }

    func resumeWrapUpSend() {
        shouldSuspendWrapUp = false
        wrapUpSendContinuation?.resume()
        wrapUpSendContinuation = nil
    }
}
