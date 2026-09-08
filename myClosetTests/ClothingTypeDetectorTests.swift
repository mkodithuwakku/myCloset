import UIKit
import XCTest
@testable import myCloset

final class ClothingTypeDetectorTests: XCTestCase {
    func testFilenameDetectsTop() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "navy-oxford-shirt.jpg"), .top)
    }

    func testFilenameDetectsBottom() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "black_wide-leg-pants.png"), .bottom)
        XCTAssertEqual(ClothingTypeDetector.kind(forFilename: "yellow-shorts.webp"), .shorts)
    }

    func testFilenameDetectsOnePieceAndOuterwear() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "summer-dress.jpeg"), .onePiece)
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "camel-wool-coat.heic"), .outerwear)
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "black-zip-hoodie.jpg"), .outerwear)
    }

    func testFilenameDetectsFootwearAndAccessory() {
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "white-sneakers.jpg"), .footwear)
        XCTAssertEqual(ClothingTypeDetector.kind(forFilename: "red-athletic-shoes.jpg"), .sneakers)
        XCTAssertEqual(ClothingTypeDetector.kind(forFilename: "black-ankle-boots.heic"), .boots)
        XCTAssertEqual(ClothingTypeDetector.category(forFilename: "silver-watch.jpg"), .accessory)
    }

    func testLowConfidenceSpecificShoeBeatsGenericClothingLabel() {
        let detection = ClothingTypeDetector.detection(forVisionObservations: [
            ("clothing", 0.91),
            ("athletic shoe", 0.05)
        ])

        XCTAssertEqual(detection.category, .footwear)
        XCTAssertEqual(detection.kind, .sneakers)
        XCTAssertEqual(detection.source, .vision)
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

        let red = ClothingColor.palette.first { $0.name == "Red" }!
        XCTAssertEqual(
            ClothingTypeDetector.suggestedName(
                filename: "images (1).jpeg",
                category: .onePiece,
                kind: .dress,
                dominantColor: red,
                index: 8
            ),
            "Red Dress"
        )
    }

    func testMachineGeneratedFilenameUsesColorAndDetectedKind() {
        let blue = ClothingColor.palette.first { $0.name == "Blue" }!
        let name = ClothingTypeDetector.suggestedName(
            filename: "219a4bbbc9d6405fbeac0a3f6bf59e01.webp",
            category: .bottom,
            kind: .shorts,
            dominantColor: blue,
            index: 2
        )

        XCTAssertEqual(name, "Blue Shorts")
    }

    func testShortsReceiveWarmWeatherCasualDefaults() {
        XCTAssertEqual(GarmentKind.shorts.suggestedSeasons, [.spring, .summer])
        XCTAssertEqual(GarmentKind.shorts.suggestedFormalities, [.active, .veryCasual, .casual])
    }

    func testGenericCategorySeasonDefaultsRemainEditableStartingPoints() {
        XCTAssertEqual(ClosetImageImporter.defaultSeasons(for: .outerwear), [.spring, .autumn, .winter])
        XCTAssertEqual(ClosetImageImporter.defaultSeasons(for: .onePiece), [.spring, .summer, .autumn])
        XCTAssertEqual(ClosetImageImporter.defaultSeasons(for: .footwear), Set(WardrobeSeason.allCases))
    }

    func testVisionPrefersSpecificGarmentAndFlagsGenericClothing() {
        let shoes = ClothingTypeDetector.detection(forVisionObservations: [
            ("clothing", 0.95),
            ("jacket", 0.94),
            ("sneaker", 0.54)
        ])
        XCTAssertEqual(shoes.category, .footwear)
        XCTAssertEqual(shoes.kind, .sneakers)
        XCTAssertFalse(shoes.needsReview)

        let generic = ClothingTypeDetector.detection(forVisionObservations: [
            ("clothing", 0.81),
            ("jacket", 0.80)
        ])
        XCTAssertEqual(generic.category, .outerwear)
        XCTAssertEqual(generic.kind, .jacket)
        XCTAssertFalse(generic.needsReview)
    }

    func testLegSplitSilhouetteDetectsTrousersWithoutAUsefulVisionLabel() {
        let silhouette = GarmentSilhouetteFeatures(
            heightToWidthRatio: 0.79,
            centerOccupancyByBand: [0.9, 0.9, 0.9, 0.85, 0.7, 0.5, 0.2, 0.1, 0, 0]
        )
        let detection = ClothingTypeDetector.detection(
            forVisionObservations: [("clothing", 0.64), ("jacket", 0.63)],
            silhouette: silhouette
        )

        XCTAssertEqual(detection.category, .bottom)
        XCTAssertEqual(detection.kind, .trousers)
        XCTAssertEqual(detection.source, .silhouette)
        XCTAssertFalse(detection.needsReview)

        let reversed = GarmentSilhouetteFeatures(
            heightToWidthRatio: 0.79,
            centerOccupancyByBand: Array(silhouette.centerOccupancyByBand.reversed())
        )
        XCTAssertEqual(reversed.suggestedBottomKind(jeansConfidence: 0), .trousers)
    }

    func testCompactOpenSilhouetteDetectsShorts() {
        let silhouette = GarmentSilhouetteFeatures(
            heightToWidthRatio: 0.6,
            centerOccupancyByBand: [0.45, 0.9, 0.95, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.65]
        )
        let detection = ClothingTypeDetector.detection(
            forVisionObservations: [("clothing", 0.25), ("jacket", 0.24)],
            silhouette: silhouette
        )

        XCTAssertEqual(detection.category, .bottom)
        XCTAssertEqual(detection.kind, .shorts)
    }

    func testCompactOpenJacketSilhouetteStaysOutOfBottoms() {
        let silhouette = GarmentSilhouetteFeatures(
            heightToWidthRatio: 0.62,
            centerOccupancyByBand: [0.67, 1, 1, 1, 1, 1, 1, 1, 0.98, 0.14]
        )
        let detection = ClothingTypeDetector.detection(
            forVisionObservations: [("clothing", 0.81), ("jacket", 0.81)],
            silhouette: silhouette
        )

        XCTAssertEqual(detection.category, .outerwear)
        XCTAssertEqual(detection.kind, .jacket)
    }

    func testDenimLabelDoesNotTurnJacketShapedGarmentIntoBottom() {
        let silhouette = GarmentSilhouetteFeatures(
            heightToWidthRatio: 1.3,
            centerOccupancyByBand: Array(repeating: 0.94, count: 10)
        )
        let detection = ClothingTypeDetector.detection(
            forVisionObservations: [("clothing", 0.95), ("jacket", 0.9), ("jeans", 0.87)],
            silhouette: silhouette
        )

        XCTAssertEqual(detection.category, .outerwear)
        XCTAssertEqual(detection.kind, .jacket)
        XCTAssertEqual(detection.source, .vision)
        XCTAssertFalse(detection.needsReview)
    }

    func testVisionIdentifiesHoodieAsOuterwear() {
        let detection = ClothingTypeDetector.detection(forVisionObservations: [
            ("clothing", 0.82),
            ("hoodie", 0.71)
        ])

        XCTAssertEqual(detection.category, .outerwear)
        XCTAssertEqual(detection.kind, .hoodie)
        XCTAssertEqual(detection.source, .vision)
    }

    func testMetadataNameUsesConfirmedColourAndCategory() {
        let black = ClothingColor.palette.first { $0.name == "Black" }!

        XCTAssertEqual(
            ClothingTypeDetector.metadataName(category: .top, dominantColor: black),
            "Black Top"
        )
    }

    func testImporterBuildsEditableDefaultsFromDescriptiveFile() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80))
        let data = renderer.image { context in
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
        }.pngData()!

        let imported = await ClosetImageImporter.makePiece(
            from: data,
            filename: "shorts.webp",
            index: 1
        )
        let result = try XCTUnwrap(imported)

        XCTAssertEqual(result.item.name, "Yellow Shorts")
        XCTAssertEqual(result.item.category, .bottom)
        XCTAssertEqual(result.item.seasons, [.spring, .summer])
        XCTAssertEqual(result.item.formalities, [.active, .veryCasual, .casual])
    }

}
