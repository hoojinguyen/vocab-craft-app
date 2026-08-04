import SwiftUI
import SwiftData

@main
struct VocabCraftApp: App {
    let container: ModelContainer
    let datasetEngine: DatasetEngine?

    init() {
        do {
            container = try SharedAppGroupContainer.createContainer()
        } catch {
            fatalError("Failed to initialize SwiftData App Group container: \(error)")
        }
        datasetEngine = DatasetEngine()
    }

    var body: some Scene {
        WindowGroup {
            HomepageView()
        }
        .modelContainer(container)
    }
}
