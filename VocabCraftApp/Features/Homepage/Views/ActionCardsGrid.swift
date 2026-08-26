import CraftUIKit
import SwiftUI

public struct BentoCardButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public struct ActionCardsGrid: View {
    public let dueCardsCount: Int
    public var onReflexTap: () -> Void
    public var onQueueTap: () -> Void

    public init(
        dueCardsCount: Int,
        onReflexTap: @escaping () -> Void,
        onQueueTap: @escaping () -> Void
    ) {
        self.dueCardsCount = dueCardsCount
        self.onReflexTap = onReflexTap
        self.onQueueTap = onQueueTap
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Quick Reflex Drill Card
            CraftActionCard(
                title: AppStrings.Homepage.reflexTitle,
                subtitle: AppStrings.Homepage.practiceNow,
                iconName: "timer",
                badgeKey: AppStrings.Homepage.reflexBadge,
                badgeIcon: "bolt.fill",
                accentColor: .vocabPeach,
                showChevron: false,
                action: onReflexTap
            )

            // SRS Queue Card
            CraftActionCard(
                title: AppStrings.Homepage.vocabLibraryTitle,
                subtitle: AppStrings.Homepage.dueCardsSubtitle(dueCardsCount),
                iconName: "rectangle.stack.fill",
                badgeText: "\(dueCardsCount) \(AppStrings.Common.wordUnitText.uppercased())",
                badgeIcon: "rectangle.stack.fill",
                accentColor: .vocabLavender,
                showChevron: false,
                action: onQueueTap
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
}
