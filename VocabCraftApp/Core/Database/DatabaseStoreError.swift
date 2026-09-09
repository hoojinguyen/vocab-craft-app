import Foundation

public enum DatabaseStoreError: LocalizedError, Sendable, Equatable {
    case storeInitializationFailed(description: String, backupURL: URL?)
    case quarantineBackupFailed(description: String)
    case manualResetFailed(description: String)

    public var errorDescription: String? {
        switch self {
        case .storeInitializationFailed(let desc, let backupURL):
            if let backupURL {
                return String(
                    localized: "app.database.error.init_failed_backed_up",
                    defaultValue: "Failed to load database. Backup created at \(backupURL.lastPathComponent): \(desc)"
                )
            } else {
                return String(
                    localized: "app.database.error.init_failed",
                    defaultValue: "Failed to load database: \(desc)"
                )
            }
        case .quarantineBackupFailed(let desc):
            return String(
                localized: "app.database.error.backup_failed",
                defaultValue: "Failed to create quarantine backup: \(desc)"
            )
        case .manualResetFailed(let desc):
            return String(
                localized: "app.database.error.reset_failed",
                defaultValue: "Failed to reset database: \(desc)"
            )
        }
    }
}
