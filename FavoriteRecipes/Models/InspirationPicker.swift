/// Picks a random recipe for "Inspire Me", avoiding the one already shown.
enum InspirationPicker {
    static func pick<Element: Equatable>(
        from candidates: [Element],
        avoiding current: Element?,
        using generator: inout some RandomNumberGenerator
    ) -> Element? {
        let others = candidates.filter { $0 != current }
        return others.randomElement(using: &generator) ?? candidates.randomElement(using: &generator)
    }

    static func pick<Element: Equatable>(from candidates: [Element], avoiding current: Element?) -> Element? {
        var generator = SystemRandomNumberGenerator()
        return pick(from: candidates, avoiding: current, using: &generator)
    }
}
