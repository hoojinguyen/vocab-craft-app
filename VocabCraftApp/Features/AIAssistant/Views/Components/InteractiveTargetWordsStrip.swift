import CraftUIKit
import Foundation
import SwiftUI

/// Horizontal strip displaying scenario target words with `CraftBadge`.
/// Supports tapping each badge to display word definition or pronunciation tooltip.
public struct InteractiveTargetWordsStrip: View {
    @Environment(\.craftTheme) private var theme

    public let targetWords: [String]
    public let masteredWords: Set<String>
    public let onWordTap: (String) -> Void

    public init(
        targetWords: [String],
        masteredWords: Set<String> = [],
        onWordTap: @escaping (String) -> Void = { _ in }
    ) {
        self.targetWords = targetWords
        self.masteredWords = masteredWords
        self.onWordTap = onWordTap
    }

    public var body: some View {
        if targetWords.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    Text(AppStrings.AIAssistant.targetWordsTitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.trailing, theme.spacing.xxs)

                    ForEach(targetWords, id: \.self) { word in
                        let isMastered = masteredWords.contains(word)
                        Button {
                            onWordTap(word)
                        } label: {
                            if isMastered {
                                CraftBadge(
                                    verbatim: word,
                                    symbol: .checkmarkCircle,
                                    variant: .solid,
                                    tone: .success,
                                    size: .sm
                                )
                            } else {
                                CraftBadge(
                                    verbatim: word,
                                    variant: .subtle,
                                    tone: .neutral,
                                    size: .sm
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel(Text(word))
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.xs)
            }
            .background(theme.colors.surfaceCard)
        }
    }
}
