/// Provider instructions, not learner-facing localized display text.
enum SpeakingPromptBuilder {
    static func systemInstruction(for plan: SpeakingSessionPlan) -> String {
        var lines = ["You are \(plan.blueprint.aiRole).", "Setting: \(plan.blueprint.setting)"]
        if let objective = plan.blueprint.objective {
            lines.append("Objective: \(objective)")
        }
        switch plan.level {
        case .a2:
            lines.append("Use short simple sentences, common everyday words, speak slowly.")
        case .b1:
            lines.append("Use natural everyday English, moderate pace, some idioms explained by context.")
        }
        lines.append("Speak only English. Never correct the learner during the conversation. Ask one question at a time. Keep each reply under 3 sentences.")
        if !plan.targetWords.isEmpty {
            lines.append("Target words: \(plan.targetWords.map(\.lemma).joined(separator: ", "))")
            lines.append("create natural chances for the learner to use these words; never say them first")
        }
        lines.append("When the objective is complete or the learner says goodbye, say a short goodbye and call end_session.")
        return lines.joined(separator: "\n")
    }

    static let openingTrigger = "Begin the conversation in your role with a short greeting and one question."
    static let hintRequest = "Give one short hint, using Vietnamese if helpful, then wait for the learner."
    static let wrapUpRequest = "Say goodbye in one sentence and call end_session."
}
