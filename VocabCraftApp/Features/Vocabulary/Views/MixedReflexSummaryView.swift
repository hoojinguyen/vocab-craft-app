import SwiftUI

/// Summary view for Mixed Reflex Drill sessions.
/// Displays session rating, Bento metrics (Speed, Accuracy, Max Combo),
/// list of practiced words with mastery badges, and actions to retry or finish.
public struct MixedReflexSummaryView: View {
    public let summary: ReflexBlitzSessionSummary
    public let practicedWords: [VaultWordItem]
    public let onSpeakWord: ((String) -> Void)?
    public let onRetry: () -> Void
    public let onDone: () -> Void

    public init(
        summary: ReflexBlitzSessionSummary,
        practicedWords: [VaultWordItem] = [],
        onSpeakWord: ((String) -> Void)? = nil,
        onRetry: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.summary = summary
        self.practicedWords = practicedWords
        self.onSpeakWord = onSpeakWord
        self.onRetry = onRetry
        self.onDone = onDone
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

    private var accuracyPercentage: Int {
        guard summary.totalWords > 0 else { return 0 }
        return Int((Double(summary.correctWords) / Double(summary.totalWords)) * 100)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    metricsBentoGrid
                    practicedWordsSection
                }
                .padding(.bottom, 110)
            }

            stickyBottomActionDock
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: headerIconName)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.vocabHeroAccent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 68, height: 68)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.vocabHeroAccent.opacity(0.35), lineWidth: 1.5)
                )
                .shadow(color: Color.vocabHeroAccent.opacity(0.20), radius: 12, x: 0, y: 4)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(cleanRatingTitle)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.vocabInk)
                    .accessibilityAddTraits(.isHeader)

                Text("Hoàn thành bài luyện tập phản xạ ngẫu nhiên")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.vocabMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
    }

    // MARK: - Metrics Bento Grid
    private var metricsBentoGrid: some View {
        HStack(spacing: 10) {
            metricCard(
                icon: "speedometer",
                color: .vocabHeroAccent,
                value: formattedAvgTime,
                title: "Tốc độ TB",
                accessibilityLabel: "Tốc độ trung bình: \(formattedAvgTime)"
            )

            metricCard(
                icon: "target",
                color: .vocabMint,
                value: "\(summary.correctWords)/\(summary.totalWords)",
                title: "Độ chính xác",
                accessibilityLabel: "Độ chính xác: \(summary.correctWords) trên \(summary.totalWords)"
            )

            metricCard(
                icon: "flame.fill",
                color: .vocabPeach,
                value: "x\(summary.maxComboStreak)",
                title: "Max Combo",
                accessibilityLabel: "Chuỗi combo tối đa: \(summary.maxComboStreak)"
            )
        }
        .padding(.horizontal, 16)
    }

    private func metricCard(
        icon: String,
        color: Color,
        value: String,
        title: String,
        accessibilityLabel: String
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(value)
                .font(.title3.weight(.bold))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundColor(.vocabInk)

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundColor(.vocabMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Practiced Words Section
    private var practicedWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "character.book.closed.fill")
                    .font(.subheadline.bold())
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.vocabHeroAccent)

                Text("Danh sách từ đã luyện (\(summary.attempts.count))")
                    .font(.headline.bold())
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabInk)
            }
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: 10) {
                ForEach(summary.attempts) { attempt in
                    wordAttemptRow(attempt)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func wordAttemptRow(_ attempt: ReflexBlitzAttempt) -> some View {
        let isMasteredWord = isWordMastered(attempt: attempt)
        let timeFormatted = String(format: "%.1fs", Double(attempt.responseTimeMs) / 1000.0)

        return VStack(alignment: .leading, spacing: 8) {
            wordAttemptHeader(attempt: attempt, isMasteredWord: isMasteredWord)
            wordAttemptMeta(attempt: attempt)
            wordAttemptFooter(attempt: attempt, timeFormatted: timeFormatted)
        }
        .padding(14)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(attempt.lemma), \(attempt.definitionVi), thời gian phản hồi: \(timeFormatted)")
    }

    private func wordAttemptHeader(attempt: ReflexBlitzAttempt, isMasteredWord: Bool) -> some View {
        HStack(alignment: .center) {
            Text(attempt.lemma)
                .font(.headline.weight(.bold))
                .fontDesign(.rounded)
                .foregroundColor(.vocabInk)

            if let onSpeak = onSpeakWord {
                Button(action: { onSpeak(attempt.lemma) }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.vocabHeroAccent)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.vocabHeroAccent.opacity(0.2), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Nghe phát âm từ \(attempt.lemma)")
            }

            Spacer()

            wordAttemptStatusBadge(attempt: attempt, isMasteredWord: isMasteredWord)
        }
    }

    @ViewBuilder
    private func wordAttemptStatusBadge(attempt: ReflexBlitzAttempt, isMasteredWord: Bool) -> some View {
        if isMasteredWord {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption2.bold())
                Text("Đã thuộc")
                    .font(.caption2.bold())
            }
            .foregroundColor(.vocabMint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.vocabMint.opacity(0.14))
            .clipShape(Capsule())
        } else if attempt.isCorrect {
            HStack(spacing: 3) {
                Image(systemName: "checkmark")
                    .font(.caption2.bold())
                Text("Đúng")
                    .font(.caption2.bold())
            }
            .foregroundColor(.vocabHeroAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.vocabHeroAccent.opacity(0.12))
            .clipShape(Capsule())
        } else {
            HStack(spacing: 3) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2.bold())
                Text("Đã luyện lại")
                    .font(.caption2.bold())
            }
            .foregroundColor(.vocabPeach)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.vocabPeach.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func wordAttemptMeta(attempt: ReflexBlitzAttempt) -> some View {
        let metaParts = [attempt.pos, attempt.ipa].filter { !$0.isEmpty }
        if !metaParts.isEmpty {
            Text(metaParts.joined(separator: " • "))
                .font(.caption.monospaced())
                .foregroundColor(.vocabMuted)
        }
    }

    private func wordAttemptFooter(attempt: ReflexBlitzAttempt, timeFormatted: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if !attempt.definitionVi.isEmpty {
                Text(attempt.definitionVi)
                    .font(.subheadline)
                    .foregroundColor(.vocabInk.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 10, weight: .bold))
                    .symbolRenderingMode(.hierarchical)

                Text(timeFormatted)
                    .font(.caption2.monospacedDigit().bold())
            }
            .foregroundColor(attempt.isCorrect ? .vocabHeroAccent : .vocabCoral)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background((attempt.isCorrect ? Color.vocabHeroAccent : Color.vocabCoral).opacity(0.10))
            .clipShape(Capsule())
        }
    }

    private func isWordMastered(attempt: ReflexBlitzAttempt) -> Bool {
        if let matchingWord = practicedWords.first(where: { $0.id == attempt.wordId || $0.lemma.lowercased() == attempt.lemma.lowercased() }) {
            return matchingWord.isMastered
        }
        return false
    }

    // MARK: - Sticky Bottom Action Dock
    private var stickyBottomActionDock: some View {
        VStack(spacing: 8) {
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.headline.weight(.bold))
                        .symbolRenderingMode(.hierarchical)

                    Text("Luyện tập lại")
                        .font(.headline.bold())
                        .fontDesign(.rounded)
                }
                .foregroundColor(.vocabInk)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.vocabSurfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.vocabHairline, lineWidth: 1)
                )
            }
            .buttonStyle(BentoCardButtonStyle())
            .accessibilityLabel("Luyện tập lại danh sách từ này")

            Button(action: onDone) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))

                    Text("Hoàn thành & Lưu tiến độ")
                        .font(.headline.bold())
                        .fontDesign(.rounded)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.vocabHeroAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.vocabHeroAccent.opacity(0.30), radius: 10, y: 4)
            }
            .buttonStyle(BentoCardButtonStyle())
            .accessibilityLabel("Hoàn thành và lưu tiến độ")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: -4)
        )
    }
}
