import SwiftUI

/// Step 3 of the Stage Learning Flow: Stage completion summary displaying XP earned, correct count, accuracy, weak words flagged for review, and unlock next stage CTA.
public struct StageSummarySheet: View {
    public let summary: StageCompletionSummary
    public let onFinish: () -> Void
    public let onRestart: () -> Void

    @State private var triggerHaptic: Bool = false

    public init(
        summary: StageCompletionSummary,
        onFinish: @escaping () -> Void,
        onRestart: @escaping () -> Void
    ) {
        self.summary = summary
        self.onFinish = onFinish
        self.onRestart = onRestart
    }

    private var accuracyPercentage: Int {
        guard summary.totalQuestions > 0 else { return 100 }
        return Int((Double(summary.correctCount) / Double(summary.totalQuestions)) * 100)
    }

    private var isPassed: Bool {
        accuracyPercentage >= 70
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas.ignoresSafeArea()

            #if canImport(UIKit)
            if isPassed {
                ConfettiParticleView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            #endif

            VStack(spacing: 24) {
                Spacer()

                // Celebration Icon
                celebrationBadge

                // Headline & Subtitle
                VStack(spacing: 6) {
                    Text(isPassed ? "Hoàn Thành Chặng!" : "Chưa Đạt Mục Tiêu")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.vocabInk)

                    Text(isPassed ? "Bạn đã nạp thành công các từ vựng vào kho kiến thức." : "Hãy ôn tập lại để củng cố các từ vựng này nhé.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Stats Dashboard Grid
                statsDashboardGrid
                    .padding(.horizontal, 20)

                // Weak Words Callout (if any)
                if !summary.weakWordIds.isEmpty {
                    weakWordsCallout
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Action Buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            triggerHaptic = true
        }
        .sensoryFeedback(isPassed ? .success : .warning, trigger: triggerHaptic)
    }

    // MARK: - Celebration Badge
    private var celebrationBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isPassed
                            ? [Color.vocabPeach.opacity(0.2), Color(hex: "FA9938").opacity(0.1)]
                            : [Color.vocabCoral.opacity(0.2), Color.vocabCoral.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)

            Image(systemName: isPassed ? "trophy.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(isPassed ? Color.vocabPeach : Color.vocabCoral)
                .symbolEffect(.bounce, value: triggerHaptic)
        }
    }

    // MARK: - Stats Dashboard Grid
    private var statsDashboardGrid: some View {
        HStack(spacing: 12) {
            statMetricCard(
                title: "+\(max(0, summary.xpEarned)) XP",
                label: "XP Đạt Được",
                color: Color.vocabMint
            )

            statMetricCard(
                title: "\(summary.correctCount)/\(summary.totalQuestions)",
                label: "Đúng",
                color: Color.vocabInk
            )

            statMetricCard(
                title: "\(accuracyPercentage)%",
                label: "Chính Xác",
                color: isPassed ? Color.vocabMint : Color.vocabCoral
            )
        }
    }

    private func statMetricCard(title: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.vocabMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
    }

    // MARK: - Weak Words Callout
    private var weakWordsCallout: some View {
        HStack(spacing: 10) {
            Image(systemName: "flag.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.vocabCoral)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(summary.weakWordIds.count) từ chưa chính xác")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.vocabInk)

                Text("Đã tự động thêm vào Kho cá nhân để bạn ôn tập lại.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.vocabCoral.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.vocabCoral.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary Finish / Next CTA
            Button(action: onFinish) {
                HStack(spacing: 8) {
                    Text(isPassed ? "Hoàn thành & Tiếp tục" : "Tiếp tục Lộ trình")
                        .font(.system(size: 15, weight: .bold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: isPassed
                            ? [Color.vocabMint, Color(hex: "34D399")]
                            : [Color.vocabPeach, Color(hex: "FA9938")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: (isPassed ? Color.vocabMint : Color.vocabPeach).opacity(0.35), radius: 8, x: 0, y: 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())

            // Secondary Restart CTA
            Button(action: onRestart) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Luyện tập lại Chặng này")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color.vocabMuted)
                .padding(.vertical, 8)
            }
        }
    }
}
