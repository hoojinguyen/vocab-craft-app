import Foundation

/// Pure domain entity representing a vocabulary word.
public struct Word: Identifiable, Equatable, Hashable, Sendable {
    public let id: Int64
    public let lemma: String
    public let pos: String?
    public let ipaUs: String?
    public let cefrLevel: String?
    public let definitionEn: String?
    public let definitionVi: String?
    public let example: String?

    public init(
        id: Int64,
        lemma: String,
        pos: String? = nil,
        ipaUs: String? = nil,
        cefrLevel: String? = nil,
        definitionEn: String? = nil,
        definitionVi: String? = nil,
        example: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipaUs = ipaUs
        self.cefrLevel = cefrLevel
        self.definitionEn = definitionEn
        self.definitionVi = definitionVi
        self.example = example
    }
}

/// Adapter to present a Word entity as ReflexDrillable.
public struct DrillableWord: ReflexDrillable, Equatable, Sendable {
    public let lemma: String
    public let pos: String
    public let ipa: String
    public let definitionVi: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let clozeSentenceEn: String
    public let cefrLevel: String
    public let audioResourceUrl: String?

    public init(word: Word) {
        self.lemma = word.lemma
        self.pos = word.pos ?? "word"
        self.ipa = word.ipaUs ?? ""
        self.definitionVi = word.definitionVi ?? word.definitionEn ?? ""
        let sentenceEn = word.example ?? "The word is \(word.lemma)."
        self.exampleSentenceEn = sentenceEn
        self.exampleSentenceVi = word.definitionVi ?? ""
        self.clozeSentenceEn = sentenceEn
        self.cefrLevel = word.cefrLevel ?? "B2"
        self.audioResourceUrl = nil
    }
}

extension Word {
    public func asDrillable() -> DrillableWord {
        DrillableWord(word: self)
    }
}
