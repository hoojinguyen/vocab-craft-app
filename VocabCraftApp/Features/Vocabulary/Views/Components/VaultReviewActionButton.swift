import CraftUIKit
import SwiftUI

/// Prominent action button for initiating review sessions in Vocabulary Vault.
/// Displays `⚡ Ôn luyện (%lld từ)` and automatically disables when count is 0.
public struct VaultReviewActionButton: View {
    @Environment(\.craftTheme) private var theme
    public let count: Int
    public let action: () -> Void

    public init(
        count: Int,
        action: @escaping () -> Void
    ) {
        self.count = count
        self.action = action
    }

    public var body: some View {
        Button(action: {
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        }) {
            Text(verbatim: AppStrings.Vault.actionPracticeText)
                .font(theme.typography.headline)
                .fontWeight(.bold)
                .tracking(0.8)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.radii.md)
                            .fill(count >= 1 ? theme.colors.accent : theme.colors.textMuted.opacity(0.35))
                        RoundedRectangle(cornerRadius: theme.radii.md)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.05), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.md)
                        .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
                )
                .craftShadow(count >= 1 ? theme.shadows.sm : CraftShadow(color: .clear, radius: 0))
        }
        .buttonStyle(.plain)
        .disabled(count < 1)
    }
}

#Preview("VaultReviewActionButton") {
    VStack(spacing: 16) {
        VaultReviewActionButton(count: 15, action: {})
        VaultReviewActionButton(count: 0, action: {})
    }
    .padding()
}
