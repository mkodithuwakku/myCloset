import XCTest
import UIKit
@testable import myCloset

final class GarmentEdgeRefinerTests: XCTestCase {
    func testRefinementRecoversFabricOutsideLassoAndRemovesFloorInsideIt() throws {
        let source = rectanglePhoto()
        // Left edge misses 6px of fabric; right edge includes 6px of floor.
        let rough = rectangle(0.28, 0.2, 0.78, 0.8)
        let result = try XCTUnwrap(GarmentEdgeRefiner.refine(from: source, normalizedOutlines: [rough], useVision: false))
        let preview = try XCTUnwrap(UIImage(data: result.previewImageData)?.cgImage)
        let pixels = try XCTUnwrap(GarmentEdgeRefiner.rgbaPixels(preview, width: 200, height: 300))
        XCTAssertGreaterThan(pixels[(150 * 200 + 51) * 4 + 3], 240, "Recover the left side of the shirt")
        XCTAssertLessThan(pixels[(150 * 200 + 154) * 4 + 3], 20, "Remove floor inside the rough right edge")
        XCTAssertGreaterThan(pixels[(150 * 200 + 100) * 4 + 3], 240, "Keep the garment interior")
        XCTAssertTrue(result.isolatedImageData.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        XCTAssertLessThan(try XCTUnwrap(UIImage(data: result.isolatedImageData)).size.width, 120)
    }

    func testRefinedPreviewPreservesAsymmetricHemAndSourceColors() throws {
        let source = photo { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 60, y: 45, width: 80, height: 100))
            UIColor.red.setFill()
            context.fill(CGRect(x: 40, y: 145, width: 120, height: 120))
        }
        let outline = [CGPoint(x: 0.28, y: 0.14), CGPoint(x: 0.72, y: 0.14),
                       CGPoint(x: 0.72, y: 0.46), CGPoint(x: 0.82, y: 0.46),
                       CGPoint(x: 0.82, y: 0.90), CGPoint(x: 0.18, y: 0.90),
                       CGPoint(x: 0.18, y: 0.46), CGPoint(x: 0.28, y: 0.46)]
        let result = try XCTUnwrap(GarmentEdgeRefiner.refine(from: source, normalizedOutlines: [outline], useVision: false))
        let pixels = try previewPixels(result)
        XCTAssertGreaterThan(pixels[(70 * 200 + 100) * 4 + 2], 240, "Blue collar stays at the top")
        XCTAssertGreaterThan(pixels[(250 * 200 + 45) * 4], 240, "Wide red hem stays at the bottom")
        XCTAssertGreaterThan(pixels[(250 * 200 + 155) * 4 + 3], 240, "Neither hem corner is lost")
        XCTAssertLessThan(pixels[(70 * 200 + 45) * 4 + 3], 20)
    }

    func testSeparateShoesSurviveWithTransparentGapAndUnselectedObjectExcluded() throws {
        let source = photo { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 30, y: 150, width: 40, height: 100))
            context.fill(CGRect(x: 120, y: 180, width: 35, height: 70))
            context.fill(CGRect(x: 100, y: 20, width: 50, height: 60))
        }
        let outlines = [rectangle(0.13, 0.49, 0.37, 0.84), rectangle(0.58, 0.59, 0.79, 0.84)]
        let result = try XCTUnwrap(GarmentEdgeRefiner.refine(from: source, normalizedOutlines: outlines, useVision: false))
        let pixels = try previewPixels(result)
        XCTAssertGreaterThan(pixels[(220 * 200 + 50) * 4 + 3], 240)
        XCTAssertGreaterThan(pixels[(220 * 200 + 135) * 4 + 3], 240)
        XCTAssertLessThan(pixels[(220 * 200 + 95) * 4 + 3], 20)
        XCTAssertLessThan(pixels[(50 * 200 + 125) * 4 + 3], 20)
    }

    func testAmbiguousColorsOfferNoSuggestionAndManualCropRemainsAvailable() throws {
        let source = photo { _ in }
        let outlines = [rectangle(0.25, 0.2, 0.75, 0.8)]
        XCTAssertNil(GarmentEdgeRefiner.refine(from: source, normalizedOutlines: outlines, useVision: false))
        XCTAssertNotNil(ImageUtilities.outlinedCutoutData(from: source, normalizedOutlines: outlines))
    }

    func testGuidanceRejectsMissingShoeAndDistantBackgroundEvenWithLargeMainRegion() throws {
        let guidance = try XCTUnwrap(OutlineGuidance(
            outlines: [rectangle(0.1, 0.1, 0.5, 0.85), rectangle(0.7, 0.6, 0.9, 0.85)],
            size: CGSize(width: 200, height: 300)))
        let valid = guidance.inside.map { UInt8($0 ? 255 : 0) }
        XCTAssertTrue(guidance.accepts(valid))
        let missingShoe = guidance.regions[0].map { UInt8($0 ? 255 : 0) }
        XCTAssertFalse(guidance.accepts(missingShoe))
        var escaped = valid
        for y in 5..<45 { for x in 140..<180 { escaped[y * 200 + x] = 255 } }
        XCTAssertFalse(guidance.accepts(escaped))
        var missingHem = valid
        for y in 220..<255 { for x in 20..<100 { missingHem[y * 200 + x] = 0 } }
        XCTAssertFalse(guidance.accepts(missingHem))
        let smallExtraArea = try XCTUnwrap(OutlineGuidance(
            outlines: [rectangle(0.1, 0.1, 0.5, 0.85), rectangle(0.7, 0.6, 0.75, 0.65)],
            size: CGSize(width: 200, height: 300)))
        XCTAssertEqual(smallExtraArea.regions.count, 2, "Never silently discard an extra area below the main-lasso minimum")
        XCTAssertFalse(smallExtraArea.accepts(smallExtraArea.regions[0].map { $0 ? 255 : 0 }))
    }

    func testVisionInstancesAreChosenByEachOutlineRatherThanImageCentre() throws {
        let guidance = try XCTUnwrap(OutlineGuidance(
            outlines: [rectangle(0.1, 0.5, 0.3, 0.9), rectangle(0.7, 0.6, 0.9, 0.9)],
            size: CGSize(width: 200, height: 300)))
        var labels = [Int](repeating: 7, count: 200 * 300) // unrelated object elsewhere
        for index in labels.indices {
            if guidance.regions[0][index] { labels[index] = 2 }
            if guidance.regions[1][index] { labels[index] = 5 }
        }
        XCTAssertEqual(GarmentEdgeRefiner.selectedInstances(labels: labels, guidance: guidance), IndexSet([2, 5]))
    }

    func testInvalidInputsFailSafelyAndLargeImagesHaveBoundedOutput() throws {
        XCTAssertNil(GarmentEdgeRefiner.refine(from: Data([0, 1]), normalizedOutlines: [rectangle(0.2, 0.2, 0.8, 0.8)]))
        XCTAssertNil(GarmentEdgeRefiner.refine(from: rectanglePhoto(), normalizedOutlines: []))
        XCTAssertNil(OutlineGuidance(outlines: [[CGPoint(x: CGFloat.nan, y: 0), .zero, CGPoint(x: 1, y: 1)]], size: CGSize(width: 200, height: 300)))
        let source = photo(size: CGSize(width: 4_000, height: 3_000)) { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 1_000, y: 600, width: 2_000, height: 1_800))
        }
        let result = try XCTUnwrap(GarmentEdgeRefiner.refine(from: source, normalizedOutlines: [rectangle(0.24, 0.19, 0.76, 0.81)], useVision: false))
        let image = try XCTUnwrap(UIImage(data: result.previewImageData))
        XCTAssertEqual(image.size.width, 1_200)
        XCTAssertEqual(image.size.height, 900)
    }

    func testCancelledRefinementReturnsNoResult() async {
        let data = rectanglePhoto()
        let outlines = [rectangle(0.24, 0.19, 0.76, 0.81)]
        let worker = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return GarmentEdgeRefiner.refine(from: data, normalizedOutlines: outlines, useVision: false)
        }
        let result = await worker.value
        XCTAssertNil(result)
    }

    private func previewPixels(_ result: GarmentEdgeRefinement) throws -> [UInt8] {
        let image = try XCTUnwrap(UIImage(data: result.previewImageData)?.cgImage)
        return try XCTUnwrap(GarmentEdgeRefiner.rgbaPixels(image, width: 200, height: 300))
    }

    private func rectanglePhoto() -> Data {
        photo { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 50, y: 60, width: 100, height: 180))
        }
    }

    private func photo(size: CGSize = CGSize(width: 200, height: 300), draw: (UIGraphicsImageRendererContext) -> Void) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(white: 0.9, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            draw(context)
        }.pngData()!
    }

    private func rectangle(_ left: CGFloat, _ top: CGFloat, _ right: CGFloat, _ bottom: CGFloat) -> [CGPoint] {
        [CGPoint(x: left, y: top), CGPoint(x: right, y: top), CGPoint(x: right, y: bottom), CGPoint(x: left, y: bottom)]
    }
}
