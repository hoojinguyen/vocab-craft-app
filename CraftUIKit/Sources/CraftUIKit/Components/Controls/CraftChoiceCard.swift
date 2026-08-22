import SwiftUI
#if os(iOS)
import UIKit
#endif

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

    public let prefix: String?
    public let title: String
    public let subtitle: String?
    public let state: CraftChoiceState
    public let action: () -> Void

    public init(
        prefix: String? = "A",
        title: String,
        subtitle: String? = nil,
        state: CraftChoiceState = .idle,
        action: @escaping () -> Void
    ) {
        self.prefix = prefix
        self.title = title
        self.subtitle = subtitle
        self.state = state
        self.action = action
    }

    public var body: some View {
        Button(action: {
            guard state != .disabled else { return }
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            #endif
            action()
        }) {
            HStack(spacing: theme.spacing.md) {
                if let prefix {
                    prefixBadge(prefix)
                }

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(title)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    if let subtitle {
                        Text(subtitle)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
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
        .buttonStyle(PlainButtonStyle())
        .craftPressEffect(scale: state == .disabled ? 1.0 : 0.98)
        .disabled(state == .disabled)
        .onChange(of: state) { _, newState in
            if newState == .wrong && !reduceMotion {
                withAnimation(.linear(duration: 0.35)) {
                    shakeCount += 1
                }
            }
        }
    }

    @ViewBuilder
    private func prefixBadge(_ text: String) -> some View {
        Text(text)
            .font(theme.typography.headline)
            .fontWeight(.semibold)
            .foregroundColor(prefixForegroundColor)
            .frame(width: 32, height: 32)
            .background(prefixBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
    }

    @ViewBuilder
    private var trailingIndicator: some View {
        switch state {
        case .correct:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.colors.statusSuccess)
        case .wrong:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.colors.statusDanger)
        case .idle, .selected, .disabled:
            EmptyView()
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .idle, .disabled:
            return theme.colors.surfaceCard
        case .selected:
            return theme.colors.brandPrimary.opacity(0.08)
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
