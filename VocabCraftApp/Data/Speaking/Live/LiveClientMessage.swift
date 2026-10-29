import Foundation

/// The configuration used to open one Gemini Live session.
public struct LiveSetup: Sendable, Equatable {
    /// The Gemini Live model resource name.
    public let model: String
    /// The prebuilt Gemini voice name.
    public let voiceName: String
    /// The instruction applied to the live conversation.
    public let systemInstruction: String
    /// The previous session handle, when resuming a conversation.
    public let resumptionHandle: String?

    /// Creates a Live session configuration.
    public init(model: String, voiceName: String, systemInstruction: String, resumptionHandle: String? = nil) {
        self.model = model
        self.voiceName = voiceName
        self.systemInstruction = systemInstruction
        self.resumptionHandle = resumptionHandle
    }
}

/// A client message supported by the approved Gemini Live session.
public enum LiveClientMessage: Sendable, Equatable {
    /// Configures the session before any other message is sent.
    case setup(LiveSetup)
    /// Sends one PCM16 little-endian mono 16 kHz audio chunk.
    case audio(Data)
    /// Adds a hidden user turn and asks the model to respond.
    case hiddenText(String)
    /// Acknowledges the `end_session` function call.
    case toolResponse(id: String, name: String)

    /// Encodes the message in Gemini Live's JSON wire format.
    public func encoded() throws -> Data {
        let message: [String: Any]
        switch self {
        case let .setup(configuration):
            var resumption: [String: Any] = [:]
            if let handle = configuration.resumptionHandle {
                resumption["handle"] = handle
            }
            message = ["setup": [
                "model": configuration.model,
                "generationConfig": [
                    "responseModalities": ["AUDIO"],
                    "speechConfig": ["voiceConfig": [
                        "prebuiltVoiceConfig": ["voiceName": configuration.voiceName]
                    ]]
                ],
                "systemInstruction": ["parts": [["text": configuration.systemInstruction]]],
                "tools": [["functionDeclarations": [[
                    "name": "end_session",
                    "description": "End the conversation after a goodbye.",
                    "parameters": ["type": "OBJECT", "properties": ["reason": ["type": "STRING"]]]
                ]]]],
                "inputAudioTranscription": [:],
                "outputAudioTranscription": [:],
                "realtimeInputConfig": ["automaticActivityDetection": ["silenceDurationMs": 700]],
                "sessionResumption": resumption
            ]]
        case let .audio(audio):
            message = ["realtimeInput": ["audio": [
                "data": audio.base64EncodedString(),
                "mimeType": "audio/pcm;rate=16000"
            ]]]
        case let .hiddenText(text):
            message = ["clientContent": [
                "turns": [["role": "user", "parts": [["text": text]]]],
                "turnComplete": true
            ]]
        case let .toolResponse(id, name):
            message = ["toolResponse": ["functionResponses": [[
                "id": id,
                "name": name,
                "response": ["ok": true]
            ]]]]
        }

        return try JSONSerialization.data(withJSONObject: message)
    }
}
