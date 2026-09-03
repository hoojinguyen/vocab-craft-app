import CraftUIKit
import SwiftUI

public struct OnboardingCelebrationSheet: View {
    public let onDismiss: () -> Void
    @State private var confettiTrigger: Bool = false
    @Environment(\.craftTheme) private var theme

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            VStack(spacing: theme.spacing.xl) {
                Spacer()

                VStack(spacing: theme.spacing.base) {
                    CraftStreakBadge(
                        count: 1,
                        isCompletedToday: true,
                        size: .md
                    )

                    Text("app.onboarding.celebration.title")
                        .font(theme.typography.titleLarge)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("app.onboarding.celebration.subtitle")
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.base)
                }

                Spacer()

                CraftButton(
                    "app.onboarding.celebration.cta",
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true
                ) {
                    onDismiss()
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 40)
        .onAppear {
            confettiTrigger = true
            CraftHaptics.shared.success()
        }
    }
}
