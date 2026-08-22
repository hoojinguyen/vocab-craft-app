import SwiftUI

// MARK: - CraftProgressBar Component

/// A customizable linear progress bar supporting continuous or stepped progress states,
/// automatic value clamping between 0.0 and 1.0, and theme-driven styling.
public struct CraftProgressBar: View {
    @Environment(\.craftTheme) private var theme

    public let progress: Double
    public let currentStep: Int?
    public let totalSteps: Int?
    public let height: CGFloat
    public let tintColor: Color?
    public let trackColor: Color?
    public let cornerRadius: CGFloat?
    public let animated: Bool

    /// Clamped progress value guaranteed to be in the [0.0, 1.0] range.
    public var clampedProgress: Double {
        min(max(progress, 0.0), 1.0)
    }

    /// Initializes a continuous progress bar with a floating-point progress value.
    public init(
        progress: Double,
        height: CGFloat = 8,
        tintColor: Color? = nil,
        trackColor: Color? = nil,
        cornerRadius: CGFloat? = nil,
        animated: Bool = true
    ) {
        self.progress = progress
        self.currentStep = nil
        self.totalSteps = nil
        self.height = height
        self.tintColor = tintColor
        self.trackColor = trackColor
        self.cornerRadius = cornerRadius
        self.animated = animated
    }

    /// Initializes a stepped progress bar based on discrete step counts.
    public init(
        currentStep: Int,
        totalSteps: Int,
        height: CGFloat = 8,
        tintColor: Color? = nil,
        trackColor: Color? = nil,
        cornerRadius: CGFloat? = nil,
        animated: Bool = true
    ) {
        let validTotal = max(totalSteps, 1)
        self.progress = Double(currentStep) / Double(validTotal)
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.height = height
        self.tintColor = tintColor
        self.trackColor = trackColor
        self.cornerRadius = cornerRadius
        self.animated = animated
    }

    public var body: some View {
        let radius = cornerRadius ?? (height / 2)
        let fill = tintColor ?? theme.colors.brandPrimary
        let track = trackColor ?? theme.colors.surfaceSubtle

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: radius)
                    .fill(track)
                    .frame(height: height)

                // Filled Progress
                RoundedRectangle(cornerRadius: radius)
                    .fill(fill)
                    .frame(width: geometry.size.width * CGFloat(clampedProgress), height: height)
                    .animation(animated ? theme.animations.springSmooth : nil, value: clampedProgress)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }
}

#Preview("CraftProgressBar") {
    VStack(spacing: 24) {
        CraftProgressBar(progress: 0.0)
        CraftProgressBar(progress: 0.5)
        CraftProgressBar(progress: 1.0)
    }
    .padding()
}


