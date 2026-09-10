import XCTest
@testable import myCloset

final class ClosetImportSummaryTests: XCTestCase {
    func testJacketAndBottomAreReadyWithoutAShirt() {
        let closet = [TestFixtures.item("Jacket", category: .outerwear), TestFixtures.item("Jeans", category: .bottom)]
        let summary = ClosetImportSummary(importedItems: closet, availableClosetItems: closet, skipped: 0, failures: 0)
        XCTAssertTrue(summary.canGenerateOutfit)
    }

    func testSummaryCountsOnlyItemsFromCompletedImport() {
        let imported = [
            TestFixtures.item("Top 1", category: .top),
            TestFixtures.item("Top 2", category: .top),
            TestFixtures.item("Shoes", category: .footwear)
        ]
        let summary = ClosetImportSummary(
            importedItems: imported,
            availableClosetItems: imported,
            skipped: 1,
            failures: 0
        )

        XCTAssertEqual(summary.count(in: .top), 2)
        XCTAssertEqual(summary.count(in: .footwear), 1)
        XCTAssertEqual(summary.count(in: .bottom), 0)
    }

    func testSummaryRecognizesTopAndBottomAsReady() {
        let closet = [
            TestFixtures.item("Top", category: .top),
            TestFixtures.item("Bottom", category: .bottom)
        ]
        let summary = ClosetImportSummary(
            importedItems: closet,
            availableClosetItems: closet,
            skipped: 0,
            failures: 0
        )

        XCTAssertTrue(summary.canGenerateOutfit)
        XCTAssertEqual(summary.readinessMessage, "Your closet has the pieces needed to generate an outfit.")
    }

    func testSummaryExplainsMissingBottom() {
        let top = TestFixtures.item("Top", category: .top)
        let summary = ClosetImportSummary(
            importedItems: [top],
            availableClosetItems: [top],
            skipped: 0,
            failures: 0
        )

        XCTAssertFalse(summary.canGenerateOutfit)
        XCTAssertEqual(summary.readinessMessage, "Add an available bottom or one-piece to generate an outfit.")
    }
}
