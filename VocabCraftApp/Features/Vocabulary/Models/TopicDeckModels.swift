import Foundation
import SwiftUI

public enum NodeState: String, Codable, Sendable {
    case completed
    case active
    case locked
}

public struct TopicWord: Identifiable, Codable, Sendable {
    public let id: String
    public let english: String
    public let phonetic: String
    public let vietnamese: String
    public let example: String
    public let partOfSpeech: String
    public var isMastered: Bool
    public var isSavedToPersonalVault: Bool

    public init(
        id: String,
        english: String,
        phonetic: String,
        vietnamese: String,
        example: String = "",
        partOfSpeech: String = "noun",
        isMastered: Bool = false,
        isSavedToPersonalVault: Bool = false
    ) {
        self.id = id
        self.english = english
        self.phonetic = phonetic
        self.vietnamese = vietnamese
        self.example = example
        self.partOfSpeech = partOfSpeech
        self.isMastered = isMastered
        self.isSavedToPersonalVault = isSavedToPersonalVault
    }
}

public struct SubTopicNode: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let iconName: String
    public let totalWords: Int
    public let learnedWords: Int
    public let state: NodeState
    public let words: [TopicWord]

    public init(
        id: String,
        title: String,
        iconName: String,
        totalWords: Int,
        learnedWords: Int,
        state: NodeState,
        words: [TopicWord]
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.totalWords = totalWords
        self.learnedWords = learnedWords
        self.state = state
        self.words = words
    }
}

extension SubTopicNode {
    public static let sampleNodes: [SubTopicNode] = [
        SubTopicNode(
            id: "1",
            title: "Chặng 1: Khởi động",
            iconName: "flag.fill",
            totalWords: 150,
            learnedWords: 150,
            state: .completed,
            words: [
                TopicWord(
                    id: "w1",
                    english: "Ecosystem",
                    phonetic: "/ˈiː.koʊˌsɪs.təm/",
                    vietnamese: "Hệ sinh thái",
                    example: "Pollution threatens the marine ecosystem.",
                    partOfSpeech: "noun",
                    isMastered: true,
                    isSavedToPersonalVault: true
                ),
                TopicWord(
                    id: "w2",
                    english: "Biodiversity",
                    phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/",
                    vietnamese: "Đa dạng sinh học",
                    example: "Rainforests are rich in biodiversity.",
                    partOfSpeech: "noun",
                    isMastered: true,
                    isSavedToPersonalVault: true
                )
            ]
        ),
        SubTopicNode(
            id: "2",
            title: "Chặng 2: Kinh tế & Xã hội",
            iconName: "chart.bar.fill",
            totalWords: 150,
            learnedWords: 150,
            state: .completed,
            words: []
        ),
        SubTopicNode(
            id: "3",
            title: "Chặng 3: Công nghệ",
            iconName: "cpu",
            totalWords: 100,
            learnedWords: 25,
            state: .active,
            words: [
                TopicWord(
                    id: "w3",
                    english: "Artificial Intelligence",
                    phonetic: "/ˌɑːr.t̬əˈfɪʃ.əl ɪnˈtel.ə.dʒəns/",
                    vietnamese: "Trí tuệ nhân tạo",
                    example: "AI is transforming many industries.",
                    partOfSpeech: "noun",
                    isMastered: false,
                    isSavedToPersonalVault: false
                )
            ]
        ),
        SubTopicNode(
            id: "4",
            title: "Chặng 4: Văn hóa & Nghệ thuật",
            iconName: "paintpalette.fill",
            totalWords: 100,
            learnedWords: 0,
            state: .locked,
            words: []
        )
    ]
}
