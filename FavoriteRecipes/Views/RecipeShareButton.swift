import SwiftUI

/// Shares a recipe as text or as a recipe file, with its photo as the share sheet preview.
struct RecipeShareButton: View {
    let recipe: Recipe

    /// Small cached thumbnail; the share sheet preview never needs the full photo.
    private var previewImage: UIImage? {
        guard let data = recipe.recipeImageData else { return nil }
        let key = "share-\(recipe.id.uuidString)-\(data.count)"
        if let cached = RecipeImageCache.shared.image(forKey: key) { return cached }
        guard let image = ImageDownsampler.downsample(data, maxPixelSize: 240) else { return nil }
        RecipeImageCache.shared.insert(image, forKey: key)
        return image
    }

    var body: some View {
        let preview = SharePreview(
            recipe.displayName,
            image: previewImage.map(Image.init(uiImage:)) ?? Image(systemName: "fork.knife")
        )
        Menu {
            ShareLink(item: recipe.shareText, subject: Text(recipe.displayName), preview: preview) {
                Label(.shareAsText, systemImage: "text.alignleft")
            }
            ShareLink(item: RecipeFileExport(file: RecipeFile(recipe)), preview: preview) {
                Label(.shareAsRecipeFile, systemImage: "doc.badge.arrow.up")
            }
            .accessibilityIdentifier("shareRecipeFile")
        } label: {
            RecipeShareLabel()
        }
        .accessibilityLabel(Text(.share))
        .accessibilityIdentifier("card.share")
    }
}
