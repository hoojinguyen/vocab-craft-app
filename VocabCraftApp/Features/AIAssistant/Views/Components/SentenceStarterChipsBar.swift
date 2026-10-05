import CraftUIKit
import Foundation
import SwiftUI

/// Horizontal scroll bar presenting starter sentence stems to eliminate blank-slate paralysis.
/// Tapping a chip triggers `onSelectPrompt(prompt)` to populate or append to user input.
public struct SentenceStarterChipsBar: View {
    @Environment(\.craftTheme) private var theme

    public let prompts: [String]
    public let onSelectPrompt: (String) -> Void

    public init(
        prompts: [String],
        onSelectPrompt: @escaping (String) -> Void
    ) {
        self.prompts = prompts
        self.onSelectPrompt = onSelectPrompt
    }

    public var body: some View {
        if prompts.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    Text(AppStrings.AIAssistant.starterChipsTitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .padding(.trailing, theme.spacing.xxs)

                    ForEach(prompts, id: \.self) { prompt in
                        Button {
                            onSelectPrompt(prompt)
                        } label: {
                            HStack(spacing: theme.spacing.xxs) {
                                CraftIcon(.sparkles, size: .sm, color: theme.colors.brandPrimary)
                                Text(prompt)
                                    .font(theme.typography.bodyMedium)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.surfaceCard)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(theme.colors.borderDefault, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.xs)
            }
        }
    }
}
