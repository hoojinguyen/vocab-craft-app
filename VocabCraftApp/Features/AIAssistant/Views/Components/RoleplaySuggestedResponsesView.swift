import CraftUIKit
import SwiftUI

/// Conversational scaffolding component offering candidate spoken responses with
/// pronunciation TTS preview, smoothly collapsing when speech is detected.
@MainActor
public struct RoleplaySuggestedResponsesView: View {
    @Bindable public var viewModel: RoleplayVoiceCallViewModel
    @Environment(\.craftTheme) private var theme

    public init(viewModel: RoleplayVoiceCallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.suggestedResponses.isEmpty {
                EmptyView()
            } else if viewModel.isHintsExpanded {
                expandedCard
            } else {
                collapsedPill
            }
        }
        .animation(theme.animations.springSnappy, value: viewModel.isHintsExpanded)
        .onChange(of: viewModel.state) { _, newState in
            if viewModel.isHintsExpanded {
                switch newState {
                case .thinking, .speaking, .ended:
                    withAnimation(theme.animations.springSnappy) {
                        viewModel.isHintsExpanded = false
                    }
                case .idle, .listening:
                    break
                }
            }
        }
    }

    private var collapsedPill: some View {
        CraftButton(
            AppStrings.AIAssistant.speakingHintsButton,
            variant: .subtle,
            size: .sm
        ) {
            withAnimation(theme.animations.springSnappy) {
                viewModel.toggleHints()
            }
        }
    }

    private var expandedCard: some View {
        CraftCard(
            style: .elevated,
            cornerRadius: theme.radii.lg,
            padding: theme.spacing.md
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                // Header with title and collapse button
                HStack {
                    Text(AppStrings.AIAssistant.speakingHintsTitle)
                        .font(theme.typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.colors.textSecondary)

                    Spacer()

                    CraftIconButton(
                        symbol: .chevronDown,
                        size: .sm,
                        variant: .ghost,
                        accessibilityLabelKey: AppStrings.Common.close
                    ) {
                        withAnimation(theme.animations.springSnappy) {
                            viewModel.toggleHints()
                        }
                    }
                }

                // List of suggested candidate responses
                VStack(spacing: theme.spacing.xs) {
                    ForEach(viewModel.suggestedResponses, id: \.self) { sentence in
                        HStack(spacing: theme.spacing.sm) {
                            Text(highlightedText(for: sentence))
                                .font(theme.typography.bodyMedium)
                                .foregroundStyle(theme.colors.textPrimary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            CraftIconButton(
                                symbol: .speakerWave2,
                                size: .sm,
                                variant: .subtle,
                                accessibilityLabelKey: AppStrings.AIAssistant.listenSample
                            ) {
                                viewModel.playSamplePronunciation(sentence)
                            }
                        }
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xs)
                        .background(theme.colors.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                    }
                }
            }
        }
    }

    private func highlightedText(for sentence: String) -> AttributedString {
        var attributed = AttributedString(sentence)
        for targetWord in viewModel.scenario.targetWordIds where !targetWord.isEmpty {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while let range = attributed[searchRange].range(of: targetWord, options: .caseInsensitive) {
                attributed[range].foregroundColor = theme.colors.brandPrimary
                attributed[range].font = theme.typography.bodyMedium.bold()
                searchRange = range.upperBound..<attributed.endIndex
            }
        }
        return attributed
    }
}
