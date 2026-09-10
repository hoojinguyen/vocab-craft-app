import Foundation

public enum DatabaseStoreError: LocalizedError, Sendable, Equatable {
    case storeInitializationFailed(description: String, backupURL: URL?)
    case quarantineBackupFailed(description: String)
    case manualResetFailed(description: String)

    public var errorDescription: String? {
        switch self {
        case .storeInitializationFailed(let desc, let backupURL):
            if let backupURL {
                return AppLocalized.format(
                    "app.database.error.init_failed_backed_up",
                    backupURL.lastPathComponent,
                    desc
                )
            } else {
                return AppLocalized.format(
                    "app.database.error.init_failed",
                    desc
                )
            }
        case .quarantineBackupFailed(let desc):
            return AppLocalized.format(
                "app.database.error.backup_failed",
                desc
            )
        case .manualResetFailed(let desc):
            return AppLocalized.format(
                "app.database.error.reset_failed",
                desc
            )
        }
    }
}
