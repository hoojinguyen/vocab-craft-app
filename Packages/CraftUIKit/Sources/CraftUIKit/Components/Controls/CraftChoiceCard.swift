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

// MARK: - Choice Prefix Style

/// Visual badge styling for choice option prefixes (e.g. A/B/C/D).
public enum CraftChoicePrefixStyle: String, Sendable, Equatable, Hashable, CaseIterable {
    /// Elegant circle badge with crisp baseline alignment (Default).
    case circle
    /// Soft squircle badge with subtle corner curvature.
    case roundedSquare
    /// Clean editorial typography with no bounding container or border.
    case minimal
    /// Completely hidden prefix badge (useful for survey and settings checklists).
    case none
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
    public let prefixStyle: CraftChoicePrefixStyle
    private let titleKey: LocalizedStringKey?
    private let rawTitle: String?
    private let subtitleKey: LocalizedStringKey?
    private let rawSubtitle: String?
    public let textAlignment: TextAlignment
    private let explicitStyle: CraftSurfaceStyle?
    public let showsStatusIndicator: Bool
    public let correctIconName: String?
    public let wrongIconName: String?

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

    public var hasSubtitle: Bool {
        if subtitleKey != nil {
            return true
        }
        if let rawSubtitle, !rawSubtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    public init(
        prefix: String? = "A",
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: String,
        subtitle: String? = nil,
        textAlignment: TextAlignment = .leading,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        showsStatusIndicator: Bool = true,
        correctIconName: String? = nil,
        wrongIconName: String? = nil,
        action: @escaping () -> Void
    ) {
        self.prefixKey = nil
        self.rawPrefix = prefix
        self.prefixStyle = prefixStyle
        self.titleKey = nil
        self.rawTitle = title
        self.subtitleKey = nil
        self.rawSubtitle = subtitle
        self.textAlignment = textAlignment
        self.state = state
        self.explicitStyle = style
        self.showsStatusIndicator = showsStatusIndicator
        self.correctIconName = correctIconName
        self.wrongIconName = wrongIconName
        self.action = action
    }

    public init(
        prefix: LocalizedStringKey? = nil,
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        textAlignment: TextAlignment = .leading,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        showsStatusIndicator: Bool = true,
        correctIconName: String? = nil,
        wrongIconName: String? = nil,
        action: @escaping () -> Void
    ) {
        self.prefixKey = prefix
        self.rawPrefix = nil
        self.prefixStyle = prefixStyle
        self.titleKey = title
        self.rawTitle = nil
        self.subtitleKey = subtitle
        self.rawSubtitle = nil
        self.textAlignment = textAlignment
        self.state = state
        self.explicitStyle = style
        self.showsStatusIndicator = showsStatusIndicator
        self.correctIconName = correctIconName
        self.wrongIconName = wrongIconName
        self.action = action
    }

    public init(
        prefix: String? = "A",
        prefixStyle: CraftChoicePrefixStyle = .circle,
        title: String,
        subtitle: String? = nil,
        textAlignment: TextAlignment = .leading,
        state: CraftChoiceState = .idle,
        style: CraftSurfaceStyle? = nil,
        showsStatusIndicator: Bool = true,
        correctSymbol: CraftSymbol,
        wrongSymbol: CraftSymbol? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            prefix: prefix,
            prefixStyle: prefixStyle,
            title: title,
            subtitle: subtitle,
            textAlignment: textAlignment,
            state: state,
            style: style,
            showsStatusIndicator: showsStatusIndicator,
            correctIconName: correctSymbol.rawValue,
            wrongIconName: wrongSymbol?.rawValue,
            action: action
        )
    }

    public var body: some View {
        cardButton
            .scaleEffect(state == .correct && !reduceMotion ? 1.02 : 1.0)
            .modifier(ChoiceShakeEffect(shakes: shakeCount))
            .craftSquashAndStretch(trigger: state)
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

    private var isCenteredLayout: Bool {
        textAlignment == .center && (prefixStyle == .none || (prefixKey == nil && rawPrefix == nil)) && (!showsStatusIndicator || (state != .correct && state != .wrong))
    }

    private var contentHorizontalAlignment: HorizontalAlignment {
        switch textAlignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    @ViewBuilder
    private var cardSurface: some View {
        let content = Group {
            if isCenteredLayout {
                VStack(alignment: .center, spacing: theme.spacing.xxs) {
                    titleAndSubtitleContent
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                HStack(alignment: hasSubtitle ? .top : .center, spacing: theme.spacing.md) {
                    if prefixStyle != .none && (prefixKey != nil || rawPrefix != nil) {
                        prefixBadge
                            .padding(.top, hasSubtitle ? 1 : 0)
                    }

                    VStack(alignment: contentHorizontalAlignment, spacing: theme.spacing.xxs) {
                        titleAndSubtitleContent
                    }
                    .frame(maxWidth: textAlignment == .center ? .infinity : nil, alignment: textAlignment == .center ? .center : (textAlignment == .trailing ? .trailing : .leading))

                    if textAlignment != .center {
                        Spacer(minLength: theme.spacing.sm)
                    }

                    if showsStatusIndicator {
                        trailingIndicator
                            .padding(.top, hasSubtitle ? 2 : 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: textAlignment == .center ? .center : (textAlignment == .trailing ? .trailing : .leading))
            }
        }
        .padding(theme.spacing.base)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
        .overlay(cardBorderOverlay)
        .overlay(topHighlightOverlay)
        .opacity(state == .disabled ? 0.6 : 1.0)
        .frame(minHeight: 44)
        .contentShape(Rectangle())

        applyCardShadow(content)
    }

    @ViewBuilder
    private var titleAndSubtitleContent: some View {
        if let titleKey {
            Text(titleKey)
                .font(theme.typography.headline)
                .foregroundStyle(titleColor)
                .lineLimit(3)
                .multilineTextAlignment(textAlignment)
        } else if let rawTitle {
            Text(rawTitle)
                .font(theme.typography.headline)
                .foregroundStyle(titleColor)
                .lineLimit(3)
                .multilineTextAlignment(textAlignment)
        }

        if let subtitleKey {
            Text(subtitleKey)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(subtitleColor)
                .multilineTextAlignment(textAlignment)
        } else if let rawSubtitle, !rawSubtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(rawSubtitle)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(subtitleColor)
                .multilineTextAlignment(textAlignment)
        }
    }

    // MARK: - Card Background & Overlays

    @ViewBuilder
    private var cardBackground: some View {
        ZStack {
            switch style {
            case .glass:
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(theme.colors.surfaceCard)
                } else {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
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

            if state != .idle && state != .disabled {
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(stateTintOverlay)
            }
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
                light: theme.colors.statusSuccess.opacity(0.08),
                dark: theme.colors.statusSuccess.opacity(0.16)
            )
        case .wrong:
            return .craftDynamic(
                light: theme.colors.statusDanger.opacity(0.08),
                dark: theme.colors.statusDanger.opacity(0.16)
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
                if state == .idle {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
                }
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
        switch prefixStyle {
        case .circle:
            circlePrefixBadge
        case .roundedSquare:
            roundedSquarePrefixBadge
        case .minimal:
            minimalPrefixBadge
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var prefixText: some View {
        if let prefixKey {
            Text(prefixKey)
        } else if let rawPrefix {
            Text(rawPrefix)
        }
    }

    private var circlePrefixBadge: some View {
        prefixText
            .font(theme.typography.headline.bold())
            .fontDesign(.rounded)
            .foregroundStyle(prefixForegroundColor)
            .padding(.horizontal, 4)
            .frame(minWidth: 32, minHeight: 32)
            .background(
                Circle()
                    .fill(prefixBackgroundColor)
            )
            .overlay(
                Circle()
                    .strokeBorder(prefixStrokeColor, lineWidth: 1)
            )
            .fixedSize()
    }

    private var roundedSquarePrefixBadge: some View {
        prefixText
            .font(theme.typography.headline.bold())
            .fontDesign(.rounded)
            .foregroundStyle(prefixForegroundColor)
            .padding(.horizontal, 6)
            .frame(minWidth: 32, minHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .fill(prefixBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.sm)
                    .strokeBorder(prefixStrokeColor, lineWidth: 1)
            )
            .fixedSize()
    }

    private var minimalPrefixBadge: some View {
        prefixText
            .font(theme.typography.headline.bold())
            .fontDesign(.rounded)
            .foregroundStyle(minimalPrefixForegroundColor)
            .fixedSize()
    }

    private var minimalPrefixForegroundColor: Color {
        switch state {
        case .idle:
            return theme.colors.textSecondary
        case .selected:
            return theme.colors.brandPrimary
        case .correct:
            return theme.colors.statusSuccess
        case .wrong:
            return theme.colors.statusDanger
        case .disabled:
            return theme.colors.textMuted
        }
    }

    private var prefixForegroundColor: Color {
        switch state {
        case .idle:
            return theme.colors.textPrimary
        case .selected, .correct, .wrong:
            return theme.colors.textInverse
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

    private var prefixStrokeColor: Color {
        if style == .flat && state == .idle {
            return .clear
        }
        switch state {
        case .idle:
            return theme.colors.borderDefault
        case .selected, .correct, .wrong:
            return theme.colors.textInverse.opacity(0.35)
        case .disabled:
            return theme.colors.borderDefault.opacity(0.4)
        }
    }

    // MARK: - Sub-Component: Trailing Indicator

    @ViewBuilder
    private var trailingIndicator: some View {
        if showsStatusIndicator {
            switch state {
            case .correct:
                CraftIcon(
                    correctIconName ?? CraftSymbol.checkmarkCircle.rawValue,
                    size: .md,
                    color: theme.colors.statusSuccess,
                    renderingMode: .hierarchical
                )
                .symbolEffect(.bounce, value: state)
                .transition(.scale.combined(with: .opacity))
            case .wrong:
                CraftIcon(
                    wrongIconName ?? CraftSymbol.wrongCircle.rawValue,
                    size: .md,
                    color: theme.colors.statusDanger,
                    renderingMode: .hierarchical
                )
                .symbolEffect(.bounce, value: state)
                .transition(.scale.combined(with: .opacity))
            case .idle, .selected, .disabled:
                EmptyView()
            }
        }
    }

    // MARK: - Accessibility & Semantic Colors

    private var accessibilityValueDescription: String {
        switch state {
        case .idle:
            return ""
        case .selected:
            return CraftLocalized.string("craft.choice.selected_a11y")
        case .correct:
            return CraftLocalized.string("craft.choice.correct_a11y")
        case .wrong:
            return CraftLocalized.string("craft.choice.wrong_a11y")
        case .disabled:
            return CraftLocalized.string("craft.choice.disabled_a11y")
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

        configuration.label
            .offset(y: depressOffset)
            .background {
                if state != .disabled && isTactile {
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .fill(bottomLipColor)
                        .offset(y: depth)
                }
            }
            .padding(.bottom, (state == .disabled || !isTactile) ? 0 : effectiveDepth)
            .scaleEffect(isPressed && !reduceMotion ? (isTactile ? 0.99 : 0.98) : 1.0)
            .animation(theme.animations.springSnappy, value: isPressed)
            .contentShape(Rectangle())
            .sensoryFeedback(.impact(weight: .light), trigger: isPressed) { _, pressed in
                pressed
            }
    }

    private var bottomLipColor: Color {
        switch state {
        case .idle:
            return .craftDynamic(light: Color(hex: 0xD1D5DB), dark: Color(hex: 0x374151))
        case .selected:
            return theme.colors.brandSecondary
        case .correct:
            return .craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x047857))
        case .wrong:
            return .craftDynamic(light: Color(hex: 0xDC2626), dark: Color(hex: 0xB91C1C))
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

private struct CraftChoiceCardPreviewContainer: View {
    @State private var selectedStyle: CraftSurfaceStyle = .tactile3D
    @State private var selectedPrefixStyle: CraftChoicePrefixStyle = .circle
    @State private var selectedAlignment: TextAlignment = .leading
    @State private var interactiveSelection: String = "B"
    @State private var practiceSelection: String? = "It's a nice day."

    private let practiceOptions = [
        "It's a nice day.",
        "He was a nurse.",
        "It's a stressful job.",
        "It was a good job."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Style Switcher Segmented Control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(verbatim: "Surface Style")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                        Text(styleDescription(for: selectedStyle))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Picker(selection: $selectedStyle, label: Text(verbatim: "Surface Style")) {
                        ForEach(CraftSurfaceStyle.allCases, id: \.self) { style in
                            Text(verbatim: style.rawValue.capitalized).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Prefix Style Switcher Segmented Control
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Prefix Style")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Picker(selection: $selectedPrefixStyle, label: Text(verbatim: "Prefix Style")) {
                        ForEach(CraftChoicePrefixStyle.allCases, id: \.self) { style in
                            Text(verbatim: style.rawValue.capitalized).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Text Alignment Switcher Segmented Control
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: "Text Alignment")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Picker(selection: $selectedAlignment, label: Text(verbatim: "Text Alignment")) {
                        Text(verbatim: "Leading").tag(TextAlignment.leading)
                        Text(verbatim: "Center").tag(TextAlignment.center)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.bottom, 4)

                // 5 States Rendered Dynamically in the Selected Style
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: "Standard Multi-Choice States")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    CraftChoiceCard(
                        prefix: selectedAlignment == .center && selectedPrefixStyle == .none ? nil : "A",
                        prefixStyle: selectedAlignment == .center && selectedPrefixStyle == .none ? .none : selectedPrefixStyle,
                        title: "Idle State",
                        subtitle: "Default unselected option",
                        textAlignment: selectedAlignment,
                        state: interactiveSelection == "A" ? .selected : .idle,
                        style: selectedStyle,
                        showsStatusIndicator: !(selectedAlignment == .center && selectedPrefixStyle == .none)
                    ) {
                        interactiveSelection = "A"
                    }

                    CraftChoiceCard(
                        prefix: selectedAlignment == .center && selectedPrefixStyle == .none ? nil : "B",
                        prefixStyle: selectedAlignment == .center && selectedPrefixStyle == .none ? .none : selectedPrefixStyle,
                        title: "Selected State",
                        subtitle: "Currently selected option",
                        textAlignment: selectedAlignment,
                        state: interactiveSelection == "B" ? .selected : .idle,
                        style: selectedStyle,
                        showsStatusIndicator: !(selectedAlignment == .center && selectedPrefixStyle == .none)
                    ) {
                        interactiveSelection = "B"
                    }

                    CraftChoiceCard(
                        prefix: selectedAlignment == .center && selectedPrefixStyle == .none ? nil : "C",
                        prefixStyle: selectedAlignment == .center && selectedPrefixStyle == .none ? .none : selectedPrefixStyle,
                        title: "Correct Answer",
                        subtitle: "Validated with custom checkmark.seal.fill icon",
                        textAlignment: selectedAlignment,
                        state: .correct,
                        style: selectedStyle,
                        showsStatusIndicator: !(selectedAlignment == .center && selectedPrefixStyle == .none),
                        correctIconName: "checkmark.seal.fill"
                    ) {}

                    CraftChoiceCard(
                        prefix: selectedAlignment == .center && selectedPrefixStyle == .none ? nil : "D",
                        prefixStyle: selectedAlignment == .center && selectedPrefixStyle == .none ? .none : selectedPrefixStyle,
                        title: "Incorrect Answer",
                        textAlignment: selectedAlignment,
                        state: .wrong,
                        style: selectedStyle,
                        showsStatusIndicator: !(selectedAlignment == .center && selectedPrefixStyle == .none),
                        wrongIconName: "xmark.octagon.fill"
                    ) {}

                    CraftChoiceCard(
                        prefix: selectedAlignment == .center && selectedPrefixStyle == .none ? nil : "E",
                        prefixStyle: selectedAlignment == .center && selectedPrefixStyle == .none ? .none : selectedPrefixStyle,
                        title: "Disabled Option",
                        subtitle: "Non-interactive dimmed state",
                        textAlignment: selectedAlignment,
                        state: .disabled,
                        style: selectedStyle,
                        showsStatusIndicator: !(selectedAlignment == .center && selectedPrefixStyle == .none)
                    ) {}
                }

                Divider()
                    .padding(.vertical, 4)

                // Dedicated Practice / Video Quiz Demo (Matching Reference Screenshot)
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: "Practice / Video Quiz (Minimalist Centered)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(verbatim: "Select what you heard:")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }

                    VStack(spacing: 12) {
                        ForEach(practiceOptions, id: \.self) { option in
                            CraftChoiceCard(
                                prefix: nil,
                                prefixStyle: .none,
                                title: option,
                                textAlignment: .center,
                                state: practiceSelection == option ? .selected : .idle,
                                style: selectedStyle,
                                showsStatusIndicator: false
                            ) {
                                practiceSelection = option
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func styleDescription(for style: CraftSurfaceStyle) -> String {
        switch style {
        case .tactile3D: return "3D Extrusion Bevel & Mechanical Press"
        case .glass: return "Liquid Glass & Light Refraction"
        case .elevated: return "Layered Elevation & Ambient Shadow"
        case .outlined: return "Crisp Hairline Stroke"
        case .flat: return "Subtle Solid Minimal"
        }
    }
}

#Preview("CraftChoiceCard") {
    CraftChoiceCardPreviewContainer()
}
