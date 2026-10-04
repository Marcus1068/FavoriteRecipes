import XCTest

final class OnboardingUITests: AppUITestCase {
    // The introduction only appears for people without recipes.
    override var extraArguments: [String] { ["-ui-onboarding", "-ui-empty"] }

    func testIntroductionShowsOnFirstLaunchAndCanBeClosed() {
        expectExists(app.staticTexts["Welcome"], "A new user should see the introduction")
        app.buttons["Get Started"].tap()
        expectGone(app.staticTexts["Welcome"], "Closing the introduction shows the app")
        expectExists(app.staticTexts["No Recipes Yet"], "The empty collection should be behind it")
    }
}

final class EmptyCollectionUITests: AppUITestCase {
    override var extraArguments: [String] { ["-ui-empty"] }

    func testAnEmptyCollectionInvitesTheFirstRecipe() {
        expectExists(app.staticTexts["No Recipes Yet"], "An empty collection should say so")
        expectExists(app.buttons["emptyAddButton"], "The empty state should have its own add button").tap()
        expectExists(app.textFields["recipeNameField"], "The button should open a new recipe")
    }
}

final class ImportUITests: AppUITestCase {

    func testImportRejectsAnInvalidAddressAndOffersPastingText() {
        expectExists(app.buttons["addMenu"], "The add button should exist").tap()
        tapMenuItem("importButton")

        let address = expectExists(app.textFields.firstMatch, "The import sheet should ask for an address")
        address.tap()
        address.typeText("not a url")
        app.buttons["Import"].tap()

        expectExists(app.staticTexts["Page not readable?"], "A failed import offers to paste the page text")
    }

    func testPastedTextBecomesADraft() {
        expectExists(app.buttons["addMenu"], "The add button should exist").tap()
        tapMenuItem("importButton")

        let address = expectExists(app.textFields.firstMatch, "The import sheet should ask for an address")
        address.tap()
        address.typeText("not a url")
        app.buttons["Import"].tap()

        let text = expectExists(app.textFields["Paste the recipe text"], "The paste field should appear")
        text.tap()
        text.typeText("Pancakes 2 eggs 200 ml milk")
        app.buttons["Create Draft from Text"].tap()

        expectExists(app.buttons["editor.add"], "The text should open as a draft to review")
    }
}
