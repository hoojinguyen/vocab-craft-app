import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - CraftStepper Component

/// A `[-] [Value + Unit] [+]` stepper control with custom increments, range bounding, and tactile feedback.
public struct CraftStepper: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public var value: Binding<Int>
    public var range: ClosedRange<Int>
    public var step: Int
    public var unit: String?
    public var label: String?

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
        self.unit = unit
        self.label = label
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
            if let label, !label.isEmpty {
                Text(label)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()
            }

            // Stepper Control Group
            HStack(spacing: 0) {
                // Decrement Button
                Button(action: {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    #endif
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
                .buttonStyle(.plain)
                .disabled(!canDecrement)
                .craftPressEffect(scale: 0.92)

                // Divider
                Rectangle()
                    .fill(theme.colors.borderDefault)
                    .frame(width: 1, height: 24)

                // Value Display
                HStack(spacing: 4) {
                    Text("\(value.wrappedValue)")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)

                    if let unit, !unit.isEmpty {
                        Text(unit)
                            .font(theme.typography.label)
                            .foregroundColor(theme.colors.textSecondary)
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
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    #endif
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
                .buttonStyle(.plain)
                .disabled(!canIncrement)
                .craftPressEffect(scale: 0.92)
            }
            .frame(height: 44)
            .background(theme.colors.surfaceSubtle)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
    }
}
