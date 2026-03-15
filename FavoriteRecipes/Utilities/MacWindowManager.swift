#if targetEnvironment(macCatalyst)
import UIKit

/// Manages window geometry on Mac Catalyst.
///
/// Strategy
/// ────────
/// On Mac Catalyst every `UIWindow` is backed by an `NSWindow`.  AppKit's
/// `NSWindow.setFrameAutosaveName(_:)` is the canonical macOS mechanism for
/// frame persistence: it automatically saves the frame to `NSUserDefaults`
/// whenever the window moves or resizes, and automatically restores it the
/// next time the same autosave-name is set.  No manual save/restore code is
/// needed once the name is registered.
///
/// We access `NSWindow` via UIKit's KVC bridge (`value(forKey: "nsWindow")`),
/// which is the standard pattern used by Mac Catalyst apps.  A manual
/// `requestGeometryUpdate` fallback is provided in case the KVC key changes
/// in a future SDK.
///
/// Timing
/// ──────
/// `requestGeometryUpdate` must be deferred: SwiftUI performs its own initial
/// window layout *after* `onAppear` fires, which would silently override an
/// immediate call.  Waiting 0.5 s (one animation frame cycle) is sufficient
/// to outlast SwiftUI's setup pass.  NSWindow autosave is set in the same
/// deferred block so it captures the correct initial frame.
@MainActor
enum MacWindowManager {

    static let minSize     = CGSize(width: 820,  height: 600)
    static let defaultSize = CGSize(width: 1100, height: 780)

    private static let autosaveName  = "FavoriteRecipesMain"
    private static let nsFrameKey    = "NSWindow Frame \(autosaveName)"  // AppKit's UserDefaults key
    private static let manualKey     = "mac.windowFrame"                  // fallback key

    // MARK: - Public API

    /// Call once from `ContentView.onAppear`.
    static func configure() {
        guard let scene = windowScene() else { return }

        // Apply minimum-size constraint immediately (no timing dependency).
        scene.sizeRestrictions?.minimumSize = minSize

        // Defer actual geometry work: SwiftUI's own window setup runs after
        // onAppear, so we must wait for it to finish before we can take over.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let uiWindow = scene.windows.first else { return }

            if let nsWindow = uiWindow.value(forKey: "nsWindow") as? NSObject {
                configureNSWindow(nsWindow, scene: scene)
            } else {
                // Fallback path — no NSWindow KVC access.
                configureManually(scene: scene)
            }
        }
    }

    /// Call from `onChange(of: scenePhase)` on `.inactive` / `.background`.
    /// When the NSWindow path is active this is a no-op (AppKit already saved).
    /// For the manual fallback it writes the frame to UserDefaults.
    static func saveFrame() {
        guard let scene = windowScene(),
              let uiWindow = scene.windows.first
        else { return }

        // If NSWindow autosave is active we do nothing — AppKit handles it.
        if uiWindow.value(forKey: "nsWindow") is NSObject { return }

        // Manual fallback: save UIWindow bounds + origin.
        let f = uiWindow.frame
        guard f.width >= minSize.width, f.height >= minSize.height else { return }
        UserDefaults.standard.set(
            ["x": f.origin.x, "y": f.origin.y, "w": f.width, "h": f.height],
            forKey: manualKey
        )
        UserDefaults.standard.synchronize()
    }

    // MARK: - NSWindow path

    private static func configureNSWindow(_ nsWindow: NSObject, scene: UIWindowScene) {
        let hasAutosave = UserDefaults.standard.string(forKey: nsFrameKey) != nil

        if !hasAutosave {
            // First launch — position the window at a sensible default *before*
            // registering the autosave name, so the default gets persisted too.
            scene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.Mac(systemFrame: defaultFrame(for: scene)),
                errorHandler: nil
            )
            // Wait one more frame so requestGeometryUpdate can apply, then
            // register the autosave name.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                nsWindow.perform(NSSelectorFromString("setFrameAutosaveName:"), with: autosaveName)
            }
        } else {
            // Subsequent launch — register the name first (AppKit restores the
            // saved frame as a side effect), then enforce the minimum size in
            // case the saved frame is smaller than our current minimum.
            nsWindow.perform(NSSelectorFromString("setFrameAutosaveName:"), with: autosaveName)
            enforceMinimumSize(scene: scene)
        }
    }

    // MARK: - Manual fallback path

    private static func configureManually(scene: UIWindowScene) {
        let frame = loadValidFrame(for: scene) ?? defaultFrame(for: scene)
        scene.requestGeometryUpdate(
            UIWindowScene.GeometryPreferences.Mac(systemFrame: frame),
            errorHandler: nil
        )
    }

    private static func loadValidFrame(for scene: UIWindowScene) -> CGRect? {
        guard
            let d = UserDefaults.standard.dictionary(forKey: manualKey) as? [String: Double],
            let x = d["x"], let y = d["y"],
            let w = d["w"], let h = d["h"],
            w >= minSize.width, h >= minSize.height
        else { return nil }
        let frame = CGRect(x: x, y: y, width: w, height: h)
        // Reject frames that are entirely off the current display.
        return scene.screen.bounds.intersects(frame.insetBy(dx: 80, dy: 80)) ? frame : nil
    }

    // MARK: - Helpers

    private static func defaultFrame(for scene: UIWindowScene) -> CGRect {
        let s = scene.screen.bounds
        return CGRect(
            x: (s.width  - defaultSize.width)  / 2,
            y: (s.height - defaultSize.height) / 2,
            width:  defaultSize.width,
            height: defaultSize.height
        )
    }

    private static func enforceMinimumSize(scene: UIWindowScene) {
        guard let window = scene.windows.first else { return }
        let f = window.frame
        if f.width < minSize.width || f.height < minSize.height {
            let fixed = CGRect(
                x: f.origin.x, y: f.origin.y,
                width:  max(f.width,  minSize.width),
                height: max(f.height, minSize.height)
            )
            scene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.Mac(systemFrame: fixed),
                errorHandler: nil
            )
        }
    }

    private static func windowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }
}
#endif
