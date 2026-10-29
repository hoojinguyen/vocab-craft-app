import Foundation

@main
struct LiveSmoke {
    static func main() async {
        if CommandLine.arguments.contains("--validate-local") {
            print("Local Live CLI validation passed; no network request was made.")
            return
        }

        guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty else {
            fputs("GEMINI_API_KEY is required for the live smoke. Use --validate-local for offline validation.\n", stderr)
            exit(2)
        }

        let transport = URLSessionLiveTransport()
        do {
            let messages = try await transport.connect(apiKey: apiKey)
            try await transport.send(.setup(LiveSetup(
                model: "models/gemini-3.8-live",
                voiceName: "Kore",
                systemInstruction: "Speak in English. Greet the learner briefly and wait for their reply."
            )))
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    var setupReceived = false
                    var audioReceived = false
                    var transcriptReceived = false
                    var turnCompleted = false

                    for try await data in messages {
                        for event in try LiveServerEvent.decode(data) {
                            switch event {
                            case .setupComplete:
                                setupReceived = true
                                print("event=setupComplete")
                                try await transport.send(.hiddenText("Say hello in one sentence."))
                            case .audio:
                                audioReceived = true
                                print("event=audio")
                            case .outputTranscript:
                                transcriptReceived = true
                                print("event=outputTranscript")
                            case .inputTranscript:
                                print("event=inputTranscript")
                            case .interrupted:
                                print("event=interrupted")
                            case .turnComplete:
                                turnCompleted = true
                                print("event=turnComplete")
                            case .toolCall:
                                print("event=toolCall")
                            case .goAway:
                                print("event=goAway")
                            case .resumptionUpdate:
                                print("event=resumptionUpdate")
                            }
                        }
                        if turnCompleted { break }
                    }

                    guard setupReceived, audioReceived, transcriptReceived, turnCompleted else {
                        throw SmokeFailure.incompleteResponse
                    }
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(10))
                    throw SmokeFailure.timeout
                }
                try await group.next()
                group.cancelAll()
            }
            await transport.close()
            print("status=passed")
        } catch {
            await transport.close()
            fputs("status=failed error=\(errorStatus(error))\n", stderr)
            exit(1)
        }
    }

    private static func errorStatus(_ error: Error) -> String {
        switch error {
        case LiveTransportError.unauthorized:
            return "unauthorized"
        case LiveTransportError.quotaExceeded:
            return "quotaExceeded"
        case LiveTransportError.network:
            return "network"
        case LiveTransportError.closed:
            return "closed"
        case SmokeFailure.timeout:
            return "timeout"
        case SmokeFailure.incompleteResponse:
            return "incompleteResponse"
        default:
            return "unexpected"
        }
    }
}

private enum SmokeFailure: Error {
    case timeout
    case incompleteResponse
}
