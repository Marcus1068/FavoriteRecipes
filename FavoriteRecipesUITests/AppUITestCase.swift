import XCTest

/// Base class: launches the app in its predictable test mode (English, in-memory store,
/// three sample recipes: Carbonara, Apple Pie, Mushroom Risotto) and offers small helpers.
class AppUITestCase: XCTestCase {
    var app: XCUIApplication!

    /// Extra launch arguments for a single test class.
    var extraArguments: [String] { [] }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + extraArguments
        app.launch()
    }

    // MARK: - Helpers

    /// Waits for an element and fails the test with a clear message if it never appears.
    @discardableResult
    func expectExists(_ element: XCUIElement, _ message: String, timeout: TimeInterval = 10,
                      file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message, file: file, line: line)
        return element
    }

    func expectGone(_ element: XCUIElement, _ message: String, timeout: TimeInterval = 10,
                    file: StaticString = #filePath, line: UInt = #line) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: timeout), .completed, message, file: file, line: line)
    }

    /// The name label of a recipe card. The carousel keeps its neighbours in the screen tree
    /// (off to the side), so use `expectCurrentCard` to check which card is in the middle.
    func currentCard(_ name: String) -> XCUIElement {
        app.staticTexts[name]
    }

    /// Whether an element is on screen, not just somewhere in the tree.
    func isOnScreen(_ element: XCUIElement) -> Bool {
        element.exists && element.isHittable
    }

    /// Polls until the condition holds or the time runs out.
    func waitUntil(timeout: TimeInterval = 10, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return condition()
    }

    /// Fails unless the recipe card with this name is the one in the middle of the carousel.
    func expectCurrentCard(_ name: String, _ message: String? = nil,
                           file: StaticString = #filePath, line: UInt = #line) {
        let card = currentCard(name)
        XCTAssertTrue(waitUntil { isOnScreen(card) }, message ?? "\(name) should be the card in the middle",
                      file: file, line: line)
    }

    /// Fails if the recipe card with this name is still in the middle of the carousel.
    func expectNoCurrentCard(_ name: String, _ message: String? = nil,
                             file: StaticString = #filePath, line: UInt = #line) {
        let card = currentCard(name)
        XCTAssertTrue(waitUntil { !isOnScreen(card) }, message ?? "\(name) should not be in the middle",
                      file: file, line: line)
    }

    /// The on-screen button with an identifier, among the copies on neighbouring cards.
    func visibleButton(_ identifier: String) -> XCUIElement {
        let buttons = app.buttons.matching(identifier: identifier)
        func firstVisible() -> XCUIElement? {
            buttons.allElementsBoundByIndex.first { $0.exists && $0.isHittable }
        }
        _ = waitUntil { firstVisible() != nil }
        return firstVisible() ?? buttons.firstMatch
    }

    /// Opens the long-press menu of the card in the middle of the carousel.
    func openCardMenu(of name: String, file: StaticString = #filePath, line: UInt = #line) {
        expectCurrentCard(name, "The \(name) card should be on screen", file: file, line: line)
        currentCard(name).press(forDuration: 1.2)
    }

    /// Taps an item of a context menu, which exposes identifiers.
    func tapMenuItem(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        expectExists(app.buttons[identifier], "Menu item \(identifier) should appear", file: file, line: line).tap()
    }

    /// Taps an item of a pull-down menu, which exposes only the visible label.
    func tapMenuLabel(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        expectExists(app.buttons[label], "Menu item \"\(label)\" should appear", file: file, line: line).tap()
    }

    /// Opens the editor of the current card with the pencil button.
    func openEditor(of name: String) {
        expectCurrentCard(name, "The \(name) card should be on screen")
        expectExists(visibleButton("card.edit"), "The card should have an edit button").tap()
        expectExists(app.buttons["editor.done"], "The editor should open")
    }

    /// Scrolls the form until the element can be tapped.
    func scrollTo(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let list = app.collectionViews.firstMatch
        var attempts = 0
        while !element.isHittable && attempts < 10 {
            list.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(element.isHittable, "\(element) should be reachable by scrolling", file: file, line: line)
    }

    func openCookingMode(of name: String) {
        expectCurrentCard(name, "The \(name) card should be on screen")
        expectExists(visibleButton("card.cook"), "The card should have a cooking mode button").tap()
        expectExists(app.buttons["cooking.done"], "Cooking mode should open")
    }

    func showStepsTab() {
        let tabs = expectExists(app.segmentedControls["cookingTabs"], "Cooking mode should have a tab picker")
        tabs.buttons.element(boundBy: 1).tap()
    }

    func openSortFilterMenu() {
        expectExists(app.buttons["sortFilterMenu"], "The sort and filter button should exist").tap()
    }
}
