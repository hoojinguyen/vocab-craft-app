import Testing
@testable import VocabCraftApp

@Suite("Reflex Hint Mask Generator Tests")
struct ReflexHintMaskGeneratorTests {
    @Test("Short word (<= 4 letters) generates prefix or suffix mask")
    func testShortWordMask() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "book",
            sentenceEn: "I read a book daily.",
            pos: "noun"
        )
        #expect(stages.maskedWordString.contains("b") || stages.maskedWordString.contains("k"))
        #expect(stages.lengthMaskedParts.slot.contains("_"))
        #expect(stages.patternRevealedParts.prefix == "I read a ")
        #expect(stages.patternRevealedParts.suffix == " daily.")
    }

    @Test("Word with double consonant detects middle cluster")
    func testDoubleConsonantDetection() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "challenge",
            sentenceEn: "Overcoming a challenge makes you stronger.",
            pos: "noun"
        )
        if case .middleCluster(let cluster, _) = stages.strategy {
            #expect(cluster == "ll")
            #expect(stages.maskedWordString.contains("l l"))
        } else {
            #expect(Bool(false), "Expected middleCluster strategy for challenge")
        }
    }

    @Test("Length mask accurately matches lemma character count")
    func testLengthMaskAccuracy() {
        let lemma = "protect"
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: lemma,
            sentenceEn: "We must protect nature.",
            pos: "verb"
        )
        let underscoreCount = stages.lengthMaskedParts.slot.filter { $0 == "_" }.count
        #expect(underscoreCount == lemma.count)
    }

    @Test("Phrasal verbs preserve whitespace in masking")
    func testPhrasalVerbPreservesSpaces() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "look up",
            sentenceEn: "Please look up the word.",
            pos: "verb"
        )
        #expect(stages.lengthMaskedParts.slot.contains("   ") || stages.lengthMaskedParts.slot.contains("  "))
    }

    @Test("Empty lemma returns safe fallback")
    func testEmptyLemmaFallback() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "",
            sentenceEn: "Sample sentence.",
            pos: "noun"
        )
        #expect(stages.maskedWordString == "...")
        #expect(stages.strategy == .shortWordPrefix)
        #expect(stages.initialParts.prefix == "Sample sentence.")
    }

    @Test("Internal digraph detection identifies consonant digraphs")
    func testDigraphDetection() {
        let stages = ReflexHintMaskGenerator.generateStages(
            lemma: "brother",
            sentenceEn: "He is my brother.",
            pos: "noun"
        )
        if case .middleCluster(let cluster, _) = stages.strategy {
            #expect(cluster == "th")
            #expect(stages.maskedWordString.contains("t h"))
        } else {
            #expect(Bool(false), "Expected middleCluster strategy for brother")
        }
    }
}
