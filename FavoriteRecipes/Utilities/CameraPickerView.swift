import SwiftUI
import PhotosUI
import UIKit

// MARK: - Public entry point (all platforms)

/// Camera capture view.
///
/// On iPhone/iPad the native camera is used via `UIImagePickerController`.
/// On Mac Catalyst the camera is unavailable, so `CameraPickerView` is never
/// presented — `RecipeDetailView` already guards the "Take Photo" button with
/// `#if !targetEnvironment(macCatalyst)`.  This file compiles cleanly on all
/// platforms by wrapping the UIImagePickerController code in a conditional.
#if !targetEnvironment(macCatalyst)

struct CameraPickerView: View {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        _CameraController(onCapture: onCapture, dismiss: dismiss)
            .ignoresSafeArea()
    }
}

private struct _CameraController: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    let dismiss: DismissAction

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
        let onCapture: (Data) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (Data) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            if let image, let data = image.jpegDataFitting() {
                onCapture(data)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

#endif // !targetEnvironment(macCatalyst)
