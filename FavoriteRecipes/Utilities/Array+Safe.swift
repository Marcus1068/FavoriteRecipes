extension Array {
    /// The element at `index`, or nil when it is out of bounds.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
