import SwiftUI

public struct TopicDeckDetailView: View {
    public let deckId: String
    public let onBack: () -> Void

    @State private var selectedNode: SubTopicNode? = nil
    @State private var activeStudyNode: SubTopicNode? = nil
    @Environment(\.colorScheme) private var colorScheme


    // Sample data (to be wired to ViewModel)
    private let nodes: [SubTopicNode] = SubTopicNode.sampleNodes


    public init(deckId: String, onBack: @escaping () -> Void) {
        self.deckId = deckId
        self.onBack = onBack
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Header Card
                VStack(spacing: 12) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.vocabInk)
                        }

                        Text("IELTS Academic 500")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.vocabInk)

                        Spacer()

                        Text("B2 - C1")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.vocabMint.opacity(0.2))
                            .foregroundColor(Color.vocabInk)
                            .cornerRadius(6)
                    }

                    HStack {
                        Text("Tiến độ: ")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                        + Text("65%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(Color.vocabMint)
                        + Text(" (325/500 từ)")
                            .font(.system(size: 13, weight: .medium))
                            .monospacedDigit()
                            .foregroundColor(Color.vocabMuted)
                        Spacer()
                    }

                    // Progress bar (Capsule Gradient Upgrade)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.vocabHairline)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.vocabMint, Color(hex: "34D399")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.65)
                                .shadow(color: Color.vocabMint.opacity(0.35), radius: 3, x: 0, y: 1.5)
                        }
                    }
                    .frame(height: 8)

                    // Hero CTA (Pill Gradient Upgrade)
                    Button(action: {
                        if let active = nodes.first(where: { $0.state == .active }) {
                            activeStudyNode = active
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("BẮT ĐẦU HỌC CHẶNG 3 (CÔNG NGHỆ)")
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
                    .sensoryFeedback(.impact(weight: .medium), trigger: activeStudyNode != nil)
                }
                .padding(16)
                .background(Color.vocabSurfaceCard)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.vocabHairline, lineWidth: 1)
                )

                // Timeline Roadmap (Gradient & Depth Upgrade)
                VStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                        VStack(spacing: 0) {
                            HStack(spacing: 14) {
                                // Node Circle Icon (Gradient Upgrade)
                                nodeCircleIcon(node: node, index: index)

                                // Node Card Info (Gradient Border & Depth Upgrade)
                                Button(action: { selectedNode = node }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Image(systemName: node.iconName)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(node.state == .active ? Color.vocabPeach : (node.state == .completed ? Color.vocabMint : Color.vocabInk))
                                                Text(node.title)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(Color.vocabInk)
                                            }

                                            Text("\(node.learnedWords)/\(node.totalWords) từ đã thuộc")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(Color.vocabMuted)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(node.state == .active ? Color.vocabPeach : Color.vocabMuted)
                                    }
                                    .padding(14)
                                    .background(nodeCardBackground(for: node.state))
                                    .cornerRadius(14)
                                    .overlay(nodeCardBorder(for: node.state))
                                    .shadow(
                                        color: node.state == .active ? Color.vocabPeach.opacity(0.18) : (node.state == .completed ? Color.vocabMint.opacity(0.06) : Color.clear),
                                        radius: node.state == .active ? 8 : 4,
                                        x: 0,
                                        y: node.state == .active ? 4 : 2
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(BentoCardButtonStyle())
                            }

                            // Vertical Line (Gradient Upgrade)
                            if index < nodes.count - 1 {
                                HStack {
                                    connectingLine(state: node.state)
                                        .padding(.leading, 22)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
        .sheet(item: $selectedNode) { node in
            SubTopicPreviewSheet(
                node: node,
                onStartDrill: {
                    let targetNode = node
                    selectedNode = nil
                    activeStudyNode = targetNode
                },
                onToggleVault: { word in
                    // Toggle vault logic
                }
            )
        }
#if os(iOS)
        .fullScreenCover(item: $activeStudyNode) { node in
            SubTopicStudySessionView(
                node: node,
                onDismiss: { activeStudyNode = nil },
                onComplete: { _ in activeStudyNode = nil }
            )
        }
#else
        .sheet(item: $activeStudyNode) { node in
            SubTopicStudySessionView(
                node: node,
                onDismiss: { activeStudyNode = nil },
                onComplete: { _ in activeStudyNode = nil }
            )
        }
#endif
    }

    @ViewBuilder
    private func nodeCircleIcon(node: SubTopicNode, index: Int) -> some View {
        ZStack {
            switch node.state {
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
    private func nodeCardBorder(for state: NodeState) -> some View {
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

    private func nodeCardBackground(for state: NodeState) -> Color {
        switch state {
        case .active:
            return Color.vocabPeach.opacity(0.04)
        case .completed, .locked:
            return Color.vocabSurfaceCard
        }
    }

    @ViewBuilder
    private func connectingLine(state: NodeState) -> some View {
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
