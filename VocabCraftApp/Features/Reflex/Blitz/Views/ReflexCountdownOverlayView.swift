import CraftUIKit
import SwiftUI

/// Apple Fitness+ style full-screen countdown overlay before starting a Reflex Blitz drill.
public struct ReflexCountdownOverlayView: View {
    public let count: Int
    public let mode: ReflexBlitzMode
    public let onFinish: () -> Void

    public init(
        count: Int = 3,
        mode: ReflexBlitzMode = .speaking,
        onFinish: @escaping () -> Void = {}
    ) {
        self.count = count
        self.mode = mode
        self.onFinish = onFinish
    }

    private var modePromptText: String {
        switch mode {
        case .speaking:
            return AppStrings.ReflexBlitz.speakingInstructionText
        case .typing:
            return AppStrings.ReflexBlitz.typingInstructionText
        case .multipleChoice:
            return AppStrings.ReflexBlitz.mcInstructionText
        case .listening:
            return AppStrings.ReflexBlitz.listeningModeInstructionText
        }
    }

    private var modeIconName: String {
        switch mode {
        case .speaking:
            return "waveform.and.mic"
        case .typing:
            return "keyboard"
        case .multipleChoice:
            return "square.grid.2x2.fill"
        case .listening:
            return "headphones"
        }
    }

    public var body: some View {
        CraftCountdownOverlay(
            startNumber: count,
            title: mode.title,
            subtitle: modePromptText,
            iconName: modeIconName,
            onFinish: onFinish
        )
    }
}
