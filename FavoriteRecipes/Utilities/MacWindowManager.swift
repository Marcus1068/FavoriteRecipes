#if targetEnvironment(macCatalyst)
import UIKit

@MainActor
enum MacWindowManager {

    static let minSize     = CGSize(width: 820,  height: 600)
    static let defaultSize = CGSize(width: 1100, height: 780)

    private static let userDefaultsKey = "mac.windowFrame"
    private static let autosaveName    = "FavoriteRecipesMain"

    // MARK: - Frame persistence

    /// Saves the current window frame.  Reads from `effectiveGeometry` if
    /// available (same coordinate space as `systemFrame`), falls back to
    /// `UIWindow.frame`.
    static func saveFrame(for scene: UIWindowScene) {
        let frame: CGRect?

        // Prefer effectiveGeometry — it's in the same coordinate space as
        // the systemFrame we pass to requestGeometryUpdate.
        if let macGeo = scene.effectiveGeometry as? UIWindowScene.GeometryPreferences.Mac {
            frame = macGeo.systemFrame
        } else {
            frame = scene.windows.first?.frame
        }

        guard let f = frame, f.width >= minSize.width, f.height >= minSize.height else { return }

        UserDefaults.standard.set(
            ["x": f.origin.x, "y": f.origin.y, "w": f.width, "h": f.height],
            forKey: userDefaultsKey
        )
        UserDefaults.standard.synchronize()
    }

    /// Returns the saved frame if it is valid and on-screen, otherwise nil.
    static func savedFrame(for scene: UIWindowScene) -> CGRect? {
        guard
            let d = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Double],
            let x = d["x"], let y = d["y"],
            let w = d["w"], let h = d["h"],
            w >= minSize.width, h >= minSize.height
        else { return nil }

        let f = CGRect(x: x, y: y, width: w, height: h)
        // Reject frames that are off-screen (e.g. secondary display removed).
        return scene.screen.bounds.intersects(f.insetBy(dx: 80, dy: 80)) ? f : nil
    }

    /// A sensible default: centred on the current screen.
    static func defaultFrame(for scene: UIWindowScene) -> CGRect {
        let s = scene.screen.bounds
        return CGRect(
            x: (s.width  - defaultSize.width)  / 2,
            y: (s.height - defaultSize.height) / 2,
            width: defaultSize.width,
            height: defaultSize.height
        )
    }

    // MARK: - NSWindow autosave (belt-and-suspenders)

    /// Registers the NSWindow autosave name so AppKit also tracks frame
    /// changes automatically.  Uses safe selector checks — never crashes even
    /// if the API changes in a future SDK.
    static func registerNSWindowAutosave(for scene: UIWindowScene) {
        guard let uiWindow = scene.windows.first else { return }
        let getSel = NSSelectorFromString("nsWindow")
        guard uiWindow.responds(to: getSel),
              let ns = uiWindow.perform(getSel)?.takeUnretainedValue() as? NSObject
        else { return }

        let setSel = NSSelectorFromString("setFrameAutosaveName:")
        guard ns.responds(to: setSel) else { return }
        ns.perform(setSel, with: autosaveName)
    }
}
#endif
