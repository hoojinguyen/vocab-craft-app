import Foundation
import Testing
@testable import VocabCraftApp

@Suite("SyncWidgetThemeUseCase")
struct SyncWidgetThemeUseCaseTests {
    private func makeStore() -> WidgetDeckStore {
        WidgetDeckStore(
            directoryURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("SyncWidgetThemeTests-\(UUID().uuidString)", isDirectory: true)
        )
    }

    @Test func savesAndReloadsWhenThemeChanges() throws {
        let store = makeStore()
        let reloader = RecordingWidgetReloader()

        SyncWidgetThemeUseCase(store: store, reloader: reloader).execute(preset: .playfulOwl)

        #expect(store.loadThemePreset() == .playfulOwl)
        #expect(reloader.kinds == [WidgetKind.vocab])
    }

    @Test func skipsWriteAndReloadWhenThemeUnchanged() throws {
        let store = makeStore()
        try store.saveThemePreset(.classic)
        let reloader = RecordingWidgetReloader()

        SyncWidgetThemeUseCase(store: store, reloader: reloader).execute(preset: .classic)

        #expect(reloader.kinds.isEmpty)
    }

    @Test func missingThemeIsTreatedAsEditorial() {
        let store = makeStore()
        let reloader = RecordingWidgetReloader()

        SyncWidgetThemeUseCase(store: store, reloader: reloader).execute(preset: .editorial)

        #expect(reloader.kinds.isEmpty)
    }

    @Test func reloadsAgainWhenThemeChangesBack() {
        let store = makeStore()
        let reloader = RecordingWidgetReloader()
        let useCase = SyncWidgetThemeUseCase(store: store, reloader: reloader)

        useCase.execute(preset: .smartCoach)
        useCase.execute(preset: .editorial)

        #expect(store.loadThemePreset() == .editorial)
        #expect(reloader.kinds.count == 2)
    }
}

private final class RecordingWidgetReloader: WidgetReloading, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var kinds: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func reloadTimelines(ofKind kind: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(kind)
    }
}
