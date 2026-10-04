import Foundation
import Observation

/// App-wide navigation state, shared by the UI and App Intents
/// (Siri, Shortcuts, Spotlight) so they can bring a recipe on screen.
@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .recipes

    /// Whether the introduction sheet is showing.
    var isShowingOnboarding = false

    /// A recipe that should be shown as soon as the recipes screen can handle it.
    private(set) var pendingRecipeID: UUID?

    /// How many editors, cooking screens and similar screens are open right now.
    /// The recipes screen waits for this to reach zero before it presents something new,
    /// because a screen cannot present a second sheet over an open one.
    private(set) var presentedCount = 0

    var canPresent: Bool { presentedCount == 0 }

    func presentationStarted() {
        presentedCount += 1
    }

    func presentationEnded() {
        presentedCount = max(0, presentedCount - 1)
    }

    /// An action for the recipes screen, e.g. from a menu command or an import link.
    private(set) var requestedAction: AppAction?

    /// Asks the recipes screen to perform an action, switching to it first.
    func request(_ action: AppAction) {
        selectedTab = .recipes
        requestedAction = action
    }

    /// Returns the requested action once and clears it.
    func consumeRequestedAction() -> AppAction? {
        defer { requestedAction = nil }
        return requestedAction
    }

    /// Switches to the recipes tab and asks it to show the recipe.
    func showRecipe(id: UUID) {
        selectedTab = .recipes
        pendingRecipeID = id
    }

    /// Returns the pending request once and clears it.
    func consumePendingRecipe() -> UUID? {
        defer { pendingRecipeID = nil }
        return pendingRecipeID
    }
}
