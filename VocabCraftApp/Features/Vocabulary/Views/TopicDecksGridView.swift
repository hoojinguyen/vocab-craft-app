import SwiftUI

public struct TopicDecksGridView: View {
    public let onDeckSelected: (String) -> Void

    private let decks: [TopicDeck] = TopicDeck.sampleDecks

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
