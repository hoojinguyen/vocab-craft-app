import SwiftUI

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: AppContainer? = nil
}

private struct AppRouterKey: EnvironmentKey {
    static let defaultValue: AppRouter? = nil
}

private struct TextToSpeechKey: EnvironmentKey {
    static let defaultValue: TextToSpeechProtocol? = nil
}

public extension EnvironmentValues {
    @MainActor
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] ?? .mock }
        set { self[AppContainerKey.self] = newValue }
    }

    @MainActor
    var appRouter: AppRouter {
        get { self[AppRouterKey.self] ?? appContainer.appRouter }
        set { self[AppRouterKey.self] = newValue }
    }

    @MainActor
    var ttsService: TextToSpeechProtocol? {
        get { self[TextToSpeechKey.self] }
        set { self[TextToSpeechKey.self] = newValue }
    }
}
