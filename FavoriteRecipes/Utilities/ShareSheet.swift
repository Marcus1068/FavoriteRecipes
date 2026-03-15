import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
#if targetEnvironment(macCatalyst)
        // On Mac Catalyst the activity controller is presented as a popover.
        // Use the coordinator's container view as the anchor; it's placed
        // once the parent view appears.
        vc.popoverPresentationController?.sourceView = context.coordinator.containerView
        vc.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        vc.popoverPresentationController?.permittedArrowDirections = []
#endif
        return vc
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    final class Coordinator {
        let containerView = UIView()
    }
}
