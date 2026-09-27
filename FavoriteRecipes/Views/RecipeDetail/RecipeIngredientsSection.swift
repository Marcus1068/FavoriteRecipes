import SwiftUI
import PhotosUI

/// Ingredients as photo, PDF or text, with a banner while text is being extracted.
struct RecipeIngredientsSection: View {
    @Bindable var recipe: Recipe
    /// Progress text while text is being read or organized; nil when idle.
    let extractionMessage: LocalizedStringResource?
    /// Shown when no text could be read from the photo or PDF.
    let extractionError: LocalizedStringResource?
    @Binding var photoItem: PhotosPickerItem?
    let onTakePhoto: () -> Void
    let onChoosePDF: () -> Void

    var body: some View {
        Section {
            Picker(.ingredientsType, selection: $recipe.ingredientsType) {
                ForEach(IngredientsType.allCases, id: \.self) { type in
                    Label(type.localizedName, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if let extractionMessage {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(extractionMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else if let extractionError {
                Label(extractionError, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            switch recipe.ingredientsType {
            case .photo:
                IngredientsPhotoContent(recipe: recipe, photoItem: $photoItem, onTakePhoto: onTakePhoto)
            case .pdf:
                IngredientsPDFContent(recipe: recipe, onChoosePDF: onChoosePDF)
            case .text:
                PlaceholderTextEditor(
                    placeholder: .ingredientsPlaceholder,
                    text: $recipe.ingredientsText,
                    minHeight: 150
                )
            }
        } header: {
            Label(.ingredients, systemImage: "list.bullet")
        }
    }
}
