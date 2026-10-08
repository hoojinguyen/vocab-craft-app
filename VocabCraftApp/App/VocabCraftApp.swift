import CraftUIKit
#if canImport(SwiftData)
import SwiftData
#endif
import SwiftUI

#if !SWIFT_PACKAGE
@main
#endif
struct VocabCraftApp: App {
    @State private var themeManager = CraftThemeManager.shared
    @State private var bootstrapper = AppBootstrapper()

    init() {}

    private var isFeedbackTestLaunch: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-test-lesson-feedback-incorrect") || args.contains("-test-lesson-feedback-correct")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if NSClassFromString("XCTestCase") != nil {
                    Text(verbatim: "Testing...")
                } else {
                    switch bootstrapper.state {
                    case .loading:
                        ProgressView()
                            .task {
                                bootstrapper.bootstrap()
                            }
                    case .error(let error):
                        DatabaseRecoveryView(
                            error: error,
                            onRetry: {
                                bootstrapper.retry()
                            },
                            onConfirmReset: {
                                bootstrapper.confirmReset()
                            }
                        )
                    case .ready:
                        if let appContainer = bootstrapper.appContainer {
                            contentView(for: appContainer)
                        } else {
                            ProgressView()
                                .task {
                                    bootstrapper.bootstrap()
                                }
                        }
                    }
                }
            }
            .onOpenURL { url in
                bootstrapper.appContainer?.appRouter.handleDeepLink(url: url)
            }
            .craftTheme(themeManager.currentPreset.theme)
            .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }

    @ViewBuilder
    private func contentView(for appContainer: AppContainer) -> some View {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-show-roleplay-room") {
            RoleplayRoomView(viewModel: appContainer.makeRoleplayRoomViewModel(for: RoleplayScenario.cafeMock), onDismiss: {})
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
        } else if args.contains("-show-voice-call") {
            RoleplayVoiceCallView(viewModel: appContainer.makeRoleplayVoiceCallViewModel(for: RoleplayScenario.cafeMock), onDismiss: {})
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
        } else if args.contains("-show-roleplay-summary") {
            RoleplaySummaryView(
                summary: RoleplaySessionSummary(
                    scenarioId: "scenario_cafe",
                    totalTurns: 6,
                    targetWordsAttempted: ["espresso", "croissant"],
                    targetWordsMastered: ["espresso"],
                    fluencyScore: 88,
                    xpEarned: 25,
                    refinements: [
                        SentenceRefinementPair(
                            originalUserSentence: "I want coffee espresso please.",
                            refinedNativeSentence: "I'd like an espresso, please."
                        )
                    ]
                ),
                onDismiss: {}
            )
            .environment(\.appContainer, appContainer)
            .environment(\.appRouter, appContainer.appRouter)
            .environment(\.ttsService, appContainer.ttsService)
        } else if args.contains("-show-ai-config") {
            AIConfigSheet(store: appContainer.userSettingsStore)
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
        } else if args.contains("-show-ai-hub") {
            AIAssistantHubView(viewModel: appContainer.makeAIAssistantHubViewModel())
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
        } else if args.contains("-show-settings") {
            SettingsView(viewModel: appContainer.makeSettingsViewModel())
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
        } else if args.contains("-show-catalog") {
            CraftCatalogView()
        } else if !appContainer.userSettingsStore.hasCompletedOnboarding && !isFeedbackTestLaunch {
            OnboardingCoordinatorView(viewModel: appContainer.makeOnboardingViewModel())
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
        } else {
            HomepageView(viewModel: appContainer.makeHomepageViewModel())
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
        }
    }
}
