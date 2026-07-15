import XCTest

final class MyClosetUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testEmptyClosetCanLoadSamplesAndCreateDailyOutfit() {
        app.launchArguments = ["-resetPrototypeData"]
        app.launch()

        let loadButton = app.buttons["Load sample closet"]
        XCTAssertTrue(loadButton.waitForExistence(timeout: 5))
        loadButton.tap()

        XCTAssertTrue(app.staticTexts["Outfit of the day"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["daily-outfit-composition"].exists)
        XCTAssertTrue(app.buttons["I wore this"].exists)
    }

    func testCoreClosetAndGeneratorJourney() {
        app.launchArguments = ["-resetPrototypeData", "-loadPrototypeSamples"]
        app.launch()

        app.tabBars.buttons["Closet"].tap()
        XCTAssertTrue(app.staticTexts["12 pieces"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Navy Oxford Shirt"].exists)
        XCTAssertTrue(app.buttons["bulk-photo-import"].exists)

        app.tabBars.buttons["Generate"].tap()
        let generate = app.buttons["generate-outfit-button"]
        XCTAssertTrue(generate.waitForExistence(timeout: 5))
        generate.tap()

        XCTAssertTrue(app.staticTexts["generated-outfit-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Lock'")).firstMatch.exists)
    }

}
