import CraftUIKit
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
    public var onSelectConfig: ((ReflexBlitzDeepLinkConfig) -> Void)?
    public let onDismiss: () -> Void

    @State private var selectedModeTrigger: ReflexBlitzMode?

    public init(
        onSelectMode: @escaping (ReflexBlitzMode) -> Void,
        onSelectConfig: ((ReflexBlitzDeepLinkConfig) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.onSelectMode = onSelectMode
        self.onSelectConfig = onSelectConfig
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
                // Top Dismiss Bar (Unified Top-Left)
                HStack {
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

                    Spacer()
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
        CraftActionCard(
            title: item.title,
            subtitle: item.subtitle,
            iconName: item.iconName,
            badgeText: item.badgeText,
            badgeIcon: "stopwatch.fill",
            accentColor: item.accentColor,
            showChevron: true
        ) {
            selectedModeTrigger = item.mode
            onSelectMode(item.mode)
        }
    }
}
