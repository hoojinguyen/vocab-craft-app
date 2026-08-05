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
                    .fill(Color.vocabHeroTeal)
                    .frame(width: 56, height: 56)
                Text(userName.prefix(1))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.headline)
                    .foregroundColor(.vocabInk)
                
                HStack(spacing: 8) {
                    Text(userLevel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.vocabLavender.opacity(0.15))
                        .foregroundColor(.vocabLavender)
                        .clipShape(Capsule())
                    
                    Text("🔥 \(streakDays) ngày")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.vocabCoral)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
