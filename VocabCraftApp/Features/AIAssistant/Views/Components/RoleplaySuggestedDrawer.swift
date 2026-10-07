import CraftUIKit
import Foundation
import SwiftUI

/// Conversational scaffolding drawer providing candidate spoken responses with
/// target vocabulary highlighting and pronunciation TTS preview.
/// Smoothly transitions between a collapsed capsule toggle and an expanded bottom drawer.
@MainActor
public struct RoleplaySuggestedDrawer: View {
    @Bindable public var viewModel: RoleplayVoiceCallViewModel
    @Environment(\.craftTheme) private var theme
    @ScaledMetric private var maxDrawerListHeight: CGFloat = 240

    public init(viewModel: RoleplayVoiceCallViewModel) {
        self.viewModel = viewModel
    }

    public var isVisible: Bool {
        !viewModel.suggestedResponses.isEmpty
    }

    public var isExpanded: Bool {
        viewModel.isHintsExpanded
    }

    public var itemCount: Int {
        viewModel.suggestedResponses.count
    }

    public var toggleTitleText: String {
        AppStrings.AICall.suggestedToggleText(viewModel.suggestedResponses.count)
    }

    public var body: some View {
        Group {
            if !isVisible {
                EmptyView()
            } else if isExpanded {
                expandedDrawer
            } else {
                collapsedCapsule
            }
        }
        .animation(theme.animations.springSnappy, value: viewModel.isHintsExpanded)
        .onChange(of: viewModel.state) { _, newState in
            withAnimation(theme.animations.springSnappy) {
                handleStateChange(newState)
            }
        }
    }

    public var collapsedCapsule: some View {
        CraftButton(
            AppStrings.AICall.suggestedToggle(viewModel.suggestedResponses.count),
            iconName: CraftSymbol.chevronUp.rawValue,
            iconPosition: .leading,
            variant: .subtle,
            size: .sm
        ) {
            withAnimation(theme.animations.springSnappy) {
                viewModel.toggleHints()
            }
        }
    }

    public var expandedDrawer: some View {
        CraftCard(
            style: .elevated,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.md
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Header with title and collapse button
                HStack {
                    Text(AppStrings.AICall.suggestedTitle)
                        .font(theme.typography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textPrimary)

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

                // Scrollable list of suggestions with 100% full multi-line text wrapping
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: theme.spacing.sm) {
                        ForEach(viewModel.suggestedResponses, id: \.self) { sentence in
                            suggestionCard(sentence)
                        }
                    }
                    .padding(.vertical, theme.spacing.xxs)
                }
                .frame(maxHeight: maxDrawerListHeight)
            }
        }
    }

    @ViewBuilder
    public func suggestionCard(_ sentence: String) -> some View {
        CraftCard(
            style: .flat,
            cornerRadius: theme.radii.lg,
            padding: theme.spacing.md
        ) {
            HStack(alignment: .center, spacing: theme.spacing.sm) {
                Text(highlightedText(for: sentence))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                CraftIconButton(
                    symbol: .speakerWave2,
                    size: .sm,
                    variant: .subtle,
                    accessibilityLabelKey: AppStrings.AICall.listenSample
                ) {
                    playSamplePronunciation(sentence)
                }
            }
        }
    }

    public func playSamplePronunciation(_ sentence: String) {
        viewModel.playSamplePronunciation(sentence)
    }

    public func handleStateChange(_ newState: VoiceCallState) {
        if viewModel.isHintsExpanded {
            switch newState {
            case .thinking, .speaking, .ended, .error:
                viewModel.isHintsExpanded = false
            case .idle, .listening:
                break
            }
        }
    }

    public func highlightedText(for sentence: String) -> AttributedString {
        Self.highlightedText(
            for: sentence,
            targetWords: viewModel.scenario.targetWordIds,
            primaryColor: theme.colors.brandPrimary,
            highlightFont: theme.typography.bodyMedium.bold()
        )
    }

    public static func highlightedText(
        for sentence: String,
        targetWords: [String],
        primaryColor: Color,
        highlightFont: Font
    ) -> AttributedString {
        var attributed = AttributedString(sentence)
        for targetWord in targetWords where !targetWord.isEmpty {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: targetWord))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            let nsString = sentence as NSString
            let matches = regex.matches(in: sentence, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                if let stringRange = Range(match.range, in: sentence),
                   let attrRange = Range(stringRange, in: attributed) {
                    attributed[attrRange].foregroundColor = primaryColor
                    attributed[attrRange].font = highlightFont
                }
            }
        }
        return attributed
    }
}
