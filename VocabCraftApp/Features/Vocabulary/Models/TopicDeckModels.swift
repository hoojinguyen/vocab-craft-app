import Foundation
import SwiftUI

extension TopicDeck {
    public var badgeColor: Color {
        Color(hex: badgeColorHex)
    }

    public static let sampleDecks: [TopicDeck] = [
        TopicDeck(id: "1", title: "IELTS Academic", wordCount: 500, completionPercentage: 0.65, badgeColorHex: "#9F7AEA", iconName: "graduationcap.fill"),
        TopicDeck(id: "2", title: "TOEIC Business", wordCount: 450, completionPercentage: 0.40, badgeColorHex: "#ED8936", iconName: "briefcase.fill"),
        TopicDeck(id: "3", title: "Oxford 3000", wordCount: 3000, completionPercentage: 0.85, badgeColorHex: "#38B2AC", iconName: "book.closed.fill"),
        TopicDeck(id: "4", title: "Travel & Food", wordCount: 250, completionPercentage: 0.20, badgeColorHex: "#E53E3E", iconName: "airplane"),
        TopicDeck(id: "5", title: "Công Nghệ & AI", wordCount: 350, completionPercentage: 0.55, badgeColorHex: "#ED8936", iconName: "cpu.fill"),
        TopicDeck(id: "6", title: "Giao Tiếp Ngày", wordCount: 400, completionPercentage: 0.90, badgeColorHex: "#38B2AC", iconName: "bubble.left.and.bubble.right.fill")
    ]
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
