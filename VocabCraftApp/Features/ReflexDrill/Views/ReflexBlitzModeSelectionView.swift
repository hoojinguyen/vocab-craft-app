import SwiftUI

/// Mode item presentation model for the Reflex Blitz Mode Selection Bento cards.
public struct ReflexBlitzModeItem: Identifiable, Sendable, Equatable {
    public let mode: ReflexBlitzMode
    public let title: String
    public let subtitle: String
    public let badgeText: String
    public let iconName: String
    public let accentColor: Color

    public var id: String { mode.rawValue }

    public init(
        mode: ReflexBlitzMode,
        title: String,
        subtitle: String,
        badgeText: String,
        iconName: String,
        accentColor: Color
    ) {
        self.mode = mode
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.iconName = iconName
        self.accentColor = accentColor
    }
}

/// Bento-style Mode Selection View allowing the user to select one of 4 Reflex Blitz drill modalities:
/// Speaking (Luyện nói), Typing (Gõ từ), Multiple Choice (Trắc nghiệm), and Listening (Phản xạ nghe).
public struct ReflexBlitzModeSelectionView: View {
    public let onSelectMode: (ReflexBlitzMode) -> Void
    public let onDismiss: () -> Void

    @State private var selectedModeTrigger: ReflexBlitzMode?

    public init(
        onSelectMode: @escaping (ReflexBlitzMode) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onSelectMode = onSelectMode
        self.onDismiss = onDismiss
    }

    public static func modeItem(for mode: ReflexBlitzMode) -> ReflexBlitzModeItem {
        switch mode {
        case .speaking:
            return ReflexBlitzModeItem(
                mode: .speaking,
                title: "Luyện nói",
                subtitle: "Phản xạ phát âm & nhận diện giọng nói",
                badgeText: "6.0s",
                iconName: "waveform.and.mic",
                accentColor: .vocabPeach
            )
        case .typing:
            return ReflexBlitzModeItem(
                mode: .typing,
                title: "Gõ từ",
                subtitle: "Phản xạ gõ phím & nhớ mặt chữ",
                badgeText: "7.5s",
                iconName: "keyboard",
                accentColor: .vocabLavender
            )
        case .multipleChoice:
            return ReflexBlitzModeItem(
                mode: .multipleChoice,
                title: "Trắc nghiệm",
                subtitle: "Nhận diện từ vựng 1 trong 4",
                badgeText: "4.5s",
                iconName: "square.grid.2x2.fill",
                accentColor: .vocabMint
            )
        case .listening:
            return ReflexBlitzModeItem(
                mode: .listening,
                title: "Phản xạ nghe",
                subtitle: "Bắt âm thanh & dịch nghĩa tức thì",
                badgeText: "5.5s",
                iconName: "headphones",
                accentColor: .vocabHeroAccent
            )
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Dismiss Bar
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.vocabInk)
                            .frame(width: 36, height: 36)
                            .background(Color.vocabMuted.opacity(0.12))
                            .clipShape(Circle())
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(BentoCardButtonStyle())
                    .accessibilityLabel("Đóng chọn chế độ")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Title & Subtitle Section
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("REFLEX BLITZ")
                                    .font(.caption.bold())
                                    .tracking(1.2)
                            }
                            .foregroundColor(.vocabPeach)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.vocabPeach.opacity(0.14))
                            .clipShape(Capsule())

                            Text("Luyện phản xạ tốc độ")
                                .font(.title2.weight(.bold))
                                .fontDesign(.serif)
                                .foregroundColor(.vocabInk)

                            Text("Chọn phương pháp phản xạ hôm nay")
                                .font(.subheadline)
                                .foregroundColor(.vocabMuted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 16)

                        // 4 Bento Cards Grid
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(ReflexBlitzMode.allCases) { mode in
                                modeCard(for: Self.modeItem(for: mode))
                            }
                        }
                        .padding(.horizontal, 18)

                        // Bottom Scaffolding Hint
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.vocabHeroAccent)
                            Text("Mỗi từ có giới hạn đếm ngược riêng biệt để tạo phản xạ vô điều kiện.")
                                .font(.caption)
                                .foregroundColor(.vocabMuted)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedModeTrigger)
    }

    @ViewBuilder
    private func modeCard(for item: ReflexBlitzModeItem) -> some View {
        Button(action: {
            selectedModeTrigger = item.mode
            onSelectMode(item.mode)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Row: Mode Icon & Timer Badge
                HStack(alignment: .top) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(item.accentColor)
                        .frame(width: 44, height: 44)
                        .background(item.accentColor.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Spacer(minLength: 4)

                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .bold))
                        Text(item.badgeText)
                            .font(.caption2.monospacedDigit().bold())
                    }
                    .foregroundColor(item.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.accentColor.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.vocabInk)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundColor(.vocabMuted)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                // Action Cue Arrow
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(item.accentColor.opacity(0.7))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
            .background(Color.vocabSurfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.vocabHairline.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(BentoCardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), thời gian \(item.badgeText), \(item.subtitle)")
        .accessibilityHint("Nhấn để bắt đầu luyện tập với chế độ \(item.title)")
    }
}
