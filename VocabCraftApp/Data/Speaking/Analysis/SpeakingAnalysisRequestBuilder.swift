import Foundation

public struct SpeakingAnalysisRequestBuilder {
    private static let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent"
    private static let maximumRequestBytes = 20 * 1_024 * 1_024

    public static func makeRequest(
        apiKey: String,
        session: SpeakingSessionSnapshot,
        audio: Data
    ) throws -> URLRequest {
        let prompt = prompt(for: session)
        let encodedAudioSize = ((audio.count + 2) / 3) * 4
        guard encodedAudioSize + prompt.utf8.count + 2_048 <= maximumRequestBytes else {
            throw SpeakingAnalysisError.invalidResponse
        }

        guard let url = URL(string: endpoint) else {
            throw SpeakingAnalysisError.invalidResponse
        }
        let schema = responseSchema(requiresTargetWords: !session.plan.targetWords.isEmpty)
        let bodyObject: [String: Any] = [
            "contents": [[
                "role": "user",
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "audio/m4a", "data": audio.base64EncodedString()]]
                ]
            ]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema
            ]
        ]
        let body: Data
        do {
            body = try JSONSerialization.data(withJSONObject: bodyObject)
        } catch {
            throw SpeakingAnalysisError.invalidResponse
        }
        guard body.count <= maximumRequestBytes else {
            throw SpeakingAnalysisError.invalidResponse
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    static func prompt(for session: SpeakingSessionSnapshot) -> String {
        let blueprint = session.plan.blueprint
        let turns = session.turns.map { turn in
            "[\(turn.index)] \(turn.speaker == .learner ? "LEARNER" : "AI"): \(turn.text)"
        }.joined(separator: "\n")
        let targetWords = session.plan.targetWords.map(\.lemma).joined(separator: ", ")
        let objective = blueprint.objective.map { "Objective: \($0)" } ?? "Objective: none"
        return """
        Analyze this \(session.plan.level.rawValue.uppercased()) English speaking practice session.
        AI role: \(blueprint.aiRole)
        Setting: \(blueprint.setting)
        \(objective)
        Conversation turns:
        \(turns)
        Hint count: \(session.hintCount)
        Target words: \(targetWords.isEmpty ? "none" : targetWords)

        First transcribe the learner's audio verbatim into learnerTranscript using the turn indexes. Quote only from that transcript.
        Score 1–5 aligned to CEFR A2–B1. At most 5 corrections, 3 natural phrasings, 3 pronunciation notes, and 3 target word uses.
        Write explanation, note, tip, reason, strengths and focusNext in Vietnamese.
        """
    }

    private static func responseSchema(requiresTargetWords: Bool) -> [String: Any] {
        let string = ["type": "STRING"]
        let integer = ["type": "INTEGER"]
        let boolean = ["type": "BOOLEAN"]
        func object(_ properties: [String: Any], required: [String]) -> [String: Any] {
            ["type": "OBJECT", "properties": properties, "required": required]
        }
        func array(_ items: [String: Any], maximumCount: Int? = nil) -> [String: Any] {
            var schema: [String: Any] = ["type": "ARRAY", "items": items]
            if let maximumCount { schema["maxItems"] = maximumCount }
            return schema
        }

        let score = object(
            ["value": integer, "reason": string], required: ["value", "reason"]
        )
        let transcriptLine = object(["turnIndex": integer, "text": string], required: ["turnIndex", "text"])
        let correction = object([
            "turnIndex": integer,
            "original": string,
            "corrected": string,
            "category": ["type": "STRING", "enum": ["grammar", "wordChoice", "other"]],
            "explanation": string
        ], required: ["turnIndex", "original", "corrected", "category", "explanation"])
        let naturalPhrasing = object(
            ["original": string, "natural": string, "note": string],
            required: ["original", "natural", "note"]
        )
        let pronunciation = object(
            ["word": string, "issue": string, "tip": string],
            required: ["word", "issue", "tip"]
        )
        let targetWordProperties: [String: Any] = [
            "lemma": string,
            "used": boolean,
            "usedCorrectly": boolean,
            "quote": ["type": "STRING", "nullable": true]
        ]
        let targetWordRequired = ["lemma", "used", "usedCorrectly"]
        let objective = object(["met": boolean, "note": string], required: ["met", "note"])
        let summary = object(
            ["strengths": array(string), "focusNext": array(string)],
            required: ["strengths", "focusNext"]
        )
        let properties: [String: Any] = [
            "learnerTranscript": array(transcriptLine),
            "scores": object([
                "fluency": score, "grammar": score, "vocabulary": score, "pronunciation": score
            ], required: ["fluency", "grammar", "vocabulary", "pronunciation"]),
            "corrections": array(correction, maximumCount: 5),
            "naturalPhrasings": array(naturalPhrasing, maximumCount: 3),
            "pronunciation": array(pronunciation, maximumCount: 3),
            "targetWords": array(object(targetWordProperties, required: targetWordRequired), maximumCount: 3),
            "objective": objective,
            "summary": summary
        ]
        var required = ["learnerTranscript", "scores", "corrections", "naturalPhrasings", "pronunciation", "summary"]
        if requiresTargetWords { required.append("targetWords") }
        return object(properties, required: required)
    }
}
