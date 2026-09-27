import UIKit

/// In-memory cache of downsampled recipe images. The system evicts entries
/// under memory pressure, so it never grows unbounded.
final class RecipeImageCache {
    static let shared = RecipeImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
