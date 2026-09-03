import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

public protocol NotificationSchedulerProtocol: Sendable {
    func scheduleDailyReminder(at timeInterval: Double) async
    func cancelDailyReminder() async
}

public final class AppNotificationScheduler: NotificationSchedulerProtocol {
    public init() {}

    public func scheduleDailyReminder(at timeInterval: Double) async {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = String(
            localized: "app.notification.daily_title",
            defaultValue: "Time for your daily vocabulary practice!",
            bundle: .module
        )
        content.body = String(
            localized: "app.notification.daily_body",
            defaultValue: "Keep your learning streak alive with just a few minutes of practice.",
            bundle: .module
        )
        content.sound = .default

        let totalSeconds = Int(timeInterval)
        let hours = (totalSeconds / 3600) % 24
        let minutes = (totalSeconds % 3600) / 60

        var dateComponents = DateComponents()
        dateComponents.hour = hours
        dateComponents.minute = minutes

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "vocabcraft_daily_reminder", content: content, trigger: trigger)

        try? await center.add(request)
        #endif
    }

    public func cancelDailyReminder() async {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["vocabcraft_daily_reminder"])
        #endif
    }
}
