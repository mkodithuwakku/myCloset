import XCTest
@testable import myCloset

final class OutfitEngineTests: XCTestCase {
    private let engine = OutfitEngine()

    func testEmptyClosetReturnsEmptyClosetError() {
        let result = engine.generate(
            from: [],
            occasion: .errands,
            formality: .casual,
            weather: TestFixtures.summerWeather
        )

        XCTAssertEqual(result.failure, .emptyCloset)
    }

    func testCompleteClosetProducesStructurallyCompleteOutfit() throws {
        let closet = TestFixtures.completeCloset
        let outfit = try generated(from: closet)
        let items = resolve(outfit, in: closet)

        XCTAssertTrue(items.contains { $0.category == .top })
        XCTAssertTrue(items.contains { $0.category == .bottom })
        XCTAssertTrue(items.contains { $0.category == .footwear })
    }

    func testLockedPieceIsAlwaysRetained() throws {
        let closet = TestFixtures.completeCloset
        let shirt = closet.first { $0.name == "Navy Shirt" }!

        for _ in 0..<20 {
            let outfit = try generated(from: closet, lockedIDs: [shirt.id])
            XCTAssertTrue(outfit.itemIDs.contains(shirt.id))
        }
    }

    func testUnavailablePieceIsExcluded() throws {
        var closet = TestFixtures.completeCloset
        let unavailableID = closet[0].id
        closet[0].availability = .laundry

        for _ in 0..<20 {
            let outfit = try generated(from: closet)
            XCTAssertFalse(outfit.itemIDs.contains(unavailableID))
        }
    }

    func testExplicitlyExcludedPieceIsNotReturned() throws {
        let closet = TestFixtures.completeCloset
        let excluded = closet.first { $0.name == "Navy Shirt" }!

        let outfit = try generated(from: closet, excludedIDs: [excluded.id])

        XCTAssertFalse(outfit.itemIDs.contains(excluded.id))
    }

    func testTwoLockedTopsReturnConflict() {
        let closet = TestFixtures.completeCloset
        let tops = closet.filter { $0.category == .top }

        let result = engine.generate(
            from: closet,
            occasion: .errands,
            formality: .casual,
            weather: TestFixtures.summerWeather,
            lockedIDs: Set(tops.map(\.id))
        )

        guard case .conflictingLocks = result.failure else {
            return XCTFail("Expected conflicting lock error, got \(String(describing: result.failure))")
        }
    }

    func testLockedOnePieceAndTopReturnConflict() {
        var closet = TestFixtures.completeCloset
        let dress = TestFixtures.item("Black Jumpsuit", category: .onePiece, color: "Black")
        closet.append(dress)
        let top = closet.first { $0.category == .top }!

        let result = engine.generate(
            from: closet,
            occasion: .dinner,
            formality: .smartCasual,
            weather: TestFixtures.summerWeather,
            lockedIDs: [dress.id, top.id]
        )

        guard case .conflictingLocks = result.failure else {
            return XCTFail("Expected one-piece conflict")
        }
    }

    func testUnavailableLockedItemReturnsConflict() {
        var closet = TestFixtures.completeCloset
        closet[0].availability = .unavailable

        let result = engine.generate(
            from: closet,
            occasion: .walk,
            formality: .casual,
            weather: TestFixtures.summerWeather,
            lockedIDs: [closet[0].id]
        )

        guard case .conflictingLocks = result.failure else {
            return XCTFail("Expected unavailable lock conflict")
        }
    }

    func testMissingBottomReturnsActionableError() {
        let closet = TestFixtures.completeCloset.filter { $0.category != .bottom }

        let result = engine.generate(
            from: closet,
            occasion: .errands,
            formality: .casual,
            weather: TestFixtures.summerWeather
        )

        XCTAssertEqual(result.failure, .missingCategory("bottom"))
    }

    func testColdWeatherIncludesAvailableWinterOuterwear() throws {
        let closet = TestFixtures.completeCloset
        let outfit = try generated(from: closet, weather: TestFixtures.winterWeather)
        let items = resolve(outfit, in: closet)

        XCTAssertTrue(items.contains { $0.category == .outerwear })
    }

    func testExplanationIncludesLockedPieceAndWeather() throws {
        let closet = TestFixtures.completeCloset
        let shirt = closet.first { $0.name == "Navy Shirt" }!

        let outfit = try generated(from: closet, lockedIDs: [shirt.id])

        XCTAssertTrue(outfit.explanation.localizedCaseInsensitiveContains("locked Navy Shirt"))
        XCTAssertTrue(outfit.explanation.contains("24°C"))
    }

    private func generated(
        from closet: [ClosetItem],
        weather: WeatherContext = TestFixtures.summerWeather,
        lockedIDs: Set<UUID> = [],
        excludedIDs: Set<UUID> = []
    ) throws -> GeneratedOutfit {
        try engine.generate(
            from: closet,
            occasion: .errands,
            formality: .casual,
            weather: weather,
            lockedIDs: lockedIDs,
            excluding: excludedIDs
        ).get()
    }

    private func resolve(_ outfit: GeneratedOutfit, in closet: [ClosetItem]) -> [ClosetItem] {
        outfit.itemIDs.compactMap { id in closet.first { $0.id == id } }
    }
}

private extension Result where Failure == OutfitGenerationError {
    var failure: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}
