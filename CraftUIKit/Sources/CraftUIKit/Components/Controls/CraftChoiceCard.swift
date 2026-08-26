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

private extension CraftSpacingTokens {
    var xxs: CGFloat { xs }
}

// MARK: - CraftChoiceCard Component

/// A quiz option card supporting prefix badges (e.g. A/B/C/D), title, subtitle,
/// status indicators, seamless 3D tactile bottom bevel, spring bounce animations, and horizontal shake feedback.
public struct CraftChoiceCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var shakeCount: CGFloat = 0

    private let prefixKey: LocalizedStringKey?
    private let rawPrefix: String?
    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let subtitleKey: LocalizedStringKey?
    private let rawSubtitle: String?
    private let explicitStyle: CraftSurfaceStyle?

    public var prefix: String? { rawPrefix }
    public var title: String? { rawTitle }
    public var subtitle: String? { rawSubtitle }
    public let state: CraftChoiceState
    public let action: () -> Void

    public var style: CraftSurfaceStyle {
        explicitStyle ?? (environmentSurfaceStyle != .flat ? environmentSurfaceStyle : .tactile3D)
    }

    public var resolvedStyle: CraftSurfaceStyle {
        style
    }

    public init(
        prefix: String? = "A",
        title: String,
        subtitle: String? = nil,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        action: @escaping () -> Void
    ) {
        self.prefixKey = nil
        self.rawPrefix = prefix
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.state = state
        self.explicitStyle = style
        self.action = action
    }

    public init(
        prefix: LocalizedStringKey? = nil,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        action: @escaping () -> Void
    ) {
        self.prefixKey = prefix
        self.rawPrefix = nil
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.state = state
        self.explicitStyle = style
        self.action = action
    }

    public var body: some View {
        cardButton
            .scaleEffect(state == .correct && !reduceMotion ? 1.02 : 1.0)
            .modifier(ChoiceShakeEffect(shakes: shakeCount))
            .animation(theme.animations.springBouncy, value: state)
            .accessibilityElement(children: .combine)
            .accessibilityValue(accessibilityValueDescription)
            .accessibilityAddTraits(state == .selected ? [.isButton, .isSelected] : [.isButton])
            .sensoryFeedback(.selection, trigger: state) { (_: CraftChoiceState, new: CraftChoiceState) -> Bool in new == .selected }
            .sensoryFeedback(.success, trigger: state) { (_: CraftChoiceState, new: CraftChoiceState) -> Bool in new == .correct }
            .sensoryFeedback(.error, trigger: state) { (_: CraftChoiceState, new: CraftChoiceState) -> Bool in new == .wrong }
            .onChange(of: state) { _, newState in
                if newState == .wrong && !reduceMotion {
                    withAnimation(.linear(duration: 0.35)) {
                        shakeCount += 1
                    }
                }
            }
    }

    private var cardButton: some View {
        Button(action: {
            guard state != .disabled else { return }
            action()
        }) {
            cardSurface
        }
        .buttonStyle(CraftChoiceCardButtonStyle(state: state, style: style, depth: theme.depths.depthMd))
        .disabled(state == .disabled)
    }

    private var cardSurface: some View {
        let content = HStack(alignment: .top, spacing: theme.spacing.md) {
            if prefixKey != nil || rawPrefix != nil {
                prefixBadge
                    .padding(.top, 1)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                if let titleKey {
                    Text(titleKey)
                        .font(theme.typography.headline)
                        .foregroundStyle(titleColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                } else if let rawTitle {
                    Text(rawTitle)
                        .font(theme.typography.headline)
                        .foregroundStyle(titleColor)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                if let subtitleKey {
                    Text(subtitleKey)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(subtitleColor)
                        .multilineTextAlignment(.leading)
                } else if let rawSubtitle {
                    Text(rawSubtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(subtitleColor)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: theme.spacing.sm)

            trailingIndicator
                .padding(.top, 2)
        }
        .padding(theme.spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(cardBorderOverlay)
        .overlay(topHighlightOverlay)
        .opacity(state == .disabled ? 0.6 : 1.0)
        .frame(minHeight: 44)
        .contentShape(Rectangle())

        return applyCardShadow(content)
    }

    // MARK: - Card Background & Overlays

    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            switch style {
            case .glass:
                if #available(iOS 26, macOS 26, *) {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceCard)
                    } else {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .glassEffect(cardGlassVariant, in: RoundedRectangle(cornerRadius: theme.radii.lg))
                    }
                } else {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceCard)
                    } else {
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: theme.radii.lg)
                            .fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
                    }
                }
            case .flat:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(theme.colors.surfaceSubtle)
            case .elevated:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(theme.colors.surfaceElevated)
            case .outlined, .tactile3D:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(theme.colors.surfaceCard)
            }

            if state != .idle && state != .disabled && (style != .glass || reduceTransparency) {
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(stateTintOverlay)
            }
        }
    }

    @available(iOS 26, macOS 26, *)
    private var cardGlassVariant: Glass {
        switch state {
        case .idle:
            return .regular.interactive()
        case .selected:
            return .regular.tint(theme.colors.brandPrimary).interactive()
        case .correct:
            return .regular.tint(theme.colors.statusSuccess).interactive()
        case .wrong:
            return .regular.tint(theme.colors.statusDanger).interactive()
        case .disabled:
            return .clear
        }
    }

    private var stateTintOverlay: Color {
        switch state {
        case .idle, .disabled:
            return .clear
        case .selected:
            return .craftDynamic(
                light: theme.colors.brandPrimary.opacity(0.08),
                dark: theme.colors.brandPrimary.opacity(0.16)
            )
        case .correct:
            return .craftDynamic(
                light: theme.colors.statusSuccess.opacity(0.10),
                dark: theme.colors.statusSuccess.opacity(0.18)
            )
        case .wrong:
            return .craftDynamic(
                light: theme.colors.statusDanger.opacity(0.10),
                dark: theme.colors.statusDanger.opacity(0.18)
            )
        }
    }

    @ViewBuilder
    private var cardBorderOverlay: some View {
        if state != .idle && state != .disabled {
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        } else {
            switch style {
            case .flat:
                if state == .disabled {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .strokeBorder(theme.colors.borderDefault.opacity(0.35), lineWidth: 1)
                } else {
                    EmptyView()
                }
            case .elevated:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                                .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            case .outlined, .tactile3D:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            case .glass:
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var topHighlightOverlay: some View {
        if state != .disabled {
            if style == .tactile3D {
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            } else if style == .glass {
                if #unavailable(iOS 26, macOS 26) {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
                }
            }
        }
    }

    @ViewBuilder
    private func applyCardShadow<V: View>(_ view: V) -> some View {
        switch style {
        case .elevated:
            view.craftShadow(theme.shadows.md)
        case .glass:
            view.craftShadow(theme.shadows.sm)
        case .flat, .outlined, .tactile3D:
            view
        }
    }

    // MARK: - Sub-Component: Prefix Badge (A/B/C/D)

    @ViewBuilder
    private var prefixBadge: some View {
        Group {
            if let prefixKey {
                Text(prefixKey)
            } else if let rawPrefix {
                Text(rawPrefix)
            }
        }
        .font(theme.typography.headline.bold())
        .fontDesign(.rounded)
        .foregroundStyle(prefixForegroundColor)
        .frame(minWidth: 32, minHeight: 32)
        .padding(.horizontal, 6)
        .background(prefixBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
        .overlay(prefixBorderOverlay)
        .fixedSize()
    }

    @ViewBuilder
    private var prefixBackground: some View {
        switch style {
        case .glass:
            if #available(iOS 26, macOS 26, *) {
                if reduceTransparency {
                    prefixSolidBackground
                } else {
                    RoundedRectangle(cornerRadius: theme.radii.sm)
                        .glassEffect(prefixGlassVariant, in: RoundedRectangle(cornerRadius: theme.radii.sm))
                }
            } else {
                if reduceTransparency {
                    prefixSolidBackground
                } else {
                    RoundedRectangle(cornerRadius: theme.radii.sm)
                        .fill(.ultraThinMaterial)
                        .overlay(prefixTintOverlay)
                }
            }
        case .flat, .elevated, .outlined, .tactile3D:
            prefixSolidBackground
        }
    }

    private var prefixSolidBackground: some View {
        RoundedRectangle(cornerRadius: theme.radii.sm)
            .fill(prefixBackgroundColor)
    }

    @available(iOS 26, macOS 26, *)
    private var prefixGlassVariant: Glass {
        switch state {
        case .idle:
            return .regular
        case .selected:
            return .regular.tint(theme.colors.brandPrimary)
        case .correct:
            return .regular.tint(theme.colors.statusSuccess)
        case .wrong:
            return .regular.tint(theme.colors.statusDanger)
        case .disabled:
            return .clear
        }
    }

    private var prefixTintOverlay: Color {
        switch state {
        case .idle, .disabled:
            return .clear
        case .selected:
            return theme.colors.brandPrimary.opacity(0.18)
        case .correct:
            return theme.colors.statusSuccess.opacity(0.20)
        case .wrong:
            return theme.colors.statusDanger.opacity(0.20)
        }
    }

    private var prefixForegroundColor: Color {
        switch style {
        case .glass:
            switch state {
            case .idle:
                return theme.colors.textPrimary
            case .selected:
                return theme.colors.brandPrimary
            case .correct:
                return theme.colors.statusSuccess
            case .wrong:
                return theme.colors.statusDanger
            case .disabled:
                return theme.colors.textMuted
            }
        case .flat, .elevated, .outlined, .tactile3D:
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

    @ViewBuilder
    private var prefixBorderOverlay: some View {
        switch style {
        case .glass:
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
        case .flat:
            if state == .idle {
                EmptyView()
            } else {
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .strokeBorder(prefixStrokeColor, lineWidth: 1)
            }
        case .elevated:
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .strokeBorder(prefixStrokeColor.opacity(0.3), lineWidth: 1)
        case .outlined, .tactile3D:
            RoundedRectangle(cornerRadius: theme.radii.sm)
                .strokeBorder(prefixStrokeColor, lineWidth: 1)
        }
    }

    private var prefixStrokeColor: Color {
        switch state {
        case .idle:
            return theme.colors.borderDefault
        case .selected, .correct, .wrong:
            return Color.white.opacity(0.35)
        case .disabled:
            return theme.colors.borderDefault.opacity(0.4)
        }
    }

    // MARK: - Sub-Component: Trailing Indicator

    @ViewBuilder
    private var trailingIndicator: some View {
        switch state {
        case .correct:
            CraftIcon(.checkmarkCircle, size: .md, color: theme.colors.statusSuccess, renderingMode: .hierarchical)
                .symbolEffect(.bounce, value: state)
                .transition(.scale.combined(with: .opacity))
        case .wrong:
            CraftIcon(.wrongCircle, size: .md, color: theme.colors.statusDanger, renderingMode: .hierarchical)
                .symbolEffect(.bounce, value: state)
                .transition(.scale.combined(with: .opacity))
        case .idle, .selected, .disabled:
            EmptyView()
        }
    }

    // MARK: - Accessibility & Semantic Colors

    private var accessibilityValueDescription: String {
        switch state {
        case .idle:
            return ""
        case .selected:
            return CraftLocalized.string("craft.choice.selected")
        case .correct:
            return CraftLocalized.string("craft.choice.correct")
        case .wrong:
            return CraftLocalized.string("craft.choice.wrong")
        case .disabled:
            return CraftLocalized.string("craft.choice.disabled")
        }
    }

    private var titleColor: Color {
        switch state {
        case .idle, .correct, .wrong, .selected:
            return theme.colors.textPrimary
        case .disabled:
            return theme.colors.textMuted
        }
    }

    private var subtitleColor: Color {
        switch state {
        case .idle, .selected, .correct, .wrong:
            return theme.colors.textSecondary
        case .disabled:
            return theme.colors.textMuted
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
            return theme.colors.borderDefault.opacity(0.35)
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
}

// MARK: - Choice Card ButtonStyle

public struct CraftChoiceCardButtonStyle: ButtonStyle {
    public let state: CraftChoiceState
    public let style: CraftSurfaceStyle
    public let depth: CGFloat
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(state: CraftChoiceState = .idle, style: CraftSurfaceStyle = .tactile3D, depth: CGFloat = 4) {
        self.state = state
        self.style = style
        self.depth = depth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && state != .disabled
        let isTactile = style == .tactile3D
        let effectiveDepth = isTactile ? depth : 0
        let depressOffset = (isPressed && isTactile) ? depth : 0

        ZStack(alignment: .top) {
            // Seamless extruded 3D base layer
            if state != .disabled && isTactile {
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(bottomLipColor)
                    .padding(.top, depth)
            }

            // Top interactive card face
            configuration.label
                .offset(y: depressOffset)
        }
        .padding(.bottom, (state == .disabled || !isTactile) ? 0 : effectiveDepth)
        .scaleEffect(isPressed && !reduceMotion ? (isTactile ? 0.99 : 0.98) : 1.0)
        .animation(theme.animations.springSnappy, value: isPressed)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in
            pressed
        }
    }

    private var bottomLipColor: Color {
        switch state {
        case .idle:
            return theme.colors.borderDefault
        case .selected:
            return theme.colors.brandSecondary
        case .correct:
            return theme.colors.statusSuccess
        case .wrong:
            return theme.colors.statusDanger
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
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Modern Tactile 3D (Default)")
                    .font(.headline)

                CraftChoiceCard(
                    prefix: "A",
                    title: "Idle State",
                    subtitle: "This is the default tactile state",
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

            VStack(alignment: .leading, spacing: 12) {
                Text("Liquid Glass Style")
                    .font(.headline)

                CraftChoiceCard(
                    prefix: "A",
                    title: "Glass Idle",
                    state: .idle,
                    style: .glass
                ) {}

                CraftChoiceCard(
                    prefix: "B",
                    title: "Glass Selected",
                    state: .selected,
                    style: .glass
                ) {}

                CraftChoiceCard(
                    prefix: "C",
                    title: "Glass Correct",
                    state: .correct,
                    style: .glass
                ) {}
            }
        }
        .padding()
    }
}
