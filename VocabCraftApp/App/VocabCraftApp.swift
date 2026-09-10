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
        if ProcessInfo.processInfo.arguments.contains("-show-catalog") {
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
