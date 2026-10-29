import Foundation

/// Opens, sends messages to, and closes a Gemini Live session.
public protocol LiveTransport: Sendable {
    /// Opens the socket and returns incoming server messages as JSON data.
    func connect(apiKey: String) async throws -> AsyncThrowingStream<Data, Error>
    /// Sends one encoded client message over the open socket.
    func send(_ message: LiveClientMessage) async throws
    /// Closes the socket and ends its incoming message stream.
    func close() async
}
