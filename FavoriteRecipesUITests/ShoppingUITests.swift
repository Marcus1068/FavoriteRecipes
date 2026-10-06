import XCTest

final class IngredientsUITests: AppUITestCase {
    private func plus(_ stepper: XCUIElement) -> XCUICoordinate { stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)) }
    private func minus(_ stepper: XCUIElement) -> XCUICoordinate { stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.76, dy: 0.5)) }

    private var ingredientRows: XCUIElementQuery { app.buttons.matching(identifier: "ingredientRow") }

    /// The stepper reports "Servings, 4"; this reads the number at the end.
    private func servingsShown() -> String? {
        app.staticTexts["servingsValue"].label.split(separator: " ").last.map(String.init)
    }

    private func rowLabels() -> [String] {
        ingredientRows.allElementsBoundByIndex.map(\.label)
    }

    func testIngredientsAreShownAsWrittenAtTheRecipesServings() {
        openCookingMode(of: "Carbonara")
        expectExists(ingredientRows.firstMatch, "The ingredients should be listed")
        XCTAssertEqual(rowLabels().first, "400 g spaghetti")
        XCTAssertEqual(servingsShown(), "4")
    }

    func testChangingServingsScalesTheAmounts() {
        openCookingMode(of: "Carbonara")
        let stepper = expectExists(app.steppers["servingsStepper"], "A recipe with servings can be scaled")
        for _ in 0..<4 { plus(stepper).tap() }

        XCTAssertEqual(servingsShown(), "8")
        XCTAssertTrue(waitUntil { self.rowLabels().first == "800 g spaghetti" }, "Amounts should double for double the servings")
        XCTAssertTrue(rowLabels().contains("8 egg yolks"))
    }

    func testFewerServingsShowFractions() {
        openCookingMode(of: "Carbonara")
        let stepper = expectExists(app.steppers["servingsStepper"], "A recipe with servings can be scaled")
        for _ in 0..<2 { minus(stepper).tap() }
        XCTAssertTrue(waitUntil { self.rowLabels().first == "200 g spaghetti" }, "Half the servings need half the amounts")
    }

    func testSwitchingToImperialUnits() {
        openCookingMode(of: "Carbonara")
        expectExists(app.buttons["unitSystemPicker"], "The unit picker should exist").tap()
        tapMenuLabel("US / Imperial")
        XCTAssertTrue(waitUntil { self.rowLabels().first == "14.1 oz spaghetti" }, "400 g are about 14 oz")
        XCTAssertTrue(rowLabels().contains("4 egg yolks"), "Counted things stay as they are")
    }

    func testRecipeWithoutServingsHasNoScaling() {
        openSortFilterMenu()
        tapMenuLabel("Oldest first")
        openCookingMode(of: "Mushroom Risotto")
        expectExists(ingredientRows.firstMatch, "The ingredients should be listed")
        XCTAssertFalse(app.steppers["servingsStepper"].exists, "Scaling needs the recipe's servings")
        XCTAssertTrue(app.buttons["unitSystemPicker"].exists, "Units can still be changed")
    }
}

final class ShoppingUITests: AppUITestCase {
    private func plus(_ stepper: XCUIElement) -> XCUICoordinate { stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)) }

    private func openShoppingTab() {
        app.tabBars.buttons["Shopping"].tap()
    }

    func testTheShoppingListStartsEmpty() {
        openShoppingTab()
        expectExists(app.staticTexts["Your shopping list is empty"], "A new list says it is empty")
    }

    func testAddingFromTheCardMenuAndTickingItems() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.shopping")
        expectExists(app.descendants(matching: .any)["shoppingAddedBanner"], "Adding should be confirmed")

        openShoppingTab()
        let items = app.buttons.matching(identifier: "shoppingItem")
        expectExists(items.firstMatch, "The ingredients should be on the list")
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.element(boundBy: 0).label, "400 g spaghetti")
        expectExists(app.staticTexts["4 servings"], "The list shows which recipe the items belong to")

        items.element(boundBy: 0).tap()
        XCTAssertEqual(items.element(boundBy: 0).value as? String, "Ready", "A ticked item says so")
    }

    func testRecipesWithTheSameIngredientAreMerged() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.shopping")

        // Swipe to the next recipe, Apple Pie, which also needs egg yolks.
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.45))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.45))
        from.press(forDuration: 0.1, thenDragTo: to)
        expectCurrentCard("Apple Pie", "The next recipe should be in the middle")
        openCardMenu(of: "Apple Pie")
        tapMenuItem("menu.shopping")

        openShoppingTab()
        let items = app.buttons.matching(identifier: "shoppingItem")
        expectExists(items.firstMatch, "The ingredients should be on the list")
        XCTAssertTrue(items.allElementsBoundByIndex.map(\.label).contains("6 egg yolks"), "4 + 2 egg yolks are added up")
        XCTAssertEqual(items.count, 5, "Spaghetti, guanciale, egg yolks, apples and flour")
    }

    func testAddingFromCookingModeUsesTheChosenServings() {
        openCookingMode(of: "Carbonara")
        let stepper = expectExists(app.steppers["servingsStepper"], "A recipe with servings can be scaled")
        plus(stepper).tap()
        plus(stepper).tap()
        expectExists(app.buttons["addToShoppingListButton"], "Cooking mode can add to the list").tap()
        app.buttons["cooking.done"].tap()

        openShoppingTab()
        let items = app.buttons.matching(identifier: "shoppingItem")
        expectExists(items.firstMatch, "The ingredients should be on the list")
        XCTAssertEqual(items.element(boundBy: 0).label, "600 g spaghetti", "The list uses the 6 servings chosen")
        expectExists(app.staticTexts["6 servings"], "and says so")
    }

    func testRemovingCheckedItems() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.shopping")
        openShoppingTab()
        let items = app.buttons.matching(identifier: "shoppingItem")
        expectExists(items.firstMatch, "The ingredients should be on the list").tap()

        expectExists(app.buttons["shopping.menu"], "The list has a menu").tap()
        tapMenuItem("shopping.clearChecked")
        XCTAssertTrue(waitUntil { items.count == 2 }, "The ticked item is gone")
    }

    func testClearingTheWholeList() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.shopping")
        openShoppingTab()
        expectExists(app.buttons["shopping.menu"], "The list has a menu").tap()
        tapMenuItem("shopping.clearAll")
        expectExists(app.buttons["shopping.confirmClearAll"].firstMatch, "Clearing asks first").tap()
        expectExists(app.staticTexts["Your shopping list is empty"], "The list is empty again")
    }

    func testRemovingARecipeFromTheList() {
        openCardMenu(of: "Carbonara")
        tapMenuItem("menu.shopping")
        openShoppingTab()
        let recipe = expectExists(app.staticTexts["4 servings"], "The recipe should be listed")
        recipe.swipeLeft()
        expectExists(app.buttons["Remove Recipe"], "A swipe offers to remove the recipe").tap()
        expectExists(app.staticTexts["Your shopping list is empty"], "Without recipes the list is empty")
    }
}
