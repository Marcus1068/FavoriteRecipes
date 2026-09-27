import Foundation
import Testing
@testable import FavoriteRecipes

struct AppNavigationTests {
    @Test func showingARecipeSwitchesTabAndIsConsumedOnce() {
        let navigation = AppNavigation()
        navigation.selectedTab = .about
        let id = UUID()

        navigation.showRecipe(id: id)

        #expect(navigation.selectedTab == .recipes)
        #expect(navigation.consumePendingRecipe() == id)
        #expect(navigation.consumePendingRecipe() == nil)
    }
}
