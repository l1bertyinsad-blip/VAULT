import XCTest

final class VAULTUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchCreateAndOpenEmptyFolder() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        XCTAssertTrue(app.buttons["globalImportButton"].waitForExistence(timeout: 5))
        app.buttons["tab_folders"].tap()
        XCTAssertTrue(app.buttons["searchFilterButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["createFolderButton"].waitForExistence(timeout: 5))
        app.buttons["createFolderButton"].tap()

        let nameField = app.textFields["folderNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("UI Test")
        app.buttons["saveFolderButton"].tap()

        let folder = app.buttons["folderCard_UI Test"]
        XCTAssertTrue(folder.waitForExistence(timeout: 2))
        folder.tap()
        XCTAssertTrue(app.descendants(matching: .any)["folderEmptyState"].waitForExistence(timeout: 4))
    }

    func testAppStoreScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITesting",
            "-AppStoreScreenshots",
            "-AppleLanguages", "(ru)",
            "-AppleLocale", "ru_RU"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["globalImportButton"].waitForExistence(timeout: 8))
        pauseForRendering()
        keepScreenshot(named: "01-home")

        app.buttons["globalImportButton"].tap()
        XCTAssertTrue(app.navigationBars["Добавить в VAULT"].waitForExistence(timeout: 5))
        pauseForRendering()
        keepScreenshot(named: "02-import")
        app.buttons["Готово"].tap()

        app.buttons["tab_folders"].tap()
        XCTAssertTrue(app.buttons["folderCard_Рецепты"].waitForExistence(timeout: 5))
        pauseForRendering()
        keepScreenshot(named: "03-folders")

        app.buttons["tab_favorites"].tap()
        pauseForRendering()
        keepScreenshot(named: "04-favorites")

        app.buttons["tab_profile"].tap()
        pauseForRendering()
        keepScreenshot(named: "05-profile")
    }

    private func keepScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func pauseForRendering() {
        Thread.sleep(forTimeInterval: 1.2)
    }
}
