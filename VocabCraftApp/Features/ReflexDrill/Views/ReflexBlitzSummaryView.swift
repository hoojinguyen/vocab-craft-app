import SwiftUI

public struct ReflexBlitzSummaryView: View {
    public let summary: ReflexBlitzSessionSummary
    public let onSpeakWord: ((String) -> Void)?
    public let onReDrillWeak: () -> Void
    public let onFinish: () -> Void

    public init(
        summary: ReflexBlitzSessionSummary,
        onSpeakWord: ((String) -> Void)? = nil,
        onReDrillWeak: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.summary = summary
        self.onSpeakWord = onSpeakWord
        self.onReDrillWeak = onReDrillWeak
        self.onFinish = onFinish
    }

    private var formattedAvgTime: String {
        String(format: "%.1fs", Double(summary.averageResponseTimeMs) / 1000.0)
    }

    private var cleanRatingTitle: String {
        summary.speedRating
            .replacingOccurrences(of: "⚡️ ", with: "")
            .replacingOccurrences(of: "🔥 ", with: "")
            .replacingOccurrences(of: "🌱 ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var headerIconName: String {
        if summary.speedRating.contains("Master") {
            return "bolt.shield.fill"
        } else if summary.speedRating.contains("Swift") {
            return "flame.fill"
        } else {
            return "sparkles"
        }
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                summaryContent
                    .padding(.bottom, summary.weakWordAttempts.isEmpty ? 100 : 150)
            }

            bottomActionDock
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
    }

    public var summaryContent: some View {
        VStack(spacing: 24) {
            headerView
            bentoMetricsGrid

            if !summary.weakWordAttempts.isEmpty {
                weakWordsSection
            } else {
                perfectScoreCard
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: headerIconName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.vocabHeroAccent)
                .frame(width: 60, height: 60)
                .background(Color.vocabHeroAccent.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(cleanRatingTitle)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.vocabInk)
                    .accessibilityAddTraits(.isHeader)

                Text("Hoàn thành phiên phản xạ Blitz")
                    .font(.subheadline)
                    .foregroundColor(.vocabMuted)
            }
        }
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cleanRatingTitle). Hoàn thành phiên phản xạ Blitz.")
    }

    // MARK: - Bento Metrics Grid
    private var bentoMetricsGrid: some View {
        HStack(spacing: 12) {
            metricCard(
                icon: "bolt.fill",
                value: formattedAvgTime,
                title: "Tốc độ TB",
                accessibilityLabel: "Tốc độ trung bình: \(formattedAvgTime)"
            )

            metricCard(
                icon: "checkmark.circle.fill",
                value: "\(summary.correctWords)/\(summary.totalWords)",
                title: "Độ chính xác",
                accessibilityLabel: "Độ chính xác: \(summary.correctWords) trên \(summary.totalWords) từ"
            )

            metricCard(
                icon: "flame.fill",
                value: "x\(summary.maxComboStreak)",
                title: "Max Combo",
                accessibilityLabel: "Chuỗi combo tối đa: \(summary.maxComboStreak)"
            )
        }
        .padding(.horizontal)
    }

    private func metricCard(icon: String, value: String, title: String, accessibilityLabel: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.vocabHeroAccent)
                .frame(width: 32, height: 32)
                .background(Color.vocabHeroAccent.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.vocabInk)

            Text(title)
                .font(.caption)
                .foregroundColor(.vocabMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Weak Words Section
    private var weakWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.vocabCoral)
                    .font(.subheadline)
                    .accessibilityHidden(true)
                Text("Từ cần củng cố (\(summary.weakWordAttempts.count))")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.vocabInk)
            }
            .padding(.horizontal)
            .accessibilityAddTraits(.isHeader)

            ForEach(summary.weakWordAttempts) { weak in
                weakWordRow(for: weak)
            }
        }
    }

    // MARK: - 3-Tier Vocabulary Row
    private func weakWordRow(for weak: ReflexBlitzAttempt) -> some View {
        let timeLabel = weak.responseTimeMs >= 6000 ? "Hết giờ" : String(format: "%.1fs", Double(weak.responseTimeMs) / 1000.0)
        let meta = [weak.pos, weak.ipa].filter { !$0.isEmpty }.joined(separator: " • ")

        return VStack(alignment: .leading, spacing: 6) {
            // Tier 1: Lemma text on the left, Audio Speaker button on the right
            HStack(alignment: .center) {
                Text(weak.lemma)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.vocabInk)

                Spacer()

                if let onSpeak = onSpeakWord {
                    Button(action: { onSpeak(weak.lemma) }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.footnote)
                            .foregroundColor(.vocabHeroAccent)
                            .frame(width: 32, height: 32)
                            .background(Color.vocabHeroAccent.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Nghe phát âm từ \(weak.lemma)")
                }
            }

            // Tier 2: Part of Speech & IPA phonetics metadata
            if !meta.isEmpty {
                Text(meta)
                    .font(.caption.monospaced())
                    .foregroundColor(.vocabMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            // Tier 3: Vietnamese definition on the left, response time badge on the right
            HStack(alignment: .center, spacing: 8) {
                if !weak.definitionVi.isEmpty {
                    Text(weak.definitionVi)
                        .font(.subheadline)
                        .foregroundColor(.vocabMuted)
                        .lineLimit(2)
                }

                Spacer()

                Text(timeLabel)
                    .font(.caption.bold())
                    .foregroundColor(.vocabCoral)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.vocabCoral.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Từ cần ôn: \(weak.lemma), thời gian phản hồi: \(timeLabel)")
    }

    // MARK: - Perfect Score State
    private var perfectScoreCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundColor(.vocabMint)
                .accessibilityHidden(true)

            Text("Phản xạ hoàn hảo!")
                .font(.headline.weight(.bold))
                .foregroundColor(.vocabInk)

            Text("Bạn đã trả lời chính xác và nhanh chóng toàn bộ từ vựng.")
                .font(.subheadline)
                .foregroundColor(.vocabMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }

    // MARK: - Sticky Bottom Action Dock
    private var bottomActionDock: some View {
        VStack(spacing: 10) {
            if !summary.weakWordAttempts.isEmpty {
                // Primary Action: Re-drill weak words
                Button(action: onReDrillWeak) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline.weight(.semibold))
                            .accessibilityHidden(true)
                        Text("Luyện lại \(summary.weakWordAttempts.count) từ chưa thuộc")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(Color.vocabCoral)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.vocabCoral.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Luyện lại \(summary.weakWordAttempts.count) từ chưa thuộc")

                // Secondary Action: Finish & Save
                Button(action: onFinish) {
                    Text("Hoàn thành & Lưu tiến độ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.vocabMuted)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hoàn thành và lưu tiến độ")
            } else {
                // Primary Action: Finish & Save
                Button(action: onFinish) {
                    Text("Hoàn thành & Lưu tiến độ")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(Color.vocabHeroAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.vocabHeroAccent.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Hoàn thành và lưu tiến độ")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: -4)
        )
    }
}
