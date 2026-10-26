import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public protocol WidgetReloading: Sendable {
    func reloadTimelines(ofKind kind: String)
}

public struct WidgetCenterReloader: WidgetReloading {
    public init() {}

    public func reloadTimelines(ofKind kind: String) {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #endif
    }
}
