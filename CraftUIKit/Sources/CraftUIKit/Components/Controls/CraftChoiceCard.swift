import SwiftUI

// MARK: - Choice State

/// Interactive selection and validation state for quiz choice cards.
public enum CraftChoiceState: String, Sendable, Equatable, Hashable, CaseIterable {
    case idle
    case selected
    case correct
    case wrong
    case disabled
}

// MARK: - CraftChoiceCard Component

/// A quiz option card supporting prefix badges (e.g. A/B/C/D), title, subtitle,
/// status indicators, 3D tactile bottom bevel, spring bounce animations, and horizontal shake feedback.
public struct CraftChoiceCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shakeCount: CGFloat = 0

    private let prefixKey: LocalizedStringKey?
    private let rawPrefix: String?
    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let subtitleKey: LocalizedStringKey?
    private let rawSubtitle: String?

    public var prefix: String? { rawPrefix }
    public var title: String? { rawTitle }
    public var subtitle: String? { rawSubtitle }
    public let state: CraftChoiceState
    public let action: () -> Void

    public init(
        prefix: String? = "A",
        title: String,
        subtitle: String? = nil,
        state: CraftChoiceState = .idle,
        action: @escaping () -> Void
    ) {
        self.prefixKey = nil
        self.rawPrefix = prefix
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.state = state
        self.action = action
    }

    public init(
        prefix: LocalizedStringKey? = nil,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        state: CraftChoiceState = .idle,
        action: @escaping () -> Void
    ) {
        self.prefixKey = prefix
        self.rawPrefix = nil
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.state = state
        self.action = action
    }

    public var body: some View {
        Button(action: {
            guard state != .disabled else { return }
            action()
        }) {
            cardSurface
        }
        .buttonStyle(CraftChoiceCardButtonStyle(state: state, depth: theme.depths.depthMd))
        .disabled(state == .disabled)
        .scaleEffect(state == .correct && !reduceMotion ? 1.02 : 1.0)
        .modifier(ChoiceShakeEffect(shakes: shakeCount))
        .animation(theme.animations.springBouncy, value: state)
        .opacity(state == .disabled ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValueDescription)
        .accessibilityAddTraits(state == .selected ? [.isButton, .isSelected] : [.isButton])
        .onChange(of: state) { _, newState in
            #if os(iOS)
            if newState == .correct {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
            } else if newState == .wrong {
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.error)
            }
            #endif
            if newState == .wrong && !reduceMotion {
                withAnimation(.linear(duration: 0.35)) {
                    shakeCount += 1
                }
            }
        }
    }

    private var cardSurface: some View {
        HStack(spacing: theme.spacing.md) {
            if prefixKey != nil || rawPrefix != nil {
                prefixBadge
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if let titleKey {
                    Text(titleKey)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                } else if let rawTitle {
                    Text(rawTitle)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                }

                if let subtitleKey {
                    Text(subtitleKey)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                } else if let rawSubtitle {
                    Text(rawSubtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: theme.spacing.sm)

            trailingIndicator
        }
        .padding(theme.spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        .overlay(topHighlightOverlay)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var topHighlightOverlay: some View {
        if state != .disabled {
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .strokeBorder(
                    theme.depths.topHighlight,
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var prefixBadge: some View {
        ZStack {
            // Embossed 3D bottom bevel / rim
            if state != .disabled {
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .fill(prefixBottomRimColor)
                    .offset(y: 2)
            }

            // Top surface
            Group {
                if let prefixKey {
                    Text(prefixKey)
                } else if let rawPrefix {
                    Text(rawPrefix)
                }
            }
            .font(theme.typography.headline)
            .fontWeight(.bold)
            .foregroundStyle(prefixForegroundColor)
            .frame(width: 32, height: 32)
            .background(prefixBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .strokeBorder(prefixBorderStroke, lineWidth: 1)
            )
        }
        .frame(width: 32, height: 34)
    }

    @ViewBuilder
    private var trailingIndicator: some View {
        switch state {
        case .correct:
            CraftIcon(
                .checkmarkCircle,
                size: .lg,
                color: theme.colors.statusSuccess,
                renderingMode: .hierarchical,
                weight: .bold
            )
        case .wrong:
            CraftIcon(
                .wrongCircle,
                size: .lg,
                color: theme.colors.statusDanger,
                renderingMode: .hierarchical,
                weight: .bold
            )
        case .idle, .selected, .disabled:
            EmptyView()
        }
    }

    private var accessibilityValueDescription: String {
        switch state {
        case .idle:
            return ""
        case .selected:
            return "Selected"
        case .correct:
            return "Correct Answer"
        case .wrong:
            return "Incorrect Answer"
        case .disabled:
            return "Disabled"
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle, .disabled:
            return theme.colors.surfaceCard
        case .selected:
            return theme.colors.brandPrimary.opacity(0.12)
        case .correct:
            return theme.colors.statusSuccess.opacity(0.12)
        case .wrong:
            return theme.colors.statusDanger.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:
            return theme.colors.borderDefault
        case .selected:
            return theme.colors.brandPrimary
        case .correct:
            return theme.colors.statusSuccess
        case .wrong:
            return theme.colors.statusDanger
        case .disabled:
            return theme.colors.borderDefault.opacity(0.5)
        }
    }

    private var borderWidth: CGFloat {
        switch state {
        case .idle, .disabled:
            return 1.5
        case .selected, .correct, .wrong:
            return 2.0
        }
    }

    private var prefixForegroundColor: Color {
        switch state {
        case .idle:
            return theme.colors.textPrimary
        case .selected:
            return theme.colors.textInverse
        case .correct, .wrong:
            return .white
        case .disabled:
            return theme.colors.textMuted
        }
    }

    private var prefixBackgroundColor: Color {
        switch state {
        case .idle:
            return theme.colors.surfaceSubtle
        case .selected:
            return theme.colors.brandPrimary
        case .correct:
            return theme.colors.statusSuccess
        case .wrong:
            return theme.colors.statusDanger
        case .disabled:
            return theme.colors.surfaceSubtle.opacity(0.5)
        }
    }

    private var prefixBottomRimColor: Color {
        switch state {
        case .idle:
            return theme.colors.borderDefault
        case .selected:
            return theme.colors.brandSecondary
        case .correct:
            return Color(hex: 0x059669)
        case .wrong:
            return Color(hex: 0xDC2626)
        case .disabled:
            return .clear
        }
    }

    private var prefixBorderStroke: Color {
        switch state {
        case .idle:
            return theme.colors.borderDefault.opacity(0.6)
        case .selected, .correct, .wrong:
            return Color.white.opacity(0.3)
        case .disabled:
            return .clear
        }
    }
}

// MARK: - Choice Card ButtonStyle

public struct CraftChoiceCardButtonStyle: ButtonStyle {
    public let state: CraftChoiceState
    public let depth: CGFloat
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(state: CraftChoiceState = .idle, depth: CGFloat = 4) {
        self.state = state
        self.depth = depth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && state != .disabled
        let depressOffset = isPressed ? depth : 0

        ZStack {
            if state != .disabled {
                // Bottom 3D Bevel / Lip
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(bottomLipColor)
                    .offset(y: depth)
            }

            // Top Card Face
            configuration.label
                .offset(y: depressOffset)
        }
        .padding(.bottom, state == .disabled ? 0 : depth)
        .scaleEffect(isPressed && !reduceMotion ? 0.99 : 1.0)
        .animation(theme.animations.springSnappy, value: isPressed)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onChange(of: configuration.isPressed) { _, pressed in
            #if os(iOS)
            if pressed && state != .disabled {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            #endif
        }
    }

    private var bottomLipColor: Color {
        switch state {
        case .idle:
            return theme.colors.borderDefault
        case .selected:
            return theme.colors.brandSecondary
        case .correct:
            return Color(hex: 0x059669)
        case .wrong:
            return Color(hex: 0xDC2626)
        case .disabled:
            return .clear
        }
    }
}

// MARK: - Choice Shake Effect

public struct ChoiceShakeEffect: GeometryEffect {
    public var amount: CGFloat = 8
    public var shakesPerUnit = 3
    public var animatableData: CGFloat

    public init(shakes: CGFloat, amount: CGFloat = 8, shakesPerUnit: Int = 3) {
        self.animatableData = shakes
        self.amount = amount
        self.shakesPerUnit = shakesPerUnit
    }

    public func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview("CraftChoiceCard") {
    ScrollView {
        VStack(spacing: 16) {
            CraftChoiceCard(
                prefix: "A",
                title: "Idle State",
                subtitle: "This is the default state",
                state: .idle
            ) {}
            
            CraftChoiceCard(
                prefix: "B",
                title: "Selected State",
                subtitle: "Currently selected option",
                state: .selected
            ) {}
            
            CraftChoiceCard(
                prefix: "C",
                title: "Correct Answer",
                state: .correct
            ) {}
            
            CraftChoiceCard(
                prefix: "D",
                title: "Incorrect Answer",
                subtitle: "Shake animation plays on appear",
                state: .wrong
            ) {}
            
            CraftChoiceCard(
                prefix: "E",
                title: "Disabled Option",
                state: .disabled
            ) {}
        }
        .padding()
    }
}
