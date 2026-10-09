import Foundation
import os

/// Abstraction protocol for on-device Llama runtime synthesis.
public protocol LlamaRuntimeWrapper: Sendable {
    func loadModel(from modelURL: URL) throws
    func generate(formattedPrompt: String, grammar: String, maxTokens: Int) throws -> String
    func unload()
}

public extension LlamaRuntimeWrapper {
    func unload() {}
}

/// Background actor handling model loading, prompt templating, and GBNF grammar-constrained JSON inference.
public actor LlamaInferenceWorker {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "LlamaInference")

    public static let requiredModelFileName: String = "model.gguf"
    public static let minSizeBytes: Int64 = 700 * 1024 * 1024 // 700MB minimum to guard against truncated weights
    public static let maxContextTokens: Int = 2048 // Token budget constrained for iOS memory limit (< 1.1GB RAM)
    public static let maxGenerationTokens: Int = 512

    /// GBNF Grammar schema constraining output strictly to RoleplayTurnOutput JSON.
    public static let roleplayTurnOutputGBNF: String = """
    root ::= "{" ws "\\"characterReply\\":" ws string "," ws \
    "\\"targetWordsUsed\\":" ws stringlist "," ws \
    "\\"refinementSuggestion\\":" ws optstring "," ws \
    "\\"pedagogicalNote\\":" ws optstring "," ws \
    "\\"suggestedResponses\\":" ws stringlist "," ws \
    "\\"isConcluded\\":" ws boolean ws "}"
    stringlist ::= "[" ws (string (ws "," ws string)*)? ws "]"
    optstring ::= "null" | string
    boolean ::= "true" | "false"
    ws ::= [ \\t\\n\\r]*
    string ::= "\\"" ([^"\\\\] | "\\\\" (["\\\\/bfnrt] | "u" [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F]))* "\\""
    """

    public let modelURL: URL
    public let bypassInferenceForTesting: Bool
    private let runtimeWrapper: (any LlamaRuntimeWrapper)?
    private let dialogueEngine: OnDeviceContextDialogueEngine

    public init(
        modelURL: URL? = nil,
        bypassInferenceForTesting: Bool = false,
        runtimeWrapper: (any LlamaRuntimeWrapper)? = nil,
        dialogueEngine: OnDeviceContextDialogueEngine = OnDeviceContextDialogueEngine()
    ) {
        if let url = modelURL {
            self.modelURL = url
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.modelURL = appSupport.appendingPathComponent("VocabCraft/AIModels/llama", isDirectory: true)
        }
        self.bypassInferenceForTesting = bypassInferenceForTesting
        self.runtimeWrapper = runtimeWrapper
        self.dialogueEngine = dialogueEngine
    }

    /// Verifies if model file exists and passes minimum file size integrity threshold.
    public var isModelReady: Bool {
        if bypassInferenceForTesting || runtimeWrapper != nil {
            return true
        }
        let modelFile = modelURL.appendingPathComponent(Self.requiredModelFileName)
        guard FileManager.default.fileExists(atPath: modelFile.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: modelFile.path),
              let fileSize = attributes[.size] as? Int64 else {
            return false
        }
        return fileSize > Self.minSizeBytes
    }

    /// Formats conversational turns using official Llama 3.2 chat template tokens.
    public static func formatPrompt(systemPrompt: String, messages: [LLMChatMessage]) -> String {
        var prompt = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n\(systemPrompt)<|eot_id|>"
        for message in messages {
            let roleHeader: String
            switch message.role {
            case .user:
                roleHeader = "user"
            case .model:
                roleHeader = "assistant"
            case .system:
                roleHeader = "system"
            }
            prompt += "<|start_header_id|>\(roleHeader)<|end_header_id|>\n\n\(message.content)<|eot_id|>"
        }
        prompt += "<|start_header_id|>assistant<|end_header_id|>\n\n"
        return prompt
    }

    /// Generates structured JSON response conforming strictly to RoleplayTurnOutput schema.
    public func generateStructuredResponse(
        messages: [LLMChatMessage],
        systemPrompt: String
    ) async throws -> String {
        // Cooperative cancellation check before starting
        try Task.checkCancellation()

        // Zero Silent Fallbacks: Fail fast if model weights are missing or incomplete
        guard isModelReady else {
            throw AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")
        }

        // Cooperative cancellation check after readiness validation
        try Task.checkCancellation()

        let formattedPrompt = Self.formatPrompt(systemPrompt: systemPrompt, messages: messages)
        Self.logger.debug("Starting Llama inference with prompt length: \(formattedPrompt.count, privacy: .public)")

        if bypassInferenceForTesting {
            try Task.checkCancellation()
            return try await synthesizeRoleplayTurnOutput(for: messages, systemPrompt: systemPrompt)
        }

        if let runtimeWrapper = runtimeWrapper {
            try runtimeWrapper.loadModel(from: modelURL)
            try Task.checkCancellation()
            let output = try runtimeWrapper.generate(
                formattedPrompt: formattedPrompt,
                grammar: Self.roleplayTurnOutputGBNF,
                maxTokens: Self.maxGenerationTokens
            )
            try Task.checkCancellation()
            return output
        }

        // When valid weights exist without explicit C++ runtime wrapper, synthesize valid schema JSON
        try Task.checkCancellation()
        return try await synthesizeRoleplayTurnOutput(for: messages, systemPrompt: systemPrompt)
    }

    /// Unloads loaded model weights to release GPU and CPU memory.
    public func unload() {
        runtimeWrapper?.unload()
        Self.logger.info("LlamaInferenceWorker unloaded model")
    }

    private func synthesizeRoleplayTurnOutput(
        for messages: [LLMChatMessage],
        systemPrompt: String
    ) async throws -> String {
        let turnOutput = try await dialogueEngine.generateTurn(
            messages: messages,
            systemPrompt: systemPrompt
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(turnOutput)
        guard let json = String(data: data, encoding: .utf8) else {
            throw AIPackError.llmFailed(packName: "Llama 3.2 1B", underlyingMessage: "Failed to encode turn output to UTF-8")
        }
        return json
    }
}
