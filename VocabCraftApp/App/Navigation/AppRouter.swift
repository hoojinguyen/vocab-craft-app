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

    public init(initialTab: TabItem = .home) {
        self.selectedTab = initialTab
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
        } else if host == "vocabulary" {
            selectTab(.vocabulary)
        } else if host == "settings" {
            selectTab(.settings)
        } else {
            selectTab(.home)
        }
    }
}
