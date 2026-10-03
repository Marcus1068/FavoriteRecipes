/// Index arithmetic for moving through the recipe carousel.
enum CarouselPaging {
    /// The index after moving by `delta`, or nil if that would leave `0..<count`.
    static func index(from current: Int, moving delta: Int, count: Int) -> Int? {
        let target = current + delta
        return (0..<count).contains(target) ? target : nil
    }
}
