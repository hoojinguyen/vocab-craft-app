import CraftUIKit
import SwiftUI

/// Dynamic countdown pulse timer bar with 3-tier color shifting and urgency breathing pulse effect.
/// Shifts from Vibrant Emerald (`brandPrimary`) -> Warm Amber (`statusWarning`) -> Crimson Coral (`statusDanger`)
/// as remaining time elapses.
public struct DynamicPulseTimerBar: View {
    @Environment(\.craftTheme) private var theme

    public let fractionRemaining: Double
    public let totalDurationSeconds: Double
    public let isActive: Bool
    public var height: CGFloat

    @State private var isPulsing: Bool = false

    public init(
        fractionRemaining: Double,
        totalDurationSeconds: Double = 5.0,
        isActive: Bool = true,
        height: CGFloat = 6.0
    ) {
        self.fractionRemaining = max(0.0, min(1.0, fractionRemaining))
        self.totalDurationSeconds = totalDurationSeconds
        self.isActive = isActive
        self.height = height
    }

    public var isUrgent: Bool {
        fractionRemaining <= 0.18
    }

    public var isWarning: Bool {
        fractionRemaining > 0.18 && fractionRemaining <= 0.45
    }

    public var barColor: Color {
        if isUrgent {
            return theme.colors.statusDanger
        } else if isWarning {
            return theme.colors.statusWarning
        } else {
            return theme.colors.brandPrimary
        }
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(theme.colors.hairline.opacity(0.35))
                    .frame(height: height)

                // Filling Progress Bar
                Capsule()
                    .fill(barColor)
                    .frame(
                        width: max(0, min(geo.size.width, geo.size.width * CGFloat(fractionRemaining))),
                        height: height
                    )
                    .shadow(
                        color: barColor.opacity(isUrgent ? (isPulsing ? 0.8 : 0.4) : 0.2),
                        radius: isUrgent ? 8 : 4,
                        x: 0,
                        y: 0
                    )
                    .scaleEffect(isUrgent && isActive && isPulsing ? 1.01 : 1.0, anchor: .leading)
                    .animation(.easeInOut(duration: 0.25), value: barColor)
            }
        }
        .frame(height: height)
        .onAppear {
            if isUrgent && isActive {
                startPulsing()
            }
        }
        .onChange(of: isUrgent) { _, urgent in
            if urgent && isActive {
                startPulsing()
            } else {
                isPulsing = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CraftLocalized.string("craft.countdown.time_remaining_a11y"))
        .accessibilityValue("\(Int(fractionRemaining * 100))%")
    }

    private func startPulsing() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}
