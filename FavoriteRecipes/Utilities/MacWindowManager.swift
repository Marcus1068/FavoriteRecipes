#if targetEnvironment(macCatalyst)
import UIKit

/// Manages window geometry (minimum size, default size, persistence) on Mac Catalyst.
///
/// NSWindow access
/// ───────────────
/// Every UIWindow on Mac Catalyst is backed by an NSWindow.  We access it
/// through a *selector* check rather than `value(forKey:)`.
/// `value(forKey: "nsWindow")` raises a fatal `NSUndefinedKeyException` if the
/// KVC key is absent (e.g., in a future SDK), and Swift **cannot** catch
/// Objective-C exceptions with try/catch.  `responds(to:)` + `perform(_:)` is
/// always safe: `responds(to:)` never throws and `perform(_:)` is only called
/// when the selector is confirmed to exist.
///
/// Timing
/// ──────
/// `requestGeometryUpdate` must be deferred: SwiftUI performs its own initial
/// window layout *after* `onAppear`, which would silently override an immediate
/// call.  1 second is used to safely outlast SwiftUI's setup pass.
@MainActor
enum MacWindowManager {

    static let minSize     = CGSize(width: 820,  height: 600)
    static let defaultSize = CGSize(width: 1100, height: 780)

    private static let autosaveName = "FavoriteRecipesMain"
    private static let nsFrameKey  = "NSWindow Frame \(autosaveName)"
    private static let manualKey   = "mac.windowFrame"

    // MARK: - Public API

    /// Call once from `ContentView.onAppear`.
    static func configure() {
        guard let scene = windowScene() else { return }
        scene.sizeRestrictions?.minimumSize = minSize

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let uiWindow = scene.windows.first else { return }

            if let ns = safeNSWindow(from: uiWindow) {
                setupNSWindowAutosave(ns, scene: scene)
            } else {
                configureManually(scene: scene)
            }
        }
    }

    /// Call from `onChange(of: scenePhase)` on `.inactive` / `.background`.
    static func saveFrame() {
        guard let scene  = windowScene(),
              let window = scene.windows.first else { return }

        // If NSWindow autosave is active it already saved — no-op.
        if safeNSWindow(from: window) != nil { return }

        // Manual fallback.
        let f = window.frame
        guard f.width >= minSize.width, f.height >= minSize.height else { return }
        UserDefaults.standard.set(
            ["x": f.origin.x, "y": f.origin.y, "w": f.width, "h": f.height],
            forKey: manualKey
        )
        UserDefaults.standard.synchronize()
    }

    // MARK: - Safe NSWindow access

    /// Returns the backing NSWindow using a selector-existence check.
    /// Never crashes: if the selector doesn't exist in this SDK, returns nil.
    private static func safeNSWindow(from uiWindow: UIWindow) -> NSObject? {
        let sel = NSSelectorFromString("nsWindow")
        guard uiWindow.responds(to: sel) else { return nil }
        return uiWindow.perform(sel)?.takeUnretainedValue() as? NSObject
    }

    // MARK: - NSWindow autosave path

    private static func setupNSWindowAutosave(_ ns: NSObject, scene: UIWindowScene) {
        let hasSaved = UserDefaults.standard.string(forKey: nsFrameKey) != nil

        if !hasSaved {
            // First launch: position at a good default first, then register
            // the autosave name so the default gets persisted going forward.
            scene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.Mac(systemFrame: defaultFrame(for: scene)),
                errorHandler: nil
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let regSel = NSSelectorFromString("setFrameAutosaveName:")
                if ns.responds(to: regSel) {
                    ns.perform(regSel, with: autosaveName)
                }
            }
        } else {
            // Subsequent launch: registering the autosave name makes AppKit
            // restore the saved frame as a side-effect.
            let regSel = NSSelectorFromString("setFrameAutosaveName:")
            if ns.responds(to: regSel) {
                ns.perform(regSel, with: autosaveName)
            }
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
        let f = CGRect(x: x, y: y, width: w, height: h)
        return scene.screen.bounds.intersects(f.insetBy(dx: 80, dy: 80)) ? f : nil
    }

    // MARK: - Helpers

    private static func defaultFrame(for scene: UIWindowScene) -> CGRect {
        let s = scene.screen.bounds
        return CGRect(
            x: (s.width  - defaultSize.width)  / 2,
            y: (s.height - defaultSize.height) / 2,
            width: defaultSize.width, height: defaultSize.height
        )
    }

    private static func enforceMinimumSize(scene: UIWindowScene) {
        guard let w = scene.windows.first else { return }
        let f = w.frame
        guard f.width < minSize.width || f.height < minSize.height else { return }
        scene.requestGeometryUpdate(
            UIWindowScene.GeometryPreferences.Mac(systemFrame: CGRect(
                x: f.origin.x, y: f.origin.y,
                width: max(f.width, minSize.width), height: max(f.height, minSize.height)
            )),
            errorHandler: nil
        )
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
