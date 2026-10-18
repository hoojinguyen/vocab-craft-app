import CraftUIKit
import SwiftUI

/// An interactive celebratory modal sheet presented when claiming a milestone treasure chest reward.
///
/// Complies with CraftUIKit design tokens:
/// - 3D tactile chest icon styled with `theme.gradients.accentShine` and depth rim.
/// - Bilingual congratulatory copy (`AppStrings.Treasure.congratsTitle`, `AppStrings.Treasure.congratsSubtitle`).
/// - XP milestone reward badge (`CraftBadge` with `+150 XP`, `symbol: .sparkles`, `tone: .warning`).
/// - Full-width primary CTA button (`CraftButton`) triggering claim action, haptics, and celebration confetti.
public struct TreasureClaimSheet: View {
    public let node: LessonNodeModel
    public let deckId: String
    public let onClaim: (@MainActor @Sendable () async throws -> TreasureRewardResult)?
    public let onClaimSuccess: (@MainActor @Sendable (TreasureRewardResult) -> Void)?
    public let onDismiss: @MainActor @Sendable () -> Void

    @Environment(\.craftTheme) private var theme
    @State private var isClaiming: Bool = false
    @State private var errorMessage: String?
    @State private var confettiTrigger: Bool = false

    public init(
        node: LessonNodeModel,
        deckId: String,
        onClaim: (@MainActor @Sendable () async throws -> TreasureRewardResult)? = nil,
        onClaimSuccess: (@MainActor @Sendable (TreasureRewardResult) -> Void)? = nil,
        onDismiss: @escaping @MainActor @Sendable () -> Void
    ) {
        self.node = node
        self.deckId = deckId
        self.onClaim = onClaim
        self.onClaimSuccess = onClaimSuccess
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.lg) {
                tactileChestIcon
                    .padding(.top, theme.spacing.base)

                VStack(spacing: theme.spacing.xs) {
                    Text(AppStrings.Treasure.congratsTitle)
                        .font(theme.typography.titleLarge.bold())
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(AppStrings.Treasure.congratsSubtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, theme.spacing.base)
                }

                CraftBadge(
                    formattedXPReward,
                    symbol: .sparkles,
                    variant: .subtle,
                    tone: .warning,
                    size: .md
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.statusDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.base)
                }

                Spacer(minLength: theme.spacing.sm)

                actionButton
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.bottom, theme.spacing.base)
            }
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 36)
        .presentationBackground(theme.colors.canvasBackground)
        .presentationDragIndicator(.visible)
        .presentationDetents([.fraction(0.52), .medium])
    }

    // MARK: - Subviews

    private var tactileChestIcon: some View {
        ZStack {
            // Bottom rim for tactile 3D depth
            RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous)
                .fill(theme.colors.accent.opacity(0.85))
                .frame(width: 80, height: 80)
                .offset(y: 4)

            // Top face with gradient and highlight stroke
            ZStack {
                RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous)
                    .fill(theme.gradients.accentShine)

                RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                effectiveIconColor.opacity(0.40),
                                effectiveIconColor.opacity(0.10),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )

                Image(systemName: effectiveIconName)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(effectiveIconColor)
                    .shadow(color: theme.colors.accent.opacity(0.5), radius: 4, x: 0, y: 2)
            }
            .frame(width: 80, height: 80)
        }
        .frame(width: 80, height: 84)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var actionButton: some View {
        if node.state == .completed {
            CraftButton(
                AppStrings.Treasure.alreadyClaimed,
                variant: .secondary,
                size: .lg,
                isFullWidth: true
            ) {
                onDismiss()
            }
        } else {
            CraftButton(
                AppStrings.Treasure.claimButton,
                iconName: "sparkles",
                variant: .primary,
                size: .lg,
                isLoading: isClaiming,
                isFullWidth: true
            ) {
                handleClaimTap()
            }
            .disabled(isClaiming)
        }
    }

    // MARK: - Properties & Helpers

    private var effectiveIconName: String {
        if node.iconName.isEmpty || node.iconName == "book.fill" {
            return "gift.fill"
        }
        return node.iconName
    }

    private var effectiveIconColor: Color {
        theme.colors.textInverse
    }

    private var formattedXPReward: String {
        let xp = node.xpReward ?? LessonEconomyPolicy.treasureXP
        return "+\(xp) XP"
    }

    private func handleClaimTap() {
        guard !isClaiming else { return }
        isClaiming = true
        errorMessage = nil

        Task { @MainActor in
            defer { isClaiming = false }
            do {
                CraftHaptics.shared.selection()
                if let onClaim {
                    let result = try await onClaim()
                    CraftHaptics.shared.success()
                    confettiTrigger = true
                    onClaimSuccess?(result)
                    try? await Task.sleep(for: .milliseconds(350))
                    onDismiss()
                } else {
                    onDismiss()
                }
            } catch {
                CraftHaptics.shared.warning()
                errorMessage = error.localizedDescription
            }
        }
    }
}
