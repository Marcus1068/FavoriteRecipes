import SwiftUI
import PhotosUI

/// The recipe's main photo: preview, remove, pick from library or camera.
struct RecipePhotoSection: View {
    @Bindable var recipe: Recipe
    @Binding var photoItem: PhotosPickerItem?
    let onTakePhoto: () -> Void

    var body: some View {
        Section {
            if let data = recipe.recipeImageData {
                DownsampledImage(data: data, id: recipe.id.uuidString, maxPointSize: 400)
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(.rect(cornerRadius: 12))
                    .frame(maxWidth: .infinity)
                Button(role: .destructive) {
                    recipe.recipeImageData = nil
                } label: {
                    Label(.removePhoto, systemImage: "xmark.circle")
                }
            }
            PhotoSourceButtons(photoItem: $photoItem, onTakePhoto: onTakePhoto)
        } header: {
            Label(.recipePhoto, systemImage: "camera.fill")
        }
    }
}
