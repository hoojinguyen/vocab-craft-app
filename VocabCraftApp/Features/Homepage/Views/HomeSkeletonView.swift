import CraftUIKit
import SwiftUI

/// Shimmer skeleton placeholder for Home Learning Path while loading.
public struct HomeSkeletonView: View {
    @Environment(\.craftTheme) private var theme

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacing.xxl) {
                // Two skeleton unit headers
                ForEach(0..<2, id: \.self) { _ in
                    skeletonUnitHeader
                }
                // Skeleton path nodes
                VStack(spacing: theme.spacing.pathRowSpacing) {
                    skeletonNodeRow(isActive: true)
                    skeletonNodeRow(isActive: false)
                    skeletonNodeRow(isActive: false)
                }
                .padding(.horizontal, theme.spacing.base)
            }
            .padding(.top, theme.spacing.xl)
            .padding(.bottom, 220)
        }
        .background(theme.colors.canvasBackground)
        .accessibilityHidden(true)
    }

    private var skeletonUnitHeader: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: 60, height: 18)
                    .craftShimmer(isActive: true)
                Spacer()
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: 50, height: 18)
                    .craftShimmer(isActive: true)
            }
            RoundedRectangle(cornerRadius: 6)
                .fill(theme.colors.surfaceSubtle)
                .frame(height: 22)
                .craftShimmer(isActive: true)
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.colors.surfaceSubtle)
                .frame(height: 4)
                .craftShimmer(isActive: true)
        }
        .padding(theme.spacing.base)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.xl)
                .fill(theme.colors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.xl)
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
        )
        .craftShadow(theme.shadows.sm)
        .padding(.horizontal, theme.spacing.base)
    }

    private func skeletonNodeRow(isActive: Bool) -> some View {
        let diameter: CGFloat = isActive ? 64 : 48
        return Circle()
            .fill(theme.colors.surfaceSubtle)
            .frame(width: diameter, height: diameter)
            .craftShimmer(isActive: true)
            .frame(maxWidth: .infinity)
            .frame(height: diameter + 20)
    }
}
