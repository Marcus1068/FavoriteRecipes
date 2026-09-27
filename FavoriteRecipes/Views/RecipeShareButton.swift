import SwiftUI

/// Shares a recipe as text, with its photo as the share sheet preview.
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
        if let uiImage = previewImage {
            let image = Image(uiImage: uiImage)
            ShareLink(
                item: recipe.shareText,
                subject: Text(recipe.displayName),
                preview: SharePreview(recipe.displayName, image: image)
            ) {
                RecipeShareLabel()
            }
        } else {
            ShareLink(
                item: recipe.shareText,
                subject: Text(recipe.displayName),
                preview: SharePreview(recipe.displayName)
            ) {
                RecipeShareLabel()
            }
        }
    }
}
