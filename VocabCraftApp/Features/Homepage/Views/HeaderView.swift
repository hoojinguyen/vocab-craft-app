import CraftUIKit
import SwiftUI

public struct HeaderView: View {
    public let userName: String
    public let streakDays: Int
    public let dailyGoalProgress: Double
    public let unreadNotifications: Bool
    public var onAvatarTap: (() -> Void)?
    public var onStreakTap: (() -> Void)?
    public var onNotificationTap: (() -> Void)?

    public init(
        userName: String,
        streakDays: Int,
        dailyGoalProgress: Double,
        unreadNotifications: Bool,
        onAvatarTap: (() -> Void)? = nil,
        onStreakTap: (() -> Void)? = nil,
        onNotificationTap: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.unreadNotifications = unreadNotifications
        self.onAvatarTap = onAvatarTap
        self.onStreakTap = onStreakTap
        self.onNotificationTap = onNotificationTap
    }

    private var userInitials: String {
        let components = userName.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        if components.count >= 2, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let firstChar = userName.first {
            return "\(firstChar)".uppercased()
        }
        return "U"
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Profile Avatar with CraftProgressRing
            Button(action: { onAvatarTap?() }) {
                CraftProgressRing(
                    progress: dailyGoalProgress,
                    lineWidth: 3.5,
                    size: 48,
                    tintColor: Color.vocabMint,
                    trackColor: Color.vocabMint.opacity(0.18),
                    accessibilityLabel: AppStrings.Home.dailyGoal(percent: Int(dailyGoalProgress * 100))
                ) {
                    Circle()
                        .fill(Color.vocabSurfaceSoft)
                        .padding(5)
                        .overlay(
                            Text(userInitials)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color.vocabInk)
                        )
                }
            }
            .buttonStyle(.plain)

            // Greeting & Goal Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(AppStrings.Home.greeting(name: userName))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Text(AppStrings.Home.dailyGoal(percent: Int(dailyGoalProgress * 100)))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppStrings.Home.greeting(name: userName))
            .accessibilityValue(AppStrings.Home.dailyGoal(percent: Int(dailyGoalProgress * 100)))

            Spacer(minLength: 4)

            // Streak Flame Pill Badge
            CraftStreakBadge(
                count: streakDays,
                tier: CraftStreakTier.tier(for: streakDays),
                isCompletedToday: dailyGoalProgress >= 1.0,
                size: .sm,
                onTap: onStreakTap
            )

            // Notification Bell Button with CraftIconButton
            ZStack(alignment: .topTrailing) {
                CraftIconButton(
                    iconName: "bell.fill",
                    size: .md,
                    shape: .circle,
                    variant: .subtle,
                    accessibilityLabel: String(localized: "craft.common.action.action", defaultValue: "Notifications"),
                    action: { onNotificationTap?() }
                )

                if unreadNotifications {
                    Circle()
                        .fill(Color.vocabCoral)
                        .frame(width: 9, height: 9)
                        .offset(x: -3, y: 3)
                }
            }
        }
        .padding(.horizontal)
    }
}
