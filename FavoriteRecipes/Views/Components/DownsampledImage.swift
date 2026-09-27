import SwiftUI

/// Shows image data decoded at display size, off the main thread and cached.
/// Resizable; apply `scaledToFill()` / `scaledToFit()` and a frame as needed.
struct DownsampledImage: View {
    let data: Data
    /// Identifies the image, e.g. the recipe id; combined with size in the cache key.
    let id: String
    /// The largest side the image is displayed at, in points.
    let maxPointSize: CGFloat

    @Environment(\.displayScale) private var displayScale
    @State private var loaded: UIImage?

    private var maxPixelSize: CGFloat { (maxPointSize * displayScale).rounded(.up) }

    /// Byte count changes when the photo is replaced, which invalidates the entry.
    private var cacheKey: String { "\(id)-\(data.count)-\(Int(maxPixelSize))" }

    var body: some View {
        let image = loaded ?? RecipeImageCache.shared.image(forKey: cacheKey)
        Group {
            if let image {
                Image(uiImage: image).resizable()
            } else {
                Color.clear
            }
        }
        .task(id: cacheKey) {
            if let cached = RecipeImageCache.shared.image(forKey: cacheKey) {
                loaded = cached
                return
            }
            guard let decoded = await ImageDownsampler.downsampled(data, maxPixelSize: maxPixelSize) else { return }
            RecipeImageCache.shared.insert(decoded, forKey: cacheKey)
            loaded = decoded
        }
    }
}
