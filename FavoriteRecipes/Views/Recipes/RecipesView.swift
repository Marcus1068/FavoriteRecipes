import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigation.self) private var navigation
    @AppStorage("inspireMeIncludesFavorites") private var inspireIncludesFavorites = false
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]

    @State private var filter = RecipeFilter(sort: RecipesView.storedSort)
    /// Address to fill into the import sheet, e.g. from an import link.
    @State private var importAddress: String?
    @FocusState private var isSearchFocused: Bool
    @State private var currentIndex: Int = 0
    @State private var newRecipe: Recipe?
    /// A recipe opened from Spotlight, Siri or Inspire Me that isn't in the carousel.
    @State private var openedRecipe: Recipe?
    @State private var showImport = false
    /// Draft from the web import, shown once the import sheet has closed.
    @State private var importedDraft: Recipe?

    /// The sort order chosen last time, so it survives relaunches.
    private static var storedSort: RecipeSort {
        RecipeSort(rawValue: UserDefaults.standard.string(forKey: "recipeSort") ?? "") ?? .newest
    }

    // MARK: - Filtered lists

    var favoriteRecipes: [Recipe] { filter.favorites(in: allRecipes) }

    var regularRecipes: [Recipe] { filter.regular(in: allRecipes) }

    /// Recipes Inspire Me may pick from; favorites only if enabled in Options.
    var inspirationCandidates: [Recipe] {
        inspireIncludesFavorites ? regularRecipes + favoriteRecipes : regularRecipes
    }

    // MARK: - Body

    var body: some View {
        // Filter once per body pass instead of on every access.
        let favorites = favoriteRecipes
        let regular = regularRecipes

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
                CategoryFilterView(selected: $filter.category)
                    .padding(.vertical, 10)

                if favorites.isEmpty && regular.isEmpty {
                    Spacer()
                    if allRecipes.isEmpty {
                        EmptyCarouselView(onAdd: addNewRecipe)
                    } else if filter.isSearching {
                        ContentUnavailableView.search(text: filter.searchText)
                    } else if filter.hasExtraFilters {
                        ContentUnavailableView {
                            Label(.noMatchingRecipes, systemImage: "line.3.horizontal.decrease.circle")
                        } description: {
                            Text(.noMatchingRecipesMessage)
                        } actions: {
                            Button(.resetFilters) {
                                filter.minimumRating = 0
                                filter.tag = nil
                            }
                        }
                    } else {
                        // Recipes exist, just none in the selected category.
                        ContentUnavailableView {
                            Label(.noRecipesInCategory, systemImage: "line.3.horizontal.decrease.circle")
                        } description: {
                            Text(.noRecipesInCategoryMessage)
                        }
                    }
                    Spacer()
                } else {
                    ActiveTimersList()
                        .padding(.bottom, 8)

                    if dynamicTypeSize.isAccessibilitySize {
                        // Fixed-size cards cannot hold accessibility text sizes; use a list.
                        RecipeListView(
                            recipes: favorites + regular,
                            inspirationCandidates: inspirationCandidates,
                            onPick: show
                        )
                    } else {
                        // Favorites strip — fixed ~150 pt, horizontal scroll inside
                        if !favorites.isEmpty {
                            FavoritesSection(recipes: favorites)
                                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        }

                        if regular.isEmpty {
                            // Every recipe in view is a favorite, so the carousel is empty.
                            ContentUnavailableView {
                                Label(.allRecipesAreFavorites, systemImage: "heart")
                            } description: {
                                Text(.allRecipesAreFavoritesMessage)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            RecipeCarouselSection(
                                recipes: regular,
                                inspirationCandidates: inspirationCandidates,
                                currentIndex: $currentIndex,
                                isKeyboardEnabled: !isSearchFocused,
                                onPick: show
                            )
                        }
                    }
                }
            }
            .background {
                RecipesBackground(recipe: regular[safe: currentIndex])
                    .animation(.easeInOut(duration: 0.55), value: currentIndex)
            }
            .searchable(text: $filter.searchText, prompt: Text(.searchPrompt))
            .searchFocused($isSearchFocused)
            .onChange(of: filter.sort) { UserDefaults.standard.set(filter.sort.rawValue, forKey: "recipeSort") }
            .onChange(of: filter) {
                withAnimation(.carouselPaging(reduceMotion: reduceMotion)) { currentIndex = 0 }
            }
            .navigationTitle(.myRecipes)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SortFilterMenu(filter: $filter, availableTags: TagList.all(in: allRecipes))
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(.newRecipeMenu, systemImage: "square.and.pencil", action: addNewRecipe)
                        Button(.importFromWeb, systemImage: "globe") {
                            importAddress = nil
                            showImport = true
                        }
                    } label: {
                        Label(.addRecipe, systemImage: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(item: $newRecipe) { recipe in
                RecipeDetailView(recipe: recipe, isNew: true)
            }
            .sheet(isPresented: $showImport, onDismiss: showImportedDraft) {
                ImportRecipeView(initialAddress: importAddress) { importedDraft = $0 }
            }
            .sheet(item: $openedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            // Requests from Siri, Shortcuts and Spotlight.
            .onChange(of: navigation.pendingRecipeID) { showPendingRecipe() }
            .onChange(of: navigation.requestedAction) { performRequestedAction() }
            .onChange(of: navigation.presentedCount) {
                // Something was closed: pick up a request that was waiting for it.
                showPendingRecipe()
                performRequestedAction()
            }
            .task {
                showPendingRecipe()
                performRequestedAction()
            }
            // Keep Spotlight in sync; waits briefly so typing doesn't reindex on every keystroke.
            .task(id: SpotlightIndexer.signature(of: allRecipes)) {
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
                await SpotlightIndexer.reindex(allRecipes)
            }
            .onChange(of: regular.count) { _, count in
                if currentIndex >= count {
                    withAnimation { currentIndex = max(0, count - 1) }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: favorites.isEmpty)
        }
    }

    // MARK: - Helpers

    /// Opens an unsaved draft; RecipeDetailView inserts it only when the user taps Add.
    private func addNewRecipe() {
        newRecipe = Recipe()
    }

    /// Scrolls the carousel to the recipe, or opens it if it isn't in the carousel
    /// (a favorite, or hidden by the current filter or search).
    private func show(_ recipe: Recipe) {
        if dynamicTypeSize.isAccessibilitySize {
            // The list has no carousel position to scroll to.
            openedRecipe = recipe
        } else if let index = regularRecipes.firstIndex(where: { $0.id == recipe.id }) {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.50, dampingFraction: 0.62)) {
                currentIndex = index
            }
        } else {
            openedRecipe = recipe
        }
    }

    /// Handles menu commands and import links.
    private func performRequestedAction() {
        // Wait until open editors have closed; they close themselves when a request arrives.
        guard navigation.canPresent else { return }
        switch navigation.consumeRequestedAction() {
        case .newRecipe:
            addNewRecipe()
        case .importRecipe(let address):
            importAddress = address
            showImport = true
        case nil:
            break
        }
    }

    private func showPendingRecipe() {
        guard navigation.canPresent else { return }
        guard let id = navigation.consumePendingRecipe(),
              let recipe = allRecipes.first(where: { $0.id == id })
        else { return }
        show(recipe)
    }

    /// Opens the imported draft for review after the import sheet has gone away.
    private func showImportedDraft() {
        guard let draft = importedDraft else { return }
        importedDraft = nil
        newRecipe = draft
    }
}
