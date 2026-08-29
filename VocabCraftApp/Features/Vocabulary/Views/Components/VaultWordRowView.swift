import CraftUIKit
import SwiftUI

/// Minimal Active Recall word row component for Vocabulary Vault.
/// Intentionally does NOT show the definition on the row to stimulate active retrieval.
/// Displays lemma, POS badge, optional CEFR badge, optional IPA, mastery/streak status, and bookmark action.
public struct VaultWordRowView: View {
    @Environment(\.craftTheme) private var theme
    public let word: VaultWordItem
    public let onTap: () -> Void
    public let onBookmarkTap: (() -> Void)?

    public init(
        word: VaultWordItem,
        onTap: @escaping () -> Void,
        onBookmarkTap: (() -> Void)? = nil
    ) {
        self.word = word
        self.onTap = onTap
        self.onBookmarkTap = onBookmarkTap
    }

    public var body: some View {
        CraftCard(
            style: .tactile3D,
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

                        if !word.cefrLevel.isEmpty {
                            CraftBadge(
                                verbatim: word.cefrLevel.uppercased(),
                                variant: .subtle,
                                tone: .primary,
                                size: .sm
                            )
                        }
                    }
                }

                Spacer(minLength: theme.spacing.xs)

                // Subtle chevron indicating tap to open detail sheet
                CraftIcon(.chevronRight, size: .sm)
                    .foregroundStyle(theme.colors.textMuted.opacity(0.4))
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
