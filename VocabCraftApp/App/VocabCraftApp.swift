import SwiftUI
import SwiftData

@main
struct VocabCraftApp: App {
    let container: ModelContainer
    let datasetEngine: DatasetEngine?
    let appContainer: AppContainer

    init() {
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            self.container = (try? SharedAppGroupContainer.createContainer(inMemory: true)) ?? (try! ModelContainer(for: Schema([UserWordProgress.self, ReflexSessionLog.self, WidgetCurrentState.self])))
            let engine = DatasetEngine()
            self.datasetEngine = engine
            self.appContainer = AppContainer(datasetEngine: engine, modelContainer: container)
            return
        }
        do {
            self.container = try SharedAppGroupContainer.createContainer()
        } catch {
            self.container = (try? SharedAppGroupContainer.createContainer(inMemory: true)) ?? (try! ModelContainer(for: Schema([UserWordProgress.self, ReflexSessionLog.self, WidgetCurrentState.self])))
        }
        let engine = DatasetEngine()
        self.datasetEngine = engine
        self.appContainer = AppContainer(datasetEngine: engine, modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            HomepageView(viewModel: appContainer.makeHomepageViewModel())
                .environment(\.appContainer, appContainer)
                .environment(\.ttsService, appContainer.ttsService)
        }
        .modelContainer(container)
    }
}
