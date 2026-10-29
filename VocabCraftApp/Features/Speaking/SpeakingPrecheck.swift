import AVFAudio
import Foundation
import Network

@MainActor
public struct SpeakingPrecheck {
    public enum Issue: Equatable {
        case missingKey
        case microphoneDenied
        case offline
    }

    private let settings: UserSettingsStore
    private let microphone: @MainActor () async -> Bool
    private let isOnline: @MainActor () -> Bool

    public init(
        settings: UserSettingsStore,
        microphone: @escaping @MainActor () async -> Bool,
        isOnline: @escaping @MainActor () -> Bool
    ) {
        self.settings = settings
        self.microphone = microphone
        self.isOnline = isOnline
    }

    public init(settings: UserSettingsStore) {
        self.init(
            settings: settings,
            microphone: { await AVAudioApplication.requestRecordPermission() },
            isOnline: { SpeakingNetworkMonitor.shared.isOnline }
        )
    }

    public func run() async -> [Issue] {
        var issues: [Issue] = []

        if !settings.isGeminiApiKeyConfigured {
            issues.append(.missingKey)
        }
        if !(await microphone()) {
            issues.append(.microphoneDenied)
        }
        if !isOnline() {
            issues.append(.offline)
        }

        return issues
    }
}

@MainActor
private final class SpeakingNetworkMonitor {
    static let shared = SpeakingNetworkMonitor()

    private let monitor: NWPathMonitor

    private init() {
        monitor = NWPathMonitor()
        monitor.start(queue: DispatchQueue(label: "app.speaking.network-monitor"))
    }

    var isOnline: Bool {
        monitor.currentPath.status == .satisfied
    }
}
