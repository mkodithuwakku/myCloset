import UIKit
import XCTest
@testable import myCloset

final class ModelsAndImageTests: XCTestCase {
    func testSpecificTypesUpdateNamesAndSeasonDefaultsWithoutChangingCustomNames() {
        var item = TestFixtures.item("Navy Top", category: .top)
        let examples: [(GarmentKind, String, Set<WardrobeSeason>)] = [
            (.shorts, "Navy Shorts", [.spring, .summer]),
            (.longSleeve, "Navy Long Sleeve", [.spring, .autumn, .winter]),
            (.jacket, "Navy Jacket", [.spring, .autumn, .winter]),
            (.sandals, "Navy Sandals", [.spring, .summer]),
            (.coat, "Navy Coat", [.autumn, .winter])
        ]
        for (kind, name, seasons) in examples {
            item.applyType(.kind(kind), updateName: true)
            XCTAssertEqual(item.name, name)
            XCTAssertEqual(item.kind, kind)
            XCTAssertEqual(item.category, kind.category)
            XCTAssertEqual(item.seasons, seasons)
        }
        item.name = "My favourite weekend piece"
        item.applyType(.kind(.jeans), updateName: false)
        XCTAssertEqual(item.name, "My favourite weekend piece")
        item.applyType(.category(.top), updateName: false)
        XCTAssertNil(item.kind)
        XCTAssertEqual(item.seasons, Set(WardrobeSeason.allCases))
    }

    func testLegacyClosetItemsAndSnapshotsDecodeWithoutSpecificType() throws {
        let item = TestFixtures.item("Older top", category: .top)
        let data = try JSONEncoder().encode(item)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "kind")
        let decoded = try JSONDecoder().decode(ClosetItem.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.kind)
        XCTAssertEqual(decoded.category, .top)
        XCTAssertEqual(decoded.name, item.name)
        let snapshot = OutfitSnapshotItem(item: item)
        var snapshotJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as? [String: Any])
        snapshotJSON.removeValue(forKey: "kind")
        let olderSnapshot = try JSONDecoder().decode(OutfitSnapshotItem.self, from: JSONSerialization.data(withJSONObject: snapshotJSON))
        XCTAssertNil(olderSnapshot.kind)
        XCTAssertEqual(olderSnapshot.name, item.name)
    }

    func testNorthernSeasonsFollowCalendarMonths() {
        XCTAssertEqual(WardrobeSeason.current(on: date(month: 1), latitude: 53), .winter)
        XCTAssertEqual(WardrobeSeason.current(on: date(month: 4), latitude: 53), .spring)
        XCTAssertEqual(WardrobeSeason.current(on: date(month: 7), latitude: 53), .summer)
        XCTAssertEqual(WardrobeSeason.current(on: date(month: 10), latitude: 53), .autumn)
    }

    func testSouthernHemisphereInvertsSeason() {
        XCTAssertEqual(WardrobeSeason.current(on: date(month: 7), latitude: -33), .winter)
    }

    func testFormalityLevelsSortFromActiveToFormal() {
        XCTAssertEqual(FormalityLevel.allCases.sorted(), FormalityLevel.allCases)
        XCTAssertLessThan(FormalityLevel.casual, .formal)
    }

    func testWeatherDisplayRoundsTemperature() {
        var weather = TestFixtures.summerWeather
        weather.temperatureCelsius = 23.6

        XCTAssertEqual(weather.displayTemperature, "24°C")
    }

    func testNearestColorMapsDarkBlueToNavy() {
        let color = ClothingColor.nearest(red: 0.12, green: 0.18, blue: 0.32)

        XCTAssertEqual(color.name, "Navy")
    }

    func testSnapshotCopiesHistoricalFields() {
        let item = TestFixtures.item("Navy Shirt", category: .top)
        let snapshot = OutfitSnapshotItem(item: item)

        XCTAssertEqual(snapshot.id, item.id)
        XCTAssertEqual(snapshot.name, item.name)
        XCTAssertEqual(snapshot.category, item.category)
        XCTAssertEqual(snapshot.dominantColor, item.dominantColor)
    }

    func testSnapshotPrefersIsolatedOutfitRendition() {
        var item = TestFixtures.item("Navy Shirt", category: .top)
        item.photoData = Data([1, 2, 3])
        item.isolatedPhotoData = Data([4, 5, 6])

        XCTAssertEqual(OutfitSnapshotItem(item: item).photoData, item.isolatedPhotoData)
    }

    func testPreparedImageIsResizedToMaximumDimension() throws {
        let source = solidImageData(color: .red, size: CGSize(width: 2_400, height: 1_200))
        let prepared = try XCTUnwrap(ImageUtilities.preparedImageData(from: source))
        let image = try XCTUnwrap(UIImage(data: prepared))

        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 1_200.5)
    }

    func testIsolationCoverageRejectsTinyOrFrameFillingMasks() {
        var credible = [Bool](repeating: false, count: 100)
        for y in 2...8 {
            for x in 3...6 { credible[y * 10 + x] = true }
        }
        var tiny = [Bool](repeating: false, count: 100)
        tiny[55] = true
        var sparse = [Bool](repeating: false, count: 100)
        for index in stride(from: 0, to: 100, by: 6) { sparse[index] = true }

        XCTAssertTrue(ImageUtilities.maskHasCredibleGarmentCoverage(credible, width: 10, height: 10))
        XCTAssertFalse(ImageUtilities.maskHasCredibleGarmentCoverage(tiny, width: 10, height: 10))
        XCTAssertFalse(ImageUtilities.maskHasCredibleGarmentCoverage(sparse, width: 10, height: 10))
        XCTAssertFalse(ImageUtilities.maskHasCredibleGarmentCoverage(
            [Bool](repeating: true, count: 100),
            width: 10,
            height: 10
        ))
    }

    func testOutlineCutoutKeepsEnclosedAreaAndMakesOutsideTransparent() throws {
        let source = solidImageData(color: .red, size: CGSize(width: 200, height: 100))
        let cutoutData = try XCTUnwrap(ImageUtilities.outlinedCutoutData(
            from: source,
            normalizedOutlines: [[
                CGPoint(x: 0.5, y: 0.15),
                CGPoint(x: 0.85, y: 0.5),
                CGPoint(x: 0.5, y: 0.85),
                CGPoint(x: 0.15, y: 0.5)
            ]]
        ))
        let cutout = try XCTUnwrap(UIImage(data: cutoutData))
        let decodedSource = try XCTUnwrap(UIImage(data: source))

        XCTAssertTrue(cutoutData.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        XCTAssertLessThan(cutout.size.width, decodedSource.size.width * 0.80)
        XCTAssertLessThan(cutout.size.height, decodedSource.size.height * 0.80)
        XCTAssertGreaterThan(try XCTUnwrap(alphaValue(in: cutout, x: 0.5, y: 0.5)), 240)
        XCTAssertLessThan(try XCTUnwrap(alphaValue(in: cutout, x: 0, y: 0)), 20)
    }

    func testOutlinePreservesAsymmetricGarmentHemAndSourceOrientation() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = try XCTUnwrap(UIGraphicsImageRenderer(
            size: CGSize(width: 200, height: 300), format: format
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 150))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 150, width: 200, height: 150))
        }.pngData())
        let cutoutData = try XCTUnwrap(ImageUtilities.outlinedCutoutData(
            from: source,
            normalizedOutlines: [[
                CGPoint(x: 0.4, y: 0.2), CGPoint(x: 0.6, y: 0.2),
                CGPoint(x: 0.9, y: 0.45), CGPoint(x: 0.8, y: 0.9),
                CGPoint(x: 0.2, y: 0.9), CGPoint(x: 0.1, y: 0.45)
            ]]
        ))
        let cutout = try XCTUnwrap(UIImage(data: cutoutData))

        // The collar is narrow and the hem is wide, so a vertically flipped
        // mask cannot pass as it did with the old symmetric diamond fixture.
        XCTAssertGreaterThan(try XCTUnwrap(alphaValue(in: cutout, x: 0.2, y: 0.9)), 240)
        XCTAssertGreaterThan(try XCTUnwrap(alphaValue(in: cutout, x: 0.8, y: 0.9)), 240)
        XCTAssertLessThan(try XCTUnwrap(alphaValue(in: cutout, x: 0.2, y: 0.1)), 20)
        XCTAssertLessThan(try XCTUnwrap(alphaValue(in: cutout, x: 0.8, y: 0.1)), 20)
        let collar = try pixelRGBA(in: cutout, x: 0.5, y: 0.1)
        let hem = try pixelRGBA(in: cutout, x: 0.5, y: 0.9)
        XCTAssertGreaterThan(collar[0], 240)
        XCTAssertLessThan(collar[2], 20)
        XCTAssertGreaterThan(hem[2], 240)
        XCTAssertLessThan(hem[0], 20)
    }

    func testOutlineKeepsSeparateOffCenterRegionsAtTheirSourcePositions() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = try XCTUnwrap(UIGraphicsImageRenderer(
            size: CGSize(width: 200, height: 300), format: format
        ).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 20, y: 180, width: 60, height: 90))
            UIColor.red.setFill()
            context.fill(CGRect(x: 120, y: 210, width: 60, height: 60))
        }.pngData())
        let data = try XCTUnwrap(ImageUtilities.outlinedCutoutData(
            from: source,
            normalizedOutlines: [
                [CGPoint(x: 0.1, y: 0.6), CGPoint(x: 0.4, y: 0.6),
                 CGPoint(x: 0.4, y: 0.9), CGPoint(x: 0.1, y: 0.9)],
                [CGPoint(x: 0.6, y: 0.7), CGPoint(x: 0.9, y: 0.7),
                 CGPoint(x: 0.9, y: 0.9), CGPoint(x: 0.6, y: 0.9)]
            ]
        ))
        let cutout = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(cutout.size.width, 168, accuracy: 1)
        XCTAssertEqual(cutout.size.height, 98, accuracy: 1)
        let leftRegion = try pixelRGBA(in: cutout, x: 0.2, y: 0.6)
        let rightRegion = try pixelRGBA(in: cutout, x: 0.8, y: 0.6)
        XCTAssertGreaterThan(leftRegion[2], 240)
        XCTAssertLessThan(leftRegion[0], 20)
        XCTAssertGreaterThan(leftRegion[3], 240)
        XCTAssertGreaterThan(rightRegion[0], 240)
        XCTAssertLessThan(rightRegion[2], 20)
        XCTAssertGreaterThan(rightRegion[3], 240)
        XCTAssertLessThan(try XCTUnwrap(alphaValue(in: cutout, x: 0.5, y: 0.6)), 20)
    }

    func testLassoRequiresAnEnclosedArea() {
        let straightLine = [
            CGPoint(x: 0.2, y: 0.2),
            CGPoint(x: 0.4, y: 0.4),
            CGPoint(x: 0.6, y: 0.6),
            CGPoint(x: 0.8, y: 0.8)
        ]
        let enclosedDiamond = [
            CGPoint(x: 0.5, y: 0.15),
            CGPoint(x: 0.85, y: 0.5),
            CGPoint(x: 0.5, y: 0.85),
            CGPoint(x: 0.15, y: 0.5)
        ]

        XCTAssertFalse(GarmentLassoGeometry.isValid(straightLine))
        XCTAssertTrue(GarmentLassoGeometry.isValid(enclosedDiamond))
    }

    func testQuarterTurnRotationSwapsImageDimensions() throws {
        let source = solidImageData(color: .purple, size: CGSize(width: 160, height: 80))
        let original = try XCTUnwrap(UIImage(data: source))
        let rotatedData = try XCTUnwrap(ImageUtilities.rotatedImageData(from: source, quarterTurns: 1))
        let rotated = try XCTUnwrap(UIImage(data: rotatedData))

        XCTAssertEqual(rotated.size.width, original.size.height, accuracy: 0.5)
        XCTAssertEqual(rotated.size.height, original.size.width, accuracy: 0.5)
    }

    func testOutfitLayoutOverlapsWaistAndStandardizesFootwearScale() {
        let bottom = OutfitCanvasLayout.bottom
        for upper in [OutfitCanvasLayout.top, OutfitCanvasLayout.outerwear] {
            XCTAssertTrue(upper.verticalRange.overlaps(bottom.verticalRange))
            XCTAssertLessThanOrEqual(upper.width / bottom.width, 1.1)
            XCTAssertLessThanOrEqual(upper.height / bottom.height, 0.7)
            let waistOverlap = upper.verticalRange.upperBound - bottom.verticalRange.lowerBound
            XCTAssertLessThanOrEqual(waistOverlap / bottom.height, 0.25)
            XCTAssertEqual(upper.x, bottom.x)
        }
        XCTAssertTrue(OutfitCanvasLayout.bottom.verticalRange.overlaps(OutfitCanvasLayout.footwear.verticalRange))
        XCTAssertLessThan(OutfitCanvasLayout.footwear.width, OutfitCanvasLayout.bottom.width)
        XCTAssertGreaterThan(OutfitCanvasLayout.footwear.height / OutfitCanvasLayout.bottom.height, 0.45)
        XCTAssertLessThan(OutfitCanvasLayout.footwear.height / OutfitCanvasLayout.bottom.height, 0.6)
        XCTAssertLessThanOrEqual(OutfitCanvasLayout.footwear.verticalRange.upperBound, 0.98)
        XCTAssertEqual(OutfitCanvasLayout.footwear.x, OutfitCanvasLayout.bottom.x)
    }

    func testSuggestedColorIgnoresTransparentCutoutBackground() throws {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200), format: format)
        let source = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            UIColor.green.setFill()
            context.fill(CGRect(x: 65, y: 20, width: 70, height: 160))
        }.pngData()!

        let result = try XCTUnwrap(ImageUtilities.suggestedColors(from: source))

        XCTAssertEqual(result.dominant.name, "Green")
        XCTAssertNil(result.accent)
    }

    func testIsolationProducesTrimmedTransparentRenditionOnPlainBackground() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 240), format: format)
        let source = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 240, height: 240))
            UIColor.red.setFill()
            context.fill(CGRect(x: 70, y: 30, width: 100, height: 180))
        }.pngData()!

        let isolatedData = try XCTUnwrap(ImageUtilities.isolatedGarmentData(from: source))
        let isolated = try XCTUnwrap(UIImage(data: isolatedData))

        XCTAssertLessThan(isolated.size.width, 180)
        XCTAssertLessThan(isolated.size.height, 230)
        XCTAssertTrue(isolatedData.starts(with: [0x89, 0x50, 0x4E, 0x47]))
    }

    func testSuggestedColorFindsRedGarment() throws {
        let source = solidImageData(color: .red, size: CGSize(width: 100, height: 100))
        let result = try XCTUnwrap(ImageUtilities.suggestedColors(from: source))

        XCTAssertEqual(result.dominant.name, "Red")
    }

    func testSuggestedColorIgnoresConsistentPlainBackground() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let source = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            UIColor(red: 0.15, green: 0.35, blue: 0.72, alpha: 1).setFill()
            context.fill(CGRect(x: 55, y: 35, width: 90, height: 130))
        }.pngData()!

        let result = try XCTUnwrap(ImageUtilities.suggestedColors(from: source))

        XCTAssertEqual(result.dominant.name, "Blue")
    }

    func testPerceptualColorKeepsCoolDarkNeutralBlack() throws {
        let result = try XCTUnwrap(ImageUtilities.rankedColors(from: [
            .init(red: 0.08, green: 0.09, blue: 0.105, weight: 100)
        ]))

        XCTAssertEqual(result.dominant.name, "Black")
        XCTAssertNil(result.accent)
    }

    func testTinyContrastingRegionIsNotReportedAsAccent() throws {
        let result = try XCTUnwrap(ImageUtilities.rankedColors(from: [
            .init(red: 0.07, green: 0.07, blue: 0.08, weight: 90),
            .init(red: 0.95, green: 0.94, blue: 0.91, weight: 10)
        ]))

        XCTAssertEqual(result.dominant.name, "Black")
        XCTAssertNil(result.accent)
    }

    func testMeaningfulContrastingRegionIsReportedAsAccent() throws {
        let result = try XCTUnwrap(ImageUtilities.rankedColors(from: [
            .init(red: 0.07, green: 0.07, blue: 0.08, weight: 70),
            .init(red: 0.95, green: 0.94, blue: 0.91, weight: 30)
        ]))

        XCTAssertEqual(result.dominant.name, "Black")
        XCTAssertEqual(result.accent?.name, "White")
    }

    func testInvalidImageDataFailsGracefully() {
        let invalid = Data("not an image".utf8)

        XCTAssertNil(ImageUtilities.preparedImageData(from: invalid))
        XCTAssertNil(ImageUtilities.suggestedColors(from: invalid))
    }

    func testForegroundMaskReaderSupportsVisionFloatMasks() throws {
        var optionalBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            nil,
            2,
            2,
            kCVPixelFormatType_OneComponent32Float,
            nil,
            &optionalBuffer
        )
        XCTAssertEqual(status, kCVReturnSuccess)
        let buffer = try XCTUnwrap(optionalBuffer)
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let baseAddress = try XCTUnwrap(CVPixelBufferGetBaseAddress(buffer))
        baseAddress.assumingMemoryBound(to: Float.self)[0] = 1

        let reader = try XCTUnwrap(ForegroundMaskReader(buffer: buffer))
        XCTAssertTrue(reader.containsForeground(x: 0, y: 0))
        XCTAssertFalse(reader.containsForeground(x: 1, y: 0))
    }

    private func date(month: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: month, day: 15))!
    }

    private func solidImageData(color: UIColor, size: CGSize) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData()!
    }

    private func pixelRGBA(in image: UIImage, x: Double, y: Double) throws -> [UInt8] {
        let cgImage = try XCTUnwrap(image.cgImage)
        let pixel = try XCTUnwrap(cgImage.cropping(to: CGRect(
            x: Int(Double(cgImage.width - 1) * x),
            y: Int(Double(cgImage.height - 1) * y), width: 1, height: 1
        )))
        var rgba = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(CGContext(
            data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return rgba
    }

    private func alphaValue(in image: UIImage, x: Double, y: Double) -> UInt8? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixelX = min(width - 1, max(0, Int(Double(width - 1) * x)))
        let pixelY = min(height - 1, max(0, Int(Double(height - 1) * y)))
        return pixels[pixelY * bytesPerRow + pixelX * 4 + 3]
    }
}
