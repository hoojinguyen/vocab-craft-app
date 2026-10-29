import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Gemini Live protocol messages")
struct LiveMessagesTests {
    @Test func setupEncodesVoiceToolsTranscriptionAndResumption() throws {
        let json = try JSONSerialization.jsonObject(
            with: LiveClientMessage.setup(.fixture(handle: "h1")).encoded()
        ) as? [String: Any]
        let setup = try #require(json?["setup"] as? [String: Any])
        let generation = try #require(setup["generationConfig"] as? [String: Any])
        let speech = try #require(generation["speechConfig"] as? [String: Any])
        let voice = try #require(speech["voiceConfig"] as? [String: Any])
        let prebuilt = try #require(voice["prebuiltVoiceConfig"] as? [String: Any])
        let tools = try #require(setup["tools"] as? [[String: Any]])
        let declarations = try #require(tools.first?["functionDeclarations"] as? [[String: Any]])

        #expect(setup["model"] as? String == "models/gemini-3.8-live")
        #expect((setup["sessionResumption"] as? [String: Any])?["handle"] as? String == "h1")
        #expect(generation["responseModalities"] as? [String] == ["AUDIO"])
        #expect(prebuilt["voiceName"] as? String == "Kore")
        #expect(declarations.first?["name"] as? String == "end_session")
        #expect(setup["inputAudioTranscription"] != nil && setup["outputAudioTranscription"] != nil)
        let realtime = try #require(setup["realtimeInputConfig"] as? [String: Any])
        let detection = try #require(realtime["automaticActivityDetection"] as? [String: Any])
        #expect(detection["silenceDurationMs"] as? Int == 700)
    }

    @Test func setupWithoutResumptionHandleOmitsHandle() throws {
        let data = try LiveClientMessage.setup(.fixture(handle: nil)).encoded()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let setup = try #require(json?["setup"] as? [String: Any])
        let resumption = try #require(setup["sessionResumption"] as? [String: Any])
        #expect(resumption["handle"] == nil)
    }

    @Test func audioEncodesBase64WithPcmMime() throws {
        let input = Data([0, 1, 254, 255])
        let data = try LiveClientMessage.audio(input).encoded()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let realtimeInput = try #require(json?["realtimeInput"] as? [String: Any])
        let audio = try #require(realtimeInput["audio"] as? [String: Any])

        #expect(audio["mimeType"] as? String == "audio/pcm;rate=16000")
        #expect(Data(base64Encoded: try #require(audio["data"] as? String)) == input)
    }

    @Test func hiddenTextEncodesCompletedUserTurn() throws {
        let data = try LiveClientMessage.hiddenText("Say hello.").encoded()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = try #require(json?["clientContent"] as? [String: Any])
        let turns = try #require(content["turns"] as? [[String: Any]])
        let parts = try #require(turns.first?["parts"] as? [[String: Any]])

        #expect(turns.first?["role"] as? String == "user")
        #expect(parts.first?["text"] as? String == "Say hello.")
        #expect(content["turnComplete"] as? Bool == true)
    }

    @Test func toolResponseEncodesMatchingFunctionResponse() throws {
        let data = try LiveClientMessage.toolResponse(id: "c1", name: "end_session").encoded()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let response = try #require(json?["toolResponse"] as? [String: Any])
        let functions = try #require(response["functionResponses"] as? [[String: Any]])
        let first = try #require(functions.first)

        #expect(first["id"] as? String == "c1")
        #expect(first["name"] as? String == "end_session")
        #expect((first["response"] as? [String: Any])?["ok"] as? Bool == true)
    }

    @Test func everyServerFixtureDecodes() throws {
        let fixtures = [
            "setup-complete", "audio-chunk", "input-transcription", "output-transcription",
            "interrupted", "turn-complete", "tool-call-end-session", "go-away",
            "session-resumption-update", "model-turn-with-transcript"
        ]

        for fixture in fixtures {
            #expect(try !LiveServerEvent.decode(liveFixtureData(fixture)).isEmpty)
        }
    }

    @Test func combinedServerContentDecodesInContractOrder() throws {
        let events = try LiveServerEvent.decode(liveFixtureData("model-turn-with-transcript"))

        #expect(events == [.audio(Data([1, 0, 2, 0])), .outputTranscript("Hi there"), .turnComplete])
    }

    @Test func serverContentDecodesAudioThenBothTranscriptionsThenControlEvents() throws {
        let json = #"""
        {
          "serverContent": {
            "modelTurn": {"parts": [{"inlineData": {"mimeType": "audio/pcm;rate=24000", "data": "AQACAA=="}}]},
            "outputTranscription": {"text": "Hello"},
            "inputTranscription": {"text": "Hi"},
            "interrupted": true,
            "turnComplete": true
          }
        }
        """#
        let events = try LiveServerEvent.decode(Data(json.utf8))

        #expect(events == [
            .audio(Data([1, 0, 2, 0])), .outputTranscript("Hello"), .inputTranscript("Hi"), .interrupted, .turnComplete
        ])
    }

    @Test func toolCallAndGoAwayDecode() throws {
        #expect(
            try LiveServerEvent.decode(liveFixtureData("tool-call-end-session")) ==
                [.toolCall(id: "c1", name: "end_session")]
        )
        #expect(
            try LiveServerEvent.decode(liveFixtureData("go-away")) == [.goAway(timeLeft: 30)]
        )
    }

    @Test func resumptionUpdateUsesNewHandleAndResumableFlag() throws {
        #expect(
            try LiveServerEvent.decode(liveFixtureData("session-resumption-update")) ==
                [.resumptionUpdate(handle: "resume-2", resumable: true)]
        )
    }

    @Test func unknownFieldsAreIgnored() throws {
        #expect(try LiveServerEvent.decode(Data(#"{"usageMetadata":{}}"#.utf8)).isEmpty)
    }

    @Test func errorEnvelopeMapsAuthenticationAndQuotaInsteadOfIgnoringIt() throws {
        let unauthorized = Data(#"{"error":{"code":403,"message":"API key not valid","status":"PERMISSION_DENIED"}}"#.utf8)
        let quota = Data(#"{"error":{"code":429,"message":"Quota exhausted","status":"RESOURCE_EXHAUSTED"}}"#.utf8)

        #expect(throws: LiveTransportError.unauthorized) { try LiveServerEvent.decode(unauthorized) }
        #expect(throws: LiveTransportError.quotaExceeded) { try LiveServerEvent.decode(quota) }
    }
}

private extension LiveSetup {
    static func fixture(handle: String?) -> Self {
        Self(
            model: "models/gemini-3.8-live",
            voiceName: "Kore",
            systemInstruction: "Practice English speaking.",
            resumptionHandle: handle
        )
    }
}

private func liveFixtureData(_ name: String) throws -> Data {
    #if SWIFT_PACKAGE
    let bundle = Bundle.module
    #else
    let bundle = Bundle(for: LiveMessagesTestsBundleToken.self)
    #endif
    if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/live") {
        return try Data(contentsOf: url)
    }

    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/live/\(name).json")
    return try Data(contentsOf: url)
}

private final class LiveMessagesTestsBundleToken {}
