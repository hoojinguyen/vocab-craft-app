import SwiftUI
import SwiftData

@main
struct VocabCraftApp: App {
    let container: ModelContainer
    let datasetEngine: DatasetEngine?
    let appContainer: AppContainer

    init() {
        do {
            container = try SharedAppGroupContainer.createContainer()
        } catch {
            fatalError("Failed to initialize SwiftData App Group container: \(error)")
        }
        let engine = DatasetEngine()
        self.datasetEngine = engine
        self.appContainer = AppContainer(datasetEngine: engine, modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            HomepageView(viewModel: appContainer.makeHomepageViewModel())
        }
        .modelContainer(container)
    }
}
