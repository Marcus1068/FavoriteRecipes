#if targetEnvironment(macCatalyst)
import UIKit

@MainActor
enum MacWindowManager {

    static let minSize     = CGSize(width: 820,  height: 600)
    static let defaultSize = CGSize(width: 1100, height: 780)

    private static let userDefaultsKey = "mac.windowFrame"
    private static let autosaveName    = "FavoriteRecipesMain"

    // MARK: - Frame persistence

    /// Saves the current window frame.  Reads from `effectiveGeometry`,
    /// which is in the same coordinate space as the `systemFrame` we pass
    /// to `requestGeometryUpdate`.
    static func saveFrame(for scene: UIWindowScene) {
        let frame = scene.effectiveGeometry.systemFrame

        guard frame.width >= minSize.width, frame.height >= minSize.height else { return }

        UserDefaults.standard.set(
            ["x": frame.origin.x, "y": frame.origin.y, "w": frame.width, "h": frame.height],
            forKey: userDefaultsKey
        )
        UserDefaults.standard.synchronize()
    }

    /// Returns the saved frame if it is valid and on-screen, otherwise nil.
    static func savedFrame(for scene: UIWindowScene) -> CGRect? {
        guard
            let saved = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Double],
            let x = saved["x"], let y = saved["y"],
            let w = saved["w"], let h = saved["h"],
            w >= minSize.width, h >= minSize.height
        else { return nil }

        let frame = CGRect(x: x, y: y, width: w, height: h)
        // Reject frames that are off-screen (e.g. secondary display removed).
        return scene.screen.bounds.intersects(frame.insetBy(dx: 80, dy: 80)) ? frame : nil
    }

    /// A sensible default: centred on the current screen.
    static func defaultFrame(for scene: UIWindowScene) -> CGRect {
        let screenBounds = scene.screen.bounds
        return CGRect(
            x: (screenBounds.width  - defaultSize.width)  / 2,
            y: (screenBounds.height - defaultSize.height) / 2,
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
              let nsWindow = uiWindow.perform(getSel)?.takeUnretainedValue() as? NSObject
        else { return }

        let setSel = NSSelectorFromString("setFrameAutosaveName:")
        guard nsWindow.responds(to: setSel) else { return }
        nsWindow.perform(setSel, with: autosaveName)
    }
}
#endif
