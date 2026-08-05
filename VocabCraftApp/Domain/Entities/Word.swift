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
