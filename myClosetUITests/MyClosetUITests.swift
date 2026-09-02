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
        let name = app.textFields["import-review-name"]
        XCTAssertTrue(name.exists)

        let bottom = app.buttons["import-review-category-bottom"]
        bottom.tap()
        XCTAssertEqual(bottom.value as? String, "Selected")
        XCTAssertEqual(name.value as? String, "Navy Bottom")

        name.tap()
        name.clearAndEnterText("Black Trousers")
        app.buttons["Done"].tap()
        let black = app.buttons["import-review-dominant-black"]
        if !black.waitForExistence(timeout: 1) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
                .press(
                    forDuration: 0.05,
                    thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.52))
                )
        }
        XCTAssertTrue(black.waitForExistence(timeout: 3))
        for _ in 0..<3 where !black.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(black.isHittable)
        black.tap()
        XCTAssertEqual(black.value as? String, "Selected")
        XCTAssertEqual(name.value as? String, "Black Trousers")

        let save = app.buttons["import-review-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        save.tap()

        XCTAssertTrue(app.staticTexts["Black Trousers"].waitForExistence(timeout: 5))
        if app.buttons["OK"].exists {
            app.buttons["OK"].tap()
        }
    }
}

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let currentValue = value as? String else {
            typeText(text)
            return
        }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        typeText(text)
    }
}
