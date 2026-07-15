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

        XCTAssertTrue(app.staticTexts["Navy Oxford Shirt"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Outfit of the day"].exists)
    }

    func testCoreClosetAndGeneratorJourney() {
        app.launchArguments = ["-resetPrototypeData", "-loadPrototypeSamples"]
        app.launch()

        app.tabBars.buttons["Closet"].tap()
        XCTAssertTrue(app.staticTexts["12 pieces"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Navy Oxford Shirt"].exists)

        app.tabBars.buttons["Generate"].tap()
        let generate = app.buttons["generate-outfit-button"]
        XCTAssertTrue(generate.waitForExistence(timeout: 5))
        generate.tap()

        XCTAssertTrue(app.staticTexts["generated-outfit-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Lock'")).firstMatch.exists)
    }

    func testFollowingExplainsSafetyBoundary() {
        app.launchArguments = ["-resetPrototypeData", "-loadPrototypeSamples"]
        app.launch()

        app.tabBars.buttons["Following"].tap()

        XCTAssertTrue(app.staticTexts["Outfit inspiration is next"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Likes and comments are intentionally not part of the product scope."].exists)
    }
}
