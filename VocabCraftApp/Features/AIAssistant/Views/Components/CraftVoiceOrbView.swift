import CraftUIKit
import SwiftUI

/// Discrete visual presentation states for the voice orb animation, decoupled from transcript text.
public enum OrbVisualState: Equatable, Sendable {
    case idle
    case speaking
    case listening
    case thinking
    case ended
}

extension VoiceCallState {
    /// Maps the domain voice call state to a discrete visual state, ignoring volatile text payloads.
    public var visualState: OrbVisualState {
        switch self {
        case .idle:
            return .idle
        case .speaking:
            return .speaking
        case .listening:
            return .listening
        case .thinking:
            return .thinking
        case .ended:
            return .ended
        }
    }
}

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

    private var visualState: OrbVisualState {
        state.visualState
    }

    public var body: some View {
        ZStack {
            // Background ambient outer glow
            Circle()
                .fill(orbColor.opacity(0.18))
                .frame(width: 220, height: 220)
                .scaleEffect(outerGlowScale(isExpanded: isBreathing))
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
                    CraftIcon(
                        stateSymbol,
                        size: .lg,
                        color: theme.colors.textInverse
                    )
                }
        }
        .accessibilityHidden(true)
        .onAppear {
            startBreathingIfNeeded()
        }
        .onChange(of: reduceMotion) { _, newValue in
            if newValue {
                isBreathing = false
            } else {
                startBreathingIfNeeded()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: visualState)
    }

    private func startBreathingIfNeeded() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }

    private var orbColor: Color {
        switch visualState {
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
        switch visualState {
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

    private var stateSymbol: CraftSymbol {
        switch visualState {
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
