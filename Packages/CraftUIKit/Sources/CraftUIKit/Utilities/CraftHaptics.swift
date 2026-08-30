#if canImport(UIKit)
import UIKit
#endif

/// Reusable haptic engine to avoid creating new generators per interaction.
/// Uses prepared generators and reuses them across calls.
public final class CraftHaptics: Sendable {
    public static let shared = CraftHaptics()

    #if canImport(UIKit) && os(iOS)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    #else
    private init() {}
    #endif

    public func light() {
        #if canImport(UIKit) && os(iOS)
        lightImpact.impactOccurred()
        lightImpact.prepare()
        #endif
    }

    public func medium() {
        #if canImport(UIKit) && os(iOS)
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
        #endif
    }

    public func heavy() {
        #if canImport(UIKit) && os(iOS)
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
        #endif
    }

    public func selection() {
        #if canImport(UIKit) && os(iOS)
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
        #endif
    }

    public func success() {
        #if canImport(UIKit) && os(iOS)
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
        #endif
    }

    public func warning() {
        #if canImport(UIKit) && os(iOS)
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
        #endif
    }

    public func error() {
        #if canImport(UIKit) && os(iOS)
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
        #endif
    }
}
