import CraftUIKit
import SpeechKit
import SwiftUI

extension WordTokenResult {
    /// Adapts a headless SpeechKit evaluation token into a standardized CraftUIKit display token.
    public var asCraftSpeechWordToken: CraftSpeechWordToken {
        let craftStatus: CraftSpeechStatus
        switch status {
        case .exactMatch:
            craftStatus = .matched
        case .fuzzyMatch:
            craftStatus = .fuzzy
        case .missing:
            craftStatus = .mismatched
        }
        return CraftSpeechWordToken(
            id: "\(id)",
            targetWord: targetWord,
            status: craftStatus,
            spokenWord: spokenWord,
            confidence: confidence
        )
    }
}

/// Shared speech visualizer component showing animated sound equalizer bars,
/// live recognized speech text display, and word token highlight chips across voice features.
public struct VocabSpeechVisualizerView: View {
    @Environment(\.craftTheme) private var theme

    public let isListening: Bool
    public let recognizedText: String
    public let placeholderText: String
    public let evaluationResult: SpeechEvaluationResult?
    public let tokens: [WordTokenResult]

    public init(
        isListening: Bool,
        recognizedText: String,
        placeholderText: String = AppStrings.Reflex.quickVisualizerPlaceholderText,
        evaluationResult: SpeechEvaluationResult? = nil,
        tokens: [WordTokenResult]? = nil
    ) {
        self.isListening = isListening
        self.recognizedText = recognizedText
        self.placeholderText = placeholderText
        self.evaluationResult = evaluationResult
        if let explicitTokens = tokens {
            self.tokens = explicitTokens
        } else if let eval = evaluationResult {
            self.tokens = eval.tokens
        } else {
            self.tokens = []
        }
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header Label & Evaluation Badge
            HStack {
                Label(
                    headerTitle,
                    systemImage: headerIcon
                )
                .font(.caption2.bold().smallCaps())
                .foregroundColor(headerColor)

                Spacer()

                if let eval = evaluationResult {
                    evaluationBadge(eval)
                }
            }

            // Equalizer Sound Bar Visualizer
            if isListening {
                EqualizerBarsView(isListening: isListening)
                    .transition(.scale.combined(with: .opacity))
            }

            // Word Tokens Highlight using CraftUIKit flow layout and token chips
            if !tokens.isEmpty {
                CraftSpeechWordFlowLayout(spacing: 8, lineSpacing: 8, alignment: .center) {
                    ForEach(tokens) { token in
                        CraftSpeechWordTokenView(token: token.asCraftSpeechWordToken)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            } else {
                Text(displayText)
                    .font(.body.weight(recognizedText.isEmpty ? .medium : .semibold))
                    .foregroundColor(recognizedText.isEmpty ? theme.colors.textMuted.opacity(0.6) : theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                theme.colors.surfaceCard

                if isListening {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [theme.colors.statusDanger.opacity(0.6), theme.colors.accent.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else if let eval = evaluationResult, eval.isPassed {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.colors.statusSuccess.opacity(0.4), lineWidth: 1.5)
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.colors.hairline, lineWidth: 1.5)
                }
            }
        )
        .cornerRadius(24)
        .shadow(
            color: isListening ? theme.colors.statusDanger.opacity(0.12) : Color.black.opacity(0.03),
            radius: isListening ? 12 : 6,
            x: 0,
            y: isListening ? 6 : 3
        )
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isListening)
        .animation(.easeInOut(duration: 0.2), value: tokens)
    }

    private var headerTitle: LocalizedStringKey {
        if isListening {
            return AppStrings.Reflex.listening
        } else if evaluationResult != nil {
            return AppStrings.Reflex.speechEvaluation
        } else {
            return AppStrings.Reflex.spokenAnswer
        }
    }

    private var headerIcon: String {
        if isListening {
            return "waveform"
        } else if evaluationResult != nil {
            return "text.badge.checkmark"
        } else {
            return "mic.fill"
        }
    }

    private var headerColor: Color {
        if isListening {
            return theme.colors.statusDanger
        } else if let eval = evaluationResult {
            return eval.isPassed ? theme.colors.statusSuccess : theme.colors.accent
        } else {
            return theme.colors.textMuted
        }
    }

    @ViewBuilder
    private func evaluationBadge(_ eval: SpeechEvaluationResult) -> some View {
        HStack(spacing: 4) {
            Text(verbatim: "⚡️ \(Int(eval.overallScore))%")
                .font(.caption2.bold())
                .foregroundColor(eval.isPassed ? theme.colors.statusSuccess : theme.colors.statusWarning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background((eval.isPassed ? theme.colors.statusSuccess : theme.colors.statusWarning).opacity(0.12))
        .clipShape(Capsule())
    }

    private var displayText: String {
        if !recognizedText.isEmpty {
            return recognizedText
        }
        if isListening {
            return AppStrings.Reflex.quickVisualizerListeningText
        }
        return placeholderText
    }
}

private struct EqualizerBarsView: View {
    @Environment(\.craftTheme) private var theme
    let isListening: Bool
    @State private var barHeights: [CGFloat] = [12, 24, 18, 30, 16, 26, 14]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<barHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [theme.colors.statusDanger, theme.colors.accent],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: barHeights[index])
                    .animation(.easeInOut(duration: 0.12), value: barHeights[index])
            }
        }
        .frame(height: 32)
        .task(id: isListening) {
            guard isListening else { return }
            while !Task.isCancelled && isListening {
                try? await Task.sleep(for: .milliseconds(120))
                for i in 0..<barHeights.count {
                    barHeights[i] = CGFloat.random(in: 8...30)
                }
            }
        }
    }
}
