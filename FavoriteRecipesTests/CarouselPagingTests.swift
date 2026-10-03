import Testing
@testable import FavoriteRecipes

struct CarouselPagingTests {
    @Test func movesWithinBounds() {
        #expect(CarouselPaging.index(from: 1, moving: 1, count: 3) == 2)
        #expect(CarouselPaging.index(from: 1, moving: -1, count: 3) == 0)
    }

    @Test func stopsAtEitherEnd() {
        #expect(CarouselPaging.index(from: 0, moving: -1, count: 3) == nil)
        #expect(CarouselPaging.index(from: 2, moving: 1, count: 3) == nil)
    }

    @Test func emptyCarouselHasNoTarget() {
        #expect(CarouselPaging.index(from: 0, moving: 1, count: 0) == nil)
    }
}
