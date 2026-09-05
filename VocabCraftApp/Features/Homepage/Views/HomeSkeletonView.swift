import CraftUIKit
import SwiftUI

/// Shimmer skeleton placeholder for Home Fluid Journey while loading.
///
/// Designed to achieve 0 Cumulative Layout Shift (CLS) by precisely matching
/// the geometric layout, dimensions, and styling of `CraftFluidJourney` and `CraftPinnedUnitHeader`:
/// - 76pt height pinned header card with tactile 3D extrusion and xl rounded corners
/// - 88x88pt uniform squircles (cornerRadius: 30) for learning path nodes
/// - S-curve horizontal offsets matching `FluidJourneyNodeOffset` sequence
/// - Exact vertical clearance and spacing tokens (`theme.spacing.xxl`)
public struct HomeSkeletonView: View {
    @Environment(\.craftTheme) private var theme

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: theme.spacing.xxl) {
                    // Header clearance matching CraftFluidJourney.headerClearanceHeight
                    Color.clear.frame(height: 110)

                    // Shimmer nodes matching CraftJourneyNode
                    ForEach(0..<4, id: \.self) { index in
                        skeletonNodeRow(index: index)
                    }

                    // Bottom padding matching CraftFluidJourney.smartBottomPadding
                    Color.clear.frame(height: 280)
                }
            }

            skeletonPinnedHeader
        }
        .background(theme.colors.canvasBackground)
        .accessibilityHidden(true)
    }

    private var skeletonPinnedHeader: some View {
        let cardShape = RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)

        return HStack(spacing: theme.spacing.md) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                RoundedRectangle(cornerRadius: theme.radii.xs)
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: 150, height: 20)
                    .craftShimmer(isActive: true)

                RoundedRectangle(cornerRadius: theme.radii.xs)
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: 190, height: 14)
                    .craftShimmer(isActive: true)
            }

            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: theme.radii.xs)
                .fill(theme.colors.surfaceSubtle)
                .frame(width: 14, height: 14)
                .craftShimmer(isActive: true)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.md)
        .frame(minHeight: 76)
        .background(
            ZStack {
                cardShape
                    .fill(theme.colors.borderDefault)
                    .offset(y: theme.depths.depthMd)

                cardShape
                    .fill(theme.colors.surfaceCard)
                    .overlay(
                        cardShape.strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
                    )
            }
            .craftShadow(theme.shadows.sm)
        )
        .padding(.horizontal, theme.spacing.base)
        .padding(.top, theme.spacing.xs)
    }

    private func skeletonNodeRow(index: Int) -> some View {
        let nodeShape = RoundedRectangle(cornerRadius: 30, style: .continuous)

        return ZStack {
            // Tactile 3D depth rim layer
            nodeShape
                .fill(theme.colors.borderDefault)
                .frame(width: 88, height: 88)
                .offset(y: theme.depths.depthMd)

            // Top surface
            nodeShape
                .fill(theme.colors.surfaceCard)
                .frame(width: 88, height: 88)
                .overlay(
                    nodeShape
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
                .overlay(
                    // Icon shimmer placeholder inside node
                    RoundedRectangle(cornerRadius: theme.radii.sm)
                        .fill(theme.colors.surfaceSubtle)
                        .frame(width: 32, height: 32)
                        .craftShimmer(isActive: true)
                )
        }
        .craftShadow(theme.shadows.sm)
        .offset(x: FluidJourneyNodeOffset.offset(for: index))
    }
}
