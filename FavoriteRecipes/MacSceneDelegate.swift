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
        guard let windowScene = scene as? UIWindowScene else { return }

        windowScene.sizeRestrictions?.minimumSize = MacWindowManager.minSize

        // Defer one run-loop so the UIWindowScene is fully initialised, but
        // still fires before SwiftUI's first layout pass.
        Task { @MainActor in
            let frame = MacWindowManager.savedFrame(for: windowScene)
                     ?? MacWindowManager.defaultFrame(for: windowScene)
            windowScene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.Mac(systemFrame: frame),
                errorHandler: nil
            )
        }

        // Register NSWindow autosave *after* the window is ready so AppKit
        // also tracks future moves/resizes automatically.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            MacWindowManager.registerNSWindowAutosave(for: windowScene)
        }
    }

    // MARK: - Save on every deactivation / disconnect

    func sceneWillResignActive(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        MacWindowManager.saveFrame(for: windowScene)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        MacWindowManager.saveFrame(for: windowScene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // At disconnect the window may already be gone; save best-effort.
        if let windowScene = scene as? UIWindowScene {
            MacWindowManager.saveFrame(for: windowScene)
        }
    }
}
#endif
