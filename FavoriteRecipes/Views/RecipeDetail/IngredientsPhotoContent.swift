import SwiftUI
import PhotosUI

/// Photo of an ingredient list, with remove / replace controls.
struct IngredientsPhotoContent: View {
    @Bindable var recipe: Recipe
    @Binding var photoItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    var body: some View {
        if let data = recipe.ingredientsImageData {
            // Larger than the frame so the list stays legible when zoomed with the system magnifier.
            DownsampledImage(data: data, id: "ingredients-\(recipe.id.uuidString)", maxPointSize: 800)
                .scaledToFit()
                .frame(maxHeight: 180)
                .clipShape(.rect(cornerRadius: 10))
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Text(.ingredientsPhotoLabel))
            Button(role: .destructive) {
                recipe.ingredientsImageData = nil
            } label: {
                Label(.removePhoto, systemImage: "xmark.circle")
            }
        }
        PhotoSourceButtons(photoItem: $photoItem, onTakePhoto: onTakePhoto)
    }
}
