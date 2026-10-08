import Foundation
import Testing
@testable import VocabCraftApp

@Suite("LlamaInferenceWorker Tests")
struct LlamaInferenceWorkerTests {
    @Test("LlamaInferenceWorker throws downloadRequired when model file is missing")
    func testWorkerThrowsWhenModelMissing() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let worker = LlamaInferenceWorker(modelURL: tempDir)
        await #expect(throws: AIPackError.self) {
            _ = try await worker.generateStructuredResponse(
                messages: [LLMChatMessage(role: .user, content: "Hello")],
                systemPrompt: "You are a barista."
            )
        }
    }

    @Test("LlamaInferenceWorker throws downloadRequired when model file is incomplete (< 700MB in production mode)")
    func testWorkerThrowsWhenModelIncomplete() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dummyGGUF = tempDir.appendingPathComponent("model.gguf")
        try Data(repeating: 0x47, count: 1024).write(to: dummyGGUF)

        let worker = LlamaInferenceWorker(modelURL: tempDir, bypassInferenceForTesting: false)
        await #expect(throws: AIPackError.self) {
            _ = try await worker.generateStructuredResponse(
                messages: [LLMChatMessage(role: .user, content: "Hello")],
                systemPrompt: "You are a barista."
            )
        }
    }

    @Test("LlamaInferenceWorker produces valid JSON when model is available or mocked")
    func testWorkerProducesValidJSON() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create a dummy model.gguf fixture
        let dummyGGUF = tempDir.appendingPathComponent("model.gguf")
        try Data(repeating: 0x47, count: 1024).write(to: dummyGGUF)

        let worker = LlamaInferenceWorker(modelURL: tempDir, bypassInferenceForTesting: true)
        let jsonString = try await worker.generateStructuredResponse(
            messages: [LLMChatMessage(role: .user, content: "Hi")],
            systemPrompt: "Roleplay prompt"
        )
        let decoder = JSONDecoder()
        let output = try decoder.decode(RoleplayTurnOutput.self, from: Data(jsonString.utf8))
        #expect(!output.characterReply.isEmpty)
        #expect(!output.suggestedResponses.isEmpty)
    }

    @Test("Llama 3.2 Chat Template formats prompt with correct special tokens")
    func testPromptFormattingWithLlamaTokens() {
        let messages = [
            LLMChatMessage(role: .user, content: "Can I have an Americano?"),
            LLMChatMessage(role: .model, content: "Sure, hot or iced?"),
            LLMChatMessage(role: .user, content: "Iced, please.")
        ]
        let systemPrompt = "You are a polite barista at a local cafe."

        let formatted = LlamaInferenceWorker.formatPrompt(systemPrompt: systemPrompt, messages: messages)

        #expect(formatted.hasPrefix("<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n\(systemPrompt)<|eot_id|>"))
        #expect(formatted.contains("<|start_header_id|>user<|end_header_id|>\n\nCan I have an Americano?<|eot_id|>"))
        #expect(formatted.contains("<|start_header_id|>assistant<|end_header_id|>\n\nSure, hot or iced?<|eot_id|>"))
        #expect(formatted.contains("<|start_header_id|>user<|end_header_id|>\n\nIced, please.<|eot_id|>"))
        #expect(formatted.hasSuffix("<|start_header_id|>assistant<|end_header_id|>\n\n"))
    }

    @Test("GBNF Grammar schema definition contains all required RoleplayTurnOutput keys")
    func testGBNFGrammarDefinitionContainsRequiredKeys() {
        let gbnf = LlamaInferenceWorker.roleplayTurnOutputGBNF
        #expect(gbnf.contains("characterReply"))
        #expect(gbnf.contains("targetWordsUsed"))
        #expect(gbnf.contains("refinementSuggestion"))
        #expect(gbnf.contains("pedagogicalNote"))
        #expect(gbnf.contains("suggestedResponses"))
        #expect(gbnf.contains("isConcluded"))
    }

    @Test("LlamaInferenceWorker respects cooperative cancellation")
    func testCooperativeCancellation() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let dummyGGUF = tempDir.appendingPathComponent("model.gguf")
        try Data(repeating: 0x47, count: 1024).write(to: dummyGGUF)

        let worker = LlamaInferenceWorker(modelURL: tempDir, bypassInferenceForTesting: true)

        let task = Task {
            try await Task.sleep(nanoseconds: 1_000_000)
            return try await worker.generateStructuredResponse(
                messages: [LLMChatMessage(role: .user, content: "Hi")],
                systemPrompt: "Roleplay prompt"
            )
        }
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected cancellation error to be thrown")
        } catch is CancellationError {
            // Success: expected cancellation error
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
    }
}
