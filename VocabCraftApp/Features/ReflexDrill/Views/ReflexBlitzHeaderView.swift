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

    private func dynamicTimerBarColor(for fraction: Double) -> Color {
        if isTimerActive {
            if fraction > (2.5 / 6.0) {
                return .vocabHeroAccent
            } else if fraction > (1.0 / 6.0) {
                return .vocabPeach
            } else {
                return .vocabCoral
            }
        } else {
            return timerBarColor
        }
    }

    private var modeIconName: String {
        switch mode {
        case .speaking:
            return "waveform.and.mic"
        case .typing:
            return "keyboard"
        case .multipleChoice:
            return "square.grid.2x2.fill"
        case .listening:
            return "headphones"
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
                .accessibilityLabel("Đóng luyện tập")

                Spacer(minLength: 8)

                // Center: Apple Fitness+ Segmented Progress Bar & Step Counter
                VStack(spacing: 5) {
                    // Segmented Interval Progress Bars
                    HStack(spacing: 4) {
                        ForEach(0..<max(1, totalCount), id: \.self) { index in
                            Capsule()
                                .fill(segmentColor(for: index))
                                .frame(height: 4)
                                .frame(maxWidth: .infinity)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                    }
                    .frame(maxWidth: 160)

                    // Step counter
                    Text("\(currentIndex + 1) / \(totalCount)")
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundColor(.vocabMuted)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Tiến độ: từ \(currentIndex + 1) trên \(totalCount)")

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
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.vocabHairline.opacity(0.3))
                        .frame(height: 4.5)

                    TimelineView(.animation(paused: !isTimerActive)) { timeline in
                        let elapsed = isTimerActive && wordStartTime != nil
                            ? timeline.date.timeIntervalSince(wordStartTime!)
                            : (fractionRemaining > 0 ? (1.0 - fractionRemaining) * timeLimitSeconds : timeLimitSeconds)
                        let currentFraction = isTimerActive
                            ? max(0.0, min(1.0, 1.0 - elapsed / max(1.0, timeLimitSeconds)))
                            : fractionRemaining
                        let barColor = dynamicTimerBarColor(for: currentFraction)

                        Capsule()
                            .fill(barColor)
                            .frame(
                                width: max(0, min(geo.size.width, geo.size.width * CGFloat(currentFraction))),
                                height: 4.5
                            )
                            .shadow(color: barColor.opacity(barColor == .vocabCoral ? 0.6 : 0.25), radius: 5, x: 0, y: 0)
                            .animation(.easeInOut(duration: 0.25), value: barColor)
                    }
                }
            }
            .frame(height: 4.5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Thời gian còn lại")
            .accessibilityValue("\(Int(fractionRemaining * 100))%")
        }
        .padding(.horizontal)
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

