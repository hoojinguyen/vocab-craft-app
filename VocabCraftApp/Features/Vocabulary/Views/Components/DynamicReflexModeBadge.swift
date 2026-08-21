import SwiftUI

/// Mode badge component displaying the active reflex mode (Multiple Choice, Speaking, Typing, Listening)
/// along with its SF Symbol icon and time duration limit.
/// Pure Apple SF Symbols only — strictly adheres to anti-AI-slop design guidelines.
public struct DynamicReflexModeBadge: View {
    public let mode: ReflexBlitzMode
    public var isCompact: Bool

    public init(mode: ReflexBlitzMode, isCompact: Bool = false) {
        self.mode = mode
        self.isCompact = isCompact
    }

    private var modeIconName: String {
        switch mode {
        case .multipleChoice:
            return "square.grid.2x2.fill"
        case .speaking:
            return "waveform.and.mic"
        case .typing:
            return "keyboard.fill"
        case .listening:
            return "headphones"
        }
    }

    private var accentColor: Color {
        switch mode {
        case .multipleChoice:
            return .vocabLavender
        case .speaking:
            return .vocabMint
        case .typing:
            return .vocabPeach
        case .listening:
            return .vocabHeroAccent
        }
    }

    private var formattedDuration: String {
        String(format: "%.1fs", mode.timeLimitSeconds)
    }

    public var body: some View {
        HStack(spacing: isCompact ? 6 : 8) {
            // Mode SF Symbol Icon
            Image(systemName: modeIconName)
                .font(.system(size: isCompact ? 12 : 14, weight: .bold))
                .foregroundColor(accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: isCompact ? 22 : 26, height: isCompact ? 22 : 26)
                .background(accentColor.opacity(0.14))
                .clipShape(Circle())

            // Mode Title
            Text(mode.title)
                .font(.system(size: isCompact ? 12 : 13, weight: .bold, design: .rounded))
                .foregroundColor(.vocabInk)

            // Duration Pill Tag
            HStack(spacing: 3) {
                Image(systemName: "stopwatch")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(accentColor)

                Text(formattedDuration)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, isCompact ? 5 : 7)
            .padding(.vertical, 3)
            .background(accentColor.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.horizontal, isCompact ? 8 : 12)
        .padding(.vertical, isCompact ? 4 : 6)
        .background(Color.vocabSurfaceCard)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(accentColor.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(0.10), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chế độ: \(mode.title), giới hạn thời gian \(formattedDuration)")
    }
}
