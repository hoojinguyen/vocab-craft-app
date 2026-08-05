import SwiftUI

public struct HeaderView: View {
    public let userName: String
    public let streakDays: Int
    public let dailyGoalProgress: Double
    public let unreadNotifications: Bool
    public var onAvatarTap: (() -> Void)?
    public var onNotificationTap: (() -> Void)?

    public init(
        userName: String,
        streakDays: Int,
        dailyGoalProgress: Double,
        unreadNotifications: Bool,
        onAvatarTap: (() -> Void)? = nil,
        onNotificationTap: (() -> Void)? = nil
    ) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.unreadNotifications = unreadNotifications
        self.onAvatarTap = onAvatarTap
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
                Text("Chào \(userName)")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                
                HStack(spacing: 4) {
                    Text("Mục tiêu:")
                        .foregroundColor(Color.vocabMuted)
                    Text("\(Int(dailyGoalProgress * 100))%")
                        .fontWeight(.bold)
                        .foregroundColor(Color.vocabMint)
                    Text("hôm nay")
                        .foregroundColor(Color.vocabMuted)
                }
                .font(.system(size: 13, weight: .medium))
            }

            Spacer(minLength: 4)

            // Streak Flame Pill Badge
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.vocabCoral)
                Text("\(streakDays)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.vocabCoral)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.vocabCoral.opacity(0.12))
            .clipShape(Capsule())

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



