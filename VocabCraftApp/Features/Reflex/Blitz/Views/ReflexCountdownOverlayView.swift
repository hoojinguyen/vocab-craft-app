import CraftUIKit
import SwiftUI

/// Apple Fitness+ style full-screen countdown overlay before starting a Reflex Blitz drill.
public struct ReflexCountdownOverlayView: View {
    public let count: Int
    public let mode: ReflexBlitzMode?
    public let title: String?
    public let subtitle: String?
    public let iconName: String?
    public let tintColor: Color?
    public let onFinish: () -> Void

    public init(
        count: Int = 3,
        mode: ReflexBlitzMode = .speaking,
        onFinish: @escaping () -> Void = {}
    ) {
        self.count = count
        self.mode = mode
        self.title = mode.title
        self.subtitle = ReflexCountdownOverlayView.modePromptText(for: mode)
        self.iconName = ReflexCountdownOverlayView.modeIconName(for: mode)
        self.tintColor = nil
        self.onFinish = onFinish
    }

    public init(
        count: Int = 3,
        title: String? = nil,
        subtitle: String? = nil,
        iconName: String? = nil,
        tintColor: Color? = nil,
        onFinish: @escaping () -> Void = {}
    ) {
        self.count = count
        self.mode = nil
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.tintColor = tintColor
        self.onFinish = onFinish
    }

    private static func modePromptText(for mode: ReflexBlitzMode) -> String {
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

    private static func modeIconName(for mode: ReflexBlitzMode) -> String {
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
            title: title,
            subtitle: subtitle,
            iconName: iconName,
            tintColor: tintColor,
            onFinish: onFinish
        )
    }
}
