import SwiftUI

extension Animation {
    /// Animation for moving between carousel cards: a spring normally,
    /// a short fade-friendly ease when the user has Reduce Motion turned on.
    static func carouselPaging(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.82)
    }
}
