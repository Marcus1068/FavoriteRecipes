import UIKit

/// Presents a system share sheet on all platforms (iOS, iPadOS, Mac Catalyst)
/// without relying on SwiftUI's `.sheet()` — which fails for
/// `UIActivityViewController` on Mac Catalyst because the popover has no
/// real anchor view in the window hierarchy.
///
/// Call after any async work (OCR, PDF extraction) is done on the main actor.
@MainActor
func presentShareSheet(items: [Any]) {
    guard
        let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
        let window = scene.keyWindow
    else { return }

    let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)

    // iPad / Mac Catalyst: anchor the popover to the window centre.
    // On iPhone this is ignored and a standard action sheet appears.
    activityController.popoverPresentationController?.sourceView = window
    activityController.popoverPresentationController?.sourceRect = CGRect(
        x: window.bounds.midX, y: window.bounds.midY, width: 1, height: 1
    )
    activityController.popoverPresentationController?.permittedArrowDirections = []

    // Walk to the topmost presented view controller so we don't try to
    // present over an already-presenting controller.
    var presenter: UIViewController? = window.rootViewController
    while let next = presenter?.presentedViewController { presenter = next }
    presenter?.present(activityController, animated: true)
}
