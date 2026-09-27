import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecipesView()
                .tabItem {
                    Label(.recipes, systemImage: "fork.knife")
                }

            OptionsView()
                .tabItem {
                    Label(.options, systemImage: "gear")
                }

            AboutView()
                .tabItem {
                    Label(.about, systemImage: "info.circle")
                }
        }
    }
}
