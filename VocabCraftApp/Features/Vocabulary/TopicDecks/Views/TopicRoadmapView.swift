import CraftUIKit
import SwiftUI

/// Vertical timeline roadmap view displaying sequential subtopic stages (.completed, .active, .locked).
public struct TopicRoadmapView: View {
    public let deckId: String
    public let deckTitle: String?
    public let onBack: () -> Void
    public var onStageSelected: ((SubTopicStage) -> Void)?

    @State private var viewModel: TopicRoadmapViewModel
    @Environment(\.appContainer) private var appContainer

    public init(
        deckId: String,
        deckTitle: String? = nil,
        viewModel: TopicRoadmapViewModel? = nil,
        onBack: @escaping () -> Void,
        onStageSelected: ((SubTopicStage) -> Void)? = nil
    ) {
        self.deckId = deckId
        self.deckTitle = deckTitle
        self.onBack = onBack
        self.onStageSelected = onStageSelected
        _viewModel = State(initialValue: viewModel ?? AppContainer.mock.makeTopicRoadmapViewModel(deckId: deckId))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Header Card
                headerCard

                // Timeline Roadmap
                timelineRoadmap
            }
            .padding(.bottom, 40)
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
        .task {
            viewModel = appContainer.makeTopicRoadmapViewModel(deckId: deckId)
            await viewModel.loadRoadmap()
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .padding(8)
                        .background(Color.vocabSurfaceSoft)
                        .clipShape(Circle())
                }

                Text(deckTitle ?? "Lộ Trình Học")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Spacer()

                Text("A2 - C1")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.vocabMint.opacity(0.2))
                    .foregroundColor(Color.vocabInk)
                    .cornerRadius(6)
            }

            let percentage = Int(viewModel.progressPercentage * 100)
            let completedWords = viewModel.stages
                .filter { $0.state == .completed }
                .reduce(0) { $0 + $1.words.count }
            let totalWords = viewModel.totalWordsCount

            HStack {
                Text(AppStrings.Vocabulary.progressTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
                + Text("\(percentage)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(Color.vocabMint)
                + Text(AppStrings.Vocabulary.progressWordsCount(current: completedWords, total: totalWords))
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(Color.vocabMuted)
                Spacer()
            }

            // Progress Bar
            Capsule()
                .fill(Color.vocabHairline)
                .frame(height: 8)
                .overlay(
                    GeometryReader { geo in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.vocabMint, Color(hex: "34D399")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(viewModel.progressPercentage))
                            .shadow(color: Color.vocabMint.opacity(0.35), radius: 3, x: 0, y: 1.5)
                    }
                )

            // Hero CTA Button
            if let active = viewModel.activeStage {
                Button(action: {
                    onStageSelected?(active)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13, weight: .bold))

                        Text(AppStrings.Vocabulary.startLearningNode(active.title.uppercased()))
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        LinearGradient(
                            colors: [Color.vocabPeach, Color(hex: "FA9938")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.vocabPeach.opacity(0.35), radius: 6, x: 0, y: 3)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
            }
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Timeline Roadmap
    private var timelineRoadmap: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 40)
            } else if viewModel.stages.isEmpty {
                Text(AppStrings.Vocabulary.emptyStageData)
                    .foregroundColor(Color.vocabMuted)
                    .padding(.top, 40)
            } else {
                ForEach(Array(viewModel.stages.enumerated()), id: \.element.id) { index, stage in
                    let learnedCount = stage.state == .completed ? stage.words.count : 0
                    CraftStepNode(
                        title: stage.title,
                        subtitle: AppStrings.Vocabulary.wordsMasteredCountText(current: learnedCount, total: stage.words.count),
                        state: stage.state.craftStepState,
                        stepNumber: index + 1,
                        isLast: index == viewModel.stages.count - 1,
                        onTap: stage.state != .locked ? {
                            onStageSelected?(stage)
                        } : nil
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - State Mapping

private extension StageState {
    var craftStepState: CraftStepState {
        switch self {
        case .completed:
            return .completed
        case .active:
            return .active
        case .locked:
            return .locked
        }
    }
}
