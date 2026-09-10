import Foundation
import Observation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftDataMacros) || canImport(SwiftData)
@Observable
@MainActor
public final class AppBootstrapper {
    public enum State: Equatable {
        case loading
        case ready
        case error(DatabaseStoreError)
    }

    public private(set) var state: State = .loading
    public private(set) var container: ModelContainer?
    public private(set) var appContainer: AppContainer?

    private let inMemoryOnly: Bool
    private let arguments: [String]
    private let containerProvider: (() throws -> ModelContainer)?
    private let resetProvider: (() throws -> ModelContainer)?

    public init(
        inMemoryOnly: Bool = false,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        containerProvider: (() throws -> ModelContainer)? = nil,
        resetProvider: (() throws -> ModelContainer)? = nil
    ) {
        self.inMemoryOnly = inMemoryOnly
        self.arguments = arguments
        self.containerProvider = containerProvider
        self.resetProvider = resetProvider
    }

    public func bootstrap() {
        state = .loading
        do {
            let modelContainer: ModelContainer
            if let containerProvider {
                modelContainer = try containerProvider()
            } else {
                modelContainer = try SharedAppGroupContainer.createContainer(inMemory: inMemoryOnly)
            }
            self.container = modelContainer

            if arguments.contains("-reset-progress") {
                try? modelContainer.mainContext.delete(model: UserWordProgress.self)
                try? modelContainer.mainContext.delete(model: UserStageProgress.self)
                try? modelContainer.mainContext.delete(model: ReflexSessionLog.self)
                try? modelContainer.mainContext.delete(model: QuickReflexAttemptRecord.self)
                try? modelContainer.mainContext.save()
            }

            let engine = DatasetEngine()
            let router = Self.createAppRouter(from: arguments)
            self.appContainer = AppContainer(
                datasetEngine: engine,
                modelContainer: modelContainer,
                appRouter: router
            )
            self.state = .ready
        } catch let storeError as DatabaseStoreError {
            self.container = nil
            self.appContainer = nil
            self.state = .error(storeError)
        } catch {
            self.container = nil
            self.appContainer = nil
            self.state = .error(.storeInitializationFailed(description: error.localizedDescription, backupURL: nil))
        }
    }

    public func retry() {
        bootstrap()
    }

    public func confirmReset() {
        state = .loading
        do {
            let newContainer: ModelContainer
            if let resetProvider {
                newContainer = try resetProvider()
            } else {
                newContainer = try SharedAppGroupContainer.resetStoreWithQuarantine()
            }
            self.container = newContainer

            let engine = DatasetEngine()
            let router = Self.createAppRouter(from: arguments)
            self.appContainer = AppContainer(
                datasetEngine: engine,
                modelContainer: newContainer,
                appRouter: router
            )
            self.state = .ready
        } catch let storeError as DatabaseStoreError {
            self.container = nil
            self.appContainer = nil
            self.state = .error(storeError)
        } catch {
            self.container = nil
            self.appContainer = nil
            self.state = .error(.manualResetFailed(description: error.localizedDescription))
        }
    }

    public static func createAppRouter(from args: [String]) -> AppRouter {
        let initialTab: TabItem
        if args.contains("-tab-reflex") || args.contains("-reflex-mode") || args.contains("-reflex-phase") {
            initialTab = .reflex
        } else if args.contains("-tab-vocabulary") || args.contains("-vocab-state") {
            initialTab = .vocabulary
        } else if args.contains("-tab-settings") {
            initialTab = .settings
        } else {
            initialTab = .home
        }
        let router = AppRouter(initialTab: initialTab)

        if let modeIdx = args.firstIndex(of: "-reflex-mode"), modeIdx + 1 < args.count {
            let modeStr = args[modeIdx + 1]
            let mode = ReflexBlitzMode(rawValue: modeStr) ?? .speaking
            let phaseStr = args.firstIndex(of: "-reflex-phase").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
            let stateStr = args.firstIndex(of: "-reflex-state").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
            let hint = args.contains("-reflex-hint")
            let combo = args.firstIndex(of: "-reflex-combo").flatMap { $0 + 1 < args.count ? Int(args[$0 + 1]) : nil } ?? 0

            let phase: ReflexBlitzPhase
            if phaseStr == "summary" {
                phase = .summary
            } else if phaseStr == "modeSelection" {
                phase = .modeSelection
            } else {
                phase = .drilling
            }

            router.pendingReflexBlitzConfig = ReflexBlitzDeepLinkConfig(
                mode: mode,
                phase: phase,
                state: stateStr,
                showHint: hint,
                combo: combo
            )
        } else if let phaseIdx = args.firstIndex(of: "-reflex-phase"), phaseIdx + 1 < args.count {
            let phaseStr = args[phaseIdx + 1]
            if phaseStr == "summary" {
                router.pendingReflexBlitzConfig = ReflexBlitzDeepLinkConfig(
                    mode: .speaking,
                    phase: .summary,
                    state: nil,
                    showHint: false,
                    combo: 3
                )
            }
        }
        return router
    }
}
#else
@Observable
@MainActor
public final class AppBootstrapper {
    public enum State: Equatable {
        case loading
        case ready
        case error(DatabaseStoreError)
    }

    public private(set) var state: State = .ready
    public private(set) var container: Any?
    public private(set) var appContainer: AppContainer?

    public init(
        inMemoryOnly: Bool = false,
        arguments: [String] = [],
        containerProvider: (() throws -> Any)? = nil,
        resetProvider: (() throws -> Any)? = nil
    ) {}

    public func bootstrap() {}
    public func retry() {}
    public func confirmReset() {}
}
#endif
