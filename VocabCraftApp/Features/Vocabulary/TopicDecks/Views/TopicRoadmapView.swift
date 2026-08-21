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
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 14) {
                            // Node Circle Icon
                            nodeCircleIcon(stage: stage, index: index)

                            // Node Card
                            Button(action: {
                                onStageSelected?(stage)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: stage.iconName)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(nodeIconColor(for: stage.state))

                                            Text(stage.title)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Color.vocabInk)
                                        }

                                        let learnedCount = stage.state == .completed ? stage.words.count : 0
                                        Text(AppStrings.Vocabulary.wordsMasteredCountLabel(current: learnedCount, total: stage.words.count))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.vocabMuted)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(stage.state == .active ? Color.vocabPeach : Color.vocabMuted)
                                }
                                .padding(14)
                                .background(nodeCardBackground(for: stage.state))
                                .cornerRadius(14)
                                .overlay(nodeCardBorder(for: stage.state))
                                .shadow(
                                    color: stage.state == .active ? Color.vocabPeach.opacity(0.18) : (stage.state == .completed ? Color.vocabMint.opacity(0.06) : Color.clear),
                                    radius: stage.state == .active ? 8 : 4,
                                    x: 0,
                                    y: stage.state == .active ? 4 : 2
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(BentoCardButtonStyle())
                            .disabled(stage.state == .locked)
                        }

                        // Connecting Vertical Line
                        if index < viewModel.stages.count - 1 {
                            HStack {
                                connectingLine(state: stage.state)
                                    .padding(.leading, 22)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func nodeIconColor(for state: StageState) -> Color {
        switch state {
        case .active: return Color.vocabPeach
        case .completed: return Color.vocabMint
        case .locked: return Color.vocabMuted
        }
    }

    @ViewBuilder
    private func nodeCircleIcon(stage: SubTopicStage, index: Int) -> some View {
        ZStack {
            switch stage.state {
            case .completed:
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.vocabMint, Color(hex: "34D399")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.vocabMint.opacity(0.35), radius: 5, x: 0, y: 3)

                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

            case .active:
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.vocabPeach, Color(hex: "FA9938")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.vocabPeach.opacity(0.4), radius: 6, x: 0, y: 3)

                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

            case .locked:
                Circle()
                    .fill(Color.vocabSurfaceSoft)
                    .frame(width: 48, height: 48)

                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.vocabMuted)
            }
        }
    }

    @ViewBuilder
    private func nodeCardBorder(for state: StageState) -> some View {
        switch state {
        case .active:
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [Color.vocabPeach, Color(hex: "FA9938")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        case .completed:
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.vocabMint.opacity(0.35), lineWidth: 1.2)
        case .locked:
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.vocabHairline, lineWidth: 1)
        }
    }

    private func nodeCardBackground(for state: StageState) -> Color {
        switch state {
        case .active:
            return Color.vocabPeach.opacity(0.04)
        case .completed, .locked:
            return Color.vocabSurfaceCard
        }
    }

    @ViewBuilder
    private func connectingLine(state: StageState) -> some View {
        if state == .completed {
            LinearGradient(
                colors: [Color.vocabMint, Color(hex: "34D399")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 4, height: 28)
            .cornerRadius(2)
        } else if state == .active {
            LinearGradient(
                colors: [Color.vocabPeach, Color.vocabHairline],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 4, height: 28)
            .cornerRadius(2)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.vocabHairline)
                .frame(width: 4, height: 28)
        }
    }
}
