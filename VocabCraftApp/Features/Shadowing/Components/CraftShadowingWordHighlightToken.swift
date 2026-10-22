import CraftUIKit
import Foundation
import SwiftUI

// MARK: - CraftColorTokens Extension for Shadowing Teleprompter

public extension CraftColorTokens {
    var successGreen: Color { statusSuccess }
    var accentPurple: Color { streakLegendary }
}

// MARK: - WordPacerState

public enum WordPacerState: Sendable, Equatable {
    case past
    case active
    case upcoming

    public static func state(for index: Int, activeIndex: Int) -> WordPacerState {
        if index < activeIndex {
            return .past
        } else if index == activeIndex {
            return .active
        } else {
            return .upcoming
        }
    }
}

// MARK: - TeleprompterPacerCalculator

public struct TeleprompterPacerCalculator: Sendable {
    public let words: [ShadowingWordTimestamp]
    public let sentenceStartTime: Double
    public let sentenceEndTime: Double

    public init(
        words: [ShadowingWordTimestamp] = [],
        sentenceStartTime: Double = 0,
        sentenceEndTime: Double = 0,
        sentenceText: String = ""
    ) {
        self.sentenceStartTime = sentenceStartTime
        self.sentenceEndTime = sentenceEndTime

        if !words.isEmpty {
            self.words = words
        } else {
            let tokens = sentenceText
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
            if tokens.isEmpty {
                self.words = []
            } else {
                let duration = max(sentenceEndTime - sentenceStartTime, 0.001)
                let slice = duration / Double(tokens.count)
                var generated: [ShadowingWordTimestamp] = []
                generated.reserveCapacity(tokens.count)
                for (idx, token) in tokens.enumerated() {
                    let start = sentenceStartTime + Double(idx) * slice
                    let end = sentenceStartTime + Double(idx + 1) * slice
                    generated.append(ShadowingWordTimestamp(word: token, start: start, end: end))
                }
                self.words = generated
            }
        }
    }

    public init(sentence: ShadowingSentence) {
        self.init(
            words: sentence.words,
            sentenceStartTime: sentence.startTime,
            sentenceEndTime: sentence.endTime,
            sentenceText: sentence.textEn
        )
    }

    public func activeWordIndex(at currentTime: Double) -> Int {
        guard !words.isEmpty else { return 0 }

        let firstStart = words.first?.start ?? sentenceStartTime
        if currentTime <= firstStart {
            return 0
        }

        let lastEnd = words.last?.end ?? sentenceEndTime
        if currentTime >= lastEnd {
            return words.count - 1
        }

        for (index, item) in words.enumerated() where currentTime >= item.start && currentTime < item.end {
            return index
        }

        if let lastPassed = words.lastIndex(where: { currentTime >= $0.start }) {
            return min(lastPassed, words.count - 1)
        }

        return 0
    }

    public func pacerState(for index: Int, at currentTime: Double) -> WordPacerState {
        let activeIdx = activeWordIndex(at: currentTime)
        return WordPacerState.state(for: index, activeIndex: activeIdx)
    }
}

// MARK: - CraftShadowingWordHighlightToken

public struct CraftShadowingWordHighlightToken: View {
    @Environment(\.craftTheme) private var theme

    public let word: String
    public let state: WordPacerState

    public init(word: String, state: WordPacerState) {
        self.word = word
        self.state = state
    }

    public var body: some View {
        Text(word)
            .font(theme.typography.titleMedium)
            .fontWeight(state == .active ? .bold : .regular)
            .foregroundColor(textColor)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                    .stroke(borderColor, lineWidth: state == .active ? 1.5 : 1)
            )
            .shadow(
                color: state == .active ? theme.colors.accentPurple.opacity(0.35) : .clear,
                radius: 6,
                x: 0,
                y: 2
            )
            .animation(theme.animations.springSnappy, value: state)
    }

    private var textColor: Color {
        switch state {
        case .past:
            return theme.colors.successGreen
        case .active:
            return theme.colors.textInverse
        case .upcoming:
            return theme.colors.textMuted
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .past:
            return theme.colors.successGreen.opacity(0.12)
        case .active:
            return theme.colors.accentPurple
        case .upcoming:
            return theme.colors.surfaceCard.opacity(0.4)
        }
    }

    private var borderColor: Color {
        switch state {
        case .past:
            return theme.colors.successGreen.opacity(0.25)
        case .active:
            return theme.colors.accentPurple
        case .upcoming:
            return theme.colors.borderDefault.opacity(0.4)
        }
    }
}
