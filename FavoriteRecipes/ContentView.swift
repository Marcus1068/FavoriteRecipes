import SwiftUI

struct ContentView: View {
    @Environment(AppNavigation.self) private var navigation

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
    }
}
