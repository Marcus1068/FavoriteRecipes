import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(UndoDeleteModel.self) private var undoDelete
    @Environment(TimerCenter.self) private var timerCenter
    @Environment(ShoppingStore.self) private var shoppingStore
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedTab) {
            Tab(.recipes, systemImage: "fork.knife", value: AppTab.recipes) {
                RecipesView()
            }
            Tab(.shopping, systemImage: "cart", value: AppTab.shopping) {
                ShoppingListView()
            }
            Tab(.options, systemImage: "gear", value: AppTab.options) {
                OptionsView()
            }
            Tab(.about, systemImage: "info.circle", value: AppTab.about) {
                AboutView()
            }
        }
        .overlay { UndoDeleteBanner(model: undoDelete) }
        .overlay { ShoppingAddedBanner(store: shoppingStore) }
        .sheet(isPresented: $navigation.isShowingOnboarding, onDismiss: { hasSeenOnboarding = true }) {
            OnboardingView()
        }
        .task {
            showOnboardingIfNeeded()
            timerCenter.cleanUpLeftoverActivities()
        }
        .onOpenURL { url in
            if let address = ImportLink.recipeAddress(in: url) {
                navigation.request(.importRecipe(address: address))
            } else if url.isFileURL, url.pathExtension.lowercased() == "favoriterecipe" {
                navigation.request(.openRecipeFile(url))
            }
        }
    }

    /// New users see the introduction once. People who already have recipes
    /// (an update, or recipes synced from iCloud) are not interrupted.
    private func showOnboardingIfNeeded() {
        guard !hasSeenOnboarding else { return }
        let recipeCount = (try? modelContext.fetchCount(FetchDescriptor<Recipe>())) ?? 0
        if recipeCount == 0 {
            navigation.isShowingOnboarding = true
        } else {
            hasSeenOnboarding = true
        }
    }
}
