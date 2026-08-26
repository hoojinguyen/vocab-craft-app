import CraftUIKit
import SwiftUI

public struct ReflexBlitzHeaderView: View {
    public let currentIndex: Int
    public let totalCount: Int
    public let comboStreak: Int
    public let fractionRemaining: Double
    public let timerStage: ReflexBlitzTimerStage
    public let mode: ReflexBlitzMode
    public let attempts: [ReflexBlitzAttempt]
    public let wordStartTime: Date?
    public let timeLimitSeconds: Double
    public let isTimerActive: Bool
    public let onClose: () -> Void
    public let onSkip: () -> Void
    public var showSkipInHeader: Bool

    public var timerBarColor: Color {
        switch timerStage {
        case .steady:
            return .vocabHeroAccent
        case .warning:
            return .vocabPeach
        case .urgent:
            return .vocabCoral
        }
    }

    public init(
        currentIndex: Int,
        totalCount: Int,
        comboStreak: Int,
        fractionRemaining: Double = 1.0,
        timerStage: ReflexBlitzTimerStage = .steady,
        mode: ReflexBlitzMode = .speaking,
        attempts: [ReflexBlitzAttempt] = [],
        wordStartTime: Date? = nil,
        timeLimitSeconds: Double = 5.0,
        isTimerActive: Bool = false,
        onClose: @escaping () -> Void,
        onSkip: @escaping () -> Void = {},
        showSkipInHeader: Bool = false
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.comboStreak = comboStreak
        self.fractionRemaining = fractionRemaining
        self.timerStage = timerStage
        self.mode = mode
        self.attempts = attempts
        self.wordStartTime = wordStartTime
        self.timeLimitSeconds = timeLimitSeconds
        self.isTimerActive = isTimerActive
        self.onClose = onClose
        self.onSkip = onSkip
        self.showSkipInHeader = showSkipInHeader
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Top Action & Progress Bar Row (Perfect 3-Column Balance)
            HStack(alignment: .center) {
                // Leading: Close button (Apple Glass Button)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.vocabInk)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel(CraftLocalized.string("craft.common.action.close"))

                Spacer(minLength: 8)

                // Center: Apple Fitness+ Segmented Progress Bar & Step Counter
                CraftStepProgressIndicator(
                    steps: (0..<totalCount).map { index in
                        if index < attempts.count {
                            return .completed(isCorrect: attempts[index].isCorrect)
                        } else if index == currentIndex {
                            return .active
                        } else {
                            return .unreached
                        }
                    },
                    currentStep: currentIndex,
                    height: 4,
                    spacing: 4,
                    showCounter: true,
                    counterStyle: .ratio
                )
                .frame(maxWidth: 160)

                Spacer(minLength: 8)

                // Trailing: Combo Streak Badge or Balanced Placeholder
                if comboStreak >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .symbolRenderingMode(.multicolor)
                            .symbolEffect(.bounce, value: comboStreak)
                        Text("x\(comboStreak)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundColor(.vocabPeach)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vocabPeach.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.vocabPeach.opacity(0.3), lineWidth: 0.8)
                    )
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Chuỗi combo \(comboStreak)")
                } else if showSkipInHeader {
                    Button(action: onSkip) {
                        Text("Bỏ qua")
                            .font(.caption.bold())
                            .foregroundColor(.vocabMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(BentoCardButtonStyle())
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .accessibilityLabel("Bỏ qua từ hiện tại")
                } else {
                    // Invisible 44x44 placeholder to keep center segmented bar mathematically centered
                    Color.clear
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }

            // Smooth Linear Countdown Timer Bar Anchored Under Header
            if isTimerActive {
                CraftCountdownTimerBar(
                    startDate: wordStartTime ?? Date(),
                    timeLimit: timeLimitSeconds,
                    isActive: isTimerActive,
                    height: 4.5,
                    colorConfig: CraftCountdownColorConfig(
                        steady: .vocabHeroAccent,
                        warning: .vocabPeach,
                        urgent: .vocabCoral,
                        trackColor: Color.vocabHairline.opacity(0.3),
                        showGlow: true
                    )
                )
            } else {
                CraftCountdownTimerBar(
                    progress: fractionRemaining,
                    height: 4.5,
                    colorConfig: CraftCountdownColorConfig(
                        steady: .vocabHeroAccent,
                        warning: .vocabPeach,
                        urgent: .vocabCoral,
                        trackColor: Color.vocabHairline.opacity(0.3),
                        showGlow: true
                    )
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    public func segmentColor(for index: Int) -> Color {
        if index < attempts.count {
            return attempts[index].isCorrect ? Color.vocabMint : Color.vocabCoral
        } else if index == currentIndex {
            return Color.vocabHeroAccent
        } else {
            return Color.vocabHairline.opacity(0.4)
        }
    }
}
