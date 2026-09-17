import Foundation
import os

enum LessonPerformanceDiagnostics {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "VocabCraftApp"
    private static let logger = Logger(subsystem: subsystem, category: "LessonPerformance")
    private static let signpostLog = OSLog(subsystem: subsystem, category: .pointsOfInterest)

    static func event(_ name: StaticString, detail: String = "") {
        #if DEBUG
        logger.notice("event=\(String(describing: name), privacy: .public) detail=\(detail, privacy: .public)")
        os_signpost(.event, log: signpostLog, name: name, "%{public}@", detail as NSString)
        #endif
    }

    static func error(_ operation: String, error: Error) {
        #if DEBUG
        let nsError = error as NSError
        logger.error("operation=\(operation, privacy: .public) domain=\(nsError.domain, privacy: .public) code=\(nsError.code)")
        #endif
    }
}
