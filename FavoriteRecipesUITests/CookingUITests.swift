import XCTest

final class CookingUITests: AppUITestCase {

    func testIngredientsCanBeTickedOff() {
        openCookingMode(of: "Carbonara")
        let rows = app.buttons.matching(identifier: "ingredientRow")
        expectExists(rows.firstMatch, "The ingredients should be listed")
        XCTAssertEqual(rows.count, 3)

        rows.element(boundBy: 0).tap()
        XCTAssertEqual(rows.element(boundBy: 0).value as? String, "Ready", "A ticked ingredient says so")
        rows.element(boundBy: 0).tap()
        XCTAssertNotEqual(rows.element(boundBy: 0).value as? String, "Ready", "Tapping again unticks it")
    }

    func testSteppingThroughThePreparation() {
        openCookingMode(of: "Carbonara")
        showStepsTab()

        expectExists(app.staticTexts["Boil the pasta"], "The first step should be shown")
        XCTAssertFalse(app.buttons["previousStepButton"].isEnabled, "There is no step before the first")

        app.buttons["nextStepButton"].tap()
        expectExists(app.staticTexts["Fry the guanciale for 10 minutes"], "The second step should be shown")

        app.buttons["nextStepButton"].tap()
        expectExists(app.staticTexts["Mix everything"], "The third step should be shown")
        XCTAssertFalse(app.buttons["nextStepButton"].isEnabled, "There is no step after the last")

        app.buttons["previousStepButton"].tap()
        expectExists(app.staticTexts["Fry the guanciale for 10 minutes"], "Back returns to the second step")
    }

    func testStartingExtendingAndStoppingATimer() {
        openCookingMode(of: "Carbonara")
        showStepsTab()
        app.buttons["nextStepButton"].tap()

        expectExists(app.buttons["startTimerButton"], "The step mentions 10 minutes, so it offers a timer").tap()
        expectExists(app.otherElements["timerRow"], "A running timer should be listed")

        visibleButton("addMinuteButton").tap()
        XCTAssertTrue(app.otherElements["timerRow"].exists)

        visibleButton("stopTimerButton").tap()
        expectGone(app.otherElements["timerRow"], "Stopping removes the timer")
    }

    func testStepsWithoutADurationOfferNoTimer() {
        openCookingMode(of: "Carbonara")
        showStepsTab()
        expectExists(app.staticTexts["Boil the pasta"], "The first step should be shown")
        XCTAssertFalse(app.buttons["startTimerButton"].exists)
    }

    func testTimersKeepRunningAfterCookingModeCloses() {
        openCookingMode(of: "Carbonara")
        showStepsTab()
        app.buttons["nextStepButton"].tap()
        expectExists(app.buttons["startTimerButton"], "A timer button should be offered").tap()
        expectExists(app.otherElements["timerRow"], "The timer should be running")

        app.buttons["cooking.done"].tap()
        expectExists(app.otherElements["timerRow"], "The timer should still be visible on the recipes screen")
    }

    func testFinishingCookingRecordsItInTheHistory() {
        openCookingMode(of: "Carbonara")
        showStepsTab()
        app.buttons["nextStepButton"].tap()
        app.buttons["nextStepButton"].tap()

        expectExists(app.buttons["Done Cooking"], "The last step offers to record that you cooked it").tap()
        expectExists(app.buttons["cookLog.save"], "The log sheet should open").tap()
        app.buttons["cooking.done"].tap()

        openEditor(of: "Carbonara")
        scrollTo(app.staticTexts["cookedCount"])
        XCTAssertTrue(app.staticTexts["cookedCount"].label.hasSuffix(" 1"), "The history should show one entry")
    }

    func testRecipeWithoutStepsExplainsWhatIsMissing() {
        // Mushroom Risotto has ingredients but no preparation.
        openSortFilterMenu()
        tapMenuLabel("Oldest first")
        openCookingMode(of: "Mushroom Risotto")
        showStepsTab()
        expectExists(app.staticTexts["No preparation steps"], "A recipe without steps says so")
    }
}
