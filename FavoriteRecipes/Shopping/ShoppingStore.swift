import Foundation
import Observation

/// The shopping list: recipes the user added, which items are ticked, and the merged list built from them.
/// It is saved on the device; the list is not synced.
@MainActor
@Observable
final class ShoppingStore {
    private(set) var recipes: [ShoppingRecipe] = []
    private(set) var checkedIDs: Set<String> = []
    /// Set when something was added, so the app can confirm it briefly.
    private(set) var lastAddedTitle: String?
    private(set) var addedCount = 0

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "shoppingList") {
        self.defaults = defaults
        self.key = key
        load()
    }

    // MARK: - Reading

    /// The merged list, in the order the ingredients were added.
    var items: [ShoppingItem] { ShoppingListBuilder.items(from: recipes) }

    var isEmpty: Bool { recipes.isEmpty }

    func isChecked(_ item: ShoppingItem) -> Bool { checkedIDs.contains(item.id) }

    /// The items still to buy, one per line, for sharing as text.
    var shareText: String {
        items.filter { !isChecked($0) }.map { "• " + $0.text }.joined(separator: "\n")
    }

    /// The items still to buy, for Reminders.
    var openItemTexts: [String] {
        items.filter { !isChecked($0) }.map(\.text)
    }

    // MARK: - Changing

    /// Adds a recipe. A recipe that is already on the list is replaced, for example with other servings.
    func add(_ recipe: ShoppingRecipe) {
        guard !recipe.ingredients.isEmpty else { return }
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        } else {
            recipes.append(recipe)
        }
        lastAddedTitle = recipe.title
        addedCount += 1
        save()
    }

    func remove(_ recipe: ShoppingRecipe) {
        recipes.removeAll { $0.id == recipe.id }
        pruneChecked()
        save()
    }

    func toggle(_ item: ShoppingItem) {
        if !checkedIDs.insert(item.id).inserted {
            checkedIDs.remove(item.id)
        }
        save()
    }

    /// Removes the ticked items from the list.
    func clearChecked() {
        let checked = checkedIDs
        for index in recipes.indices {
            recipes[index].ingredients.removeAll { checked.contains(ShoppingListBuilder.groupKey(for: $0)) }
        }
        recipes.removeAll { $0.ingredients.isEmpty }
        checkedIDs = []
        save()
    }

    func clearAll() {
        recipes = []
        checkedIDs = []
        save()
    }

    func dismissAddedNotice() {
        lastAddedTitle = nil
    }

    /// Forget ticks for items that are no longer on the list.
    private func pruneChecked() {
        let current = Set(items.map(\.id))
        checkedIDs = checkedIDs.intersection(current)
    }

    // MARK: - Saving

    private struct SavedState: Codable {
        var recipes: [ShoppingRecipe]
        var checkedIDs: Set<String>
    }

    private func save() {
        let state = SavedState(recipes: recipes, checkedIDs: checkedIDs)
        defaults.set(try? JSONEncoder().encode(state), forKey: key)
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        recipes = state.recipes
        checkedIDs = state.checkedIDs
    }
}
