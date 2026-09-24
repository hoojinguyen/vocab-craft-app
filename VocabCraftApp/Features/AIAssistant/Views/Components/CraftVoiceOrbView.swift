import CraftUIKit
import SwiftUI

/// Animated circular Voice Orb dynamically reflecting Speaking, Listening, and Thinking call states.
@MainActor
public struct CraftVoiceOrbView: View {
    public let state: VoiceCallState
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    public init(state: VoiceCallState) {
        self.state = state
    }

    public var body: some View {
        ZStack {
            // Background ambient outer glow
            Circle()
                .fill(orbColor.opacity(0.18))
                .frame(width: 220, height: 220)
                .scaleEffect(scaleForState)
                .blur(radius: 20)

            // Middle soundwave ring
            Circle()
                .stroke(orbColor.opacity(0.35), lineWidth: 2)
                .frame(width: 170, height: 170)
                .scaleEffect(reduceMotion ? 1.0 : (isBreathing ? 1.08 : 0.94))

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
                    stateIcon
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(theme.colors.textInverse)
                }
        }
        .accessibilityHidden(true)
        .animation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true), value: isBreathing)
        .animation(.easeInOut(duration: 0.35), value: state)
        .onAppear {
            if !reduceMotion {
                isBreathing = true
            }
        }
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

    private var scaleForState: CGFloat {
        if reduceMotion { return 1.0 }
        switch state {
        case .speaking:
            return isBreathing ? 1.15 : 0.98
        case .listening:
            return isBreathing ? 1.25 : 1.02
        case .thinking:
            return isBreathing ? 1.05 : 0.95
        case .idle, .ended:
            return 1.0
        }
    }

    private var animationDuration: Double {
        switch state {
        case .speaking: return 0.7
        case .listening: return 0.5
        case .thinking: return 1.2
        case .idle, .ended: return 1.5
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .idle:
            Image(systemName: "phone.fill")
        case .speaking:
            Image(systemName: "waveform")
        case .listening:
            Image(systemName: "mic.fill")
        case .thinking:
            Image(systemName: "sparkles")
        case .ended:
            Image(systemName: "phone.down.fill")
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
