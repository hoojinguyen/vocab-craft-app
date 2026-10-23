import Foundation

/// Feature flag configuration controlling the availability of the Guided Communication Practice experience.
public enum GuidedPracticeFeatureConfiguration {
    public static let userDefaultsKey = "enable_guided_practice"
    public static let launchArgument = "-enable-guided-practice"

    /// Indicates whether the Guided Communication Practice feature is enabled.
    /// Defaults to false. Can be enabled via launch argument, environment variable, or user defaults setting.
    public static var enabled: Bool {
        get {
            if ProcessInfo.processInfo.arguments.contains(launchArgument) {
                return true
            }
            if ProcessInfo.processInfo.environment["ENABLE_GUIDED_PRACTICE"] == "1" {
                return true
            }
            return UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }

    /// Resets the configuration to default state (useful for test isolation).
    public static func reset() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
