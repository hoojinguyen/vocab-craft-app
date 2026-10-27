import CraftUIKit
#if canImport(SwiftData)
import SwiftData
#endif
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if !SWIFT_PACKAGE
@main
#endif
struct VocabCraftApp: App {
    @State private var themeManager = CraftThemeManager.shared
    @State private var bootstrapper = AppBootstrapper()
    @State private var syncWidgetTheme = SyncWidgetThemeUseCase(
        store: .appGroup(),
        reloader: WidgetCenterReloader()
    )
    @Environment(\.scenePhase) private var scenePhase

    init() {}

    private var isFeedbackTestLaunch: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-test-lesson-feedback-incorrect")
            || args.contains("-test-lesson-feedback-correct")
            || args.contains("-test-lesson-discovery")
            || args.contains("-test-path-switch")
            || args.contains("-test-treasure-claim")
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
                bootstrapper.handleDeepLink(url)
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .background,
                      let refresh = bootstrapper.appContainer?.refreshWidgetDeckUseCase else { return }
                Self.refreshWidgetDeckInBackground(refresh)
            }
            .onChange(of: themeManager.currentPreset, initial: true) { _, newPreset in
                syncWidgetTheme.execute(preset: newPreset)
            }
            .craftTheme(themeManager.currentPreset.theme)
            .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }

    /// Keeps the process alive long enough for the widget deck refresh to finish after backgrounding.
    @MainActor
    private static func refreshWidgetDeckInBackground(_ refresh: any RefreshWidgetDeckUseCaseProtocol) {
        #if canImport(UIKit)
        let holder = BackgroundTaskHolder()
        holder.id = UIApplication.shared.beginBackgroundTask(withName: "RefreshWidgetDeck") {
            holder.end()
        }
        Task { @MainActor in
            await refresh.execute()
            holder.end()
        }
        #else
        Task { await refresh.execute() }
        #endif
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
        } else if args.contains("-show-shadowing") {
            ShadowingPracticeView(viewModel: appContainer.makeShadowingPracticeViewModel(for: ShadowingVideoRepositoryImpl.sampleVideo))
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

#if canImport(UIKit)
/// Main-actor box so the expiration handler and the refresh task can end the same background task once.
@MainActor
private final class BackgroundTaskHolder {
    var id = UIBackgroundTaskIdentifier.invalid

    func end() {
        guard id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
        id = .invalid
    }
}
#endif
