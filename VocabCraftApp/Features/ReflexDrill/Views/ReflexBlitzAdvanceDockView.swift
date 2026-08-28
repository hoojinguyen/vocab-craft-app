import CraftUIKit
import SwiftUI

/// Ergonomic Bottom Dock Action Button for advancing between drill items in Reflex Blitz.
/// Displays speed metrics (e.g. `⚡️ 1.4s • Từ tiếp theo ➔` or `⚠️ Hết giờ • Từ tiếp theo ➔`),
/// provides clear auditory/tactile feedback, and anchors firmly within the thumb reach zone.
public struct ReflexBlitzAdvanceDockView: View {
    @Environment(\.craftTheme) private var theme

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
            return AppStrings.ReflexBlitz.skipText
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if isReviewed {
                CraftButton(
                    buttonTitle,
                    iconName: isTimeout ? "clock.badge.exclamationmark.fill" : (isCorrect ? "bolt.fill" : "arrow.right.circle.fill"),
                    variant: isCorrect ? .primary : (isTimeout ? .danger : .secondary),
                    size: .lg,
                    isFullWidth: true,
                    style: .tactile3D,
                    action: {
                        advanceTapTrigger.toggle()
                        onAdvance()
                    }
                )
                .keyboardShortcut(.defaultAction)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(accessibilityDescription)
                .accessibilityHint("Nhấn để chuyển sang từ vựng tiếp theo")
            } else if let onSkip = onSkip {
                CraftButton(
                    AppStrings.ReflexBlitz.skip,
                    iconName: "forward.fill",
                    variant: .outline,
                    size: .md,
                    isFullWidth: true,
                    style: .outlined,
                    action: {
                        advanceTapTrigger.toggle()
                        onSkip()
                    }
                )
                .accessibilityLabel(AppStrings.ReflexBlitz.skipText)
            }
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.sm)
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
