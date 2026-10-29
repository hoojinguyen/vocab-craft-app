import Foundation

/// A Gemini Live WebSocket transport backed by URLSession.
public actor URLSessionLiveTransport: LiveTransport {
    private static let endpoint = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"

    private var session: URLSession?
    private var sessionDelegate: LiveWebSocketSessionDelegate?
    private var webSocket: URLSessionWebSocketTask?
    private var incoming: AsyncThrowingStream<Data, Error>.Continuation?
    private var receiver: Task<Void, Never>?

    /// Creates a transport that owns one active URLSession WebSocket at a time.
    public init() {}

    public func connect(apiKey: String) async throws -> AsyncThrowingStream<Data, Error> {
        await close()

        guard var components = URLComponents(string: Self.endpoint) else {
            throw LiveTransportError.network
        }
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else {
            throw LiveTransportError.network
        }

        let delegate = LiveWebSocketSessionDelegate { [weak self] statusCode in
            Task { await self?.handleHandshakeFailure(statusCode: statusCode) }
        }
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let webSocket = session.webSocketTask(with: url)
        let (stream, continuation) = AsyncThrowingStream<Data, Error>.makeStream()
        self.session = session
        sessionDelegate = delegate
        self.webSocket = webSocket
        self.incoming = continuation
        continuation.onTermination = { [weak webSocket] termination in
            if case .cancelled = termination {
                webSocket?.cancel(with: .goingAway, reason: nil)
            }
        }
        webSocket.resume()
        receiver = Task { [weak self] in
            await self?.receiveMessages(from: webSocket)
        }
        return stream
    }

    public func send(_ message: LiveClientMessage) async throws {
        guard let webSocket else {
            throw LiveTransportError.closed(code: 1006, reason: "WebSocket is not connected")
        }
        do {
            let data = try message.encoded()
            guard let text = String(data: data, encoding: .utf8) else {
                throw LiveTransportError.network
            }
            try await webSocket.send(.string(text))
        } catch {
            let statusCode = (webSocket.response as? HTTPURLResponse)?.statusCode
            throw LiveTransportError.map(error, statusCode: statusCode)
        }
    }

    public func close() async {
        receiver?.cancel()
        receiver = nil
        if let webSocket {
            webSocket.cancel(with: .normalClosure, reason: nil)
        }
        webSocket = nil
        incoming?.finish()
        incoming = nil
        session?.invalidateAndCancel()
        session = nil
        sessionDelegate = nil
    }

    private func receiveMessages(from webSocket: URLSessionWebSocketTask) async {
        do {
            while !Task.isCancelled {
                let message = try await webSocket.receive()
                let data: Data
                switch message {
                case let .data(binary):
                    data = binary
                case let .string(text):
                    data = Data(text.utf8)
                @unknown default:
                    continue
                }
                incoming?.yield(data)
            }
        } catch {
            guard !Task.isCancelled else { return }
            let reason = webSocket.closeReason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            if webSocket.closeCode != .invalid {
                incoming?.finish(throwing: LiveTransportError.map(closeCode: Int(webSocket.closeCode.rawValue), reason: reason))
            } else {
                let statusCode = (webSocket.response as? HTTPURLResponse)?.statusCode
                incoming?.finish(throwing: LiveTransportError.map(error, statusCode: statusCode))
            }
            incoming = nil
            self.webSocket = nil
            session?.invalidateAndCancel()
            session = nil
            sessionDelegate = nil
        }
    }

    private func handleHandshakeFailure(statusCode: Int) {
        let error: LiveTransportError
        switch statusCode {
        case 401, 403:
            error = .unauthorized
        case 429:
            error = .quotaExceeded
        default:
            error = .network
        }
        incoming?.finish(throwing: error)
        incoming = nil
        receiver?.cancel()
        receiver = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        session?.invalidateAndCancel()
        session = nil
        sessionDelegate = nil
    }
}

// URLSession invokes this delegate across queues; its only stored value is an immutable Sendable closure.
private final class LiveWebSocketSessionDelegate: NSObject, URLSessionWebSocketDelegate, @unchecked Sendable {
    private let onHandshakeFailure: @Sendable (Int) -> Void

    init(onHandshakeFailure: @escaping @Sendable (Int) -> Void) {
        self.onHandshakeFailure = onHandshakeFailure
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let response = task.response as? HTTPURLResponse,
              response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 429 else { return }
        onHandshakeFailure(response.statusCode)
    }
}
