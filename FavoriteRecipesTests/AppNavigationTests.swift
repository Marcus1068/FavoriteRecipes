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

@MainActor
struct PresentationCountTests {
    @Test func startsWithNothingPresented() {
        #expect(AppNavigation().canPresent)
    }

    @Test func tracksNestedPresentations() {
        let navigation = AppNavigation()
        navigation.presentationStarted()
        navigation.presentationStarted()
        #expect(!navigation.canPresent)
        navigation.presentationEnded()
        #expect(!navigation.canPresent)
        navigation.presentationEnded()
        #expect(navigation.canPresent)
    }

    @Test func extraEndsNeverGoNegative() {
        let navigation = AppNavigation()
        navigation.presentationEnded()
        navigation.presentationStarted()
        #expect(!navigation.canPresent)
        #expect(navigation.presentedCount == 1)
    }

    @Test func aRequestStaysPendingUntilConsumed() {
        let navigation = AppNavigation()
        navigation.presentationStarted()
        navigation.request(.newRecipe)
        #expect(navigation.requestedAction == .newRecipe)
        #expect(!navigation.canPresent)
        navigation.presentationEnded()
        #expect(navigation.consumeRequestedAction() == .newRecipe)
    }
}
