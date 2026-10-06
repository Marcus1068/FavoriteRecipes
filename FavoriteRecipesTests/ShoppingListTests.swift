import Foundation
import Testing
@testable import FavoriteRecipes

private let en = Locale(identifier: "en_US")

private func recipe(_ title: String, _ lines: String, servings: Int? = nil, id: UUID = UUID()) -> ShoppingRecipe {
    ShoppingRecipe(id: id, title: title, servings: servings, ingredients: IngredientParser.parseLines(lines))
}

struct ShoppingListBuilderTests {
    private func texts(_ recipes: [ShoppingRecipe]) -> [String] {
        ShoppingListBuilder.items(from: recipes, locale: en).map(\.text)
    }

    @Test func addsUpTheSameIngredientAcrossRecipes() {
        let list = texts([
            recipe("Pasta", "400 g spaghetti\n4 eggs"),
            recipe("Cake", "200 g flour\n3 eggs")
        ])
        #expect(list == ["400 g spaghetti", "7 eggs", "200 g flour"])
    }

    @Test func addsUpDifferentUnitsOfTheSameKind() {
        let list = texts([
            recipe("A", "500 g flour"),
            recipe("B", "8 oz flour")
        ])
        // 500 g + 226.8 g = 726.8 g, shown in metric because the first recipe used metric.
        #expect(list == ["725 g flour"])
    }

    @Test func largeSumsUseBiggerUnits() {
        let list = texts([recipe("A", "700 g flour"), recipe("B", "600 g flour")])
        #expect(list == ["1.3 kg flour"])
    }

    @Test func usesTheFirstRecipesSystemForSums() {
        let list = texts([recipe("A", "1 cup milk"), recipe("B", "250 ml milk")])
        #expect(list == ["2 cups milk"])
    }

    @Test func keepsAmountsOfDifferentKindsApart() {
        let list = texts([recipe("A", "200 g butter"), recipe("B", "2 butter")])
        #expect(list.count == 2)
    }

    @Test func recognizesTheSameIngredientDespiteNotesAndCase() {
        let list = texts([
            recipe("A", "3 cloves Garlic, minced"),
            recipe("B", "2 cloves garlic")
        ])
        #expect(list == ["5 cloves Garlic"])
    }

    @Test func keepsLinesWithoutAnAmountOnce() {
        let list = texts([recipe("A", "Salt and pepper"), recipe("B", "salt and pepper")])
        #expect(list == ["Salt and pepper"])
    }

    @Test func keepsDifferentCountingWordsApart() {
        let list = texts([recipe("A", "2 cloves garlic"), recipe("B", "1 head garlic")])
        #expect(list.count == 2)
    }

    @Test func sumsRanges() {
        let list = texts([recipe("A", "2-3 cloves garlic"), recipe("B", "1 clove garlic")])
        #expect(list == ["3–4 cloves garlic"])
    }

    @Test func keepsTheOrderOfFirstAppearance() {
        let list = texts([recipe("A", "1 onion\n2 carrots"), recipe("B", "1 leek\n1 onion")])
        #expect(list == ["2 onion", "2 carrots", "1 leek"])
    }

    @Test func anEmptyListStaysEmpty() {
        #expect(texts([]).isEmpty)
        #expect(texts([recipe("A", "")]).isEmpty)
    }
}

@MainActor
struct ShoppingStoreTests {
    private func makeStore(_ suite: String = UUID().uuidString) -> (ShoppingStore, UserDefaults) {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (ShoppingStore(defaults: defaults), defaults)
    }

    @Test func startsEmpty() {
        let (store, _) = makeStore()
        #expect(store.isEmpty && store.items.isEmpty)
    }

    @Test func addingARecipeFillsTheList() {
        let (store, _) = makeStore()
        store.add(recipe("Pasta", "400 g spaghetti\n4 eggs"))
        #expect(store.items.count == 2)
        #expect(store.lastAddedTitle == "Pasta")
        #expect(store.addedCount == 1)
    }

    @Test func addingTheSameRecipeAgainReplacesIt() {
        let (store, _) = makeStore()
        let id = UUID()
        store.add(recipe("Pasta", "400 g spaghetti", servings: 2, id: id))
        store.add(recipe("Pasta", "800 g spaghetti", servings: 4, id: id))
        #expect(store.recipes.count == 1)
        #expect(store.items.map(\.text).first?.hasPrefix("800") == true)
        #expect(store.recipes.first?.servings == 4)
    }

    @Test func recipesWithoutIngredientsAreIgnored() {
        let (store, _) = makeStore()
        store.add(recipe("Empty", ""))
        #expect(store.isEmpty)
        #expect(store.addedCount == 0)
    }

    @Test func tickingItemsAndSharingOnlyOpenOnes() {
        let (store, _) = makeStore()
        store.add(recipe("Pasta", "400 g spaghetti\n4 eggs"))
        let first = store.items[0]
        store.toggle(first)
        #expect(store.isChecked(first))
        #expect(store.openItemTexts.count == 1)
        #expect(store.shareText == "• " + store.openItemTexts[0])
        store.toggle(first)
        #expect(!store.isChecked(first))
        #expect(store.openItemTexts.count == 2)
    }

    @Test func clearingCheckedItemsRemovesThemFromEveryRecipe() {
        let (store, _) = makeStore()
        store.add(recipe("A", "4 eggs\n200 g flour"))
        store.add(recipe("B", "2 eggs"))
        let eggs = store.items.first { $0.text.contains("eggs") }!
        store.toggle(eggs)
        store.clearChecked()
        #expect(store.items.count == 1)
        #expect(store.items.first?.text.contains("flour") == true)
        #expect(store.recipes.count == 1, "Recipe B has nothing left and is dropped")
    }

    @Test func removingARecipeDropsItsIngredients() {
        let (store, _) = makeStore()
        let a = recipe("A", "4 eggs")
        store.add(a)
        store.add(recipe("B", "1 leek"))
        store.remove(a)
        #expect(store.items.map(\.text) == ["1 leek"])
    }

    @Test func removingARecipeForgetsTicksOfItemsThatAreGone() {
        let (store, _) = makeStore()
        let a = recipe("A", "4 eggs")
        store.add(a)
        store.toggle(store.items[0])
        store.remove(a)
        #expect(store.checkedIDs.isEmpty)
    }

    @Test func clearAllEmptiesTheList() {
        let (store, _) = makeStore()
        store.add(recipe("A", "4 eggs"))
        store.clearAll()
        #expect(store.isEmpty && store.checkedIDs.isEmpty)
    }

    @Test func theListIsRememberedBetweenLaunches() {
        let suite = UUID().uuidString
        let (store, defaults) = makeStore(suite)
        store.add(recipe("Pasta", "400 g spaghetti", servings: 4))
        store.toggle(store.items[0])

        let reopened = ShoppingStore(defaults: defaults)
        #expect(reopened.recipes.count == 1)
        #expect(reopened.recipes.first?.servings == 4)
        #expect(reopened.items.count == 1)
        #expect(reopened.isChecked(reopened.items[0]))
    }

    @Test func aDamagedSavedListIsIgnored() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(Data("not json".utf8), forKey: "shoppingList")
        #expect(ShoppingStore(defaults: defaults).isEmpty)
    }

    @Test func noticeCanBeDismissed() {
        let (store, _) = makeStore()
        store.add(recipe("A", "4 eggs"))
        store.dismissAddedNotice()
        #expect(store.lastAddedTitle == nil)
    }

    @Test func aRecipeCanBeAddedFromItsIngredientText() {
        let (store, _) = makeStore()
        let model = Recipe(name: "Pancakes")
        model.ingredientsText = "200 g flour\n2 eggs"
        model.servings = 4
        store.add(model.shoppingRecipe)
        #expect(store.recipes.first?.title == "Pancakes")
        #expect(store.recipes.first?.servings == 4)
        #expect(store.items.count == 2)
    }
}

@MainActor
struct CookingModelScalingTests {
    private func model(servings: Int?) -> CookingModel {
        CookingModel(steps: [], ingredients: ["400 g spaghetti", "4 eggs", "Salt"], recipeName: "Pasta",
                     baseServings: servings, recipeID: UUID())
    }

    @Test func scalesToTheChosenServings() {
        let model = model(servings: 4)
        model.servings = 6
        #expect(model.scaleFactor == 1.5)
        #expect(model.displayLines(system: .original, locale: en) == ["600 g spaghetti", "6 eggs", "Salt"])
    }

    @Test func showsTheRecipeAsWrittenAtItsOwnServings() {
        let model = model(servings: 4)
        #expect(model.scaleFactor == 1)
        #expect(model.displayLines(system: .original, locale: en) == ["400 g spaghetti", "4 eggs", "Salt"])
    }

    @Test func scalingIsNotOfferedWithoutBaseServings() {
        let model = model(servings: nil)
        #expect(!model.canScale)
        #expect(model.scaleFactor == 1)
        #expect(model.displayLines(system: .original, locale: en).first == "400 g spaghetti")
    }

    @Test func convertsUnitsToo() {
        let model = model(servings: 2)
        model.servings = 4
        #expect(model.displayLines(system: .imperial, locale: en).first == "1.8 lb spaghetti")
    }

    @Test func theShoppingRecipeUsesTheChosenServings() {
        let model = model(servings: 4)
        model.servings = 8
        let shopping = model.shoppingRecipe()
        #expect(shopping?.servings == 8)
        #expect(shopping?.ingredients.first?.amount == 800)
        #expect(shopping?.title == "Pasta")
    }

    @Test func noShoppingRecipeWithoutARecipeID() {
        let model = CookingModel(steps: [], ingredients: ["1 egg"])
        #expect(model.shoppingRecipe() == nil)
    }
}

struct CountingWordTests {
    @Test func singularAndPluralAreTheSameWord() {
        #expect(IngredientUnit.canonicalCountingWord("cloves") == IngredientUnit.canonicalCountingWord("clove"))
        #expect(IngredientUnit.canonicalCountingWord("Zehen") == IngredientUnit.canonicalCountingWord("Zehe"))
        #expect(IngredientUnit.canonicalCountingWord("Prisen") == IngredientUnit.canonicalCountingWord("Prise"))
        #expect(IngredientUnit.canonicalCountingWord("pinches") == IngredientUnit.canonicalCountingWord("pinch"))
        #expect(IngredientUnit.canonicalCountingWord("slices") == "slice")
    }

    @Test func differentWordsStayDifferent() {
        #expect(IngredientUnit.canonicalCountingWord("clove") != IngredientUnit.canonicalCountingWord("head"))
    }

    @Test func theTotalUsesTheRightForm() {
        let one = ShoppingListBuilder.items(from: [
            ShoppingRecipe(id: UUID(), title: "A", servings: nil, ingredients: IngredientParser.parseLines("1 clove garlic")),
        ], locale: Locale(identifier: "en_US"))
        #expect(one.map(\.text) == ["1 clove garlic"])

        let many = ShoppingListBuilder.items(from: [
            ShoppingRecipe(id: UUID(), title: "A", servings: nil, ingredients: IngredientParser.parseLines("1 clove garlic")),
            ShoppingRecipe(id: UUID(), title: "B", servings: nil, ingredients: IngredientParser.parseLines("2 cloves garlic")),
        ], locale: Locale(identifier: "en_US"))
        #expect(many.map(\.text) == ["3 cloves garlic"])
    }
}
