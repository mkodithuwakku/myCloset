import Foundation
import XCTest
@testable import myCloset

final class ClothingTypeDetectorTests: XCTestCase {
    func testFilenameDetectsTop() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "navy-oxford-shirt.jpg"), .top)
    }

    func testFilenameDetectsBottom() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "black_wide-leg-pants.png"), .bottom)
    }

    func testFilenameDetectsOnePieceAndOuterwear() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "summer-dress.jpeg"), .onePiece)
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "camel-wool-coat.heic"), .outerwear)
    }

    func testFilenameDetectsFootwearAndAccessory() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "white-sneakers.jpg"), .footwear)
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "silver-watch.jpg"), .accessory)
    }

    func testSuggestedNameCleansFilename() {
        let name = ClothingTypeDetector.suggestedName(
            filename: "navy_oxford-shirt.jpg",
            category: .top,
            index: 1
        )

        XCTAssertEqual(name, "Navy Oxford Shirt")
    }

    func testGenericCameraFilenameUsesGeneratedName() {
        let name = ClothingTypeDetector.suggestedName(
            filename: "IMG_2048.HEIC",
            category: .footwear,
            index: 7
        )

        XCTAssertEqual(name, "Imported Footwear 7")
    }
}
