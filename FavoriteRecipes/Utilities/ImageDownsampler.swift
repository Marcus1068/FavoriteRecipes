import ImageIO
import UIKit

/// Decodes images at the size they are displayed instead of full resolution.
///
/// A 12-megapixel photo decoded with `UIImage(data:)` takes ~48 MB of memory;
/// a 600-pixel thumbnail of it takes ~1.4 MB and decodes far faster.
nonisolated enum ImageDownsampler {

    /// Returns an image whose longest side is at most `maxPixelSize` pixels.
    static func downsample(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize)
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: image)
    }

    /// Same as `downsample`, off the main actor.
    @concurrent
    static func downsampled(_ data: Data, maxPixelSize: CGFloat) async -> UIImage? {
        downsample(data, maxPixelSize: maxPixelSize)
    }
}
