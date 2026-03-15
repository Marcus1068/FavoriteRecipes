import UIKit

/// UIApplicationDelegate used solely to register MacSceneDelegate for Mac
/// Catalyst window management.  All other app lifecycle is handled by SwiftUI.
class AppDelegate: NSObject, UIApplicationDelegate {
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
}
