import UIKit

extension UIImage {

    /// Returns JPEG data compressed and/or downscaled so the result is ≤ `maxBytes`.
    /// Strategy:
    ///   1. Iterate over decreasing JPEG quality values first (cheap, no re-render).
    ///   2. If quality alone isn't enough, progressively halve the pixel dimensions
    ///      and retry at a moderate quality.
    ///   3. Absolute last resort: minimum quality at current scale.
    func jpegDataFitting(maxBytes: Int = 1_048_576) -> Data? {
        // Phase 1 – quality reduction only
        let qualities: [CGFloat] = [0.85, 0.70, 0.55, 0.40, 0.25, 0.10]
        for q in qualities {
            if let data = jpegData(compressionQuality: q), data.count <= maxBytes {
                return data
            }
        }

        // Phase 2 – downscale dimensions, then apply moderate quality
        var scaleFactor: CGFloat = 0.75
        while scaleFactor >= 0.10 {
            let newSize = CGSize(
                width:  (size.width  * scaleFactor).rounded(),
                height: (size.height * scaleFactor).rounded()
            )
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let scaled = renderer.image { _ in
                draw(in: CGRect(origin: .zero, size: newSize))
            }
            if let data = scaled.jpegData(compressionQuality: 0.55),
               data.count <= maxBytes {
                return data
            }
            scaleFactor -= 0.15
        }

        // Last resort – should rarely be reached
        return jpegData(compressionQuality: 0.05)
    }
}
