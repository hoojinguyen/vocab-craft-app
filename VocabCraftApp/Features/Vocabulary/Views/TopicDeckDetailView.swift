import SwiftUI

public struct TopicDeckDetailView: View {
    public let deckId: String
    public let onBack: () -> Void

    @State private var selectedNode: SubTopicNode? = nil
    @Environment(\.colorScheme) private var colorScheme

    // Sample data (to be wired to ViewModel)
    private let nodes: [SubTopicNode] = [
        SubTopicNode(
            id: "1",
            title: "Môi trường & Khí hậu",
            iconName: "leaf.fill",
            totalWords: 25,
            learnedWords: 25,
            state: .completed,
            words: [
                TopicWord(id: "w1", english: "Ecosystem", phonetic: "/ˈiː.koʊˌsɪs.təm/", vietnamese: "Hệ sinh thái", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w2", english: "Biodiversity", phonetic: "/ˌbaɪ.oʊ.daɪˈvɜːr.sə.ti/", vietnamese: "Đa dạng sinh học", isMastered: true, isSavedToPersonalVault: true)
            ]
        ),
        SubTopicNode(
            id: "2",
            title: "Giáo dục & Đào tạo",
            iconName: "graduationcap.fill",
            totalWords: 25,
            learnedWords: 25,
            state: .completed,
            words: []
        ),
        SubTopicNode(
            id: "3",
            title: "Công nghệ & AI",
            iconName: "cpu",
            totalWords: 25,
            learnedWords: 12,
            state: .active,
            words: [
                TopicWord(id: "w3", english: "Algorithm", phonetic: "/ˈæl.ɡə.rɪ.ðəm/", vietnamese: "Thuật toán", isMastered: true, isSavedToPersonalVault: true),
                TopicWord(id: "w4", english: "Automation", phonetic: "/ˌɔː.təˈmeɪ.ʃən/", vietnamese: "Tự động hóa", isMastered: false, isSavedToPersonalVault: false)
            ]
        ),
        SubTopicNode(
            id: "4",
            title: "Kinh tế & Thị trường",
            iconName: "chart.line.uptrend.xyaxis",
            totalWords: 25,
            learnedWords: 0,
            state: .locked,
            words: []
        )
    ]

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

                    // Hero CTA
                    Button(action: {
                        if let active = nodes.first(where: { $0.state == .active }) {
                            selectedNode = active
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("BẮT ĐẦU HỌC CHẶNG 3 (CÔNG NGHỆ)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.vocabPeach)
                        .foregroundColor(Color.vocabInk)
                        .cornerRadius(12)
                    }
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
                                            .foregroundColor(Color.vocabInk)
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
                    selectedNode = nil
                },
                onToggleVault: { word in
                    // Toggle vault logic
                }
            )
        }
    }

    private func nodeColor(for state: NodeState) -> Color {
        switch state {
        case .completed: return Color.vocabMint
        case .active: return Color.vocabPeach
        case .locked: return Color.vocabSurfaceSoft
        }
    }
}
