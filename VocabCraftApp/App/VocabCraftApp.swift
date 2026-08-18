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
        let initialTab: TabItem
        if ProcessInfo.processInfo.arguments.contains("-tab-reflex") {
            initialTab = .reflex
        } else if ProcessInfo.processInfo.arguments.contains("-tab-vocabulary") {
            initialTab = .vocabulary
        } else if ProcessInfo.processInfo.arguments.contains("-tab-settings") {
            initialTab = .settings
        } else {
            initialTab = .home
        }
        let router = AppRouter(initialTab: initialTab)
        self.appContainer = AppContainer(datasetEngine: engine, modelContainer: container, appRouter: router)
    }

    var body: some Scene {
        WindowGroup {
            HomepageView(viewModel: appContainer.makeHomepageViewModel())
                .environment(\.appContainer, appContainer)
                .environment(\.appRouter, appContainer.appRouter)
                .environment(\.ttsService, appContainer.ttsService)
                .environment(\.speechAssessmentService, appContainer.speechAssessmentService)
                .onOpenURL { url in
                    appContainer.appRouter.handleDeepLink(url: url)
                }
                .onAppear {
                    let args = ProcessInfo.processInfo.arguments
                    if args.contains("-tab-reflex") {
                        appContainer.appRouter.selectTab(.reflex)
                    } else if args.contains("-tab-vocabulary") {
                        appContainer.appRouter.selectTab(.vocabulary)
                    } else if args.contains("-tab-settings") {
                        appContainer.appRouter.selectTab(.settings)
                    }
                }
        }
        .modelContainer(container)
    }
}
