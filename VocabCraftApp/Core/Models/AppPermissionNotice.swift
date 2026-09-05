import Foundation

public struct AppPermissionNotice: Equatable, Sendable {
    public let title: String
    public let message: String
    public let settingsActionTitle: String
    public let dismissActionTitle: String

    public init(
        title: String = AppStrings.Lesson.permissionTitleText,
        message: String = AppStrings.Lesson.permissionMessageText,
        settingsActionTitle: String = AppStrings.Lesson.permissionSettingsActionText,
        dismissActionTitle: String = AppStrings.Lesson.permissionDismissActionText
    ) {
        self.title = title
        self.message = message
        self.settingsActionTitle = settingsActionTitle
        self.dismissActionTitle = dismissActionTitle
    }
}

public typealias LessonPermissionNotice = AppPermissionNotice
public typealias ReflexPermissionNotice = AppPermissionNotice
