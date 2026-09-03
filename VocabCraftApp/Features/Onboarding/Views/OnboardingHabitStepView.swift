import CraftUIKit
import SwiftUI
import UserNotifications

public struct OnboardingHabitStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    private let wordOptions: [(words: Int, minutes: Int, isPopular: Bool)] = [
        (5, 5, false),
        (10, 10, true),
        (15, 15, false),
        (20, 20, false)
    ]

    private let reminderOptions: [(titleKey: LocalizedStringKey, interval: Double)] = [
        ("app.onboarding.habit.reminder_morning", 28800),  // 08:00
        ("app.onboarding.habit.reminder_lunch", 45000),    // 12:30
        ("app.onboarding.habit.reminder_evening", 72000)   // 20:00
    ]

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("app.onboarding.habit.title")
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("app.onboarding.habit.subtitle")
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Daily Word Goals
                    VStack(spacing: theme.spacing.md) {
                        ForEach(wordOptions, id: \.words) { opt in
                            let titleStr = String(
                                format: String(localized: "app.onboarding.habit.words_per_day_format", defaultValue: "%lld words per day", bundle: .module),
                                Int64(opt.words)
                            )
                            let subStr = String(
                                format: String(localized: "app.onboarding.habit.minutes_per_day_format", defaultValue: "%lld min / day", bundle: .module),
                                Int64(opt.minutes)
                            )

                            ZStack(alignment: .topTrailing) {
                                CraftChoiceCard(
                                    prefix: nil as String?,
                                    prefixStyle: .none,
                                    title: titleStr,
                                    subtitle: subStr,
                                    state: viewModel.selectedDailyWords == opt.words ? .selected : .idle,
                                    showsStatusIndicator: false,
                                    action: {
                                        CraftHaptics.shared.selection()
                                        viewModel.selectedDailyWords = opt.words
                                    }
                                )

                                if opt.isPopular {
                                    CraftBadge(
                                        String(localized: "app.onboarding.habit.popular_badge", bundle: .module),
                                        variant: .subtle,
                                        tone: .primary,
                                        size: .sm
                                    )
                                    .padding(.trailing, theme.spacing.base)
                                    .padding(.top, theme.spacing.sm)
                                    .allowsHitTesting(false)
                                }
                            }
                        }
                    }

                    // Reminder Time Header
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("app.onboarding.habit.reminder_header")
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.colors.textPrimary)

                        HStack(spacing: theme.spacing.sm) {
                            ForEach(reminderOptions, id: \.interval) { opt in
                                Button {
                                    CraftHaptics.shared.selection()
                                    viewModel.selectedReminderInterval = opt.interval
                                } label: {
                                    Text(opt.titleKey)
                                        .font(theme.typography.caption)
                                        .fontWeight(.semibold)
                                        .padding(.vertical, theme.spacing.sm)
                                        .padding(.horizontal, theme.spacing.md)
                                        .background(
                                            viewModel.selectedReminderInterval == opt.interval
                                                ? theme.colors.brandPrimary
                                                : theme.colors.surfaceCard
                                        )
                                        .foregroundStyle(
                                            viewModel.selectedReminderInterval == opt.interval
                                                ? theme.colors.textInverse
                                                : theme.colors.textPrimary
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }

            Spacer()

            CraftButton(
                "app.onboarding.common.continue",
                variant: .primary,
                size: .lg,
                isFullWidth: true
            ) {
                requestNotificationPermissionAndAdvance()
            }
            .disabled(!viewModel.canContinue)
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
        }
    }

    private func requestNotificationPermissionAndAdvance() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                viewModel.updateNotificationPermission(granted: granted)
                viewModel.nextStep()
            }
        }
    }
}
