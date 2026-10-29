import Foundation

/// A decoded event received from the Gemini Live server.
public enum LiveServerEvent: Sendable, Equatable {
    case setupComplete
    case audio(Data)
    case inputTranscript(String)
    case outputTranscript(String)
    case interrupted
    case turnComplete
    case toolCall(id: String, name: String)
    case goAway(timeLeft: TimeInterval?)
    case resumptionUpdate(handle: String?, resumable: Bool)

    /// Decodes one server message into events in the order expected by the call controller.
    public static func decode(_ data: Data) throws -> [LiveServerEvent] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Live message must be a JSON object"))
        }

        if let error = root["error"] as? [String: Any] {
            let status = error["status"] as? String ?? ""
            let message = error["message"] as? String ?? ""
            throw LiveTransportError.map(status: status, message: message, code: error["code"] as? Int)
        }

        var events: [LiveServerEvent] = []
        if root["setupComplete"] != nil {
            events.append(.setupComplete)
        }
        if let serverContent = root["serverContent"] as? [String: Any] {
            if let modelTurn = serverContent["modelTurn"] as? [String: Any],
               let parts = modelTurn["parts"] as? [[String: Any]] {
                for part in parts {
                    guard let inlineData = part["inlineData"] as? [String: Any] else { continue }
                    guard let encoded = inlineData["data"] as? String,
                          let audio = Data(base64Encoded: encoded) else {
                        throw DecodingError.dataCorrupted(.init(
                            codingPath: [],
                            debugDescription: "Live audio part contains invalid base64 data"
                        ))
                    }
                    events.append(.audio(audio))
                }
            }
            appendTranscript(serverContent["outputTranscription"], as: { .outputTranscript($0) }, to: &events)
            appendTranscript(serverContent["inputTranscription"], as: { .inputTranscript($0) }, to: &events)
            if serverContent["interrupted"] as? Bool == true {
                events.append(.interrupted)
            }
            if serverContent["turnComplete"] as? Bool == true {
                events.append(.turnComplete)
            }
        }
        if let toolCall = root["toolCall"] as? [String: Any],
           let calls = toolCall["functionCalls"] as? [[String: Any]] {
            for call in calls {
                guard let id = call["id"] as? String, let name = call["name"] as? String else {
                    throw DecodingError.dataCorrupted(.init(
                        codingPath: [],
                        debugDescription: "Live function call is missing its id or name"
                    ))
                }
                events.append(.toolCall(id: id, name: name))
            }
        }
        if let goAway = root["goAway"] as? [String: Any] {
            events.append(.goAway(timeLeft: duration(goAway["timeLeft"])))
        }
        if let update = root["sessionResumptionUpdate"] as? [String: Any] {
            events.append(.resumptionUpdate(
                handle: update["newHandle"] as? String,
                resumable: update["resumable"] as? Bool ?? false
            ))
        }
        return events
    }

    private static func appendTranscript(
        _ value: Any?,
        as makeEvent: (String) -> LiveServerEvent,
        to events: inout [LiveServerEvent]
    ) {
        guard let transcript = value as? [String: Any], let text = transcript["text"] as? String else { return }
        events.append(makeEvent(text))
    }

    private static func duration(_ value: Any?) -> TimeInterval? {
        if let encoded = value as? String {
            let seconds = encoded.hasSuffix("s") ? String(encoded.dropLast()) : encoded
            return TimeInterval(seconds)
        }
        if let duration = value as? [String: Any] {
            let seconds = duration["seconds"] as? Double ?? 0
            let nanos = duration["nanos"] as? Double ?? 0
            return seconds + nanos / 1_000_000_000
        }
        return nil
    }
}

/// An expected failure while opening or using a Gemini Live WebSocket.
public enum LiveTransportError: Error, Equatable, Sendable {
    case unauthorized
    case quotaExceeded
    case network
    case closed(code: Int, reason: String)

    static func map(status: String, message: String, code: Int? = nil) -> Self {
        let combined = "\(status) \(message)".lowercased()
        if code == 401 || code == 403 || combined.contains("api key") || combined.contains("unauthorized") {
            return .unauthorized
        }
        if code == 429 || combined.contains("resource_exhausted") || combined.contains("quota") {
            return .quotaExceeded
        }
        return .network
    }

    static func map(closeCode: Int, reason: String) -> Self {
        let mapped = map(status: "", message: reason)
        switch mapped {
        case .unauthorized, .quotaExceeded:
            return mapped
        case .network, .closed:
            return .closed(code: closeCode, reason: reason)
        }
    }

    static func map(_ error: Error) -> Self {
        map(error, statusCode: nil)
    }

    static func map(_ error: Error, statusCode: Int?) -> Self {
        if let statusCode {
            switch statusCode {
            case 401, 403:
                return .unauthorized
            case 429:
                return .quotaExceeded
            default:
                break
            }
        }
        if let transportError = error as? Self {
            return transportError
        }
        let nsError = error as NSError
        if let response = nsError.userInfo["NSURLErrorFailingURLResponseErrorKey"] as? HTTPURLResponse {
            if response.statusCode == 401 || response.statusCode == 403 {
                return .unauthorized
            }
            if response.statusCode == 429 {
                return .quotaExceeded
            }
        }
        if nsError.domain == NSURLErrorDomain {
            return .network
        }
        return .network
    }
}
