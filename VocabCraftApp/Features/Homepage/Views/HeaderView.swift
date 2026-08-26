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
            // Profile Avatar with Radial Daily Goal Progress Ring
            Button(action: { onAvatarTap?() }) {
                ZStack {
                    // Background track circle
                    Circle()
                        .stroke(Color.vocabMint.opacity(0.18), lineWidth: 3.5)

                    // Animated Radial Progress Ring
                    Circle()
                        .trim(from: 0, to: CGFloat(min(max(dailyGoalProgress, 0), 1.0)))
                        .stroke(
                            Color.vocabMint,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    // User Initials Inner Avatar
                    Circle()
                        .fill(Color.vocabSurfaceSoft)
                        .padding(5)

                    Text(userInitials)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color.vocabInk)
                }
                .frame(width: 48, height: 48)
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

            // Notification Bell Button with 44x44pt touch target
            ZStack(alignment: .topTrailing) {
                Button(action: { onNotificationTap?() }) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.vocabInk)
                        .frame(width: 44, height: 44)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

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
