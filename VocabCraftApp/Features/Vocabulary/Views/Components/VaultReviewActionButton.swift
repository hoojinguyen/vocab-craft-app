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
        CraftButton(
            verbatim: AppStrings.Vault.actionReviewWords(count),
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            action: action
        )
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
