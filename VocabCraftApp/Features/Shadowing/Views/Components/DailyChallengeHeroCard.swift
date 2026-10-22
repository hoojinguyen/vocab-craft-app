import CraftUIKit
import SwiftUI

public struct DailyChallengeHeroCard: View {
    @Environment(\.craftTheme) private var theme

    public let video: ShadowingVideo
    public let onStart: () -> Void

    public init(video: ShadowingVideo, onStart: @escaping () -> Void) {
        self.video = video
        self.onStart = onStart
    }

    public var body: some View {
        CraftCard(
            style: .elevated,
            cornerRadius: theme.radius.lg,
            padding: 0
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.xs) {
                    CraftBadge(
                        LocalizedStringKey("app.shadowing.hub.daily_challenge"),
                        symbol: .sparkles,
                        variant: .solid,
                        tone: .primary,
                        size: .sm
                    )

                    Spacer()

                    CraftBadge(
                        verbatim: formattedDuration,
                        iconName: "clock",
                        variant: .subtle,
                        tone: .neutral,
                        size: .sm
                    )
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(video.title)
                        .font(theme.typography.titleLarge)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: theme.spacing.xs) {
                        CraftBadge(
                            verbatim: video.level,
                            variant: .subtle,
                            tone: .primary,
                            size: .sm
                        )

                        Text(metaSummary)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                CraftButton(
                    LocalizedStringKey("app.shadowing.hub.start_practice"),
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true,
                    action: onStart
                )
            }
            .padding(theme.spacing.lg)
            .background(theme.gradients.surfaceGlass)
        }
    }

    private var formattedDuration: String {
        let totalSeconds = Int(video.durationSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var metaSummary: String {
        String(
            format: String(localized: "app.shadowing.hub.meta_format", bundle: .main),
            video.sentences.count,
            video.accent
        )
    }
}
