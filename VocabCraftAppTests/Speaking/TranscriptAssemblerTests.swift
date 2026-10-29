import Testing
@testable import VocabCraftApp

@Suite("Speaking transcript assembler")
struct TranscriptAssemblerTests {
    @Test func alternatingTurnsAreSplitAndIndexed() {
        var assembler = TranscriptAssembler()
        assembler.ingest(.outputTranscript("Hi, what"), at: 0)
        assembler.ingest(.outputTranscript("can I get you?"), at: 1)
        assembler.ingest(.turnComplete, at: 2)
        assembler.ingest(.inputTranscript("A latte"), at: 3)
        assembler.ingest(.inputTranscript("please"), at: 4)
        assembler.ingest(.outputTranscript("Sure."), at: 5)

        #expect(assembler.turns.map(\.text) == ["Hi, what can I get you?", "A latte please", "Sure."])
        #expect(assembler.turns.map(\.speaker) == [.ai, .learner, .ai])
        #expect(assembler.turns.map(\.index) == [0, 1, 2])
        #expect(assembler.turns[0].endOffset == 2)
        #expect(assembler.turns[1].endOffset == 5)
    }

    @Test func repeatedInterruptionsDoNotMergeAITurns() {
        var assembler = TranscriptAssembler()
        assembler.ingest(.outputTranscript("One"), at: 0)
        assembler.ingest(.interrupted, at: 1)
        assembler.ingest(.inputTranscript("wait"), at: 2)
        assembler.ingest(.outputTranscript("Two"), at: 3)
        assembler.ingest(.interrupted, at: 4)
        assembler.ingest(.interrupted, at: 4.5)
        assembler.ingest(.inputTranscript("sorry"), at: 5)

        #expect(assembler.turns.map(\.text) == ["One", "wait", "Two", "sorry"])
        #expect(assembler.turns.map(\.index) == [0, 1, 2, 3])
        #expect(assembler.turns[0].endOffset == 1)
        #expect(assembler.turns[1].endOffset == 3)
        #expect(assembler.turns[2].endOffset == 4)
        #expect(assembler.turns[3].endOffset == nil)
    }

    @Test func whitespaceAndEmptyFragmentsDoNotCreateTurnsOrBreakJoining() {
        var assembler = TranscriptAssembler()
        assembler.ingest(.outputTranscript("  "), at: 0)
        assembler.ingest(.outputTranscript(" Hello "), at: 1)
        assembler.ingest(.outputTranscript(""), at: 2)
        assembler.ingest(.outputTranscript(" there  "), at: 3)
        assembler.ingest(.turnComplete, at: 4)
        assembler.ingest(.inputTranscript("\n"), at: 5)
        assembler.ingest(.inputTranscript(" yes "), at: 6)
        assembler.ingest(.outputTranscript("   "), at: 7)
        assembler.ingest(.outputTranscript("Okay"), at: 8)

        #expect(assembler.turns.map(\.text) == ["Hello there", "yes", "Okay"])
        #expect(assembler.turns.map(\.index) == [0, 1, 2])
        #expect(assembler.turns[1].endOffset == 8)
    }

    @Test func transcriptAfterClosingEventStartsANewAITurn() {
        var assembler = TranscriptAssembler()
        assembler.ingest(.outputTranscript("First"), at: 0)
        assembler.ingest(.turnComplete, at: 1)
        assembler.ingest(.turnComplete, at: 2)
        assembler.ingest(.outputTranscript("Second"), at: 3)

        #expect(assembler.turns.map(\.text) == ["First", "Second"])
        #expect(assembler.turns.map(\.index) == [0, 1])
        #expect(assembler.turns[0].endOffset == 1)
        #expect(assembler.turns[1].endOffset == nil)
    }
}
