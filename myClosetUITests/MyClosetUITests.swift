import XCTest

final class MyClosetUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testEmptyClosetStartsWithOwnImageImport() {
        app.launchArguments = ["-resetPrototypeData"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Import your own images from Closet to begin."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Load sample closet"].exists)
        app.tabBars.buttons["Closet"].tap()
        XCTAssertTrue(app.buttons["bulk-photo-import"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Start your closet"].exists)
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
        XCTAssertTrue(app.otherElements["generated-outfit-composition"].waitForExistence(timeout: 5))

        let brief = app.buttons["Change outfit brief"]
        XCTAssertTrue(brief.exists)
        brief.tap()
        XCTAssertTrue(app.staticTexts["Set the scene."].waitForExistence(timeout: 5))
        app.buttons["Work"].tap()
        XCTAssertFalse(app.buttons["Choose an anchor piece"].exists)
        app.buttons["apply-outfit-brief"].tap()

        XCTAssertTrue(app.staticTexts["generated-outfit-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["generated-outfit-composition"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Lock'")).firstMatch.exists)
    }

    func testFollowingIsClearlyMarkedComingSoon() {
        app.launchArguments = ["-resetPrototypeData"]
        app.launch()

        app.tabBars.buttons["Following"].tap()

        XCTAssertTrue(app.staticTexts["Coming soon"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Profiles and outfit inspiration are planned for after launch."].exists)
        XCTAssertTrue(app.staticTexts["Your closet will always stay private."].exists)
    }

    func testClosetPieceOpensEditableMetadata() {
        app.launchArguments = ["-resetPrototypeData", "-loadPrototypeSamples"]
        app.launch()

        app.tabBars.buttons["Closet"].tap()
        let piece = app.staticTexts["Navy Oxford Shirt"]
        XCTAssertTrue(piece.waitForExistence(timeout: 5))
        piece.tap()

        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Name"].exists)
        XCTAssertTrue(app.staticTexts["Piece details"].exists)
    }

    func testImportedPieceMustBeConfirmedAndCanBeCorrectedBeforeSaving() {
        app.launchArguments = ["-resetPrototypeData", "-openPrototypeImportReview"]
        app.launch()

        XCTAssertTrue(app.otherElements["import-review-screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["import-review-confidence-warning"].exists)
        let name = app.textFields["import-review-name"]
        XCTAssertTrue(name.exists)

        name.tap()
        name.clearAndEnterText("Black Trousers")
        app.buttons["Done"].tap()

        let bottom = app.buttons["import-review-category-bottom"]
        bottom.tap()
        XCTAssertEqual(bottom.value as? String, "Selected")
        XCTAssertEqual(name.value as? String, "Black Trousers")

        let black = app.buttons["import-review-dominant-black"]
        XCTAssertTrue(black.waitForExistence(timeout: 3))
        XCTAssertTrue(black.waitUntilHittable(timeout: 3))
        black.tap()

        let noAccent = app.buttons["import-review-accent-none"]
        XCTAssertTrue(noAccent.waitForExistence(timeout: 3))
        XCTAssertTrue(noAccent.waitUntilHittable(timeout: 3))
        noAccent.tap()

        let seasonsContinue = app.buttons["import-review-seasons-continue"]
        XCTAssertTrue(seasonsContinue.waitForExistence(timeout: 3))
        XCTAssertTrue(seasonsContinue.waitUntilHittable(timeout: 3))
        seasonsContinue.tap()

        let next = app.buttons["import-review-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        next.tap()

        let secondHeader = app.staticTexts["Piece 2 of 2"]
        XCTAssertTrue(secondHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(secondHeader.waitUntilHittable(timeout: 3))
        XCTAssertEqual(app.textFields["import-review-name"].value as? String, "Beige Footwear")

        let save = app.buttons["import-review-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()

        XCTAssertTrue(app.otherElements["import-summary-screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["2 pieces added"].exists)
        XCTAssertTrue(app.staticTexts["import-summary-readiness"].exists)
        app.buttons["import-summary-done"].tap()
        XCTAssertTrue(app.staticTexts["Black Trousers"].waitForExistence(timeout: 5))
    }

    func testImportReviewCanSkipAnAccidentalPhoto() {
        app.launchArguments = ["-resetPrototypeData", "-openPrototypeImportReview"]
        app.launch()

        XCTAssertTrue(app.otherElements["import-review-screen"].waitForExistence(timeout: 5))
        app.buttons["import-review-skip"].tap()
        XCTAssertTrue(app.buttons["Skip photo"].waitForExistence(timeout: 3))
        app.buttons["Skip photo"].tap()

        XCTAssertTrue(app.staticTexts["Piece 1 of 1"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.textFields["import-review-name"].value as? String, "Beige Footwear")
        XCTAssertTrue(app.buttons["import-review-fast-confirm"].exists)
        app.buttons["import-review-fast-confirm"].tap()

        XCTAssertTrue(app.otherElements["import-summary-screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 piece added"].exists)
        XCTAssertTrue(app.staticTexts["1 photo was skipped."].exists)
        app.buttons["import-summary-done"].tap()
        XCTAssertTrue(app.staticTexts["Beige Footwear"].waitForExistence(timeout: 5))
    }
}

private extension XCUIElement {
    func waitUntilHittable(timeout: TimeInterval) -> Bool {
        XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: self)],
            timeout: timeout
        ) == .completed
    }

    func clearAndEnterText(_ text: String) {
        guard let currentValue = value as? String else {
            typeText(text)
            return
        }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        typeText(text)
    }
}
