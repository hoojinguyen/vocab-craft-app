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
            title: "Môi trường & Khí hậu",
            iconName: "leaf.fill",
            totalWords: 25,
            learnedWords: 25,
            state: .completed,
            words: [
                TopicWord(id: "w1", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", example: "Pollution threatens the marine ecosystem.", partOfSpeech: "noun", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w2", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", example: "Rainforests are rich in biodiversity.", partOfSpeech: "noun", isMastered: true, isSavedToPersonalVault: true)
            ]
        ),
        SubTopicNode(
            id: "2",
            title: "Giáo dục & Đào tạo",
            iconName: "graduationcap.fill",
            totalWords: 5,
            learnedWords: 5,
            state: .completed,
            words: [
                TopicWord(id: "w21", english: "Curriculum", phonetic: "/kəˈrɪk.jə.ləm/", vietnamese: "Chương trình giảng dạy", example: "The school offers a modern STEM curriculum.", partOfSpeech: "noun", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w22", english: "Pedagogy", phonetic: "/ˈped.ə.ɡɑː.dʒi/", vietnamese: "Phương pháp giảng dạy", example: "Innovative pedagogy enhances student engagement.", partOfSpeech: "noun", isMastered: true, isSavedToPersonalVault: false),
                TopicWord(id: "w23", english: "Scholarship", phonetic: "/ˈskɑː.lɚ.ʃɪp/", vietnamese: "Học bổng", example: "She won a full scholarship to Harvard.", partOfSpeech: "noun", isMastered: true, isSavedToPersonalVault: true)
            ]
        ),
        SubTopicNode(
            id: "3",
            title: "Công nghệ & AI",
            iconName: "cpu",
            totalWords: 10,
            learnedWords: 2,
            state: .active,
            words: [
                TopicWord(id: "w1", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Sự tự động hóa", example: "Factory automation reduces production costs.", partOfSpeech: "noun", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w2", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán", example: "The search algorithm returns accurate results.", partOfSpeech: "noun", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w3", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", example: "Pollution threatens the marine ecosystem.", partOfSpeech: "noun"),
                TopicWord(id: "w4", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", example: "Rainforests are rich in biodiversity.", partOfSpeech: "noun"),
                TopicWord(id: "w5", english: "Sustainability", phonetic: "/səˌsteɪ.nəˈbɪl.ə.ti/", vietnamese: "Sự bền vững", example: "Company policies focus on sustainability.", partOfSpeech: "noun"),
                TopicWord(id: "w6", english: "Innovation", phonetic: "/ˌɪn.əˈveɪ.ʃən/", vietnamese: "Sự đổi mới sáng tạo", example: "Technological innovation drives economic growth.", partOfSpeech: "noun"),
                TopicWord(id: "w7", english: "Infrastructure", phonetic: "/ˈɪn.frəˌstrʌk.tʃər/", vietnamese: "Hạ tầng", example: "The city invested in new transportation infrastructure.", partOfSpeech: "noun"),
                TopicWord(id: "w8", english: "Artificial", phonetic: "/ˌɑːr.t̬əˈfɪʃ.əl/", vietnamese: "Nhân tạo", example: "Artificial intelligence learns from data.", partOfSpeech: "adjective"),
                TopicWord(id: "w9", english: "Intelligence", phonetic: "/ɪnˈtel.ə.dʒəns/", vietnamese: "Trí tuệ", example: "Human intelligence is adaptable.", partOfSpeech: "noun"),
                TopicWord(id: "w10", english: "Architecture", phonetic: "/ˈɑːr.kə.tek.tʃər/", vietnamese: "Kiến trúc", example: "Modern architecture combines style and utility.", partOfSpeech: "noun")
            ]
        ),
        SubTopicNode(
            id: "4",
            title: "Kinh tế & Thị trường",
            iconName: "chart.line.uptrend.xyaxis",
            totalWords: 5,
            learnedWords: 0,
            state: .locked,
            words: [
                TopicWord(id: "w41", english: "Inflation", phonetic: "/ɪnˈfleɪ.ʃən/", vietnamese: "Lạm phát", example: "Central banks aim to control inflation.", partOfSpeech: "noun"),
                TopicWord(id: "w42", english: "Monopoly", phonetic: "/məˈnɑː.pəl.i/", vietnamese: "Độc quyền", example: "The law prevents market monopoly.", partOfSpeech: "noun"),
                TopicWord(id: "w43", english: "Revenue", phonetic: "/ˈrev.ə.nuː/", vietnamese: "Doanh thu", example: "Annual revenue increased by fifteen percent.", partOfSpeech: "noun")
            ]
        )
    ]
}

