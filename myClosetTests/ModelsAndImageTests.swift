import UIKit
import XCTest
@testable import myCloset

final class ModelsAndImageTests: XCTestCase {
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

    func testPreparedImageIsResizedToMaximumDimension() throws {
        let source = solidImageData(color: .red, size: CGSize(width: 2_400, height: 1_200))
        let prepared = try XCTUnwrap(ImageUtilities.preparedImageData(from: source))
        let image = try XCTUnwrap(UIImage(data: prepared))

        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 1_200.5)
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
}
