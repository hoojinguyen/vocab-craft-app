import CoreGraphics
import Foundation

public enum ShadowingTopic: String, Sendable, Codable, CaseIterable {
    case dailyLife
    case moviesAndSeries
    case businessEnglish
    case techAndScience
    case cultureAndTravel
}

public struct ShadowingTopicItem: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let titleEn: String
    public let titleVi: String
    public let iconName: String
    public let displayOrder: Int

    public init(
        id: String,
        titleEn: String,
        titleVi: String,
        iconName: String,
        displayOrder: Int
    ) {
        self.id = id
        self.titleEn = titleEn
        self.titleVi = titleVi
        self.iconName = iconName
        self.displayOrder = displayOrder
    }
}

public struct ShadowingKeyWord: Identifiable, Sendable, Codable, Equatable {
    public var id: String { lemma }
    public let lemma: String
    public let phonetic: String
    public let definitionVi: String
    public let definitionEn: String?
    public let linkedWordId: Int64?

    public init(
        lemma: String,
        phonetic: String,
        definitionVi: String,
        definitionEn: String? = nil,
        linkedWordId: Int64? = nil
    ) {
        self.lemma = lemma
        self.phonetic = phonetic
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.linkedWordId = linkedWordId
    }
}

public struct ShadowingSentence: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let orderIndex: Int
    public let startTime: Double
    public let endTime: Double
    public let textEn: String
    public let textVi: String
    public let keyWords: [ShadowingKeyWord]
    public let words: [ShadowingWordTimestamp]

    public init(
        id: String,
        orderIndex: Int,
        startTime: Double,
        endTime: Double,
        textEn: String,
        textVi: String,
        keyWords: [ShadowingKeyWord] = [],
        words: [ShadowingWordTimestamp] = []
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.startTime = startTime
        self.endTime = endTime
        self.textEn = textEn
        self.textVi = textVi
        self.keyWords = keyWords
        self.words = words
    }

    enum CodingKeys: String, CodingKey {
        case id
        case orderIndex
        case startTime
        case endTime
        case textEn
        case textVi
        case keyWords
        case words
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        self.startTime = try container.decode(Double.self, forKey: .startTime)
        self.endTime = try container.decode(Double.self, forKey: .endTime)
        self.textEn = try container.decode(String.self, forKey: .textEn)
        self.textVi = try container.decode(String.self, forKey: .textVi)
        self.keyWords = try container.decodeIfPresent([ShadowingKeyWord].self, forKey: .keyWords) ?? []
        self.words = try container.decodeIfPresent([ShadowingWordTimestamp].self, forKey: .words) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(orderIndex, forKey: .orderIndex)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(textEn, forKey: .textEn)
        try container.encode(textVi, forKey: .textVi)
        try container.encode(keyWords, forKey: .keyWords)
        try container.encode(words, forKey: .words)
    }
}

public struct ShadowingVideo: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let youtubeVideoId: String
    public let title: String
    public let topic: ShadowingTopic
    public let level: String
    public let durationSeconds: Double
    public let sentences: [ShadowingSentence]
    public let thumbnailUrl: String?
    public let accent: String

    public init(
        id: String,
        youtubeVideoId: String,
        title: String,
        topic: ShadowingTopic,
        level: String,
        durationSeconds: Double,
        sentences: [ShadowingSentence] = [],
        thumbnailUrl: String? = nil,
        accent: String = "American"
    ) {
        self.id = id
        self.youtubeVideoId = youtubeVideoId
        self.title = title
        self.topic = topic
        self.level = level
        self.durationSeconds = durationSeconds
        self.sentences = sentences
        self.thumbnailUrl = thumbnailUrl
        self.accent = accent
    }

    enum CodingKeys: String, CodingKey {
        case id
        case youtubeVideoId
        case title
        case topic
        case level
        case durationSeconds
        case sentences
        case thumbnailUrl
        case accent
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.youtubeVideoId = try container.decode(String.self, forKey: .youtubeVideoId)
        self.title = try container.decode(String.self, forKey: .title)
        self.topic = try container.decode(ShadowingTopic.self, forKey: .topic)
        self.level = try container.decode(String.self, forKey: .level)
        self.durationSeconds = try container.decode(Double.self, forKey: .durationSeconds)
        self.sentences = try container.decodeIfPresent([ShadowingSentence].self, forKey: .sentences) ?? []
        self.thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        self.accent = try container.decodeIfPresent(String.self, forKey: .accent) ?? "American"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(youtubeVideoId, forKey: .youtubeVideoId)
        try container.encode(title, forKey: .title)
        try container.encode(topic, forKey: .topic)
        try container.encode(level, forKey: .level)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(sentences, forKey: .sentences)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(accent, forKey: .accent)
    }
}

public enum ShadowingPlaybackPhase: Equatable, Sendable {
    case idle
    case playingNative(currentTime: Double)
    case readyToRecord
    case listening(levels: [CGFloat])
    case evaluating
    case evaluated(score: Double)
}

public struct SentenceAttemptRecord: Sendable, Equatable {
    public let score: Double
    public let userAudioURL: URL?
    public let isPassed: Bool

    public init(score: Double, userAudioURL: URL? = nil, isPassed: Bool) {
        self.score = score
        self.userAudioURL = userAudioURL
        self.isPassed = isPassed
    }
}
