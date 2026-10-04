import XCTest

final class EditorUITests: AppUITestCase {

    func testAddingATagShowsAChip() {
        openEditor(of: "Carbonara")
        let field = app.textFields["tagField"]
        scrollTo(field)
        field.tap()
        field.typeText("kids\n")
        expectExists(app.buttons["tagChip.kids"], "The new tag should appear as a chip")
    }

    func testRemovingATag() {
        openEditor(of: "Carbonara")
        let chip = app.buttons["tagChip.weeknight"]
        scrollTo(chip)
        chip.tap()
        expectGone(chip, "Tapping a chip removes the tag")
    }

    func testLoggingCookingShowsInTheHistory() {
        openEditor(of: "Carbonara")
        let log = app.buttons["logCookingButton"]
        scrollTo(log)
        XCTAssertTrue(app.staticTexts["cookedCount"].label.hasSuffix(" 0"), "Nothing has been cooked yet")
        log.tap()
        expectExists(app.buttons["cookLog.save"], "The log sheet should open").tap()
        expectExists(app.staticTexts["cookedCount"], "The history should be visible")
        XCTAssertTrue(app.staticTexts["cookedCount"].label.hasSuffix(" 1"), "The history should show one entry")
    }

    func testDeletingFromTheEditorCanBeUndone() {
        openEditor(of: "Carbonara")
        let delete = app.buttons["editor.delete"]
        scrollTo(delete)
        delete.tap()
        expectExists(app.buttons["confirmDelete"].firstMatch, "Deleting should ask for confirmation").tap()

        expectExists(app.buttons["undoButton"], "The undo banner should appear after the editor closes")
        app.buttons["undoButton"].tap()
        expectCurrentCard("Carbonara", "Undo should bring the recipe back")
    }

    func testChangingTheNameUpdatesTheCard() {
        openEditor(of: "Carbonara")
        let name = app.textFields["recipeNameField"]
        name.tap()
        name.press(forDuration: 1.0)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) { app.menuItems["Select All"].tap() }
        name.typeText("Spaghetti Carbonara")
        app.buttons["editor.done"].tap()
        expectCurrentCard("Spaghetti Carbonara", "The card should show the new name")
    }
}
