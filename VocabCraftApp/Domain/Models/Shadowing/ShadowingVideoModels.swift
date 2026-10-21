import CoreGraphics
import Foundation

public enum ShadowingTopic: String, Sendable, Codable, CaseIterable {
    case dailyLife
    case moviesAndSeries
    case businessEnglish
    case techAndScience
    case cultureAndTravel
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

    public init(
        id: String,
        orderIndex: Int,
        startTime: Double,
        endTime: Double,
        textEn: String,
        textVi: String,
        keyWords: [ShadowingKeyWord] = []
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.startTime = startTime
        self.endTime = endTime
        self.textEn = textEn
        self.textVi = textVi
        self.keyWords = keyWords
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

    public init(
        id: String,
        youtubeVideoId: String,
        title: String,
        topic: ShadowingTopic,
        level: String,
        durationSeconds: Double,
        sentences: [ShadowingSentence]
    ) {
        self.id = id
        self.youtubeVideoId = youtubeVideoId
        self.title = title
        self.topic = topic
        self.level = level
        self.durationSeconds = durationSeconds
        self.sentences = sentences
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
