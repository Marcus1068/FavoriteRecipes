import SwiftUI
import PhotosUI

/// "Choose from Library" and, where a camera exists, "Take Photo".
struct PhotoSourceButtons: View {
    @Binding var photoItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    var body: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Label(.chooseFromLibrary, systemImage: "photo.on.rectangle")
        }
        #if !targetEnvironment(macCatalyst)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button(.takePhoto, systemImage: "camera", action: onTakePhoto)
        }
        #endif
    }
}
