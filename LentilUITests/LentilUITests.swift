import XCTest

final class LentilUITests: XCTestCase {
    func testBorrowedItemFromEntryThroughHistory() {
        let app = XCUIApplication()
        app.launchEnvironment["LENTIL_TEST_STORE"] = UUID().uuidString
        app.launch()
        let name = "Apples " + UUID().uuidString.prefix(6)
        app.buttons["Add loan"].tap()
        app.buttons["I borrowed"].tap()
        fill(app.textFields["Borrowed from"], "Maya")
        fill(app.textFields["Item name"], String(name))
        fill(app.textFields["Quantity"], "2")
        app.buttons["Save"].tap()
        app.buttons.containing(.staticText, identifier: String(name)).firstMatch.tap()
        app.buttons["Record return"].tap()
        fill(app.textFields["Amount returned"], "1")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Record return"].waitForExistence(timeout: 3))
        app.terminate()
        app.launch()
        app.buttons.containing(.staticText, identifier: String(name)).firstMatch.tap()
        app.buttons["Record return"].tap()
        app.buttons["Return all"].tap()
        XCTAssertEqual(app.textFields["Amount returned"].value as? String, "1")
        app.buttons["Save"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["History"].tap()
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: String(name)).firstMatch.exists)
    }

    func testSingleItemWithoutDueDate() {
        let app = XCUIApplication()
        app.launchEnvironment["LENTIL_TEST_STORE"] = UUID().uuidString
        app.launch()
        let name = "Book " + UUID().uuidString.prefix(6)
        app.buttons["Add loan"].tap()
        let dueToggle = app.switches["Set due date"]
        let switchControl = dueToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        XCTAssertEqual(dueToggle.value as? String, "0")
        switchControl.tap()
        XCTAssertEqual(dueToggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Due date"].waitForExistence(timeout: 3))
        switchControl.tap()
        fill(app.textFields["Lent to"], "Maya")
        fill(app.textFields["Item name"], String(name))
        app.buttons["Save"].tap()
        app.buttons.containing(.staticText, identifier: String(name)).firstMatch.tap()
        XCTAssertFalse(app.staticTexts["Due date"].exists)
        app.buttons["Record return"].tap()
        app.buttons["Return all"].tap()
        XCTAssertEqual(app.textFields["Amount returned"].value as? String, "1")
    }

    func testMoneyRepayment() {
        let app = XCUIApplication()
        app.launchEnvironment["LENTIL_TEST_STORE"] = UUID().uuidString
        app.launch()
        let person = "Sam " + UUID().uuidString.prefix(6)
        app.buttons["Add loan"].tap()
        fill(app.textFields["Lent to"], String(person))
        app.buttons["Money"].tap()
        XCTAssertTrue(app.textFields["Amount"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        fill(app.textFields["Amount"], "4.50")
        app.buttons["Save"].tap()
        app.buttons.containing(.staticText, identifier: String(person)).firstMatch.tap()
        app.buttons["Record return"].tap()
        fill(app.textFields["Amount returned"], "1.25")
        app.buttons["Save"].tap()
        app.buttons["Record return"].tap()
        app.buttons["Return all"].tap()
        XCTAssertEqual(app.textFields["Amount returned"].value as? String, "3.25")
    }

    private func fill(_ field: XCUIElement, _ text: String) {
        field.tap()
        field.typeText(text)
    }
}
