import SwiftUI

public struct HeaderView: View {
    public let userName: String
    public let streakDays: Int
    public let dailyGoalProgress: Double
    public let unreadNotifications: Bool

    public init(userName: String, streakDays: Int, dailyGoalProgress: Double, unreadNotifications: Bool) {
        self.userName = userName
        self.streakDays = streakDays
        self.dailyGoalProgress = dailyGoalProgress
        self.unreadNotifications = unreadNotifications
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Avatar inside Daily Goal Conic Ring
            ZStack {
                Circle()
                    .stroke(Color.vocabHairline, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(dailyGoalProgress, 0), 1.0))
                    .stroke(Color.vocabCoral, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(userName.prefix(2).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.vocabInk)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Chào \(userName) 👋")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.vocabInk)
                
                Text("Mục tiêu hôm nay: \(Int(dailyGoalProgress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }

            Spacer()

            // Streak Badge Pill Capsule
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.vocabCoral)
                Text("\(streakDays) ngày liên tiếp")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.vocabCoral)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.vocabCoral.opacity(0.12))
            .clipShape(Capsule())

            // Notification Bell Button with 44x44pt touch target
            ZStack(alignment: .topTrailing) {
                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
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
                        .offset(x: -4, y: 4)
                }
            }
        }
        .padding(.horizontal)
    }
}

