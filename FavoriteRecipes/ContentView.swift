import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedTab) {
            Tab(.recipes, systemImage: "fork.knife", value: AppTab.recipes) {
                RecipesView()
            }
            Tab(.options, systemImage: "gear", value: AppTab.options) {
                OptionsView()
            }
            Tab(.about, systemImage: "info.circle", value: AppTab.about) {
                AboutView()
            }
        }
        .sheet(isPresented: $navigation.isShowingOnboarding, onDismiss: { hasSeenOnboarding = true }) {
            OnboardingView()
        }
        .task { showOnboardingIfNeeded() }
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
