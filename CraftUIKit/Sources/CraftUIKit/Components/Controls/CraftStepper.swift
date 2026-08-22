import SwiftUI

// MARK: - CraftStepper Component

/// A `[-] [Value + Unit] [+]` stepper control with custom increments, range bounding, and tactile feedback.
public struct CraftStepper: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public var value: Binding<Int>
    public var range: ClosedRange<Int>
    public var step: Int
    private let rawUnit: String?
    private let unitKey: LocalizedStringKey?
    private let rawLabel: String?
    private let labelKey: LocalizedStringKey?

    public var unit: String? { rawUnit }
    public var label: String? { rawLabel }

    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        unit: String? = nil,
        label: String? = nil
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.rawUnit = unit
        self.unitKey = nil
        self.rawLabel = label
        self.labelKey = nil
    }

    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        unit: LocalizedStringKey? = nil,
        label: LocalizedStringKey
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.rawUnit = nil
        self.unitKey = unit
        self.rawLabel = nil
        self.labelKey = label
    }

    public init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...100,
        step: Int = 1,
        unit: LocalizedStringKey
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.rawUnit = nil
        self.unitKey = unit
        self.rawLabel = nil
        self.labelKey = nil
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
        HStack {
            if let labelKey {
                Text(labelKey)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()
            } else if let rawLabel, !rawLabel.isEmpty {
                Text(rawLabel)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Spacer()
            }

            // Stepper Control Group
            HStack(spacing: 0) {
                // Decrement Button
                Button(action: {
                    decrement()
                }) {
                    CraftIcon(
                        "minus",
                        size: .sm,
                        color: canDecrement ? theme.colors.textPrimary : theme.colors.textMuted
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.craftPress(scale: 0.92))
                .disabled(!canDecrement)
                .accessibilityLabel("Decrease")

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

                    if let unitKey {
                        Text(unitKey)
                            .font(theme.typography.label)
                            .foregroundStyle(theme.colors.textSecondary)
                    } else if let rawUnit, !rawUnit.isEmpty {
                        Text(rawUnit)
                            .font(theme.typography.label)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .frame(minWidth: 64)
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
                        "plus",
                        size: .sm,
                        color: canIncrement ? theme.colors.textPrimary : theme.colors.textMuted
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.craftPress(scale: 0.92))
                .disabled(!canIncrement)
                .accessibilityLabel("Increase")
            }
            .frame(height: 44)
            .background(theme.colors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
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
