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
            style: .glass,
            isPressable: true,
            padding: theme.spacing.md,
            action: onTap
        ) {
            HStack(alignment: .center, spacing: theme.spacing.md) {
                // Word Details (Lemma, IPA, POS, CEFR) - Never truncated, no definition for Active Recall
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(word.lemma)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !word.phonetic.isEmpty {
                        Text(word.phonetic)
                            .font(theme.typography.phonetic)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
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
                        }
                    }
                }

                Spacer(minLength: theme.spacing.xs)

                // Subtle Bookmark Button (Clean, no solid background)
                Button(action: {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    #endif
                    onBookmarkTap()
                }) {
                    Image(systemName: word.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(word.isBookmarked ? theme.colors.accent : theme.colors.textMuted.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(word.isBookmarked ? "homepage.saved" : "homepage.saveWord")
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
