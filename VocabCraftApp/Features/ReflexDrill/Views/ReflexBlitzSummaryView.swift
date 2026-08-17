import SwiftUI

public struct ReflexBlitzSummaryView: View {
    public let summary: ReflexBlitzSessionSummary
    public let onReDrillWeak: () -> Void
    public let onFinish: () -> Void

    public init(
        summary: ReflexBlitzSessionSummary,
        onReDrillWeak: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.summary = summary
        self.onReDrillWeak = onReDrillWeak
        self.onFinish = onFinish
    }

    private var formattedAvgTime: String {
        String(format: "%.1fs", Double(summary.averageResponseTimeMs) / 1000.0)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Title Badge
                VStack(spacing: 8) {
                    Text(summary.speedRating)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.vocabInk)
                        .accessibilityAddTraits(.isHeader)

                    Text("Hoàn thành phiên phản xạ Blitz")
                        .font(.subheadline)
                        .foregroundColor(.vocabMuted)
                }
                .padding(.top, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(summary.speedRating). Hoàn thành phiên phản xạ Blitz.")

                // Bento Metrics Grid
                HStack(spacing: 12) {
                    // Avg Speed Card
                    VStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.title3)
                            .foregroundColor(.vocabPeach)
                            .accessibilityHidden(true)
                        Text(formattedAvgTime)
                            .font(.title2.bold())
                            .foregroundColor(.vocabInk)
                        Text("Tốc độ TB")
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Tốc độ trung bình: \(formattedAvgTime)")

                    // Accuracy Card
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.vocabMint)
                            .accessibilityHidden(true)
                        Text("\(summary.correctWords)/\(summary.totalWords)")
                            .font(.title2.bold())
                            .foregroundColor(.vocabInk)
                        Text("Độ chính xác")
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Độ chính xác: \(summary.correctWords) trên \(summary.totalWords) từ")

                    // Max Combo Card
                    VStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .foregroundColor(.vocabLavender)
                            .accessibilityHidden(true)
                        Text("x\(summary.maxComboStreak)")
                            .font(.title2.bold())
                            .foregroundColor(.vocabInk)
                        Text("Max Combo")
                            .font(.caption)
                            .foregroundColor(.vocabMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Chuỗi combo tối đa: \(summary.maxComboStreak)")
                }
                .padding(.horizontal)

                // Weak Words Section
                if !summary.weakWordAttempts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Từ cần củng cố (\(summary.weakWordAttempts.count))")
                            .font(.headline)
                            .foregroundColor(.vocabInk)
                            .padding(.horizontal)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(summary.weakWordAttempts) { weak in
                            HStack {
                                Text(weak.lemma)
                                    .font(.body.bold())
                                    .foregroundColor(.vocabInk)

                                Spacer()

                                Text(weak.responseTimeMs >= 6000 ? "Hết giờ" : "\(String(format: "%.1fs", Double(weak.responseTimeMs) / 1000.0))")
                                    .font(.caption.bold())
                                    .foregroundColor(.vocabCoral)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.vocabCoral.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .padding()
                            .background(Color.vocabSurfaceCard)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Từ cần ôn: \(weak.lemma), thời gian phản hồi: \(weak.responseTimeMs >= 6000 ? "Hết giờ" : "\(String(format: "%.1fs", Double(weak.responseTimeMs) / 1000.0))")")
                        }

                        // Re-drill Button
                        Button(action: onReDrillWeak) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .accessibilityHidden(true)
                                Text("Củng cố ngay \(summary.weakWordAttempts.count) từ yếu")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 50)
                            .background(Color.vocabCoral)
                            .cornerRadius(16)
                            .shadow(color: Color.vocabCoral.opacity(0.3), radius: 8, y: 4)
                        }
                        .buttonStyle(BentoCardButtonStyle())
                        .padding(.horizontal)
                        .accessibilityLabel("Củng cố ngay \(summary.weakWordAttempts.count) từ yếu")
                    }
                }

                // Finish Button
                Button(action: onFinish) {
                    Text("Hoàn thành & Lưu tiến độ")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(Color.vocabHeroAccent)
                        .cornerRadius(16)
                        .shadow(color: Color.vocabHeroAccent.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(BentoCardButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 20)
                .accessibilityLabel("Hoàn thành và lưu tiến độ")
            }
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
    }
}
