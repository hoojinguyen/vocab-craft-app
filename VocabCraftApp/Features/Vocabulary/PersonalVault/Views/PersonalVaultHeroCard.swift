import SwiftUI

/// Smart Action Hero Card for the Personal Vault.
/// Displays a 1-click CTA button to review weak words if any exist, or a health summary of SRS retention.
public struct PersonalVaultHeroCard: View {
    public let metrics: PersonalVaultMetrics
    public let onStartSmartReview: () -> Void

    public init(
        metrics: PersonalVaultMetrics,
        onStartSmartReview: @escaping () -> Void
    ) {
        self.metrics = metrics
        self.onStartSmartReview = onStartSmartReview
    }

    private var hasWeakWords: Bool {
        metrics.needsReviewCount > 0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if hasWeakWords {
                weakWordsContent
            } else {
                healthySRSContent
            }
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    hasWeakWords ? Color.vocabPeach.opacity(0.3) : Color.vocabHairline,
                    lineWidth: hasWeakWords ? 1.5 : 1
                )
        )
        .shadow(
            color: hasWeakWords ? Color.vocabPeach.opacity(0.08) : Color.black.opacity(0.02),
            radius: 8,
            x: 0,
            y: 4
        )
        .padding(.horizontal)
    }

    // MARK: - Weak Words Active Card
    private var weakWordsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.vocabPeach.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.vocabPeach)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cần Củng Cố Kiến Thức")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.vocabInk)

                    Text("Bạn có \(metrics.needsReviewCount) từ vựng cần ôn tập lại.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                }

                Spacer()
            }

            Button(action: onStartSmartReview) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))

                    Text("Ôn tập từ yếu ngay (\(metrics.needsReviewCount) từ)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [Color.vocabPeach, Color(hex: "FA9938")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.vocabPeach.opacity(0.35), radius: 6, x: 0, y: 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())
            .sensoryFeedback(.impact(weight: .medium), trigger: metrics.needsReviewCount)
        }
    }

    // MARK: - Healthy SRS Retention Summary Card
    private var healthySRSContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.vocabMint.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.vocabMint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trí Nhớ SRS Ổn Định")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.vocabInk)

                    Text("Toàn bộ từ vựng đều trong trạng thái ghi nhớ tốt.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                metricPill(
                    title: "Tổng từ",
                    value: "\(metrics.totalWords)",
                    icon: "book.closed.fill",
                    color: Color.vocabInk
                )

                metricPill(
                    title: "Đã thuộc",
                    value: "\(metrics.masteredCount)",
                    icon: "star.fill",
                    color: Color.vocabMint
                )

                metricPill(
                    title: "Đã ghim",
                    value: "\(metrics.bookmarkedCount)",
                    icon: "bookmark.fill",
                    color: Color.vocabPeach
                )
            }
        }
    }

    private func metricPill(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.vocabInk)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.vocabMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.vocabSurfaceSoft)
        .cornerRadius(10)
    }
}
