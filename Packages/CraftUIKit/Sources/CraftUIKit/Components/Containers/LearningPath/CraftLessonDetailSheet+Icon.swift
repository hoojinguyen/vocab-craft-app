import SwiftUI

// MARK: - 3D Tactile Node Icon Extensions

extension CraftLessonDetailSheet {
    var tactile3DNodeIcon: some View {
        ZStack {
            // Bottom 3D Bevel/Rim
            bottomRimShape
                .offset(y: node.state == .locked ? 0 : 4)

            // Top Face
            topFaceShape
        }
        .frame(width: tactileDiameter, height: tactileDiameter + (node.state == .locked ? 0 : 4))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    var bottomRimShape: some View {
        switch node.kind {
        case .checkpoint:
            HexagonShape()
                .fill(rimColor)
                .frame(width: tactileDiameter, height: tactileDiameter)
        case .spiralReview:
            DiamondShape()
                .fill(rimColor)
                .frame(width: tactileDiameter, height: tactileDiameter)
        case .standard, .treasureChest:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(rimColor)
                .frame(width: tactileDiameter, height: tactileDiameter)
        }
    }

    var topFaceShape: some View {
        ZStack {
            faceBackground

            // Highlight overlay
            faceHighlight

            // Center SF Symbol
            Image(systemName: effectiveIconName)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(effectiveIconColor)
        }
        .frame(width: tactileDiameter, height: tactileDiameter)
        .opacity(node.state == .locked ? 0.6 : 1.0)
    }

    @ViewBuilder
    var faceBackground: some View {
        switch node.kind {
        case .checkpoint:
            ZStack {
                switch node.state {
                case .completed:
                    HexagonShape().fill(theme.colors.surfaceCard)
                    HexagonShape().fill(theme.colors.brandPrimary.opacity(0.08))
                    HexagonShape().stroke(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
                case .active:
                    HexagonShape().fill(theme.gradients.brandHero)
                case .inProgress:
                    HexagonShape().fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    HexagonShape().fill(theme.colors.surfaceSubtle)
                case .bonus:
                    HexagonShape().fill(theme.gradients.accentShine)
                }

                if node.state == .upcoming || node.state == .locked {
                    HexagonShape()
                        .stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .spiralReview:
            ZStack {
                switch node.state {
                case .completed:
                    DiamondShape().fill(theme.colors.surfaceCard)
                    DiamondShape().fill(theme.colors.streakLegendary.opacity(0.08))
                    DiamondShape().stroke(theme.colors.streakLegendary.opacity(0.25), lineWidth: 1.5)
                case .active:
                    DiamondShape().fill(theme.gradients.streakLegendary)
                case .inProgress:
                    DiamondShape().fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    DiamondShape().fill(theme.colors.surfaceSubtle)
                case .bonus:
                    DiamondShape().fill(theme.gradients.streakLegendary)
                }

                if node.state == .upcoming || node.state == .locked {
                    DiamondShape()
                        .stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .standard:
            let squircle = RoundedRectangle(cornerRadius: 22, style: .continuous)
            ZStack {
                switch node.state {
                case .completed:
                    squircle.fill(theme.colors.surfaceCard)
                    squircle.fill(theme.colors.brandPrimary.opacity(0.08))
                    squircle.stroke(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
                case .active:
                    squircle.fill(theme.gradients.brandHero)
                case .inProgress:
                    squircle.fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    squircle.fill(theme.colors.surfaceSubtle)
                case .bonus:
                    squircle.fill(theme.gradients.accentShine)
                }

                if node.state == .upcoming || node.state == .locked {
                    squircle
                        .stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .treasureChest:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.gradients.accentShine)
        }
    }

    @ViewBuilder
    var faceHighlight: some View {
        switch node.kind {
        case .checkpoint:
            HexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        case .spiralReview:
            DiamondShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        case .standard, .treasureChest:
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        }
    }

    var rimColor: Color {
        switch node.kind {
        case .treasureChest:
            return theme.colors.accent.opacity(0.85)
        case .spiralReview:
            switch node.state {
            case .completed:
                return theme.colors.streakLegendary.opacity(0.80)
            case .active:
                return theme.colors.streakLegendary.opacity(0.85)
            case .inProgress, .upcoming:
                return theme.colors.borderDefault
            case .locked:
                return theme.colors.surfaceSubtle
            case .bonus:
                return theme.colors.accent.opacity(0.85)
            }
        case .standard, .checkpoint:
            switch node.state {
            case .completed:
                return theme.colors.brandPrimary.opacity(0.80)
            case .active:
                return theme.colors.brandPrimary.opacity(0.85)
            case .inProgress, .upcoming:
                return theme.colors.borderDefault
            case .locked:
                return theme.colors.surfaceSubtle
            case .bonus:
                return theme.colors.accent.opacity(0.85)
            }
        }
    }

    var effectiveIconName: String {
        if node.kind == .treasureChest {
            return (node.iconName == "book.fill" || node.iconName.isEmpty) ? "gift.fill" : node.iconName
        }

        if node.kind == .checkpoint && (node.iconName == "book.fill" || node.iconName.isEmpty) {
            return "crown.fill"
        }

        if node.kind == .spiralReview && (node.iconName == "book.fill" || node.iconName.isEmpty) {
            return "arrow.triangle.2.circlepath.circle.fill"
        }

        if !node.iconName.isEmpty {
            return CraftJourneyNode.resolveIconName(for: node.iconName)
        }

        switch node.state {
        case .completed:
            return "checkmark"
        case .locked:
            return "lock.fill"
        case .bonus:
            return "star.fill"
        case .active, .inProgress, .upcoming:
            return "book.fill"
        }
    }

    var effectiveIconColor: Color {
        switch node.state {
        case .completed:
            return theme.colors.brandPrimary
        case .active, .bonus:
            return .white
        case .inProgress:
            return .white
        case .upcoming, .locked:
            return theme.colors.textMuted
        }
    }
}
