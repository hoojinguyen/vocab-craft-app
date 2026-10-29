import Foundation
import Observation
import SwiftUI

/// App-wide Navigation Router managing Tab selection and Deep Linking.
@MainActor
@Observable
public final class AppRouter {
    public var selectedTab: TabItem
    public var navigationPath: NavigationPath
    public var pendingReflexBlitzConfig: ReflexBlitzDeepLinkConfig?
    public var pendingShadowingVideoId: String?
    public var pendingSmartReview: Bool = false

    public init(initialTab: TabItem = .home) {
        let args = ProcessInfo.processInfo.arguments
        let testAIArgs = ["-tab-ai", "-test-ai-config", "-test-ai-room", "-test-ai-voice", "-test-ai-summary"]
        let testShadowingArgs = ["-test-shadowing", "-test-shadowing-hub"]
        if testAIArgs.contains(where: { args.contains($0) }) || testShadowingArgs.contains(where: { args.contains($0) }) {
            self.selectedTab = .aiAssistant
        } else if args.contains("-tab-settings") {
            self.selectedTab = .settings
        } else {
            self.selectedTab = initialTab
        }
        self.navigationPath = NavigationPath()
    }

    public func selectTab(_ tab: TabItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedTab = tab
        }
    }

    public func navigateToHome() {
        selectTab(.home)
    }

    public func navigateToVocabulary() {
        selectTab(.vocabulary)
    }

    public func navigateToReflex() {
        selectTab(.reflex)
    }

    public func navigateToAIAssistant() {
        selectTab(.aiAssistant)
    }

    public func navigateToSettings() {
        selectTab(.settings)
    }

    public func handleDeepLink(url: URL) {
        print("[AppRouter] handleDeepLink received: \(url.absoluteString)")
        guard url.scheme == "vocabcraft" else { return }
        let host = url.host ?? ""
        if host == "reflex" || url.absoluteString.contains("reflex") {
            let query = url.query ?? ""
            var queryParams: [String: String] = [:]
            for item in query.split(separator: "&") {
                let pair = item.split(separator: "=")
                if pair.count == 2 {
                    queryParams[String(pair[0])] = String(pair[1])
                }
            }
            let modeParam = queryParams["mode"]
            let phaseParam = queryParams["phase"]
            let stateParam = queryParams["state"]
            let hintParam = queryParams["hint"] == "true"
            let comboParam = Int(queryParams["combo"] ?? "0") ?? 0

            let mode = ReflexBlitzMode(rawValue: modeParam ?? "") ?? .speaking
            let phase: ReflexBlitzPhase
            if phaseParam == "modeSelection" {
                phase = .modeSelection
            } else if phaseParam == "summary" {
                phase = .summary
            } else if phaseParam == "countdown" {
                phase = .countdown
            } else {
                phase = .drilling
            }

            self.pendingReflexBlitzConfig = ReflexBlitzDeepLinkConfig(
                mode: mode,
                phase: phase,
                state: stateParam,
                showHint: hintParam,
                combo: comboParam
            )
            print("[AppRouter] pendingReflexBlitzConfig set: mode=\(mode), phase=\(phase), state=\(String(describing: stateParam))")
            selectTab(.reflex)
        } else if host == "shadowing" {
            let query = url.query ?? ""
            for item in query.split(separator: "&") {
                let pair = item.split(separator: "=")
                if pair.count == 2, pair[0] == "videoId" {
                    self.pendingShadowingVideoId = String(pair[1])
                }
            }
        } else if host == "vocabulary" {
            selectTab(.vocabulary)
        } else if host == "review" {
            pendingSmartReview = true
            selectTab(.vocabulary)
        } else if host == "settings" {
            selectTab(.settings)
        } else if host == "speaking" || host == "ai" || host == "aiAssistant" {
            selectTab(.aiAssistant)
        } else {
            selectTab(.home)
        }
    }
}
