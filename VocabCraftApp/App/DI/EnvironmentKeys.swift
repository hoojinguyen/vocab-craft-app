import SwiftUI

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: AppContainer? = nil
}

private struct TextToSpeechKey: EnvironmentKey {
    static let defaultValue: TextToSpeechProtocol? = nil
}

public extension EnvironmentValues {
    var appContainer: AppContainer? {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }

    var ttsService: TextToSpeechProtocol? {
        get { self[TextToSpeechKey.self] }
        set { self[TextToSpeechKey.self] = newValue }
    }
}
