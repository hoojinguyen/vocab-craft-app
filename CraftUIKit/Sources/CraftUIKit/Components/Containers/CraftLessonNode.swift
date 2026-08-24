import SwiftUI

// MARK: - Accessibility Traits Extension

extension AccessibilityTraits {
    /// Inactive element representation with no interactive button traits.
    static let notEnabled: AccessibilityTraits = []
}

// MARK: - CaretDownShape

/// Downward-pointing triangle shape for speech bubble carets.
public struct CaretDownShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - HexagonShape

/// Hexagonal polygon shape for checkpoint nodes.
public struct HexagonShape: Shape, InsettableShape {
    private let insetAmount: CGFloat

    public init(insetAmount: CGFloat = 0) {
        self.insetAmount = insetAmount
    }

    public func inset(by amount: CGFloat) -> HexagonShape {
        HexagonShape(insetAmount: self.insetAmount + amount)
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        let width = insetRect.width
        let height = insetRect.height
        let x = insetRect.minX
        let y = insetRect.minY

        path.move(to: CGPoint(x: x + width * 0.5, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.25))
        path.addLine(to: CGPoint(x: x + width, y: y + height * 0.75))
        path.addLine(to: CGPoint(x: x + width * 0.5, y: y + height))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.75))
        path.addLine(to: CGPoint(x: x, y: y + height * 0.25))
        path.closeSubpath()
        return path
    }
}

// MARK: - DiamondShape

/// Diamond polygon shape for checkpoint or milestone nodes.
public struct DiamondShape: Shape, InsettableShape {
    private let insetAmount: CGFloat

    public init(insetAmount: CGFloat = 0) {
        self.insetAmount = insetAmount
    }

    public func inset(by amount: CGFloat) -> DiamondShape {
        DiamondShape(insetAmount: self.insetAmount + amount)
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        path.move(to: CGPoint(x: insetRect.midX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.midY))
        path.addLine(to: CGPoint(x: insetRect.midX, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - TactileNodeButtonStyle

/// Button style simulating a 3D mechanical press by translating the top face downward on depress.
public struct TactileNodeButtonStyle: ButtonStyle {
    public let isLocked: Bool
    public let depth: CGFloat

    public init(isLocked: Bool, depth: CGFloat = 4) {
        self.isLocked = isLocked
        self.depth = depth
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: (!isLocked && configuration.isPressed) ? depth : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - ActiveCalloutBubble

/// Floating speech bubble positioned above active nodes with subtle bobbing oscillation.
public struct ActiveCalloutBubble: View {
    public let text: String

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(text: String = "TIẾP TỤC") {
        self.text = text
    }

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        content
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if reduceMotion {
            bubbleView
        } else {
            PhaseAnimator(BobbingPhase.allCases) { phase in
                bubbleView
                    .offset(y: phase == .high ? -2 : 2)
            } animation: { _ in
                .craftBobbing
            }
        }
    }

    private var bubbleView: some View {
        VStack(spacing: 0) {
            Text(text.uppercased())
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(theme.colors.textInverse)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.colors.brandPrimary,
                                    theme.colors.brandPrimary.opacity(0.92)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: theme.colors.brandPrimary.opacity(0.35), radius: 6, x: 0, y: 3)

            CaretDownShape()
                .fill(theme.colors.brandPrimary)
                .frame(width: 8, height: 4)
                .offset(y: -0.5)
        }
    }
}

// MARK: - CraftLessonNode Component

/// An atom view representing an individual 3D tactile lesson node within a learning journey path.
///
/// Supports 6 progression states (`completed`, `active`, `inProgress`, `upcoming`, `locked`, `bonus`),
/// 3 node kinds (`standard`, `checkpoint`, `treasureChest`), mechanical depress physics, visible typography
/// labels with XP/stars, and active callout speech bubbles.
public struct CraftLessonNode: View, Equatable {
    public let model: LessonNodeModel
    public let calloutText: String?
    public let onTap: (@Sendable () -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1.0

    @State private var tapTrigger: Bool = false
    @State private var completionTrigger: Bool = false
    @State private var lockedAttemptTrigger: Bool = false

    // MARK: - Initializer

    public init(
        model: LessonNodeModel,
        calloutText: String? = nil,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.model = model
        self.calloutText = calloutText
        self.onTap = onTap
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftLessonNode, rhs: CraftLessonNode) -> Bool {
        lhs.model == rhs.model && lhs.calloutText == rhs.calloutText
    }

    // MARK: - Computed Sizing

    public var nodeDiameter: CGFloat {
        let unscaled: CGFloat = switch model.state {
        case .completed: 52
        case .active: 64
        case .inProgress: 56
        case .upcoming, .locked: 48
        case .bonus: 56
        }
        return unscaled * baseScale
    }

    public var iconSize: CGFloat {
        let unscaled: CGFloat = switch model.state {
        case .active: 26
        case .inProgress, .bonus: 22
        case .completed: 20
        case .upcoming, .locked: 18
        }
        return unscaled * baseScale
    }

    // MARK: - Accessibility Helpers

    public var accessibilityLabelText: String {
        let base: String
        switch model.state {
        case .completed:
            base = "Lesson: \(model.title), Completed"
        case .active:
            if let progress = model.progress {
                let percent = Int((progress * 100).rounded())
                base = "Lesson: \(model.title), Current lesson. \(percent)% complete"
            } else {
                base = "Lesson: \(model.title), Current lesson"
            }
        case .inProgress:
            if let progress = model.progress {
                let percent = Int((progress * 100).rounded())
                base = "Lesson: \(model.title), In progress. \(percent)% complete"
            } else {
                base = "Lesson: \(model.title), In progress"
            }
        case .upcoming:
            base = "Lesson: \(model.title), Upcoming lesson"
        case .locked:
            base = "Lesson: \(model.title), Locked"
        case .bonus:
            base = "Bonus Lesson: \(model.title)"
        }

        if let xp = model.xpReward {
            return "\(base). Reward: \(xp) XP"
        }
        return base
    }

    public var accessibilityHintText: String {
        switch model.state {
        case .completed:
            return "Double tap to review"
        case .active, .inProgress:
            return "Double tap to continue"
        case .upcoming, .bonus:
            return "Double tap to start"
        case .locked:
            return "Complete previous lessons to unlock"
        }
    }

    public var accessibilityTraits: AccessibilityTraits {
        model.state == .locked ? .notEnabled : .isButton
    }

    // MARK: - Subtitle / Metadata Formatting

    public var metadataText: String? {
        if let subtitle = model.subtitle, !subtitle.isEmpty {
            return subtitle
        } else if let xp = model.xpReward {
            return "+\(xp) XP"
        }
        return nil
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            if model.state == .active {
                ActiveCalloutBubble(text: calloutText ?? "TIẾP TỤC")
                    .padding(.bottom, 6)
            }

            tactileNodeAtom
                .anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center) { anchor in
                    [model.id: anchor]
                }

            nodeLabels
                .padding(.top, 6)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: tapTrigger)
        .sensoryFeedback(.success, trigger: completionTrigger)
        .sensoryFeedback(.error, trigger: lockedAttemptTrigger)
        .sensoryFeedback(.selection, trigger: model.badgeCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Tactile Node Atom

    private var tactileNodeAtom: some View {
        ZStack {
            // Active outer glow ring
            if model.state == .active {
                activeGlowRing
            }

            // 3D tactile button stack
            ZStack {
                // Bottom Rim (Extrusion shadow/bevel)
                bottomRimView
                    .offset(y: model.state == .locked ? 0 : theme.depths.depthMd)

                // Top Face Button
                Button {
                    handleTap()
                    onTap?()
                } label: {
                    topFaceView
                }
                .buttonStyle(TactileNodeButtonStyle(isLocked: model.state == .locked, depth: theme.depths.depthMd))
            }
            .frame(width: nodeDiameter, height: nodeDiameter + (model.state == .locked ? 0 : theme.depths.depthMd))
        }
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: - Top Face View

    private var topFaceView: some View {
        ZStack {
            // Face Background & Shape
            faceShapeBackground

            // Highlight overlay along top rim
            highlightOverlay

            // Progress overlay for in-progress nodes
            if model.state == .inProgress {
                progressArc
            }

            // Icon content
            nodeIcon
        }
        .frame(width: nodeDiameter, height: nodeDiameter)
        .opacity(model.state == .locked ? 0.6 : 1.0)
        .overlay(alignment: .topTrailing) {
            badgeOverlay
        }
    }

    // MARK: - Bottom Rim View

    @ViewBuilder
    private var bottomRimView: some View {
        switch model.kind {
        case .checkpoint:
            HexagonShape()
                .fill(rimColor)
                .frame(width: nodeDiameter, height: nodeDiameter)
        case .standard, .treasureChest:
            Circle()
                .fill(rimColor)
                .frame(width: nodeDiameter, height: nodeDiameter)
        }
    }

    // MARK: - Face Shape Background

    @ViewBuilder
    private var faceShapeBackground: some View {
        switch model.kind {
        case .checkpoint:
            ZStack {
                switch model.state {
                case .completed:
                    HexagonShape().fill(theme.colors.statusSuccess)
                case .active:
                    HexagonShape().fill(theme.gradients.brandHero)
                case .inProgress:
                    HexagonShape().fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    HexagonShape().fill(theme.colors.surfaceSubtle)
                case .bonus:
                    HexagonShape().fill(theme.gradients.accentShine)
                        .craftShimmer(isActive: !reduceMotion)
                }

                if model.state == .upcoming || model.state == .locked {
                    HexagonShape()
                        .stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .standard:
            ZStack {
                switch model.state {
                case .completed:
                    Circle().fill(theme.colors.statusSuccess)
                case .active:
                    Circle().fill(theme.gradients.brandHero)
                case .inProgress:
                    Circle().fill(theme.colors.surfaceElevated)
                case .upcoming, .locked:
                    Circle().fill(theme.colors.surfaceSubtle)
                case .bonus:
                    Circle().fill(theme.gradients.accentShine)
                        .craftShimmer(isActive: !reduceMotion)
                }

                if model.state == .upcoming || model.state == .locked {
                    Circle()
                        .stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        case .treasureChest:
            Circle()
                .fill(theme.gradients.accentShine)
                .craftShimmer(isActive: !reduceMotion)
        }
    }

    // MARK: - Highlight Overlay

    @ViewBuilder
    private var highlightOverlay: some View {
        switch model.kind {
        case .checkpoint:
            HexagonShape()
                .stroke(
                    theme.depths.topHighlight,
                    lineWidth: 1.5
                )
        case .standard, .treasureChest:
            Circle()
                .stroke(
                    theme.depths.topHighlight,
                    lineWidth: 1.5
                )
        }
    }

    // MARK: - Rim Color

    private var rimColor: Color {
        switch model.kind {
        case .treasureChest:
            return theme.colors.accent.opacity(0.85)
        case .standard, .checkpoint:
            switch model.state {
            case .completed:
                return theme.colors.statusSuccess.opacity(0.85)
            case .active:
                return theme.colors.brandPrimary.opacity(0.85)
            case .inProgress, .upcoming:
                return theme.colors.borderDefault
            case .locked:
                return theme.colors.surfaceSubtle
            case .bonus:
                return theme.colors.accent.opacity(0.85)
            }
        }
    }

    // MARK: - Active Glow Ring

    @ViewBuilder
    private var activeGlowRing: some View {
        let isCheckpoint = model.kind == .checkpoint
        let haloSize = nodeDiameter + 24
        if reduceMotion {
            ZStack {
                if isCheckpoint {
                    HexagonShape()
                        .fill(theme.colors.pathHaloGlow)
                        .frame(width: haloSize, height: haloSize)
                    HexagonShape()
                        .stroke(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
                        .frame(width: haloSize, height: haloSize)
                } else {
                    Circle()
                        .fill(theme.colors.pathHaloGlow)
                        .frame(width: haloSize, height: haloSize)
                    Circle()
                        .stroke(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
                        .frame(width: haloSize, height: haloSize)
                }
            }
        } else {
            PhaseAnimator(GlowPhase.allCases) { phase in
                ZStack {
                    if isCheckpoint {
                        HexagonShape()
                            .fill(theme.colors.pathHaloGlow.opacity(phase == .glowing ? 1.0 : 0.75))
                            .frame(width: haloSize, height: haloSize)
                            .scaleEffect(phase == .glowing ? 1.04 : 0.98)

                        HexagonShape()
                            .stroke(
                                theme.colors.brandPrimary.opacity(phase == .glowing ? 0.35 : 0.18),
                                lineWidth: 1.5
                            )
                            .frame(width: haloSize, height: haloSize)
                            .scaleEffect(phase == .glowing ? 1.04 : 0.98)
                    } else {
                        Circle()
                            .fill(theme.colors.pathHaloGlow.opacity(phase == .glowing ? 1.0 : 0.75))
                            .frame(width: haloSize, height: haloSize)
                            .scaleEffect(phase == .glowing ? 1.04 : 0.98)

                        Circle()
                            .stroke(
                                theme.colors.brandPrimary.opacity(phase == .glowing ? 0.35 : 0.18),
                                lineWidth: 1.5
                            )
                            .frame(width: haloSize, height: haloSize)
                            .scaleEffect(phase == .glowing ? 1.04 : 0.98)
                    }
                }
            } animation: { _ in
                .craftGlow
            }
        }
    }

    // MARK: - Progress Arc

    @ViewBuilder
    private var progressArc: some View {
        let clampedProgress = min(max(model.progress ?? 0.0, 0.0), 1.0)
        if model.kind == .checkpoint {
            HexagonShape()
                .trim(from: 0.0, to: CGFloat(clampedProgress))
                .stroke(
                    theme.colors.brandPrimary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
        } else {
            ZStack {
                Circle()
                    .stroke(theme.colors.borderDefault, lineWidth: 3)

                Circle()
                    .trim(from: 0.0, to: CGFloat(clampedProgress))
                    .stroke(
                        theme.colors.brandPrimary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    // MARK: - Icon

    private var effectiveIconName: String {
        if model.kind == .treasureChest {
            return (model.iconName == "book.fill" || model.iconName.isEmpty) ? "gift.fill" : model.iconName
        }

        switch model.state {
        case .completed:
            return "checkmark"
        case .locked:
            return "lock.fill"
        case .bonus:
            return model.iconName.isEmpty ? "star.fill" : model.iconName
        case .active, .inProgress, .upcoming:
            if model.kind == .checkpoint && (model.iconName == "book.fill" || model.iconName.isEmpty) {
                return "crown.fill"
            }
            return model.iconName.isEmpty ? "book.fill" : model.iconName
        }
    }

    private var iconColor: Color {
        switch model.state {
        case .completed, .active, .bonus:
            return .white
        case .inProgress:
            return theme.colors.brandPrimary
        case .upcoming, .locked:
            return theme.colors.textMuted
        }
    }

    private var nodeIcon: some View {
        Image(systemName: effectiveIconName)
            .font(.system(size: iconSize, weight: .bold))
            .foregroundStyle(iconColor)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.pulse.byLayer, isActive: model.state == .active && !reduceMotion)
            .symbolEffect(.bounce, value: model.state == .completed)
            .symbolEffectsRemoved(reduceMotion)
    }

    // MARK: - Node Labels

    private var nodeLabels: some View {
        VStack(spacing: 2) {
            Text(model.title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(model.state == .locked ? theme.colors.textMuted : theme.colors.textPrimary)

            if let metadata = metadataText {
                Text(metadata)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            if model.state == .completed, let starCount = model.stars, starCount > 0 {
                starRatingView(count: starCount)
            }
        }
        .frame(maxWidth: 120)
    }

    // MARK: - 3D Star Rating

    private func starRatingView(count: Int) -> some View {
        let clampedStars = min(max(count, 0), 3)
        return HStack(spacing: 3) {
            ForEach(0..<clampedStars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.gradients.accentShine)
                    .shadow(color: theme.colors.accent.opacity(0.5), radius: 0, x: 0, y: 1.2)
                    .overlay {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.depths.topHighlight)
                    }
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Badge Overlay

    @ViewBuilder
    private var badgeOverlay: some View {
        if let count = model.badgeCount, count > 0 {
            badgeView(text: "\(count)", bounceValue: count)
                .offset(x: 4, y: -4)
        } else if let text = model.badgeText, !text.isEmpty {
            badgeView(text: text, bounceValue: nil)
                .offset(x: 4, y: -4)
        }
    }

    private func badgeView(text: String, bounceValue: Int?) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(theme.colors.textInverse)
            .padding(.horizontal, text.count > 1 ? 5 : 0)
            .frame(minWidth: 18, minHeight: 18)
            .background(
                Capsule()
                    .fill(theme.colors.statusDanger)
            )
            .overlay(
                Capsule()
                    .stroke(theme.colors.surfaceCard, lineWidth: 1.5)
            )
            .contentTransition(.numericText())
            .symbolEffect(.bounce, value: bounceValue ?? 0)
    }

    // MARK: - Tap Handling

    private func handleTap() {
        if model.state == .locked {
            lockedAttemptTrigger.toggle()
        } else if model.state == .completed {
            completionTrigger.toggle()
        } else {
            tapTrigger.toggle()
        }
    }
}
