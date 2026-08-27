import CraftUIKit
import SwiftData
import SwiftUI

#if !SWIFT_PACKAGE
@main
#endif
struct VocabCraftApp: App {
    let container: ModelContainer
    let datasetEngine: DatasetEngine?
    let appContainer: AppContainer

    init() {
        let isTesting = NSClassFromString("XCTestCase") != nil
        let fallbackSchema = Schema(versionedSchema: SchemaV2.self)
        if isTesting {
            let containerResult: ModelContainer
            if let primary = try? SharedAppGroupContainer.createContainer(inMemory: true) {
                containerResult = primary
            } else if let secondary = try? ModelContainer(for: fallbackSchema, migrationPlan: AppMigrationPlan.self) {
                containerResult = secondary
            } else {
                fatalError("Failed to create test ModelContainer")
            }
            self.container = containerResult
            let engine = DatasetEngine()
            self.datasetEngine = engine
            self.appContainer = AppContainer(datasetEngine: engine, modelContainer: container)
            return
        }
        do {
            self.container = try SharedAppGroupContainer.createContainer()
        } catch {
            let containerResult: ModelContainer
            if let primary = try? SharedAppGroupContainer.createContainer(inMemory: true) {
                containerResult = primary
            } else if let secondary = try? ModelContainer(for: fallbackSchema, migrationPlan: AppMigrationPlan.self) {
                containerResult = secondary
            } else {
                fatalError("Failed to create fallback ModelContainer: \(error.localizedDescription)")
            }
            self.container = containerResult
        }
        let engine = DatasetEngine()
        self.datasetEngine = engine
        let args = ProcessInfo.processInfo.arguments
        let initialTab: TabItem
        if args.contains("-tab-reflex") || args.contains("-reflex-mode") || args.contains("-reflex-phase") {
            initialTab = .reflex
        } else if args.contains("-tab-vocabulary") || args.contains("-vocab-state") {
            initialTab = .vocabulary
        } else if args.contains("-tab-settings") {
            initialTab = .settings
        } else {
            initialTab = .home
        }
        let router = AppRouter(initialTab: initialTab)

        if let modeIdx = args.firstIndex(of: "-reflex-mode"), modeIdx + 1 < args.count {
            let modeStr = args[modeIdx + 1]
            let mode = ReflexBlitzMode(rawValue: modeStr) ?? .speaking
            let phaseStr = args.firstIndex(of: "-reflex-phase").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
            let stateStr = args.firstIndex(of: "-reflex-state").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
            let hint = args.contains("-reflex-hint")
            let combo = args.firstIndex(of: "-reflex-combo").flatMap { $0 + 1 < args.count ? Int(args[$0 + 1]) : nil } ?? 0

            let phase: ReflexBlitzPhase
            if phaseStr == "summary" {
                phase = .summary
            } else if phaseStr == "modeSelection" {
                phase = .modeSelection
            } else {
                phase = .drilling
            }

            router.pendingReflexBlitzConfig = ReflexBlitzDeepLinkConfig(
                mode: mode,
                phase: phase,
                state: stateStr,
                showHint: hint,
                combo: combo
            )
        } else if let phaseIdx = args.firstIndex(of: "-reflex-phase"), phaseIdx + 1 < args.count {
            let phaseStr = args[phaseIdx + 1]
            if phaseStr == "summary" {
                router.pendingReflexBlitzConfig = ReflexBlitzDeepLinkConfig(
                    mode: .speaking,
                    phase: .summary,
                    state: nil,
                    showHint: false,
                    combo: 3
                )
            }
        }

        self.appContainer = AppContainer(datasetEngine: engine, modelContainer: container, appRouter: router)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if NSClassFromString("XCTestCase") != nil {
                    Text("Testing...")
                } else {
                    HomepageView(viewModel: appContainer.makeHomepageViewModel())
                        .environment(\.appContainer, appContainer)
                        .environment(\.appRouter, appContainer.appRouter)
                        .environment(\.ttsService, appContainer.ttsService)
                        .environment(\.speechAssessmentService, appContainer.speechAssessmentService)
                        .onOpenURL { url in
                            appContainer.appRouter.handleDeepLink(url: url)
                        }
                }
            }
            .craftTheme(AppThemeManager.shared.currentPreset.theme)
            .preferredColorScheme(AppThemeManager.shared.preferredColorScheme)
        }
        .modelContainer(container)
    }
}
