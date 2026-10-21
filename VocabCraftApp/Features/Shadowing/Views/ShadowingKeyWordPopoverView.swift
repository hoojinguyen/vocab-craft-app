import CraftUIKit
import SwiftUI

public struct ShadowingKeyWordPopoverView: View {
    @Environment(\.craftTheme) private var theme
    public let keyWord: ShadowingKeyWord
    public let isBookmarked: Bool
    public let onToggleBookmark: () -> Void

    public init(
        keyWord: ShadowingKeyWord,
        isBookmarked: Bool,
        onToggleBookmark: @escaping () -> Void
    ) {
        self.keyWord = keyWord
        self.isBookmarked = isBookmarked
        self.onToggleBookmark = onToggleBookmark
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(keyWord.lemma)
                        .font(theme.typography.titleMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text(keyWord.phonetic)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
                Button(action: onToggleBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(theme.typography.titleMedium)
                        .foregroundColor(isBookmarked ? theme.colors.brandPrimary : theme.colors.textSecondary)
                }
                .accessibilityLabel(
                    isBookmarked
                        ? String(localized: "app.shadowing.srs.saved_success")
                        : String(localized: "app.shadowing.srs.add_to_vault")
                )
            }

            Text(keyWord.definitionVi)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)

            CraftButton(
                isBookmarked
                    ? String(localized: "app.shadowing.srs.saved_success")
                    : String(localized: "app.shadowing.srs.add_to_vault"),
                iconName: isBookmarked ? "checkmark.circle.fill" : "plus.circle.fill",
                variant: isBookmarked ? .ghost : .secondary,
                isFullWidth: true,
                action: onToggleBookmark
            )
        }
        .padding(theme.spacing.md)
        .frame(width: 260)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
    }
}

#if canImport(PreviewsMacros)
#Preview("ShadowingKeyWordPopoverView") {
    ShadowingKeyWordPopoverView(
        keyWord: ShadowingKeyWord(
            lemma: "barista",
            phonetic: "/bəˈriːstə/",
            definitionVi: "Người pha chế cà phê"
        ),
        isBookmarked: false,
        onToggleBookmark: {}
    )
    .padding()
}
#endif
