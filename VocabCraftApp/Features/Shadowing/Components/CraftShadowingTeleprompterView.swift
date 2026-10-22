import CraftUIKit
import Foundation
import SwiftUI

// MARK: - CraftShadowingTeleprompterView

public struct CraftShadowingTeleprompterView: View {
    @Environment(\.craftTheme) private var theme

    public let currentSentence: ShadowingSentence
    public let nextSentence: ShadowingSentence?
    public let currentTime: Double
    public let playbackSpeed: Float

    private let calculator: TeleprompterPacerCalculator

    public init(
        currentSentence: ShadowingSentence,
        nextSentence: ShadowingSentence? = nil,
        currentTime: Double,
        playbackSpeed: Float = 1.0
    ) {
        self.currentSentence = currentSentence
        self.nextSentence = nextSentence
        self.currentTime = currentTime
        self.playbackSpeed = playbackSpeed
        self.calculator = TeleprompterPacerCalculator(sentence: currentSentence)
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            mainCard
            if let next = nextSentence {
                nextSentencePreview(next)
            }
        }
    }

    private var mainCard: some View {
        CraftCard(style: .elevated) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                pacerHeader

                CraftSpeechWordFlowLayout(
                    spacing: theme.spacing.xs,
                    lineSpacing: theme.spacing.xs,
                    alignment: .leading
                ) {
                    ForEach(Array(calculator.words.enumerated()), id: \.offset) { index, wordItem in
                        CraftShadowingWordHighlightToken(
                            word: wordItem.word,
                            state: calculator.pacerState(for: index, at: currentTime)
                        )
                    }
                }

                if !currentSentence.textVi.isEmpty {
                    Text(currentSentence.textVi)
                        .font(theme.typography.bodyMedium)
                        .italic()
                        .foregroundColor(theme.colors.textSecondary)
                        .padding(.top, theme.spacing.xxs)
                }
            }
        }
    }

    private var pacerHeader: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: "waveform.and.mic")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.brandPrimary)

            Text(LocalizedStringKey("app.shadowing.round2.pacer_hint"))
                .font(theme.typography.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.brandPrimary)

            Spacer()
        }
    }

    private func nextSentencePreview(_ next: ShadowingSentence) -> some View {
        CraftCard(style: .flat) {
            HStack(spacing: theme.spacing.xs) {
                Text(LocalizedStringKey("app.shadowing.round2.upcoming_sentence"))
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textSecondary)

                Text(next.textEn)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textMuted)
                    .lineLimit(1)

                Spacer()
            }
        }
    }
}
