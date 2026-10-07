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
        case .ended, .error:
            return .ended
        }
    }
}

/// Animated circular Voice Orb dynamically reflecting Speaking, Listening, and Thinking call states.
@MainActor
public struct CraftVoiceOrbView: View {
    public let state: VoiceCallState
    public let audioLevel: Float
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    public init(state: VoiceCallState, audioLevel: Float = 0.0) {
        self.state = state
        self.audioLevel = audioLevel
    }

    var visualState: OrbVisualState {
        state.visualState
    }

    public var body: some View {
        ZStack {
            // Background ambient outer glow
            Circle()
                .fill(orbColor.opacity(outerGlowOpacity))
                .frame(width: 220, height: 220)
                .scaleEffect(outerGlowScale(isExpanded: isBreathing, audioLevel: audioLevel))
                .blur(radius: outerGlowBlur)

            // Middle soundwave ring
            Circle()
                .stroke(orbColor.opacity(0.35), lineWidth: 2)
                .frame(width: 170, height: 170)
                .scaleEffect(soundwaveRingScale(isExpanded: isBreathing, audioLevel: audioLevel))

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
                .shadow(color: orbColor.opacity(coreShadowOpacity), radius: coreShadowRadius, x: 0, y: 0)
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
        .animation(.easeOut(duration: 0.1), value: audioLevel)
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

    var outerGlowOpacity: Double {
        visualState == .listening ? 0.18 + Double(audioLevel) * 0.12 : 0.18
    }

    var outerGlowBlur: CGFloat {
        visualState == .listening ? 20 + CGFloat(audioLevel) * 10 : 20
    }

    var coreShadowRadius: CGFloat {
        visualState == .listening ? 15 + CGFloat(audioLevel) * 15 : 15
    }

    var coreShadowOpacity: Double {
        visualState == .listening ? 0.4 + Double(audioLevel) * 0.3 : 0.4
    }

    func outerGlowScale(isExpanded: Bool, audioLevel: Float? = nil, reduceMotion: Bool? = nil) -> CGFloat {
        let isReduced = reduceMotion ?? self.reduceMotion
        if isReduced { return 1.0 }
        let level = audioLevel ?? self.audioLevel
        switch visualState {
        case .speaking:
            return isExpanded ? 1.15 : 0.98
        case .listening:
            return 1.0 + CGFloat(level) * 0.35
        case .thinking:
            return isExpanded ? 1.05 : 0.95
        case .idle, .ended:
            return 1.0
        }
    }

    func soundwaveRingScale(isExpanded: Bool, audioLevel: Float? = nil, reduceMotion: Bool? = nil) -> CGFloat {
        let isReduced = reduceMotion ?? self.reduceMotion
        if isReduced { return 1.0 }
        let level = audioLevel ?? self.audioLevel
        switch visualState {
        case .listening:
            return 1.0 + CGFloat(level) * 0.35
        default:
            return isExpanded ? 1.08 : 0.94
        }
    }

    var stateSymbol: CraftSymbol {
        switch visualState {
        case .idle:
            return .phone
        case .speaking:
            return .waveform
        case .listening:
            return audioLevel > 0.08 ? .waveform : .mic
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
