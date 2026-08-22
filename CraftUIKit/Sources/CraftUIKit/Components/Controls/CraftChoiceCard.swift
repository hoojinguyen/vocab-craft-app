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
/// status indicators, spring bounce animations, and horizontal shake feedback.
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
            .scaleEffect(state == .correct && !reduceMotion ? 1.02 : 1.0)
            .modifier(ChoiceShakeEffect(shakes: shakeCount))
            .animation(theme.animations.springBouncy, value: state)
            .opacity(state == .disabled ? 0.5 : 1.0)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.craftPress(scale: state == .disabled ? 1.0 : 0.98))
        .disabled(state == .disabled)
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValueDescription)
        .accessibilityAddTraits(state == .selected ? [.isButton, .isSelected] : [.isButton])
        .onChange(of: state) { _, newState in
            if newState == .wrong && !reduceMotion {
                withAnimation(.linear(duration: 0.35)) {
                    shakeCount += 1
                }
            }
        }
    }

    @ViewBuilder
    private var prefixBadge: some View {
        Group {
            if let prefixKey {
                Text(prefixKey)
            } else if let rawPrefix {
                Text(rawPrefix)
            }
        }
        .font(theme.typography.headline)
        .fontWeight(.semibold)
        .foregroundStyle(prefixForegroundColor)
        .frame(width: 32, height: 32)
        .background(prefixBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
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
            return theme.colors.brandPrimary.opacity(0.16)
        case .correct:
            return theme.colors.statusSuccess.opacity(0.16)
        case .wrong:
            return theme.colors.statusDanger.opacity(0.16)
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
}

// MARK: - Choice Shake Effect

private struct ChoiceShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    init(shakes: CGFloat, amount: CGFloat = 8, shakesPerUnit: Int = 3) {
        self.animatableData = shakes
        self.amount = amount
        self.shakesPerUnit = shakesPerUnit
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
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
