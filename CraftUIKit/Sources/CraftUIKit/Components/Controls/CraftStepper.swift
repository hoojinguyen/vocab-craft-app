import SwiftUI

// MARK: - CraftStepper Component

/// A `[-] [Value + Unit] [+]` stepper control with custom increments, range bounding, and tactile feedback.
public struct CraftStepper: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.craftSurfaceStyle) private var envStyle

    public var value: Binding<Int>
    public var range: ClosedRange<Int>
    public var step: Int
    private let rawUnit: String?
    private let unitKey: LocalizedStringKey?
    private let rawLabel: String?
    private let labelKey: LocalizedStringKey?
    public let style: CraftSurfaceStyle?

    public var unit: String? { rawUnit }
    public var label: String? { rawLabel }

    public var resolvedStyle: CraftSurfaceStyle {
        style ?? envStyle
    }

    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        unit: String? = nil,
        label: String? = nil,
        style: CraftSurfaceStyle? = nil
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.rawUnit = unit
        self.unitKey = nil
        self.rawLabel = label
        self.labelKey = nil
        self.style = style
    }

    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        unit: LocalizedStringKey? = nil,
        label: LocalizedStringKey,
        style: CraftSurfaceStyle? = nil
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.rawUnit = nil
        self.unitKey = unit
        self.rawLabel = nil
        self.labelKey = label
        self.style = style
    }

    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        unit: LocalizedStringKey,
        style: CraftSurfaceStyle? = nil
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.rawUnit = nil
        self.unitKey = unit
        self.rawLabel = nil
        self.labelKey = nil
        self.style = style
    }

    /// Whether the value can be incremented further within range.
    public var canIncrement: Bool {
        value.wrappedValue < range.upperBound
    }

    /// Whether the value can be decremented further within range.
    public var canDecrement: Bool {
        value.wrappedValue > range.lowerBound
    }

    /// Increases the current value by the configured step increment, capped at the range upper bound.
    public func increment() {
        guard canIncrement else { return }
        let next = value.wrappedValue + step
        value.wrappedValue = min(next, range.upperBound)
    }

    /// Decreases the current value by the configured step decrement, floored at the range lower bound.
    public func decrement() {
        guard canDecrement else { return }
        let prev = value.wrappedValue - step
        value.wrappedValue = max(prev, range.lowerBound)
    }

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            if let labelKey {
                Text(labelKey)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(2)
                    .layoutPriority(0)

                Spacer(minLength: theme.spacing.xs)
            } else if let rawLabel, !rawLabel.isEmpty {
                Text(rawLabel)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(2)
                    .layoutPriority(0)

                Spacer(minLength: theme.spacing.xs)
            }

            // Stepper Control Group
            applyShadow(
                HStack(spacing: 0) {
                    // Decrement Button
                    Button(action: {
                        decrement()
                    }) {
                        CraftIcon(
                            .minus,
                            size: .sm,
                            color: canDecrement ? theme.colors.textPrimary : theme.colors.textMuted
                        )
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.craftPress(scale: 0.92))
                    .disabled(!canDecrement)
                    .accessibilityLabel(CraftLocalized.string("craft.stepper.decreaseA11y"))

                    // Divider
                    Rectangle()
                        .fill(theme.colors.borderDefault)
                        .frame(width: 1, height: 24)

                    // Value Display
                    HStack(spacing: 4) {
                        Text("\(value.wrappedValue)")
                            .font(theme.typography.headline)
                            .monospacedDigit()
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineLimit(1)

                        if let unitKey {
                            Text(unitKey)
                                .font(theme.typography.label)
                                .foregroundStyle(theme.colors.textSecondary)
                                .lineLimit(1)
                        } else if let rawUnit, !rawUnit.isEmpty {
                            Text(rawUnit)
                                .font(theme.typography.label)
                                .foregroundStyle(theme.colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, theme.spacing.sm)

                    // Divider
                    Rectangle()
                        .fill(theme.colors.borderDefault)
                        .frame(width: 1, height: 24)

                    // Increment Button
                    Button(action: {
                        increment()
                    }) {
                        CraftIcon(
                            .add,
                            size: .sm,
                            color: canIncrement ? theme.colors.textPrimary : theme.colors.textMuted
                        )
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.craftPress(scale: 0.92))
                    .disabled(!canIncrement)
                    .accessibilityLabel(CraftLocalized.string("craft.stepper.increaseA11y"))
                }
                .frame(height: 44)
                .background(stepperBackground)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
                .overlay(stepperBorder)
                .opacity(isEnabled ? 1.0 : 0.5)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabelContent)
            .accessibilityValue(accessibilityValueContent)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    increment()
                case .decrement:
                    decrement()
                @unknown default:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private var stepperBackground: some View {
        switch resolvedStyle {
        case .flat:
            theme.colors.surfaceSubtle
        case .elevated:
            theme.colors.surfaceElevated
        case .outlined, .tactile3D:
            theme.colors.surfaceCard
        case .glass:
            ZStack {
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .fill(theme.colors.surfaceCard.opacity(theme.glass.tintOpacity))
            }
        }
    }

    @ViewBuilder
    private var stepperBorder: some View {
        switch resolvedStyle {
        case .flat, .outlined:
            RoundedRectangle(cornerRadius: theme.radii.md)
                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
        case .elevated:
            RoundedRectangle(cornerRadius: theme.radii.md)
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
        case .tactile3D:
            ZStack {
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
            }
        case .glass:
            RoundedRectangle(cornerRadius: theme.radii.md)
                .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func applyShadow<V: View>(_ view: V) -> some View {
        switch resolvedStyle {
        case .elevated:
            view.craftShadow(theme.shadows.sm)
        case .glass:
            view.craftShadow(theme.shadows.sm)
        case .flat, .outlined, .tactile3D:
            view
        }
    }

    private var accessibilityLabelContent: Text {
        if let labelKey {
            return Text(labelKey)
        } else if let rawLabel, !rawLabel.isEmpty {
            return Text(rawLabel)
        }
        return Text("Stepper")
    }

    private var accessibilityValueContent: Text {
        if let unitKey {
            return Text("\(value.wrappedValue) ") + Text(unitKey)
        } else if let rawUnit, !rawUnit.isEmpty {
            return Text("\(value.wrappedValue) \(rawUnit)")
        }
        return Text("\(value.wrappedValue)")
    }
}

#Preview("CraftStepper") {
    @Previewable @State var value1 = 5
    @Previewable @State var value2 = 25
    @Previewable @State var value3 = 10
    
    return ScrollView {
        VStack(spacing: 32) {
            CraftStepper(
                value: $value1,
                range: 0...10
            )
            
            CraftStepper(
                value: $value2,
                range: 0...100,
                step: 5,
                label: "Daily Goal"
            )
            
            CraftStepper(
                value: $value3,
                range: 5...60,
                step: 5,
                unit: "mins",
                label: "Study Duration"
            )
        }
        .padding()
    }
}
