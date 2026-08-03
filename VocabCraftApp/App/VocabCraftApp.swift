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
            TabView {
                ReflexDrillView(datasetEngine: datasetEngine)
                    .tabItem {
                        Label("Reflex Drill", systemImage: "bolt.fill")
                    }

                ContentView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
            }
        }
        .modelContainer(container)
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("VocabCraft")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Luyện phản xạ từ vựng & mẫu câu tiếng Anh")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("VocabCraft")
        }
    }
}
