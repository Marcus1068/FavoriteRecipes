#if targetEnvironment(macCatalyst)
import UIKit

/// Manages window size/position persistence on Mac Catalyst.
///
/// - Restores the last frame (origin + size) from `UserDefaults` on launch.
/// - Centres and sizes a sensible default on first launch.
/// - Enforces a minimum window size.
/// - Validates the saved frame: if it no longer intersects the available
///   screen area (e.g. secondary display disconnected) it falls back to the
///   default frame so the window is never off-screen.
@MainActor
enum MacWindowManager {

    private static let frameKey   = "mac.windowFrame"
    private static let minSize    = CGSize(width: 820,  height: 600)
    private static let defaultSize = CGSize(width: 1100, height: 780)

    // MARK: - Setup (call from ContentView.onAppear)

    static func configure() {
        guard let scene = activeWindowScene() else { return }

        // Minimum size — prevents the window from being shrunk too small.
        scene.sizeRestrictions?.minimumSize = minSize

        // Geometry update must be deferred: the window isn't fully ready at
        // the moment onAppear fires, so we wait one run-loop pass.
        DispatchQueue.main.async {
            scene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.Mac(systemFrame: targetFrame(for: scene)),
                errorHandler: nil
            )
        }
    }

    // MARK: - Save (call on scenePhase → inactive / background)

    static func saveFrame() {
        guard
            let scene  = activeWindowScene(),
            let window = scene.windows.first
        else { return }

        let f = window.frame
        UserDefaults.standard.set(
            ["x": f.origin.x, "y": f.origin.y, "w": f.width, "h": f.height],
            forKey: frameKey
        )
    }

    // MARK: - Private helpers

    private static func targetFrame(for scene: UIWindowScene) -> CGRect {
        let screen = scene.screen.bounds

        if let saved = loadFrame() {
            // Reject saved frames that are off-screen or smaller than the minimum.
            let tooSmall = saved.width < minSize.width || saved.height < minSize.height
            let offScreen = !screen.intersects(saved.insetBy(dx: 80, dy: 80)) // 80 pt margin
            if !tooSmall && !offScreen { return saved }
        }

        // Centre the default size on screen.
        return CGRect(
            x: (screen.width  - defaultSize.width)  / 2,
            y: (screen.height - defaultSize.height) / 2,
            width:  defaultSize.width,
            height: defaultSize.height
        )
    }

    private static func loadFrame() -> CGRect? {
        guard
            let d = UserDefaults.standard.dictionary(forKey: frameKey) as? [String: Double],
            let x = d["x"], let y = d["y"],
            let w = d["w"], let h = d["h"],
            w > 0, h > 0
        else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }
}
#endif
