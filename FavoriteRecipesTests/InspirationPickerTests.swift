import Testing
@testable import FavoriteRecipes

struct InspirationPickerTests {
    @Test func neverPicksTheCurrentItemWhenThereIsAnAlternative() {
        var generator = SeededGenerator(seed: 42)
        for _ in 0..<200 {
            let pick = InspirationPicker.pick(from: [1, 2, 3], avoiding: 2, using: &generator)
            #expect(pick != 2)
            #expect(pick != nil)
        }
    }

    @Test func returnsTheOnlyItemEvenIfItIsCurrent() {
        #expect(InspirationPicker.pick(from: [7], avoiding: 7) == 7)
    }

    @Test func returnsNilForNoCandidates() {
        #expect(InspirationPicker.pick(from: [Int](), avoiding: nil) == nil)
    }

    @Test func eventuallyPicksEveryAlternative() {
        var generator = SeededGenerator(seed: 1)
        var seen = Set<Int>()
        for _ in 0..<100 {
            if let pick = InspirationPicker.pick(from: [1, 2, 3, 4], avoiding: 1, using: &generator) {
                seen.insert(pick)
            }
        }
        #expect(seen == [2, 3, 4])
    }
}
