import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]

    @State private var selectedCategory: RecipeCategory?
    @State private var currentIndex: Int = 0
    @State private var newRecipe: Recipe?

    // MARK: - Filtered lists

    var favoriteRecipes: [Recipe] {
        let favs = allRecipes.filter { $0.isFavorite }
        guard let cat = selectedCategory else { return favs }
        return favs.filter { $0.category == cat }
    }

    var regularRecipes: [Recipe] {
        let nonFav = allRecipes.filter { !$0.isFavorite }
        guard let cat = selectedCategory else { return nonFav }
        return nonFav.filter { $0.category == cat }
    }

    var backgroundImage: UIImage? {
        guard let recipe = regularRecipes[safe: currentIndex],
              let data = recipe.recipeImageData else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            // ── Layout root is VStack + .background, NOT ZStack ──────────────
            // Using ZStack as the root caused SwiftUI to propose the full
            // window height to all children; the carousel's maxHeight:.infinity
            // then absorbed more space than intended on iPad/Mac, pushing the
            // Inspire Me button and page dots out of the visible area.
            // .background{} keeps the dynamic image purely decorative —
            // it does not participate in layout — and the VStack receives the
            // exact safe-area–bounded content height from NavigationStack.
            VStack(spacing: 0) {
                // Category filter — fixed height ~50 pt
                CategoryFilterView(selected: $selectedCategory)
                    .padding(.vertical, 10)
                    .onChange(of: selectedCategory) { _, _ in
                        withAnimation(.spring()) { currentIndex = 0 }
                    }

                if regularRecipes.isEmpty {
                    Spacer()
                    EmptyCarouselView(onAdd: addNewRecipe)
                    Spacer()
                } else {
                    // Favorites strip — fixed ~150 pt, horizontal scroll inside
                    if !favoriteRecipes.isEmpty {
                        FavoritesSection(recipes: favoriteRecipes)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // ── Carousel ─────────────────────────────────────────────
                    CarouselView(recipes: regularRecipes, currentIndex: $currentIndex)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(minHeight: 220)
                        // Arrow-key navigation via UIKit pressesBegan.
                        // See KeyboardNavigationHandler.swift for the rationale
                        // behind this approach vs onKeyPress / keyboardShortcut.
                        .overlay(
                            KeyboardNavigationHandler(
                                onLeft: {
                                    guard currentIndex > 0 else { return }
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                        currentIndex -= 1
                                    }
                                },
                                onRight: {
                                    guard currentIndex < regularRecipes.count - 1 else { return }
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                        currentIndex += 1
                                    }
                                }
                            )
                            .accessibilityHidden(true)
                        )
                    // ─────────────────────────────────────────────────────────

                    // Page dots — always below the carousel
                    PageIndicatorView(count: regularRecipes.count, current: currentIndex)
                        .padding(.vertical, 6)

                    // Inspire Me — always visible at the bottom
                    InspireMeButton(recipes: regularRecipes, currentIndex: $currentIndex)
                        .padding(.bottom, 20)
                }
            }
            .background { dynamicBackground }
            .navigationTitle(.myRecipes)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(.addRecipe, systemImage: "plus.circle.fill", action: addNewRecipe)
                        .font(.title3)
                }
            }
            .sheet(item: $newRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .onChange(of: regularRecipes.count) { _, count in
                if currentIndex >= count {
                    withAnimation { currentIndex = max(0, count - 1) }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: favoriteRecipes.isEmpty)
        }
    }

    // MARK: - Dynamic Background

    @ViewBuilder
    private var dynamicBackground: some View {
        if let img = backgroundImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .blur(radius: 60)
                .opacity(0.22)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.55), value: currentIndex)
                .id(currentIndex)
        } else {
            Color(.systemBackground).ignoresSafeArea()
        }
    }

    // MARK: - Helpers

    private func addNewRecipe() {
        let recipe = Recipe()
        modelContext.insert(recipe)
        newRecipe = recipe
    }
}

// MARK: - Category Filter

struct CategoryFilterView: View {
    @Binding var selected: RecipeCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: .all, icon: "🍽️", color: .accentColor, isSelected: selected == nil) {
                    withAnimation(.spring(response: 0.3)) { selected = nil }
                }
                ForEach(RecipeCategory.allCases) { cat in
                    FilterChip(title: cat.localizedName, icon: cat.icon, color: cat.color, isSelected: selected == cat) {
                        withAnimation(.spring(response: 0.3)) {
                            selected = (selected == cat) ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct FilterChip: View {
    let title: LocalizedStringResource
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(icon).font(.subheadline)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Page Indicators

struct PageIndicatorView: View {
    let count: Int
    let current: Int

    var body: some View {
        Group {
            if count > 11 {
                Text(.pageIndicator(current + 1, count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i == current ? Color.accentColor : Color.secondary.opacity(0.38))
                            .frame(width: i == current ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Inspire Me Button

struct InspireMeButton: View {
    let recipes: [Recipe]
    @Binding var currentIndex: Int
    @State private var isSpinning = false

    var body: some View {
        Button {
            guard recipes.count > 1 else { return }
            isSpinning = true
            var newIdx: Int
            repeat { newIdx = Int.random(in: 0..<recipes.count) } while newIdx == currentIndex
            withAnimation(.spring(response: 0.50, dampingFraction: 0.62)) {
                currentIndex = newIdx
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { isSpinning = false }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.headline)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(isSpinning ? .linear(duration: 0.65) : .default, value: isSpinning)
                Text(.inspireMe)
                    .font(.headline)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 13)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.50, green: 0.20, blue: 0.90),
                        Color(red: 0.90, green: 0.28, blue: 0.52),
                        Color(red: 1.00, green: 0.60, blue: 0.20)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: Color(red: 0.50, green: 0.20, blue: 0.90).opacity(0.45), radius: 14, y: 7)
        }
        .scaleEffect(isSpinning ? 0.94 : 1.0)
        .animation(.spring(response: 0.2), value: isSpinning)
        .disabled(recipes.count <= 1)
    }
}

// MARK: - Empty State

struct EmptyCarouselView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 76))
                .foregroundStyle(.secondary.opacity(0.45))

            Text(.noRecipesYet)
                .font(.title2.bold())

            Text(.noRecipesYetMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onAdd) {
                Label(.addRecipe, systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
                    .font(.headline)
            }
        }
        .padding(40)
    }
}

// MARK: - Array safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
