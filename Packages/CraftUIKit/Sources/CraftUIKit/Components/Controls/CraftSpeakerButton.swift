import SwiftUI

/// Visual style variants for speaker audio button.
public enum CraftSpeakerButtonVariant: String, Sendable, CaseIterable {
    case subtle
    case filled
    case ghost
}

/// A dedicated pronunciation and audio playback button adhering to Apple HIG and CraftUIKit design tokens.
public struct CraftSpeakerButton: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public let variant: CraftSpeakerButtonVariant
    public let size: CraftIconSize
    public let isPlaying: Bool
    public let label: LocalizedStringKey?
    public let customTint: Color?
    public let action: () -> Void

    public init(
        variant: CraftSpeakerButtonVariant = .subtle,
        size: CraftIconSize = .md,
        isPlaying: Bool = false,
        label: LocalizedStringKey? = nil,
        customTint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.variant = variant
        self.size = size
        self.isPlaying = isPlaying
        self.label = label
        self.customTint = customTint
        self.action = action
    }

    private var effectiveTint: Color {
        customTint ?? theme.colors.brandPrimary
    }

    private var visualDimension: CGFloat {
        switch size {
        case .sm: return 32
        case .md: return 40
        case .lg: return 48
        case .xl: return 56
        }
    }

    private var iconSizePt: CGFloat {
        switch size {
        case .sm: return 14
        case .md: return 18
        case .lg: return 22
        case .xl: return 26
        }
    }

    @State private var hapticTrigger: Int = 0

    public var body: some View {
        Button(action: {
            hapticTrigger &+= 1
            action()
        }) {
            if let label {
                pillContent(label: label)
            } else {
                circleContent
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .accessibilityLabel(CraftLocalized.string(isPlaying ? "craft.audio.playing" : "craft.audio.pronounce"))
        .accessibilityAddTraits(.isButton)
    }

    private var circleContent: some View {
        ZStack {
            backgroundShape(for: Circle())
            speakerIcon
        }
        .frame(width: visualDimension, height: visualDimension)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
    }

    private func pillContent(label: LocalizedStringKey) -> some View {
        HStack(spacing: theme.spacing.xs) {
            speakerIcon
            Text(label, bundle: .module)
                .font(theme.typography.label)
                .foregroundStyle(foregroundColor)
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(
            backgroundShape(for: Capsule())
        )
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var speakerIcon: some View {
        let iconName = isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill"
        Image(systemName: iconName)
            .font(.system(size: iconSizePt, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .symbolRenderingMode(.hierarchical)
            .contentTransition(.symbolEffect(.replace))
    }

    private var foregroundColor: Color {
        switch variant {
        case .filled:
            return theme.colors.textInverse
        case .subtle, .ghost:
            return effectiveTint
        }
    }

    @ViewBuilder
    private func backgroundShape<S: InsettableShape>(for shape: S) -> some View {
        switch variant {
        case .filled:
            shape.fill(effectiveTint)
        case .subtle:
            shape.fill(effectiveTint.opacity(0.12))
        case .ghost:
            shape.fill(Color.clear)
        }
    }
}

// MARK: - Previews

#Preview("CraftSpeakerButton Variants") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            CraftSpeakerButton(variant: .subtle, isPlaying: false, action: {})
            CraftSpeakerButton(variant: .filled, isPlaying: true, action: {})
            CraftSpeakerButton(variant: .ghost, isPlaying: false, action: {})
        }

        HStack(spacing: 16) {
            CraftSpeakerButton(
                variant: .subtle,
                size: .md,
                isPlaying: false,
                label: "craft.audio.pronounce",
                action: {}
            )
            CraftSpeakerButton(
                variant: .filled,
                size: .md,
                isPlaying: true,
                label: "craft.audio.playing",
                action: {}
            )
        }
    }
    .padding()
}
