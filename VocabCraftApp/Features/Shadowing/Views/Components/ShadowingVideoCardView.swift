import CraftUIKit
import SwiftUI

public struct ShadowingVideoCardView: View {
    @Environment(\.craftTheme) private var theme

    public let video: ShadowingVideo
    public let progress: ShadowingProgressRecord?
    public let onSelect: () -> Void

    public init(
        video: ShadowingVideo,
        progress: ShadowingProgressRecord?,
        onSelect: @escaping () -> Void
    ) {
        self.video = video
        self.progress = progress
        self.onSelect = onSelect
    }

    public var body: some View {
        CraftCard(
            style: .elevated,
            isPressable: true,
            cornerRadius: theme.radius.md,
            padding: 0,
            action: onSelect
        ) {
            VStack(alignment: .leading, spacing: 0) {
                thumbnailView

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(video.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: theme.spacing.xs) {
                        CraftBadge(
                            verbatim: video.level,
                            variant: .subtle,
                            tone: .primary,
                            size: .sm
                        )

                        if let progress {
                            CraftBadge(
                                verbatim: String(
                                    format: String(localized: "app.shadowing.hub.practiced_format", bundle: .main),
                                    Int(progress.bestScore.rounded())
                                ),
                                symbol: .star,
                                variant: .subtle,
                                tone: .success,
                                size: .sm
                            )
                        } else {
                            CraftBadge(
                                LocalizedStringKey("app.shadowing.hub.not_practiced"),
                                variant: .subtle,
                                tone: .neutral,
                                size: .sm
                            )
                        }

                        Spacer()

                        Text(metaSummary)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(theme.spacing.sm)
            }
        }
    }

    private var thumbnailView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let thumbnailUrl = video.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }

            Text(formattedDuration)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textInverse)
                .padding(.horizontal, theme.spacing.xs)
                .padding(.vertical, theme.spacing.xxs)
                .background(theme.colors.textPrimary.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.xs))
                .padding(theme.spacing.xs)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var placeholderImage: some View {
        ZStack {
            theme.colors.surfaceSubtle
            Image(systemName: "play.circle.fill")
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textMuted)
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
