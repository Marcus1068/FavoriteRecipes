import Foundation
import UserNotifications

/// Rings the user when a timer ends, even if the app is in the background.
protocol TimerNotifying: Sendable {
    func schedule(id: UUID, title: String, endDate: Date) async
    func cancel(id: UUID) async
}

/// Local notifications. Asks for permission the first time a timer starts.
struct LocalTimerNotifier: TimerNotifying {
    func schedule(id: UUID, title: String, endDate: Date) async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])

        let content = UNMutableNotificationContent()
        content.title = String(localized: .timerDoneTitle)
        content.body = title
        content.sound = .default

        let interval = max(1, endDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger))
    }

    func cancel(id: UUID) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
