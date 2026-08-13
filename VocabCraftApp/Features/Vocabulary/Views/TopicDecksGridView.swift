import SwiftUI

public struct TopicDeck: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let wordCount: Int
    public let completionPercentage: Double
    public let badgeColor: Color
    public let iconName: String

    public init(
        id: String,
        title: String,
        wordCount: Int,
        completionPercentage: Double,
        badgeColor: Color,
        iconName: String
    ) {
        self.id = id
        self.title = title
        self.wordCount = wordCount
        self.completionPercentage = completionPercentage
        self.badgeColor = badgeColor
        self.iconName = iconName
    }
}

public struct TopicDecksGridView: View {
    public let onDeckSelected: (String) -> Void

    private let decks: [TopicDeck] = [
        TopicDeck(id: "1", title: "IELTS Academic", wordCount: 500, completionPercentage: 0.65, badgeColor: .vocabLavender, iconName: "graduationcap.fill"),
        TopicDeck(id: "2", title: "TOEIC Business", wordCount: 450, completionPercentage: 0.40, badgeColor: .vocabPeach, iconName: "briefcase.fill"),
        TopicDeck(id: "3", title: "Oxford 3000", wordCount: 3000, completionPercentage: 0.85, badgeColor: .vocabMint, iconName: "book.closed.fill"),
        TopicDeck(id: "4", title: "Travel & Food", wordCount: 250, completionPercentage: 0.20, badgeColor: .vocabCoral, iconName: "airplane"),
        TopicDeck(id: "5", title: "Công Nghệ & AI", wordCount: 350, completionPercentage: 0.55, badgeColor: .vocabPeach, iconName: "cpu.fill"),
        TopicDeck(id: "6", title: "Giao Tiếp Ngày", wordCount: 400, completionPercentage: 0.90, badgeColor: .vocabMint, iconName: "bubble.left.and.bubble.right.fill")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public init(onDeckSelected: @escaping (String) -> Void) {
        self.onDeckSelected = onDeckSelected
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(decks) { deck in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        onDeckSelected(deck.id)
                    }
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: deck.iconName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                                .padding(8)
                                .background(deck.badgeColor.opacity(0.20))
                                .clipShape(Circle())

                            Spacer()

                            Text("📚 \(deck.wordCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.vocabMuted)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(deck.title))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.vocabInk)

                            Text(AppStrings.Vocabulary.completionPercent(Int(deck.completionPercentage * 100)))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.vocabMuted)
                        }

                        // Progress Bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.vocabHairline)
                            .frame(height: 4)
                            .overlay(
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.vocabMint)
                                        .frame(width: geo.size.width * CGFloat(deck.completionPercentage))
                                }
                            )
                    }
                    .padding(14)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.vocabHairline, lineWidth: 1.5)
                    )
                    .shadow(color: Color.vocabHeroTeal.opacity(0.04), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}
