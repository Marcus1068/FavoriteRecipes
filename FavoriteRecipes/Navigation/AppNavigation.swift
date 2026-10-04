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
