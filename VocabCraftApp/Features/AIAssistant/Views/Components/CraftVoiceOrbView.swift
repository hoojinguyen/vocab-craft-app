import CraftUIKit
import SwiftUI

/// Animated circular Voice Orb dynamically reflecting Speaking, Listening, and Thinking call states.
@MainActor
public struct CraftVoiceOrbView: View {
    public let state: VoiceCallState
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(state: VoiceCallState) {
        self.state = state
    }

    public var body: some View {
        PhaseAnimator([false, true], trigger: state) { isExpanded in
            ZStack {
                // Background ambient outer glow
                Circle()
                    .fill(orbColor.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .scaleEffect(outerGlowScale(isExpanded: isExpanded))
                    .blur(radius: 20)

                // Middle soundwave ring
                Circle()
                    .stroke(orbColor.opacity(0.35), lineWidth: 2)
                    .frame(width: 170, height: 170)
                    .scaleEffect(reduceMotion ? 1.0 : (isExpanded ? 1.08 : 0.94))

                // Inner core liquid glass orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [orbColor, orbColor.opacity(0.65), theme.colors.surfaceCard],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 130, height: 130)
                    .shadow(color: orbColor.opacity(0.4), radius: 15, x: 0, y: 0)
                    .overlay {
                        CraftIcon(
                            stateSymbol,
                            size: .lg,
                            color: theme.colors.textInverse
                        )
                    }
            }
        } animation: { _ in
            animationForState
        }
        .accessibilityHidden(true)
        .animation(.easeInOut(duration: 0.35), value: state)
    }

    private var orbColor: Color {
        switch state {
        case .idle:
            return theme.colors.textSecondary
        case .speaking:
            return theme.colors.brandPrimary
        case .listening:
            return theme.colors.accent
        case .thinking:
            return theme.colors.statusWarning
        case .ended:
            return theme.colors.statusDanger
        }
    }

    private func outerGlowScale(isExpanded: Bool) -> CGFloat {
        if reduceMotion { return 1.0 }
        switch state {
        case .speaking:
            return isExpanded ? 1.15 : 0.98
        case .listening:
            return isExpanded ? 1.25 : 1.02
        case .thinking:
            return isExpanded ? 1.05 : 0.95
        case .idle, .ended:
            return 1.0
        }
    }

    private var animationForState: Animation {
        switch state {
        case .speaking:
            return .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
        case .listening:
            return .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
        case .thinking:
            return .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
        case .idle, .ended:
            return .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        }
    }

    private var stateSymbol: CraftSymbol {
        switch state {
        case .idle:
            return .phone
        case .speaking:
            return .waveform
        case .listening:
            return .mic
        case .thinking:
            return .sparkles
        case .ended:
            return .phoneDown
        }
    }
}

#if DEBUG
#Preview("CraftVoiceOrbView - All States") {
    VStack(spacing: 32) {
        CraftVoiceOrbView(state: .idle)
        CraftVoiceOrbView(state: .speaking(characterText: "Hello there!"))
        CraftVoiceOrbView(state: .listening(liveTranscript: "I want coffee"))
        CraftVoiceOrbView(state: .thinking)
        CraftVoiceOrbView(state: .ended)
    }
    .padding()
}
#endif
