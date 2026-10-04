import UIKit
import UserNotifications

/// UIApplicationDelegate used to register MacSceneDelegate for Mac Catalyst window
/// management and to show timer notifications while the app is open.
/// All other app lifecycle is handled by SwiftUI.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
#if targetEnvironment(macCatalyst)
        config.delegateClass = MacSceneDelegate.self
#endif
        return config
    }

    /// A timer that ends while the app is open still rings and shows a banner.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
