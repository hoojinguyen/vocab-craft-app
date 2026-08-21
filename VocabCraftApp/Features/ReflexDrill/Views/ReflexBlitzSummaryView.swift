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
        VStack(spacing: 14) {
            Image(systemName: headerIconName)
                .font(.system(size: 36, weight: .semibold))
                .symbolRenderingMode(.multicolor)
                .frame(width: 68, height: 68)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.vocabHeroAccent.opacity(0.4), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.vocabHeroAccent.opacity(0.2), radius: 12, x: 0, y: 4)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(cleanRatingTitle)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.vocabInk)
                    .accessibilityAddTraits(.isHeader)

                Text("Hoàn thành phiên phản xạ Blitz")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.vocabMuted)
            }
        }
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cleanRatingTitle). Hoàn thành phiên phản xạ Blitz.")
    }

    private struct MetricCardItem {
        let icon: String
        let isMulticolor: Bool
        let accentColor: Color
        let value: String
        let title: String
        let accessibilityLabel: String
    }

    // MARK: - Bento Metrics Grid
    private var bentoMetricsGrid: some View {
        HStack(spacing: 12) {
            metricCard(MetricCardItem(
                icon: "speedometer",
                isMulticolor: false,
                accentColor: .vocabHeroAccent,
                value: formattedAvgTime,
                title: "Tốc độ TB",
                accessibilityLabel: "Tốc độ trung bình: \(formattedAvgTime)"
            ))

            metricCard(MetricCardItem(
                icon: "target",
                isMulticolor: false,
                accentColor: .vocabMint,
                value: "\(summary.correctWords)/\(summary.totalWords)",
                title: "Độ chính xác",
                accessibilityLabel: "Độ chính xác: \(summary.correctWords) trên \(summary.totalWords) từ"
            ))

            metricCard(MetricCardItem(
                icon: "flame.fill",
                isMulticolor: true,
                accentColor: .vocabPeach,
                value: "x\(summary.maxComboStreak)",
                title: "Max Combo",
                accessibilityLabel: "Chuỗi combo tối đa: \(summary.maxComboStreak)"
            ))
        }
        .padding(.horizontal)
    }

    private func metricCard(_ item: MetricCardItem) -> some View {
        VStack(spacing: 8) {
            Group {
                if item.isMulticolor {
                    Image(systemName: item.icon)
                        .symbolRenderingMode(.multicolor)
                } else {
                    Image(systemName: item.icon)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(item.accentColor)
                }
            }
            .font(.system(size: 20, weight: .semibold))
            .frame(width: 38, height: 38)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(item.accentColor.opacity(0.2), lineWidth: 0.8)
            )
            .accessibilityHidden(true)

            Text(item.value)
                .font(.title3.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundColor(.vocabInk)

            Text(item.title)
                .font(.caption2.weight(.medium))
                .foregroundColor(.vocabMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.vocabHairline.opacity(0.7), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.accessibilityLabel)
    }

    // MARK: - Weak Words Section
    private var weakWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.vocabCoral)
                    .font(.headline)
                    .accessibilityHidden(true)
                Text("Từ cần củng cố (\(summary.weakWordAttempts.count))")
                    .font(.headline.weight(.bold))
                    .fontDesign(.rounded)
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

        return VStack(alignment: .leading, spacing: 8) {
            // Tier 1: Lemma text on the left, Audio Speaker button on the right
            HStack(alignment: .center) {
                Text(weak.lemma)
                    .font(.headline.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabInk)

                Spacer()

                if let onSpeak = onSpeakWord {
                    Button(action: { onSpeak(weak.lemma) }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.vocabHeroAccent)
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.vocabHeroAccent.opacity(0.2), lineWidth: 0.8)
                            )
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
                        .foregroundColor(.vocabInk.opacity(0.8))
                        .lineLimit(2)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 10, weight: .bold))
                        .symbolRenderingMode(.hierarchical)

                    Text(timeLabel)
                        .font(.caption2.monospacedDigit().bold())
                }
                .foregroundColor(.vocabCoral)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.vocabCoral.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.vocabHairline.opacity(0.6), lineWidth: 1)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Từ cần ôn: \(weak.lemma), thời gian phản hồi: \(timeLabel)")
    }

    // MARK: - Perfect Score State
    private var perfectScoreCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "medal.fill")
                .font(.system(size: 44, weight: .bold))
                .symbolRenderingMode(.multicolor)
                .accessibilityHidden(true)

            Text("Phản xạ hoàn hảo!")
                .font(.title3.weight(.bold))
                .fontDesign(.rounded)
                .foregroundColor(.vocabInk)

            Text("Bạn đã trả lời chính xác và nhanh chóng toàn bộ từ vựng.")
                .font(.subheadline)
                .foregroundColor(.vocabMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.vocabMint.opacity(0.4), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Sticky Bottom Action Dock
    private var bottomActionDock: some View {
        VStack(spacing: 10) {
            if !summary.weakWordAttempts.isEmpty {
                // Primary Action: Re-drill weak words
                Button(action: onReDrillWeak) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.headline.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityHidden(true)

                        Text("Luyện lại \(summary.weakWordAttempts.count) từ chưa thuộc")
                            .font(.headline.bold())
                            .fontDesign(.rounded)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.vocabCoral, Color.vocabCoral.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.vocabCoral.opacity(0.35), radius: 10, y: 5)
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
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.bold))
                        Text("Hoàn thành & Lưu tiến độ")
                            .font(.headline.bold())
                            .fontDesign(.rounded)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.vocabHeroAccent, Color.vocabMint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.vocabHeroAccent.opacity(0.3), radius: 10, y: 5)
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
