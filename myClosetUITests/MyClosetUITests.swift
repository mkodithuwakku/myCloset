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
        XCTAssertEqual(app.textFields["Name"].value as? String, "Navy Oxford Shirt")
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

        let typeContinue = app.buttons["import-review-type-continue"]
        scrollTo(typeContinue)
        typeContinue.tap()

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

    func testImportRequiresSimpleLassoBeforeMetadata() {
        app.launchArguments = ["-resetPrototypeData", "-openPrototypeImportOutline"]
        app.launch()

        XCTAssertTrue(app.otherElements["import-review-screen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["import-review-outline-required"].exists)
        XCTAssertFalse(app.textFields["import-review-name"].exists)
        XCTAssertFalse(app.buttons["import-review-next"].isEnabled)

        let outlineItem = app.buttons["import-review-outline-item"]
        XCTAssertTrue(outlineItem.waitForExistence(timeout: 3))
        outlineItem.tap()

        XCTAssertTrue(app.otherElements["outline-editor"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["outline-shoe-pair-guidance"].exists)
        let outlineCanvas = app.otherElements["outline-canvas"]
        XCTAssertTrue(outlineCanvas.waitForExistence(timeout: 3))
        outlineCanvas.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.25)).press(
            forDuration: 0.1,
            thenDragTo: outlineCanvas.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.75))
        )
        XCTAssertTrue(app.buttons["outline-clear"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["apply-item-outline"].exists)
        app.navigationBars["Outline item"].buttons["Cancel"].tap()
    }

    func testRefinedOutlineCanBeComparedAppliedAndClearedForRetracing() {
        app.launchArguments = ["-resetPrototypeData", "-openPrototypeImportOutline", "-previewPrototypeRefinedOutline"]
        app.launch()
        XCTAssertTrue(app.buttons["import-review-outline-item"].waitForExistence(timeout: 5))
        app.buttons["import-review-outline-item"].tap()
        let versions = app.segmentedControls["outline-version"]
        XCTAssertTrue(versions.waitForExistence(timeout: 30))
        XCTAssertEqual(app.buttons["apply-item-outline"].label, "Use refined cutout")
        let refinedPreview = XCTAttachment(screenshot: app.screenshot())
        refinedPreview.name = "Refined edges preview"
        refinedPreview.lifetime = .keepAlways
        add(refinedPreview)
        versions.buttons["My outline"].tap()
        XCTAssertEqual(app.buttons["apply-item-outline"].label, "Use this outline")
        let manualPreview = XCTAttachment(screenshot: app.screenshot())
        manualPreview.name = "Original outline comparison"
        manualPreview.lifetime = .keepAlways
        add(manualPreview)
        versions.buttons["Refined"].tap()
        app.buttons["apply-item-outline"].tap()
        XCTAssertTrue(app.textFields["import-review-name"].waitForExistence(timeout: 10))
        app.swipeDown()
        app.buttons["import-review-outline-item"].tap()
        XCTAssertTrue(versions.waitForExistence(timeout: 30))
        app.buttons["outline-clear"].tap()
        XCTAssertTrue(app.otherElements["outline-canvas"].waitForExistence(timeout: 3))
        XCTAssertFalse(versions.exists)
        XCTAssertFalse(app.buttons["apply-item-outline"].isEnabled)
        app.buttons["outline-rotate-right"].tap()
        XCTAssertFalse(versions.exists)
        XCTAssertFalse(app.buttons["apply-item-outline"].isEnabled)
        app.navigationBars["Outline item"].buttons["Cancel"].tap()
        XCTAssertTrue(app.otherElements["import-review-screen"].waitForExistence(timeout: 3))
    }

    func testLongPressDeleteCanBeCancelledThenPersistsAfterRelaunch() {
        app.launchArguments = ["-resetPrototypeData", "-loadPrototypeSamples"]
        app.launch()
        app.tabBars.buttons["Closet"].tap()
        let piece = app.staticTexts["Navy Oxford Shirt"]
        XCTAssertTrue(piece.waitForExistence(timeout: 5))
        piece.press(forDuration: 1)
        let delete = app.buttons["closet-delete-item"]
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        delete.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(piece.exists)
        piece.press(forDuration: 1)
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        delete.tap()
        let confirm = app.alerts.buttons["Delete"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["11 pieces"].waitForExistence(timeout: 5))
        XCTAssertFalse(piece.exists)

        app.terminate()
        app.launchArguments = []
        app.launch()
        app.tabBars.buttons["Closet"].tap()
        XCTAssertTrue(app.staticTexts["11 pieces"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Navy Oxford Shirt"].exists)
    }

    func testSpecificImportTypeUpdatesAutomaticNameSeasonsAndSavedDetails() {
        app.launchArguments = ["-resetPrototypeData", "-openPrototypeImportReview"]
        app.launch()
        XCTAssertTrue(app.otherElements["import-review-screen"].waitForExistence(timeout: 5))
        let bottom = app.buttons["import-review-category-bottom"]
        scrollTo(bottom)
        bottom.tap()
        let shorts = app.buttons["import-review-kind-shorts"]
        scrollTo(shorts)
        shorts.tap()
        XCTAssertEqual(shorts.value as? String, "Selected")
        let typeContinue = app.buttons["import-review-type-continue"]
        scrollTo(typeContinue)
        typeContinue.tap()
        let black = app.buttons["import-review-dominant-black"]
        XCTAssertTrue(black.waitUntilHittable(timeout: 3))
        black.tap()
        let noAccent = app.buttons["import-review-accent-none"]
        XCTAssertTrue(noAccent.waitUntilHittable(timeout: 3))
        noAccent.tap()
        let summer = app.buttons["import-review-season-summer"]
        XCTAssertTrue(summer.waitUntilHittable(timeout: 3))
        XCTAssertEqual(summer.value as? String, "Selected")
        XCTAssertEqual(app.buttons["import-review-season-spring"].value as? String, "Selected")
        XCTAssertEqual(app.buttons["import-review-season-autumn"].value as? String, "Not selected")
        XCTAssertEqual(app.buttons["import-review-season-winter"].value as? String, "Not selected")
        app.buttons["import-review-next"].tap()
        XCTAssertTrue(app.staticTexts["Piece 2 of 2"].waitForExistence(timeout: 3))
        app.buttons["import-review-save"].tap()
        XCTAssertTrue(app.otherElements["import-summary-screen"].waitForExistence(timeout: 5))
        app.buttons["import-summary-done"].tap()
        let saved = app.staticTexts["Black Shorts"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.textFields["Name"].value as? String, "Black Shorts")
        XCTAssertTrue(app.buttons["piece-editor-category"].label.contains("Shorts"))
        let editorSummer = app.buttons["piece-editor-season-summer"]
        scrollTo(editorSummer)
        XCTAssertEqual(editorSummer.value as? String, "Selected")
        XCTAssertEqual(app.buttons["piece-editor-season-winter"].value as? String, "Not selected")
    }

    private func scrollTo(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<12 {
            // SwiftUI can report an offscreen button as hittable underneath
            // the sticky import controls. Keep the whole target above them.
            if element.isHittable, element.frame.minY >= 140,
               element.frame.maxY <= app.frame.maxY - 120 { return }
            let scrollingBack = element.exists && element.frame.minY < 140
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollingBack ? 0.40 : 0.70))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollingBack ? 0.70 : 0.40))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Element did not become fully visible", file: file, line: line)
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
