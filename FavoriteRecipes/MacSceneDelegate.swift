#if targetEnvironment(macCatalyst)
import UIKit

/// UIWindowSceneDelegate that manages Mac Catalyst window geometry.
///
/// Why this approach?
/// ─────────────────
/// `requestGeometryUpdate` called from SwiftUI's `.onAppear` fires *after*
/// SwiftUI performs its own initial window layout — which silently overrides
/// our call.  `scene(_:willConnectTo:options:)` fires *before* SwiftUI creates
/// any views, so our geometry request wins and is respected.
///
/// For saving, `sceneWillResignActive` / `sceneDidDisconnect` are used instead
/// of SwiftUI's `scenePhase` because they fire reliably on Mac for every
/// window-close, Cmd-Q, Cmd-H and app-switch event.
final class MacSceneDelegate: NSObject, UIWindowSceneDelegate {

    // MARK: - Connect (before SwiftUI layout)

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let ws = scene as? UIWindowScene else { return }

        ws.sizeRestrictions?.minimumSize = MacWindowManager.minSize

        // Defer one run-loop so the UIWindowScene is fully initialised, but
        // still fires before SwiftUI's first layout pass.
        DispatchQueue.main.async {
            let frame = MacWindowManager.savedFrame(for: ws)
                     ?? MacWindowManager.defaultFrame(for: ws)
            ws.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.Mac(systemFrame: frame),
                errorHandler: nil
            )
        }

        // Register NSWindow autosave *after* the window is ready so AppKit
        // also tracks future moves/resizes automatically.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            MacWindowManager.registerNSWindowAutosave(for: ws)
        }
    }

    // MARK: - Save on every deactivation / disconnect

    func sceneWillResignActive(_ scene: UIScene) {
        guard let ws = scene as? UIWindowScene else { return }
        MacWindowManager.saveFrame(for: ws)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        guard let ws = scene as? UIWindowScene else { return }
        MacWindowManager.saveFrame(for: ws)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // At disconnect the window may already be gone; save best-effort.
        if let ws = scene as? UIWindowScene {
            MacWindowManager.saveFrame(for: ws)
        }
    }
}
#endif
