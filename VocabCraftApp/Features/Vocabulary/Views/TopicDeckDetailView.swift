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
                        Text("Tiến độ: 65% (325/500 từ)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.vocabMuted)
                        Spacer()
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.vocabHairline)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.vocabMint)
                                .frame(width: geo.size.width * 0.65)
                        }
                    }
                    .frame(height: 6)

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

                // Timeline Roadmap
                VStack(spacing: 0) {
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                        VStack(spacing: 0) {
                            HStack(spacing: 14) {
                                // Node Circle Icon
                                ZStack {
                                    Circle()
                                        .fill(nodeColor(for: node.state))
                                        .frame(width: 48, height: 48)

                                    if node.state == .completed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color.vocabCanvas)
                                    } else if node.state == .active {
                                        Text("\(index + 1)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color(red: 0.05, green: 0.08, blue: 0.12))
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.vocabMuted)
                                    }
                                }


                                // Node Card Info
                                Button(action: { selectedNode = node }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Image(systemName: node.iconName)
                                                Text(node.title)
                                                    .font(.system(size: 15, weight: .bold))
                                            }
                                            .foregroundColor(Color.vocabInk)

                                            Text("\(node.learnedWords)/\(node.totalWords) từ đã thuộc")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.vocabMuted)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.vocabMuted)
                                    }
                                    .padding(12)
                                    .background(Color.vocabSurfaceCard)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(node.state == .active ? Color.vocabPeach : Color.vocabHairline, lineWidth: node.state == .active ? 2 : 1)
                                    )
                                }
                            }

                            // Vertical Line (except for last item)
                            if index < nodes.count - 1 {
                                HStack {
                                    Rectangle()
                                        .fill(node.state == .completed ? Color.vocabMint : Color.vocabHairline)
                                        .frame(width: 4, height: 28)
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


    private func nodeColor(for state: NodeState) -> Color {
        switch state {
        case .completed: return Color.vocabMint
        case .active: return Color.vocabPeach
        case .locked: return Color.vocabSurfaceSoft
        }
    }
}
