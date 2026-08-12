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
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.vocabHeroTeal, .vocabHeroAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: Color.vocabHeroTeal.opacity(0.35), radius: 8, x: 0, y: 4)
                    
                    Text(userName.prefix(1))
                        .font(.title2.bold())
                        .fontDesign(.rounded)
                        .foregroundColor(.white)
                }

                // Status indicator dot
                Circle()
                    .fill(Color.vocabMint)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: Color.vocabMint.opacity(0.4), radius: 3, x: 0, y: 1)
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(userName)
                    .font(.headline.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabInk)
                
                HStack(spacing: 6) {
                    Text(userLevel)
                        .font(.caption2.weight(.bold))
                        .fontDesign(.rounded)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.vocabLavender.opacity(0.14))
                                .overlay(Capsule().stroke(Color.vocabLavender.opacity(0.25), lineWidth: 0.8))
                        )
                        .foregroundColor(.vocabLavender)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.vocabCoral)
                        Text("\(streakDays) \(AppStrings.Homepage.streakDays)")
                            .font(.caption2.weight(.bold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundColor(.vocabCoral)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.vocabCoral.opacity(0.12))
                            .overlay(Capsule().stroke(Color.vocabCoral.opacity(0.22), lineWidth: 0.8))
                    )
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
