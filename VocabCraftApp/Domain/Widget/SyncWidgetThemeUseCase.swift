import CraftUIKit
import Foundation

/// Mirrors the app's selected theme into the shared store so the widget renders with it.
/// Timelines are reloaded only when the stored theme actually changes.
public struct SyncWidgetThemeUseCase: Sendable {
    private let store: WidgetDeckStore
    private let reloader: WidgetReloading

    public init(store: WidgetDeckStore, reloader: WidgetReloading) {
        self.store = store
        self.reloader = reloader
    }

    public func execute(preset: CraftThemePreset) {
        guard store.loadThemePreset() != preset else { return }
        do {
            try store.saveThemePreset(preset)
        } catch {
            print("[SyncWidgetTheme] save failed: \(error)")
            return
        }
        reloader.reloadTimelines(ofKind: WidgetKind.vocab)
    }
}
