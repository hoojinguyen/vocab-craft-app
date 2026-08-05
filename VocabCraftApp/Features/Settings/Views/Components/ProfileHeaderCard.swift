import SwiftUI

public struct ProfileHeaderCard: View {
    public var userName: String
    public var userLevel: String
    public var streakDays: Int

    public init(
        userName: String = "Hooji N.",
        userLevel: String = "B2 Intermediate",
        streakDays: Int = 14
    ) {
        self.userName = userName
        self.userLevel = userLevel
        self.streakDays = streakDays
    }

    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.vocabHeroTeal, .vocabHeroAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: Color.vocabHeroTeal.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Text(userName.prefix(1))
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(userName)
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabInk)
                
                HStack(spacing: 8) {
                    Text(userLevel)
                        .font(.caption.weight(.bold))
                        .fontDesign(.rounded)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.vocabLavender.opacity(0.15))
                        .foregroundColor(.vocabLavender)
                        .clipShape(Capsule())
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.vocabCoral)
                        Text("\(streakDays) ngày")
                            .font(.caption.weight(.bold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundColor(.vocabCoral)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.vocabCoral.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
