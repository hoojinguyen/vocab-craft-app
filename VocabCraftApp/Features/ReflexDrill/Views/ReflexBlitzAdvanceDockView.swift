import SwiftUI

/// Ergonomic Bottom Dock Action Button for advancing between drill items in Reflex Blitz.
/// Displays speed metrics (e.g. `⚡️ 1.4s • Từ tiếp theo ➔` or `⚠️ Hết giờ • Từ tiếp theo ➔`),
/// provides clear auditory/tactile feedback, and anchors firmly within the thumb reach zone.
public struct ReflexBlitzAdvanceDockView: View {
    public let isReviewed: Bool
    public let responseTimeMs: Int
    public let isCorrect: Bool
    public let isTimeout: Bool
    public let onAdvance: () -> Void
    public let onSkip: (() -> Void)?

    @State private var advanceTapTrigger = false

    public init(
        isReviewed: Bool,
        responseTimeMs: Int = 0,
        isCorrect: Bool = false,
        isTimeout: Bool = false,
        onAdvance: @escaping () -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self.isReviewed = isReviewed
        self.responseTimeMs = responseTimeMs
        self.isCorrect = isCorrect
        self.isTimeout = isTimeout
        self.onAdvance = onAdvance
        self.onSkip = onSkip
    }

    public init(
        isReviewed: Bool,
        responseTimeMs: Int,
        isCorrect: Bool,
        onAdvance: @escaping () -> Void
    ) {
        self.init(
            isReviewed: isReviewed,
            responseTimeMs: responseTimeMs,
            isCorrect: isCorrect,
            isTimeout: false,
            onAdvance: onAdvance,
            onSkip: nil
        )
    }

    public init(
        cardPhase: ReflexCardPhase,
        onAdvance: @escaping () -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        switch cardPhase {
        case .activeCountdown:
            self.init(
                isReviewed: false,
                responseTimeMs: 0,
                isCorrect: false,
                isTimeout: false,
                onAdvance: onAdvance,
                onSkip: onSkip
            )
        case .reviewed(let result):
            self.init(
                isReviewed: true,
                responseTimeMs: result.responseTimeMs,
                isCorrect: result.isCorrect,
                isTimeout: result.isTimeout,
                onAdvance: onAdvance,
                onSkip: onSkip
            )
        }
    }

    public var formattedResponseTime: String {
        let seconds = Double(responseTimeMs) / 1000.0
        return String(format: "%.1fs", seconds)
    }

    public var buttonTitle: String {
        if isReviewed {
            if isTimeout {
                return "⚠️ Hết giờ • Từ tiếp theo ➔"
            } else if isCorrect {
                return "⚡️ \(formattedResponseTime) • Từ tiếp theo ➔"
            } else {
                return "\(formattedResponseTime) • Từ tiếp theo ➔"
            }
        } else {
            return "Bỏ qua"
        }
    }

    private var buttonGradient: LinearGradient {
        if isReviewed {
            if isCorrect {
                return LinearGradient(
                    colors: [Color.vocabHeroAccent, Color.vocabMint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if isTimeout {
                return LinearGradient(
                    colors: [Color.vocabCoral, Color.vocabPeach],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                return LinearGradient(
                    colors: [Color.vocabPeach, Color.vocabCoral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        } else {
            return LinearGradient(
                colors: [Color.vocabSurfaceCard, Color.vocabSurfaceCard],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if isReviewed {
                Button(action: {
                    advanceTapTrigger.toggle()
                    onAdvance()
                }) {
                    HStack(spacing: 8) {
                        if isTimeout {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .font(.subheadline.bold())
                                .symbolRenderingMode(.hierarchical)
                            Text("Hết giờ • Từ tiếp theo")
                                .font(.headline.weight(.bold))
                                .fontDesign(.rounded)
                        } else if isCorrect {
                            Image(systemName: "bolt.fill")
                                .font(.subheadline.bold())
                                .symbolRenderingMode(.hierarchical)
                                .symbolEffect(.pulse)
                            Text("\(formattedResponseTime) • Từ tiếp theo")
                                .font(.headline.weight(.bold))
                                .fontDesign(.rounded)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.subheadline.bold())
                                .symbolRenderingMode(.hierarchical)
                            Text("\(formattedResponseTime) • Từ tiếp theo")
                                .font(.headline.weight(.bold))
                                .fontDesign(.rounded)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(buttonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(
                        color: isCorrect
                            ? Color.vocabHeroAccent.opacity(0.35)
                            : Color.vocabCoral.opacity(0.35),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .keyboardShortcut(.defaultAction)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(accessibilityDescription)
                .accessibilityHint("Nhấn để chuyển sang từ vựng tiếp theo")
            } else {
                Button(action: {
                    advanceTapTrigger.toggle()
                    if let onSkip = onSkip {
                        onSkip()
                    } else {
                        onAdvance()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("Bỏ qua")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "forward.fill")
                            .font(.caption2.weight(.bold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .foregroundColor(.vocabMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.vocabSurfaceCard)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.vocabHairline.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Bỏ qua từ hiện tại")
            }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .sensoryFeedback(.impact(weight: .medium), trigger: advanceTapTrigger)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isReviewed)
    }

    private var accessibilityDescription: String {
        if isTimeout {
            return "Hết giờ. Nhấn để sang từ tiếp theo"
        } else if isCorrect {
            return "Chính xác, phản xạ \(formattedResponseTime). Nhấn để sang từ tiếp theo"
        } else {
            return "Chưa chính xác, thời gian \(formattedResponseTime). Nhấn để sang từ tiếp theo"
        }
    }
}
