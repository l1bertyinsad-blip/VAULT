import XCTest

final class VAULTUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchCreateAndOpenEmptyFolder() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        XCTAssertTrue(app.otherElements["foldersEmptyState"].waitForExistence(timeout: 3))
        app.buttons["createFolderButton"].tap()

        let nameField = app.textFields["folderNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("UI Test")
        app.buttons["saveFolderButton"].tap()

        let folder = app.buttons["folderCard_UI Test"]
        XCTAssertTrue(folder.waitForExistence(timeout: 2))
        folder.tap()
        XCTAssertTrue(app.otherElements["folderEmptyState"].waitForExistence(timeout: 2))
    }
}
