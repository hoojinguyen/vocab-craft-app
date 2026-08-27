import CraftUIKit
import SwiftUI

/// Minimal Active Recall word row component for Vocabulary Vault.
/// Intentionally does NOT show the definition on the row to stimulate active retrieval.
/// Displays lemma, POS badge, optional CEFR badge, optional IPA, mastery/streak status, and bookmark action.
public struct VaultWordRowView: View {
    @Environment(\.craftTheme) private var theme
    public let word: VaultWordItem
    public let onTap: () -> Void
    public let onBookmarkTap: () -> Void

    public init(
        word: VaultWordItem,
        onTap: @escaping () -> Void,
        onBookmarkTap: @escaping () -> Void
    ) {
        self.word = word
        self.onTap = onTap
        self.onBookmarkTap = onBookmarkTap
    }

    public var body: some View {
        CraftCard(
            style: .outlined,
            isPressable: true,
            padding: theme.spacing.md,
            action: onTap
        ) {
            HStack(alignment: .center, spacing: theme.spacing.md) {
                // Word Details (Lemma, POS, CEFR, IPA) - NO DEFINITION for Active Recall
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack(spacing: theme.spacing.sm) {
                        Text(word.lemma)
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineLimit(1)

                        if !word.phonetic.isEmpty {
                            Text(word.phonetic)
                                .font(theme.typography.phonetic)
                                .foregroundStyle(theme.colors.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    HStack(spacing: theme.spacing.xs) {
                        if !word.pos.isEmpty {
                            CraftBadge(
                                verbatim: word.pos,
                                variant: .subtle,
                                tone: .neutral,
                                size: .sm
                            )
                        }

                        if let cefr = word.cefrLevel, !cefr.isEmpty {
                            CraftBadge(
                                verbatim: cefr.uppercased(),
                                variant: .subtle,
                                tone: .primary,
                                size: .sm
                            )
                        }

                        if word.isMastered {
                            CraftBadge(
                                AppStrings.Vocabulary.masteredBadge,
                                symbol: .checkmarkCircle,
                                variant: .subtle,
                                tone: .success,
                                size: .sm
                            )
                        } else if word.correctStreak > 0 {
                            CraftBadge(
                                verbatim: "\(word.correctStreak)/3",
                                symbol: .streak,
                                variant: .subtle,
                                tone: .warning,
                                size: .sm
                            )
                        }
                    }
                }

                Spacer(minLength: theme.spacing.xs)

                // Bookmark Icon Button
                CraftIconButton(
                    symbol: word.isBookmarked ? .bookmarkFill : .bookmark,
                    size: .md,
                    shape: .circle,
                    variant: .ghost,
                    customTint: word.isBookmarked ? theme.colors.accent : theme.colors.textMuted,
                    isSelected: word.isBookmarked,
                    accessibilityLabelKey: word.isBookmarked ? "homepage.saved" : "homepage.saveWord"
                ) {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    #endif
                    onBookmarkTap()
                }
            }
        }
    }
}

#Preview("VaultWordRowView") {
    VStack(spacing: 12) {
        VaultWordRowView(
            word: VaultWordItem(
                id: 1,
                lemma: "resilience",
                pos: "noun",
                phonetic: "/rɪˈzɪl.jəns/",
                definitionVi: "Khả năng phục hồi",
                cefrLevel: "B2",
                isMastered: false,
                isBookmarked: true,
                correctStreak: 2
            ),
            onTap: {},
            onBookmarkTap: {}
        )

        VaultWordRowView(
            word: VaultWordItem(
                id: 2,
                lemma: "ephemeral",
                pos: "adj",
                phonetic: "/ɪˈfem.ər.əl/",
                definitionVi: "Phù du, chóng tàn",
                cefrLevel: "C1",
                isMastered: true,
                isBookmarked: false,
                correctStreak: 3
            ),
            onTap: {},
            onBookmarkTap: {}
        )
    }
    .padding()
}
