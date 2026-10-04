import XCTest

final class RecipesUITests: AppUITestCase {

    func testLaunchShowsTheNewestRecipe() {
        expectCurrentCard("Carbonara", "The newest recipe should be in the middle of the carousel")
        XCTAssertTrue(app.tabBars.buttons.count >= 3, "The app should have its three tabs")
    }

    func testAddingARecipe() {
        expectExists(app.buttons["addMenu"], "The add button should exist").tap()
        tapMenuItem("newRecipeButton")

        let name = expectExists(app.textFields["recipeNameField"], "The editor should have a name field")
        let add = app.buttons["editor.add"]
        XCTAssertFalse(add.isEnabled, "An empty draft cannot be added")

        name.tap()
        name.typeText("Pancakes")
        XCTAssertTrue(add.isEnabled, "A draft with a name can be added")
        add.tap()

        expectCurrentCard("Pancakes", "The new recipe should be the newest card")
    }

    func testCancellingAnEmptyDraftKeepsTheCollection() {
        expectExists(app.buttons["addMenu"], "The add button should exist").tap()
        tapMenuItem("newRecipeButton")
        expectExists(app.buttons["editor.cancel"], "The editor should open").tap()
        expectCurrentCard("Carbonara", "Nothing should have changed")
    }

    func testDuplicatingARecipe() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.duplicate")

        let name = expectExists(app.textFields["recipeNameField"], "The copy should open in the editor")
        XCTAssertEqual(name.value as? String, "Carbonara (copy)")
        app.buttons["editor.done"].tap()

        expectCurrentCard("Carbonara (copy)", "The copy should be a new recipe in the collection")
    }

    func testDeletingARecipeCanBeUndone() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.delete")
        expectExists(app.buttons["confirmDelete"].firstMatch, "Deleting should ask for confirmation").tap()

        expectExists(app.buttons["undoButton"], "A banner should offer to undo")
        expectNoCurrentCard("Carbonara", "The deleted recipe should be gone")
        expectCurrentCard("Apple Pie", "The next recipe should move in")

        app.buttons["undoButton"].tap()
        expectCurrentCard("Carbonara", "Undo should bring the recipe back")
    }

    func testCancellingTheDeleteConfirmationKeepsTheRecipe() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.delete")
        expectExists(app.buttons["confirmDelete"].firstMatch, "Deleting should ask for confirmation")
        app.otherElements["PopoverDismissRegion"].tap()
        expectCurrentCard("Carbonara", "Cancelling should keep the recipe")
        XCTAssertFalse(app.buttons["undoButton"].exists)
    }

    func testSortingByName() {
        openSortFilterMenu()
        tapMenuLabel("Name (A–Z)")
        expectCurrentCard("Apple Pie", "Sorted by name, Apple Pie comes first")
        expectNoCurrentCard("Carbonara", "Carbonara is no longer in the middle")
    }

    func testSortingByRating() {
        openSortFilterMenu()
        tapMenuLabel("Best rated")
        expectCurrentCard("Apple Pie", "The best rated recipe comes first")
    }

    func testFilteringByMinimumRatingAndResetting() {
        openSortFilterMenu()
        tapMenuLabel("5 ★ or better")
        expectCurrentCard("Apple Pie", "Only the five-star recipe is left")
        expectNoCurrentCard("Carbonara", "Lower rated recipes are hidden")

        openSortFilterMenu()
        tapMenuLabel("Reset Filters")
        expectCurrentCard("Carbonara", "Resetting shows everything again")
    }

    func testFilteringByTag() {
        openSortFilterMenu()
        tapMenuLabel("baking")
        expectCurrentCard("Apple Pie", "Only the baking recipe is left")
        expectNoCurrentCard("Carbonara", "Other recipes are hidden")
    }

    func testFilteringWithNoMatchesOffersAReset() {
        openSortFilterMenu()
        tapMenuLabel("weeknight")
        openSortFilterMenu()
        tapMenuLabel("5 ★ or better")
        expectExists(app.staticTexts["No matching recipes"], "An empty result should say so")
        expectExists(app.buttons["Reset Filters"], "and offer to reset the filters").tap()
        expectCurrentCard("Carbonara", "Resetting shows the recipes again")
    }

    func testSearchFindsRecipesByIngredient() {
        let search = expectExists(app.searchFields.firstMatch, "The recipes screen should be searchable")
        search.tap()
        search.typeText("guanciale")
        expectCurrentCard("Carbonara", "Search covers ingredients")
        expectNoCurrentCard("Apple Pie", "Other recipes do not match")
    }
}
