import SwiftUI

/// Bento card style grid of topic vocabulary decks displaying aggregate progress and word count.
public struct TopicDecksGridView: View {
    public let onDeckSelected: (String) -> Void
    private var viewModel: TopicDecksViewModel?
    @Environment(\.appContainer) private var appContainer
    @State private var internalViewModel: TopicDecksViewModel?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public init(
        viewModel: TopicDecksViewModel? = nil,
        onDeckSelected: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.onDeckSelected = onDeckSelected
    }

    private var displayedDecks: [TopicDeck] {
        if let vm = viewModel, !vm.decks.isEmpty {
            return vm.decks
        }
        if let internalVM = internalViewModel, !internalVM.decks.isEmpty {
            return internalVM.decks
        }
        return TopicDeck.sampleDecks
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(displayedDecks) { deck in
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
                                .lineLimit(1)

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
        .task {
            if let vm = viewModel {
                if vm.decks.isEmpty {
                    await vm.loadDecks()
                }
            } else if let internalVM = internalViewModel {
                if internalVM.decks.isEmpty {
                    await internalVM.loadDecks()
                }
            } else {
                let vm = appContainer.makeTopicDecksViewModel()
                internalViewModel = vm
                await vm.loadDecks()
            }
        }
    }
}
